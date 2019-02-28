#!/bin/bash

# Gets the temperature  data from the log generated by temperhum program, and saves it on XML

# Changes to the folder where the data is saved
cd /home/fileServer/logs/Temperature/

# Variables
previousDate=""
date=""
temperature=""
humidity=""
year=$(date +%Y)

# Los datos se guardan en el siguiente formato:

#   1    2      3      4        5               6   7    8
# number , temperature , humidity, dew point , date hour
# 2450 , 27,06 , 36,12,10,76 , 06/09/2018 11:10:45

# Deletes all the values for the current year from the database
query="DELETE FROM Temperature WHERE Date > '$year-01-01' AND Date <'$year-12-31' "
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

# Reads all the files for this year
ls -v $year-* | while read file
do
  while read linea
  do
    date=$(echo $linea | awk '{print $7}')
    date=$(echo $date | awk -F '/' '{print $3"-"$2"-"$1}')
    # For each date, reads only the first one. Saves the last date on a variable.
    # If the data is the same, doesn't write it on XML
    previousDate" ] && [ ! -z "$date" ]
    then
      temperature=$(echo $linea | awk '{print $3}')
      temperature=${temperature//,/.}
      humidity=$(echo $linea | awk '{print $5}' | awk 'BEGIN { FS="," }{print $1 "," $2}')
      humidity=${humidity//,/.}

# Inserts values in the intranet database
#date=$(date +"%Y-%m-%d")
query="insert into Temperature (Date, Temperature, Humidity) values ('$date', $temperature, $humidity)"
echo $query
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF

    fi
    previousDate=$date
  done <"$file"
done
