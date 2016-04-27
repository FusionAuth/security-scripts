#!/usr/bin/env bash

function bail {
  echo "************** ${1} **************"
  exit 1
}

function replace_uncomment_or_append {
  file_name=$1
  already_exists_indicator=$2
  original=$3
  new=$4

  # If the replacement we want to use already exists, we don't need to run this replacement
  if grep "${already_exists_indicator}" ${file_name} > /dev/null 2>&1; then
    return 0
  fi

  # Check if the final value exists, but is commented out
  if grep "^#.*${new}" ${file_name} > /dev/null 2>&1; then
    if ! sed -i.bak "s/${original}/${new}/g" ${file_name}; then
      bail "Failed to uncomment the value ${new} in file ${file_name}"
    fi

  # Check if the original value exists and replace it
  elif grep "^${original}" ${file_name} > /dev/null 2>&1; then
    if ! sed -i.bak "s/${original}/${new}/g" ${file_name}; then
      bail "Unable to update file ${file_name}"
    fi

  # Check if the original value exists and is commented out and replace it
  elif grep "^#.*${original}" ${file_name} > /dev/null 2>&1; then
    if ! sed -i.bak "s/^#.*${original}/${new}/g" ${file_name}; then
      bail "Unable to update file ${file_name}"
    fi
  else
    echo "${new}" >> ${file_name}
  fi

  rm ${file_name}.bak > /dev/null 2>&1
}

if [[ $# != 3 ]]; then
  bail "Usage: setup-server.sh <ordinary-username> <ssh-public-key-file> <iptable-config-file>"
fi

ORDINARY_USER=$1
SSH_KEY_FILE=$2
IPTABLE_CFG_FILE=$3

if ! [ -f ${SSH_KEY_FILE} ]; then
  bail "Invalid SSH public key file"
fi

if ! [ -f ${IPTABLE_CFG_FILE} ]; then
  bail "Invalid IPTables configuration file"
fi

####### Start SSH setup #######
echo "Adding the ordinary user"
if useradd -m -G sudo -s /bin/bash ${ORDINARY_USER}; then
  echo "Please provide the password for the ${ORDINARY_USER}"
  if ! passwd ${ORDINARY_USER}; then
    bail "Unable to change the ordinary user's password"
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
else
  echo "It looks like the ordinary user has already been setup. Skipping those steps"
fi

echo "Securing the SSH configuration"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
replace_uncomment_or_append /etc/ssh/sshd_config "^PermitRootLogin no" "PermitRootLogin yes" "PermitRootLogin no"
replace_uncomment_or_append /etc/ssh/sshd_config "^PasswordAuthentication no" "PasswordAuthentication yes" "PasswordAuthentication no"

echo "Installing Google Two-Factor Authentication"
if apt-get -qq -y install libpam-google-authenticator > /dev/null 2>&1; then
  cp /etc/pam.d/sshd /etc/pam.d/sshd.orig
  if ! grep "pam_google_authenticator.so" /etc/pam.d/sshd; then
    echo "auth [success=done new_authtok_reqd=done default=die] pam_google_authenticator.so nullok" >> /etc/pam.d/sshd
  fi

  replace_uncomment_or_append /etc/ssh/sshd_config "^ChallengeResponseAuthentication yes" "ChallengeResponseAuthentication no" "ChallengeResponseAuthentication yes"
  replace_uncomment_or_append /etc/ssh/sshd_config "^AuthenticationMethods publickey,keyboard-interactive" "AuthenticationMethods .+$" "AuthenticationMethods publickey,keyboard-interactive"

  if ! apt-get -qq -y install ntp; then
    echo "************** Unable to install the Network Time Protocol services so that the Google Authenticator works properly. You should figure out why this failed and install NTP manually **************"
  fi
else
  echo "Unable to install the Google Authenticator library. Skipping the configuration steps for that"
fi

if ! service ssh restart; then
  echo "************** Unable to restart the SSH daemon. Everything appears to be okay otherwise. You'll just need to figure out why the reload failed **************"
fi
####### End SSH setup #######

####### Start IPTables setup #######
echo "Installing the Persistent IPTables package"
if ! apt-get -qq -y install iptables-persistent; then
  bail "Unable to install persistent iptables package"
fi

cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
cp ${IPTABLE_CFG_FILE} /etc/iptables/rules.v4
if grep "%APPLICATION_SERVER_IP%" /etc/iptables/rules.v4; then
  echo "Enter the IP address of the Application Server"
  read APPLICATION_SERVER_IP
  sed -i.bak "s/%APPLICATION_SERVER_IP%/${APPLICATION_SERVER_IP}/g" /etc/iptables/rules.v4
  rm /etc/iptables/rules.v4.bak
fi

if ! service netfilter-persistent reload; then
  echo "************** Unable to reload the IPTables configuration. Everything appears to be okay otherwise. You'll just need to figure out why the reload failed **************"
fi
####### End IPTables setup #######

####### Start Monit setup #######
echo "Installing Monit for login/intrusion detection"
if apt-get -qq -y install monit > /dev/null 2>&1; then
  if ! grep "^set alert ${MONIT_EMAIL}" /etc/monit/monitrc > /dev/null 2>&1; then
    cp monit-ssh-logins.cfg /etc/monit/conf.d/ssh-logins
    echo "Enter the SMTP host"
    read SMTP_HOST
    echo "Enter the SMTP port"
    read SMTP_PORT
    echo "Enter the SMTP username"
    read SMTP_USERNAME
    echo "Enter the SMTP password"
    read SMTP_PASSWORD

    SMTP_ENCRYPTION=""
    while [[ ${SMTP_ENCRYPTION} != "ssl" && ${SMTP_ENCRYPTION} != "tlsv12" ]]; do
      echo "Enter the SMTP encryption (ssl or tlsv12)"
      read SMTP_ENCRYPTION
    done

    echo "Enter email address to send alerts to"
    read MONIT_EMAIL

    cp /etc/monit/monitrc /etc/monit/monitrc.orig
    replace_uncomment_or_append /etc/monit/monitrc "^set mailserver.*${SMTP_HOST}" "set mailserver.*" "set mailserver ${SMTP_HOST} port ${SMTP_PORT} username \"${SMTP_USERNAME}\" password \"${SMTP_PASSWORD}\" using ${SMTP_ENCRYPTION}"
    echo "set alert ${MONIT_EMAIL} not on { instance, action }" >> /etc/monit/monitrc

    if ! service monit restart; then
      echo "Unable to restart Monit. Everything appears to be okay otherwise. You'll just need to figure out why the reload failed"
    fi
  fi
else
  echo "Unable to install Monit. Skipping the intrusion detection for SSH logins"
fi
####### End Monit setup #######

####### Start Lock Root Account #######
if ! usermod -p '*' root; then
  bail "Unable to lock root user's account for direct login"
fi
####### End Lock Root Account #######
