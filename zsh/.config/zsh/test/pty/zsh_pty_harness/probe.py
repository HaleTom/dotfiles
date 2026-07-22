"""Capability discovery via sentinel announcements.

The announce hook in inject.py emits HARNESS_CAP<key=value> lines. This
module waits for those lines and exposes a CapabilityMap to the runner.

Cases declare `requires = ["fzf_tab", "carapace"]`. The runner probes each
capability tag; if any is missing the case is reported as SKIP with the
absent tag name.
"""

from __future__ import annotations

import re
import time
from dataclasses import dataclass, field
from typing import Optional

from .driver import ZshSession, ZshSessionError


@dataclass
class CapabilityMap:
    """Snapshot of shell capabilities detected by the announce hook."""
    caps: dict[str, str] = field(default_factory=dict)

    def has(self, tag: str) -> bool:
        """True if capability tag was announced with value 'yes' (or any truthy)."""
        v = self.caps.get(tag)
        return v is not None and v != "" and v != "no"

    def get(self, tag: str, default: str = "") -> str:
        return self.caps.get(tag, default)

    def missing(self, required: list[str]) -> list[str]:
        return [tag for tag in required if not self.has(tag)]


def probe_capabilities(zsh: ZshSession, ready_timeout_s: float = 30.0) -> CapabilityMap:
    """Drain PTY until HARNESS_READY, collecting HARNESS_CAP lines.

    Single drain loop scans each new line for CAP or READY markers, avoiding
    the previous N×2s retry storm when no more CAP lines arrive. Returns as
    soon as READY is seen (or deadline/EOF).
    """
    caps = CapabilityMap()
    cap_re = re.compile(r"HARNESS_CAP<(\w+)=(\S*)>")
    ready_re = re.compile(r"HARNESS_READY")
    deadline = time.monotonic() + ready_timeout_s
    while True:
        got = zsh._pump(deadline)
        # Scan all buffered lines for CAP/READY in one pass.
        remaining: list[str] = []
        saw_ready = False
        for line in zsh._line_buf:
            cm = cap_re.search(line)
            if cm:
                caps.caps[cm.group(1)] = cm.group(2)
                continue
            if ready_re.search(line):
                saw_ready = True
                continue
            remaining.append(line)
        zsh._line_buf = remaining
        if saw_ready:
            return caps
        if not got:
            # No new bytes this round; check termination conditions.
            if time.monotonic() >= deadline:
                return caps
            # EOF: no buffered bytes and pump returned False twice.
            if not zsh._buf and not zsh._line_buf:
                # Try one more pump to confirm EOF.
                if not zsh._pump(deadline):
                    return caps