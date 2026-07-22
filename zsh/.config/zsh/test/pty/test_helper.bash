# zsh/.config/zsh/test/pty/test_helper.bash — shared bats helpers for the PTY harness suite.
# Loaded via `load 'test_helper'` from pty_harness.bats.

# Resolve the directory of this file (BATS_TEST_DIRNAME points at the .bats
# file, which is a sibling of test_helper.bash).
PT_HARNESS_DIR="${BATS_TEST_DIRNAME}"

# Path to the run wrapper.
PT_RUN="${PT_HARNESS_DIR}/run"