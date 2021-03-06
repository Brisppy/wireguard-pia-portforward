#!/bin/bash

# Check the status of the port with nmap.
LOCAL_INT=ethXX
PORT=$(cat /pia-shared/port.dat)
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
LOCALIP=$(ip -f inet addr show $LOCAL_INT | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
STATUS=0

echo $(date)
STATUS=$(nmap -p $PORT $WANIP -S $LOCALIP | awk -F'/' '/open/ {print $1}')
if [ $STATUS = $PORT ]; then
        echo $PORT is open
else
        echo $PORT seems closed, checking again in 20 minutes...
	sleep 1320
	STATUS=$(nmap -p $PORT $WANIP -S $LOCALIP | awk -F'/' '/open/ {print $1}')
	if [ $STATUS = $PORT ]; then
		echo $PORT now open after waiting, exiting...
		exit 1
	else
		echo $PORT still closed, restarting...
	        # Restarting VPN GW service
	        sleep 10
	        echo Restarting VPN Gateway service...
	       	systemctl restart vpn-gateway.service
	fi
fi
