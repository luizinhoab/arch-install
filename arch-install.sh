# a instalacao e iniciada como sudo automaticamente

# define teclado abnt2
loadkeys br-abnt2

# aumenta fonte do terminal
setfont lat4-19

# altera lingua para instalacao
nano /etc/locale.gen
# descomentar en_US UTF-8 e ISO
# descomentar pt_BR UTF-8 e ISO

# verificar conexao (wired)
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