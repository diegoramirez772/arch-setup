# Guía de archinstall — Paso a paso

Guía visual para instalar Arch Linux en el IdeaPad 330 con dual boot Windows.
Leer `docs/dual-boot.md` antes de empezar.

---

## Antes de correr archinstall

Verificar que hay internet:
```bash
ping archlinux.org -c 3
```

Si no hay internet: conectar el celular por USB con USB tethering. Ver `docs/wifi-fix.md`.

Correr el instalador:
```bash
archinstall
```

---

## Pantalla por pantalla

### Idioma del instalador
Dejar en inglés — es más fácil buscar ayuda en inglés si algo falla.

---

### Mirrors
Seleccionar **"Mirror region"** → buscar y seleccionar tu país o usar `Worldwide`.

---

### Locales
- **Locale language:** `es_MX` o `es_419` (español latinoamericano)
- **Locale encoding:** UTF-8

---

### Disk configuration ← PARTE CRÍTICA

Elegir: **"Manual partitioning"**

Seleccionar el disco: `/dev/sda` (el de 1TB, NO el USB)

Vas a ver las particiones existentes. Identificar:
- Una pequeña de ~500MB → es la EFI de Windows
- Una grande de ~830GB → es Windows C:
- Una de ~570MB → es recuperación de Windows
- Un bloque de ~100GB que dice "free space" → acá va Arch

**En el bloque de free space (~100GB):**
- Seleccionarlo → Add partition
- Filesystem: `ext4`
- Mount point: `/`
- Formatear: `Yes`

**En la partición EFI (~500MB):**
- Seleccionarla → Edit
- Mount point: `/boot/efi`
- Formatear: **`No`** ← crítico, si se formatea se rompe Windows

**Las particiones de Windows:** no tocarlas para nada.

---

### Bootloader
Seleccionar: **GRUB**
NO elegir systemd-boot.

---

### Swap
Recomendado: **zram** o sin swap (el script post-install configura zram).

---

### Hostname
Nombre que quieras para la máquina. Ej: `ideapad`

---

### Root password
Poner una contraseña al root. Anotarla.

---

### User account
- Crear un usuario normal (no root) con tu nombre
- Marcar como **sudoer**: Yes

---

### Profile
Seleccionar: **Desktop** → **Hyprland**

Si no aparece Hyprland, seleccionar **Minimal** y el script post-install instala Hyprland.

---

### Audio
Seleccionar: **Pipewire**

---

### Network configuration
Seleccionar: **NetworkManager**

---

### Timezone
Buscar tu zona: `America/Mexico_City` o la que corresponda.

---

### Instalar
Revisar el resumen que muestra archinstall.
Verificar que:
- La EFI está en `/boot/efi` y NO se va a formatear
- La partición de Arch (ext4, ~100GB) está en `/` y SÍ se va a formatear
- Windows no aparece tocado

Si todo se ve bien: confirmar y esperar que termine (~5-15 minutos).

---

## Al terminar

archinstall pregunta si querés hacer chroot o reiniciar.
Seleccionar **Reboot**.

Sacar el USB cuando la pantalla quede negra / apague.

Al reiniciar aparece GRUB con Arch Linux. Si Windows no aparece: ver `docs/dual-boot.md` sección "Primer arranque".

---

## Primer login

Ingresar con el usuario que creaste (no root).

Luego correr:
```bash
git clone https://github.com/diegoramirez772/arch-setup.git
cd arch-setup
bash install/2-post-install.sh
```
