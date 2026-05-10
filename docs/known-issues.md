# Problemas conocidos — Lenovo IdeaPad 330 con Arch Linux

Hardware: AMD E2-9000 + Radeon R2 + Realtek 8821CE — 1366x768

---

## WiFi no funciona en la live ISO

**Causa:** Realtek 8821CE no tiene driver en el kernel base.
**Solución:** USB tethering desde el celular durante la instalación. Ver `wifi-fix.md`.

---

## WiFi se desconecta solo después de un rato

**Causa:** Power management agresivo del chip Realtek en Linux.
**Solución:**
```bash
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf << EOF
[connection]
wifi.powersave = 2
EOF
sudo systemctl restart NetworkManager
```

---

## Pantalla negra al arrancar Hyprland

**Causa:** AMD Radeon R2 a veces necesita que se especifique el driver explícitamente.
**Solución:** En `/etc/mkinitcpio.conf` agregar `amdgpu` en MODULES:
```
MODULES=(amdgpu)
```
```bash
sudo mkinitcpio -P
```

---

## Rendimiento lento en general

**Causa:** AMD E2-9000 es un CPU de gama muy baja (1.8GHz, 2 núcleos).
**Lo que ayuda:**
- Usar `zram` para swap en RAM (más rápido que swap en HDD)
- Evitar compositors pesados — Hyprland está bien optimizado para hardware limitado
- No instalar KDE ni GNOME

```bash
# Habilitar zram
sudo pacman -S zram-generator
sudo tee /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0
```

---

## Tecla Fn y brillo no funcionan

**Causa:** El IdeaPad 330 tiene algunos quirks con acpi en Linux.
**Solución:** Agregar parámetro al kernel en `/etc/default/grub`:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet acpi_backlight=native"
```
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## El HDD hace lag en operaciones de escritura pesada

**Causa:** Es un HDD de 5400rpm, no un SSD — es lento por naturaleza.
**Lo que ayuda:**
- `noatime` en opciones de montaje en `/etc/fstab` reduce escrituras innecesarias
- `npm` y builds de Node.js son notablemente más rápidos que en Windows de todas formas
