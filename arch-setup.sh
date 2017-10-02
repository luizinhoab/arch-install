echo '#################################################################'
echo '#                                                               #'
echo '#                                                               #'
echo '#                 Setup Script Arch Linux                       #'
echo '#                                                               #'
echo "#                                                               #"
echo '#################################################################'
echo
echo
echo '########################'
echo '#        Regional      #'
echo '#       Definitions    #'
echo '########################'
echo
echo
while getopts "k:l:L:b:" opt; do
  case $opt in
    k) keyboard="$OPTARG"
    echo "Keyboard -- $keyboard"
    ;;
    l) language="$OPTARG"
    echo "Language -- $language"
    ;;
    L) locale="$OPTARG"
    echo "Locale -- $locale"
    ;;
    b) boot="$OPTARG"
    echo "Boot Partition -- $boot"
    ;;
    \?) echo "Invalid parameter - $OPTARG" >&2
    ;;
  esac
done

keyboard="${keyboard:-br-abnt2}"
language="${language:-en_US.UTF-8}"
locale="${locale:-pt_BR.UTF-8}"

echo 'Setup locale definitions'
sed -i "/^$locale/s/^#//g" /etc/locale.gen
echo "Locale defined to $locale"
locale-gen
echo "Locale file generated."
echo
echo 'Language definitions'
echo LANG=$language > /etc/locale.conf
export LANG=$language
echo "$LANG was defined"
echo
echo 'Persiting keyboard setup.'
cat > /etc/vconsole.conf << EOF
KEYMAP=$keyboard.map.gz
FONT=Lat2-Terminus16
EOF
echo
cat /etc/vconsole.conf

echo
echo 'The next step will be choose the time zone.'

while [[ true ]]; do

  echo 'Select a time zone to adjust the clock.'
  read -p 'Type a country, state or province to list related timezones, or 'skip' to GMT 0: ' localtime

  if [[ $localtime == "skip" ]]; then
    timedatectl set-timezone UTC
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

  read -p 'Type timezone of previous list (America/Vancouver):' timeZone

  timedatectl set-timezone $timeZone

  if [[ $? -eq 0 ]]; then
    echo "$timeZone selected."
    break
  fi

done

echo
echo 'Adjustig time with hardware clock.'
hwclock --systohc --utc
echo
echo
echo '########################'
echo '#      Netowork &      #'
echo '#     Repositories     #'
echo '#        Config        #'
echo '########################'
echo
echo


echo 'Defining the host name e hosts file.'
read -p 'Type a name to the host: ' hostName
echo $hostname >> /etc/hostname
echo 'Generating the hosts file'
echo "127.0.0.1	localhost $hostName" >> /etc/hosts
echo "::1	localhost ip6-localhost ip6-loopback $hostName" >> /etc/hosts
echo "fe00::0 ip6-localnet" >> /etc/hosts
echo "fe00::0 ip6-mcastprefix" >> /etc/hosts
echo "ff02::1 ip6-allnodes" >> /etc/hosts
echo "ff02::2 ip6-allrouters" >> /etc/hosts
echo "ff02::3 ip6-allhosts" >> /etc/hosts


while [[ true ]]; do

  echo 'Below will be listed the network intefaces:'
  ip link

  #read -p 'Type wired interface name: ' wired
  #systemctl enable dhcpcd@$wired.service
  systemctl enable dhcpcd
  if [[ $? -eq 1 ]]; then
  echo 'An error ocurred while tried configure wired connection'
  fi

  echo 'Activing wireless network.'
  systemctl enable dhcpcd@enp3s0.service
  if [[ $? -eq 1 ]]; then
  echo 'An error ocurred while tried configure wireless connection'
  fi

  echo 'Testing Connection'
  ping -c 3 8.8.8.8

  if [[ $? -eq 0 ]]; then
    break
  else
    echo 'No internet connection reached.'
  fi
done

while [[ true ]]; do
  sed -i '/#Color/ s/#Color/Color \n ILoveCandy/' /etc/pacman.conf

  echo 'Type which repository you want to enable'
  read -p '(testing, comunity-testing, multilib, multilib-testing) or "skip"' repository

  if [[ $repository == "skip" ]]; then
    break
  fi

  sed -i "/\[$repository\]/, +1 s/^#//" /etc/pacman.conf
  echo 'Updating from repositories ...'
  pacman -Syy

  read -p "You wanna add another repository (Y/N) " addYn
  if [[ $addYn == 'N' ]]; then
    break
  fi
done


echo 'Installing yaour and synchronizing with AUR'
echo '[archlinuxfr]' >> /etc/pacman.conf
echo 'SigLevel = Never' >> /etc/pacman.conf
echo 'Server = http://repo.archlinux.fr/$arch' >> /etc/pacman.conf
sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm yaourt

read
echo
echo
echo '########################'
echo '#    Shell & Users     #'
echo '#        Config        #'
echo '########################'
echo
echo

echo 'Installing Git'
pacman -S --noconfirm git
echo
read -p 'Do you wanna use ZSH ? (Y/N) ' shYn
if [[ $shYn == "Y" ]]; then
  echo 'Installing ZSH ...'
  pacman -S --noconfirm zsh	zsh-completions

  echo 'Setup oh-my-zsh ...'
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh//g')"
  shellPath='/bin/zsh'

else
  shellPath='/bin/bash'
fi

while [[ true ]]; do
  read -p 'Do You wanna a password for super-user ? This is strongly recommended.(Y/N) ' suYn
  if [[ $suYn == "Y" ]]; then
    passwd
    if [[ $? -eq 0 ]]; then
      break
    fi
  fi
done

while [[ true ]]; do
  read -p 'Add new ADMIN user. Type the username or "skip"' admin
  if [[ $admin == 'skip' ]]; then
    break
  fi

  useradd -m -G wheel -s $shellPath $admin
  passwd $admin

  #gpasswd -a $admin locate
  #gpasswd -a $admin users
  #gpasswd -a $admin audio
  #gpasswd -a $admin video
  #gpasswd -a $admin daemon
  #gpasswd -a $admin dbus
  #gpasswd -a $admin disk
  #gpasswd -a $admin games
  #gpasswd -a $admin rfkill
  #gpasswd -a $admin lp
  #gpasswd -a $admin network
  #gpasswd -a $admin optical
  #gpasswd -a $admin power
  #gpasswd -a $admin scanner
  #gpasswd -a $admin storage

done

sed -i 's/\# \%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/g' /etc/sudoers

while [[ true ]]; do
  read -p 'Add new user to "users" groups. Type the username or "skip"' user
  if [[ $user == 'skip' ]]; then
    break
  fi

  useradd -m -g users -G audio -s $shellPath $user
  passwd $user

done

echo 'Listing processors ...'
grep --color "model name" /proc/cpuinfo
echo
echo
echo 'If you have a intel processor, generally is need intall the intel microcode.'
read -p 'Do you wanna install intel microcode ?(Y/N)' ynMicro

if [[ $ynMicro == 'Y' ]]; then
  pacman -S --noconfirm intel-ucode
fi

module='ext4'

while [[ true ]]; do
  read -p 'Select your video graphic card(intel, intel/nvidia, nvidia, amd): ' video
  case $video in
    intel ) pacman -S --noconfirm mesa lib32-mesa xf86-video-intel vulkan-intel
            pacman -S --noconfirm mesa-libgl
            pacman -S --noconfirm libva-intel-driver libva
            export LIBVA_DRIVER_NAME="i965"
            module+=" intel_agp i915"
            break
      ;;
    intel/nvidia )
            pacman -S --noconfirm intel-dri xf86-video-intel bumblebee nvidia
            pacman -S --noconfirm bbswitch
            pacman -S --noconfirm lib32-nvidia-utils
            pacman -S --noconfirm lib32-intel-dri
            pacman -S --noconfirm opencl-nvidia
            pacman -S --noconfirm lib32-virtualgl
            gpasswd -a $admin bumblebee
            systemctl status bumblebeed
            systemctl enable bumblebeed
            systemctl start bumblebeed

            glxspheres64
            optirun glxspheres64

            module+=" nouveau"
            break
      ;;
    nvidia ) sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
             export LIBVA_DRIVER_NAME="nvidia"
             module+=" nouveau"
             break
      ;;
    amd ) "Video configuration for $video, should be accomplished after installation."
          module+=" radeon/amdgpu"
          break
      ;;
  esac
done
echo 'Setting video modules for initramfs'
sed -i "/MODULES=\"\"/ s/MODULES=\"$modules\"/" /etc/mkinitcpio.conf

echo 'Installing audio drivers and libs'
pacman -S --noconfirm alsa-driver alsa-utils alsa-lib alsa-plugins
echo
echo

echo 'Installing system monitor battery.'
pacman -S --noconfirm acpi acpid
echo 'Enabling and starting service.'
systemctl enable acpid.service

echo 'Installing X Window System'
pacman -S --noconfirm xorg xorg-server-utils xorg-apps xorg-xinit xdg-user-dirs

echo 'Gnerate an update common directories'
xdg-user-dirs-update

echo 'Installing mouse, keyboard and touchpad managers.'
pacman -S --noconfirm xf86-input-libinput xf86-input-synaptics xf86-input-mouse xf86-input-keyboard

echo 'Regenerate initramfs image after graphic card configuration.'
mkinitcpio -p linux

read -p 'Do you wanna configure bootloader GRUB ?(Y/N)' ynGRUB

if [[ $ynGRUB == 'Y' ]]; then
  echo 'Installing os prober to check disks, if exists another OS.'
  pacman -S --noconfirm os-prober

  echo 'Configuring boot partition.'
  mkdir -p /boot/efi
  mount $boot /boot/efi

  echo 'Installing GRUB boot loader.'
  pacman -S --noconfirm grub-efi-x86_64 efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
  cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

  efibootmgr -c -g -d /dev/sdX -p Y -w -L "Arch Linux (GRUB)" -l '\\EFI\\arch_grub\\grubx64.efi'

  echo 'Installing os prober to check disks, if exists another OS.'
  pacman -S --noconfirm os-prober

  echo 'Generate GRUB config files.'
  grub-mkconfig -o /boot/grub/grub.cfg
fi

cp /etc/X11/xinit/xinitrc ~/.xinitrc

while [[ true ]]; do
  read -p "Select which desktop enviroment you want install or type 'skip': \n
           GNOME \n
           XFCE \n
           KDE \n
           LXDE -" deskEnv

  case $deskEnv in
    skip)
      break
      ;;
    GNOME)
      echo 'Installing Gnome'
      echo 'The GDM login manager will be installed by default.'
      pacman -S --noconfirm --force gnome gnome-extra
      systemctl enable gdm.service
      ln -svf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
      deskEnv='gnome-session'
      ;;
    XFCE )
      echo 'Installing XFCE'
      echo 'The XFWM login manager will be installed by default.'
      pacman -S --noconfirm --force xfce4 xfce4-goodies
      deskEnv='startxfce4'
      ;;
    KDE)
      echo 'The KDE has minimal installation option.'
      read -p "Do you wanna install minimal installation (Y or any other for Complete installation) ?" ynMin
      if [[ $yn == 'Y' ]]; then
        echo 'Minimal installation'
        pacman -S --noconfirm --force plasma-desktop sddm
      else
        echo 'Complete installation'
        pacman -S --noconfirm --force plasma-meta kde-applications-meta sddm
      fi

      echo 'The SDDM login manager will be installed by default.'
      system_ctl enable sddm.service
      sddm --example-config > /etc/sddm.conf

      deskEnv='startkde'
      ;;
    LXDE )
      echo 'Installing LXDE'
      echo 'The LXDM login manager will be installed by default.'
      pacman -S --noconfirm --force lxde lxde-common lxsession openbox
      systemctl enable lxdm.service
      deskEnv='startlxde'
      ;;
  esac
  echo "exec $deskEnv" >> ~/.xinitrc
  break
done

echo 'Instllation & Setup complete.'
read -p 'Rebooting your system.'
exit
