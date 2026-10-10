#!/bin/bash
# ============================================================
#  ADMBuho Official One-Line Installer (@El_IBuhonero)
# ============================================================
set -e

main() {
    REPO="TaquitoSuabe/ADMBuho"

    # Verificar permisos de root
    if [ "$EUID" -ne 0 ]; then
        echo -e "\033[0;31m[ADMBuho] ERROR: Debe ejecutar el instalador como root (sudo -i).\033[0m"
        exit 1
    fi

    # Detectar Arquitectura
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)          TARGET_ARCH="x86_64" ;;
        *) 
            echo -e "\033[0;31m[ADMBuho] Error: Arquitectura $ARCH no soportada.\033[0m"
            exit 1
            ;;
    esac

    BINARY="buho-installer"
    DEST="/tmp/buho-installer"

    # Cleanup al salir
    trap 'rm -f "$DEST"' EXIT INT TERM

    # Colores
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    RESET='\033[0m'

    echo -e "${CYAN}[•]${RESET} ${YELLOW}Preparando Instalador Oficial ADMBuho (@El_IBuhonero)...${RESET}"

    # Si existe un binario local en el entorno de desarrollo/pruebas, usarlo
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
    if [ -n "$BASE_DIR" ] && [ -f "$BASE_DIR/target/x86_64-unknown-linux-musl/release/$BINARY" ]; then
        cp "$BASE_DIR/target/x86_64-unknown-linux-musl/release/$BINARY" "$DEST"
        chmod +x "$DEST"
    elif [ -n "$BASE_DIR" ] && [ -f "$BASE_DIR/extras/$BINARY" ]; then
        cp "$BASE_DIR/extras/$BINARY" "$DEST"
        chmod +x "$DEST"
    else
        # Descargar desde GitHub Oficial
        URL="https://raw.githubusercontent.com/$REPO/main/extras/$BINARY?v=$(date +%s)"

        download_bin() {
            local u="$1"
            local d="$2"
            if command -v curl &>/dev/null; then
                if curl -4 -fsSL -H "Cache-Control: no-cache" --connect-timeout 15 "$u" -o "$d"; then
                    return 0
                fi
            fi
            if command -v wget &>/dev/null; then
                if wget -4 -q --no-cache --timeout=15 "$u" -O "$d"; then
                    return 0
                fi
            fi
            return 1
        }

        if ! download_bin "$URL" "$DEST"; then
            export DEBIAN_FRONTEND=noninteractive
            # Soporte de rescate para Debian 10 (Buster EOL) si no tiene curl instalado
            if [ -f /etc/debian_version ] && grep -qs '^10' /etc/debian_version; then
                mkdir -p /etc/apt/apt.conf.d
                echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive
                cat << 'EOF' > /etc/apt/sources.list
deb [check-valid-until=no] http://archive.debian.org/debian/ buster main contrib non-free
deb [check-valid-until=no] http://archive.debian.org/debian/ buster-updates main contrib non-free
deb [check-valid-until=no] http://archive.debian.org/debian-security buster/updates main contrib non-free
EOF
            fi
            apt-get update -qq >/dev/null 2>&1 || true
            apt-get install -y -qq curl ca-certificates >/dev/null 2>&1 || true
            if ! download_bin "$URL" "$DEST"; then
                echo -e "${RED}[ADMBuho] Error: No se pudo descargar el instalador desde $URL${RESET}"
                exit 1
            fi
        fi
        chmod +x "$DEST"
    fi

    # Detectar si hay una terminal TTY disponible para entrada
    HAS_TTY=false
    if (exec < /dev/tty) 2>/dev/null; then
        HAS_TTY=true
    fi

    # Ejecutar con terminal interactiva si está disponible
    if [ "$HAS_TTY" = true ]; then
        "$DEST" "$@" < /dev/tty
    else
        "$DEST" "$@"
    fi
}

main "$@"
