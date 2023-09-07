require 'socket'
hostname = Socket.gethostname

home = hostname.include? 'felwinter'

tap "d12frosted/emacs-plus"
tap "getsentry/tools"
tap "homebrew/bundle"
tap "homebrew/services"

brew "mas"
brew "awscli"
brew "ruby"
brew "doctl"
brew "ffmpeg"
brew "git"
brew "git-secrets"
brew "imagemagick"
brew "librsvg"
brew "node"
brew "ripgrep"
brew "shellcheck"
brew "yarn"
brew "d12frosted/emacs-plus/emacs-plus@29", args: ["with-nobu417-big-sur-icon"], restart_service: true, link: true
brew "getsentry/tools/sentry-cli"
brew "gh"

cask "blender" if home
cask "google-cloud-sdk"
cask "ultimaker-cura" if home
cask "lycheeslicer" if home
cask "macdown"
cask "bettertouchtool"
cask "scroll-reverser"
cask "zoom"

vscode "amodio.tsl-problem-matcher"
vscode "bierner.markdown-yaml-preamble"
vscode "dbaeumer.vscode-eslint"
vscode "eamodio.gitlens"
vscode "esbenp.prettier-vscode"
vscode "gamunu.vscode-yarn"
vscode "GitHub.remotehub"
vscode "github.vscode-github-actions"
vscode "GitHub.vscode-pull-request-github"
vscode "gwicksted.paste-escaped"
vscode "hiro-sun.vscode-emacs"
vscode "HTMLHint.vscode-htmlhint"
vscode "mrmlnc.vscode-apache"
vscode "ms-azuretools.vscode-docker"
vscode "ms-vscode.cpptools"
vscode "ms-vscode.remote-repositories"
vscode "ms-vscode.Theme-TomorrowKit"
vscode "Orta.vscode-jest"
vscode "redhat.vscode-yaml"
vscode "reduckted.vscode-gitweblinks"
vscode "stkb.rewrap"
vscode "streetsidesoftware.code-spell-checker"
vscode "stylelint.vscode-stylelint"
vscode "timonwong.shellcheck"

mas "Bitwarden", id: 1352778147
mas "Pixelmator", id: 407963104
mas "Xcode", id: 497799835
mas "Final Cut Pro", id: 424389933
mas "Affinity Designer", id: 824171161
mas "Slack", id: 803453959
mas "Tailscale", id: 1475387142
mas "The Unarchiver", id: 425424353
mas "1Blocker", id: 1365531024
mas "Hush", id: 1544743900
