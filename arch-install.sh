echo '#################################################################'
echo '#                                                               #'
echo '#                                                               #'
echo '#             Install Script Arch Linux 0.1.0a                  #'
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
      if [[ ! -z $interface ]]; then
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
    echo '/dev/sdx1 2M   EFI Systems'
    echo '/dev/sdx2 8G   linux swap'
    echo '/dev/sdx3 64G  linux filesystem (ext4 for the root"/")'
    echo '/dev/sdx4 390G linux filesystem (ext4 for the "/home")'

    cfdisk $disc
    break
  else
    echo 'Unknown disk. Please re-type.'
  fi
done

while [[ true ]]; do
  read -p 'Type the boot EFI partition(/dev/sdx1): ' boot
  checkBoot=$(fdisk -l | grep $boot |wc -l)
  if [[ $checkBoot -ge 1 ]]; then
    mkfs.fat -F32 $boot
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
    mkswap $swap
    swapon $swap
    break
  else
    echo 'Unknown partition. Please re-type.'
  fi
done
echo
echo
echo 'Particioning layout'
echo
lsblk $disc

while [[ true ]]; do
  read -p 'Type de root partition(/dev/sdx3): ' root
  checkRoot=$(fdisk -l | grep $root |wc -l)

  if [[ checkRoot -ge 1 ]]; then
    mkfs.ext4 $root
    mount $root /mnt
    break
  else
    echo 'Unknown partition. Please re-type.'
  fi
done

while [[ true ]]; do
  read -p 'Type de home partition(/dev/sdx4) or type "skip"  - Optional: ' home
  checkHome=$(fdisk -l | grep $home |wc -l)
  if [[ $home == skip ]]; then
    break
  fi

  if [[ $checkHome -ge 1 ]]; then
    mkfs.ext4 $home
    mkdir /mnt/home
    mount $home /mnt/home
    break
   else
    echo 'Unknown partition. Please re-type.'
   fi
done
# ----------------- opcional
# OTIMIZAR MIRRORS E DNS (melhora muito tempo de instalacao de pacotes)
# nao e obrigatorio mas recomendado
nano /etc/resolv.conf
# para utilizar o DNS do Google adicione "nameserver 8.8.8.8" antes de outros nameservers, sem aspas
# salve com ctrl+o, enter
nano /etc/pacman.d/mirrorlist
# ctrl+k para apagar mirrors que nao sejam brasileiros (sao mais ou menos 5 brasileiros)
# ctrl+o, enter para salvar
# saia do nano e caminhe para a pasta de mirrors
cd /etc/pacman.d/
# rankeie os mirrors brasileiros
# (exclua mirrors de paises longinquos. Quanto mais mirrors, mais demora o ranking)
rankmirrors mirrorlist
# walk de volta para a home (alias "~")
cd ~
# ------------------ fim-opcional

# INSTALAR SISTEMA BASE E BASE PARA FUNCOES ADICIONAIS
pacstrap /mnt base base-devel

# GERAR O FSTAB (descritor de particoes)
genfstab -U -p /mnt >> /mnt/etc/fstab

# verificar se fstab foi gerado conforme dados do "lsblk"
# a particao de boot fica com path "none" mesmo
cat /mnt/etc/fstab

# LOGAR NA INSTALACAO PARA DEFINIR INICIALIZACAO
arch-chroot /mnt

# agora, dentro da instalacao...
# ALTERAR LINGUA DA INSTALACAO... observando um comando a mais
nano /etc/locale.gen
# descomentar en_US UTF-8 e ISO
# descomentar pt_BR UTF-8 e ISO
# ctrl+o, enter para salvar... ctrl+x para sair do nano
locale-gen
# criar arquivo de configuracao de lingua
echo LANG=pt_BR.UTF-8 > /etc/locale.conf
export LANG=pt_BR.UTF-8

# DEFINIR CONFIGS DE TECLADO PARA PERSISTIR ENTRE SESSOES
nano /etc/vconsole.conf
# KEYMAP="br-abnt2.map.gz"
# FONT=Lat2-Terminus16
# FONT_MAP=
# ctrl+o, enter, ctrl+x para salvar e sair do nano

# DEFINIR HORA E FUSO
# procurar fuso horario (existe fusos para o Brazil e Americas compativeis)
ls /usr/share/zoneinfo
# dou preferencia ao fuso de Sao Paulo
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# sincronizar o relogio de hardware com o sistema
hwclock --systohc --utc

# CONFIGURAR REDE PARA USUARIOS
# alguns tutoriais definem o servico de rede agora...
# essa rede serve apenas para o live boot e não para a instalação final
# eu prefiro usar o dhcpcd manualmente e depois instalar o NetworkManager
# que e compativel e habilita icones para o gnome 3
# ----- opcional (rede do live boot para instalacao de dependencias)
# WIRED/ ETHERNET
# execute ip link e veja qual sua rede ether
ip link
# normalmente e "eth0" (formato antigo) ou "enp3s0" (formato novo e meu caso)
systemctl enable dhcpcd@enp3s0.service
#
# WIRELESS
pacman -S wireless_tools wpa_supplicant wpa_actiond netcf dialog
systemctl enable net-auto-wireless.service
# ----- fim-opcional (rede para instalacao)

# HABILITAR REPOSITORIO MULTI ARQUITETURA (tipo o ia32 do Ubuntu)
nano /etc/pacman.conf
# descomente "[multilib]" e seus dados
# descomente "Color" para ter cores
# insira "ILoveCandy" depois de "Color" para ativar o loading do Pac-Man
# ctrl+x, yes, enter para salvar

# sincronizar multilib
pacman -Sy


# CRIAR SENHA DO ROOT (opcional, recomendado... nao esqueca essa senha)
passwd

# CRIAR USUARIO PESSOAL, substituindo "meulogin" pelo seu login desejado
useradd -m -g users -G wheel,storage,power -s /bin/bash meulogin

# ALTERAR SENHA DO USUARIO PESSOAL, substituindo "meulogin" pelo seu login desejado
passwd meulogin

# INSTALAR SUDO (MUITO IMPORTANTE)
pacman -S sudo

# editar as propriedades de sudo
EDITOR=nano visudo
# descomentar linha "%wheel ALL=(ALL) ALL"

# instala o Intel microcode para processadores Intel
pacman -S intel-ucode

# INSTALAR GRUB BIOS
# Existe a opção de instalar o GRUB BIOS ou UEFI.
# Utilizaremos o GRUB BIOS.
# Ver Arch Wiki como instalar GRUB UEFI caso prefira/seja necessário para sua mobo...
# baixar e instalar o GRUB BIOS
pacman -S grub-bios
# target i386 e o padrao e serve para 64-bits tambem
# mais detalhes na wiki e google
# recorra a outros tutoriais para definir melhor este comando para arquiteturas especificas
# atencao para direcionar a instalacao para a raiz da unidade formatada no inicio do tutorial
# ja que seu pc pode ter diversas memorias secundarias (USB inclusive)
grub-install --target=i386-pc --recheck /dev/sdx
# nao sei exatamente o que a proxima linha faz, mas funciona :)
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# criar arquivo de configuracao do GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# sair do arch-chroot
exit

# desmontar particoes
umount /mnt/home
umount /mnt

# reinicie e defina a unidade de instalacao como primeira opcao de boot, na sua BIOS
reboot

# o sistema devera bootar no terminal do arch ja instalado, sem gerenciador grafico
# REALIZE LOGIN NO SISTEMA OPERACIONAL INSTALADO

# ALTERE O HOSTNAME, substituindo meuhostname pelo nome desejado
sudo hostnamectl set-hostname meuhostname

# CONECTAR COM A INTERNET (caso nao tenha habilitado o dhcpcd ou wpa anteriormente)
# pode ser necessario usar sudo para o dhcpcd
dhcpcd
# ele demora alguns segundos (5 seg em media)
# teste a conexao
ping -c 3 www.google.com


# -------- Configurar AUR
# adicionar AUR ao pacman
sudo nano /etc/pacman.conf
# adicione ao pacman.conf, proximo aos outros repositorios:
# --------------------------------------
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch
# --------------------------------------

# sincronize o pacman ao AUR e atualizar
sudo pacman -Syyu --noconfirm

# instalar yaourt
sudo pacman -S yaourt

# instalar o pacaur
# o pacaur e como o yaourt, com mais inteligencias e facilidades.
# compartilham as mesmas funcoes, locks e instalacoes ja que sao baseados no pacman
# adicione a chave para cower, dependencia do pacaur
# pena que ambos nao sao paralelos como o, ja depreciado, "bauer"
gpg --recv-key 1EB2638FF56C0C53
# instale o pacaur
yaourt -S pacaur


# ----- opcional
# instalar e utilizar powerpill como backend paralelo, no lugar do pacman
gpg --recv-keys 1D1F0DC78F173680
pacaur -S powerpill
# configure o .bashrc da home de usuario com o seguinte
export PACMAN=/usr/bin/powerpill
# essa variavel informa ao pacaur qual backend utilizar
# adicione tambem o SigLevel a todos os repositorios padrao do Arch (core, extra, community, multilib)
# para isso edite o pacman.conf
sudo nano /etc/pacman.conf
# ex:
[core]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist
# ----- fim-opcional


# sincronizar e instalar mixer da alsa
pacman -Sy alsa-utils
# ajuste o som, se desejar
alsamixer

# xf86-input-libinput é o default, mas existem inputs para synaptics, evdev and wacom (ver Arch Wiki)
# se nenhum for escolhido agora, deverá ser escolhido ao instalar o xorg / ambiente grafico
sudo pacman -S xf86-input-libinput

# INSTALAR DRIVER E TOOLS DA NVIDIA
# em alguma parte do processo seguinte existe uma decisão sobre
# lib libx264 ou libx264-10bit, sendo essa segunda de raro uso e dependente de arquitetura
# (ver wiki, comentarios aqui: https://www.reddit.com/r/archlinux/comments/30khba/libx264_vs_libx26410bit/)

# verifique a wiki e instale driver de video adequado à sua GPU
# no meu caso e a nvidia
# lembrando que e bom instalar os drivers de video antes do XOrg e Gnome para evitar
# bindings ruins com mesa ou nouveau
#sudo pacman -S nvidia nvidia-libgl lib32-nvidia-libgl nvidia-settings
sudo pacman -S nvidia-utils lib32-nvidia-utils nvidia-settings

# INSTALAR XORG, FONTES E FERRAMENTAS BASICAS
# force refaz alguns bindings por causa do driver NVIDIA
sudo pacman -S --force xorg-server \
                       xorg-xinit \
                       mesa \
                       ttf-dejavu \
                       samba \
                       smbclient \
                       gvfs \
                       gvfs-smb \
                       sshfs

# instalar network manager caso nao esteja utilizando dhcpcd ou wpa como servico (como citado no passo opcional de redes)
# network manager e compativel com Gnome 3 (applet adiciona controles)
sudo pacman -S networkmanager networkmanager-vpnc networkmanager-pptp networkmanager-openconnect network-manager-applet
# habilite o network manager, caso tenha instalado
sudo systemctl enable NetworkManager

# verifique a wiki e instale o seu ambiente grafico, no meu caso e o Gnome 3
# podemos instalar o gnome, todas suas apps, jogos e ferramentas (pacotes "gnome" e "gnome-extra")
# (sudo pacman -S gnome gnome-extra)
# eu escolhi instalar o basico...
# force refaz alguns bindings por causa do driver NVIDIA
sudo pacman -S --force gnome-shell \
                       gnome-keyring \
                       libsecret \
                       seahorse \
                       nautilus \
                       gnome-terminal \
                       gnome-tweak-tool \
                       gnome-control-center \
                       gnome-system-monitor \
                       gnome-disk-utility \
                       xdg-user-dirs \
                       gdm \
                       vinagre \
                       baobab \
                       polari \
                       eog \
                       gnome-characters \
                       gnome-logs\

# ATIVAR GDM (desktop manager)
sudo systemctl enable gdm

# reinicie
# o sistema devera exibir a tela de login do GDM
# em caso de erros, procure ler os logs do xorg e journalctl
# ou verifique problemas de drivers de sua GPU
# a wiki do Arch e uma das melhores entre comunidades Linux

# prepara dirs de usuarios (xinitrc e pastas de pictures, documentos, etc)
# talvez nao seja mais necessario no futuro (nem instalacao nem essa execucao)
xdg-user-dirs-update

# FIXME
# configurar teclado abnt2
# pode ser necessario executar como root (incerteza)
# visivel apenas reiniciar sessao XOrg
# nesse caso e "br abnt2" mesmo, sem hifen
localectl set-x11-keymap br abnt2

# configure um DNS bom pelo network manager
# existe uma limitacao de 3 nameservers no resolv.conf
# e bom usar 2 para ipv4 e um ipv6
# - gigadns: 189.38.95.95 / 2804:10:10::10
# - google DNS: 8.8.8.8 / 2001:4860:4860::8888
# sem isso o gnupg nao consegue achar keyservers em ISPs ruins

# popular pacman-key para uso futuro (opcional)
sudo mkdir -p /root/.gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux && sudo pacman-key --refresh-keys




# INSTALAR FERRAMENTAS COMUNS DE DESENVOLVIMENTO
# ele ja verifica o que baixar pelo pacman ou AUR, dando preferencia ao pacman
pacaur -S --noedit ttf-ms-fonts \
                   jdk \
                   git \
                   p7zip \
                   firefox \
                   vlc \
                   virtualbox \
                   skype \
                   google-chrome \
                   chrome-remote-desktop \
                   docker \
                   gitkraken \
                   plex-media-server \
                   gimp \
                   inkscape \
                   steam-native-runtime \
                   steam \
                   atom \
                   visual-studio-code \
                   playonlinux \
                   transmission-gtk \
                   openssh \
                   vim \
                   terminator \
                   spotify \
                   empathy \
                   slack-desktop \
                   libreoffice-fresh

# HABILITAR SERVICO DOCKER
sudo systemctl enable docker
sudo systemctl start docker
# Docker sem sudo
sudo gpasswd -a ${USER} docker
newgrp docker

# HABILITAR SERVICO PLEX MEDIA SERVER
sudo systemctl enable plexmediaserver.service
sudo systemctl start plexmediaserver.service

# (opcional) para evitar checks de seguranca e fazer o acesso ao HD mais rapido
# edite o fstab e substitua "relatime" por "noatime"
# (ref: https://wiki.archlinux.org/index.php/fstab#atime_options)
sudo nano /etc/fstab

# INFINALITY IS NOT REQUIRED ANYMORE. FREETYPE 2.7+ HAS HINTING
# (https://github.com/bohoomil/fontconfig-ultimate/issues/171)

# desativa windows key da esquerda, mudando para a direita ou nenhuma
gsettings set org.gnome.mutter overlay-key "Super_R"
# gsettings set org.gnome.mutter overlay-key ""

# -------------------------------------------------------------------------
# nao instale o pacote "preload", atrapalha mais do que ajuda em gaming PCs
# -------------------------------------------------------------------------

# EXTENSOES E TEMAS GNOME 3
# common Gnome extensions, status bar system usage monitor, tab change, audio device output changer
# use Gnome Tweak Tool to configure themes, cursors and extensions
pacaur -S --noedit gnome-shell-extensions \
                   gnome-shell-system-monitor-applet-git \
                   gnome-shell-extension-coverflow-alt-tab-git \
                   gnome-shell-extension-audio-output-switcher-git \
                   gtk-theme-arc-git \
                   arc-icon-theme \
                   elementary-icon-theme \
                   adapta-gtk-theme \
                   noto-fonts

# Define nautilus como default handler de diretorios e
# faz com que o "mostrar na pasta" do Chrome e outros apps funcione corretamente.
xdg-mime default nautilus.desktop inode/directory

# Permite que Google Chrome instale extensões do site Gnome
pacaur -S --noedit chrome-gnome-shell-git

# instalar NVM, Node.js e modulos globais mais utilizados
pacaur -S nvm
# Do source NVM functionality for Bash (or ZSH)
echo 'source /usr/share/nvm/init-nvm.sh' > .bashrc
# echo 'source /usr/share/nvm/init-nvm.sh' > .zshrc
nvm install stable
nvm use stable
npm i -g gulp grunt webpack electron pm2 express-generator nodemon

# Configurar Git para utilizar o Gnome Keyring (opcional e muito particular)
# depois de instalados gnome-keyring e libsecret
cd /usr/share/git/credential/gnome-keyring
sudo make
git config --global credential.helper /usr/lib/git-core/git-credential-gnome-keyring

# EOF
