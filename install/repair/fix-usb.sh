#!/bin/bash
# Reparación de automontaje USB y teléfonos
# Síntomas: pendrives no aparecen en Thunar, teléfonos no se detectan
# Uso: bash install/repair/fix-usb.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
check() { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "=== FIX USB / AUTOMONTAJE ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"
check "Dispositivos USB conectados:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v loop

check "Estado de udisks2:"
systemctl is-active udisks2 && info "udisks2 activo" || warn "udisks2 inactivo"

check "Estado de gvfs:"
systemctl --user is-active gvfs-udisks2-volume-monitor 2>/dev/null && info "gvfs activo" || warn "gvfs-udisks2 no activo"

echo ""

# ─── Fix 1: Instalar paquetes necesarios ─────────────────────────────────────
echo "--- Fix 1: Instalar paquetes ---"
sudo pacman -S --needed --noconfirm \
    gvfs \
    gvfs-mtp \
    udisks2 \
    thunar-volman \
    tumbler
info "Paquetes instalados"

# ─── Fix 2: Habilitar udisks2 ────────────────────────────────────────────────
echo ""
echo "--- Fix 2: Habilitar udisks2 ---"
sudo systemctl enable --now udisks2
info "udisks2 habilitado y corriendo"

# ─── Fix 3: Reiniciar Thunar en modo daemon ───────────────────────────────────
echo ""
echo "--- Fix 3: Reiniciar Thunar daemon ---"
pkill thunar 2>/dev/null || true
sleep 1
thunar --daemon &
sleep 1
info "Thunar daemon reiniciado"

# ─── Fix 4: Permisos de usuario para montar ──────────────────────────────────
echo ""
echo "--- Fix 4: Verificar grupo storage ---"
if groups | grep -q storage; then
    info "Usuario en grupo storage — OK"
else
    warn "Usuario no está en grupo storage — agregando..."
    sudo usermod -aG storage "$(whoami)"
    info "Agregado al grupo storage — reiniciar sesión para que tome efecto"
fi

# ─── Fix 5: Para teléfonos Android (MTP) ─────────────────────────────────────
echo ""
echo "--- Fix 5: Soporte Android MTP ---"
if pacman -Q gvfs-mtp &>/dev/null; then
    info "gvfs-mtp instalado — teléfonos Android deberían aparecer en Thunar"
else
    sudo pacman -S --noconfirm gvfs-mtp
    info "gvfs-mtp instalado"
fi

echo ""
echo "Para montar un USB manualmente si sigue sin aparecer:"
echo "  lsblk                    # ver dispositivos"
echo "  udisksctl mount -b /dev/sdbX  # montar (reemplazar X)"
echo ""
echo "Reiniciar Thunar después de conectar el USB si no aparece automáticamente."
