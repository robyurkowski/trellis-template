################################################################################
# Constants
################################################################################
ROOT_PATH       = File.expand_path("../", __FILE__)
TRELLIS_FOLDER  = File.join(ROOT_PATH, "provision")
BEDROCK_FOLDER  = File.join(ROOT_PATH, "site")

BASE_REPO       = "https://github.com/robyurkowski/trellis-template.git"
TRELLIS_REPO    = "https://github.com/roots/trellis.git"
BEDROCK_REPO    = "https://github.com/roots/bedrock.git"


################################################################################
# Helpers
################################################################################
def ask(question)
  print "#{question} "
  gets.chomp
end

def branch_and_sync(repo:, dest:)

  `git checkout -b upgrade`
  `git clone --depth=1 #{repo} upgrade`
  `rm -rf upgrade/.git`
  `rsync -ah --progress upgrade/ #{dest}`
  `rm -rf upgrade`

  all_done "Now review the changes, discarding any that might overwrite your own local changes.\n\nAfterward, commit the changes and merge into master. Then delete the update branch."
end

def all_done(msg)
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
  dest_content = File.read(dest)
  content      = file ? File.read(file) : string
  short_content = file ? file : string[0..25]

  if dest_content.include? content
    puts "- #{dest} already contains #{short_content}"
  else
    if after
      dest_content.gsub!(after, /\0#{after}/)
      File.open(dest, "w") {|f| f.puts content }
    else
      File.open(dest, "a") {|f| f.puts content }
    end

    puts "- Wrote #{short_content} to #{dest}"
  end
end


################################################################################
# Bootstrap
################################################################################
namespace :bootstrap do
  desc "Cleans and preps base folder after a successful clone"
  task :base do
    `rm -rf #{ROOT_PATH}/.git`
    `git init`
  end

  desc "Downloads trellis."
  task :trellis do
    unless File.exist?(TRELLIS_FOLDER)
      `git clone --depth=1 #{TRELLIS_REPO} #{TRELLIS_FOLDER}`
      `rm -rf #{TRELLIS_FOLDER}/.git`
    end
  end

  desc "Downloads bedrock."
  task :bedrock do
    unless File.exist?(BEDROCK_FOLDER)
      `git clone --depth=1 #{BEDROCK_REPO} #{BEDROCK_FOLDER}`
      `rm -rf #{BEDROCK_FOLDER}/.git`
    end
  end

  desc "Injects non-default modules and variables into trellis files."
  task :inject_extras do
    injections = {
      "additional_requirements.yml" => ["provision/requirements.yml"],
      "additional_roles.yml" => ["provision/server.yml", ],
      "additional_vars.yml" => [
        "provision/group_vars/production/wordpress_sites.yml",
        "provision/group_vars/staging/wordpress_sites.yml",
        "provision/group_vars/development/wordpress_sites.yml",
      ],
    }

    injections.each do |file, destinations|
      destinations.each do |dest|
        append_to_file(dest: dest, file: "templates/#{file}")
      end
    end
  end

  desc "Downloads and installs all trellis requirements."
  task build_trellis_deps: [:trellis] do
    `cd #{TRELLIS_FOLDER} && ansible-galaxy install -r requirements.yml`
  end

  desc "Injects a vault pass file."
  task inject_vault_pass_file: [:trellis] do
    vault_pass_file = ask "Where would you like to write the vault pass to?"
    vault_pass = ask "What's the password?"
    File.write(File.expand_path(vault_pass_file), vault_pass)

    append_to_file(
      dest: "#{TRELLIS_FOLDER}/ansible.cfg",
      string: "vault_password_file = #{vault_pass_file}",
      after: /\[defaults\]/
    )
  end

  # desc "Substitutes any example.com or example.dev for the given domain."
  # task sub_domains: [:trellis] do
  # end


  task default: [:base, :trellis, :bedrock, :inject_extras, :build_trellis_deps]
end

desc "Completely loads the project from just this Rakefile."
task :bootstrap => 'bootstrap:default'


################################################################################
# Update
################################################################################
namespace :update do
  desc "Updates trellis."
  task :trellis do
    branch_and_sync(repo: TRELLIS_REPO, dest: TRELLIS_FOLDER)
  end

  desc "Updates bedrock."
  task :bedrock do
    branch_and_sync(repo: BEDROCK_REPO, dest: BEDROCK_FOLDER)
  end

  desc "Updates base rakefile."
  task :base do
    branch_and_sync(repo: BASE_REPO, dest: ROOT_PATH)
  end
end
