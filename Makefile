# Makefile — arch-setup
# Alternativa a bash para correr pasos individuales
# Uso: make <target>
#
# Si bash falla, make es otro mecanismo de ejecución disponible en Arch base.
# make está incluido en base-devel que viene en el grupo base de Arch.

.PHONY: all base caelestia check wifi hyprland audio grub fix-caelestia keybindings hyprlock usb git-ssh node reset help

# Instalación completa
all: base caelestia check

# Solo el stack base (paso 1 y 2 del install.sh)
base:
	@echo "==> Instalando stack base..."
	bash install/2-post-install.sh

# Solo caelestia
caelestia:
	@echo "==> Instalando caelestia..."
	bash install/3-caelestia-setup.sh

# Health check
check:
	@echo "==> Verificando instalación..."
	bash install/repair/health-check.sh

# Scripts de reparación individuales
wifi:
	@echo "==> Reparando WiFi..."
	bash install/repair/fix-wifi.sh

hyprland:
	@echo "==> Reparando Hyprland..."
	bash install/repair/fix-hyprland.sh

audio:
	@echo "==> Reparando audio..."
	bash install/repair/fix-audio.sh

grub:
	@echo "==> Reparando GRUB..."
	bash install/repair/fix-grub.sh

fix-caelestia:
	@echo "==> Reparando caelestia..."
	bash install/repair/fix-caelestia.sh

keybindings:
	@echo "==> Reparando keybindings..."
	bash install/repair/fix-keybindings.sh

hyprlock:
	@echo "==> Reparando hyprlock/hypridle..."
	bash install/repair/fix-hyprlock.sh

usb:
	@echo "==> Reparando automontaje USB..."
	bash install/repair/fix-usb.sh

git-ssh:
	@echo "==> Reparando Git SSH dos cuentas..."
	bash install/repair/fix-git-ssh.sh

node:
	@echo "==> Reparando Node.js / nvm.fish..."
	bash install/repair/fix-node.sh

# Reiniciar state file para empezar de cero
reset:
	@echo "==> Reiniciando estado de instalación..."
	rm -f $(HOME)/.arch-setup.state
	@echo "Listo. El próximo 'bash install/install.sh' empieza desde cero."

# Ayuda
help:
	@echo ""
	@echo "  make all           — instalación completa"
	@echo "  make base          — solo stack base (sin caelestia)"
	@echo "  make caelestia     — solo caelestia"
	@echo "  make check         — health check del sistema"
	@echo ""
	@echo "  make wifi          — reparar WiFi"
	@echo "  make hyprland      — reparar Hyprland / AMD"
	@echo "  make audio         — reparar audio"
	@echo "  make grub          — reparar GRUB / dual boot"
	@echo "  make fix-caelestia — reparar caelestia-shell"
	@echo "  make keybindings   — reparar atajos de teclado"
	@echo "  make hyprlock      — reparar pantalla de bloqueo"
	@echo "  make usb           — reparar automontaje USB/teléfonos"
	@echo "  make git-ssh       — reparar Git SSH dos cuentas"
	@echo "  make node          — reparar Node.js / nvm.fish en fish"
	@echo ""
	@echo "  make reset         — reiniciar estado de instalación"
	@echo ""
