# -*- mode: zsh -*-
# zsh environment vars

export PATH=~/bin:$PATH

# RVM - Ruby Version Manager
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"  # This loads RVM into a shell session.

# Cargo / Rust
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Use emacs when an editor is required
export EDITOR='ec'

#################### load additional zshenv files #####################

# Load a platform-specific zshenv, such as Darwin.zshenv
platform=`uname`
if [ -f ~/dotfiles/$platform.zshenv ]; then
    source ~/dotfiles/$platform.zshenv
fi

# Host-specific zshrc, such as legion.zshenv
SHORTHOST=${HOST/\.local/}
if [ -f ~/dotfiles/$SHORTHOST.zshenv ]; then
    source ~/dotfiles/$SHORTHOST.zshenv
fi

# Uncommitted local zshrc
if [ -f ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi


