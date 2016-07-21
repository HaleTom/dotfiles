#!/bin/sh

die() {
    echo "$@: $?"
    exit 1
}

cd -P -- "$(dirname "$0")" || exit 1  # cd includes it's own fail message

echo Updating submodules...
git pull && 
git submodule update --init --recursive

echo Submodule status:
git submodule status --recursive

# Install dotfiles
stow misc vim bash ruby git

echo
echo "Install YCM vim plugin (just load vim) then:"
echo "cd ~/.vim/bundle/YouCompleteMe"
echo "./install.py --clang-completer"
