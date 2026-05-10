#!/bin/bash
# Setup de caelestia-shell + caelestia dots
# Paso A: caelestia-shell ya instalado vía AUR en 2-post-install.sh
# Paso B: clonar caelestia dots y correr su installer
# Correr como usuario normal DESPUÉS de 2-post-install.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# ─── Verificar que fish está disponible (lo necesita el installer de caelestia) ──
if ! command -v fish &>/dev/null; then
    error "fish no está instalado. Correr primero 2-post-install.sh"
fi

# ─── Verificar que yay está disponible ───────────────────────────────────────
if ! command -v yay &>/dev/null; then
    error "yay no está instalado. Correr primero 2-post-install.sh"
fi

# ─── Dependencias adicionales que necesita caelestia-shell en runtime ─────────
info "Instalando dependencias de runtime de caelestia-shell..."
yay -S --needed --noconfirm \
    quickshell \
    app2unit \
    aubio \
    libcava \
    libqalculate \
    ddcutil \
    brightnessctl \
    lm_sensors \
    qt6-base \
    qt6-declarative \
    wl-clipboard \
    cliphist \
    btop \
    eza \
    jq \
    fastfetch \
    starship \
    trash-cli

# ─── Dependencias de los dots de caelestia ───────────────────────────────────
info "Instalando dependencias de caelestia dots..."
sudo pacman -S --needed --noconfirm \
    xdg-desktop-portal-hyprland \
    wireplumber \
    adw-gtk-theme

yay -S --needed --noconfirm \
    papirus-icon-theme \
    ttf-jetbrains-mono-nerd

# ─── Clonar caelestia dots ────────────────────────────────────────────────────
CAELESTIA_DIR="$HOME/.local/share/caelestia"

if [ -d "$CAELESTIA_DIR" ]; then
    warn "caelestia dots ya existe en $CAELESTIA_DIR"
    read -rp "¿Actualizar el repo existente? (s/N): " update_dots
    if [[ "$update_dots" =~ ^[Ss]$ ]]; then
        info "Actualizando caelestia dots..."
        git -C "$CAELESTIA_DIR" pull
    else
        info "Saltando clonado — usando versión existente"
    fi
else
    info "Clonando caelestia dots en $CAELESTIA_DIR..."
    git clone https://github.com/caelestia-dots/caelestia.git "$CAELESTIA_DIR"
fi

# ─── ADVERTENCIA antes de correr el installer ────────────────────────────────
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  IMPORTANTE: leer antes de continuar                       ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "El installer de caelestia va a hacer SYMLINKS de sus configs en:"
echo "  ~/.config/hypr/     (Hyprland)"
echo "  ~/.config/foot/     (terminal)"
echo "  ~/.config/fish/     (shell)"
echo "  ~/.config/caelestia/"
echo ""
echo "Esto significa que NO podés mover ni borrar la carpeta:"
echo "  $CAELESTIA_DIR"
echo "...o se rompen todos los symlinks."
echo ""
echo "Si ya tenías configs propias en esas rutas, el installer las va a"
echo "reemplazar. Hacé backup si te importa algo de lo que hay ahí."
echo ""
read -rp "¿Continuar con la instalación de caelestia dots? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    warn "Instalación cancelada. Los dots están clonados en $CAELESTIA_DIR"
    warn "Podés correr el installer manualmente cuando quieras:"
    warn "  cd $CAELESTIA_DIR && fish install.fish"
    exit 0
fi

# ─── Correr el installer oficial de caelestia dots ───────────────────────────
info "Corriendo installer de caelestia dots..."
cd "$CAELESTIA_DIR"

# El installer acepta flags opcionales: --spotify --vscode --discord --zen
# VS Code ya lo instalamos en 2-post-install.sh si el usuario lo eligió
if command -v code &>/dev/null; then
    fish install.fish --vscode
else
    fish install.fish
fi

# ─── Configurar autostart y variables de entorno en Hyprland ─────────────────
info "Configurando Hyprland para AMD Radeon R2..."
HYPR_USER_CONF="$HOME/.config/hypr/hyprland.conf"

# Variables de entorno obligatorias para AMD integrado en Wayland
HYPR_EXTRA="$HOME/.config/hypr/amd-env.conf"
tee "$HYPR_EXTRA" > /dev/null << 'EOF'
# Variables de entorno para AMD Radeon R2 (Stoney Ridge) + Wayland
env = LIBVA_DRIVER_NAME,radeonsi
env = AQ_DRM_DEVICES,/dev/dri/card0
env = MESA_DEBUG,quiet
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland
env = SDL_VIDEODRIVER,wayland

# Cursor
env = XCURSOR_THEME,Bibata-Modern-Ice
env = XCURSOR_SIZE,24

# Render para GPU integrada de gama baja
render {
    explicit_sync = 1
    explicit_sync_kms = 0
}

misc {
    disable_hyprland_logo = true
    enable_hyprcursor = false
}
EOF
info "Configuración AMD guardada en $HYPR_EXTRA"

# caelestia dots ya incluye hyprland.conf — agregar sources y autostarts
if [ -f "$HYPR_USER_CONF" ]; then
    grep -q "amd-env.conf"    "$HYPR_USER_CONF" || echo "source = ~/.config/hypr/amd-env.conf"    >> "$HYPR_USER_CONF"
    grep -q "keybindings.conf" "$HYPR_USER_CONF" || echo "source = ~/.config/hypr/keybindings.conf" >> "$HYPR_USER_CONF"
    grep -q "caelestia shell"  "$HYPR_USER_CONF" || echo "exec-once = caelestia shell -d"                        >> "$HYPR_USER_CONF"
    grep -q "hypridle"         "$HYPR_USER_CONF" || echo "exec-once = hypridle"                                    >> "$HYPR_USER_CONF"
    grep -q "lxpolkit"         "$HYPR_USER_CONF" || echo "exec-once = lxpolkit"                                    >> "$HYPR_USER_CONF"
    grep -q "cliphist"         "$HYPR_USER_CONF" || echo "exec-once = wl-paste --watch cliphist store"             >> "$HYPR_USER_CONF"
    grep -q "gnome-keyring"    "$HYPR_USER_CONF" || echo "exec-once = /usr/bin/gnome-keyring-daemon --start --components=secrets" >> "$HYPR_USER_CONF"
    info "hyprland.conf configurado"
else
    warn "hyprland.conf no encontrado — agregar manualmente:"
    warn "  source = ~/.config/hypr/amd-env.conf"
    warn "  source = ~/.config/hypr/keybindings.conf"
    warn "  exec-once = caelestia shell -d"
    warn "  exec-once = hypridle"
    warn "  exec-once = lxpolkit"
fi

# ─── Copiar configs al sistema ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

mkdir -p "$HOME/.config/caelestia"
mkdir -p "$HOME/.config/hypr"

# shell.json de caelestia
[ -f "$CONFIG_DIR/shell.json" ] && cp "$CONFIG_DIR/shell.json" "$HOME/.config/caelestia/shell.json" && info "shell.json copiado"

# hyprlock — pantalla de bloqueo
[ -f "$CONFIG_DIR/hyprlock.conf" ] && cp "$CONFIG_DIR/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf" && info "hyprlock.conf copiado"

# hypridle — daemon de inactividad y suspend
[ -f "$CONFIG_DIR/hypridle.conf" ] && cp "$CONFIG_DIR/hypridle.conf" "$HOME/.config/hypr/hypridle.conf" && info "hypridle.conf copiado"

# keybindings
[ -f "$CONFIG_DIR/hyprland-keybindings.conf" ] && cp "$CONFIG_DIR/hyprland-keybindings.conf" "$HOME/.config/hypr/keybindings.conf" && info "keybindings.conf copiado"

# GTK settings — tema, cursor, iconos para apps GTK (Chrome, Thunar, file-roller, etc.)
if [ -f "$CONFIG_DIR/gtk-settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    cp "$CONFIG_DIR/gtk-settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    cp "$CONFIG_DIR/gtk-settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    # Cursor para apps X11 legacy
    mkdir -p "$HOME/.icons/default"
    tee "$HOME/.icons/default/index.theme" > /dev/null << 'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=Bibata-Modern-Ice
EOF
    info "GTK settings y cursor copiados"
fi

# SDDM config — tema de pantalla de login
if [ -f "$CONFIG_DIR/sddm.conf" ]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$CONFIG_DIR/sddm.conf" /etc/sddm.conf.d/arch-setup.conf
    info "SDDM config instalado"
fi

# Instalar tema catppuccin para SDDM
if pacman -Q sddm &>/dev/null; then
    warn "Instalando tema SDDM catppuccin — puede tardar un momento..."
    yay -S --needed --noconfirm catppuccin-sddm-theme-git || warn "Tema SDDM no instalado — SDDM funcionará con tema default"
fi

# ─── Resumen final ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  caelestia listo                       ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Para arrancar caelestia manualmente:"
echo "  caelestia shell -d"
echo ""
echo "Al reiniciar, Hyprland lo arranca automáticamente."
echo ""
echo "Comandos útiles:"
echo "  caelestia wallpaper set ~/Pictures/Wallpapers/foto.jpg"
echo "  caelestia scheme set catppuccin-mocha"
echo "  caelestia shell -s    # ver todos los comandos IPC disponibles"
echo ""
echo "Si algo falla: ver docs/known-issues.md"
echo ""
