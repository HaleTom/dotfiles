## Why

Removing a directory from the colon-delimited PATH variable sounds trivial but
is riddled with security pitfalls: glob metacharacters in directory names get
expanded by `${var//pattern/replacement}`, partial-segment matches silently
corrupt PATH (removing `/bin` also removes `/usr/bin`), and empty-arg or
colon-containing inputs cause undefined behaviour.  No existing shell one-liner
handles all of these correctly.  A well-tested, security-hardened function is
needed for use in bwrapper and other shell projects.

## What Changes

- **New function**: `rm_from_path_var <dir>` — removes every exact-segment
  occurrence of `<dir>` from the `PATH` environment variable.
- Input validation: rejects empty args, colons, newlines, and non-absolute
  paths (return code 2).
- Exact-segment matching only — `/bin` cannot match `/usr/bin`.
- Path normalization: trailing slashes, duplicate internal slashes, and POSIX
  `//` leading-slash special case are handled correctly.
- Glob metacharacters (`*`, `?`, `[`, `]`) in `<dir>` are treated as literal
  characters, never as patterns.
- Empty PATH segments (consecutive/leading/trailing colons) are preserved.
- Guard: if removal would leave PATH empty, the operation is aborted (return
  code 3) and `PATH` is left unchanged.
- Caller's `extglob` shell option state is preserved across the call.

## Capabilities

### New Capabilities
- `rm-from-path-var`: Safe removal of directories from PATH with input
  validation, exact-segment matching, path normalization, glob safety, empty-
  segment preservation, empty-PATH guard, and shell-state preservation.

### Modified Capabilities
_(none)_

## Impact

- New file: `functions` (implementation)
- New file: `test/rm_from_path_var.bats` (55 BATS tests)
- No changes to existing bwrapper code — this is a standalone library function
  for future integration.
