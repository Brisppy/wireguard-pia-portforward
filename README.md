# wireguard-pia-portforward

A heavily modified fork of https://github.com/thrnz/docker-wireguard-pia
Allows the use of a 'gateway' VM for routing traffic through a Wireguard tunnel, while portforwarding to a specific host.

## Requirements
* The Wireguard kernel module must already be installed on the host.
* An active [PIA](https://www.privateinternetaccess.com) subscription.

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
|```PORT_FORWARDING=0/1```|Whether to enable port forwarding. Requires ```USEMODERN=1``` and a supported server. Defaults to 0 if not specified. The forwarded port number is dumped to ```/pia-shared/port.dat``` for possible access by scripts in other containers.
|```EXIT_ON_FATAL=0/1```|There is no error recovery logic at this stage. If something goes wrong we simply go to sleep. By default the container will continue running until manually stopped. Set this to 1 to force the container to exit when an error occurs. Exiting on an error may not be desirable behavior if other containers are sharing the connection.
|```LOCAL_INT=```|Interface used to reach the Internet.
|```DESTHOST=```|IP address of the seedbox.
|```GATEWAY=```|IP address of the default gateway used to reach the Internet.
|```SEEDBOX_USER=```|Username for account which writes new port on seedbox host.
|```SEEDBOX_PASS=```|Password for account which writes new port on seedbox host.

## Credits
Some bits and pieces and ideas have been borrowed from the following:
* https://github.com/thrnz/docker-wireguard-pia
* https://github.com/activeeos/wireguard-docker
* https://github.com/cmulk/wireguard-docker
* https://github.com/dperson/openvpn-client
* https://github.com/pia-foss/desktop
* https://gist.github.com/triffid/da48f3c99f1ff334571ae49be80d591b