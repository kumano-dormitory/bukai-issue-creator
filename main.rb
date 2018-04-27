$LOAD_PATH.push('./lib')

require 'kumano_tasks'
require 'sinatra'

API_KEY=ENV['API_KEY'].freeze
REPOSITORY=ENV['REPOSITORY'].freeze
USERNAME=ENV['USERNAME'].freeze
PASSWORD=ENV['PASSWORD'].freeze

use Rack::Auth::Basic do |username, password|
  username == USERNAME && password == PASSWORD
end

get '/' do
  erb :index
end

post '/create_issue' do
  reader = KumanoTasks::GithubReader.new(API_KEY, REPOSITORY)
  writer = KumanoTasks::GithubWriter.new(API_KEY, REPOSITORY)
  new_issue = writer.create_issue(reader.issues_grouped_by_label)

  redirect new_issue.html_url
end
