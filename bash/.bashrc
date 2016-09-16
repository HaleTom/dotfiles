#!/bin/bash
# above line is for shellcheck's happiness

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
        ln -s "$(readlink -f "$(dirname "$(gem which tmuxinator)")"/../completion/tmuxinator.bash)" "$tmuxbash"
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
        echo "${BASH_SOURCE[0]}: Cannot source $dotfile"
    fi
done <<DOTFILES
    $HOME/.bash_funcs
    /usr/share/bash-completion/completions/git
    $HOME/.alias
    $tmuxbash
    $HOME/.vim/bundle/gruvbox/gruvbox_256palette.sh
    $HOME/.fzf.bash
    /usr/local/share/chruby/chruby.sh
    /usr/local/share/chruby/auto.sh
DOTFILES
unset tmuxbash

# This tells bash to reinterpret PS1 after every command, which we
# need because __git_ps1 will return different text and colors
PROMPT_COMMAND=__set_bash_prompt # see ~/.bash_funcs

############################
# Comments only below here #
############################

# # rbenv setup
# eval "$(rbenv init -)"
# export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

