# rbenv setup
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

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
