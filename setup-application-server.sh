#!/usr/bin/env bash

function bail {
  echo $1
  exit 1
}

function replace_or_append {
  file_name=$1
  original=$2
  new=$3

  # Check if the value exists and replace or append based on that
  if grep ${original} ${file_name}; then
    if ! perl -pi -e "s/${original}/${new}/g" ${file_name}; then
      bail "Unable to update file ${file_name}"
    fi
  else
    echo "${new}" >> ${file_name}
  fi
}

if [[ $# != 2 ]]; then
  bail "Usage: setup-application-server.sh <username> <ssh-public-key-file>"
fi

ORDINARY_USER=$1
SSH_KEY_FILE=$2

####### Start SSH setup #######
if ! useradd -m -G sudo -s /bin/bash ${ORDINARY_USER}; then
  bail "Unable to create ordinary user ${ORDINARY_USER}"
fi

echo "Please provide the password for the ${ORDINARY_USER}"
if ! passwd ${ORDINARY_USER}; then
  bail "Unable to change the ordinary user's password"
fi

if ! [ -f ${SSH_KEY_FILE} ]; then
  bail "Invalid SSH public key file"
fi

if ! mkdir -p /home/${ORDINARY_USER}/.ssh; then
  bail "Unable to create .ssh directory for the ordinary user"
fi

if ! cp ${SSH_KEY_FILE} /home/${ORDINARY_USER}/.ssh/authorized_keys; then
  bail "Unable to create .ssh directory for the ordinary user"
fi

if ! chown -R ${ORDINARY_USER}:${ORDINARY_USER} /home/${ORDINARY_USER}/.ssh; then
  bail "Unable to chown the ordinary user's SSH files"
fi

if ! chmod 700 /home/${ORDINARY_USER}/.ssh; then
  bail "Unable to chmod the ordinary user's .ssh directory"
fi

if ! chmod 600 /home/${ORDINARY_USER}/.ssh/authorized_keys; then
  bail "Unable to chmod the ordinary user's SSH authorized_keys file"
fi

replace_or_append /etc/ssh/sshd_config "PermitRootLogin yes" "PermitRootLogin no"
replace_or_append /etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"

if ! apt-get install libpam-google-authenticator; then
  bail "Missing package Google Authentication"
fi

if ! perl -p -i -e 'BEGIN { print "auth [success=done new_authtok_reqd=done default=die] pam_google_authenticator.so nullok\n" }' /etc/pam.d/sshd; then
  bail "Unable to enable PAM module for Google Authenticator"
fi

replace_or_append /etc/ssh/sshd_config "ChallengeResponseAuthentication no" "ChallengeResponseAuthentication yes"
replace_or_append /etc/ssh/sshd_config "AuthenticationMethods .+$" "AuthenticationMethods publickey,keyboard-interactive"

if ! apt-get install ntp; then
  bail "Unable to install the Network Time Protocol services so that the Google Authenticator works properly"
fi

if ! service ssh restart; then
  bail "Unable to restart the SSH daemon"
fi
####### End SSH setup #######

####### Start IPTables setup #######
if ! apt-get install iptables-persistent; then
  bail "Unable to install persistent iptables package"
fi

if ! iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT; then
  bail "Unable to update iptables to allow OUTPUT for SSH"
fi

if ! iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT; then
  bail "Unable to update iptables to allow OUTPUT for HTTPS"
fi

if ! iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT; then
  bail "Unable to update iptables to allow INPUT for SSH"
fi

if ! iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT; then
  bail "Unable to update iptables to allow INPUT for HTTPS"
fi

if ! iptables -P INPUT DROP; then
  bail "Unable to update iptables to DROP all INPUT"
fi

if ! iptables -P OUTPUT DROP; then
  bail "Unable to update iptables to DROP all OUTPUT"
fi

if ! iptables -P FORWARD DROP; then
  bail "Unable to update iptables to DROP all FORWARD"
fi

if ! iptables-save > /etc/iptables.conf; then
  bail "Unable to write out iptables configuration file"
fi

if ! cat > /etc/network/if-pre-up.d/iptablesload <<EOF
  #!/bin/sh
  iptables-restore < /etc/iptables.config
  exit 0
EOF
then
  bail "Unable to create iptables load script"
fi

if ! chmod +x /etc/network/if-pre-up.d/iptablesload; then
  bail "Unable to chomd iptables load script"
fi
####### End IPTables setup #######

if ! usermod -p '*' root; then
  bail "Unable to lock root user's account for direct login"
fi
