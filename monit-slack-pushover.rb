#!/usr/bin/ruby

require 'net/https'
require 'json'

slack_hostname="%SLACK_HOSTNAME%"
slack_api_key="%SLACK_API_KEY%"
slack_channel="%SLACK_CHANNEL%"
pushover_application="%PUSHOVER_APPLICATION%"
pushover_user="%PUSHOVER_USER%"

uri = URI.parse("https://#{slack_hostname}.slack.com/services/hooks/incoming-webhook?token=#{slack_api_key}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
request.body = {
    "channel"  => slack_channel,
    "username" => "mmonit",
    "text"     => "[#{ENV['MONIT_HOST']}] #{ENV['MONIT_SERVICE']} - #{ENV['MONIT_DESCRIPTION']}"
}.to_json
response = http.request(request)
puts response.body

uri = URI.parse("https://api.pushover.net/1/messages.json")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'multipart/form-data'})
request.set_form_data("token" => pushover_application, "user" => pushover_user, "message" => "[#{ENV['MONIT_HOST']}] #{ENV['MONIT_SERVICE']} - #{ENV['MONIT_DESCRIPTION']}")
response = http.request(request)
puts response.body
