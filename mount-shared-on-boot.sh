#!/bin/bash

# Mounts three shared folders so they can be used by the program Backintime

mount -t cifs //192.168.0.56/Almacen/ /mnt/amidalaAlmacen/ -o username=administrator,password=adminPassword,rw,uid=1000

mount -t cifs //192.168.0.37/Copias\ sql/ /mnt/sauron2Copiassql/ -o username=administrator,password=adminPassword,rw,uid=1000

mount -t cifs //192.168.0.250/Eustat/ /mnt/eustat/ -o username=administrator,password=adminPassword,rw,uid=1000
