#!/bin/bash
# Overwrite = cat > 
# Append = cat >>


# ICON/COLOR THEME
cat > "$HOME/.config/kdeglobals" << EOL
[$Version]
update_info=fonts_global.upd:Fonts_Global

[ColorEffects:Disabled]
Color=
ColorAmount=
ColorEffect=
ContrastAmount=
ContrastEffect=
IntensityAmount=
IntensityEffect=

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=
ColorAmount=
ColorEffect=
ContrastAmount=
ContrastEffect=
Enable=false
IntensityAmount=
IntensityEffect=

[Colors:Button]
BackgroundAlternate=189,195,199
BackgroundNormal=238,238,238
DecorationFocus=240,84,76
DecorationHover=240,84,76
ForegroundActive=61,174,233
ForegroundInactive=136,136,128
ForegroundLink=41,128,185
ForegroundNegative=239,85,92
ForegroundNeutral=255,128,0
ForegroundNormal=68,68,68
ForegroundPositive=84,205,238
ForegroundVisited=127,140,141

[Colors:Complementary]
BackgroundAlternate=59,64,69
BackgroundNormal=49,54,59
DecorationFocus=30,146,255
DecorationHover=61,174,230
ForegroundActive=246,116,0
ForegroundInactive=175,176,179
ForegroundLink=61,174,230
ForegroundNegative=237,21,21
ForegroundNeutral=201,206,59
ForegroundNormal=239,240,241
ForegroundPositive=17,209,22
ForegroundVisited=61,174,230

[Colors:Selection]
BackgroundAlternate=29,153,243
BackgroundNormal=240,84,76
DecorationFocus=240,84,76
DecorationHover=240,84,76
ForegroundActive=252,252,252
ForegroundInactive=236,236,236
ForegroundLink=253,188,75
ForegroundNegative=239,85,92
ForegroundNeutral=255,128,0
ForegroundNormal=236,236,236
ForegroundPositive=84,205,238
ForegroundVisited=189,195,199

[Colors:Tooltip]
BackgroundAlternate=77,77,77
BackgroundNormal=68,68,68
DecorationFocus=240,84,76
DecorationHover=240,84,76
ForegroundActive=61,174,233
ForegroundInactive=136,136,128
ForegroundLink=41,128,185
ForegroundNegative=239,85,92
ForegroundNeutral=255,128,0
ForegroundNormal=236,236,236
ForegroundPositive=84,205,238
ForegroundVisited=127,140,141

[Colors:View]
BackgroundAlternate=239,240,241
BackgroundNormal=255,255,255
DecorationFocus=240,84,76
DecorationHover=240,84,76
ForegroundActive=61,174,233
ForegroundInactive=136,136,128
ForegroundLink=41,128,185
ForegroundNegative=239,85,92
ForegroundNeutral=255,128,0
ForegroundNormal=68,68,68
ForegroundPositive=84,205,238
ForegroundVisited=127,140,141

[Colors:Window]
BackgroundAlternate=189,195,199
BackgroundNormal=238,238,238
DecorationFocus=240,84,76
DecorationHover=240,84,76
ForegroundActive=61,174,233
ForegroundInactive=136,136,128
ForegroundLink=41,128,185
ForegroundNegative=239,85,92
ForegroundNeutral=255,128,0
ForegroundNormal=68,68,68
ForegroundPositive=84,205,238
ForegroundVisited=127,140,141

[DirSelect Dialog]
DirSelectDialog Size=640,480
History Items[$e]=file:$HOME/Downloads

[General]
ColorScheme=Numix
Name=Breeze Dark
shadeSortColumn=true

[Icons]
Theme=breeze-dark

[KDE]
DoubleClickInterval=400
LookAndFeelPackage=org.kde.breezedark.desktop
ShowDeleteCommand=false
SingleClick=true
StartDragDist=4
StartDragTime=500
WheelScrollLines=3
contrast=4
widgetStyle=Breeze

[KFileDialog Settings]
Automatically select filename extension=true
Breadcrumb Navigation=true
Decoration position=0
LocationCombo Completionmode=5
PathCombo Completionmode=5
Previews=true
Show Bookmarks=false
Show Full Path=false
Show Preview=false
Show Speedbar=true
Show hidden files=false
Sort by=Name
Sort directories first=true
Sort reversed=false
Speedbar Width=128
View Style=Simple
listViewIconSize=28

[PreviewSettings]
MaximumRemoteSize=0

[WM]
activeBackground=68,68,68
activeBlend=68,68,68
activeForeground=239,240,241
inactiveBackground=68,68,68
inactiveBlend=68,68,68
inactiveForeground=136,136,128
EOL


# DESKTOP PLASMA
cat > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" << EOL
[ActionPlugins][0]
MidButton;NoModifier=org.kde.paste
RightButton;NoModifier=org.kde.contextmenu
wheel:Vertical;NoModifier=org.kde.switchdesktop

[ActionPlugins][1]
MidButton;NoModifier=org.kde.paste
RightButton;NoModifier=org.kde.contextmenu

[Containments][1]
activityId=
formfactor=3
immutability=1
lastScreen=0
location=5
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][1][Applets][2][Configuration][General]
favorites=firefox.desktop,org.kde.dolphin.desktop,org.kde.konversation.desktop,libreoffice-writer.desktop,cantata.desktop,org.kde.konsole.desktop,octopi.desktop,systemsettings.desktop

[Containments][1][Applets][4][Configuration][General]
launchers=file:///usr/share/applications/org.kde.ksysguard.desktop,file:///usr/share/applications/org.kde.dolphin.desktop?wmClass=dolphin,file:///usr/share/applications/firefox.desktop
maxStripes=10
showOnlyCurrentActivity=false

[Containments][1][Applets][45]
immutability=1
plugin=org.kde.plasma.kicker

[Containments][1][Applets][45][Configuration][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][1][Applets][45][Configuration][General]
alignResultsToBottom=false
alphaSort=true
favoriteApps=systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kcalc.desktop,steam.desktop,org.kde.konsole.desktop
favoriteSystemActions=shutdown,reboot
limitDepth=true
showRecentApps=false
showRecentDocs=false
useExtraRunners=false

[Containments][1][Applets][45][Shortcuts]
global=Alt+F1

[Containments][1][Applets][48][Configuration][General]
groupingStrategy=0
maxStripes=1

[Containments][1][Applets][49][Configuration][General]
launchers=file:///usr/share/applications/org.kde.dolphin.desktop

[Containments][1][Applets][53]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][1][Applets][53][Configuration][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][1][Applets][53][Configuration][General]
groupingAppIdBlacklist=org.kde.dolphin,steam,firefox,org.kde.kate,org.kde.konsole
groupingLauncherUrlBlacklist=file:///usr/share/applications/org.kde.dolphin.desktop,file:///usr/share/applications/org.kde.konsole.desktop,file:///usr/share/applications/firefox.desktop,file:///usr/share/applications/steam.desktop,file:///usr/share/applications/org.kde.kate.desktop
launchers=file:///usr/share/applications/org.kde.dolphin.desktop,file:///usr/share/applications/firefox.desktop
maxStripes=1
middleClickAction=ToggleGrouping

[Containments][1][Applets][55][Configuration][General]
noteId=fc917376-abdd-424c-8891-fcdf61eaaa

[Containments][1][Applets][7]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][7][Configuration]
SystrayContainmentId=8

[Containments][1][Applets][7][Configuration][Containments][8]
formfactor=2
location=4

[Containments][1][Applets][8]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][1][ConfigDialog]
DialogHeight=1080
DialogWidth=170

[Containments][1][General]
AppletOrder=45;53;7;8

[Containments][59]
activityId=834cd1ce-3ff2-448f-b41e-b9d7915b321d
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.desktopcontainment
wallpaperplugin=org.kde.image

[Containments][59][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][59][General]
showToolbox=false

[Containments][59][Wallpaper][org.kde.image][General]
FillMode=2
Image=file:///usr/share/wallpapers/EveningGlow/contents/images/2560x1440.jpg

[Containments][8]
activityId=
formfactor=3
immutability=1
lastScreen=0
location=5
plugin=org.kde.plasma.private.systemtray
wallpaperplugin=org.kde.image

[Containments][8][Applets][36]
immutability=1
plugin=org.kde.plasma.volume

[Containments][8][Applets][36][Configuration][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][8][Applets][37]
immutability=1
plugin=org.kde.plasma.clipboard

[Containments][8][Applets][38]
immutability=1
plugin=org.kde.plasma.devicenotifier

[Containments][8][Applets][39]
immutability=1
plugin=org.kde.kdeconnect

[Containments][8][Applets][40]
immutability=1
plugin=org.kde.plasma.notifications

[Containments][8][Applets][41]
immutability=1
plugin=org.kde.plasma.printmanager

[Containments][8][Applets][42]
immutability=1
plugin=org.kde.plasma.battery

[Containments][8][Applets][43]
immutability=1
plugin=org.kde.plasma.networkmanagement

[Containments][8][Applets][47]
immutability=1
plugin=org.kde.plasma.bluetooth

[Containments][8][Applets][48]
immutability=1
plugin=org.kde.plasma.mediacontroller

[Containments][8][General]
extraItems=org.kde.kdeconnect,org.kde.plasma.printmanager,org.kde.plasma.battery,org.kde.plasma.devicenotifier,org.kde.plasma.networkmanagement,org.kde.plasma.clipboard,org.kde.plasma.notifications,org.kde.plasma.volume,org.kde.plasma.bluetooth,org.kde.plasma.mediacontroller
knownItems=org.kde.kdeconnect,org.kde.plasma.printmanager,org.kde.plasma.battery,org.kde.plasma.devicenotifier,org.kde.plasma.networkmanagement,org.kde.plasma.clipboard,org.kde.plasma.notifications,org.kde.plasma.volume,org.kde.plasma.bluetooth,org.kde.plasma.mediacontroller

EOL

# DOLPHIN BOOKMARKS
cat > "$HOME/.local/share/user-places.xbel" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xbel>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
 <bookmark href="file:///$HOME">
  <title>Home</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-home"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1494821596/0</ID>
    <isSystemItem>true</isSystemItem>
    <IsHidden>false</IsHidden>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file:////$HOME/Documents">
  <title>Documents</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-documents"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1504326356/0 (V2)</ID>
    <IsHidden>false</IsHidden>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file:///$HOME/Downloads">
  <title>Downloads</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-download"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1495079848/0 (V2)</ID>
    <IsHidden>false</IsHidden>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="remote:/">
  <title>Network</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="network-workgroup"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1494821596/1</ID>
    <isSystemItem>true</isSystemItem>
    <IsHidden>false</IsHidden>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="file:///">
  <title>Root</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-red"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1494821596/2</ID>
    <isSystemItem>true</isSystemItem>
    <IsHidden>false</IsHidden>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="trash:/">
  <title>Trash</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="user-trash-full"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1494821596/3</ID>
    <isSystemItem>true</isSystemItem>
    <IsHidden>false</IsHidden>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="recentlyused:/files">
  <title>Recent Files</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="document-open-recent"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1588304428/0</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="recentlyused:/locations">
  <title>Recent Locations</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-open-recent"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1588304428/1</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="">
  <title>Project Folder</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-favorites"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <OnlyInApp>kdenlive</OnlyInApp>
   </metadata>
  </info>
 </bookmark>
 <info>
  <metadata owner="http://www.kde.org">
   <withRecentlyUsed>true</withRecentlyUsed>
   <GroupState-RecentlySaved-IsHidden>true</GroupState-RecentlySaved-IsHidden>
   <withBaloo>true</withBaloo>
   <GroupState-SearchFor-IsHidden>true</GroupState-SearchFor-IsHidden>
  </metadata>
 </info>
 <bookmark href="search:/documents">
  <title>Documents</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-text"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1588304428/2</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="search:/images">
  <title>Images</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-images"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1588304428/3</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="search:/audio">
  <title>Audio</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-sound"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1588304428/4</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <bookmark href="search:/videos">
  <title>Videos</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="folder-videos"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>1588304428/5</ID>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </bookmark>
 <separator>
  <info>
   <metadata owner="http://www.kde.org">
    <UDI>/org/freedesktop/UDisks2/block_devices/sda1</UDI>
    <isSystemItem>true</isSystemItem>
   </metadata>
  </info>
 </separator>
</xbel>

EOL

# KWIN WINDOW SETTINGS
cat > "$HOME/.config/kwinrc" << EOL
[Compositing]
AnimationSpeed=3
Backend=OpenGL
Enabled=true
GLCore=false
GLPreferBufferSwap=a
GLTextureFilter=2
HiddenPreviews=5
OpenGLIsUnsafe=false
WindowsBlockCompositing=true
XRenderSmoothScale=false

[Effect-CoverSwitch]
TabBox=false
TabBoxAlternative=false

[Effect-Cube]
BorderActivate=9
BorderActivateCylinder=9
BorderActivateSphere=9

[Effect-DesktopGrid]
BorderActivate=9

[Effect-FlipSwitch]
TabBox=false
TabBoxAlternative=false

[Effect-PresentWindows]
BorderActivate=9
BorderActivateAll=9
BorderActivateClass=9

[ElectricBorders]
Bottom=None
BottomLeft=None
BottomRight=None
Left=None
Right=None
Top=None
TopLeft=None
TopRight=None

[MouseBindings]
CommandActiveTitlebar1=Raise
CommandActiveTitlebar2=Start window tab drag
CommandActiveTitlebar3=Operations menu
CommandAll1=Move
CommandAll2=Toggle raise and lower
CommandAll3=Resize
CommandAllKey=Meta
CommandAllWheel=Nothing
CommandInactiveTitlebar1=Activate and raise
CommandInactiveTitlebar2=Start window tab drag
CommandInactiveTitlebar3=Operations menu
CommandTitlebarWheel=Switch to Window Tab to the Left/Right
CommandWindow1=Activate, raise and pass click
CommandWindow2=Activate and pass click
CommandWindow3=Activate and pass click
CommandWindowWheel=Scroll

[Plugins]
coverswitchEnabled=true
flipswitchEnabled=true
highlightwindowEnabled=true
presentwindowsEnabled=false
windowgeometryEnabled=false
zoomEnabled=false

[TabBox]
ActivitiesMode=1
ApplicationsMode=0
BorderActivate=9
BorderAlternativeActivate=9
DesktopLayout=org.kde.breeze.desktop
DesktopListLayout=org.kde.breeze.desktop
DesktopMode=1
HighlightWindows=false
LayoutName=thumbnails
MinimizedMode=0
MultiScreenMode=1
ShowDesktopMode=0
ShowTabBox=true
SwitchingMode=0

[TabBoxAlternative]
ActivitiesMode=1
ApplicationsMode=0
DesktopMode=1
HighlightWindows=true
LayoutName=org.kde.breeze.desktop
MinimizedMode=0
MultiScreenMode=0
ShowDesktopMode=0
ShowTabBox=true
SwitchingMode=0

[Windows]
ActiveMouseScreen=false
AutoRaise=false
AutoRaiseInterval=750
AutogroupInForeground=true
AutogroupSimilarWindows=false
BorderSnapZone=10
CenterSnapZone=0
ClickRaise=true
DelayFocusInterval=300
ElectricBorderCooldown=350
ElectricBorderCornerRatio=0.25
ElectricBorderDelay=150
ElectricBorderMaximize=true
ElectricBorderTiling=true
ElectricBorders=0
FocusPolicy=ClickToFocus
FocusStealingPreventionLevel=1
GeometryTip=false
HideUtilityWindowsForInactive=true
InactiveTabsSkipTaskbar=false
MaximizeButtonLeftClickCommand=Maximize
MaximizeButtonMiddleClickCommand=Maximize (vertical only)
MaximizeButtonRightClickCommand=Maximize (horizontal only)
NextFocusPrefersMouse=false
Placement=Centered
SeparateScreenFocus=false
ShadeHover=false
ShadeHoverInterval=250
SnapOnlyWhenOverlapping=false
TitlebarDoubleClickCommand=Maximize
WindowSnapZone=10

[org.kde.kdecoration2]
BorderSize=NoSides
ButtonsOnLeft=M
ButtonsOnRight=HIAX
CloseOnDoubleClickOnMenu=true
library=org.kde.breeze
theme=
EOL

# SHUTDOWN & LOGIN SESSION
cat > "$HOME/.config/ksmserverrc" << EOL
[General]
confirmLogout=false
excludeApps=
loginMode=default
offerShutdown=true
screenCount=1
shutdownType=2
EOL


# RIGHT CLICK MENU
cat > "$HOME/.config/kservicemenurc" << EOL
[Show]
ChangeCustom=true
ChangePerm=true
ChangeRoot=true
ChangeUser=true
Compress=true
Copy=true
CreateK3bAudioProject=false
CreateK3bDataProject=false
CreateK3bVcdProject=false
Delete=true
EditAsText=true
OpenInFilemanager=true
OpenInFilemanagerFile=true
OpenInKonsole=true
OpenInKonsoleFile=true
OpenWithCustom=true
Rename=true
WriteCdImage=false
bluedevilfileitemaction=false
compressfileitemaction=true
extractfileitemaction=true
installFont=true
kactivitymanagerd_fileitem_linking_plugin=false
kdeconnectsendfile=true
kleodecryptverifyfiles=false
kleoencryptfiles=false
kleoencryptfolder=false
kleoencryptsignfiles=false
kleosignencryptfolder=false
kleosignfilescms=false
kleosignfilesopenpgp=false
openTerminalHere=true
runInKonsole=true
slideshow=false

EOL

# TITLE ALIGNMENT
cat > "$HOME/.config/breezerc" << EOL
[Windeco]
TitleAlignment=AlignLeft
EOL


# KDE THEME
cat > "$HOME/.config/plasmarc" << EOL
[Theme]
name=breeze-dark
EOL


# LOCK SCREEN DISABLE
cat > "$HOME/.config/kscreenlockerrc" << EOL
[\$Version]
update_info=kscreenlocker.upd:0.1-autolock

[Daemon]
Autolock=false
LockOnResume=false

[Greeter]
Theme=org.kde.breezedark.desktop
EOL

# KDE SPLASH SCREEN
cat > "$HOME/.config/ksplashrc" << EOL
[KSplash]
Engine=none
Theme=None
EOL

# KDE GLOBAL KEYBOARD SHORTCUTS
# for media controls etc
cat > "$HOME/.config/kglobalshortcutsrc" << EOL
[KDE Keyboard Layout Switcher]
Switch to Next Keyboard Layout=Ctrl+Alt+K,none,Switch to Next Keyboard Layout
_k_friendly_name=System Settings Module

[kaccess]
Toggle Screen Reader On and Off=Meta+Alt+S,Meta+Alt+S,Toggle Screen Reader On and Off
_k_friendly_name=Accessibility

[kcm_touchpad]
Disable Touchpad=Touchpad Off,Touchpad Off,Disable Touchpad
Enable Touchpad=Touchpad On,Touchpad On,Enable Touchpad
Toggle Touchpad=Touchpad Toggle,Touchpad Toggle,Toggle Touchpad
_k_friendly_name=KDE Daemon

[kded5]
Decrease Keyboard Brightness=Keyboard Brightness Down,Keyboard Brightness Down,Decrease Keyboard Brightness
Decrease Screen Brightness=Monitor Brightness Down,Monitor Brightness Down,Decrease Screen Brightness
Hibernate=Hibernate,Hibernate,Hibernate
Increase Keyboard Brightness=Keyboard Brightness Up,Keyboard Brightness Up,Increase Keyboard Brightness
Increase Screen Brightness=Monitor Brightness Up,Monitor Brightness Up,Increase Screen Brightness
PowerOff=Power Off,Power Off,Power Off
Show System Activity=Ctrl+Esc,Ctrl+Esc,Show System Activity
Sleep=Sleep,Sleep,Suspend
Toggle Keyboard Backlight=Keyboard Light On/Off,Keyboard Light On/Off,Toggle Keyboard Backlight
_k_friendly_name=Power Management
display=Display\tMeta+P,Display\tMeta+P,Switch Display

[khotkeys]
_k_friendly_name=KDE Daemon
{1e25b461-3ddd-440f-9038-bbea108b0303}=Print,none,Start Screenshot Tool
{abe80e75-17a4-4b1a-8e55-9e17a0b5abed}=Ctrl+Shift+Print,none,Take Rectangular Region Screenshot
{b8340e9f-cfdb-4b86-b98f-171948437341}=Shift+Print,none,Take Full Screen Screenshot
{c33a70db-9522-4d76-ab98-413ed7341f97}=Ctrl+Alt+T,none,Launch Konsole
{c3d9528b-5c2b-4c46-adea-f4e821e8ce7a}=Ctrl+Print,none,Take Active Window Screenshot
{d03619b6-9b3c-48cc-9d9c-a2aadb485550}=,none,Search

[kmix]
_k_friendly_name=Audio Volume
decrease_microphone_volume=Microphone Volume Down,Microphone Volume Down,Decrease Microphone Volume
decrease_volume=Volume Down,Volume Down,Decrease Volume
increase_microphone_volume=Microphone Volume Up,Microphone Volume Up,Increase Microphone Volume
increase_volume=Volume Up,Volume Up,Increase Volume
mic_mute=Microphone Mute,Microphone Mute,Mute Microphone
mute=Volume Mute,Volume Mute,Mute

[krunner]
_k_friendly_name=Run Command
run command=Alt+Space\tAlt+F2\tSearch,Alt+Space,Run Command
run command on clipboard contents=Alt+Shift+F2,Alt+Shift+F2,Run Command on clipboard contents

[ksmserver]
Halt Without Confirmation=Ctrl+Alt+Shift+PgDown,none,Halt Without Confirmation
Lock Session=Ctrl+Alt+L\tScreensaver,Ctrl+Alt+L\tScreensaver,Lock Session
Log Out=none,none,Log Out
Log Out Without Confirmation=,none,Log Out Without Confirmation
Reboot Without Confirmation=Ctrl+Alt+Shift+Del,none,Reboot Without Confirmation
_k_friendly_name=ksmserver

[kwin]
Activate Window Demanding Attention=Ctrl+Alt+A,Ctrl+Alt+A,Activate Window Demanding Attention
Decrease Opacity=none,none,Decrease Opacity of Active Window by 5 %
Expose=Ctrl+F9,Ctrl+F9,Toggle Present Windows (Current desktop)
ExposeAll=Ctrl+F10\tLaunch (C),Ctrl+F10\tLaunch (C),Toggle Present Windows (All desktops)
ExposeClass=Ctrl+F7,Ctrl+F7,Toggle Present Windows (Window class)
Increase Opacity=none,none,Increase Opacity of Active Window by 5 %
Invert Screen Colors=none,none,Invert Screen Colors
Kill Window=Ctrl+Alt+Esc,Ctrl+Alt+Esc,Kill Window
MoveMouseToCenter=Meta+F6,Meta+F6,Move Mouse to Center
MoveMouseToFocus=Meta+F5,Meta+F5,Move Mouse to Focus
MoveZoomDown=Meta+Down,Meta+Down,Move Zoomed Area Downwards
MoveZoomLeft=Meta+Left,Meta+Left,Move Zoomed Area to Left
MoveZoomRight=Meta+Right,Meta+Right,Move Zoomed Area to Right
MoveZoomUp=Meta+Up,Meta+Up,Move Zoomed Area Upwards
Remove Window From Group=none,none,Remove Window From Group
Setup Window Shortcut=none,none,Setup Window Shortcut
Show Desktop=none,none,Show Desktop
ShowDesktopGrid=Ctrl+F8,Ctrl+F8,Show Desktop Grid
Suspend Compositing=Alt+Shift+F12,Alt+Shift+F12,Suspend Compositing
Switch One Desktop Down=none,none,Switch One Desktop Down
Switch One Desktop Up=none,none,Switch One Desktop Up
Switch One Desktop to the Left=none,none,Switch One Desktop to the Left
Switch One Desktop to the Right=none,none,Switch One Desktop to the Right
Switch Window Down=Meta+Alt+Down,Meta+Alt+Down,Switch to Window Below
Switch Window Left=Meta+Alt+Left,Meta+Alt+Left,Switch to Window to the Left
Switch Window Right=Meta+Alt+Right,Meta+Alt+Right,Switch to Window to the Right
Switch Window Up=Meta+Alt+Up,Meta+Alt+Up,Switch to Window Above
Switch to Desktop 1=Ctrl+F1,Ctrl+F1,Switch to Desktop 1
Switch to Desktop 10=none,none,Switch to Desktop 10
Switch to Desktop 11=none,none,Switch to Desktop 11
Switch to Desktop 12=none,none,Switch to Desktop 12
Switch to Desktop 13=none,none,Switch to Desktop 13
Switch to Desktop 14=none,none,Switch to Desktop 14
Switch to Desktop 15=none,none,Switch to Desktop 15
Switch to Desktop 16=none,none,Switch to Desktop 16
Switch to Desktop 17=none,none,Switch to Desktop 17
Switch to Desktop 18=none,none,Switch to Desktop 18
Switch to Desktop 19=none,none,Switch to Desktop 19
Switch to Desktop 2=Ctrl+F2,Ctrl+F2,Switch to Desktop 2
Switch to Desktop 20=none,none,Switch to Desktop 20
Switch to Desktop 3=Ctrl+F3,Ctrl+F3,Switch to Desktop 3
Switch to Desktop 4=Ctrl+F4,Ctrl+F4,Switch to Desktop 4
Switch to Desktop 5=none,none,Switch to Desktop 5
Switch to Desktop 6=none,none,Switch to Desktop 6
Switch to Desktop 7=none,none,Switch to Desktop 7
Switch to Desktop 8=none,none,Switch to Desktop 8
Switch to Desktop 9=none,none,Switch to Desktop 9
Switch to Next Desktop=none,none,Switch to Next Desktop
Switch to Next Screen=none,none,Switch to Next Screen
Switch to Previous Desktop=none,none,Switch to Previous Desktop
Switch to Previous Screen=none,none,Switch to Previous Screen
Switch to Screen 0=none,none,Switch to Screen 0
Switch to Screen 1=none,none,Switch to Screen 1
Switch to Screen 2=none,none,Switch to Screen 2
Switch to Screen 3=none,none,Switch to Screen 3
Switch to Screen 4=none,none,Switch to Screen 4
Switch to Screen 5=none,none,Switch to Screen 5
Switch to Screen 6=none,none,Switch to Screen 6
Switch to Screen 7=none,none,Switch to Screen 7
Toggle Window Raise/Lower=none,none,Toggle Window Raise/Lower
Walk Through Desktop List=none,none,Walk Through Desktop List
Walk Through Desktop List (Reverse)=none,none,Walk Through Desktop List (Reverse)
Walk Through Desktops=none,none,Walk Through Desktops
Walk Through Desktops (Reverse)=none,none,Walk Through Desktops (Reverse)
Walk Through Window Tabs=none,none,Walk Through Window Tabs
Walk Through Window Tabs (Reverse)=none,none,Walk Through Window Tabs (Reverse)
Walk Through Windows=Alt+Tab,none,Walk Through Windows
Walk Through Windows (Reverse)=Alt+Shift+Backtab,none,Walk Through Windows (Reverse)
Walk Through Windows Alternative=none,none,Walk Through Windows Alternative
Walk Through Windows Alternative (Reverse)=none,none,Walk Through Windows Alternative (Reverse)
Walk Through Windows of Current Application=Alt+\`,none,Walk Through Windows of Current Application
Walk Through Windows of Current Application (Reverse)=Alt+~,none,Walk Through Windows of Current Application (Reverse)
Walk Through Windows of Current Application Alternative=none,none,Walk Through Windows of Current Application Alternative
Walk Through Windows of Current Application Alternative (Reverse)=none,none,Walk Through Windows of Current Application Alternative (Reverse)
Window Above Other Windows=none,none,Keep Window Above Others
Window Below Other Windows=none,none,Keep Window Below Others
Window Close=Alt+F4,Alt+F4,Close Window
Window Fullscreen=none,none,Make Window Fullscreen
Window Grow Horizontal=none,none,Pack Grow Window Horizontally
Window Grow Vertical=none,none,Pack Grow Window Vertically
Window Lower=none,none,Lower Window
Window Maximize=none,none,Maximize Window
Window Maximize Horizontal=none,none,Maximize Window Horizontally
Window Maximize Vertical=none,none,Maximize Window Vertically
Window Minimize=none,none,Minimize Window
Window Move=none,none,Move Window
Window No Border=none,none,Hide Window Border
Window On All Desktops=none,none,Keep Window on All Desktops
Window One Desktop Down=none,none,Window One Desktop Down
Window One Desktop Up=none,none,Window One Desktop Up
Window One Desktop to the Left=none,none,Window One Desktop to the Left
Window One Desktop to the Right=none,none,Window One Desktop to the Right
Window Operations Menu=Alt+F3,Alt+F3,Window Operations Menu
Window Pack Down=none,none,Pack Window Down
Window Pack Left=none,none,Pack Window to the Left
Window Pack Right=none,none,Pack Window to the Right
Window Pack Up=none,none,Pack Window Up
Window Quick Tile Bottom=none,none,Quick Tile Window to the Bottom
Window Quick Tile Bottom Left=none,none,Quick Tile Window to the Bottom Left
Window Quick Tile Bottom Right=none,none,Quick Tile Window to the Bottom Right
Window Quick Tile Left=none,none,Quick Tile Window to the Left
Window Quick Tile Right=none,none,Quick Tile Window to the Right
Window Quick Tile Top=none,none,Quick Tile Window to the Top
Window Quick Tile Top Left=none,none,Quick Tile Window to the Top Left
Window Quick Tile Top Right=none,none,Quick Tile Window to the Top Right
Window Raise=none,none,Raise Window
Window Resize=none,none,Resize Window
Window Shade=none,none,Shade Window
Window Shrink Horizontal=none,none,Pack Shrink Window Horizontally
Window Shrink Vertical=none,none,Pack Shrink Window Vertically
Window to Desktop 1=none,none,Window to Desktop 1
Window to Desktop 10=none,none,Window to Desktop 10
Window to Desktop 11=none,none,Window to Desktop 11
Window to Desktop 12=none,none,Window to Desktop 12
Window to Desktop 13=none,none,Window to Desktop 13
Window to Desktop 14=none,none,Window to Desktop 14
Window to Desktop 15=none,none,Window to Desktop 15
Window to Desktop 16=none,none,Window to Desktop 16
Window to Desktop 17=none,none,Window to Desktop 17
Window to Desktop 18=none,none,Window to Desktop 18
Window to Desktop 19=none,none,Window to Desktop 19
Window to Desktop 2=none,none,Window to Desktop 2
Window to Desktop 20=none,none,Window to Desktop 20
Window to Desktop 3=none,none,Window to Desktop 3
Window to Desktop 4=none,none,Window to Desktop 4
Window to Desktop 5=none,none,Window to Desktop 5
Window to Desktop 6=none,none,Window to Desktop 6
Window to Desktop 7=none,none,Window to Desktop 7
Window to Desktop 8=none,none,Window to Desktop 8
Window to Desktop 9=none,none,Window to Desktop 9
Window to Next Desktop=none,none,Window to Next Desktop
Window to Next Screen=none,none,Window to Next Screen
Window to Previous Desktop=none,none,Window to Previous Desktop
Window to Previous Screen=none,none,Window to Previous Screen
Window to Screen 0=none,none,Window to Screen 0
Window to Screen 1=none,none,Window to Screen 1
Window to Screen 2=none,none,Window to Screen 2
Window to Screen 3=none,none,Window to Screen 3
Window to Screen 4=none,none,Window to Screen 4
Window to Screen 5=none,none,Window to Screen 5
Window to Screen 6=none,none,Window to Screen 6
Window to Screen 7=none,none,Window to Screen 7
_k_friendly_name=KWin
view_actual_size=,Meta+0,Actual Size
view_zoom_in=Meta+=,Meta+=,Zoom In
view_zoom_out=Meta+-,Meta+-,Zoom Out

[mediacontrol]
_k_friendly_name=Media Controller
nextmedia=Media Next\tCtrl+Right,Media Next,Media playback next
playpausemedia=Media Play\tCtrl+Up,Media Play,Play/Pause media playback
previousmedia=Media Previous\tCtrl+Left,Media Previous,Media playback previous
stopmedia=Media Stop\tCtrl+Down,Media Stop,Stop media playback

[org.kde.dolphin.desktop]
_k_friendly_name=Launch Dolphin
_launch=Meta+F\tMeta+E,none,Launch Dolphin

[org.kde.konsole.desktop]
NewTab=,none,Open a New Tab
NewWindow=none,none,Open a New Window
_k_friendly_name=Launch Konsole
_launch=Ctrl+Alt+T,none,Launch Konsole

[org.kde.ksysguard.desktop]
_k_friendly_name=Launch KSysGuard
_launch=Meta+Esc,none,Launch KSysGuard

[plasmashell]
_k_friendly_name=Plasma
activate task manager entry 1=Meta+1,Meta+1,Activate Task Manager Entry 1
activate task manager entry 10=Meta+0,Meta+0,Activate Task Manager Entry 10
activate task manager entry 2=Meta+2,Meta+2,Activate Task Manager Entry 2
activate task manager entry 3=Meta+3,Meta+3,Activate Task Manager Entry 3
activate task manager entry 4=Meta+4,Meta+4,Activate Task Manager Entry 4
activate task manager entry 5=Meta+5,Meta+5,Activate Task Manager Entry 5
activate task manager entry 6=Meta+6,Meta+6,Activate Task Manager Entry 6
activate task manager entry 7=Meta+7,Meta+7,Activate Task Manager Entry 7
activate task manager entry 8=Meta+8,Meta+8,Activate Task Manager Entry 8
activate task manager entry 9=Meta+9,Meta+9,Activate Task Manager Entry 9
activate widget 45=Alt+F1,none,Activate Application Menu Widget
clear-history=none,none,Clear Clipboard History
clipboard_action=Ctrl+Alt+X,Ctrl+Alt+X,Enable Clipboard Actions
cycleNextAction=none,none,Next History Item
cyclePrevAction=none,none,Previous History Item
edit_clipboard=none,none,Edit Contents...
manage activities=Meta+Q,Meta+Q,Activities...
next activity=Meta+Tab,none,Walk through activities
previous activity=Meta+Shift+Tab,none,Walk through activities (Reverse)
repeat_action=Ctrl+Alt+R,Ctrl+Alt+R,Manually Invoke Action on Current Clipboard
show dashboard=Meta+D,Ctrl+F12,Show Desktop
show-barcode=none,none,Show Barcode...
show-on-mouse-pos=none,none,Open Klipper at Mouse Position
stop current activity=Meta+S,Meta+S,Stop Current Activity
EOL



# KDE GLOBAL APP KEYBOARD SHORTCUTS
# this is unchanged, we should only change global hotkeys
cat > "$HOME/.config/khotkeysrc" << EOL
[Data]
DataCount=4

[Data_1]
Comment=KMenuEdit Global Shortcuts
DataCount=2
Enabled=true
Name=KMenuEdit
SystemGroup=1
Type=ACTION_DATA_GROUP

[Data_1Conditions]
Comment=
ConditionsCount=0

[Data_1_1]
Comment=Comment
Enabled=true
Name=Search
Type=SIMPLE_ACTION_DATA

[Data_1_1Actions]
ActionsCount=1

[Data_1_1Actions0]
CommandURL=http://google.com
Type=COMMAND_URL

[Data_1_1Conditions]
Comment=
ConditionsCount=0

[Data_1_1Triggers]
Comment=Simple_action
TriggersCount=1

[Data_1_1Triggers0]
Key=
Type=SHORTCUT
Uuid={d03619b6-9b3c-48cc-9d9c-a2aadb485550}

[Data_1_2]
Comment=Global keyboard shortcut to launch Konsole
Enabled=true
Name=Launch Konsole
Type=MENUENTRY_SHORTCUT_ACTION_DATA

[Data_1_2Actions]
ActionsCount=1

[Data_1_2Actions0]
CommandURL=org.kde.konsole.desktop
Type=MENUENTRY

[Data_1_2Conditions]
Comment=
ConditionsCount=0

[Data_1_2Triggers]
Comment=Simple_action
TriggersCount=1

[Data_1_2Triggers0]
Key=Ctrl+Alt+T
Type=SHORTCUT
Uuid={c33a70db-9522-4d76-ab98-413ed7341f97}

[Data_2]
Comment=This group contains various examples demonstrating most of the features of KHotkeys. (Note that this group and all its actions are disabled by default.)
DataCount=8
Enabled=false
ImportId=kde32b1
Name=Examples
SystemGroup=0
Type=ACTION_DATA_GROUP

[Data_2Conditions]
Comment=
ConditionsCount=0

[Data_2_1]
Comment=After pressing Ctrl+Alt+I, the KSIRC window will be activated, if it exists. Simple.
Enabled=false
Name=Activate KSIRC Window
Type=SIMPLE_ACTION_DATA

[Data_2_1Actions]
ActionsCount=1

[Data_2_1Actions0]
Type=ACTIVATE_WINDOW

[Data_2_1Actions0Window]
Comment=KSIRC window
WindowsCount=1

[Data_2_1Actions0Window0]
Class=ksirc
ClassType=1
Comment=KSIRC
Role=
RoleType=0
Title=
TitleType=0
Type=SIMPLE
WindowTypes=33

[Data_2_1Conditions]
Comment=
ConditionsCount=0

[Data_2_1Triggers]
Comment=Simple_action
TriggersCount=1

[Data_2_1Triggers0]
Key=Ctrl+Alt+I
Type=SHORTCUT
Uuid={72ca13ca-3a8b-4ecd-81bd-c608394960bb}

[Data_2_2]
Comment=After pressing Alt+Ctrl+H the input of 'Hello' will be simulated, as if you typed it.  This is especially useful if you have call to frequently type a word (for instance, 'unsigned').  Every keypress in the input is separated by a colon ':'. Note that the keypresses literally mean keypresses, so you have to write what you would press on the keyboard. In the table below, the left column shows the input and the right column shows what to type.\n\n"enter" (i.e. new line)                Enter or Return\na (i.e. small a)                          A\nA (i.e. capital a)                       Shift+A\n: (colon)                                  Shift+;\n' '  (space)                              Space
Enabled=false
Name=Type 'Hello'
Type=SIMPLE_ACTION_DATA

[Data_2_2Actions]
ActionsCount=1

[Data_2_2Actions0]
DestinationWindow=2
Input=Shift+H:E:L:L:O\n
Type=KEYBOARD_INPUT

[Data_2_2Conditions]
Comment=
ConditionsCount=0

[Data_2_2Triggers]
Comment=Simple_action
TriggersCount=1

[Data_2_2Triggers0]
Key=Ctrl+Alt+H
Type=SHORTCUT
Uuid={8806f2e8-cb24-4f9b-af33-7e6dac24b247}

[Data_2_3]
Comment=This action runs Konsole, after pressing Ctrl+Alt+T.
Enabled=false
Name=Run Konsole
Type=SIMPLE_ACTION_DATA

[Data_2_3Actions]
ActionsCount=1

[Data_2_3Actions0]
CommandURL=konsole
Type=COMMAND_URL

[Data_2_3Conditions]
Comment=
ConditionsCount=0

[Data_2_3Triggers]
Comment=Simple_action
TriggersCount=1

[Data_2_3Triggers0]
Key=Ctrl+Alt+T
Type=SHORTCUT
Uuid={29cdaae1-c278-4609-82df-4c05a5f45af1}

[Data_2_4]
Comment=Read the comment on the "Type 'Hello'" action first.\n\nQt Designer uses Ctrl+F4 for closing windows.  In KDE, however, Ctrl+F4 is the shortcut for going to virtual desktop 4, so this shortcut does not work in Qt Designer.  Further, Qt Designer does not use KDE's standard Ctrl+W for closing the window.\n\nThis problem can be solved by remapping Ctrl+W to Ctrl+F4 when the active window is Qt Designer. When Qt Designer is active, every time Ctrl+W is pressed, Ctrl+F4 will be sent to Qt Designer instead. In other applications, the effect of Ctrl+W is unchanged.\n\nWe now need to specify three things: A new shortcut trigger on 'Ctrl+W', a new keyboard input action sending Ctrl+F4, and a new condition that the active window is Qt Designer.\nQt Designer seems to always have title 'Qt Designer by Trolltech', so the condition will check for the active window having that title.
Enabled=false
Name=Remap Ctrl+W to Ctrl+F4 in Qt Designer
Type=GENERIC_ACTION_DATA

[Data_2_4Actions]
ActionsCount=1

[Data_2_4Actions0]
DestinationWindow=2
Input=Ctrl+F4
Type=KEYBOARD_INPUT

[Data_2_4Conditions]
Comment=
ConditionsCount=1

[Data_2_4Conditions0]
Type=ACTIVE_WINDOW

[Data_2_4Conditions0Window]
Comment=Qt Designer
WindowsCount=1

[Data_2_4Conditions0Window0]
Class=
ClassType=0
Comment=
Role=
RoleType=0
Title=Qt Designer by Trolltech
TitleType=2
Type=SIMPLE
WindowTypes=33

[Data_2_4Triggers]
Comment=
TriggersCount=1

[Data_2_4Triggers0]
Key=Ctrl+W
Type=SHORTCUT
Uuid={a756bdec-d89a-4823-acfc-e32d0b63c348}

[Data_2_5]
Comment=By pressing Alt+Ctrl+W a D-Bus call will be performed that will show the minicli. You can use any kind of D-Bus call, just like using the command line 'qdbus' tool.
Enabled=false
Name=Perform D-Bus call 'qdbus org.kde.krunner /App display'
Type=SIMPLE_ACTION_DATA

[Data_2_5Actions]
ActionsCount=1

[Data_2_5Actions0]
Arguments=
Call=popupExecuteCommand
RemoteApp=org.kde.krunner
RemoteObj=/App
Type=DBUS

[Data_2_5Conditions]
Comment=
ConditionsCount=0

[Data_2_5Triggers]
Comment=Simple_action
TriggersCount=1

[Data_2_5Triggers0]
Key=Ctrl+Alt+W
Type=SHORTCUT
Uuid={c8a584cb-3dcd-4a89-b178-2f0a512c110d}

[Data_2_6]
Comment=Read the comment on the "Type 'Hello'" action first.\n\nJust like the "Type 'Hello'" action, this one simulates keyboard input, specifically, after pressing Ctrl+Alt+B, it sends B to XMMS (B in XMMS jumps to the next song). The 'Send to specific window' checkbox is checked and a window with its class containing 'XMMS_Player' is specified; this will make the input always be sent to this window. This way, you can control XMMS even if, for instance, it is on a different virtual desktop.\n\n(Run 'xprop' and click on the XMMS window and search for WM_CLASS to see 'XMMS_Player').
Enabled=false
Name=Next in XMMS
Type=SIMPLE_ACTION_DATA

[Data_2_6Actions]
ActionsCount=1

[Data_2_6Actions0]
DestinationWindow=1
Input=B
Type=KEYBOARD_INPUT

[Data_2_6Actions0DestinationWindow]
Comment=XMMS window
WindowsCount=1

[Data_2_6Actions0DestinationWindow0]
Class=XMMS_Player
ClassType=1
Comment=XMMS Player window
Role=
RoleType=0
Title=
TitleType=0
Type=SIMPLE
WindowTypes=33

[Data_2_6Conditions]
Comment=
ConditionsCount=0

[Data_2_6Triggers]
Comment=Simple_action
TriggersCount=1

[Data_2_6Triggers0]
Key=Ctrl+Alt+B
Type=SHORTCUT
Uuid={9398ed3d-458b-4ce8-8b9e-283573d46ce8}

[Data_2_7]
Comment=Konqueror in KDE3.1 has tabs, and now you can also have gestures.\n\nJust press the middle mouse button and start drawing one of the gestures, and after you are finished, release the mouse button. If you only need to paste the selection, it still works, just click the middle mouse button. (You can change the mouse button to use in the global settings).\n\nRight now, there are the following gestures available:\nmove right and back left - Forward (Alt+Right)\nmove left and back right - Back (Alt+Left)\nmove up and back down  - Up (Alt+Up)\ncircle anticlockwise - Reload (F5)\n\nThe gesture shapes can be entered by performing them in the configuration dialog. You can also look at your numeric pad to help you: gestures are recognized like a 3x3 grid of fields, numbered 1 to 9.\n\nNote that you must perform exactly the gesture to trigger the action. Because of this, it is possible to enter more gestures for the action. You should try to avoid complicated gestures where you change the direction of mouse movement more than once.  For instance, 45654 or 74123 are simple to perform, but 1236987 may be already quite difficult.\n\nThe conditions for all gestures are defined in this group. All these gestures are active only if the active window is Konqueror (class contains 'konqueror').
DataCount=4
Enabled=false
Name=Konqi Gestures
SystemGroup=0
Type=ACTION_DATA_GROUP

[Data_2_7Conditions]
Comment=Konqueror window
ConditionsCount=1

[Data_2_7Conditions0]
Type=ACTIVE_WINDOW

[Data_2_7Conditions0Window]
Comment=Konqueror
WindowsCount=1

[Data_2_7Conditions0Window0]
Class=konqueror
ClassType=1
Comment=Konqueror
Role=
RoleType=0
Title=
TitleType=0
Type=SIMPLE
WindowTypes=33

[Data_2_7_1]
Comment=
Enabled=false
Name=Back
Type=SIMPLE_ACTION_DATA

[Data_2_7_1Actions]
ActionsCount=1

[Data_2_7_1Actions0]
DestinationWindow=2
Input=Alt+Left
Type=KEYBOARD_INPUT

[Data_2_7_1Conditions]
Comment=
ConditionsCount=0

[Data_2_7_1Triggers]
Comment=Gesture_triggers
TriggersCount=3

[Data_2_7_1Triggers0]
GesturePointData=0,0.0625,1,1,0.5,0.0625,0.0625,1,0.875,0.5,0.125,0.0625,1,0.75,0.5,0.1875,0.0625,1,0.625,0.5,0.25,0.0625,1,0.5,0.5,0.3125,0.0625,1,0.375,0.5,0.375,0.0625,1,0.25,0.5,0.4375,0.0625,1,0.125,0.5,0.5,0.0625,0,0,0.5,0.5625,0.0625,0,0.125,0.5,0.625,0.0625,0,0.25,0.5,0.6875,0.0625,0,0.375,0.5,0.75,0.0625,0,0.5,0.5,0.8125,0.0625,0,0.625,0.5,0.875,0.0625,0,0.75,0.5,0.9375,0.0625,0,0.875,0.5,1,0,0,1,0.5
Type=GESTURE

[Data_2_7_1Triggers1]
GesturePointData=0,0.0833333,1,0.5,0.5,0.0833333,0.0833333,1,0.375,0.5,0.166667,0.0833333,1,0.25,0.5,0.25,0.0833333,1,0.125,0.5,0.333333,0.0833333,0,0,0.5,0.416667,0.0833333,0,0.125,0.5,0.5,0.0833333,0,0.25,0.5,0.583333,0.0833333,0,0.375,0.5,0.666667,0.0833333,0,0.5,0.5,0.75,0.0833333,0,0.625,0.5,0.833333,0.0833333,0,0.75,0.5,0.916667,0.0833333,0,0.875,0.5,1,0,0,1,0.5
Type=GESTURE

[Data_2_7_1Triggers2]
GesturePointData=0,0.0833333,1,1,0.5,0.0833333,0.0833333,1,0.875,0.5,0.166667,0.0833333,1,0.75,0.5,0.25,0.0833333,1,0.625,0.5,0.333333,0.0833333,1,0.5,0.5,0.416667,0.0833333,1,0.375,0.5,0.5,0.0833333,1,0.25,0.5,0.583333,0.0833333,1,0.125,0.5,0.666667,0.0833333,0,0,0.5,0.75,0.0833333,0,0.125,0.5,0.833333,0.0833333,0,0.25,0.5,0.916667,0.0833333,0,0.375,0.5,1,0,0,0.5,0.5
Type=GESTURE

[Data_2_7_2]
Comment=
Enabled=false
Name=Forward
Type=SIMPLE_ACTION_DATA

[Data_2_7_2Actions]
ActionsCount=1

[Data_2_7_2Actions0]
DestinationWindow=2
Input=Alt+Right
Type=KEYBOARD_INPUT

[Data_2_7_2Conditions]
Comment=
ConditionsCount=0

[Data_2_7_2Triggers]
Comment=Gesture_triggers
TriggersCount=3

[Data_2_7_2Triggers0]
GesturePointData=0,0.0625,0,0,0.5,0.0625,0.0625,0,0.125,0.5,0.125,0.0625,0,0.25,0.5,0.1875,0.0625,0,0.375,0.5,0.25,0.0625,0,0.5,0.5,0.3125,0.0625,0,0.625,0.5,0.375,0.0625,0,0.75,0.5,0.4375,0.0625,0,0.875,0.5,0.5,0.0625,1,1,0.5,0.5625,0.0625,1,0.875,0.5,0.625,0.0625,1,0.75,0.5,0.6875,0.0625,1,0.625,0.5,0.75,0.0625,1,0.5,0.5,0.8125,0.0625,1,0.375,0.5,0.875,0.0625,1,0.25,0.5,0.9375,0.0625,1,0.125,0.5,1,0,0,0,0.5
Type=GESTURE

[Data_2_7_2Triggers1]
GesturePointData=0,0.0833333,0,0.5,0.5,0.0833333,0.0833333,0,0.625,0.5,0.166667,0.0833333,0,0.75,0.5,0.25,0.0833333,0,0.875,0.5,0.333333,0.0833333,1,1,0.5,0.416667,0.0833333,1,0.875,0.5,0.5,0.0833333,1,0.75,0.5,0.583333,0.0833333,1,0.625,0.5,0.666667,0.0833333,1,0.5,0.5,0.75,0.0833333,1,0.375,0.5,0.833333,0.0833333,1,0.25,0.5,0.916667,0.0833333,1,0.125,0.5,1,0,0,0,0.5
Type=GESTURE

[Data_2_7_2Triggers2]
GesturePointData=0,0.0833333,0,0,0.5,0.0833333,0.0833333,0,0.125,0.5,0.166667,0.0833333,0,0.25,0.5,0.25,0.0833333,0,0.375,0.5,0.333333,0.0833333,0,0.5,0.5,0.416667,0.0833333,0,0.625,0.5,0.5,0.0833333,0,0.75,0.5,0.583333,0.0833333,0,0.875,0.5,0.666667,0.0833333,1,1,0.5,0.75,0.0833333,1,0.875,0.5,0.833333,0.0833333,1,0.75,0.5,0.916667,0.0833333,1,0.625,0.5,1,0,0,0.5,0.5
Type=GESTURE

[Data_2_7_3]
Comment=
Enabled=false
Name=Up
Type=SIMPLE_ACTION_DATA

[Data_2_7_3Actions]
ActionsCount=1

[Data_2_7_3Actions0]
DestinationWindow=2
Input=Alt+Up
Type=KEYBOARD_INPUT

[Data_2_7_3Conditions]
Comment=
ConditionsCount=0

[Data_2_7_3Triggers]
Comment=Gesture_triggers
TriggersCount=3

[Data_2_7_3Triggers0]
GesturePointData=0,0.0625,-0.5,0.5,1,0.0625,0.0625,-0.5,0.5,0.875,0.125,0.0625,-0.5,0.5,0.75,0.1875,0.0625,-0.5,0.5,0.625,0.25,0.0625,-0.5,0.5,0.5,0.3125,0.0625,-0.5,0.5,0.375,0.375,0.0625,-0.5,0.5,0.25,0.4375,0.0625,-0.5,0.5,0.125,0.5,0.0625,0.5,0.5,0,0.5625,0.0625,0.5,0.5,0.125,0.625,0.0625,0.5,0.5,0.25,0.6875,0.0625,0.5,0.5,0.375,0.75,0.0625,0.5,0.5,0.5,0.8125,0.0625,0.5,0.5,0.625,0.875,0.0625,0.5,0.5,0.75,0.9375,0.0625,0.5,0.5,0.875,1,0,0,0.5,1
Type=GESTURE

[Data_2_7_3Triggers1]
GesturePointData=0,0.0833333,-0.5,0.5,1,0.0833333,0.0833333,-0.5,0.5,0.875,0.166667,0.0833333,-0.5,0.5,0.75,0.25,0.0833333,-0.5,0.5,0.625,0.333333,0.0833333,-0.5,0.5,0.5,0.416667,0.0833333,-0.5,0.5,0.375,0.5,0.0833333,-0.5,0.5,0.25,0.583333,0.0833333,-0.5,0.5,0.125,0.666667,0.0833333,0.5,0.5,0,0.75,0.0833333,0.5,0.5,0.125,0.833333,0.0833333,0.5,0.5,0.25,0.916667,0.0833333,0.5,0.5,0.375,1,0,0,0.5,0.5
Type=GESTURE

[Data_2_7_3Triggers2]
GesturePointData=0,0.0833333,-0.5,0.5,0.5,0.0833333,0.0833333,-0.5,0.5,0.375,0.166667,0.0833333,-0.5,0.5,0.25,0.25,0.0833333,-0.5,0.5,0.125,0.333333,0.0833333,0.5,0.5,0,0.416667,0.0833333,0.5,0.5,0.125,0.5,0.0833333,0.5,0.5,0.25,0.583333,0.0833333,0.5,0.5,0.375,0.666667,0.0833333,0.5,0.5,0.5,0.75,0.0833333,0.5,0.5,0.625,0.833333,0.0833333,0.5,0.5,0.75,0.916667,0.0833333,0.5,0.5,0.875,1,0,0,0.5,1
Type=GESTURE

[Data_2_7_4]
Comment=
Enabled=false
Name=Reload
Type=SIMPLE_ACTION_DATA

[Data_2_7_4Actions]
ActionsCount=1

[Data_2_7_4Actions0]
DestinationWindow=2
Input=F5
Type=KEYBOARD_INPUT

[Data_2_7_4Conditions]
Comment=
ConditionsCount=0

[Data_2_7_4Triggers]
Comment=Gesture_triggers
TriggersCount=3

[Data_2_7_4Triggers0]
GesturePointData=0,0.03125,0,0,1,0.03125,0.03125,0,0.125,1,0.0625,0.03125,0,0.25,1,0.09375,0.03125,0,0.375,1,0.125,0.03125,0,0.5,1,0.15625,0.03125,0,0.625,1,0.1875,0.03125,0,0.75,1,0.21875,0.03125,0,0.875,1,0.25,0.03125,-0.5,1,1,0.28125,0.03125,-0.5,1,0.875,0.3125,0.03125,-0.5,1,0.75,0.34375,0.03125,-0.5,1,0.625,0.375,0.03125,-0.5,1,0.5,0.40625,0.03125,-0.5,1,0.375,0.4375,0.03125,-0.5,1,0.25,0.46875,0.03125,-0.5,1,0.125,0.5,0.03125,1,1,0,0.53125,0.03125,1,0.875,0,0.5625,0.03125,1,0.75,0,0.59375,0.03125,1,0.625,0,0.625,0.03125,1,0.5,0,0.65625,0.03125,1,0.375,0,0.6875,0.03125,1,0.25,0,0.71875,0.03125,1,0.125,0,0.75,0.03125,0.5,0,0,0.78125,0.03125,0.5,0,0.125,0.8125,0.03125,0.5,0,0.25,0.84375,0.03125,0.5,0,0.375,0.875,0.03125,0.5,0,0.5,0.90625,0.03125,0.5,0,0.625,0.9375,0.03125,0.5,0,0.75,0.96875,0.03125,0.5,0,0.875,1,0,0,0,1
Type=GESTURE

[Data_2_7_4Triggers1]
GesturePointData=0,0.0277778,0,0,1,0.0277778,0.0277778,0,0.125,1,0.0555556,0.0277778,0,0.25,1,0.0833333,0.0277778,0,0.375,1,0.111111,0.0277778,0,0.5,1,0.138889,0.0277778,0,0.625,1,0.166667,0.0277778,0,0.75,1,0.194444,0.0277778,0,0.875,1,0.222222,0.0277778,-0.5,1,1,0.25,0.0277778,-0.5,1,0.875,0.277778,0.0277778,-0.5,1,0.75,0.305556,0.0277778,-0.5,1,0.625,0.333333,0.0277778,-0.5,1,0.5,0.361111,0.0277778,-0.5,1,0.375,0.388889,0.0277778,-0.5,1,0.25,0.416667,0.0277778,-0.5,1,0.125,0.444444,0.0277778,1,1,0,0.472222,0.0277778,1,0.875,0,0.5,0.0277778,1,0.75,0,0.527778,0.0277778,1,0.625,0,0.555556,0.0277778,1,0.5,0,0.583333,0.0277778,1,0.375,0,0.611111,0.0277778,1,0.25,0,0.638889,0.0277778,1,0.125,0,0.666667,0.0277778,0.5,0,0,0.694444,0.0277778,0.5,0,0.125,0.722222,0.0277778,0.5,0,0.25,0.75,0.0277778,0.5,0,0.375,0.777778,0.0277778,0.5,0,0.5,0.805556,0.0277778,0.5,0,0.625,0.833333,0.0277778,0.5,0,0.75,0.861111,0.0277778,0.5,0,0.875,0.888889,0.0277778,0,0,1,0.916667,0.0277778,0,0.125,1,0.944444,0.0277778,0,0.25,1,0.972222,0.0277778,0,0.375,1,1,0,0,0.5,1
Type=GESTURE

[Data_2_7_4Triggers2]
GesturePointData=0,0.0277778,0.5,0,0.5,0.0277778,0.0277778,0.5,0,0.625,0.0555556,0.0277778,0.5,0,0.75,0.0833333,0.0277778,0.5,0,0.875,0.111111,0.0277778,0,0,1,0.138889,0.0277778,0,0.125,1,0.166667,0.0277778,0,0.25,1,0.194444,0.0277778,0,0.375,1,0.222222,0.0277778,0,0.5,1,0.25,0.0277778,0,0.625,1,0.277778,0.0277778,0,0.75,1,0.305556,0.0277778,0,0.875,1,0.333333,0.0277778,-0.5,1,1,0.361111,0.0277778,-0.5,1,0.875,0.388889,0.0277778,-0.5,1,0.75,0.416667,0.0277778,-0.5,1,0.625,0.444444,0.0277778,-0.5,1,0.5,0.472222,0.0277778,-0.5,1,0.375,0.5,0.0277778,-0.5,1,0.25,0.527778,0.0277778,-0.5,1,0.125,0.555556,0.0277778,1,1,0,0.583333,0.0277778,1,0.875,0,0.611111,0.0277778,1,0.75,0,0.638889,0.0277778,1,0.625,0,0.666667,0.0277778,1,0.5,0,0.694444,0.0277778,1,0.375,0,0.722222,0.0277778,1,0.25,0,0.75,0.0277778,1,0.125,0,0.777778,0.0277778,0.5,0,0,0.805556,0.0277778,0.5,0,0.125,0.833333,0.0277778,0.5,0,0.25,0.861111,0.0277778,0.5,0,0.375,0.888889,0.0277778,0.5,0,0.5,0.916667,0.0277778,0.5,0,0.625,0.944444,0.0277778,0.5,0,0.75,0.972222,0.0277778,0.5,0,0.875,1,0,0,0,1
Type=GESTURE

[Data_2_8]
Comment=After pressing Win+E (Tux+E) a WWW browser will be launched, and it will open http://www.kde.org . You may run all kind of commands you can run in minicli (Alt+F2).
Enabled=false
Name=Go to KDE Website
Type=SIMPLE_ACTION_DATA

[Data_2_8Actions]
ActionsCount=1

[Data_2_8Actions0]
CommandURL=http://www.kde.org
Type=COMMAND_URL

[Data_2_8Conditions]
Comment=
ConditionsCount=0

[Data_2_8Triggers]
Comment=Simple_action
TriggersCount=1

[Data_2_8Triggers0]
Key=Meta+E
Type=SHORTCUT
Uuid={82dd4486-4928-48a3-83d0-b09660a32dd6}

[Data_3]
Comment=Shortcuts for taking screenshots
DataCount=4
Enabled=true
ImportId=spectacle
Name=Screenshots
SystemGroup=0
Type=ACTION_DATA_GROUP

[Data_3Conditions]
Comment=
ConditionsCount=0

[Data_3_1]
Comment=Start the screenshot tool and show the GUI
Enabled=true
Name=Start Screenshot Tool
Type=SIMPLE_ACTION_DATA

[Data_3_1Actions]
ActionsCount=1

[Data_3_1Actions0]
Arguments=
Call=StartAgent
RemoteApp=org.kde.Spectacle
RemoteObj=/
Type=DBUS

[Data_3_1Conditions]
Comment=
ConditionsCount=0

[Data_3_1Triggers]
Comment=Simple_action
TriggersCount=1

[Data_3_1Triggers0]
Key=Print
Type=SHORTCUT
Uuid={1e25b461-3ddd-440f-9038-bbea108b0303}

[Data_3_2]
Comment=Take a full screen (all monitors) screenshot and save it
Enabled=true
Name=Take Full Screen Screenshot
Type=SIMPLE_ACTION_DATA

[Data_3_2Actions]
ActionsCount=1

[Data_3_2Actions0]
Arguments=false
Call=FullScreen
RemoteApp=org.kde.Spectacle
RemoteObj=/
Type=DBUS

[Data_3_2Conditions]
Comment=
ConditionsCount=0

[Data_3_2Triggers]
Comment=Simple_action
TriggersCount=1

[Data_3_2Triggers0]
Key=Shift+Print
Type=SHORTCUT
Uuid={b8340e9f-cfdb-4b86-b98f-171948437341}

[Data_3_3]
Comment=Take a screenshot of the currently active window and save it
Enabled=true
Name=Take Active Window Screenshot
Type=SIMPLE_ACTION_DATA

[Data_3_3Actions]
ActionsCount=1

[Data_3_3Actions0]
Arguments=true false
Call=ActiveWindow
RemoteApp=org.kde.Spectacle
RemoteObj=/
Type=DBUS

[Data_3_3Conditions]
Comment=
ConditionsCount=0

[Data_3_3Triggers]
Comment=Simple_action
TriggersCount=1

[Data_3_3Triggers0]
Key=Ctrl+Print
Type=SHORTCUT
Uuid={c3d9528b-5c2b-4c46-adea-f4e821e8ce7a}

[Data_3_4]
Comment=Take a screenshot of a rectangular region you specify and save it
Enabled=true
Name=Take Rectangular Region Screenshot
Type=SIMPLE_ACTION_DATA

[Data_3_4Actions]
ActionsCount=1

[Data_3_4Actions0]
Arguments=true
Call=RectangularRegion
RemoteApp=org.kde.Spectacle
RemoteObj=/
Type=DBUS

[Data_3_4Conditions]
Comment=
ConditionsCount=0

[Data_3_4Triggers]
Comment=Simple_action
TriggersCount=1

[Data_3_4Triggers0]
Key=Ctrl+Shift+Print
Type=SHORTCUT
Uuid={abe80e75-17a4-4b1a-8e55-9e17a0b5abed}

[Data_4]
Comment=Basic Konqueror gestures.
DataCount=14
Enabled=true
ImportId=konqueror_gestures_kde321
Name=Konqueror Gestures
SystemGroup=0
Type=ACTION_DATA_GROUP

[Data_4Conditions]
Comment=Konqueror window
ConditionsCount=1

[Data_4Conditions0]
Type=ACTIVE_WINDOW

[Data_4Conditions0Window]
Comment=Konqueror
WindowsCount=1

[Data_4Conditions0Window0]
Class=^konqueror\s
ClassType=3
Comment=Konqueror
Role=konqueror-mainwindow#1
RoleType=0
Title=file:/ - Konqueror
TitleType=0
Type=SIMPLE
WindowTypes=1

[Data_4_1]
Comment=Press, move left, release.
Enabled=true
Name=Back
Type=SIMPLE_ACTION_DATA

[Data_4_10]
Comment=Opera-style: Press, move up, release.\nNOTE: Conflicts with 'New Tab', and as such is disabled by default.
Enabled=false
Name=Stop Loading
Type=SIMPLE_ACTION_DATA

[Data_4_10Actions]
ActionsCount=1

[Data_4_10Actions0]
DestinationWindow=2
Input=Escape\n
Type=KEYBOARD_INPUT

[Data_4_10Conditions]
Comment=
ConditionsCount=0

[Data_4_10Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_10Triggers0]
GesturePointData=0,0.125,-0.5,0.5,1,0.125,0.125,-0.5,0.5,0.875,0.25,0.125,-0.5,0.5,0.75,0.375,0.125,-0.5,0.5,0.625,0.5,0.125,-0.5,0.5,0.5,0.625,0.125,-0.5,0.5,0.375,0.75,0.125,-0.5,0.5,0.25,0.875,0.125,-0.5,0.5,0.125,1,0,0,0.5,0
Type=GESTURE

[Data_4_11]
Comment=Going up in URL/directory structure.\nMozilla-style: Press, move up, move left, move up, release.
Enabled=true
Name=Up
Type=SIMPLE_ACTION_DATA

[Data_4_11Actions]
ActionsCount=1

[Data_4_11Actions0]
DestinationWindow=2
Input=Alt+Up
Type=KEYBOARD_INPUT

[Data_4_11Conditions]
Comment=
ConditionsCount=0

[Data_4_11Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_11Triggers0]
GesturePointData=0,0.0625,-0.5,1,1,0.0625,0.0625,-0.5,1,0.875,0.125,0.0625,-0.5,1,0.75,0.1875,0.0625,-0.5,1,0.625,0.25,0.0625,1,1,0.5,0.3125,0.0625,1,0.875,0.5,0.375,0.0625,1,0.75,0.5,0.4375,0.0625,1,0.625,0.5,0.5,0.0625,1,0.5,0.5,0.5625,0.0625,1,0.375,0.5,0.625,0.0625,1,0.25,0.5,0.6875,0.0625,1,0.125,0.5,0.75,0.0625,-0.5,0,0.5,0.8125,0.0625,-0.5,0,0.375,0.875,0.0625,-0.5,0,0.25,0.9375,0.0625,-0.5,0,0.125,1,0,0,0,0
Type=GESTURE

[Data_4_12]
Comment=Going up in URL/directory structure.\nOpera-style: Press, move up, move left, move up, release.\nNOTE: Conflicts with  "Activate Previous Tab", and as such is disabled by default.
Enabled=false
Name=Up #2
Type=SIMPLE_ACTION_DATA

[Data_4_12Actions]
ActionsCount=1

[Data_4_12Actions0]
DestinationWindow=2
Input=Alt+Up\n
Type=KEYBOARD_INPUT

[Data_4_12Conditions]
Comment=
ConditionsCount=0

[Data_4_12Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_12Triggers0]
GesturePointData=0,0.0625,-0.5,1,1,0.0625,0.0625,-0.5,1,0.875,0.125,0.0625,-0.5,1,0.75,0.1875,0.0625,-0.5,1,0.625,0.25,0.0625,-0.5,1,0.5,0.3125,0.0625,-0.5,1,0.375,0.375,0.0625,-0.5,1,0.25,0.4375,0.0625,-0.5,1,0.125,0.5,0.0625,1,1,0,0.5625,0.0625,1,0.875,0,0.625,0.0625,1,0.75,0,0.6875,0.0625,1,0.625,0,0.75,0.0625,1,0.5,0,0.8125,0.0625,1,0.375,0,0.875,0.0625,1,0.25,0,0.9375,0.0625,1,0.125,0,1,0,0,0,0
Type=GESTURE

[Data_4_13]
Comment=Press, move up, move right, release.
Enabled=true
Name=Activate Next Tab
Type=SIMPLE_ACTION_DATA

[Data_4_13Actions]
ActionsCount=1

[Data_4_13Actions0]
DestinationWindow=2
Input=Ctrl+.\n
Type=KEYBOARD_INPUT

[Data_4_13Conditions]
Comment=
ConditionsCount=0

[Data_4_13Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_13Triggers0]
GesturePointData=0,0.0625,-0.5,0,1,0.0625,0.0625,-0.5,0,0.875,0.125,0.0625,-0.5,0,0.75,0.1875,0.0625,-0.5,0,0.625,0.25,0.0625,-0.5,0,0.5,0.3125,0.0625,-0.5,0,0.375,0.375,0.0625,-0.5,0,0.25,0.4375,0.0625,-0.5,0,0.125,0.5,0.0625,0,0,0,0.5625,0.0625,0,0.125,0,0.625,0.0625,0,0.25,0,0.6875,0.0625,0,0.375,0,0.75,0.0625,0,0.5,0,0.8125,0.0625,0,0.625,0,0.875,0.0625,0,0.75,0,0.9375,0.0625,0,0.875,0,1,0,0,1,0
Type=GESTURE

[Data_4_14]
Comment=Press, move up, move left, release.
Enabled=true
Name=Activate Previous Tab
Type=SIMPLE_ACTION_DATA

[Data_4_14Actions]
ActionsCount=1

[Data_4_14Actions0]
DestinationWindow=2
Input=Ctrl+,
Type=KEYBOARD_INPUT

[Data_4_14Conditions]
Comment=
ConditionsCount=0

[Data_4_14Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_14Triggers0]
GesturePointData=0,0.0625,-0.5,1,1,0.0625,0.0625,-0.5,1,0.875,0.125,0.0625,-0.5,1,0.75,0.1875,0.0625,-0.5,1,0.625,0.25,0.0625,-0.5,1,0.5,0.3125,0.0625,-0.5,1,0.375,0.375,0.0625,-0.5,1,0.25,0.4375,0.0625,-0.5,1,0.125,0.5,0.0625,1,1,0,0.5625,0.0625,1,0.875,0,0.625,0.0625,1,0.75,0,0.6875,0.0625,1,0.625,0,0.75,0.0625,1,0.5,0,0.8125,0.0625,1,0.375,0,0.875,0.0625,1,0.25,0,0.9375,0.0625,1,0.125,0,1,0,0,0,0
Type=GESTURE

[Data_4_1Actions]
ActionsCount=1

[Data_4_1Actions0]
DestinationWindow=2
Input=Alt+Left
Type=KEYBOARD_INPUT

[Data_4_1Conditions]
Comment=
ConditionsCount=0

[Data_4_1Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_1Triggers0]
GesturePointData=0,0.125,1,1,0.5,0.125,0.125,1,0.875,0.5,0.25,0.125,1,0.75,0.5,0.375,0.125,1,0.625,0.5,0.5,0.125,1,0.5,0.5,0.625,0.125,1,0.375,0.5,0.75,0.125,1,0.25,0.5,0.875,0.125,1,0.125,0.5,1,0,0,0,0.5
Type=GESTURE

[Data_4_2]
Comment=Press, move down, move up, move down, release.
Enabled=true
Name=Duplicate Tab
Type=SIMPLE_ACTION_DATA

[Data_4_2Actions]
ActionsCount=1

[Data_4_2Actions0]
DestinationWindow=2
Input=Ctrl+Shift+D\n
Type=KEYBOARD_INPUT

[Data_4_2Conditions]
Comment=
ConditionsCount=0

[Data_4_2Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_2Triggers0]
GesturePointData=0,0.0416667,0.5,0.5,0,0.0416667,0.0416667,0.5,0.5,0.125,0.0833333,0.0416667,0.5,0.5,0.25,0.125,0.0416667,0.5,0.5,0.375,0.166667,0.0416667,0.5,0.5,0.5,0.208333,0.0416667,0.5,0.5,0.625,0.25,0.0416667,0.5,0.5,0.75,0.291667,0.0416667,0.5,0.5,0.875,0.333333,0.0416667,-0.5,0.5,1,0.375,0.0416667,-0.5,0.5,0.875,0.416667,0.0416667,-0.5,0.5,0.75,0.458333,0.0416667,-0.5,0.5,0.625,0.5,0.0416667,-0.5,0.5,0.5,0.541667,0.0416667,-0.5,0.5,0.375,0.583333,0.0416667,-0.5,0.5,0.25,0.625,0.0416667,-0.5,0.5,0.125,0.666667,0.0416667,0.5,0.5,0,0.708333,0.0416667,0.5,0.5,0.125,0.75,0.0416667,0.5,0.5,0.25,0.791667,0.0416667,0.5,0.5,0.375,0.833333,0.0416667,0.5,0.5,0.5,0.875,0.0416667,0.5,0.5,0.625,0.916667,0.0416667,0.5,0.5,0.75,0.958333,0.0416667,0.5,0.5,0.875,1,0,0,0.5,1
Type=GESTURE

[Data_4_3]
Comment=Press, move down, move up, release.
Enabled=true
Name=Duplicate Window
Type=SIMPLE_ACTION_DATA

[Data_4_3Actions]
ActionsCount=1

[Data_4_3Actions0]
DestinationWindow=2
Input=Ctrl+D\n
Type=KEYBOARD_INPUT

[Data_4_3Conditions]
Comment=
ConditionsCount=0

[Data_4_3Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_3Triggers0]
GesturePointData=0,0.0625,0.5,0.5,0,0.0625,0.0625,0.5,0.5,0.125,0.125,0.0625,0.5,0.5,0.25,0.1875,0.0625,0.5,0.5,0.375,0.25,0.0625,0.5,0.5,0.5,0.3125,0.0625,0.5,0.5,0.625,0.375,0.0625,0.5,0.5,0.75,0.4375,0.0625,0.5,0.5,0.875,0.5,0.0625,-0.5,0.5,1,0.5625,0.0625,-0.5,0.5,0.875,0.625,0.0625,-0.5,0.5,0.75,0.6875,0.0625,-0.5,0.5,0.625,0.75,0.0625,-0.5,0.5,0.5,0.8125,0.0625,-0.5,0.5,0.375,0.875,0.0625,-0.5,0.5,0.25,0.9375,0.0625,-0.5,0.5,0.125,1,0,0,0.5,0
Type=GESTURE

[Data_4_4]
Comment=Press, move right, release.
Enabled=true
Name=Forward
Type=SIMPLE_ACTION_DATA

[Data_4_4Actions]
ActionsCount=1

[Data_4_4Actions0]
DestinationWindow=2
Input=Alt+Right
Type=KEYBOARD_INPUT

[Data_4_4Conditions]
Comment=
ConditionsCount=0

[Data_4_4Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_4Triggers0]
GesturePointData=0,0.125,0,0,0.5,0.125,0.125,0,0.125,0.5,0.25,0.125,0,0.25,0.5,0.375,0.125,0,0.375,0.5,0.5,0.125,0,0.5,0.5,0.625,0.125,0,0.625,0.5,0.75,0.125,0,0.75,0.5,0.875,0.125,0,0.875,0.5,1,0,0,1,0.5
Type=GESTURE

[Data_4_5]
Comment=Press, move down, move half up, move right, move down, release.\n(Drawing a lowercase 'h'.)
Enabled=true
Name=Home
Type=SIMPLE_ACTION_DATA

[Data_4_5Actions]
ActionsCount=1

[Data_4_5Actions0]
DestinationWindow=2
Input=Alt+Home\n
Type=KEYBOARD_INPUT

[Data_4_5Conditions]
Comment=
ConditionsCount=0

[Data_4_5Triggers]
Comment=Gesture_triggers
TriggersCount=2

[Data_4_5Triggers0]
GesturePointData=0,0.0461748,0.5,0,0,0.0461748,0.0461748,0.5,0,0.125,0.0923495,0.0461748,0.5,0,0.25,0.138524,0.0461748,0.5,0,0.375,0.184699,0.0461748,0.5,0,0.5,0.230874,0.0461748,0.5,0,0.625,0.277049,0.0461748,0.5,0,0.75,0.323223,0.0461748,0.5,0,0.875,0.369398,0.065301,-0.25,0,1,0.434699,0.065301,-0.25,0.125,0.875,0.5,0.065301,-0.25,0.25,0.75,0.565301,0.065301,-0.25,0.375,0.625,0.630602,0.0461748,0,0.5,0.5,0.676777,0.0461748,0,0.625,0.5,0.722951,0.0461748,0,0.75,0.5,0.769126,0.0461748,0,0.875,0.5,0.815301,0.0461748,0.5,1,0.5,0.861476,0.0461748,0.5,1,0.625,0.90765,0.0461748,0.5,1,0.75,0.953825,0.0461748,0.5,1,0.875,1,0,0,1,1
Type=GESTURE

[Data_4_5Triggers1]
GesturePointData=0,0.0416667,0.5,0,0,0.0416667,0.0416667,0.5,0,0.125,0.0833333,0.0416667,0.5,0,0.25,0.125,0.0416667,0.5,0,0.375,0.166667,0.0416667,0.5,0,0.5,0.208333,0.0416667,0.5,0,0.625,0.25,0.0416667,0.5,0,0.75,0.291667,0.0416667,0.5,0,0.875,0.333333,0.0416667,-0.5,0,1,0.375,0.0416667,-0.5,0,0.875,0.416667,0.0416667,-0.5,0,0.75,0.458333,0.0416667,-0.5,0,0.625,0.5,0.0416667,0,0,0.5,0.541667,0.0416667,0,0.125,0.5,0.583333,0.0416667,0,0.25,0.5,0.625,0.0416667,0,0.375,0.5,0.666667,0.0416667,0,0.5,0.5,0.708333,0.0416667,0,0.625,0.5,0.75,0.0416667,0,0.75,0.5,0.791667,0.0416667,0,0.875,0.5,0.833333,0.0416667,0.5,1,0.5,0.875,0.0416667,0.5,1,0.625,0.916667,0.0416667,0.5,1,0.75,0.958333,0.0416667,0.5,1,0.875,1,0,0,1,1
Type=GESTURE

[Data_4_6]
Comment=Press, move right, move down, move right, release.\nMozilla-style: Press, move down, move right, release.
Enabled=true
Name=Close Tab
Type=SIMPLE_ACTION_DATA

[Data_4_6Actions]
ActionsCount=1

[Data_4_6Actions0]
DestinationWindow=2
Input=Ctrl+W\n
Type=KEYBOARD_INPUT

[Data_4_6Conditions]
Comment=
ConditionsCount=0

[Data_4_6Triggers]
Comment=Gesture_triggers
TriggersCount=2

[Data_4_6Triggers0]
GesturePointData=0,0.0625,0,0,0,0.0625,0.0625,0,0.125,0,0.125,0.0625,0,0.25,0,0.1875,0.0625,0,0.375,0,0.25,0.0625,0.5,0.5,0,0.3125,0.0625,0.5,0.5,0.125,0.375,0.0625,0.5,0.5,0.25,0.4375,0.0625,0.5,0.5,0.375,0.5,0.0625,0.5,0.5,0.5,0.5625,0.0625,0.5,0.5,0.625,0.625,0.0625,0.5,0.5,0.75,0.6875,0.0625,0.5,0.5,0.875,0.75,0.0625,0,0.5,1,0.8125,0.0625,0,0.625,1,0.875,0.0625,0,0.75,1,0.9375,0.0625,0,0.875,1,1,0,0,1,1
Type=GESTURE

[Data_4_6Triggers1]
GesturePointData=0,0.0625,0.5,0,0,0.0625,0.0625,0.5,0,0.125,0.125,0.0625,0.5,0,0.25,0.1875,0.0625,0.5,0,0.375,0.25,0.0625,0.5,0,0.5,0.3125,0.0625,0.5,0,0.625,0.375,0.0625,0.5,0,0.75,0.4375,0.0625,0.5,0,0.875,0.5,0.0625,0,0,1,0.5625,0.0625,0,0.125,1,0.625,0.0625,0,0.25,1,0.6875,0.0625,0,0.375,1,0.75,0.0625,0,0.5,1,0.8125,0.0625,0,0.625,1,0.875,0.0625,0,0.75,1,0.9375,0.0625,0,0.875,1,1,0,0,1,1
Type=GESTURE

[Data_4_7]
Comment=Press, move up, release.\nConflicts with Opera-style 'Up #2', which is disabled by default.
Enabled=true
Name=New Tab
Type=SIMPLE_ACTION_DATA

[Data_4_7Actions]
ActionsCount=1

[Data_4_7Actions0]
DestinationWindow=2
Input=Ctrl+Shift+N
Type=KEYBOARD_INPUT

[Data_4_7Conditions]
Comment=
ConditionsCount=0

[Data_4_7Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_7Triggers0]
GesturePointData=0,0.125,-0.5,0.5,1,0.125,0.125,-0.5,0.5,0.875,0.25,0.125,-0.5,0.5,0.75,0.375,0.125,-0.5,0.5,0.625,0.5,0.125,-0.5,0.5,0.5,0.625,0.125,-0.5,0.5,0.375,0.75,0.125,-0.5,0.5,0.25,0.875,0.125,-0.5,0.5,0.125,1,0,0,0.5,0
Type=GESTURE

[Data_4_8]
Comment=Press, move down, release.
Enabled=true
Name=New Window
Type=SIMPLE_ACTION_DATA

[Data_4_8Actions]
ActionsCount=1

[Data_4_8Actions0]
DestinationWindow=2
Input=Ctrl+N\n
Type=KEYBOARD_INPUT

[Data_4_8Conditions]
Comment=
ConditionsCount=0

[Data_4_8Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_8Triggers0]
GesturePointData=0,0.125,0.5,0.5,0,0.125,0.125,0.5,0.5,0.125,0.25,0.125,0.5,0.5,0.25,0.375,0.125,0.5,0.5,0.375,0.5,0.125,0.5,0.5,0.5,0.625,0.125,0.5,0.5,0.625,0.75,0.125,0.5,0.5,0.75,0.875,0.125,0.5,0.5,0.875,1,0,0,0.5,1
Type=GESTURE

[Data_4_9]
Comment=Press, move up, move down, release.
Enabled=true
Name=Reload
Type=SIMPLE_ACTION_DATA

[Data_4_9Actions]
ActionsCount=1

[Data_4_9Actions0]
DestinationWindow=2
Input=F5
Type=KEYBOARD_INPUT

[Data_4_9Conditions]
Comment=
ConditionsCount=0

[Data_4_9Triggers]
Comment=Gesture_triggers
TriggersCount=1

[Data_4_9Triggers0]
GesturePointData=0,0.0625,-0.5,0.5,1,0.0625,0.0625,-0.5,0.5,0.875,0.125,0.0625,-0.5,0.5,0.75,0.1875,0.0625,-0.5,0.5,0.625,0.25,0.0625,-0.5,0.5,0.5,0.3125,0.0625,-0.5,0.5,0.375,0.375,0.0625,-0.5,0.5,0.25,0.4375,0.0625,-0.5,0.5,0.125,0.5,0.0625,0.5,0.5,0,0.5625,0.0625,0.5,0.5,0.125,0.625,0.0625,0.5,0.5,0.25,0.6875,0.0625,0.5,0.5,0.375,0.75,0.0625,0.5,0.5,0.5,0.8125,0.0625,0.5,0.5,0.625,0.875,0.0625,0.5,0.5,0.75,0.9375,0.0625,0.5,0.5,0.875,1,0,0,0.5,1
Type=GESTURE

[Directories]
dir_pixmap[$d]

[General]
BrowserApplication[$d]
ColorScheme[$d]
Name[$d]
fixed[$d]
font[$d]
menuFont[$d]
shadeSortColumn[$d]
smallestReadableFont[$d]
toolBarFont[$d]

[Gestures]
Disabled=true
MouseButton=2
Timeout=300

[GesturesExclude]
Comment=
WindowsCount=0

[Icons]
Theme[$d]

[KDE]
ChangeCursor[$d]
ColorScheme[$d]
LookAndFeelPackage[$d]
contrast[$d]
widgetStyle[$d]

[KFileDialog Settings]
Breadcrumb Navigation[$d]

[Main]
AlreadyImported=defaults,konsole,kde32b1,spectacle,konqueror_gestures_kde321
Disabled=false
Version=2

[Paths]
Trash[$d]

[PreviewSettings]
MaximumSize[$d]
camera[$d]
file[$d]
fonts[$d]

[Voice]
Shortcut=
EOL


notify-send 'KDE Config' 'Please reboot!'

$SHELL
