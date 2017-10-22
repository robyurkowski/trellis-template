namespjace :dev do
  namespace :composer do
    task :install do
      run "vagrant ssh -c 'cd #{REMOTE_APP_FOLDER} && composer install'"
    end

    task :update do
      run "vagrant ssh -c 'cd #{REMOTE_APP_FOLDER} && composer update'"
    end
  end
end
