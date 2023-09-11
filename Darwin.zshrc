# Mac customization
alias ls='ls -G -F' # color and slashes/stars

# Add "code" command to path
export PATH="${PATH+:$PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin";

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
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
fi
