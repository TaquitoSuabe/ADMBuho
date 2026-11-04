#!/bin/bash
# ============================================================
#  ADMBuho Official Uninstaller & System Purger (@El_IBuhonero)
# ============================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m[ADMBuho] ERROR: Debe ejecutar el desinstalador como root (sudo -i).\033[0m"
    exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${RED}============================================================${RESET}"
echo -e "       ${YELLOW}ADMBuho Official Uninstaller & Suite Purger${RESET}"
echo -e "${RED}============================================================${RESET}"
echo -e "${YELLOW}Esta operación apagará y removerá todos los servicios,${RESET}"
echo -e "${YELLOW}túneles, iptables, reglas tc, PAM y archivos de ADMBuho.${RESET}\n"

# Confirmación si es interactivo
if [ "$1" != "--force" ] && [ "$1" != "-f" ] && [ "$1" != "-y" ]; then
    read -rp "$(echo -e "${CYAN}¿Confirmar desinstalación y purga total? [S/N]: ${RESET}")" CONFIRM
    case "$CONFIRM" in
        [sS]|[yY]|[sS][iI]) ;;
        *)
            echo -e "${CYAN}[•] Operación cancelada por el usuario.${RESET}"
            exit 0
            ;;
    esac
fi

# Si el binario compilado está disponible, usar su lógica nativa de purga
if [ -x "/usr/local/bin/admbuho" ]; then
    /usr/local/bin/admbuho uninstall --force
    exit 0
fi

echo -e "\n${CYAN}[•]${RESET} ${YELLOW}Deteniendo y deshabilitando servicios Systemd...${RESET}"
SERVICES=(
    buho-monitor.service
    checkuser.service
    buho-speedlimit.service
    buho-pyproxy-autostart.service
    zivpn.service
    udp-custom.service
    hcr.service
    hcr-server.service
    hysteria.service
    hysteria-server.service
    slowdns.service
    slowdns-mux.service
    btun.service
    bhttp.service
    bilola.service
    bilola-server.service
    badvpn.service
    stunnel4.service
    stunnel.service
    sslh.service
    xray.service
    v2ray.service
    openvpn.service
    wg-quick@wg0.service
)

for svc in "${SERVICES[@]}"; do
    systemctl stop "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
done

# Purgar servicios dinámicos
for f in /etc/systemd/system/buho-py-* /etc/systemd/system/buho-pyproxy@* /etc/systemd/system/python.* /etc/systemd/system/nodews.* /etc/systemd/system/badvpn-*; do
    if [ -f "$f" ]; then
        sname=$(basename "$f")
        systemctl stop "$sname" 2>/dev/null || true
        systemctl disable "$sname" 2>/dev/null || true
        rm -f "$f"
    fi
done

echo -e "${CYAN}[•]${RESET} ${YELLOW}Terminando procesos residuales...${RESET}"
PROCS=(
    buho-monitor
    buho-auth
    zivpn
    udp-custom
    udp-amd64.bin
    udp-arm64.bin
    hcr-server
    hysteria
    SlowDNS.bin
    vaydns-server
    dns-server
    bilola-server
    btun
    badvpn-udpgw
    PPub.py
    PPriv.py
    POpen.py
    wsproxy.js
)

for p in "${PROCS[@]}"; do
    pkill -9 -f "$p" 2>/dev/null || true
done

echo -e "${CYAN}[•]${RESET} ${YELLOW}Limpiando reglas de iptables y control de tráfico (tc)...${RESET}"
for comment in ADMBuho zivpn udp-custom badvpn hysteria slowdns; do
    while true; do
        num=$(iptables -t nat -L PREROUTING --line-numbers -n 2>/dev/null | grep "$comment" | head -n1 | awk '{print $1}')
        [ -z "$num" ] && break
        iptables -t nat -D PREROUTING "$num" 2>/dev/null || break
    done
done
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -j MASQUERADE 2>/dev/null || true

for iface in $(ls /sys/class/net 2>/dev/null); do
    tc qdisc del dev "$iface" root 2>/dev/null || true
done

echo -e "${CYAN}[•]${RESET} ${YELLOW}Restaurando módulos PAM y OpenSSH...${RESET}"
sed -i '/buho-auth/d' /etc/pam.d/sshd 2>/dev/null || true
sed -i '/ADMBuho/d' /etc/pam.d/sshd 2>/dev/null || true
sed -i '/buho-auth/d' /etc/pam.d/dropbear 2>/dev/null || true
sed -i '/ADMBuho/d' /etc/pam.d/dropbear 2>/dev/null || true
rm -f /etc/ssh/sshd_config.d/00-admbuho.conf
rm -rf /etc/systemd/system/dropbear.service.d

systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

echo -e "${CYAN}[•]${RESET} ${YELLOW}Purgando unidades Systemd...${RESET}"
for svc in "${SERVICES[@]}"; do
    rm -f "/etc/systemd/system/$svc"
done
systemctl daemon-reload 2>/dev/null || true
systemctl reset-failed 2>/dev/null || true

echo -e "${CYAN}[•]${RESET} ${YELLOW}Eliminando binarios y accesos directos...${RESET}"
BINARIES=(
    /usr/local/bin/admbuho
    /usr/local/bin/buho-installer
    /usr/local/bin/buho-auth
    /usr/local/bin/buho-monitor
    /usr/local/bin/zivpn
    /usr/local/bin/udp-custom
    /usr/local/bin/hcr-server
    /usr/local/bin/hysteria
    /usr/local/bin/SlowDNS.bin
    /usr/local/bin/dns-server
    /usr/local/bin/vaydns-server
    /usr/local/bin/bilola-server
    /usr/local/bin/badvpn-udpgw
    /usr/local/bin/dropbear-buho
    /usr/local/bin/dropbearkey-buho
    /usr/bin/admbuho
    /usr/bin/menu
    /usr/bin/hcr-server
    /usr/bin/zivpn
    /bin/zivpn
    /usr/bin/udp-custom
    /usr/bin/vaydns-server
    /usr/bin/SlowDNS.bin
    /usr/bin/badvpn-udpgw
    /usr/bin/hysteria
    /usr/bin/bilola-server
)

for b in "${BINARIES[@]}"; do
    rm -f "$b"
done

echo -e "${CYAN}[•]${RESET} ${YELLOW}Eliminando carpetas de configuración y datos...${RESET}"
rm -rf /etc/ADMBuho /etc/zivpn /etc/udp /etc/hysteria /etc/slowdns /etc/bilola /etc/badvpn /var/log/admbuho
rm -rf /tmp/buho* /tmp/zivpn* /tmp/udp*

echo -e "${CYAN}[•]${RESET} ${YELLOW}Limpiando perfiles de usuario y crontab...${RESET}"
for p in /root/.bashrc /etc/bash.bashrc /etc/profile /root/.profile; do
    if [ -f "$p" ]; then
        sed -i '/ADMBuho/d' "$p" 2>/dev/null || true
        sed -i '/admbuho/d' "$p" 2>/dev/null || true
        sed -i '/\/usr\/bin\/menu/d' "$p" 2>/dev/null || true
        sed -i '/alias menu=/d' "$p" 2>/dev/null || true
    fi
done
crontab -l 2>/dev/null | grep -v 'admbuho' | grep -v 'ADMBuho' | crontab - 2>/dev/null || true

echo -e "\n${GREEN}[ ✓ ] Desinstalación y purga total de ADMBuho completada.${RESET}"
echo -e "${GREEN}El servidor ha quedado limpio y sin rastros de la suite.${RESET}\n"
