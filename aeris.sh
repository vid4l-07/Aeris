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
	echo -ne "\n \e[4mOpciones:\e[0m\n"
	echo -ne "\t-p\t Usa aircrack para capturar un handshake y luego crackearlo\n"
	echo -ne "\t-a\t Usa hostapd y dnsmasq para crear un punto de acceso con un portal cautivo montado con php\n"
	echo -ne "\t--help\t Muestra este mensaje\n"
}

##############################    datos    ########################################################
function set_interfaz (){	
	echo -ne "\n======Interfaces======\n"
	interfaces=$(iw dev | grep Interface | awk '{print $2}')
	echo "$interfaces"
	iw dev | grep Interface | awk '{print $2}' > content/interfaces.txt 2>&1

	interfaz="sdlkjfh"
    while !(grep $interfaz content/interfaces.txt >/dev/null 2>&1); do
		echo -ne "\nNombre de la interfaz a usar: " && read -r interfaz
		if !(grep $interfaz content/interfaces.txt >/dev/null 2>&1); then
			echo -e "\nLa interfaz $interfaz no existe"
		fi
	done; sleep 0.5

	echo $interfaz > ./content/interfaz
}

function programas_ap(){
	echo -e "\nComprobando programas necesarios...\n"
	sleep 0.5
	programaslist=("dnsmasq" "hostapd" "php")

	for programa in "${programaslist[@]}"; do
		if [ "$(which $programa)" ]; then
			echo ". . . . $programa esta instalado"
		else
			echo ". . . . $programa no esta instalado :("
			exit 0
		fi
	done; echo -e "\nTodo en orden :)\n"
	sleep 1; clear
}

function programas_wifi(){
	echo -e "\nComprobando programas necesarios...\n"
	sleep 1
	programaslist=("aircrack-ng")

	for programa in "${programaslist[@]}"; do
		if [ "$(which $programa)" ]; then
			echo ". . . . $programa esta instalado"
		else
			echo ". . . . $programa no esta instalado :("
			exit 0
		fi
	done; echo -e "\nTodo en orden :)\n"
	sleep 1; clear
}

################################    Inicio del programa    #############################

if [ "$(id -u)" -eq 0 ];then
	echo ""
else
    echo "Este script necesita ser ejecutado como root."
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
	programas_ap
	set_interfaz
	/bin/bash ./src/ap.sh

elif [ "$1" == "-p" ];then
	programas_wifi
	set_interfaz
	/bin/bash ./src/wifipass.sh
fi


