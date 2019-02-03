#!/bin/bash

# Este script descarga ficheros XML de una cuenta FTP, los desencripta
# y los copia a dos servidores locales, un Linux y un Windows, para
# finalmente borrarlos del servidor FTP

# Variables
noProblemFound=1 # 1: sin problemas, 2: error serverName, 3: error fileServer
carpetaremotaEnc="/FronturNuevaEncript/"
carpetalocal="/home/companyname/frontur/"
servidorftp="ftp.companyname.es"
nombreftp="companyname.es"
passwordftp="ftpPassword"
anyo=$(date +%Y)
anyomes=$(date +%m-%Y)
dia=$(date +%d)

# Descargamos la lista de ficheros del servidor FTP en un archivo "ftpListNoEnc"
ftp -n -i $servidorftp <<EOF
passive
quote USER $nombreftp
quote PASS $passwordftp

binary
cd $carpetaremotaEnc
mls . ftpListEnc
quit
EOF

# Editamos la lista de ficheros para convertirla en una lista de órdenes para
# descargar y borrar los ficheros
# Esto es necesario por si mientras descargamos ficheros se suben otros nuevos
for i in ftpListEnc
do
  # Duplicamos todas las lineas y añadimos los comandos get y del
  sed -i "p" $i
  sed -i '1~2 s/^/get "/' $i
  sed -i '1~2 s/$/"/' $i
  sed -i '0~2 s/^/delete "/' $i
  sed -i '0~2 s/$/"/' $i

  # Añadimos primeras lineas (comandos para abrir la conexión)
  sed -i '1i\#!/bin/bash\n\n#variables\n' $i
  sed -i '5i\servidorftp="ftp.companyname.es"' $i
  sed -i '6i\nombreftp="companyname.es"' $i
  sed -i '7i\passwordftp="ftpPassword"' $i
  sed -i '8i\#descargar cada fichero y borrarlo del servidor' $i
  sed -i '9i\ftp -n -i $servidorftp <<EOF' $i
  sed -i '10i\passive' $i
  sed -i '11i\quote USER $nombreftp' $i
  sed -i '12i\quote PASS $passwordftp' $i
  sed -i '13i\binary' $i
  sed -i '14i\cd $carpetaremota' $i

  # Añadimos pie (comandos para cerrar la conexión)
  echo -e "quit" >> $i
  echo -e "EOF" >> $i
  echo -e "echo ok" >> $i
done

# Añadimos tres líneas más al fichero a ejecutar
sed -i '5i\carpetaremota="/FronturNuevaEncript/"' ftpListEnc
sed -i '6i\carpetalocal="/home/companyname/frontur/"' ftpListEnc
sed -i '17i\lcd "$carpetalocal"encriptados' ftpListEnc

# Cambiamos los permisos, ejecutamos el fichero, y finalmente lo borramos
chmod 777 ftpListEnc
./ftpListEnc
rm ftpListEnc

# Desencriptamos lo ficheros descargados
cp *.class "$carpetalocal"encriptados/
cd "$carpetalocal"encriptados/
for file in *.xml
do
  java desencriptar "$file" ../desencriptados/"$file"
done

# Borramos los ficheros encriptados
rm -f "$carpetalocal"encriptados/*.xml
rm -f "$carpetalocal"encriptados/*.XML
rm -f "$carpetalocal"encriptados/*.class

# Eliminamos los saltos de carro no precedidos por ">"
shopt -s nullglob
cd "$carpetalocal"desencriptados/
for f in *.xml *.XML
do
  perl -0777 -p -e 's/(\n|\r|\r\n)(?!(\<|(\s\s\s\s\<)|(\s\s\<))|\Z)//g' "$f" > temporal
  perl -0777 -p -e 's/([^\>])(\n|\r|\r\n)/\1/g' temporal > temporal2
  rm "$f"
  rm temporal
  mv temporal2 "$f"
done

# Copiamos los ficheros desencriptados a serverName
copiadoOk=0
while [ $copiadoOk -eq 0 ]; do
  smbclient //serverName/TRABAJOS adminPassword -U administrator -c "cd IET/$anyo/LLEG_DIA; recurse; prompt; mput *"
  if [ $? -eq 0 ]; then
    copiadoOk=1
  else
  # El servidor serverName da a veces errores de copia. Si es así, esperamos 60 segundos y volvemos a intentarlo
# Inserts values in the intranet database
dateNow=$(date +"%Y-%m-%d")
query="INSERT INTO MetricaXmlFronturenc (Date, Successful) VALUES ('$dateNow', 2)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
    sleep 60
  fi
done

# Creamos en local las carpetas del mes-año y del dia, si no existen
if [ ! -d "$anyomes" ]; then
  mkdir "$anyomes"
fi
cd "$anyomes"
if [ ! -d "$dia" ]; then
  mkdir "$dia"
fi
cd "$carpetalocal"desencriptados/
mv *.XML *.xml "$carpetalocal"desencriptados/"$anyomes"/"$dia"

# Copiamos los ficheros al servidor fileServer
copiadoOk=0
while [ $copiadoOk -eq 0 ]; do
  smbclient //fileServer/trabajos adminPassword -U administrator -c "cd IET; recurse; prompt; mput *"
  if [ $? -eq 0 ]; then
    copiadoOk=1
  else
  # fileServer no ha dado error nunca, pero por si acaso, hacemos igual que con serverName
# Inserts values in the intranet database
dateNow=$(date +"%Y-%m-%d")
query="INSERT INTO MetricaXmlFronturenc (Date, Successful) VALUES ('$dateNow', 3)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
    sleep 60
  fi
done

# Borramos los ficheros una vez copiados
# (los movemos a una carpeta a modo de copia de seguridad)
mv "$carpetalocal"desencriptados/* "$carpetalocal"desencriptados2/

if [[ $(date +%k) -eq 23 ]]; then
# Inserts values in the intranet database
fecha=$(date +"%Y-%m-%d")
query="INSERT INTO MetricaXmlFronturenc (Date, Successful) VALUES ('$fecha', 1)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
fi
