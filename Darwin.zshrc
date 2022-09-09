# Mac customization
alias ls='ls -G -F' #color and slashes/stars

# VSCode, Homebrew on Mac
export PATH="${PATH+:$PATH}:/opt/homebrew/bin:/Applications/Visual Studio Code.app/Contents/Resources/app/bin";
eval "$(/opt/homebrew/bin/brew shellenv)"

# Homebrew Golang
export GOPATH=$HOME/go
if [ -d "$HOME/Snapchat/dev" ]; then
    export GOPATH=$HOME/Snapchat/dev/go
fi
export GOROOT=/opt/homebrew/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# Homebrew java + jenv
if [ -d /opt/homebrew/Cellar/jenv ]; then
    export PATH="$HOME/.jenv/shims:${PATH}"
    export JENV_SHELL=zsh
    export JENV_LOADED=1
    unset JAVA_HOME
    unset JDK_HOME
    source '/opt/homebrew/Cellar/jenv/0.5.5_2/libexec/libexec/../completions/jenv.zsh'
    jenv rehash 2>/dev/null
    jenv refresh-plugins
    jenv() {
        type typeset &> /dev/null && typeset command
        command="$1"
        if [ "$#" -gt 0 ]; then
            shift
        fi

        case "$command" in
            enable-plugin|rehash|shell|shell-options)
                eval `jenv "sh-$command" "$@"`;;
            *)
                command jenv "$command" "$@";;
        esac
    }
fi
