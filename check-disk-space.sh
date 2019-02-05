#!/bin/bash

# Checks the available space on the server's hard disk
# and saves it in a log. If the used space exceeds the maximum
# threshold (85%), it sends an alert email

# Calculates the disk space, and store it in variables
total=$(df -h | grep /dev/sda1 | awk '{print $2}')
total=${total//[TG]/}
total=${total//,/.}

# Calculates percentage
#usado=$(df -h | grep /dev/sda1 | awk '{print $3}')
used100=$(df -h | grep /dev/sda1 | awk '{print $5}')
used100=${used100//%/}

# Calculates free space
free=$(df -h | grep /dev/sda1 | awk '{print $4}')
free=${free//[TG]/}
free=${free//,/.}
free100=$(( 100 - used100 ))%

resultsTable=ServerSpace
SQLServer=192.168.0.163
passwordSql=pmypassword
mailTo=alerts@companyname.es
mailFrom=alerts@companyname.com
serverName=fileServer

# Inserts results in the intranet database
dateNow=$(date +"%Y-%m-%d")
query="insert into $resultsTable (Date, Total, Free, Used100) values ('$dateNow', $total, $free, $used100)"
mysql -h $SQLServer intranet -u root -$passwordSql << EOF
$query
EOF

# If it's over the maximum threshold, sends an email
if [ $used100 -gt 85 ]; then
echo "Warning: Server $serverName with low disk space on: $(date)"

ssmtp -oi $mailTo <<-EOF
From: $serverName <$mailFrom>
To: $mailTo
Subject: Low disk space on $serverName

Warning: The free disk space on $serverName is $free Gb, $free100 % from the total space, on: $(dateNow)

EOF
fi
