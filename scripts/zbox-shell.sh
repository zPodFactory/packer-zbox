#!/bin/bash -eux

##
## zBox shell tuning
##


echo '> Installing zBox Shell...'

apt-get install -y \
  zsh

usermod --shell /bin/zsh root

echo '> Installing oh-my-zsh...'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo '> Installing oh-my-posh...'
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh

echo '> Installing posh themes...'
mkdir -vp $HOME/.poshthemes
mkdir -vp $HOME/.cache

wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O $HOME/.poshthemes/themes.zip
unzip $HOME/.poshthemes/themes.zip -d $HOME/.poshthemes
chmod u+rw $HOME/.poshthemes/*.json
rm -vf $HOME/.poshthemes/themes.zip


# Set some zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting


# tmux tpm/plugins/catppuccin theme
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


# Add Zoxide (cd replacement)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | zsh -s -- --bin-dir=/usr/local/bin --man-dir=/usr/local/share/man

# Add Atuin for history (https://docs.atuin.sh/guide/installation/)
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

echo '. "$HOME/.atuin/bin/env"' >> $HOME/.zshenv


echo '> Done'

