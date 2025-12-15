#!/bin/bash

# fish shell
# yazi file manager
# niri tiling wm
# brightnessctl laptop display
./util.sh -i niri noctalia-shell

# fish niri yazi alaricitty brightnessctl

# dank material shell - noctalia is better
# curl -fsSL https://install.danklinux.com | sh


tee ~/.config/fish/config.fish > /dev/null << EOL
if status is-interactive
   # Commands to run in interactive sessions can go here
end

# Created by pipx on 2025-05-23 00:57:46
set PATH $PATH $HOME/.local/bin

# yazi exit in current dir
function y
   set tmp (mktemp -t "yazi-cwd.XXXXXX")
   yazi $argv --cwd-file="$tmp"
   if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
       builtin cd -- "$cwd"
   end
   rm -f -- "$tmp"
end
EOL

#echo "add the following to your ~./bashrc"
#echo 'eval "fish"'

echo "Complete"
