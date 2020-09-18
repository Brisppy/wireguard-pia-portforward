# wireguard-pia-portforward

A heavily modified fork of https://github.com/thrnz/docker-wireguard-pia

Allows the use of a 'gateway' VM for routing traffic through a Wireguard tunnel, while portforwarding to a specific host.

## Requirements
* The Wireguard kernel module must already be installed on the host.
* An active [PIA](https://www.privateinternetaccess.com) subscription.
* A VM or PC with two interfaces; one Internet interface (Used to establish the tunnel) and one VPN Network interface, used by other hosts to reach the Internet through the VM.

## Config
The following ENV vars are written to the systemd service file:

| ENV Var | Function |
|-------|------|
|```LOC=swiss```|Location of the server to connect to. Available classic/legacy locations are listed [here](https://www.privateinternetaccess.com/vpninfo/servers?version=1001&client=x-alpha) and available 'next-gen' servers are listed [here](https://serverlist.piaservers.net/vpninfo/servers/new). For classic/legacy locations, LOC should be set to the location's index value, and for 'next-gen' servers the 'id' value should be used. Example values include ```us_california```, ```ca_ontario```, and ```swiss```. If left empty, or an invalid location is specified, the container will print out all available locations for the selected infrastructure and exit.
|```USER=p00000000```|PIA username
|```PASS=xxxxxxxx```|PIA password
|```USEMODERN=0/1```| Set this to 1 to use the '[next gen](https://www.privateinternetaccess.com/blog/private-internet-access-next-generation-network-now-available-for-beta-preview/)' network, or 0 to use the classic/legacy network. This must be set to 1 for ```PORT_FORWARDING``` to function. Defaults to 1 if not specified.
|```KEEPALIVE=25```|If defined, PersistentKeepalive will be set to this in the Wireguard config.
|```VPNDNS=8.8.8.8, 8.8.4.4```|Use these DNS servers in the Wireguard config. Defaults to PIA's DNS servers if not specified.
|```PORT_FORWARDING=0/1```|Whether to enable port forwarding. Requires ```USEMODERN=1``` and a supported server. Defaults to 0 if not specified. The forwarded port number is dumped to ```/pia-shared/port.dat``` and then pushed to another host via SSH.
|```EXIT_ON_FATAL=0/1```|There is no error recovery logic at this stage. If something goes wrong we simply go to sleep. By default the container will continue running until manually stopped. Set this to 1 to force the container to exit when an error occurs. Exiting on an error may not be desirable behavior if other containers are sharing the connection.
|```PUSH_PORT=0/1```|If you wish to automatically forward a port, change to 1.
|```FORWARD_HOST=```|OPTIONAL: IP address of the forwarded host.
|```FORWARD_USER=```|OPTIONAL: Username for account which writes new port on forward host.
|```FORWARD_PASS=```|OPTIONAL: Password for account which writes new port on forward host.
|```MAIL_NOTIFY=0/1```|OPTIONAL: Sets whether an email is sent on success or failure of portforward. (STARTTLS SMTP SERVERS ONLY)
|```MAILSERVER=```|OPTIONAL: IP or FQDN of mail server.
|```MAILPORT=```|OPTIONAL: Port used to connect to mail server.
|```MAILUSER=```|OPTIONAL: Username for mail server account.
|```MAILPASS=```|OPTIONAL: Password for mail server account.

## Install
### Install required packages:
> apt install ca-certificates curl iptables jq openssl wireguard-tools resolvconf sshpass nmap python3

### Clone the repository:
```
git clone https://github.com/Brisppy/wireguard-pia-portforward
mkdir /scripts
mv ./wireguard-pia-portforward/ /scripts/
```

### Modify ENV variables and move vpn-gateway.service to /etc/systemd/service/
```
mv /scripts/wireguard-pia-portforward/vpn-gateway.service /etc/systemd/system/
systemctl enable vpn-gateway
```

### Enable IP forwarding:

Set net.ipv4.ip_forward (in /etc/sysctl.conf) to 1.

### Add the following iptables rules, substituting your own values:

The ROUTED variables relate to the interface and network on which the vpn-gateway is connected to other hosts which will tunnel through it to the Internet.
```
iptables -A FORWARD -s ROUTED_NETWORK -i ROUTED_INTERFACE -o wg0 -m conntrack --cstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --cstate RELATED,ESTABLISHED -j ACCEPT
iptables -A POSTROUTING -o wg0 -j MASQUERADE
```

Save iptables rules to file
```
iptables-save > /etc/iptables.rules
```

Add an iptables restore command to crontab
```
@reboot USER    iptables-restore < /etc/iptables.rules
```

Permit execution of scripts:
```
chmod +x /scripts/* -R
```

### Make sure to update the Network configuration on connected hosts to use vpn_gateway as their default gateway.

# Optional
If using port forwarding, but not using the provided PUSH_PORT function:
* After port forwarding is activated, you will need to add some iptables rules to forward the port to a specific host, replacing the $VARIABLEs with your own values.
```
iptables -A PREROUTING -t nat -i wg0 -p tcp --dport $FORWARDED_PORT -j DNAT --to $FORWARD_HOST:$FORWARDED_PORT
iptables -A FORWARD -p tcp -d $FORWARD_HOST --dport $FORWARDED_PORT -j ACCEPT
```

If forwarding a port to a specific host:
* Set PUSH_PORT to 1
* SSH into the host to ensure it is working and the fingerprint is added.
* Modify the LOCAL_INT variable of portforward.sh (Line 4) to be the Internet-connected interface (e.g eth0).
* Add the portforward-check.sh script to crontab.
```
@hourly USER    /scripts/portforward-check.sh >> /var/log/portforward-check.log
```

If using mail notifications:
* Modify ENV variables in the systemd service file.
* Add Mail ENV variables to user account (/etc/environment or user profile).
```
MAIL_NOTIFY=1/0
MAILSERVER=
MAILPORT=
MAILUSER=
MAILPASS=
```

## Credits
Some bits and pieces and ideas have been borrowed from the following:
* https://github.com/thrnz/docker-wireguard-pia
* https://github.com/activeeos/wireguard-docker
* https://github.com/cmulk/wireguard-docker
* https://github.com/dperson/openvpn-client
* https://github.com/pia-foss/desktop
* https://gist.github.com/triffid/da48f3c99f1ff334571ae49be80d591b
