################################################################################
# Helpers
################################################################################
def ask(question)
  print "#{question} "
  STDIN.gets.chomp
end

def branch_and_sync(repo:, dest:)

  `git checkout -b upgrade`
  `git clone --depth=1 #{repo} upgrade`
  `rm -rf upgrade/.git`
  `rsync -ah --progress upgrade/ #{dest}`
  `rm -rf upgrade`

  header "Now review the changes, discarding any that might overwrite your own local changes.\n\nAfterward, commit the changes and merge into master. Then delete the update branch."
end

def say(msg)
  puts "#{msg}..."
end

def run(cmd, silent: false)
  `#{cmd}#{" >& /dev/null" if silent}`
end

def header(msg)
  puts "-----------------"
  puts msg
  puts "-----------------"
end

def find_and_replace(files:, find:, replace_with:)
  Dir["#{files}"].each do |file|
    buff = File.read(file)
    buff.gsub!(find, replace_with)
    File.write(file, buff)
  end
end

def append_to_file(dest:, file: nil, string: nil, after: nil)
  raise "Neither a file nor a string were given" unless file || string
  dest_content  = File.read(dest)
  content       = file ? File.read(file) : string
  short_content = file ? file : string[0..25]

  if dest_content.include? content
    say "#{dest} already contains #{short_content}"
  else
    if after
      dest_content.gsub!(after, "\\0#{content}")
      File.open(dest, "w") {|f| f.puts dest_content }
    else
      File.open(dest, "a") {|f| f.puts content }
    end

    say "Wrote #{short_content} to #{dest}"
  end
end


