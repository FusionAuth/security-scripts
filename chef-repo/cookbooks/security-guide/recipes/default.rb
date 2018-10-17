#
# Cookbook Name:: security_guide
# Recipe:: default
#
# Copyright (c) 2018 FusionAuth, All Rights Reserved.

include_recipe 'security_guide::users'
include_recipe 'security_guide::strong-passwords'
include_recipe 'security_guide::iptables'
include_recipe 'security_guide::sshd'
if node['security_guide']['two_factor_enabled']
  include_recipe 'security_guide::two-factor'
end
include_recipe 'security_guide::monit'
