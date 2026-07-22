"""PTY driver for interactive zsh completion testing.

Spawns a real interactive zsh (no -c), drives keystrokes, and captures
sentinel-tagged output. The harness installs a ZDOTDIR shim (see inject.py)
that emits tagged lines the driver waits for; this avoids fragile sleeps.
"""

from __future__ import annotations

import os
import pty
import re
import select
import signal
import struct
import termios
import time
from typing import Optional


class ZshSessionError(RuntimeError):
    """Raised when the PTY session fails in a way the runner cannot recover."""


class ZshSession:
    """A single interactive zsh process attached to a PTY.

    Use as a context manager:

        with ZshSession(env, zsh_env_path, timeout_s=60) as zsh:
            zsh.wait_for("CAP", r"fzf_tab=yes")
            zsh.send_keys(b"ls ./has\\\\ \t")
            buf = zsh.wait_for("BUFFER", r"HARNESS_BUFFER_START<(.*)>HARNESS_BUFFER_END")
    """

    def __init__(
        self,
        env_overrides: dict,
        zsh_env_path: str,
        timeout_s: int = 60,
        zsh_bin: str = "zsh",
    ) -> None:
        self.env_overrides = env_overrides
        self.zsh_env_path = zsh_env_path
        self.timeout_s = timeout_s
        self.zsh_bin = zsh_bin
        self.pid: Optional[int] = None
        self.master_fd: Optional[int] = None
        self._buf = bytearray()  # raw bytes accumulated from master
        self._line_buf: list[str] = []  # complete decoded lines not yet consumed
        self._closed = False

    # ------------------------------------------------------------------ #
    # lifecycle
    # ------------------------------------------------------------------ #

    def start(self) -> None:
        env = dict(os.environ)
        env.update(self.env_overrides)
        env["ZSH_ENV"] = self.zsh_env_path
        # Force line-buffered, predictable terminal behaviour
        env.setdefault("TERM", "xterm-256color")
        env.setdefault("LINES", "50")
        env.setdefault("COLUMNS", "200")
        pid, master_fd = pty.fork()
        if pid == 0:
            # child
            try:
                os.execvpe(self.zsh_bin, [self.zsh_bin, "-i"], env)
            except OSError:
                # exec failed
                os._exit(127)
        self.pid = pid
        self.master_fd = master_fd
        # Set a reasonable terminal size so fzf / --select-1 work.
        try:
            winsize = struct.pack("HHHH", 50, 200, 0, 0)
            import fcntl
            fcntl.ioctl(master_fd, termios.TIOCSWINSZ, winsize)
        except OSError:
            pass
        # non-blocking reads
        import fcntl
        flags = fcntl.fcntl(master_fd, fcntl.F_GETFL)
        fcntl.fcntl(master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

    def close(self) -> int:
        if self._closed or self.pid is None:
            return 0
        self._closed = True
        if self.master_fd is not None:
            try:
                os.close(self.master_fd)
            except OSError:
                pass
            self.master_fd = None
        # reap child
        try:
            _, status = os.waitpid(self.pid, os.WNOHANG)
            if status == 0:
                # still running; signal it
                try:
                    os.kill(self.pid, signal.SIGHUP)
                except OSError:
                    pass
                # brief wait
                for _ in range(20):
                    _, status = os.waitpid(self.pid, os.WNOHANG)
                    if status != 0:
                        break
                    time.sleep(0.05)
                else:
                    try:
                        os.kill(self.pid, signal.SIGKILL)
                    except OSError:
                        pass
                    _, status = os.waitpid(self.pid, 0)
            return status
        except (OSError, ChildProcessError):
            return -1

    def __enter__(self) -> "ZshSession":
        self.start()
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    # ------------------------------------------------------------------ #
    # I/O
    # ------------------------------------------------------------------ #

    def _pump(self, deadline: float) -> bool:
        """Read available bytes from the PTY. Returns True if bytes arrived."""
        if self.master_fd is None:
            return False
        timeout = max(0.0, deadline - time.monotonic())
        if timeout <= 0:
            return False
        try:
            r, _, _ = select.select([self.master_fd], [], [], timeout)
        except (OSError, ValueError):
            return False
        if not r:
            return False
        try:
            chunk = os.read(self.master_fd, 65536)
        except OSError:
            # EIO means child exited
            return False
        if not chunk:
            return False
        self._buf.extend(chunk)
        # split complete lines
        while True:
            nl = self._buf.find(b"\n")
            if nl < 0:
                break
            line_bytes = bytes(self._buf[: nl + 1])
            del self._buf[: nl + 1]
            # strip trailing \r\n or \n
            line = line_bytes.rstrip(b"\r\n").decode("utf-8", errors="replace")
            self._line_buf.append(line)
        return True

    def wait_for(self, tag: str, pattern: str, timeout_s: Optional[float] = None) -> str:
        """Block until a `HARNESS_<tag><...>` line matches `pattern`.

        Returns the first regex group on match (or the whole match if no group).
        Raises ZshSessionError on timeout or EOF.
        """
        if timeout_s is None:
            timeout_s = self.timeout_s
        deadline = time.monotonic() + timeout_s
        regex = re.compile(pattern)
        # scan already-buffered lines first
        while True:
            for i, line in enumerate(self._line_buf):
                if f"HARNESS_{tag}" in line:
                    m = regex.search(line)
                    if m:
                        del self._line_buf[i]
                        return m.group(1) if m.groups() else m.group(0)
            # consume one batch
            got = self._pump(deadline)
            if not got:
                # check EOF
                if self.master_fd is not None:
                    try:
                        select.select([self.master_fd], [], [], 0)
                    except (OSError, ValueError):
                        pass
                if time.monotonic() >= deadline:
                    raise ZshSessionError(
                        f"timeout waiting for HARNESS_{tag} matching {pattern!r}"
                    )
                # if buffer is empty and pump returned False repeatedly, may be EOF
                if not self._buf and not self._line_buf:
                    # try one more read
                    if not self._pump(deadline):
                        raise ZshSessionError(
                            f"EOF waiting for HARNESS_{tag} matching {pattern!r}"
                        )

    def send_keys(self, data: bytes, inter_byte_ms: int = 10) -> None:
        """Write bytes to the PTY with a small inter-byte delay so the ZLE
        event loop processes each keystroke."""
        if self.master_fd is None:
            raise ZshSessionError("session not started")
        for b in data:
            n = 0
            while n < 1:
                try:
                    n = os.write(self.master_fd, bytes([b]))
                except BlockingIOError:
                    select.select([], [self.master_fd], [], 0.1)
                except OSError as e:
                    raise ZshSessionError(f"write failed: {e}") from e
            if inter_byte_ms > 0:
                time.sleep(inter_byte_ms / 1000.0)

    def drain(self, timeout_s: float = 0.5) -> list[str]:
        """Consume and return any pending output lines."""
        deadline = time.monotonic() + timeout_s
        self._pump(deadline)
        lines = list(self._line_buf)
        self._line_buf.clear()
        return lines