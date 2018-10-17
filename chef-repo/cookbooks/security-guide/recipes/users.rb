#
# Cookbook Name:: security_guide
# Recipe:: default
#
# Copyright (c) 2018 FusionAuth, All Rights Reserved.

# Validate the attributes
if node['security_guide']['users'].length == 0
  Chef::Application.fatal!('You must specify at least one user')
end

# Determine what users to delete
existing_usernames = Dir.entries(node['security_guide']['home_directory'])
existing_usernames.delete('.')
existing_usernames.delete('..')
existing_usernames.delete('vagrant')
new_usernames = node['security_guide']['users'].map { |user| user.username }
users_to_delete = existing_usernames.delete_if { |u| new_usernames.include?(u) }

# Delete users
if users_to_delete != nil
  users_to_delete.each do |username|
    user username do
      force true
      manage_home true
      action :remove
    end
  end
end

# Create the ordinary users
node['security_guide']['users'].each do |user|
  user user.username do
    home "#{node['security_guide']['home_directory']}/#{user.username}"
    manage_home true
    shell node['security_guide']['default_shell']
    password user.password
  end

  # Add the ordinary user to the sudo group
  group node['security_guide']['sudo_group'] do
    action :modify
    members user.username
    append true
  end

  # Setup SSH key's for the ordinary user
  directory "#{node['security_guide']['home_directory']}/#{user.username}/.ssh" do
    owner user.username
    group user.username
    mode '0700'
    action :create
  end
  file "#{node['security_guide']['home_directory']}/#{user.username}/.ssh/authorized_keys" do
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
