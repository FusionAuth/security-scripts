#!/bin/bash

BACKUP_DIR=/root/backups
# You may consider a more temporary directory if backups are stored offsite:
# BACKUP_DIR=/tmp/backups
DATE=`date +%Y%m%d`
BACKUP_FILE="${DATE}.tar.gz"
BACKUP_FILE_ENCRYPTED="${DATE}.tar.gz.enc"
BACKUP_PASSPHRASE_FILE="${DATE}.passphrase"
BACKUP_PASSPHRASE_FILE_ENCRYPTED="${DATE}.passphrase.enc"

# Make the directory just in case it doesn't exist
mkdir ${BACKUP_DIR}
cd ${BACKUP_DIR}

# Delete the oldest files by only listing out everything older than the newest 7 files
ls *.tar.gz.enc | sort | tail -n +7 | xargs rm
ls *.passphrase.enc | sort | tail -n +7 | xargs rm

# Backup the MySQL databases
mysqldump -u<username> -p<password> production > production.sql

# Tar GZ everything (modify this line to include more files and directories in the backup)
tar -pczf ${BACKUP_FILE} /etc *.sql

# Generate a random passphrase
openssl rand 32 -out ${BACKUP_PASSPHRASE_FILE}

# Encrypt the backup tar.gz
openssl enc -aes-256-cbc -pass file:${BACKUP_PASSPHRASE_FILE} < ${BACKUP_FILE} > ${BACKUP_FILE_ENCRYPTED}

# Encrypt the passphrase
openssl rsautl -encrypt -pubin -inkey /root/public-key.pem < ${BACKUP_PASSPHRASE_FILE} > ${BACKUP_PASSPHRASE_FILE_ENCRYPTED}

# Clean up
rm ${BACKUP_FILE} ${BACKUP_PASSPHRASE_FILE} *.sql

# Copy offsite
#scp ${BACKUP_FILE_ENCRYPTED} ${BACKUP_PASSPHRASE_FILE_ENCRYPTED} <username>@<backup-server>:backups/.
