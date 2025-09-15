# Erdem's base arch setup
sudo pacman -Syu
sudo pacman -S --needed base-devel git

# Regenerate mirrorlist
sudo pacman -S --needed --noconfirm reflector
sudo reflector --country 'United Kingdom,Germany' --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syy

# setup yay
mkdir ~/Documents/git
cd ~/Documents/git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

# install usefull fonts
yay -S --needed --noconfirm ttf-ms-win11-auto
sudo pacman -S all-repository-fonts

# install chaotic aur
wget -q -O chaotic-AUR-installer.bash https://raw.githubusercontent.com/SharafatKarim/chaotic-AUR-installer/main/install.bash && sudo bash chaotic-AUR-installer.bash && rm chaotic-AUR-installer.bash

# 32bit utility gpu modules, bc arch linux doesnt have it defaulitly (they are used to run 2d games or older games like portal 2 etc.)
if lspci -nn | grep -E "VGA|3D|Display" | grep -qi "10de:"; then
    echo "Detected NVIDIA GPU"
    sudo pacman -S --noconfirm --needed lib32-nvidia-utils
elif lspci -nn | grep -E "VGA|3D|Display" | grep -qi "1002:"; then
    echo "Detected AMD GPU"
    sudo pacman -S --noconfirm --needed \
        lib32-vulkan-radeon lib32-mesa-vdpau \
        libva-mesa-driver lib32-libva-mesa-driver \
        mesa-vdpau vulkan-radeon
else
    echo "No supported GPU detected, skipping..."
fi
