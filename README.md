# wireguard-pia-portforward

A heavily modified fork of https://github.com/thrnz/docker-wireguard-pia

Allows the use of a 'gateway' VM for routing traffic through a Wireguard tunnel, while portforwarding to a specific host.

**A little note: some of the documentation and script mdofications were done at separate points and may be inaccurate, if something doesn't work or there are any issues / inconsistencies, please let me know.**

### WHY?
The benefit of using a VM for this purpose is that it allows you to seamlessly route data over the VPN tunnel from inside of you own network, requiring ZERO configuraiton on end devices. You can even assign a VLAN to a wireless ntwork and route wifi devices through the tunnel. Another option is of course to connect other VMs or computers to the VPN network.

## Requirements
* The Wireguard kernel module must already be installed on the host.
* An active [PIA](https://www.privateinternetaccess.com) subscription.
* A VM or PC with two interfaces; one Internet interface (Used to establish the tunnel) and one VPN Network interface, used by other hosts to reach the Internet through the VM.

## Config
The following ENV vars are written to the systemd service override file:

| ENV Var | Function |
|-------|------|
|```LOC=xxx```|Location of the server to connect to. Available classic/legacy locations are listed [here](https://www.privateinternetaccess.com/vpninfo/servers?version=1001&client=x-alpha) and available 'next-gen' servers are listed [here](https://serverlist.piaservers.net/vpninfo/servers/new). For classic/legacy locations, LOC should be set to the location's index value, and for 'next-gen' servers the 'id' value should be used. Example values include ```us_california```, ```ca_ontario```, and ```swiss```. If left empty, or an invalid location is specified, the container will print out all available locations for the selected infrastructure and exit.
|```USER=pxxxxxxx```|PIA username
|```PASS=xxxxxxxx```|PIA password
|```USEMODERN=0/1```| Set this to 1 to use the '[next gen](https://www.privateinternetaccess.com/blog/private-internet-access-next-generation-network-now-available-for-beta-preview/)' network, or 0 to use the classic/legacy network. This must be set to 1 for ```PORT_FORWARDING``` to function. Defaults to 1 if not specified.
|```KEEPALIVE=25```|If defined, PersistentKeepalive will be set to this in the Wireguard config.
|```VPNDNS=1.1.1.1, 1.0.0.1```|Use these DNS servers in the Wireguard config. Defaults to PIA's DNS servers if not specified.
|```PORT_FORWARDING=0/1```|Whether to enable port forwarding. Requires ```USEMODERN=1``` and a supported server. Defaults to 0 if not specified. The forwarded port number is dumped to ```/pia-shared/port.dat``` and then pushed to another host via SSH.
|```EXIT_ON_FATAL=0/1```|There is no error recovery logic at this stage. If something goes wrong we simply go to sleep. By default the container will continue running until manually stopped. Set this to 1 to force the container to exit when an error occurs. Exiting on an error may not be desirable behavior if other containers are sharing the connection.
|```PUSH_PORT=0/1```|If you wish to automatically forward a port, change to 1.
|```FORWARD_HOST=```|OPTIONAL: IP address of the forwarded host.
|```FORWARD_USER=```|OPTIONAL: Username for account which writes new port on forward host.
|```FORWARD_PASS=```|OPTIONAL: Password for account which writes new port on forward host.

## Install
### Install required packages:
> apt install ca-certificates curl iptables jq openssl wireguard-tools resolvconf sshpass python3

### Clone the repository:
```
git clone https://github.com/Brisppy/wireguard-pia-portforward
mkdir /scripts
mv ./wireguard-pia-portforward/ /scripts/
mv /scripts/wireguard-pia-portforward/scripts/* /scripts/
```

### Modify ENV variables and move vpn-gateway.service to /etc/systemd/service/
```
mv /scripts/wireguard-pia-portforward/vpn-gateway.service /etc/systemd/system/
mv /scripts/wireguard-pia-portforward/vpn-gateway.service.d /etc/systemd/system/
systemctl enable vpn-gateway
```

# Optional
### If you are routing other traffic through the VM:
* Set net.ipv4.ip_forward (in /etc/sysctl.conf) to 1.
* Add the following iptables rules, replacing the $ROUTED variables with the interface and network on which the vpn-gateway is connected to other hosts which will tunnel through it to the Internet.
```
iptables -A FORWARD -s $ROUTED_NETWORK -i $ROUTED_INTERFACE -o wg0 -m conntrack --cstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --cstate RELATED,ESTABLISHED -j ACCEPT
iptables -A POSTROUTING -o wg0 -j MASQUERADE
```
* Save iptables rules to file
```
iptables-save > /etc/iptables.rules
```
* Add an iptables restore command to crontab
```
@reboot root    iptables-restore < /etc/iptables.rules
```

### If forwarding a port to a specific host with the PUSH_PORT function:
* SSH into the host to ensure it is working and the fingerprint is added.
* The port can then be grabbed from the HOME directory of the SSH user in a file named 'port'.

## Automatically check if port is forwarded:
* Modify the 'portforward_check.sh' LOCAL_INT variable to one which can reach the Internet outside of the tunnel.
* Create a crontab entry

```@hourly  root    /scripts/portforward-check.sh >> /var/log/portforward-check.log

## Credits
Some bits and pieces and ideas have been borrowed from the following:
* https://github.com/thrnz/docker-wireguard-pia
* https://github.com/activeeos/wireguard-docker
* https://github.com/cmulk/wireguard-docker
* https://github.com/dperson/openvpn-client
* https://github.com/pia-foss/desktop
* https://gist.github.com/triffid/da48f3c99f1ff334571ae49be80d591b
