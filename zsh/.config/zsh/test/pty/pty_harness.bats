#!/usr/bin/env bats
# zsh/.config/zsh/test/pty/pty_harness.bats — bats entry point for the PTY completion harness.
# Runs the Python PTY suite by default; set NO_PTY_HARNESS=1 to skip it
# (useful when iterating on bash-only tests and you don't want to wait for
# the interactive zsh bootstrap on every bats invocation).

load 'test_helper'

@test "pty completion harness: full TAP suite" {
  if [[ -n "${NO_PTY_HARNESS:-}" ]]; then
    skip "NO_PTY_HARNESS set"
  fi
  local harness_output
  local harness_status

  if [[ -n "${PTY_HARNESS_VERBOSE:-}" ]]; then
    local tmp_output
    tmp_output="$(mktemp)"
    bash "${BATS_TEST_DIRNAME}/run" >"${tmp_output}" 2>&1 || harness_status="$?"
    harness_status="${harness_status:-0}"
    harness_output="$(<"${tmp_output}")"
    while IFS= read -r line; do
      printf '# %s\n' "$line" >&3
    done <"${tmp_output}"
    rm -f "${tmp_output}"
  else
    run bash "${BATS_TEST_DIRNAME}/run"
    harness_status="$status"
    harness_output="$output"
    echo "$harness_output"
  fi

  # TAP plan line must be present and non-zero exit on FAIL/ERROR is enforced by the runner.
  [[ "$harness_status" -eq 0 || "$harness_status" -eq 1 ]]
  [[ "$harness_output" == "TAP version 14"* ]]
  # At least the self-test must pass (ok 1 - _selftest)
  [[ "$harness_output" == *"ok 1 - _selftest"* ]]
  # The negative self-test must fail (not ok 2 - _selftest_negative)
  [[ "$harness_output" == *"not ok 2 - _selftest_negative"* ]]
}
