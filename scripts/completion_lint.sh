#!/bin/sh
set -eu

if command -v bash >/dev/null 2>&1; then
    for script in integration_tests/snapshots/completion/*.bash; do
        [ -e "$script" ] || continue
        bash -n "$script"
    done
else
    echo "bash not found; skipping bash completion lint"
fi

if command -v zsh >/dev/null 2>&1; then
    for script in integration_tests/snapshots/completion/_*; do
        [ -e "$script" ] || continue
        zsh -n "$script"
    done
else
    echo "zsh not found; skipping zsh completion lint"
fi

if command -v fish >/dev/null 2>&1; then
    for script in integration_tests/snapshots/completion/*.fish; do
        [ -e "$script" ] || continue
        fish -n "$script"
    done
else
    echo "fish not found; skipping fish completion lint"
fi
