# $ZDOTDIR/.zshenv - this file will always be sourced.
# Used for setting user's environment variables.
# It should not contain commands that produce output or assume the shell is attached to a tty.

# It is sourced before the login shell files:
# /etc/zsh/zprofile, /etc/profile and $ZDOTDIR/.zprofile (in that order)
# Only /etc/zsh/zshenv is sourced prior.

# If $ZDOTDIR is not set, $HOME is used instead.
# Dotfiles has:  .zshenv -> .config/zsh/.zshenv
export ZDOTDIR=$HOME/.config/zsh

#
# XDG vars should probably be setup from here.
# Split check from setup?
