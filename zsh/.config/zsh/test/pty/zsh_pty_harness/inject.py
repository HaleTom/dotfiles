"""Construct the injection shim directory.

ZSH_ENV is NOT auto-sourced by zsh (unlike BASH_ENV in bash). The correct
injection point is ZDOTDIR: zsh sources $ZDOTDIR/.zshenv (always) and
$ZDOTDIR/.zshrc (interactive). We create a temp ZDOTDIR with:

  .zshenv  -> sources the user's real .zshenv (if any) + our announce hook
  .zshrc   -> sources the user's real .zshrc

The announce hook is installed via add-zsh-hook precmd so it survives any
precmd_functions reassignment in .zshrc. It self-unregisters after announcing.

Design constraints:
  - Never edits .zshrc, zle, or plugins — those are the system under test.
  - The accept-line override is installed INSIDE the announce hook (after the
    first precmd) so we replace accept-line only once zle is fully up.
  - zstyle_overrides are applied in a one-shot precmd hook that runs after
    .zshrc (i.e. on the first precmd) and then unregisters itself.
"""

from __future__ import annotations

import os
import shutil
import tempfile
from typing import Optional


# The announce hook prints one HARNESS_CAP<...> line per capability it
# detects. probe.py waits for these.  The hook self-disables after announcing
# (but the accept-line override stays installed for the life of the session).
_ANNOUNCE_BODY = r'''
# ---- harness injection (regenerated each run; do not edit) ----
typeset -g _HARNESS_ANNOUNCED=0
typeset -g _HARNESS_PRECMD_COUNT=0
typeset -g _HARNESS_SCHED_TICKS=0
typeset -g _HARNESS_MAX_TICKS=50
typeset -g _HARNESS_PRE_ACCEPT_LINE=""
typeset -g _HARNESS_POST_ACCEPT_LINE=""

zsh-harness-accept() {
  # Print BUFFER inside tagged sentinels on a single line, then run the
  # real accept-line. Backslashes are printed literally via print -r.
  print -r -- "HARNESS_BUFFER_START<$BUFFER>HARNESS_BUFFER_END"
  builtin zle .accept-line
}

# Direct Enter binding: print BUFFER then accept. This is more robust than
# wrapping accept-line because plugins replace accept-line but rarely touch ^M.
harness-capture-enter() {
  print -r -- "HARNESS_BUFFER_START<$BUFFER>HARNESS_BUFFER_END"
  builtin zle .accept-line
}
zle -N harness-capture-enter

# Chain approach: save the current accept-line widget (set by plugins)
# and install our wrapper on top. Our wrapper prints BUFFER, then calls
# the saved widget. This survives plugin wrapping because we wrap the
# OUTERMOST widget, whatever it is.
typeset -g _HARNESS_ACCEPT_CHAIN_INSTALLED=0
harness-rearm-widget() {
  # Re-arm: always save the CURRENT accept-line (which may be a plugin wrapper
  # installed after our initial chain) and install our chained wrapper on top.
  # If we already have a saved original, restore it first so we do not nest.
  if (( _HARNESS_ACCEPT_CHAIN_INSTALLED )); then
    zle -A .harness-orig-accept-line accept-line 2>/dev/null
  fi
  zle -A accept-line .harness-orig-accept-line
  zle -N accept-line zsh-harness-accept-chained
  # Also re-bind Enter to our direct capture widget (more robust than accept-line).
  bindkey '^M' harness-capture-enter
  bindkey -M viins '^M' harness-capture-enter
  _HARNESS_ACCEPT_CHAIN_INSTALLED=1
}
zle -N harness-rearm-widget

# Chained accept-line: print BUFFER, then call the saved original.
zsh-harness-accept-chained() {
  print -r -- "HARNESS_BUFFER_START<$BUFFER>HARNESS_BUFFER_END"
  zle .harness-orig-accept-line
}
zle -N zsh-harness-accept-chained

# zinit turbo loads plugins asynchronously via `sched +N` chains. Our precmd
# hook fires before the first turbo load, so we can't detect fzf-tab there.
# Instead, after the first precmd we arm a `sched` chain that re-checks for
# fzf-tab every tick until it is loaded (or _HARNESS_MAX_TICKS is hit), then
# announces all caps at once and stops.
zsh-harness-announce() {
  (( _HARNESS_ANNOUNCED )) && return
  _HARNESS_PRECMD_COUNT=$((_HARNESS_PRECMD_COUNT + 1))
  if (( _HARNESS_PRECMD_COUNT == 1 )); then
    zle -N accept-line zsh-harness-accept
    bindkey '^Xh' harness-rearm-widget
    bindkey -M viins '^Xh' harness-rearm-widget
    bindkey -M vicmd '^Xh' harness-rearm-widget
    # Bind Enter (^M) to our capture widget. Re-bind in all keymaps.
    # Plugins may override this later; ^Xh re-arms.
    bindkey '^M' harness-capture-enter
    bindkey -M viins '^M' harness-capture-enter
    # Arm the sched chain that will poll for fzf-tab.
    sched +1 zsh-harness-tick
  fi
}

zsh-harness-tick() {
  (( _HARNESS_ANNOUNCED )) && return
  _HARNESS_SCHED_TICKS=$((_HARNESS_SCHED_TICKS + 1))
  local has_fft=$+functions[enable-fzf-tab]
  if (( ! has_fft )) && (( _HARNESS_SCHED_TICKS < _HARNESS_MAX_TICKS )); then
    sched +1 zsh-harness-tick
    return
  fi
  # fzf-tab loaded (or we gave up): announce now.
  # Pre-install the accept-line chain (wraps whatever plugin set).
  # Only install once to avoid loop.
  (( !_HARNESS_ACCEPT_CHAIN_INSTALLED )) && {
    zle -A accept-line .harness-orig-accept-line
    zle -N accept-line zsh-harness-accept-chained
    _HARNESS_ACCEPT_CHAIN_INSTALLED=1
  }
  # Re-bind Enter to our direct capture widget (survives accept-line clobbering).
  bindkey '^M' harness-capture-enter
  bindkey -M viins '^M' harness-capture-enter
  _HARNESS_POST_ACCEPT_LINE=$(bindkey '^M' 2>/dev/null)
  local tab=$(bindkey '^I' 2>/dev/null)
  tab="${tab##* }"
  print -r -- "HARNESS_CAP<tab=${tab}>"
  (( has_fft )) && print -r -- "HARNESS_CAP<fzf_tab=yes>"
  (( $+functions[disable-fzf-tab] )) && print -r -- "HARNESS_CAP<fzf_tab=yes>"
  (( $+commands[carapace] )) && print -r -- "HARNESS_CAP<carapace=yes>"
  local si=$(bindkey ' ' 2>/dev/null)
  case "$si" in
    *url-quote-magic*) print -r -- "HARNESS_CAP<url_quote_magic=yes>" ;;
  esac
  (( $+functions[_zsh_autosuggest_start] )) && print -r -- "HARNESS_CAP<autosuggestions=yes>"
  if [[ "$_HARNESS_POST_ACCEPT_LINE" != *zsh-harness-accept* ]]; then
    print -r -- "HARNESS_CAP<accept_line_clobbered=yes>"
  fi
  print -r -- "HARNESS_READY"
  _HARNESS_ANNOUNCED=1
  add-zsh-hook -d precmd zsh-harness-announce
}

zsh-harness-apply-overrides() {
  __HARNESS_OVERRIDES__
  add-zsh-hook -d precmd zsh-harness-apply-overrides
}
'''

# .zshenv shim: source user's real .zshenv then define the announce hook.
# The hook is *defined* here (so it exists before .zshrc) but *registered* in
# .zshrc-shim via add-zsh-hook so it runs after .zshrc's zinit setup.
_ZSHENV_SHIM = '''#!/bin/zsh
# harness .zshenv shim
__HARNESS_REAL_ZDOTDIR__={real_zdotdir}
__HARNESS_SHIM_ZDOTDIR__=$ZDOTDIR
# Source the user's real .zshenv if it exists (it may reset ZDOTDIR)
[[ -r "$__HARNESS_REAL_ZDOTDIR__/.zshenv" ]] && source "$__HARNESS_REAL_ZDOTDIR__/.zshenv"
# Re-assert our shim ZDOTDIR — the user's .zshenv sets ZDOTDIR=$HOME/.config/zsh
export ZDOTDIR="$__HARNESS_SHIM_ZDOTDIR__"
unset __HARNESS_REAL_ZDOTDIR__ __HARNESS_SHIM_ZDOTDIR__
'''

# .zshrc shim: source user's real .zshrc, then register our hooks.
_ZSHRC_SHIM = '''#!/bin/zsh
# harness .zshrc shim
__HARNESS_REAL_ZDOTDIR__={real_zdotdir}
# Restore real ZDOTDIR so user's .zshrc can find $ZDOTDIR/plugins, $ZDOTDIR/zle,
# $ZDOTDIR/functions-zsh, etc. The shim ZDOTDIR was only needed to locate THIS
# shim .zshrc; now that we're executing it, the user's .zshrc needs the real one.
export ZDOTDIR="$__HARNESS_REAL_ZDOTDIR__"
# Source the user's real .zshrc
[[ -r "$ZDOTDIR/.zshrc" ]] && source "$ZDOTDIR/.zshrc"
# Now register our announce hook via add-zsh-hook (survives precmd reassignment)
autoload -Uz add-zsh-hook
add-zsh-hook precmd zsh-harness-announce
{overrides_reg}
unset __HARNESS_REAL_ZDOTDIR__
'''


def _build_announce_body(zstyle_overrides: list[str] | None) -> str:
    body = _ANNOUNCE_BODY
    if zstyle_overrides:
        overrides_lines = "\n".join(f"  zstyle {z}" for z in zstyle_overrides)
    else:
        overrides_lines = "  # no overrides"
    # Normalize: strip leading whitespace on each line, re-indent with 2 spaces
    overrides_lines = "\n".join("  " + line.strip() for line in overrides_lines.splitlines() if line.strip())
    return body.replace("__HARNESS_OVERRIDES__", overrides_lines)


def _build_zshrc_shim(real_zdotdir: str, zstyle_overrides: list[str] | None) -> str:
    if zstyle_overrides:
        reg = "add-zsh-hook precmd zsh-harness-apply-overrides"
    else:
        reg = ""
    return _ZSHRC_SHIM.format(real_zdotdir=real_zdotdir, overrides_reg=reg)


class ZshShimDir:
    """A temp ZDOTDIR containing .zshenv and .zshrc shims.

    Use as a context manager; returns the temp dir path. Cleaned up on close().
    """

    def __init__(
        self,
        real_zdotdir: str,
        zstyle_overrides: list[str] | None = None,
    ) -> None:
        self.path: Optional[str] = None
        self.path = tempfile.mkdtemp(prefix="harness_zdotdir_")
        # .zshenv
        with open(os.path.join(self.path, ".zshenv"), "w") as f:
            f.write(_ZSHENV_SHIM.format(real_zdotdir=real_zdotdir))
        # .zshrc: announce body (defines the functions) + shim (sources real .zshrc)
        with open(os.path.join(self.path, ".zshrc"), "w") as f:
            f.write(_build_announce_body(zstyle_overrides))
            f.write("\n")
            f.write(_build_zshrc_shim(real_zdotdir, zstyle_overrides))

    def close(self) -> None:
        if self.path and os.path.exists(self.path):
            shutil.rmtree(self.path, ignore_errors=True)
            self.path = None

    def __enter__(self) -> str:
        return self.path  # type: ignore[return-value]

    def __exit__(self, *exc) -> None:
        self.close()