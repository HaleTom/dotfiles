#!/bin/bash
# above line is for shellcheck's happiness

source "$HOME/.config/bash/xdg" # Needed for $XDG* variables below

export PATH="$HOME/bin:$PATH:/usr/local/heroku/bin:$HOME/.cabal/bin"
export EDITOR=vim
export RUBYLIB="$HOME"/lib:"$RUBYLIB"
export GNULIB_SRCDIR="$HOME"/repo/gnulib
export LESS=-FRXsu

# F = exit if all can be displayed on first creen
# R = interpret ANSI colour codes
# X = Don't send termcap initialization and deinitialization strings (eg clear)
# s = squash multiple blank lines into one
# u = send backspaces and carriage returns directly to the terminal

# Have command-not-found ask to install
export COMMAND_NOT_FOUND_INSTALL_PROMPT=1

# Exclude duplicates and commands starting with a <space> from history
export HISTCONTROL=ignorespace:ignoredups

# shopt -s histverify # Show output of !! - press enter twice

# Scripting overkill - how often will the tmuxinator.bash script really change?
# Check for existence of "tmuxinator.bash" file/symlink, create if necessary
# use [[ to prevent expansion of variables
tmuxbash="$HOME/.tmuxinator/tmuxinator.bash"
# If not a regular file or symlink to one
if [[ ! -f $tmuxbash ]]; then
    # If doesn't exist or is a symlink to nowhere
    if [[ ! -e $tmuxbash ]] || [[ -L $tmuxbash ]] && [[ ! -e $tmuxbash ]]; then
        echo "Creating $tmuxbash symlink"
        rm -f "$tmuxbash" && \
        ln -sv "$(readlink -f "$(dirname "$(gem which tmuxinator)")"/../completion/tmuxinator.bash)" "$tmuxbash"
    else
      echo "Not creating symlink at at existing:"
      ls -lF "$tmuxbash"
    fi
fi

# Source .dotfiles listed at end of loop (one per line)
while read -r dotfile ; do
    if [[ -f "$dotfile" ]]; then
        # shellcheck source=/dev/null
        source "$dotfile"
    else
       case "$dotfile" in
          \#*) continue;; # Skip commented lines
          *  ) echo "${BASH_SOURCE[0]}: Cannot source $dotfile"
       esac
    fi
done <<DOTFILES
    $XDG_CONFIG_HOME/bash/functions
    $XDG_CONFIG_HOME/bash/aliases
    $XDG_CONFIG_HOME/bash/completion
    $XDG_DATA_HOME/fzf/fzf.bash
    $tmuxbash
    $HOME/.vim/bundle/gruvbox/gruvbox_256palette.sh
    /usr/local/share/chruby/chruby.sh
    /usr/local/share/chruby/auto.sh
DOTFILES
unset tmuxbash

# alias g=git (done in .bash_aliases)
# This needs to be here - doesn't work inside .bash_aliases for some reason
# See http://stackoverflow.com/a/39507158/5353461
_xfunc git __git_complete g _git

# This tells bash to reinterpret PS1 after every command, which we
# need because __git_ps1 will return different text and colors
PROMPT_COMMAND=__set_bash_prompt # see ~/.bash_funcs

############################
# Comments only below here #
############################

# # rbenv setup
# eval "$(rbenv init -)"
# export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
