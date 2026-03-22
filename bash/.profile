# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.
# See /usr/share/doc/bash/examples/startup-files for examples.
# The files are located in the bash-doc package.

# The default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Manjaro defaults:
[[ -f ~/.extend.profile ]] && . ~/.extend.profile


## Mapped this via MS Windows VM Host instead
# if [ -x `which setxkbmap` ]; then
#     setxkbmap -option 'caps:ctrl_modifier'
# fi

## Undo Caps Lock => Escape
# # These work even if Caps Lock is mapped to Control in Windows VM Host
# if [ -x `xcape` ]; then
#     # wait -t milliseconds before actioning the non-tap version
#     xcape -t 300 -e 'Caps_Lock=Escape'
#     # Win VM Host does this
#     # xcape -t 300 -e 'Alt_R=Caps_Lock'
# fi

# If running bash (then .bash_profile and .bash_logon don't exist -- only the first one to exist is read.
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -e "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# Manage path in .bashrc instead
# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi
