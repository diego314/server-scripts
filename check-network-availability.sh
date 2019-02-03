#!/bin/bash

# Checks if the internet connection is alive. We make a wget
# from three different known servers. If none responds, it
# probably means thatthe connection is offline

# Variables
networkOK=0
noProblemFound=1
google=0
lhc=0
iscon=0
# TODO: Setup an array

# Trying to connect with wget, redirecting the result to /dev/null and doing
# a maximum of 10 attempts
wget -qO- --tries=10 --timeout=20 http://google.com > /dev/null
if [[ $? -eq 0 ]]; then
    networkOK=1
    google=1
fi
wget -qO- --tries=10 --timeout=20 http://hasthelargehadroncolliderdestroyedtheworldyet.com > /dev/null
if [[ $? -eq 0 ]]; then
    networkOK=1
    lhc=1
fi
wget -qO- --tries=10 --timeout=20 http://ismycomputeron.com/ > /dev/null
if [[ $? -eq 0 ]]; then
    networkOK=1
    iscon=1
fi

# They are not responding, internet connection is most probably off
if [[ $networkOK -ne 1 ]]; then
    noProblemFound=0

# Sending a warning email to alerts@companyname.es
ssmtp -oi alerts@companyname.es <<-EOF
From: Servidor fileServer <alerts@companyname.com>
To: alerts@companyname.es
Subject: Internet caido

Aviso: La conexion a internet esta caida en: $(date)

EOF
fi

# Inserts values in the intranet database
fecha=$(date +"%Y-%m-%d")
query="insert into MetricaInternet (Fecha, Satisfactoria, Google, LHC, Ismycomputeron) values ('$fecha', $noProblemFound, $google, $lhc, $iscon)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
