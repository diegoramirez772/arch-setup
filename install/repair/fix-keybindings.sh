#!/bin/bash
# Reparación de keybindings — Hyprland
# Síntomas: atajos no funcionan, volumen/brillo sin respuesta, screenshots fallan
# Uso: bash install/repair/fix-keybindings.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

echo ""
echo "=== FIX KEYBINDINGS — Hyprland ==="
echo ""

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
KEYS_CONF="$HOME/.config/hypr/keybindings.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../../config"

# ─── Fix 1: Dependencias de los keybindings ───────────────────────────────────
echo "--- Fix 1: Verificar dependencias ---"
MISSING=()
command -v brightnessctl &>/dev/null || MISSING+=("brightnessctl")
command -v pactl         &>/dev/null || MISSING+=("pipewire-pulse")
command -v grim          &>/dev/null || MISSING+=("grim")
command -v slurp         &>/dev/null || MISSING+=("slurp")
command -v swappy        &>/dev/null || MISSING+=("swappy")
command -v wl-copy       &>/dev/null || MISSING+=("wl-clipboard")
command -v wofi          &>/dev/null || MISSING+=("wofi")
command -v notify-send   &>/dev/null || MISSING+=("libnotify")

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Paquetes faltantes: ${MISSING[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
    info "Dependencias instaladas"
else
    info "Todas las dependencias OK"
fi

# ─── Fix 2: Copiar keybindings.conf ──────────────────────────────────────────
echo ""
echo "--- Fix 2: Verificar keybindings.conf ---"
if [ ! -f "$KEYS_CONF" ]; then
    if [ -f "$CONFIG_DIR/hyprland-keybindings.conf" ]; then
        cp "$CONFIG_DIR/hyprland-keybindings.conf" "$KEYS_CONF"
        info "keybindings.conf copiado"
    else
        error "No se encontró el archivo fuente. Clonar el repo arch-setup primero."
    fi
else
    info "keybindings.conf existe"
fi

# ─── Fix 3: Verificar que está sourced en hyprland.conf ──────────────────────
echo ""
echo "--- Fix 3: Source en hyprland.conf ---"
if [ -f "$HYPR_CONF" ]; then
    if grep -q "keybindings.conf" "$HYPR_CONF"; then
        info "keybindings.conf ya está sourced — OK"
    else
        echo "source = ~/.config/hypr/keybindings.conf" >> "$HYPR_CONF"
        info "Source agregado a hyprland.conf"
    fi
else
    error "hyprland.conf no encontrado en $HYPR_CONF"
fi

# ─── Fix 4: Carpeta de screenshots ───────────────────────────────────────────
echo ""
echo "--- Fix 4: Carpeta de screenshots ---"
mkdir -p "$HOME/Pictures/Screenshots"
info "~/Pictures/Screenshots/ lista"

# ─── Recarga de Hyprland ──────────────────────────────────────────────────────
echo ""
echo "--- Recargar config de Hyprland ---"
if command -v hyprctl &>/dev/null; then
    hyprctl reload && info "Hyprland recargado — keybindings activos" || warn "No se pudo recargar — reiniciar sesión"
else
    warn "hyprctl no disponible — cerrar sesión y volver a entrar para aplicar"
fi

echo ""
echo "Keybindings disponibles:"
echo "  Super+T       — terminal (foot)"
echo "  Super+E       — archivos (thunar)"
echo "  Super+B       — Chrome"
echo "  Super+L       — bloquear pantalla"
echo "  PrtSc         — screenshot completo"
echo "  Super+PrtSc   — screenshot zona + anotar"
echo "  Super+Shift+S — screenshot zona al clipboard"
echo "  Super+V       — historial clipboard"
echo "  Teclas Fn     — volumen y brillo"
