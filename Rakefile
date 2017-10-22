SITE_NAME       = "example.com".freeze
ROOT_PATH       = File.expand_path("../", __FILE__)
TRELLIS_FOLDER  = File.join(ROOT_PATH, "provision")
BEDROCK_FOLDER  = File.join(ROOT_PATH, "site")
REMOTE_APP_FOLDER = "/srv/www/#{SITE_NAME}/current/"

BASE_REPO       = "https://github.com/robyurkowski/trellis-template.git"
TRELLIS_REPO    = "https://github.com/roots/trellis.git"
BEDROCK_REPO    = "https://github.com/roots/bedrock.git"

$: << ROOT_PATH
require 'base/operations'
require 'base/tasks/bootstrap'
require 'base/tasks/update'
require 'base/tasks/dev'
