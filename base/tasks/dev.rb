namespace :dev do
  namespace :composer do
    desc "Runs composer install on the VM."
    task :install do
      run "vagrant ssh -- -t 'cd #{REMOTE_APP_FOLDER}; composer install'"
    end

    desc "Runs composer update on the VM."
    task :update do
      run "vagrant ssh -- -t 'cd #{REMOTE_APP_FOLDER}; composer update'"
    end
  end
end
