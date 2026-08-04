# Aurora with composefs backend

## necessary changes

- add bootc to initramfs
- install systemd-boot (systemd-boot-unsigned for f44)

## Installation (with FDE)

Follow https://github.com/travier/fedora-atomic-desktops-sealed#testing-on-real-hardware

but you can stop after the bootc install command as we are not doing UKIs here

then set your actual FDE password with the usual `cryptsetup` flow

then modify `/boot/loader/entries/bootc_aurora-44-1.conf` and remove `root/rootflags` related things, it will use auto-detection.


## Cheat Sheet

Modify kernel commandline for things like `vconsole.keymap=de` (no bootc loader-entries for composefs)

```
mount -o remount,rw /boot

vim /boot/loader/entries/bootc_aurora-44-1.conf
```
