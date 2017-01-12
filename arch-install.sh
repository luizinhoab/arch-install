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
mkfs.ext4 /dev/sdx3
mkfs.ext4 /dev/sdx4

# formatar particao de swap e ligar
mkswap /dev/sdx2
swapon /dev/sdx2`


