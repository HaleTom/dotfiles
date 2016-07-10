# set prefix key to ctrl+t
# unbind C-b
# set -g prefix C-t 

set-option -g status-keys vi
set-option -g history-limit 8192

# toggle last window like screen
bind-key C-b last-window

# open %% man page
bind C-m command-prompt -p "Open man page for:" "new-window 'exec man %%'"

# quick view of processes
bind '~' split-window "exec sh -c htop || top"

# copy tmux buffer to clipboard
bind C-y run "tmux show-buffer | xsel -b"
# move x clipboard into tmux paste buffer
bind C-p run "tmux set-buffer \"$(xsel -o)\"; tmux paste-buffer"

# set vi keys
setw -g mode-keys vi
# unbind [
bind Escape copy-mode
unbind p
bind p paste-buffer
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection

# Set 256 colors only if the TERM supports it TODO
# Something like:   # Statusbar starting in X or not
# if '[ -n "$DISPLAY" ]' 'source-file ~/.tmux/inx'
# if '[ -z "$DISPLAY" ]' 'source-file ~/.tmux/xless'
set -g default-terminal "screen-256color"

# Remove symbols after window names
# set -g window-status-format "#I:#W"
# set -g window-status-current-format "#I:#W"

# Set environment NEEDED???
# set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"

# Available colours:
# default, black, red, green, yellow, blue, magenta, cyan, white
# colour0 to colour255 from the 256-colour palette

# Command/message line colors
set -g message-fg white
set -g message-bg black
set -g message-attr bright

# Default statusbar colors
set -g status-fg white
set -g status-bg default

# Window status line colouring
set-window-option -g window-status-bg default
set-window-option -g window-status-fg default

set-window-option -g window-status-current-bg cyan
set-window-option -g window-status-current-fg default

set-window-option -g window-status-bell-fg red
set-window-option -g window-status-bell-bg black

set-window-option -g window-status-activity-fg white
set-window-option -g window-status-activity-bg black

set-window-option -g clock-mode-colour red
set-window-option -g clock-mode-style 24

set-window-option -g utf8 on

# don't rename windows automatically when manually giving names using
# <leader> ,
# set-option -g allow-rename off

# Automatically set window title
set-window-option -g automatic-rename on
set-option -g set-titles on

# Sane scrolling
set -g terminal-overrides 'xterm*:smcup@:rmcup@'

# Index starting from 1 as '0' key is a bit of a stretch
set -g base-index 1
set-window-option -g pane-base-index 1

# Enable mouse mode (tmux 2.1 and above)
# set -g mouse on
set-option -g mouse-select-pane on
set-option -g mouse-select-window on
set -g mouse-resize-pane on
set-window-option -g mode-mouse on

# Window options
setw -g monitor-activity on
set -g visual-activity on
set -g window-status-current-attr bold

bind-key s split-window -h # Split into a left and right
bind-key v split-window -v

bind-key J resize-pane -D 5
bind-key K resize-pane -U 5
bind-key H resize-pane -L 5
bind-key L resize-pane -R 5

bind-key M-j resize-pane -D
bind-key M-k resize-pane -U
bind-key M-h resize-pane -L
bind-key M-l resize-pane -R

# Vim style pane selection
bind h select-pane -L
bind j select-pane -D 
bind k select-pane -U
bind l select-pane -R

# Use Alt-vim keys without prefix key to switch panes
bind -n M-h select-pane -L
bind -n M-j select-pane -D 
bind -n M-k select-pane -U
bind -n M-l select-pane -R

# Use Alt-arrow keys without prefix key to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Shift arrow to switch windows
bind -n S-Left  previous-window
bind -n S-Right next-window

# No delay for escape key press
set -sg escape-time 10 # Default 500 is too long

# Remap window navigation to vim
bind-key j select-pane -D
bind-key k select-pane -U
bind-key h select-pane -L
bind-key l select-pane -R

# Reload tmux config (not a reset, cumulative only)
bind r source-file ~/.tmux.conf \; display "tmux.conf reloaded"

