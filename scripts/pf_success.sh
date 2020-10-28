#!/bin/bash

new_port=$1

iptables-restore < /etc/iptables.rules
echo "$(date): Closing old port"
iptables -A PREROUTING -t nat -i wg0 -p tcp --dport $new_port -j DNAT --to $FORWARD_HOST:$new_port
iptables -A FORWARD -p tcp -d $FORWARD_HOST --dport $new_port -j ACCEPT
echo "$(date): Allowing incoming traffic on port $new_port"
