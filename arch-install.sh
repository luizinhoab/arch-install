# a instalacao e iniciada como sudo automaticamente

# define teclado abnt2
loadkeys br-abnt2

# aumenta fonte do terminal
setfont lat4-19

# altera lingua para instalacao
nano /etc/locale.gen
# descomentar en_US UTF-8 e ISO
# descomentar pt_BR UTF-8 e ISO
# ctrl+o, enter para salvar... ctrl+x para sair do nano
locale-gen
export LANG=pt_BR.UTF-8

# testa conexao (wired) com a Internet
ping -c 3 www.google.com

# mostrar discos e particoes
fdisk -l

# gerenciar particoes com cfdisk (outras opcoes na wiki do Arch)
cfdisk /dev/sdx
# GPT requer particao de boot...
# criar particao de boot com no minimo 2M, tipo BIOS LINUX / BOOT
# criar particao para swap (tipo "Linux swap") ideal do mesmo tamanho da RAM (ex: 8GB)
# criar outras particoes conforme desejo de uso (Linux filesystem, ext4)
# executar write

# exemplo de particionamento:
# /dev/sdx
# L /dev/sdx1 2M   bios boot
# L /dev/sdx2 8G   linux swap
# L /dev/sdx3 64G  linux filesystem (a formatar como ext4 para o "/")
# L /dev/sdx4 390G linux filesystem (a formatar como ext4 para a "/home")

# formatar particoes "Linux filesystem" (numeros ficticios, execute fdisk para rever os seus)
# nao formate a particao de boot para ext4 ou outra, o GRUB cuida disso
mkfs.ext4 /dev/sdx3
mkfs.ext4 /dev/sdx4

# formatar particao de swap e ligar
mkswap /dev/sdx2
swapon /dev/sdx2

# ver o layout do particionamento
lsblk /dev/sdx

# montar particoes
mount /dev/sdx3 /mnt
# criar pasta home e montar particao
mkdir /mnt/home
mount /dev/sdx4 /mnt/home

# ----------------- opcional
# nao e obrigatorio 
# mas recomendo otimizar os mirrors
# e otimizar o DNS (utilizando o do Google)
nano /etc/resolv.conf
# adicione "nameserver 8.8.8.8" antes de outros nameservers, sem aspas
# salve com ctrl+o, enter
nano /etc/pacman.d/mirrorlist
# ctrl+k para apagar mirrors que nao sejam brasileiros (sao mais ou menos 5 brasileiros)
# ctrl+o, enter para salvar
# saia do nano e caminhe para a pasta de mirrors
cd /etc/pacman.d/
# rankeie os mirrors brasileiors (quanto mais mirrors, mais lento)
rankmirrors mirrorlist
# caminhe de volta para a home (alias "~")
cd ~
# ------------------ fim-opcional

# instalar o sistema base
pacstrap /mnt base base-devel

# gerar o arquivo fstab (descritor de particoes)
genfstab -U -p /mnt >> /mnt/etc/fstab

# verificar se fstab foi gerado conforme dados do "lsblk"
# a particao de boot fica com path "none" mesmo
cat /mnt/etc/fstab

# logar na instalacao para definir inicializacao
arch-chroot /mnt

# agora, dentro da instalacao...
# alterar lingua novamente... observando um comando a mais
nano /etc/locale.gen
# descomentar en_US UTF-8 e ISO
# descomentar pt_BR UTF-8 e ISO
# ctrl+o, enter para salvar... ctrl+x para sair do nano
locale-gen
# criar arquivo de configuracao de lingua
echo LANG=pt_BR.UTF-8 > /etc/locale.conf
export LANG=pt_BR.UTF-8

# ----------------- opcional
# nao e obrigatorio 
# mas recomendo otimizar os mirrors
# e otimizar o DNS (utilizando o do Google)
nano /etc/resolv.conf
# adicione "nameserver 8.8.8.8" antes de outros nameservers, sem aspas
# salve com ctrl+o, enter
nano /etc/pacman.d/mirrorlist
# ctrl+k para apagar mirrors que nao sejam brasileiros (sao mais ou menos 5 brasileiros)
# ctrl+o, enter para salvar
# saia do nano e caminhe para a pasta de mirrors
cd /etc/pacman.d/
# rankeie os mirrors brasileiors (quanto mais mirrors, mais lento)
rankmirrors mirrorlist
# caminhe de volta para a home (alias "~")
cd ~
# ------------------ fim-opcional

# definir configuracoes de teclado para persistir entre sessoes
nano /etc/vconsole.conf
# KEYMAP="br-abnt2.map.gz"
# FONT=Lat2-Terminus16
# FONT_MAP=
# ctrl+o, enter, ctrl+x para salvar e sair do nano

# procurar fuso horario (existe fusos para o Brazil e Americas compativeis)
ls /usr/share/zoneinfo
# dou preferencia ao fuso de Sao Paulo
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# sincronizar o relogio de hardware com o sistema
hwclock --systohc --utc

# alguns tutoriais definem o servico de rede agora...
# eu prefiro usar o dhcpcd manualmente e depois instalar o NetworkManager
# que e compativel e habilita icones para o gnome 3
# ----------------- opcional (rede)
# WIRED
# execute ip link e veja qual sua rede ether
ip link
# normalmente e "eth0" (formato antigo) ou "enp3s0" (formato novo e meu caso)
systemctl enable dhcpcd@enp3s0.service
#
# WIRELESS
pacman -S wireless_tools wpa_supplicant wpa_actiond netcf dialog
systemctl enable net-auto-wireless.service
# ----------------- fim-opcional (rede)

# habilitar repositorio multi arquitetura (tipo o ia32 do Ubuntu)
nano /etc/pacman.conf
# descomente "[multilib]" e seus dados
# ctrl+x, yes, enter para salvar

# sincronizar multilib
pacman -Sy

# criar senha de root (opcional, recomendado... nao esqueca essa senha)
passwd

# criar usuario pessoal, substituindo "meulogin" pelo seu login desejado
useradd -m -g users -G wheel,storage,power -s /bin/bash meulogin

# alterar senha do login pessoal, substituindo "meulogin" pelo seu login desejado
passwd meulogin

# instalar sudo
pacman -S sudo

# editar as propriedades de sudo
EDITOR=nano visudo
# descomentar linha "%wheel ALL=(ALL) ALL"

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
grub-mkconfig -O /boot/grub/grub.cfg

# sair do arch-chroot
exit

# desmontar particoes
umount /mnt/home
umount /mnt

# reinicie e defina a unidade de instalacao como primeira opcao de boot, na sua BIOS
reboot

# o sistema devera bootar no terminal do arch ja instalado, sem gerenciador grafico
# realize o login

# mude o hostname, substituindo meuhostname pelo nome desejado
sudo hostnamectl set-hostname meuhostname

# conectar o computador com a Internet (caso nao tenha habilitado o dhcpcd ou wpa anteriormente)
# pode ser necessario usar sudo para o dhcpcd
dhcpcd
# ele demora alguns segundos (5 seg em media)
# teste a conexao
ping -c 3 www.google.com

# sincronizar e instalar mixer da alsa
pacman -Sy alsa-utils
# ajuste o som, se desejar
alsamixer

# instalar network manager compativel com Gnome 3 (applet adiciona controles)
sudo pacman -S networkmanager networkmanager-vpnc networkmanager-pptp networkmanager-openconnect network-manager-applet

# gosto de instalar o xf86-input-evdev e o xf86-input-libinput
# nao e o correto, mas na wiki cita os casos e nunca sei qual utilizar
# (parece que um serve ao novo "wayland" e nao e la muito estavel 
# se nenhum for escolhido agora, sera ao instalar o xorg / ambiente grafico
sudo pacman -S xf86-input-libinput xf86-input-evdev

# em alguma parte do processo seguinte ele pergunta pela
# lib libx264 ou libx264-10bit, sendo essa segunda de raro uso e dependente de arquitetura
# (ver wiki, comentarios aqui: https://www.reddit.com/r/archlinux/comments/30khba/libx264_vs_libx26410bit/)

# instalar xorg e ferramentas basicas
sudo pacman -S xorg-server xorg-init xorg-server-utils mesa ttf-dejavu samba smbclient gvfs gvfs-smb sshfs

# habilite o network manager, caso tenha instalado
systemctl enable NetworkManager

# verifique a wiki e instale driver de video adequado a sua GPU
# no meu caso e a nvidia
sudo pacman -S nvidia nvidia-libgl

# verifique a wiki e instale o seu ambiente grafico, no meu caso e o Gnome 3
# podemos instalar o gnome, todas suas apps, jogos e ferramentas (pacotes "gnome" e "gnome-extra")
# (sudo pacman -S gnome gnome-extra)
# eu escolhi instalar o basico...
sudo pacman -S gnome-shell nautilus gnome-terminal gnome-tweak-tool gnome-control-center xdg-user-dirs gdm

# ative o gdm
systemctl enable gdm

# reinicie
# o sistema devera exibir a tela de login do GDM
# em caso de erros, procure ler os logs do xorg e journalctl
# ou verifique problemas de drivers de sua GPU
# lembrando que e bom instalar os drivers de video antes do XOrg e Gnome para evitar 
# bindings ruins com mesa ou nouveau