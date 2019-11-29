#!/bin/bash

function main {
    # loop args
    if [[ $# -ne 0 ]] ; then
        for var in "$@" ; do
            eval $var
        done
        exit 1
    fi
    
    # menu
    while true; do
    read -n 1 -p "
    1) Kill wine
    2) Wine - 64 bit
    3) Wine - 32 bit
    4) Switch wine prefix
    5) Steam
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_kill_wine ;;
        2) fn_wine_64 ;;
        3) fn_wine_32 ;;
        4) fn_switch_wine_prefix ;;
        5) fn_setup_steam ;;
        *) $SHELL ;;
    esac
    done
}


function fn_setup_steam {
    #mkdir
    mkdir -p $HOME/Games/Steam

    # move existing install
    mv $HOME/.local/share/Steam $HOME/Games

    # create symlink
    #rm -r $HOME/.local/share/Steam
    ln -s $HOME/Games/Steam $HOME/.local/share/Steam

    # steam fix
    # find ~/.steam/root/ \( -name "libgcc_s.so*" -o -name "libstdc++.so*" -o -name "libxcb.so*" -o -name "libgpg-error.so*" \) -print -delete

    notify-send 'Steam' 'Game on!'
    $SHELL
}


function fn_install_wine {
    # symlink winetricks to wine
    rm -rf $HOME/.cache/winetricks
    rm -rf $HOME/.cache/wine
    ln -s $HOME/wine/cache $HOME/.cache/winetricks
    ln -s $HOME/wine/cache $HOME/.cache/wine
    
    # remove
    ./util.sh -r wine-mono wine winetricks lib32-libldap lib32-gnutls lib32-mpg123 lib32-openal openal lib32-libgpg-error lib32-sqlite lib32-libpulse vulkan-radeon lib32-vulkan-radeon lib32-vulkan-icd-loader
    
    # install software - wine-staging
    ./util.sh -i wine-staging winetricks 
}

function fn_wine_64 {
    # to install a game in windows steam under wine:
    # wine steam steam://install/appid
    # dont use wine-mono if using .net
    fn_install_wine
    printf "\ncreating prefix...\n\n"
    
    # create 64bit wine
    WINE_DIR=$HOME/wine/wine64
    unlink $HOME/.wine
    ln -s $WINE_DIR $HOME/.wine
    WINEARCH=win64 WINEPREFIX=$HOME/.wine wine wineboot -u
    export WINEPREFIX
    
    # set to windows 10 default
    WINEPREFIX=$WINE_DIR winetricks win10
    
    printf "\nremaping directories...\n\n"
    
    # remap user directories
    ID=$(id -nu)
    unlink "$WINE_DIR/drive_c/users/$ID/My Documents"
    unlink "$WINE_DIR/drive_c/users/$ID/Desktop"
    unlink "$WINE_DIR/drive_c/users/$ID/My Pictures"
    unlink "$WINE_DIR/drive_c/users/$ID/My Music"
    unlink "$WINE_DIR/drive_c/users/$ID/My Videos"

    mkdir "$WINE_DIR/drive_c/users/$ID/My Documents"
    mkdir "$WINE_DIR/drive_c/users/$ID/Desktop"
    mkdir "$WINE_DIR/drive_c/users/$ID/My Pictures"
    mkdir "$WINE_DIR/drive_c/users/$ID/My Music"
    mkdir "$WINE_DIR/drive_c/users/$ID/My Videos"
    
    printf "\ninstalling libraries...\n\n"

    # essentials
    # seperate lines if one fails the next will continue
    WINEPREFIX=$WINE_DIR winetricks -q d3dx9
    WINEPREFIX=$WINE_DIR winetricks -q d3dx10
    WINEPREFIX=$WINE_DIR winetricks -q d3dx11
    WINEPREFIX=$WINE_DIR winetricks -q directplay
    WINEPREFIX=$WINE_DIR winetricks -q corefonts
    WINEPREFIX=$WINE_DIR winetricks -q dxvk
    
    # for commandos
    #WINEPREFIX=$WINE_DIR winetricks -q amstream 
    #WINEPREFIX=$WINE_DIR winetricks -q quartz 

    # crusader 2
    #WINEPREFIX=$WINE_DIR winetricks -q comctl32 
    #WINEPREFIX=$WINE_DIR winetricks -q d3dcompiler_43 
    #WINEPREFIX=$WINE_DIR winetricks -q vcrun2010
    
    # sacred 2
    #WINEPREFIX=$WINE_DIR winetricks -q gdiplus
    
    # red solstice 
    # launch steam command: MESA_GL_VERSION_OVERRIDE=3.0 wine Steam.exe - OLD
    #WINEPREFIX=$WINE_DIR winetricks -q vcrun2012
    #WINEPREFIX=$WINE_DIR winetricks -q vcrun2013
    
    # settlers 4 history edititon
    #WINEPREFIX=$WINE_DIR winetricks -q vcrun2015

    # act of aggression - xaudio
    #WINEPREFIX=$WINE_DIR winetricks -q xact 

    # uplay
    #WINEPREFIX=$WINE_DIR winetricks -q winhttp
    
    # the forest installer
    # settings in regedit - HKEY_CURRENT_USER\Software\SKS\TheForest 
    #WINEPREFIX=$WINE_DIR winetricks -q mfc42
    
    # Gaea software
    #WINEPREFIX=$WINE_DIR winetricks -q dotnet472
    
    # reg force steam winxp mode
    #WINEPREFIX=$WINE_DIR wine reg.exe ADD "HKEY_CURRENT_USER\Software\Wine\AppDefaults\Steam.exe" /v "Version" /t "REG_SZ" /d "winxp64" /f
    #WINEPREFIX=$WINE_DIR wine reg.exe ADD "HKEY_CURRENT_USER\Software\Wine\AppDefaults\steamwebhelper.exe" /v "Version" /t "REG_SZ" /d "winxp64" /f 
    
    # titan quest requires winxp mode
    #WINEPREFIX=$WINE_DIR wine reg.exe ADD "HKEY_CURRENT_USER\Software\Wine\AppDefaults\TQ.exe" /v "Version" /t "REG_SZ" /d "winxp64" /f    

    # open dialog to set settings
    WINEPREFIX=$WINE_DIR winecfg
    #wine control
    #wine regedit
    
    #remove wine config
    #rm -rf ~/.wine
    #rm ~/.local/share/applications/wine*
    
    echo 'install complete'
    notify-send 'Applications' 'Install completed'    
}


function fn_wine_32 {
    # how to install dotnet:
    # https://ubuntuforums.org/showthread.php?t=2283185
    
    fn_install_wine

    # create 32bit wine
    WINE_DIR=$HOME/wine/wine32
    unlink $HOME/.wine
    ln -s $WINE_DIR $HOME/.wine
    WINEARCH=win32 WINEPREFIX=$HOME/.wine wine wineboot -u
    export WINEPREFIX

    # set to windows 7 default
    WINEPREFIX=$WINE_DIR winetricks win7

    # remap user directories
    ID=$(id -nu)
    unlink "$WINE_DIR/drive_c/users/$ID/My Documents"
    unlink "$WINE_DIR/drive_c/users/$ID/Desktop"
    unlink "$WINE_DIR/drive_c/users/$ID/My Pictures"
    unlink "$WINE_DIR/drive_c/users/$ID/My Music"
    unlink "$WINE_DIR/drive_c/users/$ID/My Videos"

    mkdir "$WINE_DIR/drive_c/users/$ID/My Documents"
    mkdir "$WINE_DIR/drive_c/users/$ID/Desktop"
    mkdir "$WINE_DIR/drive_c/users/$ID/My Pictures"
    mkdir "$WINE_DIR/drive_c/users/$ID/My Music"
    mkdir "$WINE_DIR/drive_c/users/$ID/My Videos"

    # needs to be installed first
    # moonbase alpha
    # sol survivor
    # magicka
    # wh40k 
    WINEPREFIX=$WINE_DIR winetricks -q dotnet20
    WINEPREFIX=$WINE_DIR winetricks -q dotnet35
    WINEPREFIX=$WINE_DIR winetricks -q dotnet40
    WINEPREFIX=$WINE_DIR winetricks -q dotnet45
    WINEPREFIX=$WINE_DIR winetricks -q dotnet46

    # essentials
    WINEPREFIX=$WINE_DIR winetricks -q d3dx9_43
    WINEPREFIX=$WINE_DIR winetricks -q directplay
    WINEPREFIX=$WINE_DIR winetricks -q corefonts
 
    # gdi plus? (https://raw.githubusercontent.com/corbindavenport/creative-cloud-linux/master/creativecloud.sh)
    # winetricks gdiplus
    # atmlib


    # magika
    WINEPREFIX=$WINE_DIR winetricks -q xna31
    WINEPREFIX=$WINE_DIR winetricks -q xinput
    WINEPREFIX=$WINE_DIR winetricks -q vcrun2008

    # open dialog to set settings
    #WINEPREFIX=$WINE_DIR winecfg
    
    echo 'install complete'
    notify-send 'Applications' 'Install completed'
}


function fn_switch_wine_prefix {

    WINE_TARGET=$(readlink -f ~/.wine)
    WINE = $HOME/.wine
    WINE_32 = $HOME/wine/wine32
    WINE_64 = $HOME/wine/wine64
    rm ~/.wine
    
    echo "target: ", $WINE_TARGET
    
    TITLE=""
    MSG=""
    if [[ "${WINE_TARGET}" == *wine64 ]]; then
        ln -s $WINE_32 $WINE
        MSG="Changed from win64 to wine32"
        TITLE="Wine32 Active"
    else
        ln -s $WINE_64 $WINE
        MSG="Changed from win32 to wine64"
        TITLE="Wine64 Active"
    fi
    
    echo $TITLE
    echo $MSG
    notify-send "${TITLE}" "${MSG}"
}


function fn_kill_wine {
    # https://askubuntu.com/questions/52341/how-to-kill-wine-processes-when-they-crash-or-are-going-to-crash
    ls -l /proc/*/exe 2>/dev/null | grep -E 'wine(64)?-preloader|wineserver|winedevice' | perl -pe 's;^.*/proc/(\d+)/exe.*$;$1;g;' | xargs -n 1 kill

    # or
    #ps -x | grep -E 'wineserver|winedevice' | awk '{print $1}' | xargs -n 1 kill
}


# pass all args
main "$@"
