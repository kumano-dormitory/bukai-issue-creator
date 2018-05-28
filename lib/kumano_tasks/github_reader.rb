require 'dotenv/load'
require "graphql/client"
require "graphql/client/http"
require 'date'
require 'time'

module KumanoTasks
  module GithubGraphQL
    HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
      def headers(context)
        { "Authorization" => "bearer #{ENV['API_KEY']}" }
      end
    end
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end

  class GithubReader
    def self.since
      (Date.today - 7).to_time # 7 days ago
    end

    def self.timeline_event_queries
      event_types = GithubGraphQL::Schema.as_json['data']['__schema']['types']
                                         .find { |t| t['name'] == 'IssueTimelineItem' }['possibleTypes']
                                         .select { |t| t['name'] != 'Commit' } .map { |t| t['name'] }

      event_types.map { |t| "... on #{t} { createdAt }" }.join(",\n")
    end

    OpenIssues = GithubGraphQL::Client.parse <<-QUERY
      query {
        repository(owner: "#{ENV['OWNER']}", name: "#{ENV['REPOSITORY_NAME']}") { 
          issues(last: 100, states: [OPEN]) {
            nodes {
              title,
              url,
              assignees(first: 10) {
                nodes {
                  login
                }
              },
              labels(first: 10) {
                nodes {
                  id,
                  name
                }
              }
            }
          }
        }
      }
    QUERY

    ClosedIssues = GithubGraphQL::Client.parse <<-QUERY
      query {
        repository(owner: "#{ENV['OWNER']}", name: "#{ENV['REPOSITORY_NAME']}") { 
          issues(first: 100, states: [CLOSED], orderBy: { direction: DESC, field: UPDATED_AT }) {
            nodes {
              title,
              url,
              assignees(first: 10) {
                nodes {
                  login
                }
              },
              labels(first: 10) {
                nodes {
                  id,
                  name
                }
              },
              timeline(last: 100, since: "#{self.since.iso8601}") {
                nodes {
                  #{self.timeline_event_queries}
                }
              }
            }
          }
        }
      }
    QUERY

    Labels = GithubGraphQL::Client.parse <<-QUERY
      query {
        repository(owner: "#{ENV['OWNER']}", name: "#{ENV['REPOSITORY_NAME']}") {
          labels(first: 100) {
            nodes {
              id,
              name
            }
          }
        }
      }
    QUERY

    def issues
      @issues ||= open_issues + closed_updated_issues
    end

    def section_labels
      @section_labels ||= GithubGraphQL::Client.query(Labels).data.repository.labels.nodes.select do |label|
        label.name.match(/セクション/) || label.name.match(/部長タスク/) || label.name.match(/会計タスク/)
      end
    end

    def issues_grouped_by_label
      grouped_issues = [*section_labels.map(&:name), 'その他'].map do |name|
        [name, []]
      end.to_h
      issues.each do |issue|
        label = section_labels.find { |section_label| issue.labels.nodes.any? { |issue_label| issue_label.id == section_label.id } }
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
      GithubGraphQL::Client.query(OpenIssues).data.repository.issues.nodes
    end

    def closed_updated_issues
      GithubGraphQL::Client.query(ClosedIssues).data.repository.issues.nodes.select do |issue|
        events_other_than_referenced = issue.timeline.nodes.select do |event|
          event.created_at? && Time.iso8601(event.created_at) > self.class.since
        end.select do |event|
          event.__typename != 'CrossReferencedEvent'
        end

        !events_other_than_referenced.empty?
      end
    end
  end
end

if __FILE__ == $0
  reader = KumanoTasks::GithubReader.new
  reader.issues_grouped_by_label.each do |label, issues|
    puts label
    issues.each do |issue|
      puts "    #{issue.title}"
    end
  end
end
