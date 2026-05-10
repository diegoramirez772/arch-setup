#!/bin/bash
# Reparación de WiFi — Realtek RTL8821CE
# Síntomas: WiFi no aparece, no se conecta, se desconecta solo
# Uso: bash install/repair/fix-wifi.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
check() { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "=== FIX WIFI — Realtek RTL8821CE ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"

check "Chip de red detectado:"
lspci | grep -i "network\|wireless" || echo "  (ninguno detectado)"

check "Módulos de red cargados:"
lsmod | grep -E "rtl|rtw" || echo "  (ninguno)"

check "Estado rfkill (bloqueo por firmware):"
rfkill list

check "Interfaces de red:"
ip link show

echo ""

# ─── Fix 1: Hard block por firmware del IdeaPad ──────────────────────────────
echo "--- Fix 1: Verificar bloqueo de firmware ---"
if rfkill list | grep -q "Hard blocked: yes"; then
    warn "HARD BLOCK detectado — el firmware está bloqueando el WiFi"
    info "Intentando desbloquear..."
    rfkill unblock wifi
    sudo tee /etc/modprobe.d/ideapad-laptop.conf > /dev/null << 'EOF'
options ideapad_laptop wifi_rfkill_state=0
EOF
    info "Fix aplicado. Si persiste, entrar a BIOS y verificar que WiFi esté habilitado."
else
    info "Sin hard block — OK"
fi

# ─── Fix 2: Blacklist driver rtw88 conflictivo ───────────────────────────────
echo ""
echo "--- Fix 2: Blacklist driver rtw88 ---"
if lsmod | grep -q "rtw88"; then
    warn "Driver rtw88 cargado — conflicto con rtl8821ce"
    info "Aplicando blacklist..."
    sudo tee /etc/modprobe.d/blacklist-rtw88.conf > /dev/null << 'EOF'
blacklist rtw88_8821ce
blacklist rtw88_core
blacklist rtw88_pci
EOF
    sudo modprobe -r rtw88_8821ce rtw88_core rtw88_pci 2>/dev/null || true
    info "Blacklist aplicada. Reiniciar para que sea permanente."
else
    info "rtw88 no cargado — OK"
fi

# ─── Fix 3: Reinstalar driver rtl8821ce-dkms-git ─────────────────────────────
echo ""
echo "--- Fix 3: Reinstalar driver ---"
read -rp "¿Reinstalar rtl8821ce-dkms-git? (s/N): " reinstall
if [[ "$reinstall" =~ ^[Ss]$ ]]; then
    if command -v yay &>/dev/null; then
        yay -S --noconfirm rtl8821ce-dkms-git
        sudo modprobe rtl8821ce
        info "Driver reinstalado"
    else
        error "yay no encontrado. Instalar yay primero."
    fi
fi

# ─── Fix 4: Power management ─────────────────────────────────────────────────
echo ""
echo "--- Fix 4: Power management (WiFi se desconecta solo) ---"
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF
sudo systemctl restart NetworkManager
info "Power save deshabilitado"

# ─── Fix 5: Cargar módulo manualmente ────────────────────────────────────────
echo ""
echo "--- Fix 5: Cargar módulo manualmente ---"
if ! lsmod | grep -q "rtl8821ce\|8821ce"; then
    info "Cargando módulo rtl8821ce..."
    sudo modprobe rtl8821ce && info "Módulo cargado" || warn "No se pudo cargar — reiniciar"
else
    info "Módulo ya cargado — OK"
fi

# ─── Estado final ─────────────────────────────────────────────────────────────
echo ""
echo "--- Estado final ---"
ip link show
echo ""
echo "Para conectar a una red:"
echo "  nmtui                              # interfaz gráfica de texto"
echo "  nmcli device wifi list             # ver redes disponibles"
echo "  nmcli device wifi connect 'Red' password 'pass'"
echo ""
echo "Si el WiFi sigue sin aparecer después de reiniciar:"
echo "  Ver docs/wifi-fix.md"
echo "  Usar USB tethering del celular como alternativa"
