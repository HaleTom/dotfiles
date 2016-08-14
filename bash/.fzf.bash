# Setup fzf
# ---------
if [[ ! "$PATH" == */home/ravi/.fzf/bin* ]]; then
  export PATH="$PATH:/home/ravi/.fzf/bin"
fi

# Man path
# --------
if [[ ! "$MANPATH" == */home/ravi/.fzf/man* && -d "/home/ravi/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/home/ravi/.fzf/man"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/ravi/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/home/ravi/.fzf/shell/key-bindings.bash"

