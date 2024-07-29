# Buildroot for QEMU and HS Development Kit

## Environment

```shell
git clone https://git.buildroot.net/buildroot buildroot
git clone -b arc64 https://github.com/foss-for-synopsys-dwc-arc-processors/buildroot buildroot-synopsys
```

## Writing an Image to micro-SD Card

Write `sdcard.img` to micro-SD card using `dd`:

```shell
sudo dd if=sdcard.img of=/dev/mmcblk0 bs=1M
```

## Building `vmlinux` instead of `uImage` for HS Development Kit

Set these options to build `vmlinux` instead of `uImage`:

```shell
# BR2_LINUX_KERNEL_UIMAGE=n
# BR2_ROOTFS_POST_IMAGE_SCRIPT=""
BR2_LINUX_KERNEL_VMLINUX=y
```

`overlay/etc/network/interfaces` makes HSDK to use a static
address `192.168.1.142` (set `BR2_SYSTEM_DHCP="eth0"` to
enable DHCP). Here is content of `~/.ssh/config` for connecting
to it through SSH:

```text
Host hsdk
    HostName            192.168.1.142
    Port                22
    User                root
    IdentityFile        ~/.ssh/keys/arc
```

Copy client side keys:

```shell
cp keys/* ~/.ssh/keys/
```

## Generating Keys

Overlay already contains pregenerated client side keys. You can generate your own keys:

```
$ mkdir -p ~/.ssh/keys
$ ssh-keygen -t rsa -C "arc@arc"
Generating public/private rsa key pair.
Enter file in which to save the key (/home/user/.ssh/id_rsa): /home/user/.ssh/keys/arc
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/user/.ssh/keys/arc
Your public key has been saved in /home/user/.ssh/keys/arc.pub
```

Add your public key to the overlay directory for all users:

```shell
mkdir -p overlay/hsdk/.ssh
cp -f ~/.ssh/keys/arc.pub common/overlay/root/.ssh/authorized_keys
cp -f ~/.ssh/keys/arc.pub common/overlay/home/user/.ssh/authorized_keys
```

Overlay already contains pregenerated host keys. However, you can generate your own keys:

```shell
ssh-keygen -A -f overlay
```

## Connecting to HS Development Kit

Now you can connect to the board this way:

1. Serial: `minicom -8 -b 115200 -D /dev/ttyUSB0 -s` (disable hardware flow control)
2. SSH: `ssh arc-hsdk-root`

## Enabling eBPF JIT

```shell
mount -t debugfs debugfs /sys/kernel/debug
sysctl net.core.bpf_jit_enable=1
```
