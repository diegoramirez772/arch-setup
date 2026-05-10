#!/bin/bash
# Script de post-instalación — Arch Linux + Hyprland + caelestia-shell
# Lenovo IdeaPad 330 — AMD E2-9000 + Radeon R2 + Realtek 8821CE
# Correr como usuario normal (no root): bash install/2-post-install.sh

set -e

# ─── Colores para output ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# ─── 1. Verificar que no corre como root ─────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
    error "No correr como root. Correr como usuario normal con sudo disponible."
fi

info "Usuario: $(whoami) — OK"

# ─── 2. Verificar internet ────────────────────────────────────────────────────
info "Verificando internet..."
if ! ping -c 1 archlinux.org &>/dev/null; then
    error "Sin internet. Conectar por USB tethering o ethernet y reintentar."
fi
info "Internet OK"

# ─── 3. Actualizar sistema ────────────────────────────────────────────────────
info "Actualizando sistema..."
sudo pacman -Syu --noconfirm

# ─── 4. Instalar git y base-devel ────────────────────────────────────────────
info "Instalando git y base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

# ─── 5. Instalar yay (AUR helper) ────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    info "Instalando yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
else
    info "yay ya instalado — saltando"
fi

# ─── 6. Paquetes pacman del stack ─────────────────────────────────────────────
info "Instalando paquetes del stack..."
sudo pacman -S --needed --noconfirm \
    hyprland xdg-desktop-portal-hyprland \
    hyprlock hypridle \
    pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-bluetooth \
    networkmanager \
    bluez bluez-utils \
    foot thunar thunar-volman tumbler \
    pavucontrol \
    fish tmux \
    grim slurp swappy \
    mpv imv \
    zathura zathura-pdf-mupdf \
    file-roller \
    gvfs gvfs-mtp \
    lxpolkit \
    wl-clipboard \
    brightnessctl \
    xdg-user-dirs \
    grub os-prober \
    mesa xf86-video-amdgpu \
    noto-fonts noto-fonts-emoji \
    ttf-liberation \
    openssh \
    wget curl unzip \
    htop \
    zram-generator

# Crear directorios estándar del usuario (Documents, Downloads, Music, Videos, etc.)
xdg-user-dirs-update

# ─── 7. Habilitar servicios ───────────────────────────────────────────────────
info "Habilitando servicios..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now pipewire pipewire-pulse wireplumber
# Crear carpeta de screenshots
mkdir -p "$HOME/Pictures/Screenshots"

# ─── 8. Driver WiFi Realtek 8821CE ───────────────────────────────────────────
info "Instalando driver WiFi Realtek 8821CE..."

# Blacklist del driver rtw88 que viene en el kernel y entra en conflicto
sudo tee /etc/modprobe.d/blacklist-rtw88.conf > /dev/null << 'EOF'
blacklist rtw88_8821ce
blacklist rtw88_core
blacklist rtw88_pci
EOF

# Usar rtl8821ce-dkms-git (más actualizado que rtl8821ce-dkms, mejor soporte kernel reciente)
yay -S --needed --noconfirm rtl8821ce-dkms-git
sudo modprobe rtl8821ce || warn "No se pudo cargar el módulo ahora — reiniciar para activarlo"

# Fix de power management del WiFi (se desconecta solo sin esto en IdeaPad 330)
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF
sudo systemctl restart NetworkManager

# ─── 9. Parámetros de kernel para AMD Radeon R2 (Stoney Ridge) ───────────────
info "Configurando parámetros de kernel para AMD Radeon R2..."

# kfd_disabled=1: Stoney Ridge no soporta KFD, sin esto puede causar errores al arrancar
sudo tee /etc/modprobe.d/amdgpu.conf > /dev/null << 'EOF'
options amdgpu kfd_disabled=1
EOF

# Parámetros GRUB:
# amdgpu.dc=1       — habilita Display Core para Stoney (necesario para Hyprland)
# acpi_backlight=native — fix de congelación gráfica conocido en IdeaPad 330
# iommu=pt          — mejora rendimiento de la GPU integrada
GRUB_FILE="/etc/default/grub"
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_FILE"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 amdgpu.dc=1 acpi_backlight=native iommu=pt"/' "$GRUB_FILE"
    info "Parámetros de kernel AMD agregados a GRUB"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else
    warn "No se encontró GRUB_CMDLINE_LINUX_DEFAULT — agregar manualmente: amdgpu.dc=1 acpi_backlight=native iommu=pt"
fi

# ─── 10. Paquetes AUR del stack ───────────────────────────────────────────────
info "Instalando paquetes AUR..."
yay -S --needed --noconfirm \
    caelestia-shell \
    caelestia-cli \
    google-chrome \
    elm-bin \
    cliphist \
    ttf-material-symbols-variable-git \
    caskaydia-cove-nerd \
    ttf-rubik
# Las dependencias de runtime de caelestia (quickshell, libcava, etc.)
# se instalan en 3-caelestia-setup.sh para mantener este script liviano

# ─── 11. Instalar nvm + Node.js LTS ──────────────────────────────────────────
info "Instalando nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    info "Node.js LTS instalado: $(node --version)"
else
    info "nvm ya instalado — saltando"
fi

# ─── 12. VS Code (opcional) ───────────────────────────────────────────────────
echo ""
read -rp "¿Instalar VS Code? (s/N): " install_vscode
if [[ "$install_vscode" =~ ^[Ss]$ ]]; then
    info "Instalando VS Code..."
    yay -S --needed --noconfirm visual-studio-code-bin
fi

# ─── 13. Copiar config de caelestia ──────────────────────────────────────────
info "Copiando config de caelestia..."
mkdir -p "$HOME/.config/caelestia"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../config/shell.json" ]; then
    cp "$SCRIPT_DIR/../config/shell.json" "$HOME/.config/caelestia/shell.json"
    info "shell.json copiado"
else
    warn "config/shell.json no encontrado — configurar caelestia manualmente"
fi

# ─── 14. Crear carpetas de trabajo ───────────────────────────────────────────
info "Creando carpetas..."
mkdir -p "$HOME/dev"
mkdir -p "$HOME/Pictures/Wallpapers"

# ─── 15. Configurar zram (swap en RAM — mejora rendimiento en HDD) ────────────
info "Configurando zram..."
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0 || warn "zram se activará al reiniciar"

# ─── 16. Cambiar shell por defecto a fish ────────────────────────────────────
info "Cambiando shell a fish..."
if [ "$(basename "$SHELL")" != "fish" ]; then
    chsh -s "$(which fish)"
    info "Shell cambiado a fish — efectivo al próximo login"
else
    info "fish ya es el shell — saltando"
fi

# ─── Resumen final ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Instalación completada                ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. Correr: bash install/3-caelestia-setup.sh"
echo "  2. Reiniciar: sudo reboot"
echo "  3. Si el WiFi no funciona: ver docs/wifi-fix.md"
echo "  4. Para cambiar wallpaper: caelestia wallpaper set ~/Pictures/Wallpapers/foto.jpg"
echo ""
