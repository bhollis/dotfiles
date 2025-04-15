hash -d d=~/Documents
hash -d stately=~/Documents/stately

if type "stately" > /dev/null; then
  source <(stately completion zsh)
fi
