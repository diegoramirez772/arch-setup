#!/bin/bash
# Reparación de Hyprland — AMD Radeon R2 (Stoney Ridge)
# Síntomas: pantalla negra, crash al iniciar, artefactos, flickering
# Uso: bash install/repair/fix-hyprland.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
check() { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "=== FIX HYPRLAND — AMD Radeon R2 (Stoney Ridge) ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"

check "GPU detectada:"
lspci | grep -i "vga\|3d\|display"

check "Driver de GPU activo:"
lspci -k | grep -A2 "VGA\|3D" | grep "Kernel driver"

check "Módulo amdgpu cargado:"
lsmod | grep amdgpu && echo "  (cargado)" || echo "  (NO cargado)"

check "Mesa version:"
glxinfo 2>/dev/null | grep "OpenGL renderer" || echo "  (glxinfo no disponible — instalar mesa-utils)"

check "Parámetros de kernel actuales:"
cat /proc/cmdline

check "Logs de Hyprland (últimas 30 líneas):"
HYPR_LOG="$HOME/.local/share/hyprland/hyprland.log"
if [ -f "$HYPR_LOG" ]; then
    tail -30 "$HYPR_LOG"
else
    journalctl -b --no-pager | grep -i hyprland | tail -20 || echo "  (sin logs)"
fi

echo ""

# ─── Fix 1: Parámetros de kernel GRUB ────────────────────────────────────────
echo "--- Fix 1: Parámetros de kernel para AMD Radeon R2 ---"
GRUB_FILE="/etc/default/grub"
CURRENT=$(grep GRUB_CMDLINE_LINUX_DEFAULT "$GRUB_FILE")
info "Configuración actual: $CURRENT"

NEEDS_UPDATE=false
grep -q "amdgpu.dc=1" "$GRUB_FILE" || NEEDS_UPDATE=true
grep -q "acpi_backlight=native" "$GRUB_FILE" || NEEDS_UPDATE=true
grep -q "iommu=pt" "$GRUB_FILE" || NEEDS_UPDATE=true

if [ "$NEEDS_UPDATE" = true ]; then
    warn "Faltan parámetros de kernel para AMD Stoney Ridge"
    read -rp "¿Aplicar parámetros recomendados? (s/N): " apply
    if [[ "$apply" =~ ^[Ss]$ ]]; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 amdgpu.dc=1 acpi_backlight=native iommu=pt"/' "$GRUB_FILE"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        info "Parámetros aplicados — reiniciar para activarlos"
    fi
else
    info "Parámetros de kernel OK"
fi

# ─── Fix 2: Modprobe amdgpu ───────────────────────────────────────────────────
echo ""
echo "--- Fix 2: Configuración de amdgpu ---"
MODPROBE_FILE="/etc/modprobe.d/amdgpu.conf"
if [ ! -f "$MODPROBE_FILE" ] || ! grep -q "kfd_disabled" "$MODPROBE_FILE"; then
    info "Aplicando kfd_disabled=1 (Stoney Ridge no soporta KFD)"
    sudo tee "$MODPROBE_FILE" > /dev/null << 'EOF'
options amdgpu kfd_disabled=1
EOF
    info "Aplicado — reiniciar para activar"
else
    info "amdgpu.conf OK"
fi

# ─── Fix 3: Variables de entorno Hyprland ─────────────────────────────────────
echo ""
echo "--- Fix 3: Variables de entorno para AMD + Wayland ---"
AMD_ENV="$HOME/.config/hypr/amd-env.conf"
if [ ! -f "$AMD_ENV" ]; then
    mkdir -p "$HOME/.config/hypr"
    tee "$AMD_ENV" > /dev/null << 'EOF'
env = LIBVA_DRIVER_NAME,radeonsi
env = AQ_DRM_DEVICES,/dev/dri/card0
env = MESA_DEBUG,quiet
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland
env = SDL_VIDEODRIVER,wayland

render {
    explicit_sync = 1
    explicit_sync_kms = 0
}

misc {
    disable_hyprland_logo = true
    enable_hyprcursor = false
}
EOF
    info "amd-env.conf creado"
fi

# Asegurarse de que está siendo sourced en hyprland.conf
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ] && ! grep -q "amd-env.conf" "$HYPR_CONF"; then
    echo "" >> "$HYPR_CONF"
    echo "source = ~/.config/hypr/amd-env.conf" >> "$HYPR_CONF"
    info "Source de amd-env.conf agregado a hyprland.conf"
else
    info "amd-env.conf ya referenciado — OK"
fi

# ─── Fix 4: Pantalla negra — modo de emergencia ───────────────────────────────
echo ""
echo "--- Fix 4: Si Hyprland no arranca (pantalla negra total) ---"
echo ""
echo "Desde TTY (Ctrl+Alt+F2 en pantalla negra):"
echo ""
echo "  # Ver qué error da Hyprland:"
echo "  cat ~/.local/share/hyprland/hyprland.log | tail -50"
echo ""
echo "  # Probar con nomodeset temporal (desactiva aceleración, solo para diagnosticar):"
echo "  # Reiniciar → en GRUB presionar 'e' → agregar 'nomodeset' al final de la línea linux"
echo ""
echo "  # Verificar que amdgpu esté en mkinitcpio:"
echo "  grep MODULES /etc/mkinitcpio.conf"
echo "  # Debe incluir: amdgpu"
echo "  # Si no está:"
echo "  sudo sed -i 's/MODULES=(/MODULES=(amdgpu /' /etc/mkinitcpio.conf"
echo "  sudo mkinitcpio -P"
echo ""

# ─── Fix 5: Reinstalar Hyprland ──────────────────────────────────────────────
echo "--- Fix 5: Reinstalar Hyprland (si crashea al iniciar) ---"
read -rp "¿Reinstalar Hyprland? (s/N): " reinstall
if [[ "$reinstall" =~ ^[Ss]$ ]]; then
    sudo pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland
    info "Hyprland reinstalado"
fi

echo ""
echo "Reiniciar y probar: sudo reboot"
