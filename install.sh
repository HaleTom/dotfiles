#!/bin/sh

die() {
    echo "$@: $?"
    exit 1
}

cd -P -- "$(dirname "$0")" || exit 1  # cd includes it's own fail message

git pull && 
git submodule init && 
git submodule update && 
git submodule foreach git pull origin master

echo "\n** You'll need to symlink all the .dotfiles manually"

