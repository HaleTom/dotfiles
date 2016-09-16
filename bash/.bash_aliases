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

# Allow git alias completion
source /usr/share/bash-completion/completions/git
export -f __git_complete # from /usr/share/bash-completion/completions/git

# One letter aliases
alias g="git" &&  __git_complete g _git
alias h="history"
alias j="jobs"
alias r="rake"
alias s="git s"

alias cuc=cucumber
alias tmux='TERM=xterm-256color tmux'
alias tmuxinator='TERM=xterm-256color tmuxinator'

