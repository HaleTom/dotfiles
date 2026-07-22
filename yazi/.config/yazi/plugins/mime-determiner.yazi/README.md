# mime-determiner.yazi

Custom [yazi](https://yazi-rs.github.io) fetcher plugin that determines file
MIME types using [magika](https://github.com/google/magika), with an
extension/filename fallback table for speed when magika is unavailable or
returns a generic result.

## Files

| File            | Purpose                                              |
|-----------------|------------------------------------------------------|
| `main.lua`      | Plugin source — loaded by yazi as a fetcher.         |
| `test_harness.lua` | Standalone test harness; no yazi runtime required. |

## Running the test harness

The harness stubs yazi's global API (`Command`, `ya`, Url/File objects) so the
plugin can be exercised with plain `lua`.

### Prerequisites

- Lua 5.4+ (the harness was developed against Lua 5.5).

### Run

From the plugin directory:

```sh
lua test_harness.lua
```

### Expected output

```
mime-determiner.yazi test harness
--------------------------------------------------
  PASS fetch returns non-nil state
  PASS state is table
  ...
RESULTS: 19 passed, 0 failed
```

Exit code is `0` on full pass, `1` if any test fails.

### What the harness covers

| # | Test                                  | Asserts                                            |
|---|---------------------------------------|----------------------------------------------------|
| 1 | `M:fetch` returns a FetchState        | Non-nil table of booleans, one per file.           |
| 2 | Extension fallback when magika fails  | `.sh` -> `text/x-shellscript`; unknown ext -> nil. |
| 3 | Magika output parsing                 | `data.bin: application/x-elf` -> correct mime.     |
| 4 | Generic-mime filtering                | `application/octet-stream` rejected, falls back.   |
| 5 | Concurrency cap (`MAX_CONCURRENT`)    | All 20 files spawned; order preserved.             |
| 6 | `update_mimes` uses Url-object keys   | Key type is `table`, not string.                   |
| 7 | Dotfile with no real extension        | `.bashrc` yields no ext mime; state `false`.       |
| 8 | Filename match overrides extension    | `Makefile` -> `text/makefile`.                     |

### Adding tests

Edit `test_harness.lua`. Each test block is self-contained: set
`_G.MAGIKA_OUTPUTS` (map of `url -> magika stdout`), build a synthetic `job`
with `make_file(name)`, call `M:fetch(job)`, then `check(name, condition)`.

Useful helpers:

- `make_file(name, opts)` — `opts.dummy`, `opts.len` control `cha` fields.
- `_G.MAGIKA_OUTPUTS` — keyed by the stringified Url (`"/cwd/<name>"`).
- `emitted` — list of `ya.emit` calls; inspect `payload.updates`.

## Syntax check (no execution)

```sh
luac -p main.lua
```

Prints nothing and exits `0` on success.