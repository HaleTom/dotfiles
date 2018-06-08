# The following lines were added by compinstall
#
# zstyle ':completion:*' auto-description 'specify %d'
# zstyle ':completion:*' completer _list _expand _complete _ignored _match _correct _approximate _prefix
# zstyle ':completion:*' expand prefix suffix
# zstyle ':completion:*' file-sort name
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' ignore-parents parent pwd .. directory
# zstyle ':completion:*' insert-unambiguous true
# zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'm:{[:lower:]}={[:upper:]}'
# zstyle ':completion:*' menu select=4
# zstyle ':completion:*' original true
# zstyle ':completion:*' preserve-prefix '//[^/]##/'
# # causes: /home/ravi/.config/zsh/.zshrc:15: no matches found: (%l)%s
# # zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p (%l)%s
# zstyle ':completion:*' special-dirs true
# zstyle ':completion:*' verbose true
# zstyle :compinstall filename '/home/ravi/.config/zsh/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

zstyle ':completion:*:*:git:*' script /usr/share/git/completion/git-completion.zsh

# ssh: use my (and the system's) ssh known hosts file.
# https://unix.stackexchange.com/a/377765/143394
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# https://wiki.archlinux.org/index.php/Zsh#Help_command
unalias run-help
alias help=run-help
autoload -Uz run-help
autoload -Uz run-help-git
autoload -Uz run-help-ip
autoload -Uz run-help-openssl
autoload -Uz run-help-p4
autoload -Uz run-help-sudo
autoload -Uz run-help-svk
autoload -Uz run-help-svn

# Ensure zsh knows about compdef via compinit before requiring it via .bashrc:
source ~/.bashrc

# Lines configured by zsh-newuser-install
HISTFILE=~/.config/zsh/history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory autocd beep extendedglob nomatch notify
bindkey -v
# End of lines configured by zsh-newuser-install

# Set the prompt
PS1='%B%n%b@%B%F{blue}%m%b%F{white}:%B%F{cyan}%~%(0?.. %F{white}[%F{red}%?% %F{white}])%F{yellow}%b%# %F{reset}'
RPS1='%D %*'

# Move these to where they will work!!
bindkey '^_' undo
bindkey '^Y' redo
