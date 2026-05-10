# Problemas conocidos — Lenovo IdeaPad 330 con Arch Linux

Hardware: AMD E2-9000 + Radeon R2 (Stoney Ridge) + Realtek 8821CE — 1366x768
Script de reparación disponible para cada problema.

---

## WiFi no funciona en la live ISO ni post-instalación

**Síntoma:** WiFi no aparece, no se conecta, o error de módulo.
**Causa:** Realtek 8821CE no tiene driver en el kernel base. Además, el kernel trae `rtw88` que entra en conflicto.
**Fix rápido:** `bash install/repair/fix-wifi.sh`
**Fix manual:**
```bash
# Blacklist del driver conflictivo del kernel
sudo tee /etc/modprobe.d/blacklist-rtw88.conf << 'EOF'
blacklist rtw88_8821ce
blacklist rtw88_core
blacklist rtw88_pci
EOF

yay -S rtl8821ce-dkms-git   # usar -git, no rtl8821ce-dkms
sudo modprobe rtl8821ce
```
**Durante instalación:** usar USB tethering del celular. Ver `wifi-fix.md`.

---

## WiFi se desconecta solo después de inactividad

**Síntoma:** WiFi cae después de un rato sin usar.
**Causa:** Power management agresivo del chip Realtek.
**Fix:**
```bash
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF
sudo systemctl restart NetworkManager
```

---

## WiFi bloqueado por firmware (hard block)

**Síntoma:** `rfkill list` muestra "Hard blocked: yes".
**Causa:** El firmware UEFI del IdeaPad bloquea el WiFi.
**Fix:**
```bash
rfkill unblock wifi
sudo tee /etc/modprobe.d/ideapad-laptop.conf << 'EOF'
options ideapad_laptop wifi_rfkill_state=0
EOF
```
Si persiste: entrar a BIOS (F2) y verificar que WiFi esté habilitado.

---

## Pantalla negra al arrancar Hyprland

**Síntoma:** Hyprland no arranca, pantalla negra total o bloqueo gráfico.
**Causa:** AMD Radeon R2 (Stoney Ridge) necesita parámetros específicos de kernel y configuración de amdgpu.
**Fix rápido:** `bash install/repair/fix-hyprland.sh`
**Fix manual:**
```bash
# Parámetros de kernel en /etc/default/grub:
# amdgpu.dc=1       — Display Core para Stoney (obligatorio para Wayland)
# acpi_backlight=native — fix de congelación gráfica del IdeaPad 330
# iommu=pt          — mejora rendimiento GPU integrada
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 amdgpu.dc=1 acpi_backlight=native iommu=pt"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Deshabilitar KFD (Stoney Ridge no lo soporta — causa errores)
sudo tee /etc/modprobe.d/amdgpu.conf << 'EOF'
options amdgpu kfd_disabled=1
EOF
```

---

## Artefactos o flickering en Hyprland

**Síntoma:** Pantalla con artefactos verdes, flickering, o rendering roto.
**Causa:** explicit_sync mal configurado para AMD integrado.
**Fix:** Agregar a `~/.config/hypr/hyprland.conf`:
```
render {
    explicit_sync = 1
    explicit_sync_kms = 0
}
```

---

## Variables de entorno AMD necesarias para Wayland

Agregar a `~/.config/hypr/amd-env.conf` (sourced desde hyprland.conf):
```
env = LIBVA_DRIVER_NAME,radeonsi
env = AQ_DRM_DEVICES,/dev/dri/card0
env = MESA_DEBUG,quiet
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland
env = SDL_VIDEODRIVER,wayland
```
El script `3-caelestia-setup.sh` lo crea automáticamente.

---

## Windows no aparece en GRUB

**Fix rápido:** `bash install/repair/fix-grub.sh`
**Fix manual:**
```bash
sudo pacman -S os-prober
echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## caelestia-shell no arranca

**Fix rápido:** `bash install/repair/fix-caelestia.sh`
**Causa frecuente:** `quickshell-git` está marcado como out-of-date en AUR. Usar `quickshell` (estable).
```bash
yay -S quickshell   # NO usar quickshell-git
```

---

## Rendimiento lento en general

**Causa:** AMD E2-9000 es CPU de gama baja (1.8GHz, 2 núcleos) + HDD de 5400rpm.
**Lo que ayuda:**
- zram habilitado (ya configurado por el script)
- Scheduler schedutil:
```bash
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```
- `noatime` en `/etc/fstab` (reduce escrituras en HDD):
```bash
# Agregar noatime a las opciones de la partición de Arch en /etc/fstab
# Ejemplo: UUID=xxx / ext4 rw,noatime 0 1
```

---

## Teclas Fn y brillo no funcionan

**Fix:** Ya incluido en los parámetros de kernel (`acpi_backlight=native`).
Si igual no funciona:
```bash
# Controlar brillo manualmente
brightnessctl set 50%
brightnessctl set +10%
brightnessctl set 10%-
```

---

## amdgpu en mkinitcpio (si hay problemas gráficos en arranque temprano)

```bash
# Verificar
grep MODULES /etc/mkinitcpio.conf

# Si no tiene amdgpu, agregarlo:
sudo sed -i 's/MODULES=(/MODULES=(amdgpu /' /etc/mkinitcpio.conf
sudo mkinitcpio -P
```
