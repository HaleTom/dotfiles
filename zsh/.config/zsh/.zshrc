#!/bin/bash
#      ^----- get shellcheck hints based on bash
# https://github.com/koalaman/shellcheck/issues/809
# shellcheck disable=SC1090 # sourced filenames with variables


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
# End of lines added by compinstall

# https://stackoverflow.com/a/24237590/5353461
zstyle ':completion:*' matcher-list '' '+m:{[:lower:]}={[:upper:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

setopt correct  # prompt to correct spelling mistakes
setopt pipe_fail  # return right-most command's non-zero return value
setopt interactive_comments  # Allow #comment in an interactive shell
setopt posix_aliases  # Don't expand aliases overloading reserved words
# complete_in_word: If unset, the cursor is set to the end of the word if completion is started. Otherwise it stays there and completion is done from both ends.
# setopt complete_in_word # XXX how to test this?

# Run a command with bash emulation.
# For safety, alias file has bash-only:  alias as_bash=''
# Avoid: emulate bash -c '"$@"' as the $funcfiletrace line numbers go awry
# (possibly because of code reformatting)
function as_bash { emulate -LR bash; "$@"; }
function as_zsh  { emulate -LR  zsh; "$@"; }

# Set the prompt
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
# Colours: black, red, green, yellow, blue, magenta, cyan, white, [0-255]
_prompt_update_zsh () {

    # Colour slashes in the directory  https://superuser.com/q/49092/365890
    local dir_colour='%B%F{cyan}'     # bold blue
    local slash_colour='%B%F{white}'  # bold white
    local root_colour='%b%F{red}'     # red
    local reset='%f%k%b%u%s'  # reset fg, bg, bold, underline and standout to defaults
    local dir=${dir_colour}${(%):-%~}  # Initially colour prompt %~ directory

    [[ $EUID = 0 ]] && slash_colour=$root_colour
    dir=${dir//\//${slash_colour}/${dir_colour}}  # Replace / with coloured /
    dir=${dir}${reset}


    # # Allow user to set $ps1_debug to have "set -xe" continue through the prompt
    # # shellcheck disable=SC2154
    # if [[ ! -v ps1_debug ]]; then
    #     local -- - # Make shell options local to this function, restore on completion
    #     set +ex    # Don''t debug or die in setting the prompt!
    # fi
    # _timer_stop
    #

    # if _colour_enabled; then
    # export GIT_PS1_SHOWCOLORHINTS=1;

    # Select git info displayed, see /usr/share/git/git-prompt.sh for more
    export GIT_PS1_SHOWCOLORHINTS=1           # Make PS1 coloured
    export GIT_PS1_SHOWDIRTYSTATE=1           # '*'=unstaged, '+'=staged
    export GIT_PS1_SHOWSTASHSTATE=1           # '$'=stashed
    export GIT_PS1_SHOWUNTRACKEDFILES=1       # '%'=untracked
    export GIT_PS1_SHOWUPSTREAM="verbose"     # 'u='=no difference, 'u+1'=ahead by 1 commit
    export GIT_PS1_STATESEPARATOR=''          # No space between branch and index status
    export GIT_PS1_DESCRIBE_STYLE="describe"  # detached HEAD style:
    #  describe      relative to older annotated tag (v1.6.3.1-13-gdd42c2f)
    #  contains      relative to newer annotated tag (v1.6.3.2~35)
    #  branch        relative to newer tag or branch (master~4)
    #  default       exactly eatching tag

    local user_host_dir='%B%n%F{black}@%B%F{blue}%m%b%F{white}:'${dir}
    local user_host_dir='%(#.'$root_colour'.%B)%n%B%F{black}@%B%F{blue}%m%b%F{white}:'${dir}
    local jobs='%(1j.%f(%B%F{green}%j%f%b%).)'
    local exit_status='%(?..%F{white}[%F{red}%?%F{white}])'
    local percent_or_hash='%(#.'${root_colour}'.%F{yellow})%#'${reset}" "

    # '${_git_status}' is literal and replaced when option prompt_subst is set.
    # shellcheck disable=SC2154  # $_git_status not defined here
    PS1=${user_host_dir}'${_git_status}'${jobs}${exit_status}${percent_or_hash}
    # shellcheck disable=2016
    RPS1='${MODE_INDICATOR_PROMPT} %D %*'
}


# Run combined {ba,z}sh commands
as_bash source ~/.bashrc
zstyle ':completion:*:*:git:*' script /usr/share/git/completion/git-completion.zsh

# ssh: Use $USER's (and the system's) ssh known hosts file.
# https://unix.stackexchange.com/a/377765/143394
# shellcheck disable=2016  # Ignore expressions not expanding in single quotes
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

# Lines configured by zsh-newuser-install
export HISTFILE=$XDG_DATA_HOME/zsh/history
export HISTSIZE=10000
export SAVEHIST=10000
setopt append_history auto_cd beep extended_glob no_clobber no_match notify prompt_subst
# notify: Report the status of background jobs immediately, rather than waiting until just before printing a prompt.

# End of lines configured by zsh-newuser-install

# zsh environment variables
READNULLCMD=less  # have "< file" be piped to less

_source_files <<DOTFILES
    # $XDG_DATA_HOME/fzf/.fzf.zsh  # It magically just works !??!
    /usr/share/fzf/key-bindings.zsh
    /usr/share/fzf/completion.zsh
    $ZDOTDIR/plugins
    $ZDOTDIR/zle
DOTFILES

# Things to do after executing the last command
precmd_zsh_hook () {
    # Allow for a simple prompt for copy / paste examples
    [[ -v ps1 ]] && { _simple_prompt; unset RPS1; return 0; }
    _git_status_gen  # Update the prompt's git component
}

# Setup $PROMPT
# Couldn't get willghatch/zsh-hooks to work here.
# Try to use it instead of add-zsh-hook as it support zle hooks also
add-zsh-hook chpwd _cd_hook
add-zsh-hook precmd precmd_zsh_hook # Update $_git_status prompt string
_git_status_gen && _prompt_update_zsh  # Set the initial prompt

# Clear the namespace of bootstrap functions
unfunction _source_file _source_files

autoload -Uz compinit; compinit

# Setup direnv
# Required at end of zshrc says: https://github.com/direnv/direnv
eval "$(direnv hook zsh)"

return
##
## Null code and comments only beyond here
##

# For shell-check to see variables used
# shellcheck disable=SC2128  # Arrays without indexing
cat <<END > /dev/null 
$RPS1 $READNULLCMD $ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE $ZSH_AUTOSUGGEST_USE_ASYNC
$ZSH_HIGHLIGHT_HIGHLIGHTERS $ZSH_HIGHLIGHT_STYLES $ZSH_HIGHLIGHT_PATTERNS
$ZSH_HIGHLIGHT_REGEXP $ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE $FAST_HIGHLIGHT_STYLES
END

