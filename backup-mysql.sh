#!/bin/bash

# Mcript makes a dump (backup) on zip format from  the local mysql
# databases, and copies this file into the assigned backup server.
# Then it does another backup from a server in the network.

# Local DDBB Password
passwordDB=pmypassword
# Where to dump the database
dumpDB=/home/sbackup/scripts/copia_BBDD_Sbackup.sql.gz

# Remote DDBB Password
passwordDBNetwork=pmypassword
# Where to dump the database
dumpDBNetwork=/home/httpmysql/copia_BBDD_Httpmysql.sql.gz

# Backup server data
backupServer=fileServer@192.168.0.56
backupServerLocation=/home/fileServer/almacen/copiassql/
mysqlServer2=httpmysql@192.168.0.60


# Create a zip backup from all databases in zip format
mysqldump -u root -$passwordDB --all-databases | gzip > $dumpDB
# Check if there's been any problem
if [ "${PIPESTATUS[0]}" -eq 0 ]
then
  # Copy the file to the backup server
  scp $dumpDB $backupServer:$backupServerLocation
  echo "Database backup finished correctly"
else
  echo "The database backup has not completed correctly"
ssmtp -oi alerts@companyname.es <<-EOF
From: Servidor Sbackup <alerts@companyname.com>
To: alerts@companyname.es
Subject: Errores en BBDD Sbackup
Las bases de datos en Sbackup contienen errores que imposibilitan hacer copia de seguridad, en: $(date)
EOF
fi


# We can also copy it to a windows shared folder, using smbclient
#smbclient //192.168.0.15/Folder adminPassword -U administrator <<EOC
#cd FOLDERNAME
#recurse
#prompt
#mput *
#EOC

# Connect to a server in the network, make a backup, and copy it
ssh $mysqlServer2 /bin/sh <<EOF
mysqldump -u root -$passwordDBNetwork --all-databases | gzip > $dumpDBNetwork
scp $dumpDBNetwork $backupServer:$backupServerLocation
exit 0
EOF

