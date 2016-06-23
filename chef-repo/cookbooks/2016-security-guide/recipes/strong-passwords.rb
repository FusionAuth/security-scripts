#
# Cookbook Name:: 2016_security_guide
# Recipe:: default
#
# Copyright (c) 2016 Inversoft, All Rights Reserved.

# Install all the security packages
package 'libpam-cracklib'

# Install the PAM password module for strong passwords
template '/etc/pam.d/common-password' do
  source 'common-password.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
