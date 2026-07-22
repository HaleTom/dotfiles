# zsh/.config/zsh/test/pty — PTY-driven zsh completion regression harness

Reproduces interactive-only completion bugs (fzf-tab, carapace, autopair, etc.)
by driving a real interactive zsh through a PTY. Cannot be reproduced with
`zsh -i -c` because zinit turbo plugins only load in truly interactive shells.

## Layout

```
zsh/.config/zsh/test/pty/
├── zsh_pty_harness/
│   ├── __init__.py
│   ├── __main__.py     # TAP 14 runner CLI
│   ├── driver.py       # ZshSession: PTY fork + sentinel wait protocol
│   ├── inject.py       # ZDOTDIR shim: announce hook + accept-line override
│   ├── probe.py        # CapabilityMap: wait for HARNESS_CAP / HARNESS_READY
│   ├── cases.py        # TOML loader + escape DSL parser
│   └── cases/
│       ├── _selftest.toml           # positive control
│       ├── _selftest_negative.toml  # negative control (must FAIL)
│       ├── backslash-space.toml     # the original bug
│       └── abbreviated-paths.toml   # /u/b/l expansion
├── pty_harness.bats    # bats entry point
├── test_helper.bash    # bats helpers
└── run                 # shell wrapper
```

## Running

```bash
# All cases
zsh/.config/zsh/test/pty/run

# Single case
zsh/.config/zsh/test/pty/run --case backslash-space

# Preserve temp files for debugging
zsh/.config/zsh/test/pty/run --keep-tmp

# Custom ZDOTDIR (default: repo's zsh/.config/zsh)
zsh/.config/zsh/test/pty/run --zdotdir /path/to/zsh/config
```

Output is TAP 14. Exit code is non-zero on any FAIL or ERROR, zero on
PASS/SKIP.

## How it works

1. **ZDOTDIR shim** (temp dir, never edits .zshrc): creates a `.zshenv` and
   `.zshrc` shim that source the user's real config, then install a `precmd`
   hook that announces detected capabilities and overrides `accept-line` to
   print `$BUFFER` inside `HARNESS_BUFFER_START<...>HARNESS_BUFFER_END`
   sentinels before executing.
2. **PTY driver**: `pty.fork()` a real interactive zsh with the user's full
   config (ZDOTDIR + zinit turbo). Wait for `HARNESS_READY` (no sleeps).
3. **Capability probe**: collect `HARNESS_CAP<key=value>` lines into a
   `CapabilityMap`. Cases declare `requires = ["fzf_tab", "carapace"]`; if
   any required cap is missing the case SKIPs (not FAILs).
4. **Send keys**: `send_keys()` writes one byte at a time so the ZLE event
   loop processes each keystroke. Tab triggers the real fzf-tab path.
5. **Assert**: capture the next `HARNESS_BUFFER` line and match against
   `expect_buffer_regex` (Python `re`).

## Escape DSL (input_keys)

| Sequence | Meaning |
|----------|---------|
| `\t`     | Tab (0x09) |
| `\r`     | Enter (0x0d) |
| `\n`     | newline (0x0a) |
| `\e`     | Escape (0x1b) |
| `\xNN`   | hex byte |
| `\\`     | literal backslash (0x5c) |
| `\X`     | literal X (any other) |

## Adding a case

No harness code changes needed. Drop a `cases/foo.toml`:

```toml
name = "foo"
description = "..."
requires = ["fzf_tab"]
env_overrides = { FZF_DEFAULT_OPTS = "--select-1 --bind enter:accept --no-tmux --height=40%" }
zstyle_overrides = [ "':fzf-tab:*' fzf-command fzf" ]
input_keys = "ls ./has\\\\ \t"
expect_buffer_regex = "^ls \\./has\\\\ space$"
```

## bats integration

The bats wrapper runs the PTY suite by default. Set `NO_PTY_HARNESS=1` to
skip it (useful when iterating on bash-only tests).

## Robustness

- **Missing caps → SKIP**, not FAIL (e.g. fzf-tab not loaded → skip fzf_tab cases)
- **accept-line clobbered → ERROR** (a plugin overrode our widget; harness bug, not SUT bug)
- **Self-test + negative self-test** cases verify the harness itself
- **No edits to SUT files** — injection is ZDOTDIR shim + env vars only
