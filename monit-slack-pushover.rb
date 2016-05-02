#!/usr/bin/ruby

require 'net/https'
require 'json'

slack_webhook_url="%SLACK_WEBHOOK_URL%"
slack_enabled=%SLACK_ENABLED%
pushover_application="%PUSHOVER_APPLICATION%"
pushover_user="%PUSHOVER_USER%"
pushover_enabled=%PUSHOVER_ENABLED%

if slack_enabled
  uri = URI.parse(slack_webhook_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
  request.body = {
      "text" => "[#{ENV['MONIT_HOST']}] #{ENV['MONIT_SERVICE']} - #{ENV['MONIT_DESCRIPTION']}"
  }.to_json
  response = http.request(request)
  open('/var/log/monit.log', 'a') { |f|
    f.puts "Response from Slack [#{response.code}] [#{response.body}]"
  }
end

if pushover_enabled
  uri = URI.parse("https://api.pushover.net/1/messages.json")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'multipart/form-data'})
  request.set_form_data("token" => pushover_application, "user" => pushover_user, "message" => "[#{ENV['MONIT_HOST']}] #{ENV['MONIT_SERVICE']} - #{ENV['MONIT_DESCRIPTION']}")
  response = http.request(request)
  open('/var/log/monit.log', 'a') { |f|
    f.puts "Response from Pushover [#{response.code}] [#{response.body}]"
  }
end