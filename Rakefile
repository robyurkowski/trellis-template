TRELLIS_REPO    = "https://github.com/roots/trellis.git"
TRELLIS_FOLDER  = "provision"
BEDROCK_REPO    = "https://github.com/roots/bedrock.git"
BEDROCK_FOLDER  = "site"

namespace :bootstrap do
  desc "Downloads trellis."
  task :trellis do
    `git clone --depth=1 #{TRELLIS_REPO} #{TRELLIS_FOLDER}`
    `rm -rf #{TRELLIS_FOLDER}/.git`
  end

  desc "Downloads bedrock."
  task :bedrock do
    `git clone --depth=1 #{BEDROCK_REPO} #{BEDROCK_FOLDER}`
    `rm -rf #{BEDROCK_FOLDER}/.git`
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
        dest_content = File.read(dest)
        file_content = File.read("templates/#{file}")

        if dest_content.include? file_content
          puts "- #{dest} already contains #{file}"
        else
          File.open("templates/#{file}", "a") {|f| f.puts file_content }
          puts "- Wrote #{file} to #{dest}"
        end
      end
    end
  end

  desc "Downloads and installs all trellis requirements."
  task build_trellis_deps: [:trellis] do
    `cd #{TRELLIS_FOLDER} && ansible-galaxy install -r requirements.yml`
  end

  task default: [:trellis, :bedrock, :inject_extras, :build_trellis_deps]
end

desc "Completely loads the project from just this Rakefile."
task :bootstrap => 'bootstrap:default'

namespace :update do
  desc "Updates trellis."
  task :trellis do
    `git checkout -b update-trellis`
    `git clone --depth=1 #{TRELLIS_REPO} trellis_upgrade`
    `rm -rf trellis_upgrade/.git`
    `rsync -ah --progress trellis_upgrade/ #{TRELLIS_FOLDER}`
    `rm -rf trellis_upgrade`

    puts "-----------------"
    puts "Now review the changes, discarding any that might overwrite your own local changes."
    puts ""
    puts "Afterward, commit the changes and merge into master. Then delete the update-trellis branch."
    puts "-----------------"
  end
end

