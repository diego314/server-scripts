#!/bin/bash

# Este script extrae del syslog el número de paquetes bloqueados por el
# firewall de zentyal en una fecha concreta

# Variables
fechaTemp=""
fechaAnterior=""
fecha=""
total=0

# Creamos una pipe temporal para poder acceder a las variables creadas dentro del bucle
mkfifo mypipe

# Extraemos del fichero las líneas que contienen "zentyal-firewall" y "drop"
cat /var/log/syslog.1 | grep zentyal-firewall | grep drop > mypipe &
while read linea; do
  if [ -z "$fecha" ]
  then
    # Si ésta es la primera línea que leemos, inicializamos las variables de fecha
    fechaTemp=$(echo $linea | awk '{print $1 $2}')
    fecha=$(date -d "$fechaTemp" +%F)
    fechaAnterior="$fecha"
    total=1
  else
    # No es la primera linea, comprobamos si es la misma fecha que antes
    fechaTemp=$(echo $linea | awk '{print $1 $2}')
    fecha=$(date -d "$fechaTemp" +%F)
    if [ "$fecha" != "$fechaAnterior" ]
    then
      # Ya hemos terminado de recoger datos para ésta fecha, guardamos el dato en sql
      query="delete from MetricaFirewall where Fecha='$fecha'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      query="insert into MetricaFirewall (Fecha, Numero) values ('$fecha', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
      fechaAnterior="$fecha"
      total=1
    else
      # Sumamos 1 al número total de datos encontrados con ésta fecha
      total=$((total + 1))
    fi
  fi
done < mypipe

if [ $total -gt 0 ]
then
# Si hemos encontrado datos, borramos del mySql los datos con la misma fecha,
# por si acaso, e insertamos el valor obtenido
query="delete from MetricaFirewall where Fecha='$fecha'"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

query="insert into MetricaFirewall (Fecha, Numero) values ('$fecha', $total)"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
fi

# Eliminamos la pipe temporal
rm mypipe
