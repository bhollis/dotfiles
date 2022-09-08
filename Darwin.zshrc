# Mac customization
alias ls='ls -G -F' #color and slashes/stars

# VSCode, Homebrew on Mac
export PATH="${PATH+:$PATH}:/opt/homebrew/bin:/Applications/Visual Studio Code.app/Contents/Resources/app/bin";
eval "$(/opt/homebrew/bin/brew shellenv)"
