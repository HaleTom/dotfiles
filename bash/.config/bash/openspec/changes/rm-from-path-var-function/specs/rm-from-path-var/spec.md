## ADDED Requirements

### Requirement: Input validation
The function SHALL reject the following inputs with return code 2 and
leave `PATH` unchanged:
- Empty argument
- Argument containing a colon (`:`)
- Argument containing a newline character
- Non-absolute path (any path not starting with `/`)

#### Scenario: Empty argument
- **WHEN** `rm_from_path_var ""` is called
- **THEN** return code is 2 and PATH is unchanged

#### Scenario: Argument contains colon
- **WHEN** `rm_from_path_var "/foo:bar"` is called
- **THEN** return code is 2 and PATH is unchanged

#### Scenario: Argument contains newline
- **WHEN** `rm_from_path_var $'/foo\nbar'` is called
- **THEN** return code is 2 and PATH is unchanged

#### Scenario: Relative path
- **WHEN** `rm_from_path_var "bin"` is called
- **THEN** return code is 2 and PATH is unchanged

#### Scenario: Relative path with dot
- **WHEN** `rm_from_path_var "./bin"` is called
- **THEN** return code is 2 and PATH is unchanged

### Requirement: Exact-segment matching
The function SHALL only remove PATH entries that match the directory argument
as a complete colon-delimited segment. Substring matches, prefix matches, and
suffix matches SHALL NOT be removed.

#### Scenario: Exact match removes entry
- **WHEN** PATH=`/a:/b:/c` and `rm_from_path_var /b` is called
- **THEN** PATH is `/a:/c` and return code is 0

#### Scenario: Partial name not removed
- **WHEN** PATH=`/usr/bin:/bin` and `rm_from_path_var /bin` is called
- **THEN** PATH is `/usr/bin` and return code is 0

#### Scenario: Longer entry not matched
- **WHEN** PATH=`/usr/local/bin:/usr/bin` and `rm_from_path_var /bin` is called
- **THEN** PATH is `/usr/local/bin:/usr/bin` and return code is 1

#### Scenario: Entry is suffix of another
- **WHEN** PATH=`/a/foo:/a/foo/bar` and `rm_from_path_var /a/foo` is called
- **THEN** PATH is `/a/foo/bar` and return code is 0

#### Scenario: Entry is prefix of another
- **WHEN** PATH=`/x:/xy` and `rm_from_path_var /x` is called
- **THEN** PATH is `/xy` and return code is 0

### Requirement: Multiple occurrence removal
The function SHALL remove ALL occurrences of the directory from PATH. If
removal would leave PATH empty (only occurrence(s) exist), the function SHALL
return code 3 and leave PATH unchanged.

#### Scenario: Duplicates all removed
- **WHEN** PATH=`/a:/b:/a:/c` and `rm_from_path_var /a` is called
- **THEN** PATH is `/b:/c` and return code is 0

#### Scenario: Three copies result in empty PATH
- **WHEN** PATH=`/x:/x:/x` and `rm_from_path_var /x` is called
- **THEN** return code is 3 and PATH is unchanged

#### Scenario: Adjacent duplicates removed
- **WHEN** PATH=`/a:/a:/b` and `rm_from_path_var /a` is called
- **THEN** PATH is `/b` and return code is 0

#### Scenario: Only entry duplicated
- **WHEN** PATH=`/only:/only` and `rm_from_path_var /only` is called
- **THEN** return code is 3 and PATH is unchanged

### Requirement: Path normalization
The function SHALL normalize the directory argument before matching:
- Trailing slashes SHALL be stripped
- Runs of internal slashes SHALL be collapsed to a single slash
- The POSIX `//` leading-slash special case (exactly two leading slashes where
  the third character is not a slash) SHALL be preserved as `//`

#### Scenario: Trailing slash stripped
- **WHEN** PATH contains `/usr/bin` and `rm_from_path_var "/usr/bin/"` is called
- **THEN** `/usr/bin` is removed

#### Scenario: Multiple trailing slashes
- **WHEN** PATH contains `/usr/bin` and `rm_from_path_var "/usr/bin///"` is called
- **THEN** `/usr/bin` is removed

#### Scenario: Internal double slash collapsed
- **WHEN** PATH contains `/usr/bin` and `rm_from_path_var "/usr//bin"` is called
- **THEN** `/usr/bin` is removed

#### Scenario: Mixed internal + trailing
- **WHEN** PATH contains `/usr/bin` and `rm_from_path_var "/usr//bin/"` is called
- **THEN** `/usr/bin` is removed

#### Scenario: Root path preserved
- **WHEN** PATH contains `/` and `rm_from_path_var "/"` is called
- **THEN** `/` is removed

#### Scenario: Root path with extras
- **WHEN** PATH contains `/` and `rm_from_path_var "///"` is called
- **THEN** `/` is removed

#### Scenario: Duplicate slash normalization matches
- **WHEN** PATH contains `/usr/bin` and `rm_from_path_var "/usr//bin"` is called
- **THEN** normalization makes them match and `/usr/bin` is removed

### Requirement: POSIX double-slash preservation
The function SHALL preserve exactly two leading slashes when the third
character is not a slash (POSIX.1-2017 §4.13).  Three or more leading slashes
SHALL normalize to a single `/`.

#### Scenario: `//host/path` preserved
- **WHEN** PATH contains `//host/path` and `rm_from_path_var "//host/path"` is called
- **THEN** `//host/path` is removed (RC 0)

#### Scenario: `//host/path//` normalized
- **WHEN** PATH contains `//host/path` and `rm_from_path_var "//host/path//"` is called
- **THEN** `//host/path` is removed (RC 0)

#### Scenario: `//` two slashes only
- **WHEN** PATH contains `//` and `rm_from_path_var "//"` is called
- **THEN** `//` is removed (RC 0)

#### Scenario: `///` is NOT `//` special case
- **WHEN** PATH contains `/` and `rm_from_path_var "///"` is called
- **THEN** `///` normalizes to `/` and `/` is removed

#### Scenario: `///host` is NOT `//` special case
- **WHEN** PATH contains `/host` and `rm_from_path_var "///host"` is called
- **THEN** `///host` normalizes to `/host` and `/host` is removed

#### Scenario: `//host` vs `/host` are different entries
- **WHEN** PATH=`//host:/host` and `rm_from_path_var "//host"` is called
- **THEN** PATH is `/host` only

### Requirement: Glob metacharacter safety
The function SHALL treat glob metacharacters (`*`, `?`, `[`, `]`) in the
directory argument as literal characters. They SHALL NOT be interpreted as
glob patterns or match multiple PATH entries.

#### Scenario: `*` treated as literal
- **WHEN** PATH=`/usr/*bin:/usr/bin` and `rm_from_path_var "/usr/*bin"` is called
- **THEN** PATH is `/usr/bin`

#### Scenario: `?` treated as literal
- **WHEN** PATH=`/usr/b?n:/usr/bin` and `rm_from_path_var "/usr/b?n"` is called
- **THEN** PATH is `/usr/bin`

#### Scenario: `[` and `]` treated as literal
- **WHEN** PATH=`/usr/[bin]:/usr/bin` and `rm_from_path_var "/usr/[bin]"` is called
- **THEN** PATH is `/usr/bin`

#### Scenario: Combined metacharacters
- **WHEN** PATH=`/a*b?c:/a*b?c:/abc` and `rm_from_path_var "/a*b?c"` is called
- **THEN** PATH is `/abc`

#### Scenario: Asterisk in real path
- **WHEN** PATH=`/opt/j*dk/bin:/usr/bin` and `rm_from_path_var "/opt/j*dk/bin"` is called
- **THEN** PATH is `/usr/bin`

### Requirement: Empty PATH segment preservation
The function SHALL preserve empty PATH segments (leading colons, trailing
colons, and consecutive colons). Empty segments represent the current
directory in POSIX PATH semantics and MUST NOT be silently removed.

#### Scenario: PATH ends with colon
- **WHEN** PATH=`/a:/b:` and `rm_from_path_var /b` is called
- **THEN** PATH is `/a:` (trailing empty segment preserved)

#### Scenario: PATH starts with colon
- **WHEN** PATH=`:/a:/b` and `rm_from_path_var /a` is called
- **THEN** PATH is `:/b` (leading empty segment preserved)

#### Scenario: Consecutive colons in PATH
- **WHEN** PATH=`/a::/b` and `rm_from_path_var /a` is called
- **THEN** PATH is `:/b` (empty segment between `::` preserved, only `/a` removed)

### Requirement: Edge cases and boundary conditions
The function SHALL handle long PATHs, entries with spaces, unicode entries,
and the empty-PATH environment variable correctly.

#### Scenario: Very long PATH
- **WHEN** PATH has 1000 entries and entry #500 is removed
- **THEN** correct removal occurs, O(n) not exponential

#### Scenario: Entry with spaces
- **WHEN** PATH=`/usr/bin:/my dir:/sbin` and `rm_from_path_var "/my dir"` is called
- **THEN** PATH is `/usr/bin:/sbin`

#### Scenario: Entry with unicode
- **WHEN** PATH=`/usr/bin:/ünicöde:/sbin` and `rm_from_path_var "/ünicöde"` is called
- **THEN** PATH is `/usr/bin:/sbin`

#### Scenario: PATH with only one entry
- **WHEN** PATH=`/only` and `rm_from_path_var /only` is called
- **THEN** return code is 3 and PATH is unchanged

#### Scenario: PATH with two same entries
- **WHEN** PATH=`/x:/x` and `rm_from_path_var /x` is called
- **THEN** return code is 3 and PATH is unchanged

#### Scenario: Empty PATH env var
- **WHEN** PATH=`""` and `rm_from_path_var /anything` is called
- **THEN** return code is 1 (not found)

### Requirement: Shell state preservation
The function SHALL preserve the caller's `extglob` shell option state across
all return paths, including early returns (RC 2) and not-found returns (RC 1).

#### Scenario: extglob OFF before call
- **WHEN** `shopt -u extglob` and `rm_from_path_var /x` is called
- **THEN** extglob is still OFF after

#### Scenario: extglob ON before call
- **WHEN** `shopt -s extglob` and `rm_from_path_var /x` is called
- **THEN** extglob is still ON after

#### Scenario: extglob ON, early return 2
- **WHEN** `shopt -s extglob` and `rm_from_path_var ""` is called
- **THEN** extglob is still ON after

#### Scenario: extglob OFF, early return 2
- **WHEN** `shopt -u extglob` and `rm_from_path_var ""` is called
- **THEN** extglob is still OFF after

#### Scenario: extglob ON, return 1
- **WHEN** `shopt -s extglob` and `rm_from_path_var /nope` is called
- **THEN** extglob is still ON after

### Requirement: Security regression prevention
The function SHALL prevent known security pitfalls: partial-segment matching,
glob injection, colon injection, newline injection, relative-path injection,
and empty-PATH-after-removal.

#### Scenario: `/bin` must not match `/usr/bin`
- **WHEN** PATH=`/usr/bin:/bin` and `rm_from_path_var /bin` is called
- **THEN** PATH is `/usr/bin`

#### Scenario: Glob injection via `*`
- **WHEN** PATH=`/usr/bin:/usr/sbin` and `rm_from_path_var "/usr/*"` is called
- **THEN** return code is 1 (literal `/usr/*` not in PATH)

#### Scenario: Colon injection
- **WHEN** PATH=`/a:/b` and `rm_from_path_var "/a:/b"` is called
- **THEN** return code is 2 (colon rejected)

#### Scenario: Newline injection
- **WHEN** PATH=`/a:/b` and `rm_from_path_var $'/a\n/b'` is called
- **THEN** return code is 2 (newline rejected)

#### Scenario: Relative path injection
- **WHEN** PATH=`/a/b` and `rm_from_path_var "b"` is called
- **THEN** return code is 2 (relative rejected)

#### Scenario: PATH all-same-dir removal
- **WHEN** PATH=`/x:/x:/x` and `rm_from_path_var /x` is called
- **THEN** return code is 3 (would be empty)

### Requirement: Implementation algorithm — character scan
The function SHALL use a character-scan approach (v3) that walks PATH
character-by-character, splitting on colons.  Each segment is compared via
quoted `[[ "$seg" == "$dir" ]]`.  This approach:
- Preserves empty PATH segments naturally (adjacent colons produce empty
  segment accumulations)
- Has zero glob surface area (all comparisons are quoted)
- Guarantees O(n) execution in PATH length (one pass, no nested loops)
- Avoids the `\]` escaping ambiguity found in `${var//pattern/replacement}`
- Avoids the IFS word-splitting issue that loses empty PATH segments

The following earlier approaches SHALL NOT be used:
- **v1**: `${var//pattern/replacement}` with glob escaping — `\]` is
  implementation-defined in bash
- **v2**: IFS split-rejoin — `read -a` with IFS=`:` collapses consecutive
  delimiters, losing empty PATH segments; sentinel-loop variant has infinite-
  loop bugs on empty `rest`

#### Scenario: Character scan handles all metacharacters literally
- **WHEN** dir contains `*`, `?`, `[`, `]` characters
- **THEN** they are compared as literal characters, never as glob patterns

#### Scenario: Character scan preserves empty segments
- **WHEN** PATH contains consecutive colons (`::`)
- **THEN** the empty segment between them is preserved after removal of a
  non-matching entry
