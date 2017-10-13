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
