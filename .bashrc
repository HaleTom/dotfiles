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

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

############################
# Comments only below here #
############################

# # rbenv setup
# eval "$(rbenv init -)"
# export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
