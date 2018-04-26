$LOAD_PATH.push('./lib')

require 'kumano_tasks'

API_KEY=ENV['API_KEY'].freeze
REPOSITORY=ENV['REPOSITORY'].freeze

reader = KumanoTasks::GithubReader.new(API_KEY, REPOSITORY)
writer = KumanoTasks::GithubWriter.new(API_KEY, REPOSITORY)
puts writer.generate_markdown_string(reader.issues_grouped_by_label)
