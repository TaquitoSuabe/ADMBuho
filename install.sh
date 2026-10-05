#!/bin/bash
# ========================================================
# Instalador Oficial ADMBuho (@El_IBuhonero)
# ========================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Debe ejecutar el instalador como root (sudo -i)."
    exit 1
fi

C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_RESET='\033[0m'

clear 2>/dev/null || true
echo -e "${C_CYAN}-----------------------------------------------------${C_RESET}"
echo -e "${C_GREEN}   ⚜ ADMBuho • Oficial @El_IBuhonero ⚜   ${C_RESET}"
echo -e "${C_CYAN}-----------------------------------------------------${C_RESET}"
echo -e "${C_YELLOW}[+] Iniciando instalación del sistema ADMBuho...${C_RESET}"

# 1. Crear directorios base
mkdir -p /usr/local/bin
mkdir -p /etc/ADMBuho
mkdir -p /etc/ADMBuho/proxies

# 2. Instalar dependencias esenciales mínimas
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq curl wget libpam-runtime >/dev/null 2>&1 || true

# 3. Ubicación o descarga de binarios
systemctl stop buho-monitor 2>/dev/null || true

safe_download() {
    local url="$1"
    local dest="$2"
    local tmp="${dest}.tmp"
    curl -fsSL "$url" -o "$tmp"
    chmod +x "$tmp"
    mv -f "$tmp" "$dest"
}

safe_install() {
    local src="$1"
    local dest="$2"
    local tmp="${dest}.tmp"
    cp -f "$src" "$tmp"
    chmod +x "$tmp"
    mv -f "$tmp" "$dest"
}

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_BASE="https://raw.githubusercontent.com/TaquitoSuabe/ADMBuho/main/extras"

if [ -f "$BASE_DIR/target/x86_64-unknown-linux-musl/release/admbuho" ]; then
    echo -e "${C_GREEN}[+] Instalando binarios locales compilados...${C_RESET}"
    safe_install "$BASE_DIR/target/x86_64-unknown-linux-musl/release/admbuho" /usr/local/bin/admbuho
    safe_install "$BASE_DIR/target/x86_64-unknown-linux-musl/release/buho-auth" /usr/local/bin/buho-auth
    safe_install "$BASE_DIR/target/x86_64-unknown-linux-musl/release/buho-monitor" /usr/local/bin/buho-monitor
elif [ -f "$BASE_DIR/extras/admbuho" ]; then
    echo -e "${C_GREEN}[+] Instalando binarios desde extras/...${C_RESET}"
    safe_install "$BASE_DIR/extras/admbuho" /usr/local/bin/admbuho
    safe_install "$BASE_DIR/extras/buho-auth" /usr/local/bin/buho-auth
    safe_install "$BASE_DIR/extras/buho-monitor" /usr/local/bin/buho-monitor
else
    echo -e "${C_YELLOW}[+] Descargando binarios precompilados...${C_RESET}"
    safe_download "$REPO_BASE/admbuho" /usr/local/bin/admbuho
    safe_download "$REPO_BASE/buho-auth" /usr/local/bin/buho-auth
    safe_download "$REPO_BASE/buho-monitor" /usr/local/bin/buho-monitor
fi

# Copiar o descargar binarios auxiliares oficiales de Chumo
if [ -f "$BASE_DIR/extras/SlowDNS.bin" ]; then
    echo -e "${C_GREEN}[+] Copiando binarios auxiliares desde extras/...${C_RESET}"
    safe_install "$BASE_DIR/extras/badvpn-udpgw" /usr/local/bin/badvpn-udpgw
    safe_install "$BASE_DIR/extras/SlowDNS.bin" /usr/local/bin/SlowDNS.bin
    safe_install "$BASE_DIR/extras/udp-amd64.bin" /usr/local/bin/udp-amd64.bin
elif [ -d "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS" ]; then
    echo -e "${C_GREEN}[+] Copiando binarios auxiliares oficiales de Chumo...${C_RESET}"
    [ -f "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/badvpn-udpgw" ] && safe_install "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/badvpn-udpgw" /usr/local/bin/badvpn-udpgw
    [ -f "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/SlowDNS.bin" ] && safe_install "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/SlowDNS.bin" /usr/local/bin/SlowDNS.bin
    [ -f "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/udp-amd64.bin" ] && safe_install "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/udp-amd64.bin" /usr/local/bin/udp-amd64.bin
else
    echo -e "${C_YELLOW}[+] Descargando binarios auxiliares oficiales...${C_RESET}"
    safe_download "$REPO_BASE/badvpn-udpgw" /usr/local/bin/badvpn-udpgw
    safe_download "$REPO_BASE/SlowDNS.bin" /usr/local/bin/SlowDNS.bin
    safe_download "$REPO_BASE/udp-amd64.bin" /usr/local/bin/udp-amd64.bin
fi

# Enlaces simbólicos estándar
ln -sf /usr/local/bin/admbuho /usr/bin/menu
ln -sf /usr/local/bin/admbuho /usr/bin/admbuho
ln -sf /usr/local/bin/SlowDNS.bin /usr/local/bin/dns-server
ln -sf /usr/local/bin/udp-amd64.bin /usr/local/bin/udp-custom

# 4. Configurar integración PAM para SSH y Dropbear
echo -e "${C_YELLOW}[+] Configurando módulo PAM SQLite (buho-auth)...${C_RESET}"
configure_pam_service() {
    local PAM_FILE="$1"
    [ ! -f "$PAM_FILE" ] && return 0

    # Evitar duplicados
    sed -i '/buho-auth/d' "$PAM_FILE"

    local TMP_FILE=$(mktemp)
    cat << 'PAM_CONF' > "$TMP_FILE"
# ADMBuho SQLite PAM Authentication Integration
auth       sufficient   pam_exec.so quiet expose_authtok /usr/local/bin/buho-auth --auth
account    sufficient   pam_exec.so quiet /usr/local/bin/buho-auth --account
session    optional     pam_exec.so quiet /usr/local/bin/buho-auth --session-open
session    optional     pam_exec.so quiet /usr/local/bin/buho-auth --session-close
PAM_CONF

    cat "$PAM_FILE" >> "$TMP_FILE"
    mv "$TMP_FILE" "$PAM_FILE"
    chmod 644 "$PAM_FILE"
}

configure_pam_service "/etc/pam.d/sshd"
configure_pam_service "/etc/pam.d/dropbear"

# 5. Configurar y arrancar buho-monitor como servicio Systemd
echo -e "${C_YELLOW}[+] Configurando servicio en segundo plano (buho-monitor)...${C_RESET}"
cat << 'SVC' > /etc/systemd/system/buho-monitor.service
[Unit]
Description=ADMBuho Session and Multilogin Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/buho-monitor
Restart=always
RestartSec=5
StandardOutput=null
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable --now buho-monitor >/dev/null 2>&1 || true

echo -e "${C_CYAN}-----------------------------------------------------${C_RESET}"
echo -e "${C_GREEN}   ¡ADMBuho instalado y listo para usar!   ${C_RESET}"
echo -e "${C_CYAN}-----------------------------------------------------${C_RESET}"
echo -e " Inicie el menú en cualquier momento escribiendo: ${C_YELLOW}menu${C_RESET}"
echo ""
