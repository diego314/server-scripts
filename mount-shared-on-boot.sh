#!/bin/bash

# Mounts three shared folders so they can be used by the program Backintime

mount -t cifs //192.168.0.56/Files/ /mnt/fileServer/ -o username=administrator,password=adminPassword,rw,uid=1000

mount -t cifs //192.168.0.37/sql\ backups/ /mnt/sqlServer/ -o username=administrator,password=adminPassword,rw,uid=1000

mount -t cifs //192.168.0.250/ProjectFiles/ /mnt/Project/ -o username=administrator,password=adminPassword,rw,uid=1000
