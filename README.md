# AERIS

AERIS es un framework desarrollado en Bash para la auditoría de seguridad en redes WiFi con fines educativos y de pruebas autorizadas.

El proyecto implementa dos modos principales de operación:

1. Captura y crackeo de handshakes WPA/WPA2
2. Despliegue de Access Point malicioso con portal cautivo

---

## Funcionalidades
**1. Auditoría WPA/WPA2**

- Activación del modo monitor
- Escaneo de redes disponibles
- Captura de handshake WPA/WPA2
- Envío de paquetes de desautenticación
- Ataque por diccionario
- Exportación de contraseña recuperada a password.txt

Dependencias:
```
aircrack-ng
```

**2. Rogue Access Point + Portal Cautivo**

- Creación de punto de acceso configurable
- WPA2 opcional
- Configuración automática de DHCP y DNS
- Portal cautivo basado en PHP
- Plantillas disponibles:
    - Google
    - Apple
    - Instagram
- Captura de credenciales introducidas por clientes
- Redirección opcional a Internet mediante NAT

Dependencias:
```
hostapd
dnsmasq
php
```
Las credenciales capturadas se almacenan en:
```creds.txt```

---

## Estructura del Proyecto
```
aeris/
│
├── aeris.sh          # Script principal
├── src/ 
│   ├── ap.sh             # Lógica del Access Point y portal cautivo
│   ├── reset.sh          # Restauración de interfaz
│   └── wifipass.sh       # Captura y crackeo de WPA/WPA2
├── pages/            # Plantillas del portal cautivo 
│   ├── google/
│   ├── apple/
│   └── instagram/
└── utils/            # Scripts auxiliares

```

---

## Uso
- Instalacion
```bash
git clone https://github.com/vid4l-07/Aeris.git
```

- Mostrar ayuda
```bash
sudo ./aeris.sh --help
```

- Rogue AP con Portal Cautivo
```bash
sudo ./aeris.sh -a
```

- Captura y Crackeo de handshake WPA/WPA2
```bash
sudo ./aeris.sh -p
```
---

## Limpieza y Restauración

Al finalizar o interrumpir el proceso:
- Se eliminan directorios temporales (content/, data/)
- Se restauran las interfaces de red
- Se detienen procesos asociados
- Se ejecuta reset.sh para devolver la interfaz a estado normal

---

## Advertencia Legal

Este software está destinado exclusivamente a:

- Laboratorios personales
- Auditorías autorizadas
- Formación académica
- El autor no asume responsabilidad por el uso indebido del software.
