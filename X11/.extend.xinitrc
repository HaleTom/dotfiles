#!/bin/sh

#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)
#

# export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export GTK2_RC_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkrc-2.0" 
export GTK_CSD=1

DEFAULT_SESSION=xfce4-session

#
# I've disabled tap-to-click as some were still getting through.
#

# input set-prop 'ELAN1300:00 04F3:3028 Touchpad xx' "libinput Disable While Typing Enabled" 1 2>/dev/null

# Synaptics disable tapping and scrolling for 0.5 seconds after last keypress
# https://wiki.archlinux.org/index.php/Touchpad_Synaptics#Using_syndaemon
# syndaemon -i 0.5 -t -K -R -d
