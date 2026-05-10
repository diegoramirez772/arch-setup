#!/bin/bash
# Reparación de audio — Pipewire + AMD APU
# Síntomas: sin sonido, audio cortado, dispositivo no detectado
# Uso: bash install/repair/fix-audio.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
check() { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "=== FIX AUDIO — Pipewire + AMD APU ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"

check "Servicios de audio activos:"
systemctl --user status pipewire pipewire-pulse wireplumber --no-pager 2>/dev/null | grep -E "Active|●" || echo "  (servicios no encontrados)"

check "Dispositivos de audio detectados:"
pactl list sinks short 2>/dev/null || echo "  (pactl no disponible o pipewire no corriendo)"

check "Tarjeta de sonido del kernel:"
aplay -l 2>/dev/null || echo "  (aplay no disponible)"

echo ""

# ─── Fix 1: Reiniciar servicios ───────────────────────────────────────────────
echo "--- Fix 1: Reiniciar servicios de audio ---"
systemctl --user stop pipewire pipewire-pulse wireplumber 2>/dev/null || true
sleep 1
systemctl --user start pipewire wireplumber pipewire-pulse
sleep 2

if pactl info &>/dev/null; then
    info "Pipewire corriendo — audio recuperado"
else
    warn "Pipewire no responde aún"
fi

# ─── Fix 2: Habilitar servicios para arranque automático ─────────────────────
echo ""
echo "--- Fix 2: Habilitar autostart ---"
systemctl --user enable pipewire pipewire-pulse wireplumber
info "Servicios habilitados para autostart"

# ─── Fix 3: Reinstalar pipewire ──────────────────────────────────────────────
echo ""
echo "--- Fix 3: Reinstalar pipewire (si el fix 1 no funcionó) ---"
read -rp "¿Reinstalar pipewire completo? (s/N): " reinstall
if [[ "$reinstall" =~ ^[Ss]$ ]]; then
    sudo pacman -S --noconfirm pipewire wireplumber pipewire-pulse pipewire-alsa
    systemctl --user restart pipewire wireplumber pipewire-pulse
    info "Pipewire reinstalado y reiniciado"
fi

# ─── Fix 4: Volumen ───────────────────────────────────────────────────────────
echo ""
echo "--- Fix 4: Verificar volumen ---"
echo "Abrir pavucontrol para ajustar volumen:"
echo "  pavucontrol &"
echo ""
echo "O con amixer:"
echo "  amixer set Master unmute"
echo "  amixer set Master 80%"
