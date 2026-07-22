r"""TOML case loader with escape DSL parser.

Case files live in zsh_pty_harness/cases/*.toml. Each case declares:

  name = "backslash-space"
  description = "..."
  requires = ["fzf_tab"]                 # optional
  env_overrides = { FZF_DEFAULT_OPTS = "..." }  # optional
  zstyle_overrides = [                    # optional
    "':fzf-tab:*' fzf-command fzf",
  ]
  input_keys = "ls ./has\\\\ \t"          # escape DSL: \t=Tab, \r=Enter, \xNN, \\\\=literal backslash
  expect_buffer_regex = "^ls \\.\\./has\\\\ space$"  # Python regex over $BUFFER
  setup_check = { bindkey_tab = "fzf-tab-complete" }  # optional pre-test assertion

The escape DSL in input_keys:
  \t  -> Tab (0x09)
  \r  -> Enter (0x0d)
  \n  -> newline (0x0a)
  \e  -> Escape (0x1b)
  \xNN -> hex byte
  \\  -> literal backslash (0x5c)
  Any other \X -> literal X
"""

from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


_ESCAPES = {
    "t": "\t",
    "r": "\r",
    "n": "\n",
    "e": "\x1b",
    "a": "\a",
    "b": "\b",
    "f": "\f",
    "v": "\v",
    "0": "\x00",
}


def parse_input_keys(s: str) -> bytes:
    """Parse the escape DSL into raw bytes to send to the PTY."""
    out = bytearray()
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c == "\\" and i + 1 < n:
            nxt = s[i + 1]
            if nxt == "\\":
                out.append(0x5c)
                i += 2
                continue
            if nxt == "x" and i + 3 < n:
                hexs = s[i + 2 : i + 4]
                try:
                    out.append(int(hexs, 16))
                    i += 4
                    continue
                except ValueError:
                    pass
            if nxt in _ESCAPES:
                out.extend(_ESCAPES[nxt].encode("utf-8"))
                i += 2
                continue
            # unknown escape: literal next char
            out.append(ord(nxt))
            i += 2
            continue
        out.extend(c.encode("utf-8"))
        i += 1
    return bytes(out)


@dataclass
class Case:
    name: str
    description: str
    input_keys: bytes
    expect_buffer_regex: str
    requires: list[str] = field(default_factory=list)
    env_overrides: dict = field(default_factory=dict)
    zstyle_overrides: list[str] = field(default_factory=list)
    setup_check: dict = field(default_factory=dict)
    post_input_delay_s: float = 8.0
    cwd: Optional[str] = None
    source_path: Optional[Path] = None


def load_case(path: Path) -> Case:
    with open(path, "rb") as f:
        data = tomllib.load(f)
    if "name" not in data:
        raise ValueError(f"{path}: missing 'name'")
    if "input_keys" not in data:
        raise ValueError(f"{path}: missing 'input_keys'")
    if "expect_buffer_regex" not in data:
        raise ValueError(f"{path}: missing 'expect_buffer_regex'")
    return Case(
        name=data["name"],
        description=data.get("description", ""),
        input_keys=parse_input_keys(data["input_keys"]),
        expect_buffer_regex=data["expect_buffer_regex"],
        requires=data.get("requires", []),
        env_overrides=data.get("env_overrides", {}),
        zstyle_overrides=data.get("zstyle_overrides", []),
        setup_check=data.get("setup_check", {}),
        post_input_delay_s=data.get("post_input_delay_s", 8.0),
        cwd=data.get("cwd"),
        source_path=path,
    )


def load_cases(cases_dir: Path) -> list[Case]:
    cases = []
    for p in sorted(cases_dir.glob("*.toml")):
        cases.append(load_case(p))
    return cases
