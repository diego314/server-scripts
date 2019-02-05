# Server scripts
A lot of scripts I made for checking the status of the company servers, keeping the intranet database updated with the results, and sending an email to the sysadmin if a problem is found.

Currently translating everything into English

### backup-mysql.sh
Makes a dump (backup) on zip format from  the local mysql databases, and a remote server in the network and copies these files into the assigned backup server.

### check-backup.sh
Checks backups to see if they are being done correctly. For doing this it checks how old the files are, and checks that there is at least one file that has been created/changed in the last two days. Since backups are done daily, this ensures at least the last backup was done correctly.

After that, it saves the result of the check in a mysql database If the backup is outdated, it also notifies the system administrator via email

### check-disk-space.sh
Checks the available space on the server's hard disk and saves it in a log. If the used space exceeds the maximum threshold (85%), it sends an alert email

### check-network-availability.sh
Checks if the internet connection is alive. We make a wget from three different known servers. If none responds, it probably means that the connection is offline

### check-network-speed.sh
Checks internet speed by downloading a 500Mb test file

### check-windows-disk-space.sh
Connects to a windows server with smbclient and checks both hard disks free space. A shared folder in each disk is needed on the windows server

### download-ftp-encrypted.sh

### download-ftp.sh

### encrypt-backup-cloud.sh
Locally encripts a series of backup files and uploads them to a cloud server with curl

### extract-backintime-syslog.sh

### extract-snort-ids-priority1.sh
Extracts from the syslog the number priority 1 attacks detected by zentyal IDS

### extract-temperhum-data.sh

### extract-zentyal-firewall.sh
Extracts from the syslog the number of blocked packages by zentyal firewall

### mount-shared-on-boot.sh
Mounts three shared folders so they can be used by the program Backintime

### ping-servers.sh
Sends a ping to all of the servers on a list, and sends an email if it finds any of them are not responding