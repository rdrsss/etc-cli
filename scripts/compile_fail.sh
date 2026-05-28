#!/bin/sh
set -eu

run_case() {
    fixture="$1"
    expected="$2"

    output="$(zig test --dep cli -Mroot="$fixture" -Mcli=src/cli/root.zig 2>&1)" && {
        printf 'compile-fail fixture unexpectedly passed: %s\n' "$fixture" >&2
        exit 1
    }

    printf '%s' "$output" | grep -F "$expected" >/dev/null || {
        printf 'compile-fail fixture did not emit expected text: %s\n' "$fixture" >&2
        printf 'expected: %s\n' "$expected" >&2
        printf '%s\n' "$output" >&2
        exit 1
    }
}

run_case integration_tests/compile_fail/duplicate_subcommand.zig "duplicate sub-command name"
run_case integration_tests/compile_fail/duplicate_inherited_flag.zig "duplicate flag long name"
run_case integration_tests/compile_fail/default_kind_mismatch.zig "has default of kind"
run_case integration_tests/compile_fail/required_with_default.zig "required AND has a default"
