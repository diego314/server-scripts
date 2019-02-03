#!/bin/bash

# Connects to a windows server with smbclient and checks both hard disks free space
# A shared folder in each disk is needed on the windows server

dateNow=$(date +"%Y-%m-%d")

# Creates to temporary pipes so it can use the information recovered inside the heredoc
mkfifo mypipe
mkfifo mypipe2

# Saves the heredoc result on variables for the first disk
smbclient //192.168.0.37/CompartidaC adminPassword -U administrator -c du | grep block > mypipe2 &
while read linea; do
  totalBlockC=$(echo $linea | awk '{print $1}')
  availableBlockC=$(echo $linea | awk '{print $6}')
  sizeBlockC=$(echo $linea | awk '{print $5}')
  sizeBlockC=${sizeBlockC//./}
  #sizeBlockC=${sizeBlockC:0:${#sizeBlockC}-1}
done < mypipe2
rm mypipe2

totalokC=$(echo "scale=2; $totalBlockC * $sizeBlockC / 1073741824" | bc -l)
availableokC=$(echo "scale=2; $availableBlockC * $sizeBlockC / 1073741824" | bc -l)
echo "total C: $totalokC"
echo "available C: $availableokC"

# Saves the heredoc result on variables for the second disk
smbclient //192.168.0.37/Compartida adminPassword -U administrator -c du | grep block > mypipe &
while read linea; do
  totalBlockD=$(echo $linea | awk '{print $1}')
  availableBlockD=$(echo $linea | awk '{print $6}')
  sizeBlockD=$(echo $linea | awk '{print $5}')
  sizeBlockD=${sizeBlockD//./}
  #sizeBlockD=${sizeBlockD:0:${#sizeBlockD}-1}
done < mypipe
rm mypipe

totalokD=$(echo "scale=2; $totalBlockD * $sizeBlockD / 1073741824" | bc -l)
availableokD=$(echo "scale=2; $availableBlockD * $sizeBlockD / 1073741824" | bc -l)
echo "total D: $totalokD"
echo "available D: $availableokD"

used100c=$(echo "($availableokC * 100) / $totalokC" | bc)
used100d=$(echo "($availableokD * 100) / $totalokD" | bc)

# Inserts values in the intranet database
query="insert into MetricaEspacioSauron (Date, TotalC, FreeC, Used100C, TotalD, FreeD, Used100D) values ('$dateNow', $totalokC, $availableokC, $used100c, $totalokD, $availableokD, $used100d)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
