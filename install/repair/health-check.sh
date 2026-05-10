#!/bin/bash
# Health check — verifica que todo el stack esté correctamente instalado
# Uso: bash install/repair/health-check.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

ok()   { echo -e "  ${GREEN}✓${NC} $1"; ((PASS++)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; ((WARN++)); }

echo ""
echo "=== HEALTH CHECK ==="
echo ""

# ─── Paquetes críticos ────────────────────────────────────────────────────────
echo "Paquetes:"
for pkg in hyprland pipewire wireplumber networkmanager fish yay grub; do
    if pacman -Q "$pkg" &>/dev/null; then
        ok "$pkg instalado"
    else
        fail "$pkg NO instalado"
    fi
done

# ─── Driver WiFi ──────────────────────────────────────────────────────────────
echo ""
echo "WiFi:"
if pacman -Q rtl8821ce-dkms-git &>/dev/null; then
    ok "rtl8821ce-dkms-git instalado"
else
    fail "rtl8821ce-dkms-git NO instalado — correr: bash install/repair/fix-wifi.sh"
fi

if [ -f /etc/modprobe.d/blacklist-rtw88.conf ]; then
    ok "blacklist rtw88 configurado"
else
    warn "blacklist rtw88 faltante — puede causar conflictos de driver"
fi

if lsmod | grep -q rtl8821ce; then
    ok "módulo rtl8821ce cargado"
else
    warn "módulo rtl8821ce no cargado — reiniciar o: sudo modprobe rtl8821ce"
fi

# ─── GPU AMD ──────────────────────────────────────────────────────────────────
echo ""
echo "GPU AMD (Stoney Ridge):"
if [ -f /etc/modprobe.d/amdgpu.conf ] && grep -q "kfd_disabled" /etc/modprobe.d/amdgpu.conf; then
    ok "amdgpu kfd_disabled configurado"
else
    fail "amdgpu.conf faltante — correr: bash install/repair/fix-hyprland.sh"
fi

if grep -q "amdgpu.dc=1" /etc/default/grub; then
    ok "parámetros de kernel AMD en GRUB"
else
    fail "parámetros AMD faltantes en GRUB — correr: bash install/repair/fix-hyprland.sh"
fi

if lsmod | grep -q amdgpu; then
    ok "módulo amdgpu cargado"
else
    fail "módulo amdgpu NO cargado"
fi

# ─── Audio ────────────────────────────────────────────────────────────────────
echo ""
echo "Audio:"
if systemctl --user is-active pipewire &>/dev/null; then
    ok "pipewire activo"
else
    fail "pipewire inactivo — correr: bash install/repair/fix-audio.sh"
fi

if systemctl --user is-active wireplumber &>/dev/null; then
    ok "wireplumber activo"
else
    warn "wireplumber inactivo"
fi

# ─── Caelestia ────────────────────────────────────────────────────────────────
echo ""
echo "Caelestia:"
if pacman -Q caelestia-shell &>/dev/null; then
    ok "caelestia-shell instalado"
else
    fail "caelestia-shell NO instalado — correr: bash install/repair/fix-caelestia.sh"
fi

if pacman -Q quickshell &>/dev/null; then
    ok "quickshell instalado"
else
    fail "quickshell NO instalado — correr: yay -S quickshell"
fi

if [ -d "$HOME/.local/share/caelestia" ]; then
    ok "caelestia dots clonados"
else
    warn "caelestia dots no encontrados en ~/.local/share/caelestia"
fi

if [ -f "$HOME/.config/hypr/amd-env.conf" ]; then
    ok "amd-env.conf presente"
else
    warn "amd-env.conf faltante — correr: bash install/repair/fix-hyprland.sh"
fi

# ─── GRUB ─────────────────────────────────────────────────────────────────────
echo ""
echo "GRUB:"
if [ -f /boot/grub/grub.cfg ]; then
    ok "grub.cfg presente"
else
    fail "grub.cfg no encontrado — correr: bash install/repair/fix-grub.sh"
fi

if grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    ok "os-prober habilitado para detectar Windows"
else
    warn "os-prober deshabilitado — Windows puede no aparecer en GRUB"
fi

# ─── Apps de escritorio ───────────────────────────────────────────────────────
echo ""
echo "Apps:"
for pkg in google-chrome mpv imv zathura file-roller hyprlock hypridle lxpolkit; do
    if pacman -Q "$pkg" &>/dev/null || yay -Q "$pkg" &>/dev/null 2>/dev/null; then
        ok "$pkg instalado"
    else
        warn "$pkg no instalado"
    fi
done

if pacman -Q gvfs &>/dev/null; then
    ok "gvfs instalado (automontaje USB)"
else
    fail "gvfs no instalado — pendrives no van a aparecer en Thunar"
fi

# ─── Dev setup ────────────────────────────────────────────────────────────────
echo ""
echo "Dev:"
if [ -d "$HOME/.nvm" ]; then
    ok "nvm instalado"
else
    warn "nvm no encontrado en ~/.nvm"
fi

if command -v elm &>/dev/null || yay -Q elm-bin &>/dev/null 2>/dev/null; then
    ok "elm instalado"
else
    warn "elm no instalado"
fi

if command -v tmux &>/dev/null; then
    ok "tmux instalado"
else
    warn "tmux no instalado"
fi

if [ -f "$HOME/.ssh/id_ed25519_personal" ] && [ -f "$HOME/.ssh/id_ed25519_school" ]; then
    ok "SSH keys dos cuentas configuradas"
else
    warn "SSH keys no configuradas — correr: bash install/setup-git.sh"
fi

for dir in dev school "Pictures/Wallpapers" "Pictures/Screenshots" Documents Downloads Music Videos; do
    if [ -d "$HOME/$dir" ]; then
        ok "~/$dir existe"
    else
        warn "~/$dir no existe"
    fi
done

# ─── Resultado ────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────"
echo -e "  ${GREEN}✓ $PASS OK${NC}   ${RED}✗ $FAIL ERRORES${NC}   ${YELLOW}⚠ $WARN ADVERTENCIAS${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "Hay errores. Correr los scripts de reparación correspondientes."
    echo "Luego: bash install/repair/health-check.sh  para reverificar"
elif [ "$WARN" -gt 0 ]; then
    echo "Todo crítico OK. Las advertencias son menores — reiniciar primero."
else
    echo -e "${GREEN}Sistema listo. Reiniciar con: sudo reboot${NC}"
fi
echo ""
