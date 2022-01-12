#!/bin/bash -eux

##
## zBox shell tuning
##


echo '> Installing zBox Shell...'

apt-get install -y \
  zsh
  
echo '> Installing oh-my-zsh...'  
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo 'alias ip="ip -c"' >> $HOME/.zshrc
echo 'alias ll="exa -l"' >> $HOME/.zshrc
echo 'alias la="exa -la"' >> $HOME/.zshrc
echo 'alias bat="batcat"' >> $HOME/.zshrc
echo 'alias cat="batcat"' >> $HOME/.zshrc
echo 'alias diff="colordiff"' >> $HOME/.zshrc

usermod --shell /bin/zsh root

echo '> Done'
