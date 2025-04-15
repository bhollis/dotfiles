# Homebrew on Mac
# HOMEBREW_PREFIX, HOMEBREW_CELLAR, adds to path
eval "$(/opt/homebrew/bin/brew shellenv)"

# Homebrew Golang
export GOPATH=$HOME/go
export GOROOT="${HOMEBREW_PREFIX}/opt/go/libexec"
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin

# Google Cloud SDK (gcloud) - brew install google-cloud-sdk
if [ -f "${HOMEBREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc" ]; then
    source "${HOMEBREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc"
fi
