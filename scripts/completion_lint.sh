#!/bin/sh
set -eu

lint_completion_snapshots() {
    shell_name=$1
    shell_bin=$2
    pattern=$3

    count=0
    for script in $pattern; do
        [ -f "$script" ] || continue
        count=$((count + 1))
    done

    if [ "$count" -eq 0 ]; then
        echo "error: no $shell_name completion snapshots matched $pattern" >&2
        exit 1
    fi

    if command -v "$shell_bin" >/dev/null 2>&1; then
        echo "linting $shell_name completion snapshots with $shell_bin -n ($count file(s))"
        for script in $pattern; do
            [ -f "$script" ] || continue
            "$shell_bin" -n "$script"
        done
    else
        echo "$shell_bin not found; skipping $shell_name completion lint ($count snapshot file(s) matched)"
    fi
}

lint_completion_snapshots "bash" "bash" "integration_tests/snapshots/completion/*.bash"
lint_completion_snapshots "zsh" "zsh" "integration_tests/snapshots/completion/_*"
lint_completion_snapshots "fish" "fish" "integration_tests/snapshots/completion/*.fish"
