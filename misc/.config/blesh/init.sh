#!/bin/bash

function my/vim-load-hook {
  bleopt exec_errexit_mark=''  # Disable non-0 exit warning
  bleopt keymap_vi_mode_show='' # Don't show INSERT under the prompt line
  # bleopt prompt_ps1_transient=''

  # bleopt complete_limit=0
  # bleopt edit_magic_expand=
  bleopt edit_magic_accept=
  bleopt prompt_ps1_transient=
  bleopt prompt_rps1=

  # ble-import integration/fzf-key-bindings
  # Allow Ctrl-D = exit: define a custom C-d widget: delete forward char, or exit if buffer empty
  ble-bind -m vi_imap -f 'C-d' 'delete-region-or delete-forward-char-or-exit'

  # Restore atuin search after fzf has been loaded
  # https://forum.atuin.sh/t/ble-sh-and-atuin/881/2
  ble/util/idle.push '
  ble-bind -m emacs   -x C-r "__atuin_history --keymap-mode=emacs"
  ble-bind -m vi_imap -x C-r "__atuin_history --keymap-mode=vim-insert"
  ble-bind -m vi_nmap -x C-r "__atuin_history --keymap-mode=vim-normal"
'
  # Always start atuin in insert mode
  # ble-bind -m vi_nmap -x C-r "__atuin_history --keymap-mode=vim-normal"

  ble-import vim-surround
}

blehook/eval-after-load keymap_vi my/vim-load-hook
