export PATH="$PATH:/usr/local/heroku/bin:$HOME/bin"
export EDITOR=vim


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
export GIT_PS1_SHOWUPSTREAM="verbose"
export GIT_PS1_DESCRIBE_STYLE="describe" # detached HEAD style:
#  contains      relative to newer annotated tag (v1.6.3.2~35)
#  branch        relative to newer tag or branch (master~4)
#  describe      relative to older annotated tag (v1.6.3.1-13-gdd42c2f)
#  default       exactly matching tag

# Check if we support colours
__colour_enabled() {
    local -i colors=$(tput colors 2>/dev/null)
    [[ $? -eq 0 ]] && [[ $colors -gt 2 ]]
}
unset __colourise_prompt && __colour_enabled && __colourise_prompt=0

__set_bash_prompt()
{
    local exit="$?"

    PS1="${debian_chroot:+($debian_chroot)}"

    if [[ $__colourise_prompt ]]; then
        # Wrap the colour codes between \[ and \], so that
        # bash counts the correct number of characters for wrapping: 
        local NC='\[\e[0m\]' # No colour
        local Gre='\[\e[0;32m\]'
        local BGre='\[\e[1;32m\]'
        local Blu='\[\e[0;34m\]'
        local BBlu='\[\e[1;34m\]'
        local Red='\[\e[0;31m\]'
        local BRed='\[\e[1;31m\]'
        export GIT_PS1_SHOWCOLORHINTS=1

        # Change colour of user if root
        if [[ ${EUID} == 0 ]]; then
            PS1+="$BRed\h "
        else
            PS1+="$Gre\u@\h$NC:"
        fi

        # Sets prompt like: ravi@boxy:~/prj/sample_app
        PS1+="$Blu\w$NC"
    else
        unset GIT_PS1_SHOWCOLORHINTS
        PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w"
    fi

    PS1+="$(__git_ps1 '(%s)')" # Append git status

    # Highlight non-standard exit codes. Colour continues through to $ or #
    if [[ $exit != 0 ]]; then
        PS1+="$Red[$exit]"
    fi

    # Change colour of prompt if root
    if [[ ${EUID} == 0 ]]; then
        PS1+="$BRed"'\$'"$NC "
    else
        PS1+="$Blu"'\$'"$NC "
    fi

    # echo '$PS1='"$PS1"
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
