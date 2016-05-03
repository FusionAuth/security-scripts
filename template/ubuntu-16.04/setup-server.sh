#!/usr/bin/env bash

if [[ ${#} != 4 ]]; then
  echo "Usage: setup-server.sh <ssh-public-key-file> <iptable-config-file> <ordinary-username> <ordinar-user-password>"
  echo ""
  echo "    for example: setup-server.sh id_rsa.pub iptables-application-server.cfg myuser password"
  exit 1
fi

ssh_key_file=$1
iptable_cfg_file=$2
ordinary_user=$3
ordinary_user_password=$4

if ! [ -f ${ssh_key_file} ]; then
  bail "Invalid SSH public key file"
fi

if ! [ -f ${iptable_cfg_file} ]; then
  bail "Invalid IPTables configuration file"
fi

apt-get -qq -y install libpam-cracklib > /dev/null 2>&1
apt-get -qq -y install libpam-google-authenticator > /dev/null 2>&1
apt-get -qq -y install ntp > /dev/null 2>&1
debconf-set-selections <<< 'iptables-persistent iptables-persistent/autosave_v4 boolean true'
debconf-set-selections <<< 'iptables-persistent iptables-persistent/autosave_v6 boolean true'
apt-get -qq -y install iptables-persistent > /dev/null 2>&1
apt-get -qq -y install monit > /dev/null 2>&1
apt-get -qq -y install ruby > /dev/null 2>&1

ordinary_user_password_encrypted=$(mkpasswd -m sha-512 ${ordinary_user_password})
useradd -m -G sudo -s /bin/bash -p "${ordinary_user_password_encrypted}" ${ordinary_user}
mkdir -p /home/${ordinary_user}/.ssh
cp ${ssh_key_file} /home/${ordinary_user}/.ssh/authorized_keys
chown -R ${ordinary_user}:${ordinary_user} /home/${ordinary_user}/.ssh
chmod 700 /home/${ordinary_user}/.ssh
chmod 600 /home/${ordinary_user}/.ssh/authorized_keys

# Backup all the configuration files
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
cp /etc/pam.d/sshd /etc/pam.d/sshd.orig
cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
cp /etc/monit/monitrc /etc/monit/monitrc.orig

# SCP over all the files
cp common-password /etc/pam.d/common-password
cp ${iptable_cfg_file} /etc/iptables/rules.v4
cp monit-ssh-logins.cfg /etc/monit/conf.d/ssh-logins
cp monitrc /etc/monit/monitrc
cp sshd_config /etc/ssh/sshd_config
cp sshd /etc/pam.d/sshd
if [ -f monit-slack-pushover.rb ]; then
  cp monit-slack-pushover.rb /etc/monit/monit-slack-pushover.rb
fi

service ssh restart
service netfilter-persistent reload
service monit restart
usermod -p '*' root