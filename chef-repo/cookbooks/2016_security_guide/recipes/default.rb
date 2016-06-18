#
# Cookbook Name:: 2016_security_guide
# Recipe:: default
#
# Copyright (c) 2016 Inversoft, All Rights Reserved.

apt_≤update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

# Create the ordinary user
#  TODO - Set the password hash for the user here
user 'ordinary-user' do
  home '/home/orindary-user'
  shell '/bin/bash'
  passwd ''
end

# Add the ordinary user to the sudo group
group 'sudo' do
  action :modify
  members 'ordinary-user'
  append true
end

# Disable rot user's password
user 'root' do
  password '!'
  action :modify
end

# Setup SSH key's for the ordinary user
cookbook_file '/home/ordinary-user/.ssh/authorized_keys' do
  source 'authorized_keys'
  owner 'ordinary-user'
  group 'oridnary-user'
  mode '0600'
end
file '/home/ordinary-user/.ssh' do
  mode '0700'
end

# Install all the security packages
package 'libpam-cracklib'
package 'libpam-google-authenticator'
package 'ntp'
package 'monit'
package 'ruby'

# Configure the Debian answers for the iptables-persistent package
ruby_block 'debconf-iptables-persistent' do 
  block do
    `echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections`
    `echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections`
  end
  action :create
end
package 'iptables-persistent'

# Install the SSH server configuration file
cookbook_file '/etc/ssh/sshd_config' do
  source 'sshd_config'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install the PAM SSH configuration file for two-factor authentication
cookbook_file '/etc/pam.d/sshd' do
  source 'sshd'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install the IPTables IPv4 configuration file
cookbook_file '/etc/iptables/rules.v4' do
  source 'rules.v4'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install the PAM password module for strong passwords
cookbook_file '/etc/pam.d/common-password' do
  source 'common-password'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install the Monit configuration for generating alerts on SSH logins
cookbook_file '/etc/monit/conf.d/ssh-logins' do
  source 'ssh-logins'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install the main Monit configuration file that sends the emails
#  TODO - Set the Monit email settings
template '/etc/monit/monitrc' do
  source 'monitrc.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    :MONIT_EMAIL_SERVER => '',
    :MONIT_EMAIL_PORT => '',
    :MONIT_EMAIL_USERNAME => '',
    :MONIT_EMAIL_PASSWORD => '',
    :MONIT_EMAIL_ENCRYPTION => 'tlsv12',
    :MONIT_ALERT_EMAIL => ''
  })
end

# Install the Monit script to send alerts to Slack and Pushover
#  TODO - Set the Monit Slack and Pushover settings
template '/etc/monit/monit-slack-pushover.rb' do
  source 'monit-slack-pushover.rb.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    :MONIT_SLACK_WEBHOOK_URL => '',
    :MONIT_SLACK_ENABLED => 'true',
    :MONIT_PUSHOVER_APPLICATION => '',
    :MONIT_PUSHOVER_USER => '',
    :MONIT_PUSHOVER_ENABLED => 'true'
  })
end

# Restart all the services
service 'ssh' do
  action :restart
end
service 'netfilter-persistent' do
  action :reload
end
service 'monit' do
  action :restart
end
