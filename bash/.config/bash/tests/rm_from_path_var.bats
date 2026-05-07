#!/usr/bin/env bats

setup() {
    source "${BATS_TEST_DIRNAME}/../functions"
    _saved_path="$PATH"
}

teardown() {
    PATH="$_saved_path"
}

# Return-code testing pattern: `run` executes in subshell (can't check
# PATH), but captures exit code.  For tests needing BOTH return code and
# PATH, call the function with `|| true` and capture `$?` immediately:
#   rm_from_path_var args || _rc=$?
#   [ "$_rc" -eq N ]
# `|| true` prevents BATS from failing on non-zero exit; `_rc=$?` inside
# `||` captures the function's exit code before `true` runs.

# ===========================================================================
# 1. Return Code Contracts
# ===========================================================================

@test "1.1 empty arg returns 2" {
    PATH="/a:/b"
    rm_from_path_var "" || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

@test "1.2 not present in PATH returns 1" {
    PATH="/a:/b"
    rm_from_path_var /nonexistent || _rc=$?
    [ "$_rc" -eq 1 ]
    [ "$PATH" = "/a:/b" ]
}

@test "1.3 present once returns 0 and removes" {
    PATH="/a:/b:/c"
    rm_from_path_var /b
    [ "$PATH" = "/a:/c" ]
}

@test "1.4 PATH becomes empty after removal — allowed" {
    PATH="/only"
    rm_from_path_var /only
    [ "$PATH" = "" ]
}

@test "1.5 contains colon returns 2" {
    PATH="/a:/b"
    rm_from_path_var "/foo:bar" || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

@test "1.6 contains newline returns 2" {
    PATH="/a:/b"
    rm_from_path_var $'/foo\nbar' || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

@test "1.7 relative path returns 2" {
    PATH="/a:/b"
    rm_from_path_var "bin" || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

@test "1.8 relative path with dot returns 2" {
    PATH="/a:/b"
    rm_from_path_var "./bin" || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

# ===========================================================================
# 2. Exact-Segment Matching (No Partial Matches)
# ===========================================================================

@test "2.1 exact match removes" {
    PATH="/a:/b:/c"
    rm_from_path_var /b
    [ "$PATH" = "/a:/c" ]
}

@test "2.2 partial name NOT removed — /bin vs /usr/bin" {
    PATH="/usr/bin:/bin"
    rm_from_path_var /bin
    [ "$PATH" = "/usr/bin" ]
}

@test "2.3 longer entry NOT matched — /bin not in /usr/local/bin:/usr/bin" {
    PATH="/usr/local/bin:/usr/bin"
    rm_from_path_var /bin || _rc=$?
    [ "$_rc" -eq 1 ]
    [ "$PATH" = "/usr/local/bin:/usr/bin" ]
}

@test "2.4 entry is suffix of another" {
    PATH="/a/foo:/a/foo/bar"
    rm_from_path_var /a/foo
    [ "$PATH" = "/a/foo/bar" ]
}

@test "2.5 entry is prefix of another" {
    PATH="/x:/xy"
    rm_from_path_var /x
    [ "$PATH" = "/xy" ]
}

# ===========================================================================
# 3. Multiple Occurrences
# ===========================================================================

@test "3.1 duplicates all removed" {
    PATH="/a:/b:/a:/c"
    rm_from_path_var /a
    [ "$PATH" = "/b:/c" ]
}

@test "3.2 three copies in a row → all removed, PATH empty" {
    PATH="/x:/x:/x"
    rm_from_path_var /x
    [ "$PATH" = "" ]
}

@test "3.3 adjacent duplicates" {
    PATH="/a:/a:/b"
    rm_from_path_var /a
    [ "$PATH" = "/b" ]
}

@test "3.4 only entry duplicated → all removed, PATH empty" {
    PATH="/only:/only"
    rm_from_path_var /only
    [ "$PATH" = "" ]
}

# ===========================================================================
# 4. Path Normalization
# ===========================================================================

@test "4.1 trailing slash stripped" {
    PATH="/a:/usr/bin:/c"
    rm_from_path_var "/usr/bin/"
    [ "$PATH" = "/a:/c" ]
}

@test "4.2 multiple trailing slashes" {
    PATH="/a:/usr/bin:/c"
    rm_from_path_var "/usr/bin///"
    [ "$PATH" = "/a:/c" ]
}

@test "4.3 internal double slash collapsed" {
    PATH="/a:/usr/bin:/c"
    rm_from_path_var "/usr//bin"
    [ "$PATH" = "/a:/c" ]
}

@test "4.4 mixed internal + trailing" {
    PATH="/a:/usr/bin:/c"
    rm_from_path_var "/usr//bin/"
    [ "$PATH" = "/a:/c" ]
}

@test "4.5 root path" {
    PATH="/a:/:/c"
    rm_from_path_var "/"
    [ "$PATH" = "/a:/c" ]
}

@test "4.6 root path with extras normalizes to /" {
    PATH="/a:/:/c"
    rm_from_path_var "///"
    [ "$PATH" = "/a:/c" ]
}

@test "4.7 input has duplicate slash, PATH has clean version — normalization matches" {
    PATH="/a:/usr/bin:/c"
    rm_from_path_var "/usr//bin"
    [ "$PATH" = "/a:/c" ]
}

# ===========================================================================
# 5. POSIX // Leading Slash Special Case
# ===========================================================================

@test "5.1 //host/path preserved and removed" {
    PATH="//host/path:/a"
    rm_from_path_var "//host/path"
    [ "$PATH" = "/a" ]
}

@test "5.2 //host/path// normalized to //host/path" {
    PATH="//host/path:/a"
    rm_from_path_var "//host/path//"
    [ "$PATH" = "/a" ]
}

@test "5.3 // (two slashes only) removed" {
    PATH="//:/a"
    rm_from_path_var "//"
    [ "$PATH" = "/a" ]
}

@test "5.4 /// is NOT // special — normalizes to /" {
    PATH="/:/a"
    rm_from_path_var "///"
    [ "$PATH" = "/a" ]
}

@test "5.5 ///host is NOT // special — normalizes to /host" {
    PATH="/host:/a"
    rm_from_path_var "///host"
    [ "$PATH" = "/a" ]
}

@test "5.6 //host vs /host are different entries" {
    PATH="//host:/host"
    rm_from_path_var "//host"
    [ "$PATH" = "/host" ]
}

# ===========================================================================
# 6. Glob Metacharacter Safety
# ===========================================================================

@test "6.1 * treated as literal" {
    PATH="/usr/*bin:/usr/bin"
    rm_from_path_var "/usr/*bin"
    [ "$PATH" = "/usr/bin" ]
}

@test "6.2 ? treated as literal" {
    PATH="/usr/b?n:/usr/bin"
    rm_from_path_var "/usr/b?n"
    [ "$PATH" = "/usr/bin" ]
}

@test "6.3 [ and ] treated as literal" {
    PATH="/usr/[bin]:/usr/bin"
    rm_from_path_var "/usr/[bin]"
    [ "$PATH" = "/usr/bin" ]
}

@test "6.4 combined metacharacters" {
    PATH="/a*b?c:/a*b?c:/abc"
    rm_from_path_var "/a*b?c"
    [ "$PATH" = "/abc" ]
}

@test "6.5 asterisk in real path" {
    PATH="/opt/j*dk/bin:/usr/bin"
    rm_from_path_var "/opt/j*dk/bin"
    [ "$PATH" = "/usr/bin" ]
}

# ===========================================================================
# 7. Edge Cases & Boundary Conditions
# ===========================================================================

@test "7.1 very long PATH (1000 entries) — remove entry #500" {
    local p=""
    local i
    for i in $(seq 1 1000); do
        p="${p:+${p}:}/dir${i}"
    done
    PATH="$p"
    time rm_from_path_var /dir500
    [[ ":${PATH}:" == *":/dir499:"* ]] || return 1
    [[ ":${PATH}:" != *":/dir500:"* ]] || return 1
    [[ ":${PATH}:" == *":/dir501:"* ]] || return 1
}

@test "7.2 entry with spaces" {
    PATH="/usr/bin:/my dir:/sbin"
    rm_from_path_var "/my dir"
    [ "$PATH" = "/usr/bin:/sbin" ]
}

@test "7.3 entry with unicode" {
    PATH="/usr/bin:/ünicöde:/sbin"
    rm_from_path_var "/ünicöde"
    [ "$PATH" = "/usr/bin:/sbin" ]
}

@test "7.4 PATH with only one entry → removed, PATH empty" {
    PATH="/only"
    rm_from_path_var /only
    [ "$PATH" = "" ]
}

@test "7.5 PATH with two same entries → both removed, PATH empty" {
    PATH="/x:/x"
    rm_from_path_var /x
    [ "$PATH" = "" ]
}

@test "7.6 empty PATH env var → RC 1" {
    PATH=""
    rm_from_path_var /anything || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "7.7 trailing empty segment dropped (no trailing colon in result)" {
    PATH="/a:/b:"
    rm_from_path_var /b
    [ "$PATH" = "/a" ]
}

@test "7.8 PATH starts with colon — leading empty segment preserved" {
    PATH=":/a:/b"
    rm_from_path_var /a
    [ "$PATH" = ":/b" ]
}

@test "7.9 consecutive colons in PATH — empty segment preserved" {
    PATH="/a::/b"
    rm_from_path_var /a
    [ "$PATH" = ":/b" ]
}

# ===========================================================================
# 8. Shell State Preservation
# ===========================================================================

@test "8.1 extglob OFF before call stays OFF" {
    PATH="/a:/b"
    shopt -u extglob 2>/dev/null || true
    rm_from_path_var /a
    ! shopt -q extglob
}

@test "8.2 extglob ON before call stays ON" {
    PATH="/a:/b"
    shopt -s extglob 2>/dev/null || true
    rm_from_path_var /a
    shopt -q extglob
}

@test "8.3 extglob ON, early return 2 stays ON" {
    PATH="/a:/b"
    shopt -s extglob 2>/dev/null || true
    rm_from_path_var "" || true
    shopt -q extglob
}

@test "8.4 extglob OFF, early return 2 stays OFF" {
    PATH="/a:/b"
    shopt -u extglob 2>/dev/null || true
    rm_from_path_var "" || true
    ! shopt -q extglob
}

@test "8.5 extglob ON, return 1 (not found) stays ON" {
    PATH="/a:/b"
    shopt -s extglob 2>/dev/null || true
    rm_from_path_var /nope || true
    shopt -q extglob
}

# ===========================================================================
# 9. Security Regression Tests
# ===========================================================================

@test "9.1 /bin must not match /usr/bin" {
    PATH="/usr/bin:/bin"
    rm_from_path_var /bin
    [ "$PATH" = "/usr/bin" ]
}

@test "9.2 glob injection via * — literal /usr/* not in PATH" {
    PATH="/usr/bin:/usr/sbin"
    rm_from_path_var "/usr/*" || _rc=$?
    [ "$_rc" -eq 1 ]
    [ "$PATH" = "/usr/bin:/usr/sbin" ]
}

@test "9.3 colon injection rejected" {
    PATH="/a:/b"
    rm_from_path_var "/a:/b" || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

@test "9.4 newline injection rejected" {
    PATH="/a:/b"
    rm_from_path_var $'/a\n/b' || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a:/b" ]
}

@test "9.5 relative path injection rejected" {
    PATH="/a/b"
    rm_from_path_var "b" || _rc=$?
    [ "$_rc" -eq 2 ]
    [ "$PATH" = "/a/b" ]
}

@test "9.6 PATH all-same-dir → empty allowed" {
    PATH="/x:/x:/x"
    rm_from_path_var /x
    [ "$PATH" = "" ]
}
