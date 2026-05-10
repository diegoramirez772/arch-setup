#!/bin/bash
# Reparación de hyprlock + hypridle
# Síntomas: pantalla no se bloquea, Super+L no hace nada, no suspende solo
# Uso: bash install/repair/fix-hyprlock.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

echo ""
echo "=== FIX HYPRLOCK + HYPRIDLE ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../../config"
HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"

# ─── Fix 1: Instalar paquetes ─────────────────────────────────────────────────
echo "--- Fix 1: Verificar instalación ---"
for pkg in hyprlock hypridle; do
    if pacman -Q "$pkg" &>/dev/null; then
        info "$pkg instalado"
    else
        warn "$pkg faltante — instalando..."
        sudo pacman -S --noconfirm "$pkg"
    fi
done

# ─── Fix 2: Copiar configs ────────────────────────────────────────────────────
echo ""
echo "--- Fix 2: Configs de hyprlock e hypridle ---"
mkdir -p "$HYPR_DIR"

if [ ! -f "$HYPR_DIR/hyprlock.conf" ] && [ -f "$CONFIG_DIR/hyprlock.conf" ]; then
    cp "$CONFIG_DIR/hyprlock.conf" "$HYPR_DIR/hyprlock.conf"
    info "hyprlock.conf copiado"
else
    info "hyprlock.conf ya existe"
fi

if [ ! -f "$HYPR_DIR/hypridle.conf" ] && [ -f "$CONFIG_DIR/hypridle.conf" ]; then
    cp "$CONFIG_DIR/hypridle.conf" "$HYPR_DIR/hypridle.conf"
    info "hypridle.conf copiado"
else
    info "hypridle.conf ya existe"
fi

# ─── Fix 3: Autostart en hyprland.conf ───────────────────────────────────────
echo ""
echo "--- Fix 3: Autostart en Hyprland ---"
if [ -f "$HYPR_CONF" ]; then
    grep -q "hypridle" "$HYPR_CONF" || { echo "exec-once = hypridle" >> "$HYPR_CONF"; info "hypridle agregado al autostart"; }
    grep -q "hyprlock" "$HYPR_CONF" && info "hyprlock referenciado en config" || warn "hyprlock no está en hyprland.conf — verificar keybinding Super+L"
else
    warn "hyprland.conf no encontrado"
fi

# ─── Fix 4: Arrancar hypridle manualmente ────────────────────────────────────
echo ""
echo "--- Fix 4: Arrancar hypridle ahora ---"
if pgrep -x hypridle &>/dev/null; then
    info "hypridle ya corriendo"
else
    read -rp "¿Arrancar hypridle ahora? (s/N): " start
    if [[ "$start" =~ ^[Ss]$ ]]; then
        hypridle &
        sleep 1
        pgrep -x hypridle &>/dev/null && info "hypridle corriendo" || warn "hypridle no arrancó — ver logs: journalctl -b | grep hypridle"
    fi
fi

# ─── Fix 5: Probar hyprlock ───────────────────────────────────────────────────
echo ""
echo "--- Fix 5: Probar hyprlock ---"
read -rp "¿Probar hyprlock ahora? (bloquea la pantalla) (s/N): " test
if [[ "$test" =~ ^[Ss]$ ]]; then
    hyprlock
fi

echo ""
echo "Tiempos configurados en hypridle.conf:"
echo "  5 min  — bloquea pantalla"
echo "  10 min — apaga pantalla"
echo "  30 min — suspend"
echo ""
echo "Para cambiar tiempos: nano ~/.config/hypr/hypridle.conf"
