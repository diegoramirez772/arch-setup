#!/bin/bash
# Reparación de GRUB — dual boot Windows + Arch
# Síntomas: Windows no aparece en GRUB, GRUB no carga, error de boot
# Uso: bash install/repair/fix-grub.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
check() { echo -e "${YELLOW}[?]${NC} $1"; }

echo ""
echo "=== FIX GRUB — Dual boot Windows + Arch ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"

check "Particiones del disco:"
lsblk -f

check "EFI montada en /boot/efi:"
mount | grep efi || warn "EFI no montada"

check "GRUB instalado:"
grub-install --version 2>/dev/null || echo "  (grub no encontrado)"

check "os-prober instalado:"
which os-prober 2>/dev/null || echo "  (os-prober no instalado)"

echo ""

# ─── Fix 1: Windows no aparece en GRUB ───────────────────────────────────────
echo "--- Fix 1: Hacer que Windows aparezca en GRUB ---"

# Instalar os-prober si falta
if ! command -v os-prober &>/dev/null; then
    info "Instalando os-prober..."
    sudo pacman -S --noconfirm os-prober
fi

# Habilitar os-prober en config de GRUB
if grep -q "GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
    sudo sed -i 's/GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    info "GRUB_DISABLE_OS_PROBER habilitado"
elif ! grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub > /dev/null
    info "GRUB_DISABLE_OS_PROBER=false agregado"
else
    info "GRUB_DISABLE_OS_PROBER ya configurado — OK"
fi

# Montar EFI si no está montada
if ! mount | grep -q "/boot/efi"; then
    warn "EFI no montada — intentando montar..."
    EFI_PART=$(lsblk -o NAME,PARTTYPE -n | grep "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | awk '{print "/dev/"$1}')
    if [ -n "$EFI_PART" ]; then
        sudo mount "$EFI_PART" /boot/efi
        info "EFI montada desde $EFI_PART"
    else
        error "No se encontró partición EFI — verificar con: lsblk -f"
    fi
fi

# Regenerar GRUB
info "Regenerando GRUB..."
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg
info "GRUB regenerado — reiniciar para verificar"

# ─── Fix 2: GRUB no carga en absoluto (desde live USB) ───────────────────────
echo ""
echo "--- Fix 2: Si GRUB no carga (instrucciones desde live USB) ---"
echo ""
echo "Desde el live USB de Arch:"
echo ""
echo "  # Ver particiones"
echo "  lsblk -f"
echo ""
echo "  # Montar Arch (ajustar número de partición)"
echo "  mount /dev/sda4 /mnt"
echo "  mount /dev/sda1 /mnt/boot/efi"
echo ""
echo "  # Entrar al sistema"
echo "  arch-chroot /mnt"
echo ""
echo "  # Reinstalar GRUB"
echo "  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
echo "  grub-mkconfig -o /boot/grub/grub.cfg"
echo ""
echo "  # Salir y reiniciar"
echo "  exit"
echo "  reboot"
