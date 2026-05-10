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

# Configuración de render para GPU integrada de gama baja
# explicit_sync=1 evita tearing, explicit_sync_kms=0 evita crashes en Stoney
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

# caelestia dots ya incluye hyprland.conf — agregar source de nuestro archivo AMD
if [ -f "$HYPR_USER_CONF" ]; then
    if ! grep -q "amd-env.conf" "$HYPR_USER_CONF"; then
        echo "" >> "$HYPR_USER_CONF"
        echo "# Config AMD Radeon R2 — generado por arch-setup" >> "$HYPR_USER_CONF"
        echo "source = ~/.config/hypr/amd-env.conf" >> "$HYPR_USER_CONF"
    fi
    if ! grep -q "caelestia shell" "$HYPR_USER_CONF"; then
        echo "exec-once = caelestia shell -d" >> "$HYPR_USER_CONF"
        info "Autostart de caelestia agregado"
    else
        info "Autostart ya presente — saltando"
    fi
else
    warn "hyprland.conf no encontrado — agregar manualmente:"
    warn "  source = ~/.config/hypr/amd-env.conf"
    warn "  exec-once = caelestia shell -d"
fi

# ─── Copiar nuestra shell.json encima de la default ──────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../config/shell.json" ]; then
    mkdir -p "$HOME/.config/caelestia"
    cp "$SCRIPT_DIR/../config/shell.json" "$HOME/.config/caelestia/shell.json"
    info "shell.json copiado a ~/.config/caelestia/"
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
