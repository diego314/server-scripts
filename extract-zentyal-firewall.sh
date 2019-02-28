#!/bin/bash

# Extracts from the syslog the number of blocked packages by zentyal firewall

# Variables
dateTemp=""
datePrevious=""
dateNow=""
total=0

# Creates a temporary pipe so it can access the variables when inside the loop
mkfifo mypipe

# Extracts from syslog the lines containing "zentyal-firewall" y "drop"
cat /var/log/syslog.1 | grep zentyal-firewall | grep drop > mypipe &
while read linea; do
  dateTemp=$(echo $linea | awk '{print $1 $2}')
  dateNow=$(date -d "$dateTemp" +%F)
  if [ -z "$dateNow" ]
  then
    # Reading the very first line, initializing dateNow variable
    datePrevious="$dateNow"
    total=1
  else
    # Not the very first line, checking if the date is the same as the previous one
    if [ "$dateNow" != "$datePrevious" ]
    then
      # Finished getting data for this date, saving data on sql
      query="delete from Firewall where Date='$dateNow'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      query="insert into Firewall (Date, Number) values ('$dateNow', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      datePrevious="$dateNow"
      total=1
    else
      # Adds 1 to the total of found data
      total=$((total + 1))
    fi
  fi
done < mypipe

if [ $total -gt 0 ]
then
# There was some data found. First deletes from mysql the data with the same dateNow value, and inserts the new found value
query="delete from Firewall where Date='$dateNow'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

query="insert into Firewall (Date, Number) values ('$dateNow', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
fi

# Deletes temp pipe
rm mypipe
