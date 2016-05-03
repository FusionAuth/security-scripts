#!/usr/bin/env bash

function bail {
  echo "************** ${1} **************"
  exit 1
}

if [[ ${#} != 4 ]]; then
  echo "Usage: setup-server.sh <ssh-public-key-file> <iptable-config-file> <ordinary-username> <ordinary-user-password>"
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

echo "############################################ Installing packages ############################################"
apt-get -y install libpam-cracklib
apt-get -y install libpam-google-authenticator
apt-get -y install ntp
debconf-set-selections <<< 'iptables-persistent iptables-persistent/autosave_v4 boolean true'
debconf-set-selections <<< 'iptables-persistent iptables-persistent/autosave_v6 boolean true'
apt-get -y install iptables-persistent
apt-get -y install monit
apt-get -y install ruby

echo "############################################ Creating ordinary user ############################################"
ordinary_user_password_encrypted=$(mkpasswd -m sha-512 ${ordinary_user_password})
useradd -m -G sudo -s /bin/bash -p "${ordinary_user_password_encrypted}" ${ordinary_user}
mkdir -p /home/${ordinary_user}/.ssh
cp ${ssh_key_file} /home/${ordinary_user}/.ssh/authorized_keys
chown -R ${ordinary_user}:${ordinary_user} /home/${ordinary_user}/.ssh
chmod 700 /home/${ordinary_user}/.ssh
chmod 600 /home/${ordinary_user}/.ssh/authorized_keys
usermod -p '*' root

# Backup all the configuration files
echo "############################################ Backing up files ############################################"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
cp /etc/pam.d/sshd /etc/pam.d/sshd.orig
cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
cp /etc/monit/monitrc /etc/monit/monitrc.orig

# Install configuration files
echo "############################################ Installing configuration files ############################################"
cp common-password /etc/pam.d/common-password
cp ${iptable_cfg_file} /etc/iptables/rules.v4
cp monit-ssh-logins.cfg /etc/monit/conf.d/ssh-logins
cp monitrc /etc/monit/monitrc
cp sshd_config /etc/ssh/sshd_config
cp sshd /etc/pam.d/sshd
if [ -f monit-slack-pushover.rb ]; then
  cp monit-slack-pushover.rb /etc/monit/monit-slack-pushover.rb
fi

echo "############################################ Restarting the services ############################################"
service ssh restart
service netfilter-persistent reload
service monit restart
