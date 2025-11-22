require 'socket'
hostname = Socket.gethostname

# Is this my home laptop?
home = hostname.include? 'felwinter'
# Or my work laptop?
work = hostname.include? 'malahayati'

tap "d12frosted/emacs-plus"
tap "getsentry/tools" # Sentry.io tools
tap "homebrew/bundle"
tap "homebrew/services"
tap "homebrew/cask-fonts"

brew "mas" # Mac App Store CLI
brew "awscli"
brew "ruby" # TODO: Maybe RVM
brew "doctl" if home # DigitalOcean
brew "git"
brew "git-secrets"
brew "imagemagick"
brew "librsvg"
brew "nvm"
brew "corepack"
brew "ripgrep"
brew "shellcheck"
brew "d12frosted/emacs-plus/emacs-plus@29", args: ["with-nobu417-big-sur-icon"], restart_service: true, link: true
brew "getsentry/tools/sentry-cli"
brew "gh" # GitHub CLI
brew "kubectl"
brew "protobuf" if work
brew "rustup-init" if work # Run "rustup-init" after this
brew "golang" if work

cask "blender" if home
cask "google-cloud-sdk" if work
cask "ultimaker-cura" if home
cask "lycheeslicer" if home
cask "macdown"
cask "bettertouchtool"
cask "scroll-reverser"
cask "zoom"
cask "vivaldi"
cask "discord"
cask "spotify"
# cask "font-hack" # My old favorite coding font
cask "font-monaspace" # My new favorite coding font
cask "docker" # Docker Desktop for Mac - not sure what the formula is
cask "imageoptim"
cask "notion" if work
cask "qlmarkdown"
cask "qlvideo"

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
# Adblocking for Safari
mas "1Blocker", id: 1365531024
mas "Hush", id: 1544743900
