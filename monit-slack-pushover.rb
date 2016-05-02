#!/usr/bin/ruby

require 'net/https'
require 'json'

slack_webhook_url="%SLACK_WEBHOOK_URL%"
slack_enabled=%SLACK_ENABLED%
pushover_application="%PUSHOVER_APPLICATION%"
pushover_user="%PUSHOVER_USER%"
pushover_enabled=%PUSHOVER_ENABLED%

def log(message)
  open('/var/log/monit.log', 'a') { |f|
    f.puts message
  }
end

if slack_enabled
  begin
    uri = URI.parse(slack_webhook_url)
    Net::HTTP.start(uri.host, uri.port, {use_ssl: true}) { |http|
      request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
      request.body = {
          :text => "[#{ENV['MONIT_HOST']}] #{ENV['MONIT_SERVICE']} - #{ENV['MONIT_DESCRIPTION']}"
      }.to_json
      response = http.request(request)
      log("Response from Slack [#{response.code}] [#{response.body}]")
    }
  rescue Exception => e
    log("Exception while calling Slack [#{e.message}]")
  end
end

if pushover_enabled
  begin
    uri = URI.parse("https://api.pushover.net/1/messages.json")
    Net::HTTP.start(uri.host, uri.port, {use_ssl: true}) { |http|
      request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'multipart/form-data'})
      request.set_form_data(token: pushover_application, user: pushover_user, message: "[#{ENV['MONIT_HOST']}] #{ENV['MONIT_SERVICE']} - #{ENV['MONIT_DESCRIPTION']}")
      response = http.request(request)
      log("Response from Pushover [#{response.code}] [#{response.body}]")
    }
  rescue Exception => e
    log("Exception while calling Pushover [#{e.message}]")
  end
end