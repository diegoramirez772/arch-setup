# CONTEXT.md — Pegar esto a una IA después de instalar Arch

Este archivo existe para que cualquier IA tenga contexto completo del sistema
sin tener que preguntar nada desde cero.

---

## Hardware completo

| Componente | Detalle |
|---|---|
| Laptop | Lenovo IdeaPad 330 (modelo 81D5) |
| CPU | AMD E2-9000 — 2 núcleos físicos / 2 lógicos @ 1.8GHz |
| GPU | AMD Radeon R2 Graphics (integrada — NO NVIDIA, NO Intel) |
| RAM | 8GB DDR4 @ 1866MHz |
| Disco | WD 1TB HDD (WDC WD10SPZX-24Z10) |
| WiFi | Realtek 8821CE — driver: `rtl8821ce-dkms` (AUR) |
| Pantalla | 1366x768 @ 60Hz |
| Firmware | UEFI — Secure Boot no soportado (BIOS antigua) |

---

## Layout del disco (completar con `lsblk -f` después de instalar)

```
# Correr: lsblk -f
# Pegar output acá después de la instalación

# Estructura esperada:
# /dev/sda1  →  EFI (vfat, ~500MB)   →  /boot/efi
# /dev/sda2  →  Windows C: (ntfs)    →  (sin montar)
# /dev/sda3  →  Recuperación Windows →  (sin montar)
# /dev/sda4  →  Arch Linux (ext4)    →  /
```

---

## Stack instalado

- Window Manager: Hyprland
- Shell UI: caelestia-shell (AUR)
- Shell CLI: caelestia-cli (AUR)
- AUR Helper: yay
- Audio: pipewire + wireplumber + pipewire-pulse
- Red: NetworkManager
- Terminal: foot
- Archivos: thunar
- Shell: fish
- Bootloader: GRUB + os-prober

---

## Rutas importantes

```
~/.config/hypr/hyprland.conf     — config de Hyprland
~/.config/caelestia/shell.json   — config de caelestia-shell
~/dev/                           — carpeta de proyectos
~/Pictures/Wallpapers/           — wallpapers
```

---

## Comandos de caelestia más usados

```bash
caelestia wallpaper set <ruta>     # cambiar wallpaper
caelestia scheme set <nombre>      # cambiar esquema de colores
caelestia shell toggle             # mostrar/ocultar shell
```

---

## Cómo actualizar el sistema

```bash
yay                  # actualiza todo: pacman + AUR
yay -Syu             # equivalente explícito
```

---

## Dev setup

- Node.js manejado con nvm (no instalar Node directo con pacman)
- Proyectos en `~/dev/`
- Stack principal: Next.js y Elm
- Editor: VS Code (`visual-studio-code-bin` AUR)

---

## Dual boot

- GRUB maneja el boot con detección de Windows via os-prober
- Si Windows no aparece en GRUB: ver `docs/dual-boot.md` sección "Primer arranque"
- Para montar la partición de Windows desde Arch: `sudo mount -t ntfs3 /dev/sdaX /mnt/windows`

---

## Problemas conocidos del IdeaPad 330

Ver `docs/known-issues.md`
