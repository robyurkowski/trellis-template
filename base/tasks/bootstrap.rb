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
        append_to_file(dest: dest, file: "base/templates/#{file}")
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


  desc "Substitutes any example.com or example.dev for the given domain."
  task sub_domains: [:trellis] do
    domain = ask "What domain are you using?"

    find_and_replace(
      files: "#{TRELLIS_FOLDER}/group_vars/**/*.yml",
      find: /example\.com/,
      replace_with: domain
    )

    find_and_replace(
      files: "#{TRELLIS_FOLDER}/group_vars/**/*.yml",
      find: /example\.dev/,
      replace_with: domain
    )

    find_and_replace(
      files: "README.md",
      find: /example\.com/,
      replace_with: domain
    )
  end


  desc "Encrypts vault files."
  task encrypt_vault_files: [:trellis] do
    Dir["#{TRELLIS_FOLDER}/group_vars/**/vault.yml"].each do |file|
      file = file.split("/")[1..-1].join("/")
      `cd #{TRELLIS_FOLDER} && ansible-vault encrypt #{file}`
    end
  end


  task default: [:base, :trellis, :bedrock, :inject_extras, :build_trellis_deps, :inject_vault_pass_file, :sub_domains, :encrypt_vault_files]
end

desc "Completely loads the project from just this Rakefile."
task :bootstrap => 'bootstrap:default'
