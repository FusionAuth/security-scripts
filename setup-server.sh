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

function log_error {
  echo -e "\e[91m************** ${1} **************"
}

function ask_yes_no {
  ANSWER=""
  while [[ ${ANSWER} != "y" && ${ANSWER} != "n" ]]; do
    echo ${1}
    read ANSWER
  done

  return ${ANSWER}
}


if [[ $# != 3 ]]; then
  echo "Usage: setup-server.sh <ordinary-username> <ssh-public-key-file> <iptable-config-file>"
  exit 1
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

####### Start Password Setup #######
if ! apt-get -qq -y install libpam-cracklib > /dev/null 2>&1; then
  log_error "Unable to setup the PAM Cracklib module. This isn't required, but it does help secure passwords so you might want to set it up later"
else
  replace_uncomment_or_append /etc/pam.d/common-password "password.*requisite.*pam_cracklib.so.*ucredit" "password.*pam_cracklib.so" "password\trequisite\t\t\tpam_cracklib.so retry=3 minlen=10 difok=3 ucredit=-1 lcredit=-2 dcredit=-1 ocredit=-1"
fi
####### End Password Setup #######

####### Start SSH Setup #######
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
    log_error "Unable to install the Network Time Protocol services so that the Google Authenticator works properly. You should figure out why this failed and install NTP manually"
  fi
else
  log_error "Unable to install the Google Authenticator library. Skipping the configuration steps for that"
fi

if ! service ssh restart; then
  log_error "Unable to restart the SSH daemon. Everything appears to be okay otherwise. You'll just need to figure out why the reload failed"
fi
####### End SSH Setup #######

####### Start IPTables Setup #######
echo "Installing the Persistent IPTables package"
if ! apt-get -qq -y install iptables-persistent; then
  bail "Unable to install persistent iptables package"
fi

cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
cp ${IPTABLE_CFG_FILE} /etc/iptables/rules.v4
if grep "%APPLICATION_SERVER_IP%" /etc/iptables/rules.v4 > /dev/null; then
  echo "Enter the IP address of the Application Server"
  read APPLICATION_SERVER_IP
  sed -i.bak "s/%APPLICATION_SERVER_IP%/${APPLICATION_SERVER_IP}/g" /etc/iptables/rules.v4
  rm /etc/iptables/rules.v4.bak
fi

if ! service netfilter-persistent reload; then
  log_error "Unable to reload the IPTables configuration. Everything appears to be okay otherwise. You'll just need to figure out why the reload failed"
fi
####### End IPTables Setup #######

####### Start Monit Setup #######
echo "Installing Monit for login/intrusion detection"
if apt-get -qq -y install monit > /dev/null 2>&1; then
  if ! grep "^set alert ${MONIT_EMAIL}" /etc/monit/monitrc > /dev/null 2>&1; then
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
      echo "Enter the SMTP encryption (ssl or tlsv12 - older versions of Monit require tlsv12 to work properly)"
      read SMTP_ENCRYPTION
    done

    echo "Enter email address to send alerts to"
    read MONIT_EMAIL

    cp /etc/monit/monitrc /etc/monit/monitrc.orig
    replace_uncomment_or_append /etc/monit/monitrc "^set mailserver.*${SMTP_HOST}" "set mailserver.*" "set mailserver ${SMTP_HOST} port ${SMTP_PORT} username \"${SMTP_USERNAME}\" password \"${SMTP_PASSWORD}\" using ${SMTP_ENCRYPTION}"
    echo "set alert ${MONIT_EMAIL} not on { instance, action }" >> /etc/monit/monitrc

    if ! service monit restart; then
      log_error "Unable to restart Monit. Everything appears to be okay otherwise. You'll just need to figure out why the reload failed"
    fi

    ask_yes_no "Install Ruby and Monit Slack/Pushover integration? (y/n)"
    if [[ ${?} == "y" ]]; then
      if ! apt-get install ruby; then
        log_error "Unable to install Ruby. Skipping Monit Slack/Pushover integration"
      else
        cp monit-ssh-logins-exec.cfg /etc/monit/conf.d/ssh-logins

        ask_yes_no "Enable Slack notifications? (y/n)"
        SLACK_WEBHOOK_URL="Not-Enabled"
        if [[ ${?} == "y" ]]; then
          echo "Enter the Slack Webhook URL (i.e. https://hooks.slack.com/services/A0411FLaa/B004CKBBB/E7eeeea2a7a1U6EUhnIAus6z)"
          read SLACK_WEBHOOK_URL
          SLACK_ENABLED="true"
        fi

        ask_yes_no "Enable Pushover notifications? (y/n)"
        PUSHOVER_APPLICATION="Not-Enabled"
        PUSHOVER_USER="Not-Enabled"
        if [[ ${?} == "y" ]]; then
          echo "Enter the Pushover Application key"
          read PUSHOVER_APPLICATION
          echo "Enter the Pushover user/group key"
          read PUSHOVER_USER
          SLACK_ENABLED="true"
        fi

        sed "s/%SLACK_WEBHOOK_URL%/${SLACK_WEBHOOK_URL}/g;s/%PUSHOVER_APPLICATION%/${PUSHOVER_APPLICATION}/g;s/%PUSHOVER_USER%/${PUSHOVER_USER}/g" < monit-slack-pushover.rb > /etc/monit/monit-slack-pushover.rb
        chmod +x /etc/monit/monit-slack-pushover.rb
      fi
    else
      cp monit-ssh-logins-alert.cfg /etc/monit/conf.d/ssh-logins
    fi
  fi
else
  echo "Unable to install Monit. Skipping the intrusion detection for SSH logins"
fi
####### End Monit Setup #######

####### Start Lock Root Account #######
if ! usermod -p '*' root; then
  bail "Unable to lock root user's account for direct login"
fi
####### End Lock Root Account #######
