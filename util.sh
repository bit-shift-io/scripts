#!/bin/bash

function main {
    # install helper works with:
    # pacman, yay, zipper
    type="${1}"
    
    # array of utils
    install_utils=(pacman yay zypper)
    
    # get package tool
    for util in ${install_utils[@]};
    do
        bin_exits=$(which ${util} 2> /dev/null | grep ${util} -c)

        if [[ ${bin_exits} == "1" ]]; then
            # install yay
            #if [[ ${util} == "pacman" ]]; then
             #   sudo pacman -S yay --noconfirm --needed
              #  util=(yay)
            #fi
            
            # return binary
            install_util=${util}
            echo "found: ${install_util}"
        fi
    done
    
    # which type
    case ${type} in
        '-i') # install
            install ${install_util} ${@:2}
            ;;

        '-r') # remove
            remove ${install_util} ${@:2}
            ;;

        *)
            echo -n "unknown"
            ;;
    esac

}

function install {
    bin="${1}"
    arr="${@:2}"
    
    for pkg in ${arr}
    do
        case ${bin} in
            'pacman')
                ${bin} -S --noconfirm --needed ${pkg}
                ;;
                
            'yay')
                ${bin} -S --noconfirm --needed ${pkg}
                ;;
                
            'zypper')
                sudo ${bin} -n install ${pkg}
                ;;

            *)
                echo -n "unknown"
                ;;
        esac
    done
    
}

function remove {
    bin="${1}"
    arr="${@:2}"
    
    for pkg in ${arr}
    do
        case ${bin} in
            'pacman')
                ${bin} -Rs --noconfirm ${pkg}
                ;;
                
            'yay')
                ${bin} -Rs --noconfirm ${pkg}
                ;;
                
            'zypper')
                sudo ${bin} -n rm ${pkg}
                ;;

            *)
                echo -n "unknown"
                ;;
        esac
    done    
}

# pass all args
main "$@"
