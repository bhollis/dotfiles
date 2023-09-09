# Ben's Dotfiles

This is my personal dotfiles repository. It configures:

* ZSH, with a nice clean minimal prompt that still gets across info about your Git status. The prompt omits information that isn't special, such as your username (when you're you) and your hostname (when you're on the same host).
* Emacs, with a few customizations but mostly set up to host [Magit](https://magit.vc) for super fast Git management.
* All the homebrew & Mac apps I use.

Don't try to use this directly - instead, browse through it and see if there's anything you'd like for your own dotfiles. I've tried to comment everything nicely.

# Install

1. Clone this repo into `~`
2. Make sure your shell is `zsh`: `chsh -s /bin/zsh`
3. Install Homebrew:
    * `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
    * `eval "$(/opt/homebrew/bin/brew shellenv)"
4. `cd dotfiles`
3. Run `dotfiles/install`. You'll probably need to restart your machine after the first time and run it a few more times before it all takes.
