# Erdem's base arch setup (im tired of it :')
sudo pacman -S --noconfirm floorp-bin

sudo pacman -S --needed --noconfirm git base-devel

mkdir -p ~/Documents/git
mkdir -p ~/Downloads/my-arch

cd ~/Documents/git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

cd ~/

yay -S --noconfirm ttf-ms-win11-auto
yay -S --noconfirm ttf-twemoji

mkdir -p /etc/fonts/conf.d
curl -L -o /etc/fonts/conf.d/99-emoji.conf https://raw.githubusercontent.com/ErdemGKSL/my-arch/main/assets/99-emoji.conf
sudo fc-cache -fv

sudo pacman -S --noconfirm steam
yay -S --noconfirm sunroof-bin

sudo pacman -S --noconfirm --needed curl
sudo pacman -S --noconfirm dpkg

curl -L -o ~/Downloads/my-arch/resktop_1.5.4.deb https://github.com/Rivercord/Resktop/releases/download/v1.5.4/resktop_1.5.4_amd64.deb
sudo dpkg -i ~/Downloads/my-arch/resktop_1.5.4.deb

yay -S --noconfirm visual-studio-code-bin

sudo pacman -S --noconfirm jdk-openjdk
sudo pacman -S --noconfirm jdk17-openjdk
sudo pacman -S --noconfirm jdk11-openjdk

yay -S --noconfirm prismlauncher-bin
