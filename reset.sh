#!/bin/bash
ip link set $moninterface down >/dev/null 2>&1
sleep 1
iw dev $moninterface set type monitor >/dev/null 2>&1
sleep 1
ip link set $moninterface up >/dev/null 2>&1
sleep 1
airmon-ng stop $moninterface > /dev/null 2>&1
systemctl start wpa_supplicant NetworkManager > /dev/null 2>&1
