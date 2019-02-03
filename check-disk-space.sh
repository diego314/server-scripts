#!/bin/bash

# Checks the available space on the server's hard disk
# and saves it in a log. If the used space exceeds the maximum
#  threshold (85%), it sends an alert email

# Calculate the disk space, and store it in variables
total=$(df -h | grep /dev/sda1 | awk '{print $2}')
total=${total//[TG]/}
total=${total//,/.}

# Calculate percentage
#usado=$(df -h | grep /dev/sda1 | awk '{print $3}')
used100=$(df -h | grep /dev/sda1 | awk '{print $5}')
used100=${used100//%/}

# Calculate free space
free=$(df -h | grep /dev/sda1 | awk '{print $4}')
free=${free//[TG]/}
free=${free//,/.}
free100=$(( 100 - used100 ))%

tablaResultados=MetricaEspacioAmidala
servidorSql=192.168.0.163
passwordSql=pmypassword
mailTo=alerts@companyname.es
mailFrom=alerts@companyname.com
nombreServidor=fileServer

# Insert results in the intranet database
fecha=$(date +"%Y-%m-%d")
query="insert into $tablaResultados (Fecha, Total, Libre, Used100) values ('$fecha', $total, $free, $used100)"
mysql -h $servidorSql intranet -u root -$passwordSql << EOF
$query
EOF

# If it's over the maximum threshold it sends an email
if [ $used100 -gt 85 ]; then
echo "Aviso: Falta de espacio en el servidor $nombreServidor en: $(date)"

ssmtp -oi $mailTo <<-EOF
From: Servidor $nombreServidor <$mailFrom>
To: $mailTo
Subject: Espacio en $nombreServidor critico

Aviso: El espacio libre en disco del servidor $nombreServidor es $free Gb, el $free100 % del total, en: $(date)

EOF
fi
