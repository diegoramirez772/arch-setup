#!/bin/bash
# Reparación de caelestia-shell
# Síntomas: caelestia no arranca, shell en blanco, error de quickshell
# Uso: bash install/repair/fix-caelestia.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
check() { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "=== FIX CAELESTIA-SHELL ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"

check "quickshell instalado:"
pacman -Q quickshell 2>/dev/null || echo "  (NO instalado)"

check "caelestia-shell instalado:"
pacman -Q caelestia-shell 2>/dev/null || echo "  (NO instalado)"

check "caelestia-cli instalado:"
pacman -Q caelestia-cli 2>/dev/null || echo "  (NO instalado)"

check "caelestia dots clonados:"
ls ~/.local/share/caelestia 2>/dev/null || echo "  (NO encontrados en ~/.local/share/caelestia)"

check "Config caelestia:"
ls ~/.config/caelestia/ 2>/dev/null || echo "  (sin config)"

check "Proceso caelestia corriendo:"
pgrep -a qs || echo "  (no corriendo)"

echo ""

# ─── Fix 1: Arrancar caelestia manualmente ────────────────────────────────────
echo "--- Fix 1: Arrancar caelestia manualmente ---"
read -rp "¿Intentar arrancar caelestia ahora? (s/N): " start
if [[ "$start" =~ ^[Ss]$ ]]; then
    caelestia shell -d &
    sleep 3
    if pgrep -x qs &>/dev/null; then
        info "caelestia arrancado"
    else
        warn "No arrancó — ver error arriba"
    fi
fi

# ─── Fix 2: Reinstalar quickshell ────────────────────────────────────────────
echo ""
echo "--- Fix 2: Reinstalar quickshell (versión estable) ---"
read -rp "¿Reinstalar quickshell? (s/N): " reinstall_qs
if [[ "$reinstall_qs" =~ ^[Ss]$ ]]; then
    # Usar versión estable, NO quickshell-git (marcado como out-of-date en AUR)
    yay -S --noconfirm quickshell
    info "quickshell reinstalado"
fi

# ─── Fix 3: Reinstalar caelestia-shell ───────────────────────────────────────
echo ""
echo "--- Fix 3: Reinstalar caelestia-shell ---"
read -rp "¿Reinstalar caelestia-shell? (s/N): " reinstall_cs
if [[ "$reinstall_cs" =~ ^[Ss]$ ]]; then
    yay -S --noconfirm caelestia-shell caelestia-cli
    info "caelestia-shell reinstalado"
fi

# ─── Fix 4: Re-clonar y reinstalar dots ───────────────────────────────────────
echo ""
echo "--- Fix 4: Re-clonar caelestia dots ---"
read -rp "¿Re-clonar y reinstalar dots? (elimina la instalación actual) (s/N): " reclone
if [[ "$reclone" =~ ^[Ss]$ ]]; then
    CAELESTIA_DIR="$HOME/.local/share/caelestia"
    if [ -d "$CAELESTIA_DIR" ]; then
        warn "Eliminando $CAELESTIA_DIR..."
        rm -rf "$CAELESTIA_DIR"
    fi
    git clone https://github.com/caelestia-dots/caelestia.git "$CAELESTIA_DIR"
    cd "$CAELESTIA_DIR"
    fish install.fish
    info "Dots reinstalados"
fi

# ─── Fix 5: Actualizar dots ───────────────────────────────────────────────────
echo ""
echo "--- Fix 5: Actualizar dots a la última versión ---"
read -rp "¿Actualizar caelestia dots? (s/N): " update
if [[ "$update" =~ ^[Ss]$ ]]; then
    CAELESTIA_DIR="$HOME/.local/share/caelestia"
    if [ -d "$CAELESTIA_DIR" ]; then
        git -C "$CAELESTIA_DIR" pull
        info "Dots actualizados"
    else
        error "Dots no encontrados. Correr primero: bash install/3-caelestia-setup.sh"
    fi
fi

# ─── Fix 6: Autostart en Hyprland ────────────────────────────────────────────
echo ""
echo "--- Fix 6: Verificar autostart en Hyprland ---"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    if grep -q "caelestia shell" "$HYPR_CONF"; then
        info "Autostart presente en hyprland.conf — OK"
    else
        warn "Autostart faltante — agregando..."
        echo "exec-once = caelestia shell -d" >> "$HYPR_CONF"
        info "Autostart agregado"
    fi
else
    warn "hyprland.conf no encontrado en $HYPR_CONF"
fi

echo ""
echo "Comandos útiles para diagnóstico:"
echo "  caelestia shell -s          # ver comandos IPC disponibles"
echo "  journalctl -b | grep -i qs  # logs del proceso quickshell"
echo "  caelestia shell -d          # arrancar manualmente"
