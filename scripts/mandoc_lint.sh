#!/bin/sh
set -eu

if ! command -v mandoc >/dev/null 2>&1; then
    echo "mandoc not found; skipping man-page lint"
    exit 0
fi

for page in integration_tests/snapshots/man/*.1; do
    [ -e "$page" ] || continue
    mandoc -Tlint "$page"
done
