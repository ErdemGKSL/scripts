# Erdem's base arch setup
sudo pacman -Syu
sudo pacman -S --needed base-devel git

sudo pacman -S --needed --noconfirm reflector
sudo reflector --country 'United Kingdom,Germany' --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syy

mkdir ~/Documents/git
cd ~/Documents/git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

yay -S --needed --noconfirm ttf-ms-win11-auto
yay -S --needed --noconfirm all-repository-fonts

wget -q -O chaotic-AUR-installer.bash https://raw.githubusercontent.com/SharafatKarim/chaotic-AUR-installer/main/install.bash && sudo bash chaotic-AUR-installer.bash && rm chaotic-AUR-installer.bash

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

# For nvidia driver
# sudo pacman -S --noconfirm --needed lib32-nvidia-utils
# For amd driver
# sudo pacman -S --noconfirm --needed lib32-vulkan-radeon lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau vulkan-radeon
