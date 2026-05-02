## Context

The `rm_from_path_var` function must safely remove a directory from the colon-
delimited `PATH` variable in bash.  Three implementation approaches were tried
and evaluated during development.

### Approach History

#### v1: `${var//pattern/replacement}` with glob escaping

Used `\*`, `\?`, `\[`, `\]` escaping in bash pattern substitution to treat
metacharacters literally.  **Abandoned** because `\]` escaping is
implementation-defined in bash glob patterns.  Per POSIX, a literal `]` inside
a bracket expression must appear first (`[]abc]`), but the backslash-escaped
form `\]` in a pattern context is not universally defined across bash
versions.

#### v2: IFS Split-Rejoin

Split `PATH` on `:` using `read -a` with `IFS=:`, compare each segment as a
plain string, rejoin.  **Abandoned** because `read -a` with IFS=`:` treats
consecutive delimiters as a single separator (standard IFS word splitting),
losing empty PATH segments (leading colons, trailing colons, consecutive
colons).  A sentinel-loop approach (`:PATH:`) suffered infinite loops when
`rest` became empty after processing the last segment.

#### v3: Character Scan (current)

Walks `PATH` character by character, splitting on colons.  When a colon (or
end of string) is reached, the accumulated segment is compared to `dir` via
`[[ "$seg" == "$dir" ]]` and either kept or discarded.

## Goals / Non-Goals

**Goals:**

- Remove exact PATH-segment matches only (no partial/substring matches)
- Treat glob metacharacters in `<dir>` as literals
- Preserve empty PATH segments (consecutive/leading/trailing colons)
- Normalize directory paths (trailing slashes, duplicate slashes, POSIX `//`)
- Validate input (reject empty, colon, newline, non-absolute paths)
- Guard against empty PATH after removal
- Preserve caller's `extglob` shell state
- O(n) single-pass algorithm

**Non-Goals:**

- Manipulating variables other than `PATH` (could be generalized later)
- Removing from PATH-like variables with different delimiters
- Bash version portability below 4.0 (namerefs, `${var:start:len}`)

## Decisions

### 1. Character scan over pattern substitution

**Choice**: v3 character scan
**Alternative**: v1 `${var//pattern/replacement}` with escaping
**Rationale**: Glob escaping is a dead end for fully general metacharacter
safety.  The `\]` ambiguity alone makes v1 unreliable.  Character scan has
zero glob surface area.

### 2. Character scan over IFS split-rejoin

**Choice**: v3 character scan
**Alternative**: v2 IFS split-rejoin
**Rationale**: IFS word splitting collapses consecutive delimiters, losing
empty PATH segments.  Fixing this with a sentinel loop introduced infinite-
loop bugs.  Character scan naturally preserves empty segments.

### 3. Path normalization with extglob

**Choice**: Enable `extglob` temporarily for `+(\/)` patterns during
normalization, restore caller's state afterward.
**Rationale**: `+(\/)` is the cleanest way to collapse runs of slashes.
extglob is needed only during normalization; preserving caller state avoids
side effects.

### 4. POSIX `//` special-case handling

**Choice**: Preserve exactly two leading slashes when the third character is
not a slash (per POSIX.1-2017 §4.13).  All other multi-slash prefixes
collapse to `/`.
**Rationale**: `//host/path` has semantic meaning on some systems; `///` and
`///host` do not and normalize to `/` and `/host` respectively.

### 5. Empty-PATH guard returns 3 (not 1)

**Choice**: Return code 3 when removal would leave PATH empty
**Rationale**: Distinguishes "would be empty" (actionable — caller may want
to set a fallback PATH) from "not found" (RC 1).  Also protects against
accidentally emptying PATH, which would break the shell.

## Risks / Trade-offs

- **[extglob dependency]** → extglob is a bashism, but bwrapper already
  requires bash 4.0+.  Acceptable.
- **[O(n) scan on every call]** → PATH is typically < 4KB.  Negligible.
- **[Empty-segment preservation]** → Preserved for correctness, but most
  tools ignore empty PATH segments anyway.  Minimal practical impact.
