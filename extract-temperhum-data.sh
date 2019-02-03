#!/bin/bash

# Este script recoge los datos del log generado por el programa que comprueba
# la temperatura en el CPD, y los guarda en un log en XML

# Cambiamos a la carpeta donde se guardan los datos de la temperatura
cd /home/fileServer/almacen/Seguridad/2013_SGSI/Temperatura\ CPD/

# Variables
fechaAnterior=""
fecha=""
temperatura=""
humedad=""

# Los datos se guardan en el siguiente formato:

#   1    2      3      4        5               6   7    8
# número , temperatura , humedad,punto de rocío , fecha hora
# 2450 , 27,06 , 36,12,10,76 , 06/09/2013 11:10:45

# Borramos los valores del año 2015 de la base de datos
query="DELETE FROM MetricaTemperatura WHERE Fecha > '2015-01-01' AND Fecha <'2015-12-31' "
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

# Leemos los ficheros que empiezan por 2014-, línea a línea
ls -v 2015-* | while read file
do
  while read linea
  do
    fecha=$(echo $linea | awk '{print $7}')
    fecha=$(echo $fecha | awk -F '/' '{print $3"-"$2"-"$1}')
    # Para cada fecha, leemos solo el primero. Guardamos la última fecha en
    # una variable, si es igual, no escribimos en el XML TODO: Cambiar a MySQL
    if [ -z "$fechaAnterior" -o "$fecha" != "$fechaAnterior" ] && [ ! -z "$fecha" ]
    then
      temperatura=$(echo $linea | awk '{print $3}')
      temperatura=${temperatura//,/.}
      humedad=$(echo $linea | awk '{print $5}' | awk 'BEGIN { FS="," }{print $1 "," $2}')
      humedad=${humedad//,/.}

# Inserts values in the intranet database
#fecha=$(date +"%Y-%m-%d")
query="insert into MetricaTemperatura (Fecha, Temperatura, Humedad) values ('$fecha', $temperatura, $humedad)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

    fi
    fechaAnterior=$fecha
  done <"$file"
done

