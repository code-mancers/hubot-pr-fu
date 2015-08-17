require 'octokit'

GH_AUTH_TOKEN        = ENV["GH_AUTH_TOKEN"]
HUBOT_VT_GITHUB_ORG  = ENV["HUBOT_VT_GITHUB_ORG"]
HUBOT_VT_GITHUB_REPO = ENV["HUBOT_VT_GITHUB_REPO"]

Octokit.default_media_type = "application/vnd.github.beta+json"


client = Octokit::Client.new access_token: GH_AUTH_TOKEN
repo   = client.repo "veritrans/turbo"
pulls  = repo.rels[:pulls].get.data

open_pulls        = pulls.select { |x| x[:state] = "open" }


aggregated_data = open_pulls.map do |pull|
  pull_request_data = pull.rels[:self].get.data
  {
    title: pull_request_data[:title],
    mergeable: pull_request_data[:mergeable] || "Unspecified",
    assignee: pull_request_data[:assignee] || "Not assigned",
    number: pull_request_data[:number],
    opened_by: pull_request_data[:user][:login],
    html_url: pull_request_data[:html_url],
    created_at: pull_request_data[:created_at]
  }
end

mergeable_pulls   = aggregated_data.select { |x| x[:mergeable] == true }
unmergeable_pulls = aggregated_data.select { |x| x[:mergeable] != true }

puts <<EOF
  Mergeable PRs       : #{mergeable_pulls.count}
  PRs with conflicts  : #{unmergeable_pulls.count}
EOF

unmergeable_pulls.each do |pull|
puts "\n\n"
puts <<EOF
  #{pull[:number]} #{pull[:title]}
  Assigned to : #{pull[:assignee]}
  Opened by   : #{pull[:opened_by]}
EOF
end

# Stats
#
# Mergeable PRs      :  8
# PRs with conflicts :  5
#
# PRs with conflicts:
#
# <number> <title>
# Assigned to: <name>
# Opened by: <name>