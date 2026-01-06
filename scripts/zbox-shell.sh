#!/bin/bash -eux

##
## zBox shell tuning
## Installs shell tools globally so all users get the same configuration
##

# Global installation paths
OMZ_DIR="/usr/share/oh-my-zsh"
POSH_THEMES_DIR="/usr/share/poshthemes"
TMUX_PLUGINS_DIR="/usr/share/tmux/plugins"

echo '> Installing zBox Shell...'

apt-get install -y zsh

# Set zsh as default shell for new users
sed -i 's|SHELL=/bin/sh|SHELL=/bin/zsh|' /etc/default/useradd
usermod --shell /bin/zsh root


echo '> Installing oh-my-zsh globally...'
# Install oh-my-zsh to global location
git clone https://github.com/ohmyzsh/ohmyzsh.git $OMZ_DIR

# Install zsh plugins globally
echo '> Installing zsh plugins...'
git clone https://github.com/zsh-users/zsh-autosuggestions $OMZ_DIR/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $OMZ_DIR/custom/plugins/zsh-syntax-highlighting


echo '> Installing oh-my-posh...'
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh


echo '> Installing posh themes globally...'
mkdir -vp $POSH_THEMES_DIR
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O /tmp/themes.zip
unzip /tmp/themes.zip -d $POSH_THEMES_DIR
chmod 644 $POSH_THEMES_DIR/*.json
rm -vf /tmp/themes.zip


echo '> Installing tmux plugins globally...'
mkdir -p $TMUX_PLUGINS_DIR/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git $TMUX_PLUGINS_DIR/catppuccin/tmux
git clone https://github.com/tmux-plugins/tpm $TMUX_PLUGINS_DIR/tpm


echo '> Installing zoxide...'
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | zsh -s -- --bin-dir=/usr/local/bin --man-dir=/usr/local/share/man


echo '> Installing atuin globally...'
# Install atuin binary to /usr/local/bin instead of per-user
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | ATUIN_NO_MODIFY_PATH=1 sh
# Move atuin binary to global location
mv $HOME/.atuin/bin/atuin /usr/local/bin/atuin
rm -rf $HOME/.atuin


echo '> Setting up /etc/skel for new users...'
# Create symlinks in /etc/skel so new users get the configuration
ln -s $OMZ_DIR /etc/skel/.oh-my-zsh
ln -s $POSH_THEMES_DIR /etc/skel/.poshthemes

# Create tmux plugin symlinks
mkdir -p /etc/skel/.config/tmux
ln -s $TMUX_PLUGINS_DIR /etc/skel/.config/tmux/plugins
mkdir -p /etc/skel/.tmux
ln -s $TMUX_PLUGINS_DIR /etc/skel/.tmux/plugins

# Create empty directories that users need
mkdir -p /etc/skel/.cache
mkdir -p /etc/skel/.ssh
chmod 700 /etc/skel/.ssh


echo '> Setting up root home directory...'
# Set up root's home with same symlinks
ln -sf $OMZ_DIR $HOME/.oh-my-zsh
ln -sf $POSH_THEMES_DIR $HOME/.poshthemes

mkdir -p $HOME/.config/tmux
ln -sf $TMUX_PLUGINS_DIR $HOME/.config/tmux/plugins
mkdir -p $HOME/.tmux
ln -sf $TMUX_PLUGINS_DIR $HOME/.tmux/plugins

mkdir -p $HOME/.cache
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh


echo '> Done'
