 #!/bin/bash

# yay -S usbip

 #devices = `usbip list -l | grep busid`

 usbip list -l | grep busid | while read -r line ; do
    echo "Processing $line"

    # busid 1-6 (2548:1002)
    # ^busid\s(.*)\s\(.*$
    if [[ $line =~ ^-[[:space:]]busid(.*)[[:space:]].*$ ]]; then
        echo "Binding USB device: ${BASH_REMATCH[1]}"
        usbip bind -b ${BASH_REMATCH[1]}
    else
        echo "no match on '$line'"
    fi
    # your code goes here
done