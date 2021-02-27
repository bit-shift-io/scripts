 
#!/bin/bash

echo "You have kernel version:"
uname -r

sudo pacman -S linux-headers
yay -S rtl8812au-dkms-git
