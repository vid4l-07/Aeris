#!/bin/bash
trap '' INT

interface=$(/bin/cat ./content/interfaz)

echo "[+] Restaurando interfaz $moninterface..."

if [ "$1" == "monitor" ];then
	airmon-ng stop $interface >/dev/null

elif [ "$1" == "ap" ];then
	ip link set ap0 down >  /dev/null 2>&1
	iw dev ap0 del > /dev/null 2>&1
	ip link delete ap0 > /dev/null 2>&1
	ip addr flush dev $interface > /dev/null 2>&1
	ip link set $interface up > /dev/null 2>&1
fi

pkill hostapd
pkill dnsmasq 

systemctl -q unmask wpa_supplicant NetworkManager
systemctl -q restart wpa_supplicant NetworkManager
systemctl -q unmask systemd-resolved-monitor.socket systemd-resolved-varlink.socket systemd-resolved
systemctl -q restart systemd-resolved-monitor.socket systemd-resolved-varlink.socket systemd-resolved
