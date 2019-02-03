#!/bin/bash

# Este script extrae del log del sistema los elementos que corresponden a
# las copias de seguridad efectuadas por el programa backintime, y hace una
# copia en el servidor fileServer del log resultante

# Copiamos el contenido de todos los syslog en el archivo scrlog-sbackup-copialog.txt
zcat /var/log/syslog.7.gz | grep backintime > /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt
zcat /var/log/syslog.6.gz | grep backintime >> /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt
zcat /var/log/syslog.5.gz | grep backintime >> /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt
zcat /var/log/syslog.4.gz | grep backintime >> /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt
zcat /var/log/syslog.3.gz | grep backintime >> /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt
zcat /var/log/syslog.2.gz | grep backintime >> /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt
cat /var/log/syslog.1 | grep backintime >> /home/sbackup/scripts/logs/scrlog-sbackup-copialog.txt

# Copiamos el log al servidor fileServer
cd /home/sbackup/scripts/logs/
smbclient //192.168.0.56/seguridad adminPassword -U administrator <<EOC
cd logs_scripts
recurse
prompt
mput scrlog-sbackup-copialog.txt
EOC
