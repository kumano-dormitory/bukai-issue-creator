$LOAD_PATH.push('./lib')

require 'kumano_tasks'
require 'sinatra'
require 'rack/ssl-enforcer'
require 'dotenv/load'

API_KEY=ENV['API_KEY'].freeze
REPOSITORY=ENV['REPOSITORY'].freeze
USERNAME=ENV['USERNAME'].freeze
PASSWORD=ENV['PASSWORD'].freeze

use Rack::SslEnforcer if production?

use Rack::Auth::Basic do |username, password|
  username == USERNAME && password == PASSWORD
end

get '/' do
  erb :index
end

post '/create_issue' do
  reader = KumanoTasks::GithubReader.new
  writer = KumanoTasks::GithubWriter.new(API_KEY, REPOSITORY)
  new_issue = writer.create_issue(reader.issues_grouped_by_label)

  sleep 1 # in order to avoid 404 issue not found error.

  redirect new_issue.html_url
end
