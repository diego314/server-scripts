#!/bin/bash

# Extracts from the syslog the number of blocked packages by zentyal firewall

# Variables
dateTemp=""
datePrevious=""
dateNow=""
total=0

# Creamos una pipe temporal para poder acceder a las variables creadas dentro del bucle
mkfifo mypipe

# Extraemos del fichero las líneas que contienen "zentyal-firewall" y "drop"
cat /var/log/syslog.1 | grep zentyal-firewall | grep drop > mypipe &
while read linea; do
  if [ -z "$dateNow" ]
  then
    # Si ésta es la primera línea que leemos, inicializamos las variables de dateNow
    dateTemp=$(echo $linea | awk '{print $1 $2}')
    dateNow=$(date -d "$dateTemp" +%F)
    datePrevious="$dateNow"
    total=1
  else
    # No es la primera linea, comprobamos si es la misma dateNow que antes
    dateTemp=$(echo $linea | awk '{print $1 $2}')
    dateNow=$(date -d "$dateTemp" +%F)
    if [ "$dateNow" != "$datePrevious" ]
    then
      # Ya hemos terminado de recoger datos para ésta dateNow, guardamos el dato en sql
      query="delete from MetricaFirewall where Date='$dateNow'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      query="insert into MetricaFirewall (Date, Number) values ('$dateNow', $total)"
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
# Si hemos encontrado datos, borramos del mySql los datos con la misma dateNow,
# por si acaso, e insertamos el valor obtenido
query="delete from MetricaFirewall where Date='$dateNow'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

query="insert into MetricaFirewall (Date, Number) values ('$dateNow', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
fi

# Deletes temp pipe
rm mypipe
