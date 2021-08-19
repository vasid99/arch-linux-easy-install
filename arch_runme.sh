#!/usr/bin/bash
# basically library includes
source arch_env
source arch_lib

# check if OS partition exists
if [ -n "$(part_exists $PART_ARCH)" ];then
	# check if OS partition is mounted
	# if not mounted, mount to the expected location 
	if [ -z "$(findmnt $PART_ARCH)" ];then
		echo OS partition not mounted, attempting to mount...
	# if mounted, remount since it may be mounted at some other location
	else
		echo OS partition already mounted, remounting...
		# EFI partition may be mounted alongside, so unmount it first
		if [[ (-n $PART_UEFI) && (-n "$(findmnt $PART_UEFI)") ]];then
			echo Unmounting EFI system partition...
			umount $PART_UEFI
		fi
		# perform the unmount
		umount $PART_ARCH
	fi
	# make directory to act as mount point
	mkdir -p $PART_ARCH_MNTPT
	# perform the mount
	mount "$PART_ARCH" "$PART_ARCH_MNTPT"
	echo Successfully mounted OS partition at $PART_ARCH_MNTPT
else
	echo Fatal error: OS partition $PART_ARCH not found. Either fix the environment file or create the partition. Exiting...
	exit	
fi
echo

# check if legacy boot partition is supposed to exist
if [ -n "$PART_LGCY" ];then
	# check if legacy boot partition exists
	if [ -z "$(part_exists $PART_LGCY)" ];then
		echo Fatal error: Legacy boot partition $PART_LGCY not found. Either fix the environment file or create the partition. Exiting...
		return
	fi
	
	# check if legacy boot partition is on the same physical disk as the (soon to be) OS partition
	if [[ ! ("$(get_disk $PART_LGCY)" = "$(get_disk $PART_ARCH)") ]];then
		echo Fatal error: Legacy and OS partitions cannot be on different disks. Exiting...
		return
	fi
	
	# check if legacy boot partition is of the type BIOS boot
	if [[ ! ("$(part_type $PART_LGCY)" = "BIOS boot") ]];then
		echo Fatal error: Legacy partition type is not BIOS boot. Exiting...
		return
	fi
	echo Legacy boot partition checks passed
	# convenience variable for boot check performed below
	bl=$bl"l"
else
	echo Warning: legacy boot partition not provided, will skip legacy boot setup
fi
echo

# check if  EFI system partition is supposed to exist
if [ -n "$PART_UEFI" ];then
	# check if EFI system partition exists
	if [ -z "$(part_exists $PART_UEFI)" ];then
		echo Fatal error: EFI system partition $PART_UEFI not found. Either fix the environment file or create the partition. Exiting...
		return
	fi
	
	# check if EFI system partition is of the type EFI System
	if [[ ! ("$(part_type $PART_UEFI)" = "EFI System") ]];then
		echo Fatal error: EFI system partition type is not EFI System. Exiting...
		return
	fi
	
	# mount EFI system partition
	echo Attempting to mount EFI system partition...
	ESP=$PART_ARCH_MNTPT$ESP_ARCH_CHROOT
	mkdir -p $ESP
	mount "$PART_UEFI" "$ESP"
	echo Successfully mounted EFI system partition at $ESP
	mkdir -p $ESP/EFI/GRUB
	
	# install efibootmgr package as well
	BASE_PACKAGES=$BASE_PACKAGES" efibootmgr"

	# convenience variable for boot check performed below
	bl=$bl"e"
else
	echo Warning: EFI system partition not provided, will skip UEFI boot setup
fi
echo

# warn user if no bootloader is configured
if [ -z "$bl" ];then
	echo "Warning: no bootloader (legacy/UEFI) has been specified"
	echo
fi

# Locale variable check (default locale in arch_env file)
if [ -z "$LOCALE" ];then
	echo Warning: locale has not been provided. Check /etc/locale.gen for available locales and specify your preferred one. If not provided, $LOCALE_DEFAULT will be installed by default.
	echo
fi

# time synchronization for package servers
echo Setting up time synchronization for package servers...
timedatectl set-ntp 1
echo

# strap operation
echo **Note: ensure that you are connected to the internet. Use the \"iwctl\" command to do so if not done already**
echo Pre-strap configuration done. Press any key to start strapping, or Ctrl+C to exit if you wish to make changes.
read -s -n 1
pacstrap $PART_ARCH_MNTPT $BASE_PACKAGES $EXTRA_PACKAGES
echo Strap complete. Press any key to start post-strap setup, or Ctrl+C to exit.
read -s -n 1

# perform post-strap setup
cp arch_env arch_lib arch_poststrap.sh $PART_ARCH_MNTPT/root
arch-chroot $PART_ARCH_MNTPT bash -c "source ~/arch_poststrap.sh"
rm $PART_ARCH_MNTPT/root/arch_* # create args list and do them individually, else spurious deletion may occur

# generate /etc/fstab for new system
genfstab -U $PART_ARCH_MNTPT >> $PART_ARCH_MNTPT/etc/fstab

# done!
if [ -n $PART_UEFI ];then
	umount $PART_UEFI
fi
umount $PART_ARCH
echo Installation complete! You may now reboot into your new system using the \"reboot\" command
