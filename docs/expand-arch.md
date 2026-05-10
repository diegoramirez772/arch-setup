# Expandir Arch — Eliminar Windows cuando llegue el momento

Este paso es FUTURO. Solo cuando Arch funcione bien después de unas semanas de uso real.

---

## Paso 1 — Pasar archivos de Windows a Arch

Desde Arch, montar la partición NTFS de Windows:

```bash
# Identificar qué partición es Windows C:
lsblk -f
# Buscar la de tipo ntfs que sea la grande (~830GB)

# Montar
sudo mkdir -p /mnt/windows
sudo mount -t ntfs3 /dev/sda2 /mnt/windows   # ajustar número si es diferente

# Copiar lo que necesitás
cp -r "/mnt/windows/Users/TuUsuario/Documents" ~/Documents
cp -r "/mnt/windows/Users/TuUsuario/Desktop" ~/Desktop
cp -r "/mnt/windows/Users/TuUsuario/dev" ~/dev    # proyectos de código

# Desmontar al terminar
sudo umount /mnt/windows
```

---

## Paso 2 — Borrar la partición de Windows desde gparted

```bash
sudo pacman -S gparted
```

Abrir gparted visualmente, seleccionar la partición NTFS grande (~830GB) y eliminarla.
Más seguro hacerlo con interfaz gráfica que con parted en terminal.

También eliminar la partición de recuperación de Windows (~570MB) si ya no la necesitás.

---

## Paso 3 — Expandir Arch al espacio liberado

```bash
# Expandir la partición (ajustar número al de la partición de Arch)
sudo parted /dev/sda resizepart 4 100%

# Expandir el filesystem ext4 para usar el espacio nuevo
sudo resize2fs /dev/sda4
```

---

## Paso 4 — Actualizar GRUB para quitar Windows

```bash
# Editar /etc/default/grub
# Comentar o eliminar esta línea:
# GRUB_DISABLE_OS_PROBER=false

sudo grub-mkconfig -o /boot/grub/grub.cfg
# Reiniciar — GRUB ya no muestra Windows
```

---

## Verificar que todo quedó bien

```bash
lsblk -f          # ver el nuevo layout del disco
df -h             # ver espacio disponible en /
```
