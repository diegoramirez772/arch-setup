#!/bin/bash
# Script maestro de instalación — arch-setup
# Lenovo IdeaPad 330 — AMD E2-9000 + Radeon R2 + Realtek 8821CE
# Uso: bash install/install.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; }
section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/arch-setup-install.log"

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }

# ─── Banner ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}"
echo "  █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗ "
echo " ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
echo " ███████║██████╔╝██║     ███████║    ███████╗█████╗     ██║   ██║   ██║██████╔╝"
echo " ██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ "
echo " ██║  ██║██║  ██║╚██████╗██║  ██║    ███████║███████╗   ██║   ╚██████╔╝██║     "
echo " ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
echo -e "${NC}"
echo "  Lenovo IdeaPad 330 — AMD E2-9000 + Radeon R2 + Realtek 8821CE"
echo "  Log: $LOG_FILE"
echo ""

# ─── Verificaciones previas ───────────────────────────────────────────────────
section "Verificaciones previas"

if [ "$EUID" -eq 0 ]; then
    error "No correr como root."
    exit 1
fi
info "Usuario: $(whoami)"

if ! ping -c 1 archlinux.org &>/dev/null; then
    error "Sin internet. Opciones:"
    echo "  1. Conectar celular por USB → Ajustes → Compartir internet por USB"
    echo "  2. Conectar cable ethernet"
    echo "  3. Ver docs/wifi-fix.md"
    exit 1
fi
info "Internet: OK"

log "Instalación iniciada por $(whoami)"

# ─── Paso 1: Post-install base ────────────────────────────────────────────────
section "PASO 1/2 — Stack base (puede tardar 20-30 min)"

if bash "$SCRIPT_DIR/2-post-install.sh"; then
    info "Post-install completado"
    log "2-post-install.sh: OK"
else
    EXIT_CODE=$?
    error "2-post-install.sh falló (código $EXIT_CODE)"
    echo ""
    echo "Scripts de reparación disponibles:"
    echo "  WiFi:      bash install/repair/fix-wifi.sh"
    echo "  Audio:     bash install/repair/fix-audio.sh"
    echo "  GRUB:      bash install/repair/fix-grub.sh"
    log "2-post-install.sh: FALLÓ con código $EXIT_CODE"
    exit 1
fi

# ─── Paso 2: Caelestia ────────────────────────────────────────────────────────
section "PASO 2/2 — Caelestia dots + Hyprland config"

if bash "$SCRIPT_DIR/3-caelestia-setup.sh"; then
    info "Caelestia setup completado"
    log "3-caelestia-setup.sh: OK"
else
    EXIT_CODE=$?
    error "3-caelestia-setup.sh falló (código $EXIT_CODE)"
    echo ""
    echo "Script de reparación disponible:"
    echo "  bash install/repair/fix-caelestia.sh"
    log "3-caelestia-setup.sh: FALLÓ con código $EXIT_CODE"
    exit 1
fi

# ─── Resumen final ────────────────────────────────────────────────────────────
section "Instalación completa"

echo -e "${GREEN}Todo listo.${NC} Reiniciá para entrar a Hyprland + caelestia."
echo ""
echo "  sudo reboot"
echo ""
echo "Si algo falla al reiniciar:"
echo "  WiFi:      bash install/repair/fix-wifi.sh"
echo "  Hyprland:  bash install/repair/fix-hyprland.sh"
echo "  Audio:     bash install/repair/fix-audio.sh"
echo "  GRUB:      bash install/repair/fix-grub.sh"
echo "  Caelestia: bash install/repair/fix-caelestia.sh"
echo ""
echo "Log completo: $LOG_FILE"
echo ""
log "Instalación completada OK"
