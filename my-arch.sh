# Erdem's base arch setup (im tired of it :')
sudo pacman -S --needed --noconfirm reflector
sudo reflector --country 'United States,Germany,Turkey' --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

sudo pacman -S --needed --noconfirm git base-devel

mkdir -p ~/Documents/git
mkdir -p ~/Downloads/my-arch

cd ~/Documents/git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

cd ~/

yay -S --needed --noconfirm zen-browser-bin
yay -S --needed --noconfirm ttf-ms-win11-auto
yay -S --needed --noconfirm all-repository-fonts
# yay -S --needed --noconfirm ttf-twemoji

mkdir -p /etc/fonts/conf.d
# curl -L -o /etc/fonts/conf.d/99-emoji.conf https://raw.githubusercontent.com/ErdemGKSL/my-arch/main/assets/99-emoji.conf
# curl -L -o /etc/fonts/local.conf https://raw.githubusercontent.com/ErdemGKSL/my-arch/main/assets/local.conf
sudo fc-cache -fv

sudo pacman -S --needed --noconfirm steam
yay -S --needed --noconfirm equibop-bin

sudo pacman -S --noconfirm --needed curl
# sudo pacman -S --noconfirm --needed dpkg

# curl -L -o ~/Downloads/my-arch/resktop_1.5.4.deb https://github.com/Rivercord/Resktop/releases/download/v1.5.4/resktop_1.5.4_amd64.deb
# sudo dpkg -i ~/Downloads/my-arch/resktop_1.5.4.deb

yay -S --noconfirm --needed visual-studio-code-bin
sudo pacman -S --noconfirm --needed zed

sudo pacman -S --noconfirm --needed jdk-openjdk jdk17-openjdk jdk11-openjdk

yay -S --noconfirm --needed prismlauncher-bin

# For nvidia driver
# sudo pacman -S --noconfirm --needed lib32-nvidia-utils
# For amd driver
# sudo pacman -S --noconfirm --needed lib32-vulkan-radeon lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau vulkan-radeon
