#
# Cookbook Name:: 2016_security_guide
# Recipe:: default
#
# Copyright (c) 2016 Inversoft, All Rights Reserved.

apt_update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

# Create the ordinary users
node['security_guide']['users'].each do |user|
  user user.username do
    home "/home/#{user.username}"
    manage_home true
    shell '/bin/bash'
    password user.password
  end

  # Add the ordinary user to the sudo group
  group node['security_guide']['sudo_group'] do
    action :modify
    members user.username
    append true
  end

  # Setup SSH key's for the ordinary user
  directory "/home/#{user.username}/.ssh" do
    owner user.username
    group user.username
    mode '0700'
    action :create
  end
  file "/home/#{user.username}/.ssh/authorized_keys" do
    content user.public_key
    owner user.username
    group user.username
    mode '0600'
  end
end

# Disable rot user's password
user 'root' do
  password '!'
  action :modify
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
template '/etc/monit/monitrc' do
  source 'monitrc.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    :MONIT_EMAIL_SERVER => node['security_guide']['monit']['email_server'],
    :MONIT_EMAIL_PORT => node['security_guide']['monit']['email_port'],
    :MONIT_EMAIL_USERNAME => node['security_guide']['monit']['email_username'],
    :MONIT_EMAIL_PASSWORD => node['security_guide']['monit']['email_password'],
    :MONIT_EMAIL_ENCRYPTION => node['security_guide']['monit']['email_encryption'],
    :MONIT_ALERT_EMAIL => node['security_guide']['monit']['alert_email']
  })
end

# Install the Monit script to send alerts to Slack and Pushover
template '/etc/monit/monit-slack-pushover.rb' do
  source 'monit-slack-pushover.rb.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables({
    :MONIT_SLACK_WEBHOOK_URL => node['security_guide']['monit']['slack_url'],
    :MONIT_SLACK_ENABLED => node['security_guide']['monit']['slack_enabled'],
    :MONIT_PUSHOVER_APPLICATION => node['security_guide']['monit']['pushover_application'],
    :MONIT_PUSHOVER_USER => node['security_guide']['monit']['pushover_user'],
    :MONIT_PUSHOVER_ENABLED => node['security_guide']['monit']['pushover_enabled']
  })
end

# Restart all the services
service 'ssh' do
  action :restart
end
service 'netfilter-persistent' do
  action :restart
end
service 'monit' do
  action :restart
end
