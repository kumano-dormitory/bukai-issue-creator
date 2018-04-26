require 'io/console'
require 'octokit'

API_KEY='4684849ce5845562dfaad29b91f50b3d88aee5d1'.freeze
REPOSITORY='genya0407/kumano-tasks'.freeze

class KumaTasks
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

KumaTasks.new.issues_grouped_by_label.each do |label_name, issues|
  puts "## #{label_name}"
  if issues.empty?
    puts 'issueなし'
  else
    issues.each do |issue|
      puts "- [ ] #{issue.title}(#{issue.html_url})"
    end
  end
  puts ''
end
