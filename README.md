# arch-setup

Repositorio de instalación de Arch Linux + Hyprland + caelestia-shell para Lenovo IdeaPad 330.

Sirve como guía de instalación, respaldo en USB y contexto de hardware para futuras IAs.

---

## Hardware

| Componente | Detalle |
|---|---|
| Laptop | Lenovo IdeaPad 330 (81D5) |
| CPU | AMD E2-9000 — 2 núcleos @ 1.8GHz |
| GPU | AMD Radeon R2 (integrada) |
| RAM | 8GB DDR4 @ 1866MHz |
| Disco | WD 1TB HDD (WDC WD10SPZX-24Z10) |
| WiFi | Realtek 8821CE — requiere `rtl8821ce-dkms` desde AUR |
| Pantalla | 1366x768 @ 60Hz |
| Firmware | UEFI (sin Secure Boot) |
| SO actual | Windows 10 Pro (dual boot durante transición) |

---

## Stack

| Componente | Paquete |
|---|---|
| Window Manager | `hyprland` |
| Shell UI | `caelestia-shell` (AUR) |
| Shell CLI | `caelestia-cli` (AUR) |
| AUR Helper | `yay` |
| Audio | `pipewire` + `wireplumber` + `pipewire-pulse` |
| Red | `networkmanager` |
| Terminal | `foot` |
| Archivos | `thunar` |
| Shell | `fish` |
| Bluetooth | `bluez` + `bluez-utils` |
| Bootloader | `grub` + `os-prober` |

---

## Orden de instalación

1. Leer [`docs/dual-boot.md`](docs/dual-boot.md) completo antes de tocar el disco
2. Seguir [`install/1-archinstall-guide.md`](install/1-archinstall-guide.md) para instalar la base
3. Clonar este repo y correr el primer script:
   ```bash
   git clone https://github.com/diegoramirez772/arch-setup.git
   cd arch-setup
   bash install/2-post-install.sh
   ```
4. Correr el segundo script para caelestia + dots:
   ```bash
   bash install/3-caelestia-setup.sh
   ```
5. Reiniciar: `sudo reboot`
6. Ante cualquier problema de WiFi: [`docs/wifi-fix.md`](docs/wifi-fix.md)
7. Cuando Arch convenza y quieras eliminar Windows: [`docs/expand-arch.md`](docs/expand-arch.md)

---

## Repos base

- caelestia-shell: https://github.com/caelestia-dots/shell
- caelestia dots: https://github.com/caelestia-dots/caelestia
