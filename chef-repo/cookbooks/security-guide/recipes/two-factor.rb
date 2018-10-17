#
# Cookbook Name:: security_guide
# Recipe:: default
#
# Copyright (c) 2018 FusionAuth, All Rights Reserved.

# Install the two-factor library
package 'ntp'
package 'libpam-google-authenticator'

# Install the PAM SSH configuration file for two-factor authentication
cookbook_file '/etc/pam.d/sshd' do
  source 'sshd'
  owner 'root'
  group 'root'
  mode '0644'
end
