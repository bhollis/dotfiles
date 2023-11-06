# Homebrew on Mac
# HOMEBREW_PREFIX, HOMEBREW_CELLAR, adds to path
eval "$(/opt/homebrew/bin/brew shellenv)"

# Homebrew Golang
export GOPATH=$HOME/go
export GOROOT="${HOMEBREW_PREFIX}/opt/go/libexec"
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin

# Google Cloud SDK (gcloud) - brew install google-cloud-sdk
source "${HOMEBREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc"

# NVM - Node Version Manager
if [ -d "${HOMEBREW_PREFIX}/opt/nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "${HOMEBREW_PREFIX}/opt/nvm/nvm.sh" ] && \. "${HOMEBREW_PREFIX}/opt/nvm/nvm.sh"  # This loads nvm
fi

# Homebrew Ruby
export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin":$PATH
