# Tom Hale's .dotfiles


## Features

* Uses `stow` to manage the dotfiles which are split into modular packages.  Attempts install if not installed.
* Follows the [XDG Base Directory Specification](https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html) where feasible (credit to Arch's [XDG Base Directory support](https://wiki.archlinux.org/index.php/XDG_Base_Directory_support) page).
* Coloured `bash` prompt with right-aligned part
* Works with both `{ba,z}sh`
* Bunches of `git` aliases and helper functions
* `tmux` config which is actually [backwards compatible](https://stackoverflow.com/a/40902312/5353461) given [`tmux` won't implement backwards compatibility](https://github.com/tmux/tmux/issues/1732)
* Pretty ponies with aphorisms when opening a new tmux pane


## Installation

```
git clone git@github.com:HaleTom/dotfiles.git ~/.dotfiles
git clone git@bitbucket.org:HaleTom/scripts.git ~/bin  # Optional - lots of useful scripts

# Private configuration - ignore if you're not me.
git clone git@bitbucket.org:HaleTom/ravi-personal.git ~/code/ravi-personal && ~/code/ravi-personal/install

~/.dotfiles/install
```
