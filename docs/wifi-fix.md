# WiFi Fix — Realtek 8821CE en Arch Linux

El IdeaPad 330 trae el chip **Realtek RTL8821CE** que NO tiene driver en el kernel de Linux.
Hay que instalarlo desde AUR después de tener internet por otro medio.

---

## Alternativas para tener internet sin WiFi durante la instalación

### Opción 1 — USB Tethering desde el celular (la más fácil)
1. Conectar el celular al laptop por cable USB
2. En Android: Ajustes → Red → Anclaje/Tethering → **Compartir internet por USB**
3. En la live ISO de Arch el adaptador aparece automáticamente como `usb0`
4. Verificar: `ip link` — debería mostrar la interfaz activa
5. Si no obtiene IP: `dhcpcd usb0`

### Opción 2 — Cable ethernet
Conectar por cable ethernet directo si tenés acceso a un router con puerto libre.

### Opción 3 — Hotspot WiFi del celular
Si el celular tiene datos, crear un hotspot y conectar el laptop al hotspot.
El IdeaPad 330 en live ISO puede no detectar el WiFi — volver a opción 1 en ese caso.

---

## Instalar el driver Realtek 8821CE (post-instalación)

Una vez dentro de Arch con internet por cualquier medio:

```bash
# Instalar yay primero si aún no está
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..

# Instalar el driver y DKMS para que sobreviva actualizaciones del kernel
yay -S rtl8821ce-dkms

# Cargar el módulo
sudo modprobe 8821ce

# Verificar que el módulo está activo
lsmod | grep 8821
```

---

## Verificar que WiFi funciona después del driver

```bash
# Ver interfaces de red
ip link

# Conectar con nmtui (interfaz gráfica de texto de NetworkManager)
nmtui

# O con nmcli desde terminal
nmcli device wifi list
nmcli device wifi connect "NombreDeRed" password "contraseña"
```

---

## Si el driver falla o da problemas

Algunos kernels recientes tienen conflictos con rtl8821ce-dkms. Alternativas:

```bash
# Probar el paquete alternativo
yay -S rtw88-dkms

# O el paquete git más actualizado
yay -S rtl8821ce-dkms-git
```

---

## Problema conocido: WiFi se desconecta solo

En el IdeaPad 330 el chip Realtek tiene problemas de power management en Linux.
Si el WiFi se cae después de un rato de inactividad:

```bash
# Crear archivo de configuración para deshabilitar power save del WiFi
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf << EOF
[connection]
wifi.powersave = 2
EOF

sudo systemctl restart NetworkManager
```
