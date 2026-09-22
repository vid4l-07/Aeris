<div align="center">

# AERIS

Bash toolkit for WiFi security audits.

![screenshot](.github/screenshot.png)

</div>

**Aeris** is a Bash toolkit for performing WiFi security audits on Linux. It automates two scenarios frequently used in authorized penetration testing and academic training:

- **WPA/WPA2 handshake capture and cracking**: capture a genuine handshake from a target network and break it with a dictionary attack.
- **Rogue Access Point + Captive Portal**: impersonate a legitimate network to study how devices and users behave when connecting to untrusted access points.

Everything is built on standard, well-known components (`aircrack-ng`, `hostapd`, `dnsmasq`, PHP), so the whole process is auditable and doesn't rely on opaque custom binaries.

> [!important]
> This software is intended exclusively for authorized audits and academic training. The author assumes no responsibility for misuse of the software.

## Features

### WPA/WPA2 handshake capture & cracking (`-p`)

- Scans nearby networks with `airodump-ng`
- Sends deauthentication packets to force clients to reconnect (`aireplay-ng`)
- Captures the WPA/WPA2 4-way handshake
- Runs a dictionary attack with `aircrack-ng`
- Saves the recovered password to `password.txt`

### Rogue Access Point + Captive Portal (`-a`)

- Creates a rogue AP with `hostapd`, with optional WPA2 encryption (an 8–63 character password; leave it empty for an open network)
- Automatic DHCP and DNS redirection with `dnsmasq` (all DNS queries resolve to the portal)
- PHP-based captive portal that captures submitted credentials
- Templates: **Google**, **Instagram** (auto-detected from `page/templates/`)
- Live dashboard showing connected clients and the captured data
- Credentials are flushed to `creds.txt` on exit

## Requirements

- Linux (preferably **Kali**)
- A Wi-Fi interface that supports **monitor mode** for `-p`, or **AP mode** for `-a`
- An X11 session for `-p` (it relies on `xterm`)
- `locate` (from `mlocate` / `plocate`) to locate the default wordlist

Dependencies per mode:

| Mode | Packages |
| ---- | -------- |
| `-p` | `aircrack-ng`, `iw`, `xterm` |
| `-a` | `hostapd`, `dnsmasq`, `php`, `iw` |

## Installation

Clone the repository:

```bash
git clone https://github.com/vid4l-07/Aeris.git
cd Aeris
```

Then install the dependencies for the mode you want to use.

## Usage

All commands must be run as root. Running `./aeris.sh` with no arguments shows the help banner.

```bash
sudo ./aeris.sh --help   # show help
sudo ./aeris.sh -a       # rogue AP + captive portal
sudo ./aeris.sh -p       # WPA/WPA2 handshake capture and cracking
```

### WPA/WPA2 mode: `sudo ./aeris.sh -p`

1. `wpa_supplicant` and `NetworkManager` are stopped and the interface is set to monitor mode with `airmon-ng`.
2. A terminal window opens showing nearby networks (`airodump-ng`).
3. Enter the target network's **ESSID**, **MAC address (BSSID)** and **channel**.
4. Enter a **wordlist** path for the attack. Leave it empty to use the first `rockyou.txt` found by `locate`.
5. The capture begins: `airodump-ng` records the handshake to `data/handshake*.cap` while `aireplay-ng` sends a burst of deauthentication packets (`--deauth 10`) to force a client reconnect.
6. `aircrack-ng` then attacks the captured handshake in a new window. When finished, the cracked password is written to `password.txt` and the interface is restored.

### Rogue AP + Captive Portal mode: `sudo ./aeris.sh -a`

1. Configure the AP:
   - **SSID** — the network name to broadcast.
   - **Channel** — a value between 1 and 12 (2.4 GHz).
   - **Password** — optional WPA2 passphrase of 8 to 63 character. Leave empty for an open AP.
   - **Template** — pick the captive portal look for the available templates.
2. A virtual interface `ap0` is created on `10.10.0.1/24`, and conflicting services (`wpa_supplicant`, `NetworkManager`, `systemd-resolved`) are stopped.
3. `hostapd` and `dnsmasq` start: the DHCP pool covers `10.10.0.2–10.10.0.30` and all DNS queries are redirected to the portal (`10.10.0.1`).
4. The selected template is copied into the portal directory and served by PHP's built-in web server (`php -S 10.10.0.1:80`). Any victim connecting sees the fake login page. Submitted credentials are appended to the portal's `data.txt`.
5. Press `Ctrl+C` to stop: captured credentials are saved to `creds.txt`, the AP and portal are torn down, and the interface is restored.

## Adding a captive portal template

Adding a template requires no code changes: templates are auto-detected from the directories in `page/templates/`.
Copy an existing one (e.g. `page/templates/google`) or create one from scratch.

Creating a template from scratch is just a matter of wiring a valid form:
- Create the folder `page/templates/<name>/` with your page files.
- The login form must use `method="POST"` with `action="../save.php"` and include at least `<input name="email">` and `<input name="password">`, the fields save.php stores to creds.txt.
- `page/captive_portal/index.php` already redirects to `./html_page/index.html`, so your `index.html` is served as the entry page automatically.

## Cleanup and Restoration

When finishing or interrupting the process:

- Temporary directories are removed (`content/`, `data/`)
- Captured credentials are stored in `creds.txt`
- The virtual AP interface (`ap0`) is deleted and the physical interface is restored (`reset.sh`)
- Running `hostapd` / `dnsmasq` processes are stopped
- NetworkManager, `wpa_supplicant` and `systemd-resolved` are unmasked and restarted

---

### Legal Warning

This software is intended exclusively for:

- Authorized audits
- Academic training

The author assumes no responsibility for misuse of the software.

