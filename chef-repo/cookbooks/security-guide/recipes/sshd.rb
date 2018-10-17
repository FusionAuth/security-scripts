#
# Cookbook Name:: security_guide
# Recipe:: default
#
# Copyright (c) 2018 FusionAuth, All Rights Reserved.

# Install the SSH server configuration file
template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Restart the SSH service
service 'ssh' do
  action :restart
end
