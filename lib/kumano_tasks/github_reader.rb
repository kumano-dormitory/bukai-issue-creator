require 'octokit'
require 'dotenv/load'

module KumanoTasks
  class GithubReader
    def initialize(api_key, repository_name)
      @api_key = api_key
      @repository_name = repository_name
      @client = Octokit::Client.new(access_token: @api_key)
    end

    def client
      @client
    end

    def issues(since: (Date.today - 7).to_time) # 7 days ago
      @issues ||= open_issues + closed_updated_issues(since)
    end

    def section_labels
      @section_labels ||= client.labels(@repository_name).select do |label|
        label.name.match(/セクション/)
      end
    end

    def issues_grouped_by_label
      grouped_issues = [*section_labels.map(&:name), 'その他'].map do |name|
        [name, []]
      end.to_h
      issues.each do |issue|
        label = section_labels.find { |section_label| issue.labels.any? { |issue_label| issue_label.id == section_label.id } }
        if label.nil?
          grouped_issues['その他'].push(issue)
        else
          grouped_issues[label.name].push(issue)
        end
      end
      grouped_issues
    end

    private
    def open_issues
      client.issues(@repository_name)
    end

    def closed_updated_issues(since)
      client.issues(@repository_name, state: :closed).select { |issue|
        issue.updated_at > since
      }
    end
  end
end
