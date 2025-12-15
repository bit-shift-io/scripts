#!/bin/bash

function main {
    # install helper works with:
    # pacman, yay, zipper
    type="${1}"
    
    # array of utils ordered by preference
    install_utils=(paru yay pacman apt zypper)
    
    # Reset install_util to ensure a selection is made
    install_util=""
    
    # get package tool
    for util in ${install_utils[@]};
    do
    
        # Check if the utility binary exists
        #bin_exits=$(which ${util} 2> /dev/null | grep ${util} -c)
        #if [[ ${bin_exits} == "1" ]]; then
        if which "${util}" > /dev/null 2>&1; then
            
            # return first found binary
            install_util=${util}
            echo "found: ${install_util}"
            break
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
    
    for pkg in "${@:2}"
    do
        case ${bin} in
            'pacman')
                sudo ${bin} -S --noconfirm --needed ${pkg}
                ;;
                
            'paru'|'yay')
                ${bin} -S --noconfirm --needed ${pkg}
                ;;
                
            'zypper')
                sudo ${bin} -n install ${pkg}
                ;;

            'apt')
                sudo ${bin} install -y ${pkg}
                ;;

            *)
                echo -n "unknown"
                ;;
        esac
    done
    
}

function remove {
    bin="${1}"
    
    for pkg in "${@:2}"
    do
        case ${bin} in
            'pacman')
                sudo ${bin} -Rs --noconfirm ${pkg}
                ;;
                
            'paru'|'yay')
                ${bin} -Rs --noconfirm ${pkg}
                ;;
                
            'zypper')
                sudo ${bin} -n rm ${pkg}
                ;;

            'apt')
                sudo ${bin} remove -y ${pkg}
                ;;

            *)
                echo -n "unknown"
                ;;
        esac
    done    
}

# pass all args
main "$@"
