#!/bin/sh

set -e

# Usage: make_home_symlink path_to_file name_of_file_in_home_to_symlink_to
make_home_symlink() {
    if [ -z "$1" ]; then
        >&2 echo "make_home_symlink: missing first argument: path to file"
        exit 1
    fi

    THIS_DOTFILE_PATH="$PWD/$1"
    if [ -z "$2" ]; then
        HOME_DOTFILE_PATH="$HOME/$1"
    else
        HOME_DOTFILE_PATH="$HOME/$2"
    fi

    printf "Installing %s into %s" "$1" "$HOME_DOTFILE_PATH"

    if [ -L "$HOME_DOTFILE_PATH" ]; then
        echo " skipping, target is already a symlink"
        return
    fi

    if [ -f "$HOME_DOTFILE_PATH" ] && [ ! -L "$HOME_DOTFILE_PATH" ]; then
        printf " You already have a regular file at %s. Do you want to remove it? (y/n) " "$HOME_DOTFILE_PATH"
        read -r response
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            rm "$HOME_DOTFILE_PATH"
        else
            return
        fi
    fi

    ln -s "$THIS_DOTFILE_PATH" "$HOME_DOTFILE_PATH" 2>/dev/null
    echo " done!"
}

# Possible devices: desktop, laptop
DEVICE="${1:-desktop}"

echo "Install symlinks as device $DEVICE"

mkdir -p "$HOME/.config"

# zsh
## Create zsh config dir
mkdir -p "$HOME/.cache/zsh"

## Symlink our zsh dir into ~/.config
make_home_symlink ".config/zsh"

## Symlink our .zprofile file into ~/
make_home_symlink ".zprofile"

# vim
## Create vim config dir
mkdir -p "$HOME/.vim"

## Symlink our .vimrc into ~/.vim/vimrc
make_home_symlink ".vimrc" ".vim/vimrc"

# Bulk install various dotfiles
dotfiles=".vimrc .gitconfig .gvimrc .gvimrc4k .Xmodmap .gdbinit .tmux.conf"
for dotfile in $dotfiles; do
    make_home_symlink "$dotfile"
done

# Install aliases used by our shell
make_home_symlink ".config/aliasrc"

# Device-specific symlinks
make_home_symlink ".xinitrc-${DEVICE}" ".xinitrc"
make_home_symlink ".Xdefaults-${DEVICE}" ".Xdefaults"

mkdir -p ~/.vim/autoload ~/.vim/bundle ~/.vim/colors

if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    echo "Installing vim-plug..."
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if [ ! -d vim-pixelmuerto-fork ]; then
    echo "Cloning pajlada's fork of pixelmuerto's VIM theme"
    git clone https://github.com/pajlada/vim-pixelmuerto.git vim-pixelmuerto-fork
fi

cp vim-pixelmuerto-fork/colors/pixelmuerto.vim ~/.vim/colors/

make_home_symlink "i3-$DEVICE" .config/i3
make_home_symlink "i3status-$DEVICE" .config/i3status

if [ ! -f ~/.gitcredentials ]; then
    echo "To make your .gitconfig up-to-date again, you might need to type: git update-index --no-assume-unchanged .gitconfig"
    echo "Put your git 'credentials' in ~/.gitcredentials in the following format:"
    echo "[user]"
    echo "    name = Your Name"
    echo "    email = your@email.com"
    echo "Or set it with these commands"
    echo "Don't forget to set your personal git configs"
    echo "git config --file ~/.gitcredentials user.name \"Your Name\""
    echo "git config --file ~/.gitcredentials user.email \"your@email.com\""
fi
