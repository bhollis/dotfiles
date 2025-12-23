require 'socket'
hostname = Socket.gethostname

# Is this my home laptop?
home = hostname.include?('felwinter')
# Or my stately laptop?
stately = !home && hostname.include?('malahayati')
# Or my Databricks laptop?
db = !home && hostname.include?('MHXV4MM664')

tap "d12frosted/emacs-plus"
tap "getsentry/tools" # Sentry.io tools

brew "mas" # Mac App Store CLI
brew "awscli"
brew "rvm" if home || stately # Ruby
brew "doctl" if home # DigitalOcean
brew "git"
brew "git-secrets"
brew "imagemagick"
brew "librsvg"
brew "nvm"
brew "corepack"
brew "ripgrep"
brew "fd"
brew "shellcheck"
brew "d12frosted/emacs-plus/emacs-plus@31", restart_service: true, link: true
brew "getsentry/tools/sentry-cli" if home || stately
brew "gh" # GitHub CLI
brew "kubectl"
brew "protobuf" if stately
# brew "rustup-init" if stately # Run "rustup-init" after this
brew "golang" if stately

cask "blender" if home
cask "google-cloud-sdk" if stately
cask "ultimaker-cura" if home
cask "lycheeslicer" if home
cask "macdown"
cask "bettertouchtool"
cask "scroll-reverser"
cask "zoom" if home || stately
cask "vivaldi" if home || stately
cask "discord" if home || stately
# cask "font-hack" # My old favorite coding font
cask "font-monaspace" # My new favorite coding font
cask "docker-desktop" # Docker Desktop for Mac - not sure what the formula is
cask "imageoptim"
cask "qlmarkdown"
cask "qlvideo"

if home || stately
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
end
