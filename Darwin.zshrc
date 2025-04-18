# Mac customization
alias ls='ls -G -F' # color and slashes/stars

eval "$(/opt/homebrew/bin/brew shellenv)"

# Add completions. Should be called before compinit.
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

# Add "code" command to path
export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin";

# Homebrew java + jenv
if [ -d "${HOMEBREW_PREFIX}/Cellar/jenv" ]; then
    export PATH="$HOME/.jenv/shims:${PATH}"
    export JENV_SHELL=zsh
    export JENV_LOADED=1
    unset JAVA_HOME
    unset JDK_HOME
    source "${HOMEBREW_CELLAR}/jenv/0.5.5_2/libexec/libexec/../completions/jenv.zsh"
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

# Google Cloud SDK (gcloud) - brew install google-cloud-sdk
source "${HOMEBREW_PREFIX}/share/google-cloud-sdk/completion.zsh.inc"

# NVM - Node Version Manager
if [ -d "${HOMEBREW_PREFIX}/opt/nvm" ]; then
    [ -s "${HOMEBREW_PREFIX}/opt/nvm/etc/bash_completion.d/nvm" ] && \. "${HOMEBREW_PREFIX}/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
    export NVM_DIR="$HOME/.nvm"
    [ -s "${HOMEBREW_PREFIX}/opt/nvm/nvm.sh" ] && \. "${HOMEBREW_PREFIX}/opt/nvm/nvm.sh"  # This loads nvm
fi

# Ruby
# This goes here instead of zshenv because macos adds its own paths in front!
#export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin":$PATH
if type "rbenv" > /dev/null; then
    eval "$(rbenv init - zsh)"
fi

# mise-en-place
if type "mise" > /dev/null; then
    eval "$(mise activate zsh)"
fi
