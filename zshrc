# TODO: Warning (emacs): You appear to be setting environment variables in your .bashrc or .zshrc: those files are only read by interactive shells, so you should instead set environment variables in startup files like .bash_profile or .zshenv.  See the man page for your shell for more info.  In future, exec-path-from-shell will not read variables set in the wrong files.
# zsh startup

# source profile like .bashrc
if [ -f /etc/profile ]; then
  source /etc/profile
fi

##################### functions ######################################
fpath=( "$HOME/dotfiles/zfunctions" $fpath )

######################### zsh options ################################
setopt ALWAYS_TO_END           # Push that cursor on completions.
setopt AUTO_NAME_DIRS          # change directories  to variable names
setopt NO_BEEP                 # self explanatory
setopt NOTIFY                  # show bg job status immediately
setopt AUTO_CD                 # cd with just a directory name
setopt PUSHD_IGNORE_DUPS       # don't insert duplicates into pushd
setopt NO_AUTO_PUSHD           # don't push directories on cd
setopt CORRECT

######################### history options ############################
setopt EXTENDED_HISTORY        # store time in history
setopt HIST_EXPIRE_DUPS_FIRST  # unique events are more usefull to me
setopt HIST_VERIFY             # Make those history commands nice
setopt INC_APPEND_HISTORY      # immediatly insert history into history file
setopt SHARE_HISTORY           # share history among sessions
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
HISTSIZE=16000                 # spots for duplicates/uniques
SAVEHIST=15000                 # unique events guaranteed
HISTFILE=~/.history

######################### key bindings ###############################
bindkey -e    # emacs is better than VI
bindkey "^R" history-incremental-search-backward
bindkey "^E" end-of-line
bindkey "^A" beginning-of-line

# bind to ctrl-< and ctrl-> to move back and forth by word, just like
# in emacs
bindkey '^[[1;5C' emacs-forward-word
bindkey '^[[1;5D' emacs-backward-word
autoload -U select-word-style
select-word-style bash # Use bash style words that stop on path separators
# pushes current command on command stack and gives blank line, after that line runs command stack is popped
bindkey "^T" push-line-or-edit

######################## command aliases #############################
alias ls='ls --color=auto -F' #color and slashes/stars
alias grep='nocorrect grep --color=auto -s'
alias memusage='ps -e -orss=,args= | sort -b -k1,1n | pr -TW$COLUMNS'
alias br='bundle exec'
alias be='bundle exec'
alias diff='git diff --no-index'
# TODO: emacsclient? set as EDITOR/VISUAL? C-x C-# to finish
# This is a shell script in bin now
if [ ! -f ~/bin/ec ]; then
    alias ec='emacsclient -a "emacs -nw"' # open in existing emacs, wait for C-x C-#
fi
alias e='emacs -nw'
alias ack='/usr/local/bin/rg'
alias rg='/usr/local/bin/rg'
alias k='kubectl'

########################### prompt ###################################
source ~/dotfiles/spectrum.zsh # COLORS! Run spectrum_ls to see them, FG[int], BG[int] to use
# TODO: set ls colors and such using this

[[ $- = *i* ]] && source ~/dotfiles/prompt.zsh

###################### environment variables #########################
export LESS='-FRiX' # quit if one screen, color, case insensitive searching
export PAGER=less
export EDITOR='ec'
export PATH=~/bin:$PATH:/usr/local/share/npm/bin:~/.cargo/bin
export GTAGSLABEL='ctags'

#################### coloring matters ########################
# Color codes: 00;{30,31,32,33,34,35,36,37} and 01;{30,31,32,33,34,35,36,37}
# are actually just color palette items (1-16 in gnome-terminal profile)
# your pallette might be very different from color names given at (http://man.he.net/man1/ls)
# The same LS_COLORS is used for auto-completion via zstyle setting (in this file)
#
# TODO: kill this
export LS_COLORS_BOLD='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.tex=01;33:*.sxw=01;33:*.sxc=01;33:*.lyx=01;33:*.pdf=0;35:*.ps=00;36:*.asm=1;33:*.S=0;33:*.s=0;33:*.h=0;31:*.c=0;35:*.cxx=0;35:*.cc=0;35:*.C=0;35:*.o=1;30:*.am=1;33:*.py=0;34:'
export LS_COLORS_NORM='no=00:fi=00:di=00;34:ln=00;36:pi=40;33:so=00;35:do=00;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.deb=00;31:*.rpm=00;31:*.jar=00;31:*.jpg=00;35:*.jpeg=00;35:*.gif=00;35:*.bmp=00;35:*.pbm=00;35:*.pgm=00;35:*.ppm=00;35:*.tga=00;35:*.xbm=00;35:*.xpm=00;35:*.tif=00;35:*.tiff=00;35:*.png=00;35:*.mpg=00;35:*.mpeg=00;35:*.avi=00;35:*.fli=00;35:*.gl=00;35:*.dl=00;35:*.xcf=00;35:*.xwd=00;35:*.ogg=00;35:*.mp3=00;35:*.wav=00;35:*.tex=00;33:*.sxw=00;33:*.sxc=00;33:*.lyx=00;33:*.pdf=0;35:*.ps=00;36:*.asm=0;33:*.S=0;33:*.s=0;33:*.h=0;31:*.c=0;35:*.cxx=0;35:*.cc=0;35:*.C=0;35:*.o=0;30:*.am=0;33:*.py=0;34:'
export MY_LS_COLORS=${MY_LS_COLORS:-LS_COLORS_BOLD}
eval export LS_COLORS=\${$MY_LS_COLORS}
# something about this doesn't work - ls and tab-completion use different colors


######################## completion ##################################
# ignore these files in tab completion
FIGNORE=".o:~"

# Command completion for network commands
compctl -v setenv

# these are some (mostly) sane defaults, if you want your own settings, I
# recommend using compinstall to choose them.  See 'man zshcompsys' for more
# info about this stuff.

# The following lines were added by compinstall
zstyle ':completion:*' completer _expand _complete _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'r:|[._-]=** r:|=**' 'l:|=* r:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*' use-compctl true
# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

autoload -U compinit
compinit

####################### terminal/screen/tmux titles ##################
# if you are at a zsh prompt, make your screen title your current directory
case $TERM in
    xterm*)
        precmd () {print -Pn "\e]0;%m: %~\a"}
        ;;
esac

# if you are running a command, make your screen title the command you're
# running
case $TERM in
    xterm*)
        preexec(){
            local CMD=${1/% */}  # kill all text after and including the first space
            print -Pn "\e]0;$CMD@%m:%~\a"
          }
        ;;
esac

#################### load additional zshrc files #####################

# Load a platform-specific zshrc, such as .Darwin.zshrc
platform=`uname`
if [ -f ~/dotfiles/$platform.zshrc ]; then
    source ~/dotfiles/$platform.zshrc
fi

# Host-specific zshrc, such as .legion.zshrc
SHORTHOST=${HOST/\.local/}
if [ -f ~/dotfiles/$SHORTHOST.zshrc ]; then
    source ~/dotfiles/$SHORTHOST.zshrc
fi

# Uncommitted local zshrc
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

############################ rvm #####################################

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"  # This loads RVM into a shell session.

[[ $- = *i* ]] && prompt_on

# kubectl completions
if type "kubectl" > /dev/null; then
  source <(kubectl completion zsh)
fi
