#!/bin/bash

# Sends a ping to all of the servers on a list, and sends an
# email if it finds any of them are not responding

# IP list:
# 37: SQLServer, 56: FileServer, 60: HttpMysql, 163: BackupServer, 235: ADServer
noProblemFound=1

declare -a serverNames=(SQLServer FileServer HttpMysql BackupServer ADServer)
declare -a serverIPs=(192.168.0.37 192.168.0.56 192.168.0.60 192.168.0.163 192.168.0.235)
declare -a serverState=(0 0 0 0 0)

# Sends a ping to each IP
for i in "${!serverNames[@]}"
do
  ping -c 5 "${serverIPs[$i]}" &> /dev/null

  # If the server is not responding, sends a warning email
  if [ $? -ne 0 ]; then
    noProblemFound=0
    serverState[$i]=1;
    echo "Warning: Server ${serverNames[$i]} is down on: $(date)"
ssmtp -oi alerts@companyname.es <<-EOF
From: Alerts <alerts@companyname.com>
To: alerts@companyname.es
Subject: Server ${serverNames[$i]} down
Warning: Server ${serverNames[$i]} is down on: $(date)
EOF

  else
    echo "Server ${serverNames[$i]} working correctly"
  fi
done

# If it found any problem, or if it's 23:00, writes the data on the intranet database
# Uses 23:00 so at least once a day it saves some data, and the intranet can then check if the script is working correctly
if [[ $noProblemFound -eq 0 ]] || [[ $(date +%k) -eq 23 ]]
  then
    # Saves on mysql the resulting data
    dateNow=$(date +"%Y-%m-%d %H:%M:%S")
    query="insert into Ping (Date, Successful, SQLServer, FileServer, Httpmysql, BackupServer, ADServer) values ('$dateNow', $noProblemFound, ${serverState[0]}, ${serverState[1]}, ${serverState[2]}, ${serverState[3]}, ${serverState[4]})"
    echo "$query"
    mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
    $query
EOF
fi
