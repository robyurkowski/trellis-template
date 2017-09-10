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
