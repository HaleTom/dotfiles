export PATH="$PATH:/usr/local/heroku/bin:$HOME/bin"
export EDITOR=vim
export RUBYLIB="$HOME"/lib:"$RUBYLIB"

# Exclude commands starting with a <space> from history
# ‘ignoreboth’ is shorthand for ‘ignorespace’ and ‘ignoredups’.
export HISTCONTROL=ignorespace
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
        ln -s "$(readlink -f $(dirname $(gem which tmuxinator))/../completion/tmuxinator.bash)" "$tmuxbash"
    else
      echo "Not creating symlink at at existing:"
      ls -lF "$tmuxbash"
    fi
fi

# Source .dotfiles listed at end of loop (one per line)
while read dotfile ; do
    if [[ -f "$dotfile" ]]; then
        source "$dotfile"
    else
        echo "$BASH_SOURCE: Cannot source $dotfile"
    fi
done <<DOTFILES
    $HOME/.alias
    $HOME/.bash_funcs
    $tmuxbash
    $HOME/.vim/bundle/gruvbox/gruvbox_256palette.sh
DOTFILES
unset tmuxbash

# chruby
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

function cdgit() {
    local HERE=$(pwd);
    local ROOT=$(git rev-parse --show-toplevel) \
      && ROOT=${ROOT:-$(git rev-parse --git-dir)/..} \
      && cd "$ROOT" && git rev-parse || cd "$HERE"
}


##################
# Set the prompt #
##################

# To get the git info coloured, must patch /usr/lib/git-core/git-sh-prompt:
# https://github.com/karlapsite/git/commit/b34d9e8b690ec0b304eb794011938ab49be30204#diff-a43cc261eac6fbcc3578c94c2aa24713R449

# Or see https://github.com/magicmonty/bash-git-prompt (not used here)

# Generate *+%$ decorations very cleanly:
# https://github.com/mathiasbynens/dotfiles

# Select git info displayed, see /usr/lib/git-core/git-sh-prompt for more
export GIT_PS1_SHOWDIRTYSTATE=1           # '*'=unstaged, '+'=staged
export GIT_PS1_SHOWSTASHSTATE=1           # '$'=stashed
export GIT_PS1_SHOWUNTRACKEDFILES=1       # '%'=untracked
export GIT_PS1_SHOWUPSTREAM="verbose"     # 'u='=no difference, 'u+1'=ahead by 1 commit
export GIT_PS1_STATESEPARATOR=''          # No space between branch and index status
export GIT_PS1_DESCRIBE_STYLE="describe"  # detached HEAD style:
#  contains      relative to newer annotated tag (v1.6.3.2~35)
#  branch        relative to newer tag or branch (master~4)
#  describe      relative to older annotated tag (v1.6.3.1-13-gdd42c2f)
#  default       exactly eatching tag

# Check if we support colours
__colour_enabled() {
    local -i colors=$(tput colors 2>/dev/null)
    [[ $? -eq 0 ]] && [[ $colors -gt 2 ]]
}

# Sets prompt like: ravi@boxy:~/prj/sample_app
__set_bash_prompt() {
    local exit="$?" # Save the exit status of the last command

    # PS1 is made from $PreGitPS1 + <git-status> + $PostGitPS1
    local PreGitPS1="${debian_chroot:+($debian_chroot)}"
    local PostGitPS1=""

    if  __colour_enabled; then
        export GIT_PS1_SHOWCOLORHINTS=1
        # Wrap the colour codes between \[ and \], so that
        # bash counts the correct number of characters for line wrapping:
        local Red='\[\e[0;31m\]'; local BRed='\[\e[1;31m\]'
        local Gre='\[\e[0;32m\]'; local BGre='\[\e[1;32m\]'
        local Yel='\[\e[0;33m\]'; local BYel='\[\e[1;33m\]'
        local Blu='\[\e[0;34m\]'; local BBlu='\[\e[1;34m\]'
        local Mag='\[\e[0;35m\]'; local BMag='\[\e[1;35m\]'
        local Cya='\[\e[0;36m\]'; local BCya='\[\e[1;36m\]'
        local Whi='\[\e[0;37m\]'; local BWhi='\[\e[1;37m\]'
        local None='\[\e[0m\]' # Return to default colour
    else # No colour
        unset GIT_PS1_SHOWCOLORHINTS
        local Red BRed Gre BGre Yel BYel Blu BBlu Mag BMag Cya BCya Whi BWhi None
    fi

    # No username and bright colour if root
    if [[ ${EUID} = 0 ]]; then
        PreGitPS1+="$BRed\h "
    else
        PreGitPS1+="$Red\u@\h$None:"
    fi

    PreGitPS1+="$Blu\w$None"

    
    # Now build the part after git's status

    # Highlight non-standard exit codes
    if [[ $exit != 0 ]]; then
        PostGitPS1="$Red[$exit]"
    fi

    # Change colour of prompt if root
    if [[ ${EUID} == 0 ]]; then
        PostGitPS1+="$BRed"'\$ '"$None"
    else
        PostGitPS1+="$Mag"'\$ '"$None"
    fi

    # Set PS1 from $PreGitPS1 + <git-status> + $PostGitPS1
    __git_ps1 "$PreGitPS1" "$PostGitPS1" '(%s)'
    # echo '$PS1='"$PS1"

    # defaut user prompt:
    # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[01;34m\] \w\[\033[00m\] $(__git_ps1 "(%s)") \$ '
}

# This tells bash to reinterpret PS1 after every command, which we
# need because __git_ps1 will return different text and colors
PROMPT_COMMAND=__set_bash_prompt

############################
# Comments only below here #
############################

# # rbenv setup
# eval "$(rbenv init -)"
# export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
