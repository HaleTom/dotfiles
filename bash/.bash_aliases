#!/bin/bash #for-shellcheck
# This file gets sourced from .bashrc

# ls aliases
alias l="ls -bCF"         # escape non printable || columns || decorated
alias la="ls -CAFb"       # Almost all - no . and ..
alias ld="ls -dlaFb */"   # no-dereference symlinks, directory entry instead of contents
alias ll="ls -laFb"
alias ls.="ls -dbCF .[^.]?*" # Hidden files except . and .. (currend directory only)
alias lsd="ls -Abl | grep --color=never ^d"   # list only directories

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# One letter aliases
alias g="git"
alias h="history"
alias j="jobs"
alias r="rake"
alias s="git s"

# Two letters
alias gh="git logda" # Git History

alias agc="ag --color"
alias cuc=cucumber
alias tmux='TERM=xterm-256color tmux'
alias tmuxinator='TERM=xterm-256color tmuxinator'
