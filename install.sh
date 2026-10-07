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

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
TMP_BIN="/tmp/buho-installer"
REPO_BIN="https://raw.githubusercontent.com/TaquitoSuabe/ADMBuho/main/extras/buho-installer"

# 1. Usar binario local precompilado si existe
if [ -n "$BASE_DIR" ] && [ -f "$BASE_DIR/target/x86_64-unknown-linux-musl/release/buho-installer" ]; then
    exec "$BASE_DIR/target/x86_64-unknown-linux-musl/release/buho-installer" "$@"
elif [ -n "$BASE_DIR" ] && [ -f "$BASE_DIR/extras/buho-installer" ]; then
    exec "$BASE_DIR/extras/buho-installer" "$@"
fi

# 2. Descargar instalador precompilado oficial
echo -e "${C_CYAN}[•]${C_RESET} ${C_YELLOW}Preparando instalador oficial ADMBuho...${C_RESET}"
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_BIN" -o "$TMP_BIN"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP_BIN" "$REPO_BIN"
else
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
    curl -fsSL "$REPO_BIN" -o "$TMP_BIN"
fi

chmod +x "$TMP_BIN"
trap 'rm -f "$TMP_BIN"' EXIT INT TERM

# 3. Ejecutar instalador compilado
exec "$TMP_BIN" "$@"
