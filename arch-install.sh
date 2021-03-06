#!/usr/bin/env bash
echo '#################################################################'
echo '#                                                               #'
echo '#                                                               #'
echo '#                  Install Script Arch Linux                    #'
echo '#                                                               #'
echo "#                                                               #"
echo '#################################################################'
echo
echo
echo 'Press Enter to continue or Ctrl + C to exit'
read key
clear
echo $(date +%d-%m-%Y--%H:%M:%S)
echo '##########################################'
echo '#                                        #'
echo '#              Pre Install               #'
echo '#                                        #'
echo '##########################################'

while getopts "k:l:L:" opt; do
  case $opt in
    k) keyboard="$OPTARG"
    echo $keyboard
    ;;
    l) language="$OPTARG"
    echo $language
    ;;
    L) locale="$OPTARG"
    echo $locale
    ;;
    \?) echo "Invalid parameter - $OPTARG" >&2
    ;;
  esac
done

keyboard="${keyboard:-br-abnt2}"
language="${language:-en_US.UTF-8}"
locale="${locale:-pt_BR.UTF-8}"

echo "Setup keyboard layout to $keyboard"
loadkeys $keyboard

echo "Setting installation locale to $locale"
count=$(fgrep -o $locale /etc/locale.gen | wc -l)

if [[ $count -eq 1 ]]; then

  #comment all uncommented lines
  sed -i '/^#/!s/^/#/g' /etc/locale.gen

  #uncomment choice locale
  sed -i "/^$locale/s/^#//g" /etc/locale.gen

  echo 'Generating locale files'
  locale-gen

else
  locale="pt_BR.UTF-8"
  echo "Locale not found. Default locale config will be used - $locale"

fi

echo "Setting language, $language, for current session"
export LANG=$language


while [[ true ]]; do

  echo 'Select a time zone to adjust the clock.'
  read -p 'Type a country, state or province to list related timezones, or "skip" to GMT 0: ' localtime

  if [[ $localtime == "skip" ]]; then
    timeZone="UTC"
    break
  fi

  if [[ -n $localtime ]]; then
    timedatectl list-timezones | grep $localtime
    if [[ $? -eq 1 ]]; then
      timedatectl list-timezones
    fi
  else
    timedatectl list-timezones
  fi

  read -p 'Type timezone of previous list (America/Vancouver):' tZ

  dirTZ="/usr/share/zoneinfo/$tZ"

  ls $dirTZ

  if [[ $? -eq 0 && -f "/usr/share/zoneinfo/$tZ" ]]; then
    timeZone=$tZ
    echo "The time zone $timeZone was selected"
    break
  else
    echo "Invalid timezone, $timeZone."
  fi


done

echo '########################'
echo '#     Pre Install      #'
echo '#   Internet Setup     #'
echo '########################'
echo
echo
echo 'The installation image enable the daemon dhcpd on wired devices initialization'

read -p "Is your network connection wired ? (Y or N)" yn
case $yn in
    [Yy]* ) echo 'Wired Connection';;
    [Nn]* )
      echo 'Verify whats your wireless interface'
      iwconfig
      read -p "Whats your wireless interface ?" interface
      echo $interface
      if [[ ! -z "$interface" ]]; then
        echo 'Setup your internet access.'
        wifi-menu $interface
      fi
    ;;
    * ) echo "Please answer Y for yes or N for no.";;
esac

echo 'Testing internet connection'
ping -c 3 8.8.8.8

if [[ $? -eq 1 ]]; then
  echo 'Internet connection not reached.'
  exit
else
  echo 'Internet connection reached.'
fi

echo
echo


echo
echo
echo '########################'
echo '#     Pre Install      #'
echo '#   Disk Management    #'
echo '########################'
echo
echo

echo 'This setup is based on GPT and EFI Systems'
echo 'Listing partitions'
fdisk -l
echo
while [[ true ]]; do

  echo 'If you need to create partitions,follow the next step with cfdisk'
  read -p 'Type your disk path to partitionate(/dev/sdx) or type "skip": ' disk
  diskCount=$(parted -l | grep $disk | wc -l)

  if [[ $disk == skip ]]; then
    break
  fi

  if [[ $diskCount -ge 1 ]]; then
    echo 'Partitioning example'
    echo
    echo '# /dev/sdx'
    echo 'Partition Size Type'
    echo '/dev/sdx1 512MiB EFI Systems'
    echo '/dev/sdx2 8GiB   linux swap'
    echo '/dev/sdx3 64GiB  linux filesystem (ext4 for the root"/")'
    echo '/dev/sdx4 390GiB linux filesystem (ext4 for the "/home")'

    cfdisk $disc
    break
  else
    echo 'Unknown disk. Please re-type.'
  fi
done

while [[ true ]]; do
  mnt='/mnt'
  read -p 'Type the boot EFI partition(/dev/sdx1): ' boot
  checkBoot=$(fdisk -l | grep $boot |wc -l)
  if [[ $checkBoot -ge 1 ]]; then
    echo 'Formatting boot partition.'
    mkfs.fat -F32 -n BOOT $boot
    break
  else
    echo 'Unknown partition. Please re-type.'
  fi
done


while [[ true ]]; do
  read -p 'Type the swap partition (/dev/sdx2) or type "skip" - Optional: ' swap
  checkSwap=$(fdisk -l | grep $swap |wc -l)

  if [[ $swap == skip ]]; then
    break
  fi

  if [[ $checkSwap  -ge 1 ]]; then
    echo 'Creating and activating boot partition.'
    mkswap $swap
    swapon $swap
    break
  else
    echo 'Unknown partition. Please re-type.'
  fi
done
echo
echo
echo 'Partitioning layout'
echo
lsblk $disc

while [[ true ]]; do
  read -p 'Type de root partition(/dev/sdx3): ' root
  checkRoot=$(fdisk -l | grep $root |wc -l)

  if [[ checkRoot -ge 1 ]]; then
    echo 'Ext4 formating of root partitionon.'
    mkfs.ext4 $root
    echo 'Mount root partition.'
    mount $root $mnt
    break
  else
    echo 'Unknown partition. Please re-type.'
  fi
done

while [[ true ]]; do
  read -p 'Type the home partition(/dev/sdx4) or type "skip"  - Optional: ' home
  checkHome=$(fdisk -l | grep $home |wc -l)
  if [[ $home == skip ]]; then
    break
  fi

  if [[ $checkHome -ge 1 ]]; then
    mkfs.ext4 $home
    mkdir $mnt/home
    mount $home $mnt/home
    break
   else
    echo 'Unknown partition. Please re-type.'
   fi
done

echo '##########################################'
echo '#                                        #'
echo '#              Installation              #'
echo '#                                        #'
echo '##########################################'
echo
echo
echo '########################'
echo '#   DNS & Mirror List  #'
echo '#      Definition      #'
echo '########################'
echo
echo

while [[ true ]]; do
  read -p 'Type IP for your preferential DNS, "Google" for Google dns or "skip" to next step: ' dns

  if [[ $dns == Google ]]; then
    dns=8.8.8.8
  fi

  if [[ $dns = skip ]]; then
    break
  fi

  ping -c 3 $dns
  if [[ $? -eq 0 ]]; then
    echo 'DNS reached.'
    sed -i "/domain Home/a \nameserver $dns" /etc/resolv.conf
    break
  else
    echo 'DNS not reached. Re-type the DNS.'
  fi
done

echo
echo 'Select your mirror for instalation, choice a mirror near you.'
echo 'Below the list of mirrors: '
sed -e '/Server/ d' -e '/Generated/ d' /etc/pacman.d/mirrorlist | sort | uniq

#comment all uncommented lines
sed -i '/^#/!s/^/#/g' /etc/pacman.d/mirrorlist
addedCountries=()

while [[ true ]]; do
  defaultMirror='Brazil'
  echo
  read -p 'Type any country listed for mirror or "skip" to Brazil like default: ' mirrorCountry

  if [[ $mirrorCountry == skip ]]; then
    echo 'The default mirror was added to list mirror.'
    sed -i "/$defaultMirror/ {n; s/^#//}" /etc/pacman.d/mirrorlist
    break
  else

    checkMirror=$(cat /etc/pacman.d/mirrorlist | grep $mirrorCountry | wc -l)
    echo "-->$checkMirror"
    if [[ checkMirror -ge 1 ]]; then
      echo "$addedCountries[@]"
      #uncoment mirror
      if [[ ! " ${addedCountries[@]} " =~ " ${mirrorCountry} " ]]; then

        echo "$checkMirror mirror(s) from $mirrorCountry added."
        sed -i "/$mirrorCountry/ {n; s/^#//}" /etc/pacman.d/mirrorlist
        addedCountries+=($mirrorCountry)

      else
        echo 'Country has benn already added.'
      fi

      read -p 'Press Enter to add new country for mirror, or type "skip" to exit.' op

      if [[ $op == 'skip' ]]; then
        break
      fi

    else
      echo 'Unknow country. Please re-type.'
    fi
  fi
  echo 'Added mirrors: '
  printf '%s\n' "${addedCountries[@]}"
done

#Delete comments
sed -i -e 's/#.*$//' -e '/^$/d' /etc/pacman.d/mirrorlist

echo 'Ranking mirrors'
rankmirrors /etc/pacman.d/mirrorlist

echo 'Populating and updating Arch GPG keys'
pacman -Sy --noconfirm archlinux-keyring
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

echo
echo 'Installing initial packages.'
pacstrap -i $mnt base base-devel wireless_tools wpa_supplicant wpa_actiond netcf dialog

echo
echo 'Generating partition descriptor'
genfstab -U -p $mnt >> $mnt/etc/fstab

echo 'Generated partition descriptor'
cat $mnt/etc/fstab

echo 'Changing root directory and initalizing the system setup.'

chmod 777 arch-setup.sh
mkdir $mnt/temp
cp arch-setup.sh $mnt/temp/arch-setup.sh
arch-chroot $mnt /bin/bash -c "chmod 777 /temp/arch-setup.sh; ./temp/arch-setup.sh -k $keyboard -l $locale -L $language -b $boot -t $timeZone"

echo "Unmount partitions and finalize installation."
umount $boot
umount $mnt
swapoff -a

echo 'Deleting installation temp files'
rm -rf $mnt/temp
read -p 'Rebooting system ..........'
reboot
