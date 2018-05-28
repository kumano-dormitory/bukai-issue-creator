require 'date'
require 'octokit'

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
      result = ''
      issues_grouped_by_label.each do |label_name, issues|
        result += "## #{label_name}\n\n"
        if issues.empty?
          result += "issueなし\n"
        else
          issues.each do |issue|
            assignees = issue.assignees.nodes.map(&:login).map {|name| "@#{name}"}.join(', ')
            result += "- [ ] #{issue.url} #{issue.title} (#{assignees})\n"
          end
        end
        result += "\n"
      end

      return result
    end
  end
end

if __FILE__ == $0
  require_relative './github_reader'
  reader = KumanoTasks::GithubReader.new
  markdown_string = KumanoTasks::GithubWriter.new(nil, nil).generate_markdown_string(reader.issues_grouped_by_label)
  puts markdown_string
end
