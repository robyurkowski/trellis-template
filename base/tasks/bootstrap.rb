require 'fileutils'

namespace :bootstrap do

  desc "Cleans and preps base folder after a successful clone"
  task :base do
    say "Cleaning up .git"
    run "rm -rf #{ROOT_PATH}/.git"
    run "git init"
  end


  desc "Downloads trellis."
  task :trellis do
    unless File.exist?(TRELLIS_FOLDER)
      say "Cloning into #{TRELLIS_FOLDER}"
      run "git clone --depth=1 #{TRELLIS_REPO} #{TRELLIS_FOLDER}", silent: true
      run "rm -rf #{TRELLIS_FOLDER}/.git", silent: true
    end
  end


  desc "Downloads bedrock."
  task :bedrock do
    unless File.exist?(BEDROCK_FOLDER)
      say "Cloning into #{BEDROCK_FOLDER}"
      run "git clone --depth=1 #{BEDROCK_REPO} #{BEDROCK_FOLDER}", silent: true
      run "rm -rf #{BEDROCK_FOLDER}/.git", silent: true
    end
  end

  desc "Does initial commit"
  task git: [:bedrock, :trellis] do
    say "Doing initial commit"
    run "git add --all"
    run "git commit -m 'Initial commit.'"
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
    say "Installing trellis requirements"
    run "cd #{TRELLIS_FOLDER} && ansible-galaxy install -r requirements.yml", silent: true
  end


  desc "Injects a vault pass file."
  task inject_vault_pass_file: [:trellis] do
    default_pass_file = "~/.vault/#{File.basename(ROOT_PATH)}"
    vault_pass_file   = ask "Where would you like to write the vault pass to?", default: default_pass_file
    vault_pass        = ask "What's the password?"

    expanded_path = File.expand_path(vault_pass_file)
    FileUtils.mkdir_p(File.dirname(expanded_path))
    File.write(File.expand_path(vault_pass_file), vault_pass)

    append_to_file(
      dest: "#{TRELLIS_FOLDER}/ansible.cfg",
      string: "vault_password_file = #{vault_pass_file}\n",
      after: /\[defaults\]\n/
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
      replace_with: SITE_NAME_DEV
    )

    find_and_replace(
      files: "README.md",
      find: /example\.com/,
      replace_with: domain
    )

    find_and_replace(
      files: "Rakefile",
      find: /example\.com/,
      replace_with: domain
    )
  end


  desc "Sets important variables."
  task configure_defaults: [:trellis] do
    smtp_password      = ask "SMTP Password?", default: ""
    mail_sender        = ask "Send mail as?", default: "admin@#{SITE_NAME}"
    dev_admin_email    = ask "Admin email (development)?", default: "admin@#{SITE_NAME_DEV}"
    dev_admin_password = ask "Admin password (development)?", default: "admin"
    prod_admin_password = ask "Sudo password? (production / staging)?", default: "example_password"

    list_of_files = {
      "#{TRELLIS_FOLDER}/Vagrantfile" => {
        # Set machine name
      },

      "#{TRELLIS_FOLDER}/hosts/production" => {
        %r{your_server_hostname} => %Q{#{SITE_NAME}},
      },

      "#{TRELLIS_FOLDER}/group_vars/all/mail.yml" => {
        %r{(mail_smtp_server): smtp.#{SITE_NAME}:587} => %Q{\\1: smtp.mailgun.org:587},
        %r{(mail_admin): admin@#{SITE_NAME}} => %Q{\\1: #{mail_sender}}, # mail_admin: admin@<your domain>
        %r{(mail_hostname): #{SITE_NAME}} => %Q{\\1: mail.#{SITE_NAME}},
        %r{(mail_user): smtp_user} => %Q{\\1: postmaster@mail.ridgewaydigital.com},
      },

      "#{TRELLIS_FOLDER}/group_vars/all/security.yml" => {
        %r{(sshd_permit_root_login): true}    => %Q{\\1: false},
      },

      "#{TRELLIS_FOLDER}/group_vars/all/vault.yml" => {
        %r{(vault_mail_password): smtp_password} => %Q{\\1: #{smtp_password}},

      },

      "#{TRELLIS_FOLDER}/group_vars/development/vault.yml" => {
        %r{(vault_mysql_root_password): devpw} => %Q{\\1: #{generate_password}},
        %r{(admin_password:): admin} => %Q{\\1: #{dev_admin_password}},
        %r{(db_password): example_dbpassword} => %Q{\\1: #{generate_password}},
      },

      "#{TRELLIS_FOLDER}/group_vars/development/wordpress_sites.yml" => {
        %r{(admin_email): admin@#{SITE_NAME_DEV}} => %Q{\\1: #{dev_admin_email}},
        # webhook url - only prod?
        # backup target
      },

      "#{TRELLIS_FOLDER}/group_vars/production/vault.yml" => {
        %r{(vault_mysql_root_password): productionpw} => %Q{\\1: #{generate_password}},
        %r{(password): example_password}              => %Q{\\1: #{prod_admin_password}},
        %r{(salt): "generateme"}                     => %Q{\\1: "#{generate_password}"},
        %r{(db_password): example_dbpassword}         => %Q{\\1: #{generate_password}},
        %r{(auth_key): "generateme"}                  => %Q{\\1: "#{generate_password}"},
        %r{(secure_auth_key): "generateme"}           => %Q{\\1: "#{generate_password}"},
        %r{(logged_in_key): "generateme"}             => %Q{\\1: "#{generate_password}"},
        %r{(nonce_key): "generateme"}                 => %Q{\\1: "#{generate_password}"},
        %r{(auth_salt): "generateme"}                 => %Q{\\1: "#{generate_password}"},
        %r{(secure_auth_salt): "generateme"}          => %Q{\\1: "#{generate_password}"},
        %r{(logged_in_salt): "generateme"}            => %Q{\\1: "#{generate_password}"},
        %r{(nonce_salt): "generateme"}                => %Q{\\1: "#{generate_password}"},
        # add backup_target_user / backup_target_pass
      },

      "#{TRELLIS_FOLDER}/group_vars/production/wordpress_sites.yml" => {
        %r{(repo: git@github.com:)example/example.com.git} => %Q{\\1robyurkowski/#{SITE_NAME}.git},
        %r{(ssl:\s+enabled): false} => %Q{\\1: true},
        # backups stuff
        # Webhook
      },

      "#{TRELLIS_FOLDER}/group_vars/staging/vault.yml" => {
        %r{(vault_mysql_root_password): stagingpw} => %Q{\\1: #{generate_password}},
        %r{(password): example_password}           => %Q{\\1: #{prod_admin_password}},
        %r{(salt): "generateme"}                   => %Q{\\1: "#{generate_password}"},
        %r{(db_password): example_dbpassword}      => %Q{\\1: #{generate_password}},
        %r{(auth_key): "generateme"}               => %Q{\\1: "#{generate_password}"},
        %r{(secure_auth_key): "generateme"}        => %Q{\\1: "#{generate_password}"},
        %r{(logged_in_key): "generateme"}          => %Q{\\1: "#{generate_password}"},
        %r{(nonce_key): "generateme"}              => %Q{\\1: "#{generate_password}"},
        %r{(auth_salt): "generateme"}              => %Q{\\1: "#{generate_password}"},
        %r{(secure_auth_salt): "generateme"}       => %Q{\\1: "#{generate_password}"},
        %r{(logged_in_salt): "generateme"}         => %Q{\\1: "#{generate_password}"},
        %r{(nonce_salt): "generateme"}             => %Q{\\1: "#{generate_password}"},
        # add backup_target_user / backup_target_pass
      },

      "#{TRELLIS_FOLDER}/group_vars/staging/wordpress_sites.yml" => {
        %r{(repo: git@github.com:)example/example.com.git} => %Q{\\1robyurkowski/#{SITE_NAME}.git},
        # backups stuff
        # Webhook
        # see prod
      },
    }

    list_of_files.each do |file, replacements|
      replacements.each do |to_find, replace_with|
        find_and_replace(
          files: file,
          find: to_find,
          replace_with: replace_with
        )
      end
    end
  end


  desc "Encrypts vault files."
  task encrypt_vault_files: [:trellis] do
    Dir["#{TRELLIS_FOLDER}/group_vars/**/vault.yml"].each do |file|
      file = "./#{file.gsub(TRELLIS_FOLDER + '/', '')}"
      run "cd #{TRELLIS_FOLDER} && ansible-vault encrypt #{file.gsub(TRELLIS_FOLDER, '')}"
    end
  end


  desc "Decrypts vault files."
  task decrypt_vault_files: [:trellis] do
    Dir["#{TRELLIS_FOLDER}/group_vars/**/vault.yml"].each do |file|
      file = "./#{file.gsub(TRELLIS_FOLDER + '/', '')}"
      run "cd #{TRELLIS_FOLDER} && ansible-vault decrypt #{file.gsub(TRELLIS_FOLDER, '')}"
    end
  end


  desc "Adds common plugins."
  task install_plugins: [:trellis] do
    plugins = [
      ["wpackagist-plugin/email-marketing", "^1.0"],
      ["wpackagist-plugin/wordpress-seo", "^5.1.0"],
      ["wpackagist-plugin/all-in-one-wp-security-and-firewall", "^4.2.8"],
      ["wpackagist-plugin/google-analytics-dashboard-for-wp", "^5.1.1.1"],
      ["wpackagist-plugin/insert-headers-and-footers", "^1.4"],
    ]

    plugins.each do |(plugin, version)|
      append_to_file(
        dest: "#{BEDROCK_FOLDER}/composer.json",
        string: %Q{    "#{plugin}": "#{version}",\n},
        after: /"require": \{\n/
      ) if confirm "Add #{plugin}?"
    end
  end


  desc "Vagrant ups."
  task vagrant_up: [:trellis] do
    run "cd #{TRELLIS_FOLDER} && vagrant up"
  end


  task default: [
    :base,
    :trellis,
    :bedrock,
    :git,
    :inject_extras,
    :build_trellis_deps,
    :inject_vault_pass_file,
    :sub_domains,
    :configure_defaults,
    :encrypt_vault_files,
    :install_plugins,
    :vagrant_up,
  ]
end

desc "Completely loads the project from just this Rakefile."
task :bootstrap => 'bootstrap:default'
