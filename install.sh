#!/bin/bash
# ========================================================
# Instalador Oficial ADMBuho (@El_IBuhonero)
# Animación y Flujo 1:1 estilo Chumo / ADMRufu
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
C_WHITE='\033[1;37m'
C_RESET='\033[0m'

spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

msg_bar() {
    echo -e "${C_CYAN}=====================================================${C_RESET}"
}

msg_bar3() {
    echo -e "${C_CYAN}-----------------------------------------------------${C_RESET}"
}

clear 2>/dev/null || true
msg_bar
echo -e "${C_GREEN}         ⚜ ADMBuho • Oficial @El_IBuhonero ⚜         ${C_RESET}"
msg_bar
echo -e "${C_YELLOW}              INSTALADOR AUTOMATIZADO               ${C_RESET}"
msg_bar

# 1. Crear directorios base
mkdir -p /usr/local/bin
mkdir -p /etc/ADMBuho
mkdir -p /etc/ADMBuho/proxies

# Detener monitor previo si existiera
systemctl stop buho-monitor 2>/dev/null || true

anim_task() {
    local label="$1"
    shift
    local i=0
    
    ("$@") >/dev/null 2>&1 &
    local pid=$!
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r  ${C_CYAN}•${C_RESET} ${C_YELLOW}%-32s${C_RESET} ${C_CYAN}%s${C_RESET}" "$label..." "${spin:$i:1}"
        sleep 0.08
    done
    wait "$pid"
    local rc=$?
    
    if [ $rc -eq 0 ]; then
        printf "\r  ${C_GREEN}[ ✓ ]${C_RESET} ${C_WHITE}%-32s${C_RESET} ${C_GREEN}LISTO${C_RESET}     \n" "$label"
    else
        printf "\r  ${C_RED}[ ✗ ]${C_RESET} ${C_YELLOW}%-32s${C_RESET} ${C_RED}FALLÓ${C_RESET}     \n" "$label"
    fi
}

anim_pkg() {
    local pkg="$1"
    local label=$(echo "$pkg" | tr '[:lower:]' '[:upper:]')
    local i=0
    
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        printf "  ${C_GREEN}[ ✓ ]${C_RESET} ${C_WHITE}%-32s${C_RESET} ${C_GREEN}PRESENTE${C_RESET}\n" "$label"
        return 0
    fi
    
    (export DEBIAN_FRONTEND=noninteractive; apt-get install -y -qq "$pkg") >/dev/null 2>&1 &
    local pid=$!
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r  ${C_CYAN}•${C_RESET} ${C_YELLOW}INSTALANDO %-21s${C_RESET} ${C_CYAN}%s${C_RESET}" "$label..." "${spin:$i:1}"
        sleep 0.08
    done
    wait "$pid"
    
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        printf "\r  ${C_GREEN}[ ✓ ]${C_RESET} ${C_WHITE}%-32s${C_RESET} ${C_GREEN}INSTALADO${C_RESET}\n" "$label"
    else
        printf "\r  ${C_RED}[ ✗ ]${C_RESET} ${C_YELLOW}%-32s${C_RESET} ${C_RED}ERROR${C_RESET}    \n" "$label"
    fi
}

anim_download() {
    local label="$1"
    local url="$2"
    local dest="$3"
    local tmp="${dest}.tmp"
    local i=0
    
    (
        curl -fsSL "$url" -o "$tmp" && chmod +x "$tmp" && mv -f "$tmp" "$dest"
    ) >/dev/null 2>&1 &
    local pid=$!
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r  ${C_CYAN}•${C_RESET} ${C_YELLOW}DESCARGANDO %-20s${C_RESET} ${C_CYAN}%s${C_RESET}" "$label..." "${spin:$i:1}"
        sleep 0.08
    done
    wait "$pid"
    local rc=$?
    
    if [ $rc -eq 0 ] && [ -s "$dest" ]; then
        printf "\r  ${C_GREEN}[ ✓ ]${C_RESET} ${C_WHITE}%-32s${C_RESET} ${C_GREEN}INSTALADO${C_RESET}\n" "$label"
    else
        printf "\r  ${C_RED}[ ✗ ]${C_RESET} ${C_YELLOW}%-32s${C_RESET} ${C_RED}ERROR${C_RESET}    \n" "$label"
    fi
}

anim_copy() {
    local label="$1"
    local src="$2"
    local dest="$3"
    local tmp="${dest}.tmp"
    cp -f "$src" "$tmp" && chmod +x "$tmp" && mv -f "$tmp" "$dest"
    printf "  ${C_GREEN}[ ✓ ]${C_RESET} ${C_WHITE}%-32s${C_RESET} ${C_GREEN}INSTALADO${C_RESET}\n" "$label"
}

# 2. Actualización de paquetes
echo -e "${C_YELLOW}  [+] ACTUALIZANDO INDICE DE PAQUETES DEL SISTEMA...${C_RESET}"
anim_task "ACTUALIZAR REPOSITORIOS" apt-get update -qq

msg_bar3
echo -e "${C_YELLOW}  [+] INSTALANDO DEPENDENCIAS ESENCIALES...${C_RESET}"
msg_bar3

pkgs=(curl wget ca-certificates libpam-runtime net-tools lsof jq iptables socat unzip cron)
for p in "${pkgs[@]}"; do
    anim_pkg "$p"
done

msg_bar
echo -e "${C_YELLOW}  [+] INSTALANDO NUCLEO Y BINARIOS OFICIALES...${C_RESET}"
msg_bar

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_BASE="https://raw.githubusercontent.com/TaquitoSuabe/ADMBuho/main/extras"

if [ -f "$BASE_DIR/target/x86_64-unknown-linux-musl/release/admbuho" ]; then
    anim_copy "ADMBUHO (CORE)" "$BASE_DIR/target/x86_64-unknown-linux-musl/release/admbuho" /usr/local/bin/admbuho
    anim_copy "BUHO-AUTH (PAM)" "$BASE_DIR/target/x86_64-unknown-linux-musl/release/buho-auth" /usr/local/bin/buho-auth
    anim_copy "BUHO-MONITOR (DAEMON)" "$BASE_DIR/target/x86_64-unknown-linux-musl/release/buho-monitor" /usr/local/bin/buho-monitor
elif [ -f "$BASE_DIR/extras/admbuho" ]; then
    anim_copy "ADMBUHO (CORE)" "$BASE_DIR/extras/admbuho" /usr/local/bin/admbuho
    anim_copy "BUHO-AUTH (PAM)" "$BASE_DIR/extras/buho-auth" /usr/local/bin/buho-auth
    anim_copy "BUHO-MONITOR (DAEMON)" "$BASE_DIR/extras/buho-monitor" /usr/local/bin/buho-monitor
else
    anim_download "ADMBUHO (CORE)" "$REPO_BASE/admbuho" /usr/local/bin/admbuho
    anim_download "BUHO-AUTH (PAM)" "$REPO_BASE/buho-auth" /usr/local/bin/buho-auth
    anim_download "BUHO-MONITOR (DAEMON)" "$REPO_BASE/buho-monitor" /usr/local/bin/buho-monitor
fi

# Binarios de protocolos auxiliares
if [ -f "$BASE_DIR/extras/SlowDNS.bin" ]; then
    anim_copy "BADVPN-UDPGW" "$BASE_DIR/extras/badvpn-udpgw" /usr/local/bin/badvpn-udpgw
    anim_copy "SLOWDNS SERVER" "$BASE_DIR/extras/SlowDNS.bin" /usr/local/bin/SlowDNS.bin
    anim_copy "UDP-CUSTOM CORE" "$BASE_DIR/extras/udp-amd64.bin" /usr/local/bin/udp-amd64.bin
elif [ -d "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS" ]; then
    [ -f "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/badvpn-udpgw" ] && anim_copy "BADVPN-UDPGW" "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/badvpn-udpgw" /usr/local/bin/badvpn-udpgw
    [ -f "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/SlowDNS.bin" ] && anim_copy "SLOWDNS SERVER" "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/x86_64/SlowDNS.bin" /usr/local/bin/SlowDNS.bin
    [ -f "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/udp-amd64.bin" ] && anim_copy "UDP-CUSTOM CORE" "$BASE_DIR/admchg_latamsrc/VERSIONWEB/BINARIOS/udp-amd64.bin" /usr/local/bin/udp-amd64.bin
else
    anim_download "BADVPN-UDPGW" "$REPO_BASE/badvpn-udpgw" /usr/local/bin/badvpn-udpgw
    anim_download "SLOWDNS SERVER" "$REPO_BASE/SlowDNS.bin" /usr/local/bin/SlowDNS.bin
    anim_download "UDP-CUSTOM CORE" "$REPO_BASE/udp-amd64.bin" /usr/local/bin/udp-amd64.bin
fi

# Enlaces simbólicos estándar
ln -sf /usr/local/bin/admbuho /usr/bin/menu
ln -sf /usr/local/bin/admbuho /usr/bin/admbuho
ln -sf /usr/local/bin/SlowDNS.bin /usr/local/bin/dns-server
ln -sf /usr/local/bin/udp-amd64.bin /usr/local/bin/udp-custom

msg_bar
echo -e "${C_YELLOW}  [+] CONFIGURANDO INTEGRACIONES DEL SISTEMA...${C_RESET}"
msg_bar

configure_pam_service() {
    local PAM_FILE="$1"
    [ ! -f "$PAM_FILE" ] && return 0

    sed -i '/buho-auth/d' "$PAM_FILE"
    sed -i '/ADMBuho/d' "$PAM_FILE"

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

anim_task "MODULO PAM SSH" configure_pam_service "/etc/pam.d/sshd"
anim_task "MODULO PAM DROPBEAR" configure_pam_service "/etc/pam.d/dropbear"

# Configurar y arrancar buho-monitor como servicio Systemd
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

start_monitor() {
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl enable --now buho-monitor >/dev/null 2>&1 || true
}

anim_task "SERVICIO BUHO-MONITOR" start_monitor

msg_bar
echo -e "${C_GREEN}     ⚜ ¡ADMBuho Instalado y Configurado con Éxito! ⚜     ${C_RESET}"
msg_bar
echo -e " Inicie el menú en cualquier momento escribiendo: ${C_YELLOW}menu${C_RESET}"
msg_bar
echo ""
