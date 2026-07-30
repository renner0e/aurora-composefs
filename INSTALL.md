# How to install a bootc image without an ISO

## Why does this guide exist

- Avoid dealing with ISO tooling yourself because it's not very good
- because you don't/can't/wan't to use `bootc switch`
- deal with current `bootc install-to-disk` shortcomings (fixed by https://github.com/bootc-dev/bootc/pull/2314)

## Prerequisites

- Experience with commandline/bash
- you read the guide in full to know what you are getting into
- Existing modern system with rootfull podman and systemd (that you may read this on)
OR
- Grab Aurora/Bazzite/CoreOS ISO, anything will do that you are comfortable navigating here

- an image you already built and published on a container registry/in containers-storage
- a spare disk you can **fully** use (no dual-boot!!!)

## Gotchas

This way of installing systems with `bootc install` has some UX papercuts.

A couple examples:

- Creating Users and logging in to the installed system is not handled (solved by plasma-setup/gnome-initial-setup)
- Flatpaks are not preinstalled (they are/should not be on the container image)
- Enrolling secureboot keys
- some special partitioning like BTRFS subvolumes (see repart.d)

So anything pretty much that is traditionally done as a "post-install script" on ISOs.

## Preparations

All the following commands require root privileges, use `sudo -i` or `run0` to get a root shell so you don't have to prefix everything with `sudo`.

## LiveISO path only

Boot the ISO, setup networking, keyboard layout...

Make sure that you have enough free space to pull the container image. If not, and if you have enough RAM, mount a tmpfs:

```
mount -t tmpfs -o size=10240M containers /var/lib/containers/storage/
chcon "system_u:object_r:container_var_lib_t:s0" /var/lib/containers/storage
```

## Pull your image

From here on your target system will be referenced as `$IMAGE`

For example:

```
IMAGE=quay.io/fedora-ostree-desktops/kinoite:44
```

```
podman pull $IMAGE
```

## Partition your disk with systemd repart

From here on your target disk will be references as `$DISK`

For example:

```
DISK=/dev/sdX
```

Use `lsblk` to find out what disk you need

Get repart config files:

```
git clone https://github.com/renner0e/aurora-composefs && cd aurora-composefs
```


Read every repart config, the current default values are
- a 2G /boot [same default as Fedora nowadays](https://fedoraproject.org/wiki/Changes/2GbootPartition)
- root with btrfs with no subvolumes (beware CentOS users!)

Example:

```
sdc                                     8:32   1 57.3G  0 disk
├─sdc1                                  8:33   1    1M  0 part
├─sdc2                                  8:34   1    2G  0 part
└─sdc3                                  8:35   1 55.3G  0 part
```

Actually partition the disk:

THIS COMMAND MAY BLOW AWAY YOUR DATA

```
systemd-repart --empty=force --definitions=repart.d/ostree-grub $DISK --dry-run=no --discard=no
```

## Mount created partitions

Example:

```
mount /dev/sdc3 /mnt/
mkdir -p /mnt/boot
mount /dev/sdc2 /mnt/boot/
mkdir -p /mnt/boot/efi
```

## Blast to disk

```
podman run --rm --privileged --pid=host --ipc=host \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers:/var/lib/containers -v /dev:/dev \
  -v /:/run/host \
  -e RUST_LOG=debug \
  $IMAGE \
  bootc install to-filesystem \
    --source-imgref=containers-storage:$IMAGE \
    --bootloader=grub --skip-finalize \
    /run/host/mnt/
```

## Unmount

umount -l -R /mnt


## User creation

Hammer into Esc key to get into grub

Press E on the top entry add and `init=/bin/bash` to the line that begins with linux

### SELinux shenanigans

```
mount -t selinuxfs selinuxfs /sys/fs/selinux
```

```
/sbin/load_policy
```

### Making a root user for initial setup 

```
passwd root
```

Now boot the system normally without

login to root user with your password you set

Now we actually create the user account

```
useradd -m username
```

Give it sudo privileges

```
usermod -aG wheel username
```


