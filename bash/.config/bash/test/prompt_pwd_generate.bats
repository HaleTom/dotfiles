#!/usr/bin/env bats

# Tests for _prompt_pwd_generate() in ../prompt
#
# The function reads $PWD and $HOME and echoes a path segment meant to be
# copy-pastable into `cd <segment>` and return to the same directory.
# It behaves differently for bash (PS1 \X escape doubling) vs zsh.
# Bats runs under bash, so these tests exercise the bash path.
# A companion script prompt_pwd_generate.zsh covers the zsh path.

setup() {
    # Extract only the _prompt_pwd_generate function definition to avoid
    # sourcing the full prompt file (which installs a DEBUG trap and other
    # side effects that interfere with bats).
    local fn_body
    fn_body=$(sed -n "/^_prompt_pwd_generate() {/,/^}/p" "${BATS_TEST_DIRNAME}/../prompt")
    eval "$fn_body"
}

# Helper: run _prompt_pwd_generate with a given PWD (and HOME=$2 if given),
# capture stdout into $seg, and assert that cd-ing through the segment returns
# to the target.  The segment is a valid shell word; use eval so tilde
# expansion, single-quote parsing, and the single-quote-escape idiom resolve
# exactly as they would when copy-pasted.  For bash, the segment has doubled
# backslashes (for PS1 \X handling); simulate the PS1 un-doubling before cd.
_check_roundtrip() {
    local target="$1"
    local home="${2:-$HOME}"
    mkdir -p -- "$target"
    HOME="$home" PWD="$target" _prompt_pwd_generate >"$BATS_TMPDIR/seg.out" 2>&1
    rc=$?
    seg=$(cat -- "$BATS_TMPDIR/seg.out")
    local cd_seg=$seg
    [[ -n $BASH_VERSION ]] && cd_seg=${cd_seg//\\\\/\\}
    ( eval "cd $cd_seg" && [ "$PWD" = "$target" ] )
}

# ===========================================================================
# 1. Basic cases (no quoting needed)
# ===========================================================================

@test "1.1 simple subdir of HOME renders as ~/subdir" {
    local got
    got=$(HOME="$HOME" PWD="$HOME/subdir" _prompt_pwd_generate 2>&1)
    [ "$got" = "~/subdir" ]
}

@test "1.2 HOME itself renders as ~" {
    local got
    got=$(HOME="$HOME" PWD="$HOME" _prompt_pwd_generate 2>&1)
    [ "$got" = "~" ]
}

@test "1.3 path outside HOME uses absolute path" {
    local got
    got=$(HOME="$HOME" PWD="/tmp" _prompt_pwd_generate 2>&1)
    [ "$got" = "/tmp" ]
}

@test "1.4 simple safe chars round-trip" {
    _check_roundtrip "$HOME/code/myapp" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "1.5 nested safe path round-trips" {
    _check_roundtrip "$HOME/a/b/c/d" "$HOME"
    [ "$rc" -eq 0 ]
}

# ===========================================================================
# 2. Special characters that need quoting
# ===========================================================================

@test "2.1 directory with space round-trips" {
    _check_roundtrip "$HOME/dir with space" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "2.2 directory with space is single-quoted" {
    local got
    got=$(HOME="$HOME" PWD="$HOME/dir with space" _prompt_pwd_generate 2>&1)
    [[ "$got" == *"dir with space"* ]]
    [[ "$got" == *"'~/"* || "$got" == "~/'"* ]]
}

@test "2.3 directory with double-quote round-trips" {
    _check_roundtrip "$HOME/fix\"quote" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "2.4 directory with single-quote round-trips" {
    local target
    printf -v target "%s/fix%squote" "$HOME" "'"
    _check_roundtrip "$target" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "2.5 directory with literal backslash round-trips" {
    _check_roundtrip "$HOME/fix\\@install" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "2.6 directory with backslash + single-quote round-trips" {
    local target
    printf -v target "%s/fix\\@install%squote" "$HOME" "'"
    _check_roundtrip "$target" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "2.7 directory with @ alone round-trips" {
    _check_roundtrip "$HOME/fix@install" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "2.8 directory with @ alone is quoted (@ is not in the safe set)" {
    local got
    got=$(HOME="$HOME" PWD="$HOME/fix@install" _prompt_pwd_generate 2>&1)
    [[ "$got" == *"'fix@install'"* ]]
}

@test "2.9 directory with colon round-trips" {
    _check_roundtrip "$HOME/fix:colon" "$HOME"
    [ "$rc" -eq 0 ]
}

# ===========================================================================
# 3. Bash PS1 \X escape handling (the original bug)
# ===========================================================================

@test "3.1 backslash-dir segment has doubled backslash for PS1" {
    local target="$HOME/fix\\@install"
    mkdir -p -- "$target"
    local got
    got=$(HOME="$HOME" PWD="$target" _prompt_pwd_generate 2>&1)
    # Verify the backslash is doubled (two backslashes before @).
    local pat='\\@'
    [[ "$got" == *"$pat"* ]]
}

# ===========================================================================
# 4. Backslash + single-quote combination (the Fix 4 case)
# ===========================================================================

@test "4.1 backslash + single-quote combined round-trips" {
    local target
    printf -v target "%s/fix\\@install%squote" "$HOME" "'"
    _check_roundtrip "$target" "$HOME"
    [ "$rc" -eq 0 ]
}

# ===========================================================================
# 5. Edge cases
# ===========================================================================

@test "5.1 empty PWD segment (root /)" {
    local got
    got=$(HOME="$HOME" PWD="/" _prompt_pwd_generate 2>&1)
    [ "$got" = "/" ]
}

@test "5.2 relative-safe path with dots and dashes" {
    local got
    got=$(HOME="$HOME" PWD="$HOME/foo.bar-baz" _prompt_pwd_generate 2>&1)
    [ "$got" = "~/foo.bar-baz" ]
}

@test "5.3 directory named with only safe chars is unquoted" {
    local got
    got=$(HOME="$HOME" PWD="$HOME/a.b-c_d" _prompt_pwd_generate 2>&1)
    [ "$got" = "~/a.b-c_d" ]
}

@test "5.5 leading dash in dirname round-trips" {
    _check_roundtrip "$HOME/-leading-dash" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "5.6 multiple backslashes in dirname round-trips" {
    _check_roundtrip "$HOME/a\\b\\\\c" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "5.7 backtick in dirname round-trips and is single-quoted" {
    local bt_char name
    bt_char=$(printf '\x60')
    name="fix${bt_char}backtick"
    mkdir -p -- "$HOME/$name"
    local got
    got=$(HOME="$HOME" PWD="$HOME/$name" _prompt_pwd_generate 2>&1)
    # Backtick is safe inside single quotes; segment must be single-quoted
    # and contain the literal backtick (no backslash-escaping needed).
    [[ "$got" == *"'${name}'"* ]]
}

@test "5.8 dollar in dirname round-trips and is single-quoted" {
    local name="fix\$dollar"
    mkdir -p -- "$HOME/$name"
    local got
    got=$(HOME="$HOME" PWD="$HOME/$name" _prompt_pwd_generate 2>&1)
    # Dollar is safe inside single quotes; segment must be single-quoted
    # and contain the literal dollar (no backslash-escaping needed).
    [[ "$got" == *"'${name}'"* ]]
}

@test "5.9 backtick command substitution in dirname round-trips safely" {
    # A dir named with backtick-command-substitution syntax must NOT execute
    # the embedded command when cd-ed through the prompt segment.
    local name
    printf -v name "fix%sdate%s" "$(printf '\x60')" "$(printf '\x60')"
    mkdir -p -- "$HOME/$name"
    _check_roundtrip "$HOME/$name" "$HOME"
    [ "$rc" -eq 0 ]
}

@test "5.10 dollar-paren command substitution in dirname round-trips safely" {
    # A dir named fix$(date) must NOT execute date when cd-ed.
    local name='fix$(date)'
    mkdir -p -- "$HOME/$name"
    _check_roundtrip "$HOME/$name" "$HOME"
    [ "$rc" -eq 0 ]
}