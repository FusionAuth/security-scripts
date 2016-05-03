#!/usr/bin/env bash

function bail {
  echo "************** ${1} **************"
  exit 1
}

if [[ ${#} != 4 && ${#} != 5 ]]; then
  echo "Usage: setup-new-server.sh <root@host> <ssh-public-key-file> <iptable-config-file> <ordinary-username> [ordinary-user-password]"
  echo ""
  echo "    for example: setup-new-server.sh root@192.168.1.1 ~/.ssh/id_rsa.pub output/iptables-application-server.cfg myuser password"
  echo ""
  echo " If the password is not specified, it will be input by the user interactively"
  exit 1
fi

root_at_host=$1
ssh_key_file=$2
iptable_cfg_file=$3
ordinary_user=$4

ordinary_user_password=""
ordinary_user_password_confirm="other"
if [[ ${#} == 5 ]]; then
  ordinary_user_password=$5
else
  while [[ ${ordinary_user_password} != ${ordinary_user_password_confirm} ]]; do
    echo -n "Password: "
    read -s ordinary_user_password
    echo ""
    echo -n "Password (again): "
    read -s ordinary_user_password_confirm
    echo ""
    if [[ ${ordinary_user_password} != ${ordinary_user_password_confirm} ]]; then
      echo "Passwords don't match"
    fi
  done
fi

if ! [ -f ${ssh_key_file} ]; then
  bail "Invalid SSH public key file"
fi

if ! [ -f ${iptable_cfg_file} ]; then
  bail "Invalid IPTables configuration file"
fi

scp output/* ${ssh_key_file} ${root_at_host}:/root
ssh -t ${root_at_host} "/root/setup-server.sh ${ssh_key_file} ${iptable_cfg_file} '${ordinary_user}' '${ordinary_user_password}'"