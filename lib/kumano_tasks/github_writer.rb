require 'date'
require 'octokit'
require 'erb'

module KumanoTasks
  class GithubWriter
    def initialize(api_key, repository_name)
      @api_key = api_key
      @repository_name = repository_name
      @client = Octokit::Client.new(access_token: @api_key)
    end

    def create_issue(issues_grouped_by_label)
      ENV['TZ'] = 'Asia/Tokyo'
      title = "#{Date.today.strftime('%m/%d')}の部会"
      body = generate_markdown_string(issues_grouped_by_label)
      @client.create_issue(@repository_name, title, body)
    end

    def generate_markdown_string(issues_grouped_by_label)
      filename = File.join(File.dirname(__FILE__), './issue.md.erb')
      erb = ERB.new(File.read(filename))

      return erb.result(binding)
    end
  end
end

if __FILE__ == $0
  require_relative './github_reader'
  reader = KumanoTasks::GithubReader.new
  markdown_string = KumanoTasks::GithubWriter.new(nil, nil).generate_markdown_string(reader.issues_grouped_by_label)
  puts markdown_string
end
