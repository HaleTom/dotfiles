## 1. Implementation

- [x] 1.1 Implement `rm_from_path_var()` with character-scan algorithm (v3) in `functions`
- [x] 1.2 Add input validation: reject empty, colon, newline, non-absolute paths (RC 2)
- [x] 1.3 Add path normalization: trailing slashes, duplicate internal slashes, POSIX `//`
- [x] 1.4 Add exact-segment matching via quoted `[[ "$seg" == "$dir" ]]`
- [x] 1.5 Add empty-PATH guard (RC 3) — abort and leave PATH unchanged
- [x] 1.6 Add extglob state save/restore across all return paths
- [x] 1.7 Preserve empty PATH segments (consecutive/leading/trailing colons)

## 2. Test Suite

- [x] 2.1 Create `test/rm_from_path_var.bats` with BATS setup/teardown (save/restore PATH)
- [x] 2.2 Category 1: Return code contracts (8 tests — RC 0/1/2/3)
- [x] 2.3 Category 2: Exact-segment matching (5 tests — no partial/suffix/prefix matches)
- [x] 2.4 Category 3: Multiple occurrences (4 tests — duplicates, empty-PATH guard)
- [x] 2.5 Category 4: Path normalization (7 tests — trailing/internal slashes, root)
- [x] 2.6 Category 5: POSIX `//` special case (6 tests — exactly-2 vs 3+ slashes)
- [x] 2.7 Category 6: Glob metacharacter safety (5 tests — `*`, `?`, `[`, `]`, combined)
- [x] 2.8 Category 7: Edge cases (9 tests — long PATH, spaces, unicode, empty PATH, colons)
- [x] 2.9 Category 8: Shell state preservation (5 tests — extglob ON/OFF across all RCs)
- [x] 2.10 Category 9: Security regression (6 tests — partial match, glob/colon/newline/relative injection)

## 3. Verification

- [x] 3.1 All 55 BATS tests pass
- [x] 3.2 Shellcheck clean on `functions`
- [x] 3.3 Character scan verified safe for `]` metacharacter (no glob surface area)
