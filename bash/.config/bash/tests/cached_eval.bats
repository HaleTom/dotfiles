#!/usr/bin/env bats

setup() {
    export EVALCACHE_DIR="$BATS_TEST_TMPDIR/evalcache"
    export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/xdg-cache"

    SOURCE_DIR="${BATS_TEST_DIRNAME}/.."
    TEST_PATH="/usr/bin:/bin:$BATS_TEST_TMPDIR/bin"
}

teardown() {
    rm -rf "$EVALCACHE_DIR" "$XDG_CACHE_HOME"
}

_make_fake_bin() {
    local name="$1"
    local echo_arg="${2:-export ${name}_LOADED=1}"
    local bin="$BATS_TEST_TMPDIR/bin/$name"
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/usr/bin/env bash\necho "%s"\n' "$echo_arg" > "$bin"
    chmod +x "$bin"
    echo "$bin"
}

@test "cache miss: creates cache file and sources it" {
    local bin
    bin=$(_make_fake_bin fakeinit)

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval fakeinit
        echo \$fakeinit_LOADED
    "
    [[ "$output" == *"1"* ]]
    local cache_count
    cache_count=$(find "$EVALCACHE_DIR" -name '*.bash' -type f 2>/dev/null | wc -l)
    [[ "$cache_count" -ge 1 ]]
}

@test "cache hit: sources cached file on second run" {
    local bin
    bin=$(_make_fake_bin cached)

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval cached
    "

    local cache_file
    cache_file=$(find "$EVALCACHE_DIR" -name '*.bash' -type f | head -1)
    [[ -n "$cache_file" ]]
    touch -r "$bin" "$cache_file"
    touch "$cache_file"

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval cached
        echo \$cached_LOADED
    "
    [[ "$output" == *"1"* ]]
}

@test "EVALCACHE_DISABLE=true bypasses cache" {
    local bin
    bin=$(_make_fake_bin disabled)

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval disabled
    "

    printf '#!/usr/bin/env bash\necho "export DISABLED_LOADED=2"\n' > "$bin"

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        EVALCACHE_DISABLE=true PATH='$TEST_PATH' _cached_eval disabled
        echo \$DISABLED_LOADED
    "
    [[ "$output" == *"2"* ]]
}

@test "binary newer than cache: regenerates cache" {
    local bin
    bin=$(_make_fake_bin newer)

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval newer
    "

    sleep 0.1
    touch "$bin"
    printf '#!/usr/bin/env bash\necho "export NEWER_LOADED=2"\n' > "$bin"

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval newer
        echo \$NEWER_LOADED
    "
    [[ "$output" == *"2"* ]]
}

@test "different realpath: different cache file" {
    local bin1 bin2
    bin1=$(_make_fake_bin diffbin1 'export DIFFBIN=1')
    bin2=$(_make_fake_bin diffbin2 'export DIFFBIN=2')

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval diffbin1
    "

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval diffbin2
        echo \$DIFFBIN
    "
    [[ "$output" == *"2"* ]]

    local count
    count=$(find "$EVALCACHE_DIR" -name '*.bash' | wc -l)
    [[ "$count" -eq 2 ]]
}

@test "binary missing: returns 0, no crash" {
    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval /nonexistent/binary_xyz
        echo exit:\$?
    "
    [[ "$output" == *"exit:0"* ]]
    [[ ! -d "$EVALCACHE_DIR" ]]
}

@test "atomic write: no partial cache file on failure" {
    local bin
    bin=$(_make_fake_bin atomic)

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval atomic
    "

    local tmp_count
    tmp_count=$(find "$EVALCACHE_DIR" -name '*.tmp.*' 2>/dev/null | wc -l)
    [[ "$tmp_count" -eq 0 ]]
}

@test "stderr: not captured in cache file" {
    local bin="$BATS_TEST_TMPDIR/bin/stderr_test"
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/usr/bin/env bash\necho "export STDERR_TEST=1"\necho "warning message" >&2\n' > "$bin"
    chmod +x "$bin"

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval stderr_test 2>/dev/null
    "

    local cache_file
    cache_file=$(find "$EVALCACHE_DIR" -name '*.bash' | head -1)
    [[ -n "$cache_file" ]]
    ! grep -q 'warning message' "$cache_file"
    grep -q 'STDERR_TEST' "$cache_file"
}

@test "staleness warning: binary older than 1 year" {
    local bin
    bin=$(_make_fake_bin stale_bin)
    touch -d "$(date -d '400 days ago' +%Y-%m-%d)" "$bin"

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval stale_bin 2>&1
    "
    [[ "$output" == *"not modified in 400 days"* ]]
}

@test "_cached_eval_clear removes all cache files" {
    local bin
    bin=$(_make_fake_bin clear_test)

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval clear_test
    "

    [[ -d "$EVALCACHE_DIR" ]]
    local before
    before=$(find "$EVALCACHE_DIR" -name '*.bash' -type f | wc -l)
    [[ "$before" -ge 1 ]]

    run bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        _cached_eval_clear
    "
    [[ "$output" == *"Cleared"* ]]

    local after
    after=$(find "$EVALCACHE_DIR" -name '*.bash' -type f 2>/dev/null | wc -l)
    [[ "$after" -eq 0 ]]
}

@test "args in cache filename: different args get separate caches" {
    local bin
    bin=$(_make_fake_bin argtest 'export ARGTEST_MODE=1')

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval argtest mode1
    "

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval argtest mode2
    "

    local count
    count=$(find "$EVALCACHE_DIR" -name '*argtest*.bash' | wc -l)
    [[ "$count" -eq 2 ]]
}

@test "args with slashes: no directory traversal in cache filename" {
    local bin
    bin=$(_make_fake_bin pathtest 'export PATHTEST=1')

    bash -c "
        source '$SOURCE_DIR/functions'
        EVALCACHE_DIR='$EVALCACHE_DIR'
        PATH='$TEST_PATH' _cached_eval pathtest /some/deep/path.lua --init bash
    "

    local cache_file
    cache_file=$(find "$EVALCACHE_DIR" -name '*pathtest*.bash' -type f | head -1)
    [[ -n "$cache_file" ]]

    local base
    base=$(basename "$cache_file")
    [[ "$base" == *pathtest*.bash ]]

    local subdirs
    subdirs=$(find "$EVALCACHE_DIR" -mindepth 2 -type f 2>/dev/null | wc -l)
    [[ "$subdirs" -eq 0 ]]
}
