#!/bin/bash
# above line is for shellcheck

export PATH="$PATH:/usr/local/heroku/bin:$HOME/bin:$HOME/.cabal/bin"
export EDITOR=vim
export RUBYLIB="$HOME"/lib:"$RUBYLIB"

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
    $HOME/.alias
    $HOME/.bash_funcs
    $tmuxbash
    $HOME/.vim/bundle/gruvbox/gruvbox_256palette.sh
    $HOME/.fzf.bash
DOTFILES
unset tmuxbash

# chruby
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

# The absolute directory name of a file(s) or directory(s)
function abs_dirname {
  for _ in $(eval echo "{1..$#}"); do
    (cd "${dir:="$(dirname "$1")"}" && pwd || exit 1 )
    [[ $? -ne 0 ]] && return 1
    shift
  done
}

# Wrapper for systems that don't support `readlink -f`
function abs_path {
  for _ in $(eval echo "{1..$#}"); do
    # Doesn't work when called with '..'
    # echo $(cd $(dirname "$1") && pwd -P)/$(basename "$1")
    # path=$(cd $(dirname "$1" || return 1) && pwd -P) &&
    #   path="$path"/$(basename "$1")
    # [[ $? -ne 0 ]] && return 1
    # echo "$path"
    readlink -f "$1" || return 1
    shift
  done
}

function git_dir {
  # $_ is currently overwitten by chruby_auto
  local dir
  dir=$(git rev-parse --git-dir) || return 1
  abs_path "$dir"
}

# Print the name of the git repository's working tree's root directory
# Search for 'Tom Hale' in http://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command
# Or, shorter: 
# (root=$(git rev-parse --git-dir)/ && cd ${root%%/.git/*} && git rev-parse && pwd)
# but this doesn't cover external $GIT_DIRs which are named other than .git
function git_root {
  local root first_commit
  # git displays its own error if not in a repository
  root=$(git rev-parse --show-toplevel) || return
  if [[ -n $root ]]; then
    echo "$root"
    return
  elif [[ $(git rev-parse --is-inside-git-dir) = true ]]; then
    # We're inside the .git directory
    # Store the commit id of the first commit to compare later
    # It's possible that $GIT_DIR points somewhere not inside the repo
    first_commit=$(git rev-list --parents HEAD | tail -1) ||
      echo "$0: Can't get initial commit" 2>&1 && false && return
    root=$(git rev-parse --git-dir)/.. &&
      # subshell so we don't change the user's working directory
    ( cd "$root" &&
      if [[ $(git rev-list --parents HEAD | tail -1) = "$first_commit" ]]; then
        pwd
      else
        echo "${FUNCNAME[0]}: git directory is not inside its repository" 2>&1
        false
      fi
    )
  else
    echo "${FUNCNAME[0]}: Can't determine repository root" 2>&1
    false
  fi
}

# Change working directory to git repository root
function cd_git_root {
  local root
  root=$(git_root) || return # git_root will print any errors
  cd "$root" || return
}

export -f git_root cd_git_root


# Generate *+%$ decorations very cleanly:
# https://github.com/mathiasbynens/dotfiles
# Or see https://github.com/magicmonty/bash-git-prompt (not used here)

# Set the prompt #
##################

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

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
    local -i colors
    colors=$(tput colors 2>/dev/null)
    [[ $? -eq 0 ]] && [[ $colors -gt 2 ]]
}

# Sets prompt like: ravi@boxy:~/prj/sample_app
__set_bash_prompt() {
    local exit="$?" # Save the exit status of the last command

    # PS1 is made from $PreGitPS1 + <git-status> + $PostGitPS1
    local PreGitPS1="${debian_chroot:+($debian_chroot)}"
    local PostGitPS1=""

    # Disable unused variables check for unused colours
    # shellcheck disable=SC2034
    # https://github.com/koalaman/shellcheck/issues/145
    if  __colour_enabled; then
        export GIT_PS1_SHOWCOLORHINTS=1;

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
