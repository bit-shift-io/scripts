#!/bin/bash


echo "installing..."
../util.sh -i dosbox-staging

mkdir -p $HOME/Games/dosbox
mkdir -p $HOME/.config/dosbox

echo "config..."
tee $HOME/.config/dosbox/dosbox-staging.conf > /dev/null << EOL
[sdl]
output              = opengl
texture_renderer    = auto
display             = 0
fullscreen          = false
fullresolution      = desktop
windowresolution    = default
window_position     = auto
window_decorations  = true
window_titlebar     = program=name dosbox=auto cycles=on mouse=full
transparency        = 0
host_rate           = auto
vsync               = auto
vsync_skip          = 0
presentation_mode   = auto
waitonerror         = true
priority            = auto auto
mute_when_inactive  = false
pause_when_inactive = false
mapperfile          = mapper-sdl2-0.82.2.map
screensaver         = auto
[dosbox]
language                    =
machine                     = svga_s3
memsize                     = 16
mcb_fault_strategy          = repair
vmemsize                    = auto
vmem_delay                  = off
dos_rate                    = default
vesa_modes                  = compatible
vga_8dot_font               = false
vga_render_per_scanline     = true
speed_mods                  = true
autoexec_section            = join
automount                   = true
startup_verbosity           = auto
allow_write_protected_files = true
shell_config_shortcuts      = true
[render]
glshader           = crt-auto
aspect             = auto
integer_scaling    = auto
viewport           = fit
monochrome_palette = amber
cga_colors         = default
[composite]
composite   = auto
era         = auto
hue         = 0
saturation  = 100
contrast    = 100
brightness  = 0
convergence = 0
[cpu]
core                 = auto
cputype              = auto
cpu_cycles           = 3000
cpu_cycles_protected = 60000
cpu_throttle         = false
cycleup              = 10
cycledown            = 20
[voodoo]
voodoo                    = true
voodoo_memsize            = 4
voodoo_threads            = auto
voodoo_bilinear_filtering = true
[capture]
capture_dir                   = capture
default_image_capture_formats = upscaled
[mouse]
mouse_capture             = onclick
mouse_middle_release      = true
mouse_multi_display_aware = true
mouse_sensitivity         = 100
mouse_raw_input           = true
dos_mouse_driver          = true
dos_mouse_immediate       = false
ps2_mouse_model           = explorer
com_mouse_model           = wheel+msm
vmware_mouse              = true
virtualbox_mouse          = true
[mixer]
nosound    = false
rate       = 48000
blocksize  = 512
prebuffer  = 20
negotiate  = true
compressor = true
crossfeed  = off
reverb     = off
chorus     = off
[midi]
mididevice      = auto
midiconfig      =
mpu401          = intelligent
raw_midi_output = false
[fluidsynth]
soundfont     = default.sf2
fsynth_chorus = auto
fsynth_reverb = auto
fsynth_filter = off
[mt32]
model       = auto
romdir      =
mt32_filter = off
[sblaster]
sbtype              = sb16
sbbase              = 220
irq                 = 7
dma                 = 1
hdma                = 5
sbmixer             = true
sbwarmup            = 100
sb_filter           = modern
sb_filter_always_on = false
oplmode             = auto
opl_fadeout         = off
opl_remove_dc_bias  = false
opl_filter          = auto
cms                 = auto
cms_filter          = on
[gus]
gus        = false
gusbase    = 240
gusirq     = 5
gusdma     = 3
gus_filter = on
ultradir   = C:\ULTRASND
[imfc]
imfc        = false
imfc_base   = 2a20
imfc_irq    = 3
imfc_filter = on
[innovation]
sidmodel          = none
sidclock          = default
sidport           = 280
6581filter        = 50
8580filter        = 50
innovation_filter = off
[speaker]
pcspeaker           = impulse
pcspeaker_filter    = on
tandy               = auto
tandy_fadeout       = off
tandy_filter        = on
tandy_dac_filter    = on
lpt_dac             = none
lpt_dac_filter      = on
ps1audio            = false
ps1audio_filter     = on
ps1audio_dac_filter = on
[reelmagic]
reelmagic       = off
reelmagic_key   = auto
reelmagic_fcode = 0
[joystick]
joysticktype                = auto
timed                       = true
autofire                    = false
swap34                      = false
buttonwrap                  = false
circularinput               = false
deadzone                    = 10
use_joy_calibration_hotkeys = false
joy_x_calibration           = auto
joy_y_calibration           = auto
[serial]
serial1       = dummy
serial2       = dummy
serial3       = disabled
serial4       = disabled
phonebookfile = phonebook.txt
[dos]
xms                   = true
ems                   = true
umb                   = true
pcjr_memory_config    = expanded
ver                   = 5.0
locale_period         = modern
country               = auto
keyboardlayout        = auto
expand_shell_variable = auto
shell_history_file    = shell_history.txt
setver_table_file     =
file_locking          = true
[ipx]
ipx = false
[ethernet]
ne2000            = true
nicbase           = 300
nicirq            = 3
macaddr           = AC:DE:48:88:99:AA
tcp_port_forwards =
udp_port_forwards =
[autoexec]
mount c $HOME/Games/dosbox/
c:
dir
EOL

echo "Complete"
