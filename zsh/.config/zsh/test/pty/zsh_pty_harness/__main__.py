"""PTY completion regression harness — TAP 14 runner.

Usage:
  python3 -m zsh_pty_harness [--case NAME] [--timeout SECS] [--keep-tmp]
  zsh/.config/zsh/test/pty/run [--case NAME]

Discovers all cases/*.toml, runs each in a fresh interactive zsh with the
user's full config, and emits TAP 14 output. Exit code is non-zero if any
case FAILs or ERRORs; zero if all PASS or SKIP.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
import time
from pathlib import Path
from typing import Optional

from .cases import Case, load_cases
from .driver import ZshSession, ZshSessionError
from .inject import ZshShimDir
from .probe import probe_capabilities

# Resolve the dotfiles repo root from this file's location.
# zsh/.config/zsh/test/pty/zsh_pty_harness/ is 6 levels deep.
HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent.parent.parent.parent.parent
CASES_DIR = HERE / "cases"

# Default ZDOTDIR used by the user's config. Override via --zdotdir.
DEFAULT_ZDOTDIR = str(REPO_ROOT / "zsh" / ".config" / "zsh")


def run_one_case(case: Case, zdotdir: str, timeout_s: int, keep_tmp: bool) -> dict:
    """Run a single case. Returns a dict: {status, detail}."""
    # Build env overrides
    env_overrides = dict(case.env_overrides)

    # Default FZF options: auto-accept single match, no tmux popup, short.
    env_overrides.setdefault(
        "FZF_DEFAULT_OPTS",
        "--select-1 --bind enter:accept --no-tmux --height=40% --inline-info",
    )
    # Match the working debug script's env defaults.
    env_overrides.setdefault("FZF_TMUX_HEIGHT", "100%")
    env_overrides.setdefault("LC_ALL", "C")
    env_overrides.setdefault("LANG", "C")
    # Suppress welcome messages (ponysay/fortune) from bashrc's welcome-message
    # script. The PTY shell sources the user's bashrc which calls ~/bin/welcome-message
    # on login/tmux; this output pollutes the TAP stream.
    # Use BWRAPPED=1 (not AI_AGENT=1 which triggers lean-ctx hook, nor
    # DISABLE_WELCOME=1 which has a side-effect on carapace completion timing).
    env_overrides.setdefault("BWRAPPED", "1")

    shim = ZshShimDir(real_zdotdir=zdotdir, zstyle_overrides=case.zstyle_overrides)
    try:
        with shim as shim_zdotdir:
            env_overrides["ZDOTDIR"] = shim_zdotdir
            _case_orig_cwd = os.getcwd()
            try:
                if case.cwd:
                    os.chdir(os.path.expanduser(case.cwd))
                with ZshSession(
                    env_overrides=env_overrides,
                    zsh_env_path="/dev/null",
                    timeout_s=timeout_s,
                ) as zsh:
                    # Wait for capabilities + READY
                    caps = probe_capabilities(zsh, ready_timeout_s=float(timeout_s))

                    # Clear accumulated output from probe/startup so it doesn't
                    # interfere with BUFFER capture later.
                    zsh._line_buf.clear()
                    zsh._buf.clear()

                    # Check requires
                    missing = caps.missing(case.requires)
                    if missing:
                        return {
                            "status": "SKIP",
                            "detail": f"missing capabilities: {','.join(missing)}",
                        }

                    # setup_check assertions (optional)
                    for key, expected in case.setup_check.items():
                        actual = caps.get(key, "")
                        # For bindkey_tab, accept fzf-tab-complete OR .fzf-tab-orig-fzf-completion
                        if key == "bindkey_tab":
                            if expected not in actual and expected != actual:
                                return {
                                    "status": "ERROR",
                                    "detail": f"setup_check {key}: expected {expected!r}, got {actual!r}",
                                }
                        else:
                            if expected != actual:
                                return {
                                    "status": "ERROR",
                                    "detail": f"setup_check {key}: expected {expected!r}, got {actual!r}",
                                }

                    # Send the keystrokes, then re-arm accept-line (in case a plugin
                    # clobbered our wrapper after turbo load), then Enter to
                    # trigger accept-line (which prints BUFFER inside sentinels).
                    # NOTE: do NOT pre-arm ^Xh before Tab — it interferes with
                    # fzf-tab's completion path (the re-arm widget changes the
                    # active keymap state). The sched tick already installed the
                    # accept-line chain; we re-arm only AFTER the popup closes.
                    zsh.send_keys(case.input_keys, inter_byte_ms=15)
                    # Give fzf-tab's popup time to appear and --select-1 to
                    # auto-accept (if there's a single match).
                    time.sleep(case.post_input_delay_s)
                    # Re-arm AGAIN after fzf-tab may have clobbered Enter binding.
                    zsh.send_keys(b"\x18h", inter_byte_ms=0)
                    time.sleep(0.3)
                    zsh.send_keys(b"\r", inter_byte_ms=0)

                    # Wait for the BUFFER capture.
                    try:
                        captured = zsh.wait_for(
                            "BUFFER",
                            r"HARNESS_BUFFER_START<(.*)>HARNESS_BUFFER_END",
                            timeout_s=20.0,
                        )
                    except ZshSessionError as e:
                        # Dump all pending lines for debugging
                        import sys as _sys
                        for _l in zsh.drain(0.5):
                            print(f"  DBG: {_l[:200]!r}", file=_sys.stderr)
                        return {"status": "FAIL", "detail": f"no BUFFER capture: {e}"}

                    # Match against the expected regex
                    regex = re.compile(case.expect_buffer_regex)
                    m = regex.match(captured)
                    if m:
                        return {"status": "PASS", "detail": captured}
                    return {
                        "status": "FAIL",
                        "detail": f"expected /{case.expect_buffer_regex}/, got {captured!r}",
                    }
            except ZshSessionError as e:
                return {"status": "ERROR", "detail": str(e)}
            finally:
                if case.cwd:
                    os.chdir(_case_orig_cwd)
    finally:
        if not keep_tmp:
            pass  # ZshShimDir.close() already ran via __exit__


def emit_tap(results: list[dict]) -> None:
    """Emit TAP 14 to stdout."""
    print("TAP version 14")
    n = len(results)
    print(f"1..{n}")
    for i, r in enumerate(results, start=1):
        status = r["status"]
        name = r["name"]
        detail = r["detail"]
        if status == "PASS":
            print(f"ok {i} - {name}")
        elif status == "SKIP":
            print(f"ok {i} - {name} # SKIP {detail}")
        elif status == "FAIL":
            print(f"not ok {i} - {name}")
            print("  ---")
            print(f"  message: {detail}")
            print("  ...")
        elif status == "ERROR":
            print(f"not ok {i} - {name} # ERROR {detail}")
        else:
            print(f"not ok {i} - {name} # unknown status {status}")


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(prog="zsh_pty_harness")
    p.add_argument("--case", help="run a single named case", default=None)
    p.add_argument("--timeout", type=int, default=60, help="per-case timeout in seconds")
    p.add_argument("--keep-tmp", action="store_true", help="preserve temp files")
    p.add_argument("--zdotdir", default=DEFAULT_ZDOTDIR, help="ZDOTDIR for the SUT")
    p.add_argument("--cases-dir", default=str(CASES_DIR), help="directory of TOML cases")
    args = p.parse_args(argv)

    cases_dir = Path(args.cases_dir)
    if not cases_dir.is_dir():
        print(f"Bail out! cases dir not found: {cases_dir}", file=sys.stderr)
        return 2

    cases = load_cases(cases_dir)
    if args.case:
        cases = [c for c in cases if c.name == args.case]
        if not cases:
            print(f"Bail out! no case named {args.case!r} in {cases_dir}", file=sys.stderr)
            return 2

    results = []
    # Cases reference files relative to the repo root (e.g. `has space`).
    # The harness may be invoked from zsh/.config/zsh/test/pty/ or elsewhere; chdir to
    # REPO_ROOT so completions resolve the same files the user sees.
    _orig_cwd = os.getcwd()
    os.chdir(REPO_ROOT)
    try:
        for case in cases:
            r = run_one_case(case, args.zdotdir, args.timeout, args.keep_tmp)
            r["name"] = case.name
            results.append(r)
    finally:
        os.chdir(_orig_cwd)

    emit_tap(results)

    # Exit code: non-zero on any FAIL or ERROR
    bad = any(r["status"] in ("FAIL", "ERROR") for r in results)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
