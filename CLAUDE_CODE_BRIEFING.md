# 🗂️ BRIEFING COMPLETO — Arch Linux Setup con Caelestia + Hyprland
> Pega esto entero a Claude Code al inicio de la sesión.
> Lee todo antes de escribir una sola línea de código.

---

## 🎯 Objetivo general

Ayudarme a armar un repositorio en mi GitHub llamado `arch-setup` que sirva como:
1. Base de instalación de Arch Linux con Hyprland + caelestia-shell
2. Respaldo en USB por si falla internet durante la instalación
3. Contexto de hardware para que cualquier IA futura sepa qué tengo y me guíe

**Filosofía clave:** NO inventes scripts desde cero si ya existen repos buenos en la comunidad.
Tu trabajo es buscar, curar e integrar. Solo crea scripts propios donde haya huecos o para
pegar las piezas entre sí. Si algo ya lo hace caelestia-shell, referenciarlo, no copiarlo.

---

## 💻 Mi hardware

- **Laptop:** Lenovo IdeaPad 330
- **GPU:** Intel integrada (o AMD integrada — confirmar con `lspci` durante live ISO)
- **WiFi:** Posiblemente Realtek — puede necesitar `rtl8821ce-dkms` desde AUR
- **RAM:** [COMPLETAR — ej: 8GB]
- **Disco:** [COMPLETAR — ej: 500GB HDD/SSD]
- **Firmware:** UEFI (no BIOS legacy)
- **SO actual:** Windows instalado y funcionando — NO se va a borrar todavía

---

## 💾 PLAN DE PARTICIONADO Y DUAL BOOT
### ⚠️ Esta es la parte más crítica del proceso. Leer completo.

### Por qué dual boot y no formato completo desde el día 1

La decisión es NO formatear todo el disco desde el inicio. La razón es simple:
si algo falla en la instalación de Arch (WiFi, drivers, bootloader), necesito poder
volver a Windows, buscar la solución y reintentar sin quedarme sin sistema operativo.
El dual boot es la red de seguridad. Una vez que Arch funcione bien y me convenza
después de unas semanas de uso real, ahí sí elimino Windows y expando Arch.
Ese paso de eliminar Windows es futuro y opcional — no ahora.

---

### FASE 0: Preparar Windows antes de tocar nada

Estos pasos se hacen desde Windows ANTES de bootear el USB de Arch.
Documentar en `docs/dual-boot.md` con instrucciones detalladas:

**0.1 — Verificar y desactivar BitLocker**
- Panel de control → Sistema y seguridad → Cifrado de unidad BitLocker
- Si está activo: desactivarlo y esperar a que termine de descifrar (puede tardar horas)
- Si no se desactiva: Arch no podrá ver ni tocar la partición de Windows correctamente
- En IdeaPad 330 con Windows 11 Home, BitLocker puede estar activo aunque no lo sepas

**0.2 — Limpiar espacio en Windows**
- Mover videos, juegos, descargas pesadas a USB externo o nube (Google Drive, etc.)
- El objetivo es tener C: con suficiente holgura después de reducirla
- Mínimo recomendado para Windows: dejarle al menos 60-80GB para que respire

**0.3 — Reducir partición C: y crear espacio libre**
- Win+X → Administración de discos
- Click derecho en disco C: → "Reducir volumen"
- En "Tamaño del espacio que desea reducir": ingresar el equivalente a 100GB (en MB: 102400)
- Hacer clic en Reducir
- Al terminar, aparecerá un bloque negro/verde que dice "No asignado"
- IMPORTANTE: NO crear partición nueva ahí desde Windows — dejarlo como "No asignado"
- Arch lo tomará desde el instalador

**Estado del disco tras este paso:**
```
┌──────────────┬───────────────────────┬─────────────────────────┐
│  EFI ~500MB  │   Windows C:          │   Sin asignar ~100GB    │
│  (sistema)   │   (reducida, intacta) │   ← Arch irá aquí       │
└──────────────┴───────────────────────┴─────────────────────────┘
```

---

### FASE 1: Bootear el USB de Arch

- USB grabado con Rufus en modo DD (no ISO mode)
- Al encender laptop: F2 o F12 para entrar al boot menu del IdeaPad 330
- Seleccionar el USB
- Al cargar la live ISO de Arch, verificar internet: `ping archlinux.org`
- Si el WiFi no jala en la live ISO → ver `docs/wifi-fix.md`
  (alternativa: hotspot del celular via cable USB)

---

### FASE 2: Particionado en archinstall — instrucciones exactas

Cuando archinstall llegue a "Disk configuration":

- Elegir: **"Manual partitioning"**
- Seleccionar el disco (ej. `/dev/sda`)
- Identificar el espacio libre de ~100GB (aparece como "free space" o sin tipo)

**Crear UNA sola partición nueva para Arch:**
```
Tipo:              Linux filesystem
Filesystem:        ext4
Punto de montaje:  /
Tamaño:            todo el espacio libre disponible
Formatear:         SÍ (es nueva, no tiene nada)
```

**Para el boot — usar la EFI ya existente de Windows:**
```
Partición EFI:     la que ya existe (tipo EFI, ~500MB)
Punto de montaje:  /boot/efi
Formatear:         NO ← crítico, si se formatea se rompe el boot de Windows
```

**Resultado visual de lo que archinstall debe mostrar:**
```
/dev/sda1  →  EFI existente  →  /boot/efi  →  NO formatear  ← Windows boot aquí también
/dev/sda2  →  Windows NTFS   →  (ninguno)  →  NO tocar
/dev/sda3  →  nueva ext4     →  /          →  SÍ formatear   ← Arch va aquí
```

**Bootloader:** elegir GRUB (no systemd-boot)
GRUB tiene detección automática de Windows via os-prober.

---

### FASE 3: Primer arranque con dual boot

Al reiniciar aparecerá el menú de GRUB con opciones.
Si Windows no aparece automáticamente, desde Arch:
```bash
sudo pacman -S os-prober
# Editar /etc/default/grub
# Descomentar o agregar: GRUB_DISABLE_OS_PROBER=false
sudo grub-mkconfig -o /boot/grub/grub.cfg
# Reiniciar — ahora aparecen ambos sistemas
```

---

### Señales de PELIGRO — cuándo parar todo

Si en cualquier momento del instalador aparece:
- "Formatear /dev/sdaX" donde sdaX es la EFI de Windows → PARAR
- Opción de usar todo el disco en vez del espacio libre → PARAR
- No se distingue cuál es el espacio libre y cuál Windows → NO ADIVINAR, PARAR
- Algo que no entiendo o que no esperaba ver → PARAR

En esos casos: tomar screenshot del instalador, volver a Windows si es necesario,
y consultar a una IA con la imagen antes de continuar.
Ese es el momento donde más ayuda puede dar una IA con contexto visual.

---

### FASE FUTURA: Eliminar Windows y quedarse full Arch

Esto NO es para ahora. Es para cuando Arch me convenza después de unas semanas.
Documentar en `docs/expand-arch.md` con pasos completos:

**Paso 1 — Pasar archivos de Windows a Arch sin hardware extra**

Desde Arch, montar la partición NTFS de Windows directamente:
```bash
# Identificar qué partición es Windows C:
lsblk -f
# Buscar la de tipo ntfs que sea la grande

# Montar
sudo mkdir -p /mnt/windows
sudo mount -t ntfs3 /dev/sdaX /mnt/windows   # reemplazar X con el número correcto

# Copiar lo que necesito
cp -r "/mnt/windows/Users/MiUsuario/Documents" ~/Documents
cp -r "/mnt/windows/Users/MiUsuario/Desktop" ~/Desktop
# mis proyectos de dev, fotos, etc.

# Desmontar al terminar
sudo umount /mnt/windows
```

**Paso 2 — Borrar la partición de Windows desde gparted**
```bash
sudo pacman -S gparted
# Abrir gparted, seleccionar la partición de Windows C:, eliminar
# Más seguro hacerlo visualmente que con parted en terminal
```

**Paso 3 — Expandir Arch al espacio liberado**
```bash
sudo parted /dev/sda resizepart 3 100%   # número de la partición de Arch
sudo resize2fs /dev/sda3                  # expandir el filesystem ext4
```

**Paso 4 — Actualizar GRUB para quitar la opción de Windows**
```bash
# En /etc/default/grub comentar o quitar: GRUB_DISABLE_OS_PROBER=false
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 🧱 Stack elegido — no cambiar

| Componente | Paquete | Fuente |
|---|---|---|
| Window Manager | `hyprland` | pacman |
| Shell UI | `caelestia-shell` | AUR |
| Shell CLI | `caelestia-cli` | AUR |
| AUR Helper | `yay` | AUR bootstrap |
| Audio | `pipewire` + `wireplumber` + `pipewire-pulse` | pacman |
| Red | `networkmanager` | pacman |
| Terminal | `foot` | pacman |
| Archivos | `thunar` | pacman |
| Audio GUI | `pavucontrol` | pacman |
| Shell | `fish` | pacman |
| Bluetooth | `bluez` + `bluez-utils` | pacman |
| Fuentes | `ttf-material-symbols-variable-git`, `caskaydia-cove-nerd`, `ttf-rubik` | AUR |
| Capturas | `swappy`, `grim`, `slurp` | pacman/AUR |
| Bootloader | `grub` + `os-prober` | pacman |

**Repo caelestia-shell:** https://github.com/caelestia-dots/shell
**Repo dots completo:** https://github.com/caelestia-dots/caelestia
Leer ambos READMEs antes de escribir cualquier script.

---

## 📁 Estructura del repo

```
arch-setup/
├── README.md
├── CONTEXT.md                   ← para pegarle a una IA después del install
├── install/
│   ├── 1-archinstall-guide.md  ← guía visual paso a paso de archinstall
│   ├── 2-post-install.sh       ← instala todo el stack post-arch
│   └── 3-caelestia-setup.sh    ← instala caelestia si no se hizo vía AUR
├── config/
│   └── shell.json              ← config de caelestia basada en el README oficial
├── wallpapers/
│   └── .gitkeep
└── docs/
    ├── dual-boot.md            ← convivir con Windows, GRUB, montar NTFS
    ├── expand-arch.md          ← cómo eliminar Windows cuando llegue el momento
    ├── wifi-fix.md             ← fix Realtek y alternativas sin WiFi
    └── known-issues.md         ← problemas conocidos del IdeaPad 330 con Arch
```

---

## 📜 `2-post-install.sh` — orden de operaciones

1. Verificar que corre como usuario normal (no root)
2. Verificar internet (`ping archlinux.org -c 1`)
3. Actualizar sistema: `sudo pacman -Syu`
4. Instalar `git` y `base-devel`
5. Instalar `yay` clonando desde AUR + `makepkg -si`
6. Instalar todos los paquetes pacman del stack
7. Instalar paquetes AUR: caelestia-shell, caelestia-cli, fuentes
8. Habilitar servicios: NetworkManager, bluetooth, pipewire
9. Instalar `nvm` + Node.js LTS (para Next.js y Elm)
10. Preguntar si instalar VS Code (`visual-studio-code-bin`) — opcional
11. Copiar `config/shell.json` a `~/.config/caelestia/shell.json`
12. Crear `~/Pictures/Wallpapers` y `~/dev`
13. Cambiar shell por defecto a fish
14. Imprimir resumen final: cómo arrancar caelestia

---

## 🔧 Dev setup — contexto para el script

- Trabajo con Next.js y Elm principalmente
- En Windows `npm run dev` tardaba mucho por NTFS + antivirus escaneando node_modules
- En Arch espero mejora significativa — ese es uno de los motivos del cambio
- Necesito `nvm` para manejar versiones de Node, no instalar Node directo con pacman
- VS Code como editor principal (`visual-studio-code-bin` desde AUR) — ponerlo como opcional
- Carpeta de proyectos: `~/dev/` — crearla en el script

---

## 🗒️ CONTEXT.md — qué debe contener

Archivo para pegarle a cualquier IA después de instalar:
- Hardware completo con chip de WiFi exacto
- Stack instalado
- URLs de repos usados como base
- Rutas importantes del sistema
- Comandos de caelestia más usados (`caelestia wallpaper`, `caelestia scheme set`, etc.)
- Estado del dual boot: qué partición es qué (`lsblk -f` output)
- Cómo actualizar: solo `yay`
- Problemas conocidos del IdeaPad 330

---

## ✅ Reglas para Claude Code

1. Leer READMEs de caelestia-shell y caelestia antes de escribir nada
2. No reinventar lo que caelestia ya hace — referenciarlo
3. Scripts idempotentes: que puedan correrse 2 veces sin romper nada
4. Comentarios en español dentro de los scripts
5. NUNCA escribir código que toque particiones automáticamente
6. El repo debe funcionar legible y offline desde USB

---

## 🚫 Lo que NO quiero

- Waybar (caelestia usa Quickshell, no waybar)
- Rofi (caelestia tiene su propio launcher)
- Scripts que particionen o formateen automáticamente
- Drivers NVIDIA (es Intel/AMD integrado)
- systemd-boot (usar GRUB por el dual boot con Windows)

---

## 🏁 Listo cuando

- [ ] `git clone` + `bash install/2-post-install.sh` deja el sistema funcional
- [ ] caelestia-shell arranca con autostart al login
- [ ] CONTEXT.md tiene todo para debuggear con IA
- [ ] `1-archinstall-guide.md` es suficiente para instalar sin buscar nada en internet
- [ ] `docs/` cubre dual boot, WiFi, expand-arch y problemas del IdeaPad 330
- [ ] Todo subido a GitHub con README claro
