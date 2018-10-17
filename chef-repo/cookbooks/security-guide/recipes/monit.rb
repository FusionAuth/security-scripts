#
# Cookbook Name:: security_guide
# Recipe:: default
#
# Copyright (c) 2018 FusionAuth, All Rights Reserved.

# Validate the attributes
unless node['security_guide']['monit'].attribute?('alert_email')
  Chef::Application.fatal!('You must specify an alert email for Monit')
end

# Install all the security packages
package 'monit'
package 'ruby'

# Install the Monit configuration for generating alerts on SSH logins
cookbook_file '/etc/monit/conf.d/ssh-logins' do
  source 'ssh-logins'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install the main Monit configuration file that sends the emails
template '/etc/monit/monitrc' do
  source 'monitrc.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install the Monit script to send alerts to Slack and Pushover
template '/etc/monit/monit-slack-pushover.rb' do
  source 'monit-slack-pushover.rb.erb'
  owner 'root'
  group 'root'
  mode '0700'
end

# Restart the Monit service
service 'monit' do
  action :restart
end
