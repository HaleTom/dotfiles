# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Manjaro defaults:
[[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] || [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]] || export QT_QPA_PLATFORMTHEME="qt5ct"
[[ -f ~/.extend.profile ]] && . ~/.extend.profile


## Mapped this via MS Windows VM Host instead
# if [ -x `which setxkbmap` ]; then
#     setxkbmap -option 'caps:ctrl_modifier'
# fi

# These work even if Caps Lock is mapped to Control in Windows VM Host
if [ -x `xcape` ]; then
    # wait -t milliseconds before actioning the non-tap version
    xcape -t 300 -e 'Caps_Lock=Escape'
    # Win VM Host does this
    # xcape -t 300 -e 'Alt_R=Caps_Lock'
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# Manage path in .bashrc instead
# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi
