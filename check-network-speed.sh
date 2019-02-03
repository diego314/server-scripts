#!/bin/bash

# Checks internet speed by downloading a 500Mb test file

# Downloads file, redirecting it to /dev/null (we only need the speed)
averageSpeed=$(wget --output-document=/dev/null http://speedtest.wdc01.softlayer.com/downloads/test500.zip |& tail -n 4 | grep /dev/null | awk '{print substr($3,2);}')
averageSpeed=$(echo "averageSpeed * 8" | bc -l)

# Saves on mysql the resulting data
query="insert into AverageSpeed (Date, Speed) values ('"`date +%Y-%m-%d:%H:%M:%S`"', '$averageSpeed')"
mysql -h 192.168.0.163 intranet -u root -pmypassword << EOF
$query
EOF
