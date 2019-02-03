#!/bin/bash

# Checks backups to see if they are being done correctly,
# For doing this it checks how old the files are, and checks that
# there is at least one file that has been created/changed in the last
# two days. Since backups are done daily, this ensures at least
# the last backup was done correctly

# After that, it saves the result of the check in a mysql database
# If the backup is outdated, it also notifies the system
# administrator via email

# Variables
successful=1
declare -a backupNames=(Server1 SQLBackup Project2)
declare -a backupFolders=(/home/server/Desktop/backup /mnt/SQLBackup /mnt/Project2)
# We add a power of 2 to each successive backup, so we can have the result in a single numeric variable
declare -a numberToAdd=(1 2 4)


for i in "${!backupNames[@]}"
do
  # Looking for files not older than 2 days
  output=$(sudo -u sbackup find "${backupFolders[$i]}" -maxdepth 7 -mtime -2 -type f)

  # If we can't find any, we send an alert email, and set the variable to save
  # the error in the database
  if [ -z "$output" ]
  then
ssmtp -oi alerts@companyname.es <<-EOF
From: Servidor Backup <alerts@companyname.com>
To: alerts@companyname.es
Subject: ${backupNames[$i]} desactualizado

Aviso: la copia de seguridad del servidor ${backupNames[$i]} esta desactualizada en $(date)
EOF

  successful=$((successful+${numberToAdd[$i]}))
  fi
done

# Inserts values in the intranet database
# 1: No problems found
# 2: Server1 error
# 3: SQL Server error,
# 4: Server1 and SQL server error
# 5: Project2 server error
# 6: Project2 and server1 error
# 7: SQL and Project2 server error
# 8: Error in all three servers
fecha=$(date +"%Y-%m-%d")
query="insert into MetricaCheckBackup (Fecha, successful) values ('$fecha', $successful)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
