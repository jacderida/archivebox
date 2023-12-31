# archivebox

Defines setup and configuration for my personal archive server, which is a physical machine.

## Install Arch Linux

This section will describe how to setup a new Arch installation from scratch, tailored to this particular machine.

We'll commence from being booted into the Arch live environment via a USB drive.

The archive server should have a wired connection, so no network configuration is necessary in the live environment.

First, set the keyboard layout and the system clock:
```
loadkeys uk
timedatectl set-ntp true
```

### Configure the Boot Disk

For some reason, the boot disk is designated `/dev/sdb` rather than `sda`.

If this drive had a previous installation, delete the three partitions:
```
fdisk /dev/sdb
# use 'd' to remove the three partitions
# use 'w' to write changes and exit
```

You can confirm the disk has no partitions by running `fdisk -l`.

Now, use `gdisk` to create three partitions for EFI, swap and root.

Create a 512MB EFI partition:
```
gdisk /dev/sdb
Command (? for help): o # create new empty partition table
Proceed? (Y/N): Y
Command (? for help): n # add a new EFI partition
Partition number (1-128, default 1): 1
First sector: (press Enter to accept default)
Last sector: +512M
Hex code or GUID: EF00 # code for the EFI type
```

Create a 4GB swap partition:
```
Command (? for help): n # add a new swap partition
Partition number (1-128, default 2): 2
First sector: (press Enter to accept default)
Last sector: +4GB
Hex code or GUID: 8200 # code for the swap type
```

Use the remaining space for the root partition:
```
Command (? for help): n # add a new swap partition
Partition number (1-128, default 3): 3
First sector: (press Enter to accept default)
Last sector: (press Enter to accept default)
Hex code or GUID: 8300 # code for Linux type
```

Now write the changes:
```
Command (? for help): w # write the changes to the partition table
Proceed? (Y/N): Y
```

You can use `fdisk -l` to see the new partitions.

Format the partitions with file systems:
```
mkfs.fat -F32 /dev/sdb1  # EFI partition
mkswap /dev/sdb2  # Swap partition
mkfs.ext4 /dev/sdb3  # Root partition
```

Enable with swap partition:
```
swapon /dev/sdb2
```

### Install the OS

Mount the EFI and root file systems:
```
mount /dev/sdb3 /mnt
mkdir /mnt/boot
mount /dev/sdb1 /mnt/boot
```

Install base packages:
```
pacstrap -K /mnt \
    base \              # minimal base: awk, bash, glibc, grep, pacman, systemd etc.
    base-devel \        # required for using AUR
    git \
    grub \              # required for setting up boot menu
    efibootmgr \        # also required for use with grub
    linux \             # the kernel package
    linux-firmware \    # for wireless networking drivers etc.
    man-db \
    man-pages \
    networkmanager \    # For wired networking after reboot
    sudo \
    texinfo \           # required for man pages
    vim
```

Generate the `fstab`:
```
genfstab -U /mnt >> /mnt/etc/fstab
```

Now switch to the new system and initially configure the host:
```
arch-chroot /mnt
curl -O -L https://raw.githubusercontent.com/jacderida/archivebox/main/config-host.sh
chmod +x config-host.sh
./config-host.sh
```

The `config-host.sh` sets up the region, locale and hostnames.

Configure grub:
```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

Set the root password using `passwd`.

Now you can exit the install and reboot:
```
exit
umount -R /mnt
reboot
```

## Post Installation Setup

When you reboot you should see an entry for your new Arch install in the boot menu. Select that entry and log in to your new install as the root user.

### Configure Networking

The networking service needs to be enabled and started:
```
systemctl enable NetworkManager
systemctl start NetworkManager
```

After this, log out and log back in again. Use `curl www.google.com` to confirm internet access.

### User Setup

Create a personal user account and give it root privileges:
```
useradd -m chris
passwd chris
EDITOR=vim visudo
chris ALL=(ALL) ALL # add at the bottom of the file
```

Now logout of the `root` account and login as `chris`.

Setup `yay` for use with the AUR:
```
git clone https://aur.archlinux.org/yay.git
mkdir ~/dev/aur.archlinux.org
cd ~/dev/aur.archlinux.org/yay
makepkg -si
```

Install `ghq` using `yay -S ghq`.

Use `ghq` to obtain my dotfiles:
```
export GHQ_ROOT=~/dev
ghq get https://github.com/jacderida/dotfiles.git
```

Install `stow` and link the dotfiles:
```
cd ~/dev/github.com/jacderida/dotfiles
sudo pacman -S stow
make links
```

### Enable Local SSH Access

Setup and configure the SSH daemon:
```
sudo pacman -Syu openssh
sudo systemctl start sshd.service
sudo systemctl enable sshd.service
```

This should allow you to SSH with password-based access.

Use `scp` to copy a public key and put it at `~/.ssh/authorized_keys`. Now disable password-based access:
```
sudo vim /etc/ssh/sshd_config
# search for this line
#PasswordAuthentication yes
# uncomment and change it to 'no'
PasswordAuthentication no

sudo systemctl restart sshd
```

Now you can also copy over a private key for use with Git and other systems.

At this point, you can log out of the shell on the physical machine and switch to using the server via SSH.

### Permanently Mount Music Drive

The music drive is at `/dev/sda`. Mount it and create an entry in `fstab`:
```
sudo mkdir /mnt/music
sudo mount /dev/sda1 /mnt/music
sudo chown chris:chris /mnt/music

sudo blkid # get the UUID of the drive
sudo vim /etc/fstab
# add an entry like this (obviously replace the UUID):
# /dev/sda1
UUID=4fd71154-4b48-4d1c-be71-e803060f0b58	/mnt/music	ext4		defaults	0 2
```

The disk mount should now persist between reboots.
