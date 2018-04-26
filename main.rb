require 'io/console'
require 'octokit'
require 'dotenv/load'

API_KEY=ENV['API_KEY'].freeze
REPOSITORY=ENV['REPOSITORY'].freeze

class KumanoTasks
  def initialize
    @client = Octokit::Client.new(access_token: API_KEY)
  end

  def client
    @client
  end

  def issues
    @issues ||= client.issues(REPOSITORY)
  end

  def section_labels
    @section_labels ||= client.labels(REPOSITORY).select do |label|
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
end

KumanoTasks.new.issues_grouped_by_label.each do |label_name, issues|
  puts "## #{label_name}"
  puts ''
  if issues.empty?
    puts 'issueなし'
  else
    issues.each do |issue|
      puts "- [ ] #{issue.title}(#{issue.html_url})"
    end
  end
  puts ''
end
