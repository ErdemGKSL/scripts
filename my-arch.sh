# Erdem's base arch setup (im tired of it :')
sudo pacman -S --needed --noconfirm reflector
sudo reflector --country 'United States,Germany,Turkey' --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

yay -S --needed --noconfirm ttf-ms-win11-auto
yay -S --needed --noconfirm all-repository-fonts

# For nvidia driver
# sudo pacman -S --noconfirm --needed lib32-nvidia-utils
# For amd driver
# sudo pacman -S --noconfirm --needed lib32-vulkan-radeon lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau vulkan-radeon
