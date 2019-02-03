#!/bin/bash

# Locally encripts a series of backup files and uploads them to a cloud server with curl

cd /mnt/sauron2Copiassql/

declare -a databasesToEncrypt=(ControlSeguridad.bak Cris.bak Defseguridad.bak GV_CMT.BAK MAD_ICCM.BAK MEYSS_LAB.bak Meyss_pe.bak PaisVasco.bak Sepi.bak)


# Encripts the databases to upload
# For later decrypt we need to use the command:
# openssl enc -aes-256-cbc -d -in nombre.enc -out nombre -pass pass:password

# Encripts the databases listed on the array databasesToEncrypt
for i in "${!databasesToEncrypt[@]}"
do
  openssl enc -aes-256-cbc -e -in "${databasesToEncrypt[$i]}" -out "${databasesToEncrypt[$i]}.enc" -pass pass:"$passwordEnc"
  echo "finished encrypting ${databasesToEncrypt[$i]} database"
done

# Uploads the databases listed on the array databasesToEncrypt
for i in "${!databasesToEncrypt[@]}"
do
curl --user $Arsys1User:$Arsys1Password -T "${databasesToEncrypt[$i]}.enc" "https://www.cloudstorage.es/$Arsys1Disco/Bases%20de%20datos/Ultima%20copia/"
  echo "subida base de datos ${databasesToEncrypt[$i]}"
done

# Calculates the total up uploaded kbytes
for i in "${!databasesToEncrypt[@]}"
do
  sizeTemp=$(stat -c%s "${databasesToEncrypt[$i]}.enc")
  sizeTotal=$(( sizeTotal + sizeTemp ))
done

# Deletes from the local disk the encrypted files
for i in "${!databasesToEncrypt[@]}"
do
  rm -f "${databasesToEncrypt[$i]}.enc"
done

# Inserts values in the intranet database
fecha=$(date +"%Y-%m-%d")
query="insert into MetricaBackupArsys (Fecha, Kbytes, Satisfactoria) values ('$fecha', $sizeTotal, 1)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
