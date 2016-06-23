#
# Cookbook Name:: 2016_security_guide
# Recipe:: default
#
# Copyright (c) 2016 Inversoft, All Rights Reserved.

include_recipe '2016_security_guide::users'
include_recipe '2016_security_guide::strong-passwords'
include_recipe '2016_security_guide::iptables'
include_recipe '2016_security_guide::sshd'
if node['security_guide']['two_factor_enabled']
  include_recipe '2016_security_guide::two-factor'
end
include_recipe '2016_security_guide::monit'
