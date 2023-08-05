#!/bin/bash -eux

##
## zBox shell tuning
##


echo '> Installing zBox Shell...'

apt-get install -y \
  zsh
  
echo '> Installing oh-my-zsh...'  
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo 'alias ip="ip -c"' >> $HOME/.zshrc
echo 'alias ll="exa -l"' >> $HOME/.zshrc
echo 'alias la="exa -la"' >> $HOME/.zshrc
echo 'alias diff="colordiff"' >> $HOME/.zshrc

usermod --shell /bin/zsh root

echo '> Installing oh-my-posh...'  
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh

echo '> Installing posh themes...'  
mkdir $HOME/.poshthemes
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O $HOME/.poshthemes/themes.zip
unzip $HOME/.poshthemes/themes.zip -d $HOME/.poshthemes
chmod u+rw $HOME/.poshthemes/*.json
rm -vf $HOME/.poshthemes/themes.zip

# Set "af-magic" Console theme
sed -i 's/robbyrussell/af-magic/g' $HOME/.zshrc

# Set Fancy theme (SSH / Nerd Fonts)
echo '> zBox PoshTheme setup...'
echo 'export XDG_CACHE_HOME=$HOME/.cache' >> $HOME/.zshrc
mkdir -vp $HOME/.cache

# Only enable zbox theme on SSH, as it uses nerd fonts icons/symbols (https://www.nerdfonts.com).
echo 'if [[ -n $SSH_CONNECTION ]]; then' >> $HOME/.zshrc
echo '  eval "$(oh-my-posh --init --shell zsh --config $HOME/.poshthemes/zbox.omp.json)"' >> $HOME/.zshrc
echo 'fi' >> $HOME/.zshrc

echo '> Done'

