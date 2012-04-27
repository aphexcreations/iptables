#!/bin/bash

##
## Iptables Script
##
##  Type: Webserver
##  Distro: Ubuntu 10.04
##  Provider: Linode
##  IP Version: ip4
##
## Author: Brendon Crawford
## Warning: Do not blindly run this script. Make sure you first understand what
##          it does. Author takes no responsibility for any damages this script
##          may cause.
##

ADDRESS_PUB=$(ifconfig eth0 | \
              awk -F: '/inet addr:/ {print $2}' | \
              awk '{ print $1 }')

FILE_STARTUP="/etc/networking/if-pre-up.d/iptablesload"
FILE_RULES_IN="/etc/iptables.rules"

## Flush rules
iptables --flush

## Set default policies
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

## Allow all incoming and forward traffic on loopback
iptables -A INPUT -i lo -j ACCEPT

## Allow currently open connections to stay open
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

## Allow ping
iptables -A INPUT -i eth0 -d ${ADDRESS_PUB} -m icmp -p icmp \
    --icmp-type echo-request -j ACCEPT

## Allow ssh
iptables -A INPUT -i eth0 -d ${ADDRESS_PUB} -m tcp -p tcp --dport ssh -j ACCEPT

## Allow Web on Public
iptables -A INPUT -i eth0 -d ${ADDRESS_PUB} -m tcp -p tcp --dport www -j ACCEPT
iptables -A INPUT -i eth0 -d ${ADDRESS_PUB} -m tcp -p tcp \
    --dport https -j ACCEPT

## Save
iptables-save -c > ${FILE_RULES_IN}

## Add to Startup
if [ !-x "${FILE_STARTUP}" ]; then
cat <<EOF > ${FILE_STARTUP}
#!/bin/bash
if [ -r "${FILE_RULES_IN}" ]; then
    iptables-restore < ${FILE_RULES_IN}
fi;
exit 0
EOF
chmod +x ${FILE_STARTUP}
fi;

## Exit
exit 0

