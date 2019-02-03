#!/bin/bash

# Este script hace un ping a cada uno de los servidores de la empresa, y si encuentra
# alguno caído, envía un correo a alerts@companyname.es

# Lista de IPs:
# 37: Sauron2, 56: fileServer, 60: HttpMysql, 163: Sbackup, 235: Gestor
noProblemFound=1

declare -a serverNames=(Sauron2 fileServer HttpMysql Sbackup Gestor Httpsql Oracle)
declare -a serverIPs=(192.168.0.37 192.168.0.56 192.168.0.60 192.168.0.163 192.168.0.235 192.168.0.9 192.168.0.250)
declare -a serverState=(0 0 0 0 0 0 0)

# Para cada IP, hacemos un ping
for i in "${!serverNames[@]}"
do
  ping -c 5 "${serverIPs[$i]}" &> /dev/null

  # If the server is not responding, sends a warning email
  if [ $? -ne 0 ]; then
    noProblemFound=0
    serverState[$i]=1;
    echo "Aviso: El servidor ${serverNames[$i]} esta caido en: $(date)"
ssmtp -oi alerts@companyname.es <<-EOF
From: Servidor Bastion <alerts@companyname.com>
To: alerts@companyname.es
Subject: Servidor ${serverNames[$i]} caido
Aviso: El servidor ${serverNames[$i]} esta caido en: $(date)
EOF

  else
    echo "servidor ${serverNames[$i]} funcionando"
  fi
done

# If we found any problem, or if it's 23:00, writes the data on the intranet database
# Uses 23:00 so at least once a day it saves some data, and the intranet can then check if the script is working correctly
if [[ $noProblemFound -eq 0 ]] || [[ $(date +%k) -eq 23 ]]
  then
    # Saves on mysql the resulting data
    fecha=$(date +"%Y-%m-%d %H:%M:%S")
    query="insert into MetricaPing (Fecha, Satisfactoria, Sauron2, fileServer, Httpmysql, Sbackup, Gestor, Httpsql, Oracle) values ('$fecha', $noProblemFound, ${serverState[0]}, ${serverState[1]}, ${serverState[2]}, ${serverState[3]}, ${serverState[4]}, ${serverState[5]}, ${serverState[6]})"
    echo "$query"
    mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
    $query
EOF
fi
