#!/bin/bash
# Script maestro de instalación — arch-setup
# Lenovo IdeaPad 330 — AMD E2-9000 + Radeon R2 + Realtek 8821CE
#
# CARACTERÍSTICAS DE ROBUSTEZ:
#   - State file: si falla, correr de nuevo y salta los pasos ya completados
#   - Retry: operaciones de red se reintentan automáticamente 3 veces
#   - Error handling por paso: un fallo no mata todo el proceso
#   - Log completo en ~/arch-setup-install.log
#
# Uso: bash install/install.sh
# Reanudar después de fallo: bash install/install.sh   (detecta estado solo)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; log "OK: $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; log "WARN: $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; log "ERROR: $1"; }
section() { echo -e "\n${BLUE}══ $1 ══${NC}\n"; log "=== $1 ==="; }
skip()    { echo -e "${CYAN}[→]${NC} $1 — ya completado, saltando"; }

LOG_FILE="$HOME/arch-setup-install.log"
STATE_FILE="$HOME/.arch-setup.state"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED_STEPS=()

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }

# ─── State tracking ───────────────────────────────────────────────────────────
step_done()  { grep -qx "$1" "$STATE_FILE" 2>/dev/null; }
mark_done()  { echo "$1" >> "$STATE_FILE"; }
reset_state(){ rm -f "$STATE_FILE"; info "Estado reiniciado — el próximo run empieza desde cero"; }

# ─── Retry para operaciones de red ────────────────────────────────────────────
# Reintenta el comando hasta 3 veces con 10 segundos de espera entre intentos
retry() {
    local max=3
    local delay=10
    local cmd="$*"
    for i in $(seq 1 "$max"); do
        if eval "$cmd"; then
            return 0
        fi
        if [ "$i" -lt "$max" ]; then
            warn "Intento $i/$max falló — reintentando en ${delay}s..."
            sleep "$delay"
        fi
    done
    return 1
}

# ─── Ejecutor de paso con state tracking ──────────────────────────────────────
# Si el paso ya estaba hecho: lo salta
# Si falla: lo registra pero continúa con el siguiente
run_step() {
    local name="$1"
    local desc="$2"
    shift 2

    if step_done "$name"; then
        skip "$desc"
        return 0
    fi

    echo -e "${BLUE}→${NC} $desc"
    log "Iniciando paso: $name"

    if "$@"; then
        mark_done "$name"
        info "$desc — OK"
        return 0
    else
        error "$desc — FALLÓ (ver $LOG_FILE)"
        FAILED_STEPS+=("$name: $desc")
        return 1
    fi
}

# ─── Banner ───────────────────────────────────────────────────────────────────
clear
echo -e "${GREEN}"
echo "  ┌─────────────────────────────────────────┐"
echo "  │         ARCH SETUP — IdeaPad 330        │"
echo "  │  AMD E2-9000 + Radeon R2 + RTL8821CE    │"
echo "  └─────────────────────────────────────────┘"
echo -e "${NC}"
echo "  Log:   $LOG_FILE"
echo "  State: $STATE_FILE"
echo ""

if [ -f "$STATE_FILE" ]; then
    echo -e "${YELLOW}Estado anterior detectado. Pasos ya completados:${NC}"
    cat "$STATE_FILE"
    echo ""
    read -rp "¿Continuar desde donde quedó? (S/n — 'n' para reiniciar todo): " cont
    if [[ "$cont" =~ ^[Nn]$ ]]; then
        reset_state
    fi
fi

log "════ Instalación iniciada ════"

# ─── Verificaciones previas ───────────────────────────────────────────────────
section "Verificaciones previas"

if [ "$EUID" -eq 0 ]; then
    error "No correr como root."
    exit 1
fi
info "Usuario: $(whoami)"

if ! ping -c 1 archlinux.org &>/dev/null; then
    error "Sin internet."
    echo ""
    echo "Opciones para conectarte:"
    echo "  1. Celular por USB → Ajustes → Compartir internet por USB"
    echo "  2. Cable ethernet"
    echo "  3. bash install/repair/fix-wifi.sh"
    exit 1
fi
info "Internet: OK"

# ─── Pasos de instalación ─────────────────────────────────────────────────────
section "PASO 1/6 — Sistema base"
run_step "reflector"  "Optimizar mirrors de pacman"    bash -c "
    sudo pacman -S --needed --noconfirm reflector
    sudo reflector --country Mexico,US --age 24 --sort rate --latest 10 --save /etc/pacman.d/mirrorlist
" || warn "reflector falló — usando mirrors por defecto"
run_step "syu"      "Actualizar sistema"               bash -c "sudo pacman -Syu --noconfirm"
run_step "base-dev" "Instalar git y base-devel"        bash -c "sudo pacman -S --needed --noconfirm git base-devel"

section "PASO 2/6 — AUR helper (yay)"
run_step "yay"      "Instalar yay"                     bash -c "
    if command -v yay &>/dev/null; then exit 0; fi
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    cd /tmp/yay-install && makepkg -si --noconfirm
"

section "PASO 3/6 — Paquetes del stack"
run_step "pacman-pkgs" "Instalar paquetes pacman"      bash -c "sudo pacman -S --needed --noconfirm \
    hyprland xdg-desktop-portal-hyprland \
    hyprlock hypridle sddm \
    pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-bluetooth \
    networkmanager bluez bluez-utils blueman \
    foot thunar thunar-volman tumbler pavucontrol \
    fish grim slurp swappy \
    mpv imv zathura zathura-pdf-mupdf \
    gvfs gvfs-mtp file-roller \
    lxpolkit gnome-keyring libsecret \
    wl-clipboard wofi libnotify brightnessctl \
    nwg-look qt5-wayland qt6-wayland \
    xdg-user-dirs xdg-utils udisks2 \
    power-profiles-daemon reflector pacman-contrib eza \
    grub os-prober \
    mesa xf86-video-amdgpu \
    noto-fonts noto-fonts-emoji ttf-liberation \
    openssh wget curl unzip htop zram-generator"

run_step "services"    "Habilitar servicios"           bash -c "
    sudo systemctl enable --now NetworkManager
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now pipewire pipewire-pulse wireplumber
    sudo systemctl enable --now power-profiles-daemon
    sudo systemctl enable sddm
    sudo systemctl enable --now udisks2
"

section "PASO 4/6 — WiFi + drivers AMD"
run_step "rtw88-blacklist" "Blacklist driver rtw88 conflictivo" bash -c "
    sudo tee /etc/modprobe.d/blacklist-rtw88.conf > /dev/null << 'EOF'
blacklist rtw88_8821ce
blacklist rtw88_core
blacklist rtw88_pci
EOF"

run_step "rtl8821ce"  "Driver WiFi Realtek 8821CE"     bash -c "
    yay -S --needed --noconfirm rtl8821ce-dkms-git
    sudo modprobe rtl8821ce 2>/dev/null || true
    sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF
    sudo systemctl restart NetworkManager
"

run_step "amdgpu-cfg" "Configurar AMD Radeon R2 (Stoney Ridge)" bash -c "
    sudo tee /etc/modprobe.d/amdgpu.conf > /dev/null << 'EOF'
options amdgpu kfd_disabled=1
EOF
    GRUB_FILE=/etc/default/grub
    if ! grep -q 'amdgpu.dc=1' \$GRUB_FILE; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 amdgpu.dc=1 acpi_backlight=native iommu=pt\"/' \$GRUB_FILE
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
"

section "PASO 5/6 — AUR + Node.js + dev tools"
run_step "aur-pkgs"   "Instalar paquetes AUR"          bash -c "yay -S --needed --noconfirm \
    caelestia-shell caelestia-cli \
    ttf-material-symbols-variable-git caskaydia-cove-nerd ttf-rubik \
    swappy"

run_step "nvm"        "Instalar nvm + Node.js LTS"     bash -c "
    if [ ! -d \$HOME/.nvm ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR=\"\$HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        nvm install --lts && nvm use --lts
    fi
"

run_step "zram"       "Configurar zram"                bash -c "
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0 || true
"

run_step "folders"    "Crear carpetas de trabajo"      bash -c "mkdir -p \$HOME/dev \$HOME/Pictures/Wallpapers"
run_step "fish-shell" "Cambiar shell a fish"           bash -c "
    if [ \"\$(basename \$SHELL)\" != 'fish' ]; then chsh -s \$(which fish); fi
"

section "PASO 6/7 — Caelestia"
run_step "caelestia"  "Instalar caelestia dots"        bash "$SCRIPT_DIR/3-caelestia-setup.sh"

section "PASO 7/7 — Git dos cuentas"
if ! step_done "git-setup"; then
    read -rp "¿Configurar Git (dos cuentas SSH)? (S/n): " setup_git
    if [[ ! "$setup_git" =~ ^[Nn]$ ]]; then
        run_step "git-setup" "Configurar Git + SSH dos cuentas" bash "$SCRIPT_DIR/setup-git.sh"
    else
        mark_done "git-setup"
    fi
fi

# ─── VS Code (siempre opcional, no bloquea) ───────────────────────────────────
if ! step_done "vscode"; then
    echo ""
    read -rp "¿Instalar VS Code? (s/N): " install_vscode
    if [[ "$install_vscode" =~ ^[Ss]$ ]]; then
        run_step "vscode" "Instalar VS Code" bash -c "yay -S --needed --noconfirm visual-studio-code-bin"
    else
        mark_done "vscode"
    fi
fi

# ─── Health check ─────────────────────────────────────────────────────────────
section "Health check"
bash "$SCRIPT_DIR/repair/health-check.sh"

# ─── Resumen ──────────────────────────────────────────────────────────────────
echo ""
if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Todo instalado correctamente          ${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "  sudo reboot"
else
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Instalación completada con errores    ${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""
    echo "Pasos que fallaron:"
    for step in "${FAILED_STEPS[@]}"; do
        echo -e "  ${RED}✗${NC} $step"
    done
    echo ""
    echo "Para reintentar solo los pasos fallidos:"
    echo "  bash install/install.sh   ← detecta el estado y salta los completados"
    echo ""
    echo "Scripts de reparación:"
    echo "  bash install/repair/fix-wifi.sh"
    echo "  bash install/repair/fix-hyprland.sh"
    echo "  bash install/repair/fix-audio.sh"
    echo "  bash install/repair/fix-grub.sh"
    echo "  bash install/repair/fix-caelestia.sh"
fi
echo ""
echo "Log completo: $LOG_FILE"
log "════ Fin de instalación — ${#FAILED_STEPS[@]} pasos fallidos ════"
