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
    hyprland \
    pipewire wireplumber pipewire-pulse pipewire-alsa \
    networkmanager \
    foot \
    thunar \
    pavucontrol \
    fish \
    bluez bluez-utils \
    grim slurp \
    grub os-prober \
    mesa xf86-video-amdgpu \
    noto-fonts noto-fonts-emoji \
    ttf-liberation \
    wget curl unzip \
    htop

# ─── 7. Habilitar servicios ───────────────────────────────────────────────────
info "Habilitando servicios..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now pipewire pipewire-pulse wireplumber

# ─── 8. Driver WiFi Realtek 8821CE ───────────────────────────────────────────
info "Instalando driver WiFi Realtek 8821CE..."
yay -S --needed --noconfirm rtl8821ce-dkms
sudo modprobe 8821ce || warn "No se pudo cargar el módulo ahora — reiniciar para activarlo"

# Fix de power management del WiFi (se desconecta solo sin esto)
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF
sudo systemctl restart NetworkManager

# ─── 9. Paquetes AUR del stack ────────────────────────────────────────────────
info "Instalando caelestia-shell y fuentes desde AUR..."
yay -S --needed --noconfirm \
    caelestia-shell \
    caelestia-cli \
    ttf-material-symbols-variable-git \
    caskaydia-cove-nerd \
    ttf-rubik \
    swappy

# ─── 10. Instalar nvm + Node.js LTS ──────────────────────────────────────────
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

# ─── 11. VS Code (opcional) ───────────────────────────────────────────────────
echo ""
read -rp "¿Instalar VS Code? (s/N): " install_vscode
if [[ "$install_vscode" =~ ^[Ss]$ ]]; then
    info "Instalando VS Code..."
    yay -S --needed --noconfirm visual-studio-code-bin
fi

# ─── 12. Copiar config de caelestia ──────────────────────────────────────────
info "Copiando config de caelestia..."
mkdir -p "$HOME/.config/caelestia"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../config/shell.json" ]; then
    cp "$SCRIPT_DIR/../config/shell.json" "$HOME/.config/caelestia/shell.json"
    info "shell.json copiado"
else
    warn "config/shell.json no encontrado — configurar caelestia manualmente"
fi

# ─── 13. Crear carpetas de trabajo ───────────────────────────────────────────
info "Creando carpetas..."
mkdir -p "$HOME/dev"
mkdir -p "$HOME/Pictures/Wallpapers"

# ─── 14. Configurar zram (swap en RAM — mejora rendimiento en HDD) ────────────
info "Configurando zram..."
sudo pacman -S --needed --noconfirm zram-generator
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0 || warn "zram se activará al reiniciar"

# ─── 15. Cambiar shell por defecto a fish ────────────────────────────────────
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
echo "  1. Reiniciar: sudo reboot"
echo "  2. Al volver a logear, caelestia-shell debería arrancar con Hyprland"
echo "  3. Si el WiFi no funciona: ver docs/wifi-fix.md"
echo "  4. Para cambiar wallpaper: caelestia wallpaper set ~/Pictures/Wallpapers/foto.jpg"
echo ""
