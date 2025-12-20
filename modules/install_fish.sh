#!/bin/bash

# install fish shell
./util.sh -i fish


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

# disable greeting
set fish_greeting ""
EOL

# config bashrc
BASHRC="$HOME/.bashrc"

# Check if 'fish' is already referenced in .bashrc to prevent duplicate entries
if grep -q "fish" "$BASHRC"; then
    echo "Fish shell command is already present in $BASHRC. Skipping append."
else
    echo "Appending fish execution to $BASHRC..."

    # Append the command safely
    # We use 'exec fish' instead of 'eval fish' so it replaces the bash process
    # rather than running inside it (cleaner exit).
    cat <<EOT >> "$BASHRC"

# Switch to fish shell if interactive
if [[ \$- == *i* ]]; then
    exec fish
fi
EOT
    echo "Complete. Restart your terminal to verify."
fi

echo "Complete"
