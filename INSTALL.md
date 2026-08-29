# How to install a bootc image without an ISO

## Why does this guide exist

- Avoid dealing with ISO tooling yourself because it's not very good
- because you don't/can't/wan't to install Fedora Silverblue/Bazzite and co first and rebase via `bootc switch`
- deal with current `bootc install-to-disk` shortcomings (fixed by https://github.com/bootc-dev/bootc/pull/2314)
- `bootc install-to-filesystem` requires knowing how to partition a drive and mount it properly
- manual user creation on a system with no user (that can be logged into, not even root) is not obvious

## Prerequisites and expectations

- you read the guide in full to know what you are getting into
- Experience with commandline/bash + dealing with containers/podman
- an image you already built and published on a container registry/or have in containers-storage
- a spare disk you can **fully** use (no dual-boot!!!) for the installed target system
- rootfull podman and systemd (a system that you may read this on right now)

If you decide to do it over the "liveiso route". You need one USB flash drive for the installation medium, i.e. where you flash Aurora/Bazzite/CoreOS ISO to, anything will do that you are comfortable navigating as long as it has podman and systemd.

## Gotchas

This way of installing systems with `bootc install` has some UX papercuts.

A couple examples:

- Creating Users and logging in to the installed system is not handled (solved by plasma-setup/gnome-initial-setup)
- Flatpaks are not preinstalled (they are/should not be on the container image) (can be a post-install thing with [flatpak preinstall](https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-preinstall))
- Enrolling secureboot keys
- some special partitioning like BTRFS subvolumes (see repart.d) directory in this repo (I guess this can be fixed, I just can't be bothered)
- kernel arguments ([although you can bake them into your image](https://bootc.dev/bootc/building/kernel-arguments.html))

So anything pretty much that is traditionally done as a "post-install script/in anaconda kickstart files" on ISOs.

## Preparations

All the following commands require root privileges, use `sudo -i` or `run0` to get a root shell so you don't have to prefix everything with `sudo`.

## LiveISO path only

Boot the ISO, setup networking, keyboard layout..., make yourself comfortable.

Make sure that you have enough free space to pull the container image. If not, and if you have enough RAM, mount a tmpfs:

```
mount -t tmpfs -o size=10240M containers /var/lib/containers/storage/
chcon "system_u:object_r:container_var_lib_t:s0" /var/lib/containers/storage
```

## Pull your image

From here on your target system will be referenced as `$IMAGE`

For example:

```
IMAGE=quay.io/fedora/fedora-bootc:latest
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
- 512MB /boot/efi
- a 2G /boot [same default as Fedora nowadays](https://fedoraproject.org/wiki/Changes/2GbootPartition)
- root with btrfs with no subvolumes (beware CentOS users!)

Example:

```
sdc                                     8:32   1 57.3G  0 disk
├─sdc1                                  8:33   1  512M  0 part
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

```
umount -l -R /mnt
```

## User creation (you don't have to care about any of this if you have plasma-setup/gnome-initial-setup and so on)

This is essentially 1:1 from [bazzite docs](https://docs.bazzite.gg/Advanced/Reset_Forgotten_User_Password/?h=password#reset-forgotten-user-password)

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

```
sync
```

```
/sbin/reboot -ff
```

Now boot the system normally without doing anything special.

login to root user with your password that you set earlier.

Now we actually create the user account

```
useradd -m username
```

Give it sudo privileges

```
usermod -aG wheel username
```
