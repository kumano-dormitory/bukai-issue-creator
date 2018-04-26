module KumanoTasks
  class GithubWriter
    def initialize(api_key, repository_name)
      @api_key = api_key
      @repository_name = repository_name
      @client = Octokit::Client.new(access_token: @api_key)
    end

    def generate_markdown_string(issues_grouped_by_label)
      result = ''
      issues_grouped_by_label.each do |label_name, issues|
        result += "## #{label_name}\n\n"
        if issues.empty?
          result += "issueなし\n"
        else
          issues.each do |issue|
            result += "- [ ] #{issue.title}(#{issue.html_url})\n"
          end
        end
        result += "\n"
      end

      return result
    end
  end
end