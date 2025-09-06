#!/bin/bash
#      ^----- get shellcheck hints based on bash
# https://github.com/koalaman/shellcheck/issues/809
# shellcheck disable=SC1090 # sourced filenames with variables

# Run a command with bash emulation.
# For safety, alias file has bash-only:  alias as_bash=''
# Avoid: emulate bash -c '"$@"' as the $funcfiletrace line numbers go awry
# (possibly because of code reformatting)
function as_bash { emulate -LR bash; "$@"; }
function as_zsh  { emulate -LR  zsh; "$@"; }

# Run combined {ba,z}sh commands; setup $XDG_* variables
as_bash source ~/.bashrc
_prompt_timer_start  # Have initial prompt show startup time from this point on

# https://wiki.archlinux.org/title/XDG_Base_Directory#:~:text=XDG_CONFIG_HOME/yarn/config%22%27-,zsh,-~/.zshrc
# compinit cache file
[ -d "$XDG_CACHE_HOME"/zsh ] || mkdir -p "$XDG_CACHE_HOME"/zsh
ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"  # compinit cache location, default == .zcompdump in $ZDOTDIR else $HOME
[[ ! -d $ZSH_COMPDUMP:h ]] && mkdir -p "$ZSH_COMPDUMP:h"  # $(dirname $ZSH_COMPDUMP)

# Runtime completion cache directory for individual commands
_completion_cache_path="$XDG_CACHE_HOME/zsh/zcompcache/"
[[ ! -d $_completion_cache_path ]] && mkdir -p "$_completion_cache_path"
zstyle ':completion:*' cache-path "$_completion_cache_path"  # Default == .zcompcache in $ZDOTDIR else $HOME
unset _completion_cache_path

# -----------------------
# Completion
# -----------------------
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html

# The following lines were added by compinstall
#
# zstyle ':completion:*' auto-description 'specify %d'
# zstyle ':completion:*' expand prefix suffix
# zstyle ':completion:*' file-sort name
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' ignore-parents parent pwd .. directory
# zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'm:{[:lower:]}={[:upper:]}'
# zstyle ':completion:*' original true
# zstyle ':completion:*' preserve-prefix '//[^/]##/'
# # causes: /home/ravi/.config/zsh/.zshrc:15: no matches found: (%l)%s
# # zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p (%l)%s
# zstyle :compinstall filename '/home/ravi/.config/zsh/.zshrc'
# End of lines added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _match _correct _approximate _prefix
zstyle ':completion:*' insert-unambiguous true
zstyle ':completion:*' menu select 2
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' verbose true
zstyle ':completion:*' use-cache on

zstyle ':completion:*' list-colors ''
# https://stackoverflow.com/a/24237590/5353461
zstyle ':completion:*' matcher-list '' '+m:{[:lower:]}={[:upper:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Include hidden (but not . ..) in file completions
zstyle ':completion:*' file-patterns '%p(D):globbed-files *(D-/):directories' '*(D):all-files'

# Include .hidden directories in completions (eg builtin cd)
_comp_options+=(globdots)

# --------------------
# Options
# --------------------
# https://zsh.sourceforge.io/Doc/Release/Options.html
setopt auto_cd extended_glob no_clobber no_match notify prompt_subst
setopt append_create  # Allow files to be created with >> redirection
setopt correct  # prompt to correct spelling mistakes
setopt pipe_fail  # return right-most command's non-zero return value
setopt interactive_comments  # Allow #comment in an interactive shell
setopt posix_aliases  # Don't expand aliases overloading reserved words
setopt ksh_glob  # Allow for matching one or more with +(x) for bash compatibility
setopt list_beep  # Beep on an ambiguous completion iff BEEP is also set (which it is by default)
setopt pipe_fail  # return right-most command's non-zero return value
setopt posix_aliases  # Don't expand aliases overloading reserved words
# notify: Report the status of background jobs immediately, rather than waiting until just before printing a prompt.

# History
HISTFILE="$XDG_STATE_HOME"/zsh/history
# Create directory for $HISTFILE if necessary
[[ ! -d ${HISTFILE%/*} ]] && mkdir -p "${HISTFILE%/*}"
export HISTSIZE=10000
export SAVEHIST=10000
setopt append_history  # Don't overwrite
setopt hist_ignore_space  # Don't store commands starting with whitespace
setopt hist_beep  # Beep in ZLE when a widget attempts to access a history entry which isn’t there.
setopt inc_append_history  # Append history immediately, not just on exit


# Set the prompt
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
# Colours: black, red, green, yellow, blue, magenta, cyan, white, [0-255]
_prompt_update_zsh () {
    # Colour slashes in the directory  https://superuser.com/q/49092/365890
    local dir_colour='%B%F{cyan}'      # Colour of non-/ characters
    local slash_colour='%B%F{yellow}'   # '/' colour
    local root_colour='%b%F{red}'      # Colour of slashes if EUID==0
    local reset='%f%k%b%u%s'  # reset fg, bg, bold, underline and standout to defaults
    local dir=${dir_colour}$(_prompt_pwd_generate)  # Initially colour quoted $PWD

    [[ $EUID = 0 ]] && slash_colour=$root_colour
    dir=${dir//\//${slash_colour}/${dir_colour}}  # Replace / with coloured /
    dir=${dir}${reset}

    # # Allow user to set $ps1_debug to have "set -xe" continue through the prompt
    # # shellcheck disable=SC2154
    # if [[ ! -v ps1_debug ]]; then
    #     local -- - # Make shell options local to this function, restore on completion
    #     set +ex    # Don''t debug or die in setting the prompt!
    # fi
    # _prompt_timer_stop
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

    # Prompt Expansion: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
    # Parameter Expansion: https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion
    local user_at='%(#.'$root_colour'.%B)%n%B%F{black}@'
    local hostname=${(%)${:-%m}};
    # %<number of characters>{$string%} tells the width of the printed characters, and includes $string literally
    # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#:~:text=%25G%20below.-,%25G,-Within%20a%20%25%7B
    local host_printable=$(fallback_to echo candify "$hostname")
    local maybe_glitch
    ((${#hostname} != ${#host_printable})) && maybe_glitch=${#hostname}
    local host="%B%F{red}%${maybe_glitch}{$host_printable%}"
    local colon_dir='%b%F{white}:'${dir}
    local jobs='%(1j.%f(%B%F{green}%j%f%b%).)'
    local exit_status='%(?.. %F{white}[%F{red}%?%F{white}])'
    local percent_or_hash='%(#.'${root_colour}'.%B%F{yellow})%#'${reset}" "

    # '${_git_status}' is literal and replaced when option prompt_subst is set.
    # shellcheck disable=SC2154  # $_git_status not defined here
    PS1=${user_at}${host}${colon_dir}'${_git_status}'${jobs}${exit_status}${percent_or_hash}

    # Set RHS prompt -- from here to end of funciton

    # No RHS prompt running inside of Midnight Commander
    if [[ $MC_SID ]]; then unset RPS1; return; fi

    # Python virtualenvwrapper calls this function via $XDG_DATA_HOME/virtualenvs/post{de,}activate
    local environment
    [[ -n ${VIRTUAL_ENV##*/} ]] && environment+="%F{blue}(venv: ${VIRTUAL_ENV##*/})%f "

    setopt local_options BASH_REMATCH
    [[ $NVM_BIN =~ ([^/]+)/bin$ ]] && environment+="%B%F{white}(node: ${BASH_REMATCH[2]})%f%b "

    # Called by $XDG_DATA_HOME/miniconda3/etc/conda/{de,}activate.d/prompt-update.sh
    # shellcheck disable=2016  # Allow literal variable
    [[ -n $CONDA_DEFAULT_ENV ]] && environment+='%F{green}(conda: $CONDA_DEFAULT_ENV)%f '

    # Add separator if environment is non-null
    [[ -n $environment ]] && environment+='%B%F{white}| %f%b'

    # shellcheck disable=2016  # Keep variables literal
    RPS1='${MODE_INDICATOR_PROMPT} '"${environment}"'${_timer_show} | %F{white}%D %*'
}

# Set the initial prompt
_git_status_gen
_prompt_update_zsh

# Setup git completion
_git_completion=$(first_sourceable \
  "/usr/share/git/completion/git-completion.zsh" \
  "/Library/Developer/CommandLineTools/usr/share/git-core/git-completion.zsh"
)
zstyle ':completion:*:*:git:*' script "$_git_completion"
unset _git_completion

# ssh: Use $USER's (and the system's) ssh known hosts file.
# https://unix.stackexchange.com/a/377765/143394
# shellcheck disable=2016  # Ignore expressions not expanding in single quotes
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'


# https://wiki.archlinux.org/index.php/Zsh#Help_command
autoload -Uz run-help
unalias run-help
alias help=run-help
autoload -Uz run-help-git
autoload -Uz run-help-ip
autoload -Uz run-help-openssl
autoload -Uz run-help-p4
autoload -Uz run-help-sudo
autoload -Uz run-help-svk
autoload -Uz run-help-svn

# End of lines configured by zsh-newuser-install

# zsh environment variables
READNULLCMD=less  # have "< file" be piped to less

source $ZDOTDIR/functions

# Source plugins
# Avoid _source_file as it sets `noalias` which seems to be restored by a zinit wait / turbo load after startup
# if setopt | grep -q noaliases ; then printf "Aliases DISabled at: "; yelp; else printf "Aliases ENabled at: "; yelp; fi
# Diagnose:  is it zsh-defer or zinit not checking then resetting the current state of option aliases?
source "$ZDOTDIR/plugins"

_source_files <<DOTFILES
    # $ZDOTDIR/plugins  # See above for aliases
    $ZDOTDIR/zle
DOTFILES
# $XDG_CONFIG_HOME/bash/aliases is sourced after plugins load to overwrite if necessary

# Allow user to set a simple prompt for capturing sample output
# by setting variable $ps1 (not $PS1)
_simple_prompt_zsh() {
    case $ps1 in
    [Xx]) # Cancel simple prompt behaviour
        unset -v ps1
        # shellcheck disable=2154,2004  # zsh
        (( ${+functions[enable_you_should_use]} )) && enable_you_should_use
        _prompt_update_zsh ;;
    "") # Set default simple prompt allowing for user laziness of `ps1=`
        PS1='%% ' ;;
    *) # User has set explicit prompt string
        PS1=${ps1} ;;
    esac
}


# Things to do after executing the last command
# precmd - Executed BEFORE each prompt. Not re-executed if command line is redrawn
precmd_zsh_hook () {
    _prompt_timer_stop
    # Allow for a simple prompt for copy / paste examples
    if [[ -n ${ps1+x} ]]; then
        _simple_prompt_zsh; unset RPS1;
        # shellcheck disable=2154,2004  # zsh
        (( ${+functions[disable_you_should_use]} )) && disable_you_should_use
        return 0
    fi
    _git_status_gen  # Update the prompt's git component

    # TODO Add classified job status to prompt
    # https://unix.stackexchange.com/a/68635/143394
    # https://stackoverflow.com/questions/12646917/show-job-count-in-bash-prompt-only-if-nonzero
}


# preexec - Executed just after a command has been read and is about to be executed.
# NOT executed if user presses enter or on a blank command line
preexec_zsh_hook () {
    :
}


# zshaddhistory - Executed when a history line has been read interactively, but before it is executed.
zshaddhistory_hook () {
    _prompt_timer_start
}
# Setup $PROMPT
# Couldn't get willghatch/zsh-hooks to work here.
# Try to use it globally instead of add-zsh-hook as it support zle hooks also
# hooks-add-hook chpwd  _cd_hook
add-zsh-hook chpwd         _cd_hook            # See source-d prompt file
add-zsh-hook zshaddhistory zshaddhistory_hook  # Start prompt timer
add-zsh-hook precmd        precmd_zsh_hook     # Stop prompt timer, update prompt?

# add-zsh-hook preexec       preexec_zsh_hook    #

# Initialise completions
autoload -Uz compinit  # zplugin will do compinit later
compinit  # Uses $ZSH_COMPDUMP cache for faster load.  Default: .zcompdump in $ZDOTDIR else $HOME

# If not included:  https://github.com/CodesOfRishi/smartcd/issues/11#issuecomment-1012844442
compdef __smartcd__=cd
# TODO fix zicompinit in plugins via debug
zinit cdreplay  # replay all the compdefs that zinit queued up


# Used in __zplg_async_run
# Clear the namespace of bootstrap functions
# unfunction _source_file _source_files

# Setup direnv
# Required at end of zshrc says: https://github.com/direnv/direnv
command -v direnv &> /dev/null && eval "$(direnv hook zsh)"


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

