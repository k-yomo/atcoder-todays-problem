require 'faraday'
require 'faraday_middleware'
require 'json'

slack_webhook_url = ENV["SLACK_WEBHOOK_URL"]
sheet_db_api_id = ENV["SHEET_DB_API_ID"]

http_client = Faraday.new do |faraday|
    faraday.request :json
    faraday.response :json, :parser_options => { :symbolize_names => true }, :content_type => /\bjson$/
    faraday.adapter Faraday.default_adapter
end

response = http_client.get("https://kenkoooo.com/atcoder/resources/problem-models.json")
raise "Failed to fetch problem list" if !response.success?
problems = response.body
target_problems = response.body
    .select{|problem_id, diff_info|
       diff_info[:difficulty] && diff_info[:difficulty] >= 600 && diff_info[:difficulty] <= 1400
    }
    .each{|problem_id, _| problems[problem_id][:ac_count] = 0}

response = http_client.get("https://sheetdb.io/api/v1/#{sheet_db_api_id}")
raise "Failed to fetch user ids" if !response.success?
users = response.body
users_acs = users.map { |user|
    user_id = user[:user_id]
    response = http_client.get("https://kenkoooo.com/atcoder/atcoder-api/results?user=#{user_id}")
    if response.success?
        response.body
            .select{|sub| sub[:result] == "AC"}
            .uniq{|sub| [sub[:problem_id], sub[:user_id]]}
    else
        nil
    end
}.compact.flatten

users_acs.each do |ac|
    problem_id = ac[:problem_id].to_sym
    target_problems[problem_id][:ac_count] += 1 if target_problems[problem_id]
end

ac_count, least_solved_problems = target_problems.group_by{|problem_id, _| target_problems[problem_id][:ac_count]}.sort[0]

raise "All candidate problems are solved by all members!" if ac_count == users.length

todays_problem_id = least_solved_problems.sample[0]
todays_problem_diff = target_problems[todays_problem_id][:difficulty]

response = http_client.get("https://kenkoooo.com/atcoder/resources/merged-problems.json")
raise "Failed to fetch problem information" if !response.success?

todays_problem = response.body.find {|problem| problem[:id] == todays_problem_id.to_s}
todays_problem[:difficulty] = todays_problem_diff

puts "todays_problem is "
pp todays_problem

diff_color_emoji = case todays_problem[:difficulty]
          when 0..399 then ":atcoder_grey:"
          when 400..799 then ":atcoder_brown:"
          when 800...1199 then ":atcoder_green:"
          when 1200...1599 then ":atcoder_cyan:"
          when 1600...1999 then ":atcoder_blue:"
          when 2000...2399 then ":atcoder_yellow:"
          when 2400...2799 then ":atcoder_orange:"
          else ":atcoder_red:"
          end

response = http_client.post do |req|
    req.url slack_webhook_url
    req.body = {
        blocks: [
            {
                type: :section,
                text: {
                    type: :plain_text,
                    text: "今日の一問はこれだ！！:dart:",
                    emoji: true
                }
            },
            {
                type: :section,
                text: {
                    type: :mrkdwn,
                    text: "#{diff_color_emoji} *<https://atcoder.jp/contests/#{todays_problem[:contest_id]}/tasks/#{todays_problem[:id]}|#{todays_problem[:contest_id]} - #{todays_problem[:title]}>* \n得点: #{todays_problem[:point] ? todays_problem[:point].to_i : '-'} \ndiff: #{todays_problem[:difficulty]}"
                },
            },
            {
                type: :divider
            },
            {
                type: :actions,
                elements: [
                    {
                        type: :button,
                        text: {
                            type: :plain_text,
                            text: "解く",
                            emoji: true
                        },
                        url: "https://atcoder.jp/contests/#{todays_problem[:contest_id]}/tasks/#{todays_problem[:id]}"
                    },
                ]
            }
        ]
    }
end
raise "Failed to send message to Slack" if !response.success?

