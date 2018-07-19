#!/bin/sh
id="$1"
myip=$(sudo grep -m 1 '"ipv6"' /etc/cjdroute.conf | awk '{ print $2 }' | sed 's/[",]//g')

while true; do

   # Manual local ip address broadcast
   for int in $(ls -1Atu /sys/class/net ); do
        ip=$(ip addr show $int | grep -v inet6 | grep -v '127.0.0.1' |grep inet | head -n 1 | awk '{print $2}' | awk -F "/" '{print $1}')
        if ! [ -z "$ip" ]; then
            echo -n "net:$ip:8008~shs:$id" |  sudo socat -T 1 - UDP4-DATAGRAM:255.255.255.255:8008,broadcast,so-bindtodevice=$int &
        fi
    done
    
    # Manual cjdns peer unicast
    read -a peers <<< `sudo nodejs /opt/cjdns/tools/peerStats 2>/dev/null | awk '{ if ($2 == "ESTABLISHED") print $1 }' | awk -F. '{ print $6".k" }' | xargs`
    for peer in "${peers[@]}"; do
        ip=$(sudo /opt/cjdns/publictoip6 $peer)
        echo -n net:$myip:8008~shs:$id | sudo socat -T 1 - UDP6-DATAGRAM:[$ip]:8008 &
    done

    sleep 15
done
