PATH="$PATH:$HOME/bin"

# Source .dotfiles listed at end of loop (one per line)
while read dotfile ; do
    if [ -f "$dotfile" ]; then
        # echo "$dotfile"
        .  "$dotfile"
    fi
done <<DOTFILES
    $HOME/.alias
    $HOME/.bash_funcs
DOTFILES

# chruby
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

##################
# Set the prompt #
##################

# To get the git info coloured, must patch /usr/lib/git-core/git-sh-prompt:
# https://github.com/karlapsite/git/commit/b34d9e8b690ec0b304eb794011938ab49be30204#diff-a43cc261eac6fbcc3578c94c2aa24713R449

# Or see https://github.com/magicmonty/bash-git-prompt (not used here)

# Select git info displayed, see /usr/lib/git-core/git-sh-prompt
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1

function colour_enabled() {
    local -i colors=$(tput colors 2>/dev/null)
    [[ $? -eq 0 ]] && [[ $colors -gt 2 ]]
}

set_bash_prompt()
{
    if [ colour_enabled ]; then
        # wrap the colour codes between \[ and \], so that
        # bash counts the correct number of characters for wrapping: 
        local NC='\[\e[0m\]'
        local C11='\[\e[1;32m\]'
        local C13='\[\e[1;34m\]'
        local BLUE='\[\e[0;34m\]'
        export GIT_PS1_SHOWCOLORHINTS=1
        PS1="${debian_chroot:+($debian_chroot)}$C11\u@\h$NC:$C13\w$NC$(__git_ps1 '(%s)')$BLUE\$$NC "
    else
        PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 "(%s)")\$ "
    fi
}

# This tells bash to reinterpret PS1 after every command, which we
# need because __git_ps1 will return different text and colors
PROMPT_COMMAND=set_bash_prompt

############################
# Comments only below here #
############################

# # rbenv setup
# eval "$(rbenv init -)"
# export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
