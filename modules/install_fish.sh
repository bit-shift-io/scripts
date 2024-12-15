#!/bin/bash

# install fish shell
./util.sh -i fish
chsh -s $(which fish)


# install zsh shell
#./util.sh -i zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
#chsh -s $(which zsh)


echo "Complete"
