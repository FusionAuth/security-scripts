#!/usr/bin/env bash

# Global variables suck, but so do Bash functions
function ask_yes_no {
  answer=""
  while [[ ${answer} != "y" && ${answer} != "n" ]]; do
    echo ${1}
    read answer
  done
}

rm -rf output
mkdir output

echo "Enter the IP address of the Application Server"
read application_server_ip
echo "Enter email address to send Monit alerts to"
read monit_alert_email
echo "Enter the SMTP host for Monit"
read monit_smtp_host
echo "Enter the SMTP port for Monit"
read monit_smtp_port
echo "Enter the SMTP username for Monit"
read monit_smtp_username
echo "Enter the SMTP password for Monit"
read monit_smtp_password

monit_smtp_encryption=""
while [[ ${monit_smtp_encryption} != "ssl" && ${monit_smtp_encryption} != "tlsv12" && ${monit_smtp_encryption} != "none" ]]; do
  echo "Enter the SMTP encryption for Monit (none, ssl or tlsv12 - older versions of Monit require tlsv12 to work properly)"
  read monit_smtp_encryption
done
if [[ ${monit_smtp_encryption} == "none" ]]; then
  monit_smtp_encryption=""
else
  monit_smtp_encryption="using ${monit_smtp_encryption}"
fi

ask_yes_no "Install Ruby and Monit Slack/Pushover integration? (y/n)"
monit_slack_webhook_url="Not-Enabled"
monit_slack_enabled="false"
monit_pushover_application="Not-Enabled"
monit_pushover_user="Not-Enabled"
monit_pushover_enabled="false"
if [[ ${answer} == "y" ]]; then
  ask_yes_no "Enable Slack notifications in Monit? (y/n)"
  if [[ "${answer}" == "y" ]]; then
    echo "Enter the Slack Webhook URL for Monit (i.e. https://hooks.slack.com/services/A0411FLaa/B004CKBBB/E7eeeea2a7a1U6EUhnIAus6z)"
    read monit_slack_webhook_url
    monit_slack_enabled="true"
  fi

  ask_yes_no "Enable Pushover notifications in Monit? (y/n)"
  if [[ "${answer}" == "y" ]]; then
    echo "Enter the Pushover Application key"
    read monit_pushover_application
    echo "Enter the Pushover user/group key"
    read monit_pushover_user
    monit_pushover_enabled="true"
  fi

  cp template/ubuntu-16.04/monit-ssh-logins-exec.cfg output/monit-ssh-logins.cfg
  sed "s/@MONIT_SLACK_WEBHOOK_URL@/${monit_slack_webhook_url//\//\\/}/g;s/@MONIT_SLACK_ENABLED@/${monit_slack_enabled}/g;s/@MONIT_PUSHOVER_APPLICATION@/${monit_pushover_application}/g;s/@MONIT_PUSHOVER_USER@/${monit_pushover_user}/g;s/@MONIT_PUSHOVER_ENABLED@/${monit_pushover_enabled}/g" < template/ubuntu-16.04/monit-slack-pushover.rb > output/monit-slack-pushover.rb
  chmod +x output/monit-slack-pushover.rb
else
  cp template/ubuntu-16.04/monit-ssh-logins-alert.cfg output/monit-ssh-logins.cfg
fi

cp template/ubuntu-16.04/backup.sh output
cp template/ubuntu-16.04/common-password output
cp template/ubuntu-16.04/iptables-application-server.cfg output
cp template/ubuntu-16.04/setup-server.sh output
cp template/ubuntu-16.04/sshd output
cp template/ubuntu-16.04/sshd_config output
chmod +x output/backup.sh
chmod +x output/setup-server.sh

sed "s/@APPLICATION_SERVER_IP@/${application_server_ip}/g" < template/ubuntu-16.04/iptables-database-server.cfg > output/iptables-database-server.cfg
sed "s/@MONIT_EMAIL_SERVER@/${monit_smtp_host}/g;s/@MONIT_EMAIL_PORT@/${monit_smtp_port}/g;s/@MONIT_EMAIL_USERNAME@/${monit_smtp_username}/g;s/@MONIT_EMAIL_PASSWORD@/${monit_smtp_password}/g;s/@MONIT_EMAIL_ENCRYPTION@/${monit_smtp_encryption}/g" < template/ubuntu-16.04/monitrc > output/monitrc
