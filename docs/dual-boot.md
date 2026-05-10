# Dual Boot — Windows + Arch Linux

Guía completa para instalar Arch en paralelo con Windows sin borrar nada.

---

## Estado del disco antes de instalar

```
/dev/sda1  →  EFI (~500MB, vfat)       ← boot de Windows, compartir con Arch
/dev/sda2  →  Windows C: (~830GB ntfs) ← NO tocar
/dev/sda3  →  Recuperación (~570MB)    ← NO tocar
            →  Sin asignar (~100GB)    ← Arch va acá
```

---

## FASE 0 — Preparar Windows (ya hecho)

- [x] BitLocker desactivado (verificado)
- [x] Reducir C: y dejar 100GB sin asignar (hecho desde Administración de discos)
- [ ] Secure Boot: no aplicable (BIOS no lo soporta)

---

## FASE 1 — Bootear el USB de Arch

- USB grabado con Rufus en modo DD (no ISO mode)
- Al encender: presionar **F12** repetidamente para entrar al boot menu del IdeaPad 330
- Seleccionar el USB
- Elegir: **"Arch Linux install medium"** (primera opción)
- Verificar internet al cargar: `ping archlinux.org -c 3`
- Si el WiFi no funciona en la live ISO: ver `wifi-fix.md`
  - Alternativa inmediata: conectar el celular por USB y usar "Compartir internet" (USB tethering)

---

## FASE 2 — Particionado en archinstall

Cuando archinstall llegue a **"Disk configuration"**:

1. Elegir: **"Manual partitioning"**
2. Seleccionar `/dev/sda`
3. Identificar el bloque de ~100GB que dice "free space"

### Crear la partición de Arch

```
Tipo:              Linux filesystem
Filesystem:        ext4
Punto de montaje:  /
Tamaño:            todo el espacio libre disponible
Formatear:         SÍ
```

### Usar la EFI existente de Windows

```
Partición EFI:     la que ya existe (~500MB, tipo EFI)
Punto de montaje:  /boot/efi
Formatear:         NO ← si se formatea se rompe el boot de Windows
```

### Resultado final en archinstall

```
/dev/sda1  →  EFI existente  →  /boot/efi  →  NO formatear
/dev/sda2  →  Windows NTFS   →  (ninguno)  →  NO tocar
/dev/sda3  →  Recuperación   →  (ninguno)  →  NO tocar
/dev/sda4  →  nueva ext4     →  /          →  SÍ formatear
```

### Bootloader

Elegir **GRUB** — tiene detección automática de Windows via os-prober.
NO usar systemd-boot.

---

## FASE 3 — Primer arranque con dual boot

Al reiniciar aparece el menú de GRUB.

Si Windows no aparece automáticamente:

```bash
sudo pacman -S os-prober

# Editar /etc/default/grub
# Buscar y cambiar (o agregar) esta línea:
GRUB_DISABLE_OS_PROBER=false

sudo grub-mkconfig -o /boot/grub/grub.cfg
# Reiniciar — ahora aparecen ambos sistemas en GRUB
```

---

## Montar la partición de Windows desde Arch

Para acceder a archivos de Windows sin reiniciar:

```bash
lsblk -f                            # identificar cuál es la partición NTFS grande
sudo mkdir -p /mnt/windows
sudo mount -t ntfs3 /dev/sda2 /mnt/windows   # ajustar número si es diferente
ls /mnt/windows/Users/
sudo umount /mnt/windows            # desmontar al terminar
```

---

## Señales de PELIGRO — parar todo si aparece esto

- "Formatear /dev/sda1" (la EFI de Windows) → **PARAR**
- Opción de usar todo el disco en vez del espacio libre → **PARAR**
- No se distingue el espacio libre de las particiones de Windows → **NO ADIVINAR, PARAR**
- Algo inesperado que no entendés → tomar foto del instalador y consultar antes de continuar
