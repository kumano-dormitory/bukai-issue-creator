$LOAD_PATH.push('./lib')

require 'kumano_tasks'

API_KEY=ENV['API_KEY'].freeze
REPOSITORY=ENV['REPOSITORY'].freeze

KumanoTasks::GithubReader.new(API_KEY, REPOSITORY).issues_grouped_by_label.each do |label_name, issues|
  result = ''
  result += "## #{label_name}\n\n"
  if issues.empty?
    result += "issueなし\n"
  else
    issues.each do |issue|
      result += "- [ ] #{issue.title}(#{issue.html_url})\n"
    end
  end
  result += "\n"
  puts result
end
