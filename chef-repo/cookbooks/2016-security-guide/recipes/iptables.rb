#
# Cookbook Name:: 2016_security_guide
# Recipe:: default
#
# Copyright (c) 2016 Inversoft, All Rights Reserved.

# Configure the Debian answers for the iptables-persistent package
ruby_block 'debconf-iptables-persistent' do 
  block do
    `echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections`
    `echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections`
  end
  action :create
end
package 'iptables-persistent'

# Install the IPTables IPv4 configuration file
template '/etc/iptables/rules.v4' do
  source 'rules.v4.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Restart the IPTables service
service 'netfilter-persistent' do
  action :restart
end
