#!/usr/bin/env bats

setup() {
    source "${BATS_TEST_DIRNAME}/../functions"
}

# Return-code testing pattern: `run` executes in subshell (can't check
# arrays), but captures exit code.  For tests needing BOTH return code and
# array state, call the function with `|| true` and capture `$?` immediately:
#   is_item_in_array args || _rc=$?
#   [ "$_rc" -eq N ]
# `|| true` prevents BATS from failing on non-zero exit; `_rc=$?` inside
# `||` captures the function's exit code before `true` runs.

# ===========================================================================
# 1. Return Code Contracts
# ===========================================================================

@test "1.1 item present returns 0" {
    local -a arr=(alpha beta gamma)
    is_item_in_array beta arr
}

@test "1.2 item absent returns 1" {
    local -a arr=(alpha beta gamma)
    is_item_in_array delta arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "1.3 empty array returns 1" {
    local -a arr=()
    is_item_in_array anything arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

# ===========================================================================
# 2. Exact Match Only (No Substring / Prefix / Suffix)
# ===========================================================================

@test "2.1 exact match on first element" {
    local -a arr=(alpha beta gamma)
    is_item_in_array alpha arr
}

@test "2.2 exact match on last element" {
    local -a arr=(alpha beta gamma)
    is_item_in_array gamma arr
}

@test "2.3 substring does not match" {
    local -a arr=(__atuin_precmd _zlua_precmd)
    is_item_in_array atu arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "2.4 prefix does not match" {
    local -a arr=(_prompt_bash_set)
    is_item_in_array _prompt_bash arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "2.5 suffix does not match" {
    local -a arr=(_prompt_bash_set)
    is_item_in_array bash_set arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "2.6 longer variant does not match shorter" {
    local -a arr=(foo)
    is_item_in_array foobar arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "2.7 shorter variant does not match longer" {
    local -a arr=(foobar)
    is_item_in_array foo arr || _rc=$?
    [ "$_rc" -eq 1 ]
}

# ===========================================================================
# 3. Nameref / Array Name Passing
# ===========================================================================

@test "3.1 passes array by name (nameref)" {
    local -a my_funcs=(one two three)
    is_item_in_array two my_funcs
}

@test "3.2 underscore-heavy names work" {
    local -a __precmd_array=(__atuin_precmd _zlua_precmd _prompt_bash_set)
    is_item_in_array _prompt_bash_set __precmd_array
}

# ===========================================================================
# 4. Declare -rn Read-Only Guard
# ===========================================================================

@test "4.1 array not mutated after call" {
    local -a arr=(a b c)
    is_item_in_array b arr
    [ "${arr[0]}" = a ]
    [ "${arr[1]}" = b ]
    [ "${arr[2]}" = c ]
    [ "${#arr[@]}" -eq 3 ]
}

@test "4.2 array not mutated when item absent" {
    local -a arr=(a b c)
    is_item_in_array z arr || true
    [ "${arr[0]}" = a ]
    [ "${arr[1]}" = b ]
    [ "${arr[2]}" = c ]
    [ "${#arr[@]}" -eq 3 ]
}

# ===========================================================================
# 5. Real-World precmd_functions Scenario
# ===========================================================================

@test "5.1 __atuin_precmd found in typical precmd_functions" {
    local -a precmd_functions=(__atuin_precmd _zlua_precmd _prompt_bash_set)
    is_item_in_array __atuin_precmd precmd_functions
}

@test "5.2 nonexistent function not found in precmd_functions" {
    local -a precmd_functions=(__atuin_precmd _zlua_precmd)
    is_item_in_array nonexistent precmd_functions || _rc=$?
    [ "$_rc" -eq 1 ]
}

@test "5.3 idempotent append pattern works" {
    local -a precmd_functions=(__atuin_precmd)
    is_item_in_array _prompt_bash_set precmd_functions || precmd_functions+=(_prompt_bash_set)
    [ "${#precmd_functions[@]}" -eq 2 ]
    is_item_in_array _prompt_bash_set precmd_functions
    is_item_in_array _prompt_bash_set precmd_functions || precmd_functions+=(_prompt_bash_set)
    [ "${#precmd_functions[@]}" -eq 2 ]
}
