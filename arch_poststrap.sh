#!/usr/bin/bash
source ~/arch_env
source ~/arch_lib

echo Requesting root password...
passwd
echo

echo Adding local timezone...
ln -sf $ZONEINFO /etc/localtime
echo

echo Syncing hardware clock...
hwclock --systohc
echo

echo "Generating locale(s)..."
if [ -z "$LOCALE" ];then
	LOCALE=$LOCALE_DEFAULT
fi
sed -i "s@#$LOCALE@$LOCALE@" /etc/locale.gen
locale-gen
echo

echo "Generating bootloader(s)..."
if [ -n "$PART_LGCY" ];then
	grub-install $(get_disk $PART_LGCY)
	grub-mkconfig -o /boot/grub/grub.cfg
	echo "Legacy bootloader generated"
fi
if [ -n "$PART_UEFI" ];then
	grub-install --target=x86_64-efi --efi-directory=$ESP_ARCH_CHROOT --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg
	echo "UEFI bootloader generated"
fi
echo

echo Configuring network and resolver daemons...
NETCONFDIR="/etc/systemd/network"
echo -e "[Match]\nName=eth0\n\n[Network]\nDHCP=yes" > $NETCONFDIR"/20-wired.network"
echo -e "[Match]\nName=enp1s0\n\n[Network]\nDHCP=yes" > $NETCONFDIR"/21-wired.network"
echo -e "[Match]\nName=wlan0\n\n[Network]\nDHCP=yes" > $NETCONFDIR"/25-wireless.network"
echo -e "[Match]\nName=wlp2s0\n\n[Network]\nDHCP=yes" > $NETCONFDIR"/26-wireless.network"

if [ -z "$(grep -v ^# /etc/resolv.conf)" ];then
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi
echo

echo Setting hostname as $HOSTNAME...
echo $HOSTNAME > /etc/hostname
if [ -z "$(grep -v ^# /etc/hosts)" ];then
	echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost" >> /etc/hosts
fi
echo

echo Setting up basic user $USERNAME...
useradd -m -G wheel $USERNAME
echo Requesting new user password...
passwd $USERNAME

chmod u+w /etc/sudoers
sed -i "s@# \(%wheel ALL=(ALL) ALL\)@\1@" /etc/sudoers
chmod u-w /etc/sudoers
echo
