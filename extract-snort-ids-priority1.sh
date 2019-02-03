#!/bin/bash

# Extracts from syslog the number priority 1 attacks detected by zentyal IDS

# Variables
dateTemp=""
datePrevious=""
dateNow=""
total=0
# Creamos una pipe temporal para poder acceder a las variables creadas dentro del bucle
mkfifo mypipe

# Extraemos del fichero las líneas que contienen "Priority: 1"
zcat /var/log/snort/alert.1.gz | grep Priority:\ 1 > mypipe &
while read linea; do
  if [ -z "$dateNow" ]
  then
    # Si ésta es la primera línea que leemos, inicializamos las variables de dateNow
    dateTemp=$(echo $linea | awk '{print substr($0,1,5)}')
    dateTemp=`date '+%Y'`/$dateTemp
    dateNow=$(date -d "$dateTemp" +%F)
    datePrevious="$dateNow"
    total=1
  else
    # No es la primera linea, comprobamos si es la misma dateNow que antes
    dateTemp=$(echo $linea | awk '{print substr($0,1,5)}')
    dateTemp=`date '+%Y'`/$dateTemp
    dateNow=$(date -d "$dateTemp" +%F)
    if [ "$dateNow" != "$datePrevious" ]
    then
      # Ya hemos terminado de recoger datos para ésta dateNow, guardamos el dato en sql
      query="delete from MetricaIDS where Date='$dateNow'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      query="insert into MetricaIDS (Date, Number) values ('$dateNow', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      datePrevious="$dateNow"
      total=1
    else
      # Sumamos 1 al número total de datos encontrados con ésta dateNow
      total=$((total + 1))
    fi
  fi
done < mypipe

if [ $total -gt 0 ]
then
# Si hemos encontrado datos, borramos del mySql los datos con la misma dateNow,
# por si acaso, e insertamos el valor obtenido
query="delete from MetricaIDS where Date='$dateNow'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

query="insert into MetricaIDS (Date, Number) values ('$dateNow', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
fi

# Deletes temp pipe
rm mypipe
