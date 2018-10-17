# Users to create and users to delete
default['security_guide']['users'] = []
default['security_guide']['home_directory'] = '/home'
default['security_guide']['default_shell'] = '/bin/bash'

# The Sudo group name
case node[:platform]
  when "centos", "redhat", "fedora", "suse", "arch"
    default['security_guide']['sudo_group'] = 'wheel'
  else
    default['security_guide']['sudo_group'] = 'sudo'
end

# SSH config
default['security_guide']['sshd']['listen_port'] = 22

# Two-factor config
default['security_guide']['two_factor_enabled'] = true

# Strong password config
default['security_guide']['strong_passwords']['uppercase'] = 1
default['security_guide']['strong_passwords']['lowercase'] = 2
default['security_guide']['strong_passwords']['numbers'] = 1
default['security_guide']['strong_passwords']['other'] = 1
default['security_guide']['strong_passwords']['min_length'] = 10
default['security_guide']['strong_passwords']['different_than_last_by'] = 3
default['security_guide']['strong_passwords']['retry_attempts'] = 3

# Monit configuration for emailing and Slack/Pushover integration
default['security_guide']['monit']['email_server'] = 'localhost'
default['security_guide']['monit']['email_port'] = '25'
default['security_guide']['monit']['slack_url'] = ''
default['security_guide']['monit']['slack_enabled'] = false
default['security_guide']['monit']['pushover_application'] = ''
default['security_guide']['monit']['pushover_user'] = ''
default['security_guide']['monit']['pushover_enabled'] = false

# IPTable config
#  node['security_guide']['iptables']['tcp']['listen_ports'] is an array of integers that sets the listen ports
#  node['security_guide']['iptables']['tcp']['source_ips'] is a hash that sets the source IP addresses for each listen port (if any)
#         i.e. {22 => '192.168.32.42'}
#  node['security_guide']['iptables']['tcp']['forward_ports'] is a hash that configures port forwarding i.e. {80 => 3000}
default['security_guide']['iptables']['tcp']['listen_ports'] = [22, 80, 443, 3000, 3003]
default['security_guide']['iptables']['tcp']['source_ips'] = {}
default['security_guide']['iptables']['tcp']['forward_ports'] = {80 => 3000, 443 => 3003}