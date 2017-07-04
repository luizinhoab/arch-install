echo '#################################################################'
echo '#                                                               #'
echo '#                                                               #'
echo '#             Setup Script Arch Linux 0.0.1a                    #'
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

  echo 'Need select a region and subregion.'
  echo 'Below a list of regions:'
  echo
  ls -d -A1 /usr/share/zoneinfo/*/ | awk -F"/" '{print $5}'
  read -p 'Type a region :' region
  echo 'Below a list of subregions:'
  ls -ds -A1 /usr/share/zoneinfo/$region/*/ | awk -F"/" '{print $6}'
  read -p 'Type a subregion :' subregion

  cd /usr/share/zoneinfo/$region/$subregion

  if [[ $? -eq 0 ]]; then
    ln -sf /usr/share/zoneinfo/$region/$subregion /etc/localtime
    break
  else
    echo 'Invalid region or subregion.'
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

  read -p 'Type wired interface name: ' wired
  systemctl enable dhcpcd@$wired.service
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
sudo pacman -S yaourt


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
read -p 'Do you wanna install and use ZSH ? (Y/N) ' shYn
if [[ $shYn == "Y" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  shellPath='/bin/zsh'
else
  shellPath = '/bin/bash'
fi

read -p 'Do You wanna a password for super-user ? This is strongly recommended.(Y/N) ' suYn
if [[ $suYn == "Y" ]]; then
  passwd
fi

while [[ true ]]; do
  read -p 'Add new ADMIN user. Type the username or "skip"' admin
  if [[ $admin == 'skip' ]]; then
    break
  fi

  useradd -m -G wheel -s $shellPath $admin
  passwd $admin

  gpasswd -a $admin locate
  gpasswd -a $admin users
  gpasswd -a $admin audio
  gpasswd -a $admin video
  gpasswd -a $admin daemon
  gpasswd -a $admin dbus
  gpasswd -a $admin disk
  gpasswd -a $admin games
  gpasswd -a $admin rfkill
  gpasswd -a $admin lp
  gpasswd -a $admin network
  gpasswd -a $admin optical
  gpasswd -a $admin power
  gpasswd -a $admin scanner
  gpasswd -a $admin storage

done

while [[ true ]]; do
  read -p 'Add new user to "users" groups. Type the username or "skip"' user
  if [[ $user == 'skip' ]]; then
    break
  fi

  useradd -m -G users -s $shellPath $user
  passwd $user

done
