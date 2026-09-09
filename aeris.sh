#!/bin/bash
export TERM=xterm
trap ctrl_c INT
function ctrl_c(){
	rm -r content data 2>/dev/null
	exit 0
}

function banner(){
echo -e "\033[31m"
echo -e "
   ▄▄      ▓█████  ██▀███   ██▓  ██████ 
 ▒████▄    ▓█   ▀ ▓██ ▒ ██ ▓ ▒▓ ██    ▒ 
 ▒██  ▀█▄  ▒███   ▓██ ░▄█ ▒▒██▒░ ▓██▄   
 ░██▄▄▄▄██ ▒▓█  ▄ ▒██▀▀█▄  ░██░  ▒   ██▒ 
  ▓█   ▓██▒░▒████▒░██▓ ▒██ ░██░▒██████▒▒
  ▒▒   ▓▒█░░░ ▒░ ░░ ▒▓ ░▒▓░░▓  ▒ ▒▓▒ ▒ ░
   ▒   ▒▒ ░ ░ ░  ░  ░▒ ░ ▒░ ▒ ░░ ░▒  ░ ░
   ░   ▒      ░     ░░   ░  ▒ ░░  ░  ░  
"
echo -e "\033[0m"
}

function help(){
	echo -ne "\n \e[4mOptions:\e[0m\n"
	echo -ne "\t-p\t Use aircrack to capture a handshake and then crack it\n"
	echo -ne "\t-a\t Use hostapd and dnsmasq to create an access point with a captive portal built with php\n"
	echo -ne "\t--help\t Show this message\n"
}

##############################    data    ########################################################
function set_interface (){	
	echo -ne "\n======Interfaces======\n"
	interfaces=$(iw dev | grep Interface | awk '{print $2}')
	echo "$interfaces"
	iw dev | grep Interface | awk '{print $2}' > content/interfaces.txt 2>&1

	interface="sdlkjfh"
	while !(grep $interface content/interfaces.txt >/dev/null 2>&1); do
		echo -ne "\nInterface name to use: " && read -r interface
		if !(grep $interface content/interfaces.txt >/dev/null 2>&1); then
			echo -e "\nThe interface $interface does not exist"
		fi
	done; sleep 0.5

	echo $interface > ./content/interface
}

function check_ap_programs(){
	echo -e "\nChecking required programs...\n"
	sleep 0.5
	programs_list=("dnsmasq" "hostapd" "php")

	for program in "${programs_list[@]}"; do
		if [ "$(which $program)" ]; then
			echo ". . . . $program is installed"
		else
			echo ". . . . $program is not installed :("
			exit 0
		fi
	done; echo -e "\nAll good :)\n"
	sleep 1; clear
}

function check_wifi_programs(){
	echo -e "\nChecking required programs...\n"
	sleep 0.5
	programs_list=("aircrack-ng")

	for program in "${programs_list[@]}"; do
		if [ "$(which $program)" ]; then
			echo ". . . . $program is installed"
		else
			echo ". . . . $program is not installed :("
			exit 0
		fi
	done; echo -e "\nAll good :)\n"
	sleep 1; clear
}

################################    Program start    #############################

if [ "$(id -u)" -eq 0 ];then
	echo ""
else
    echo "This script needs to be run as root."
    exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "" ];then
	banner
	help
	exit 0
fi

mkdir content data 2>/dev/null
banner

if [ "$1" == "-a" ];then
	check_ap_programs
	set_interface
	/bin/bash ./src/ap.sh

elif [ "$1" == "-p" ];then
	check_wifi_programs
	set_interface
	/bin/bash ./src/wifipass.sh
fi

