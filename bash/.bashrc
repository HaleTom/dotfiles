#!/bin/bash
# shellcheck disable=SC1090
# Above two lines are for shellcheck's happiness:
# 1) Determine shell.  2) Silence when trying to source from variable

source "$HOME/.config/bash/xdg" # Needed for $XDG* variables below
export PATH="$HOME/bin:$(ruby -e 'print Gem.user_dir')/bin:$PATH:/usr/local/heroku/bin:$HOME/.cabal/bin"
export EDITOR=vim
export RUBYLIB="$HOME"/lib:"$RUBYLIB"
export GNULIB_SRCDIR="$HOME"/repo/gnulib

# Have less display colours
# from: https://wiki.archlinux.org/index.php/Color_output_in_console#man
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;33m'     # begin blink
export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
export LESS=-FMRXis
# F = exit if all can be displayed on first creen
# M = show line numbers and percentage if known
# R = interpret ANSI colour codes
# X = don't send termcap initialization and deinitialization strings (eg clear)
# i = smartcase searching
# m = show :w
# s = squash multiple blank lines into one
# u = send backspaces and carriage returns directly to the terminal (breaks colored man)
export MANPAGER='less -Ms +Gg' # Show line percentage in man pages

# Have command-not-found ask to install
export COMMAND_NOT_FOUND_INSTALL_PROMPT=1

# ssh-ident
export BINARY_SSH=/usr/bin/ssh
export BINARY_SCP=/usr/bin/scp

# Allow shell-specific code
function sh_is_zsh { [[ -n $ZSH_VERSION ]]; }
function sh_is_bash { [[ -n $BASH_VERSION ]]; }

# Bash only
if sh_is_bash; then
    export HISTFILE="$XDG_DATA_HOME"/bash/history
    # Exclude duplicates and commands starting with a <space> from history
    export HISTCONTROL=ignorespace:ignoredups
fi

# Zsh only
sh_is_zsh && export HISTFILE="$XDG_DATA_HOME"/zsh/history

# Enable gcc colours, available since gcc 4.9.0
export GCC_COLORS=1

# shopt -s histverify # Show output of !! - press enter twice

# Update "tmuxinator.{z,ba}sh" if needed
tmuxinator_source="$XDG_CONFIG_HOME/tmuxinator/tmuxinator.$(sh_is_zsh && echo zsh || echo bash)"
# If not a regular file or symlink to one
if [[ ! -f $tmuxinator_source ]]; then
    # If not readable or is a symlink to nowhere
    if [[ ! -e $tmuxinator_source ]] || [[ -L $tmuxinator_source ]] && [[ ! -e $tmuxinator_source ]]; then
        echo "Creating ${tmuxinator_source##*/} symlink:"
        tmp=$(gem which tmuxinator) # tmuxinator executable
        tmp=$(readlink -f "${tmp%/*}/../completion") # completion scripts dir
        ln -fsv "$tmp/${tmuxinator_source##*/}" "$tmuxinator_source"
        unset tmp
    else
      echo "Not creating symlink at at existing:"
      ls -lF "$tmuxinator_source"
    fi
fi

# Source files given as arguments
function source_file {
    if [[ -f $1 ]]; then
        source "$1"
    else
        # [ shell_is_zsh ] && echo "${(%):-%x line %i}: Cannot source $dotfile";
        # [ shell_is_zsh ] && echo "${(%):-%N}: Cannot source $dotfile";
        [[ -n $BASH_VERSION ]] && echo "${BASH_SOURCE[0]}: Cannot source $dotfile";
        [[ -n $ZSH_VERSION ]] && echo "${(%):-%x}: Cannot source $dotfile";
        return 1
    fi
}

# Source .dotfiles listed on STDIN (one per line)
function source_files {
    while read -r dotfile ; do
        case "$dotfile" in
            \#*) continue;; # Skip commented lines
            *  ) source_file "$dotfile"
        esac
    done
}

# Both zsh and bash
source_files <<DOTFILES
    $XDG_CONFIG_HOME/bash/functions
    $XDG_CONFIG_HOME/bash/aliases
    $tmuxinator_source
    # $HOME/.vim/bundle/gruvbox/gruvbox_256palette.sh
    /usr/share/git/completion/git-prompt.sh
    # /usr/share/chruby/chruby.sh
    # /usr/share/chruby/auto.sh
DOTFILES
unset tmuxinator_source

# Bash only
if sh_is_bash; then
    source_files <<DOTFILES
        $XDG_DATA_HOME/fzf/.fzf.bash
        $XDG_CONFIG_HOME/bash/completion
DOTFILES
fi

# Zsh only
if sh_is_zsh; then source_files <<DOTFILES
    $XDG_DATA_HOME/fzf/.fzf.zsh
DOTFILES
fi

# alias g=git (done in .bash_aliases)
# This needs to be here - doesn't work inside .bash_aliases for some reason
# See http://stackoverflow.com/a/39507158/5353461
## Not needed in Manjaro with bash-completion
#_xfunc git __git_complete g _git

# This tells bash to reinterpret PS1 after every command, which we
# need because __git_ps1 will return different text and colors
PROMPT_COMMAND=__set_bash_prompt # see "functions" sourced file

############################
# Comments only below here #
############################

# # rbenv setup
# eval "$(rbenv init -)"
# export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
