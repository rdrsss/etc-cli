# Contributing to etcli

Thanks for your interest in improving `etcli`. This is a small, dependency-free
Zig package, so the contribution loop is intentionally simple.

By participating, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Prerequisites

- Zig `0.16.x` (the version is pinned in CI; `minimum_zig_version` in
  `build.zig.zon` is a floor, not a guarantee that newer majors work).
- Optional, for the documentation/completion lint gates:
  - `mandoc` — strict man-page linting.
  - `bash`, `zsh`, `fish` — shell-specific completion syntax checks.

When an optional tool is absent, its lint gate prints a skip message and
succeeds, so you can build and test without them. When `mandoc` is installed,
any `mandoc -Tlint` warning or error fails the test step.

## Build and test

The whole suite runs from a single command:

```sh
zig build test --summary all
```

That step compiles the package and the example, runs source-local unit tests,
the downstream-style import fixtures for both `cli` and `etcli`, the parser /
dispatch / help / completion / man / schema / snapshot integration tests, the
parser property tests, and the compile-fail validation fixtures, then runs the
optional man-page and completion lints.

## Compile-fail fixtures

Negative validation behavior (anything that should fail at compile time) is
covered by fixtures under `integration_tests/compile_fail/`, driven by
`scripts/compile_fail.sh`. When you add or change a `comptime` validation rule:

1. Add a fixture `.zig` file that triggers the new `@compileError`.
2. Register it in `scripts/compile_fail.sh` with a `grep`-able substring of the
   expected diagnostic.

## Snapshots

`integration_tests/snapshots/` pins representative help, man, completion, and
schema output. If a change intentionally alters generated output, update the
affected snapshot in the same commit and confirm the diff is what you expect.

## Pull requests

- Keep changes focused; one logical change per PR.
- Update `CHANGELOG.md` under `## Unreleased` for any user-visible change.
- Make sure `zig build test` is green before pushing.
- For changes to public types, generated artifact shape, parser semantics, or
  validation rules, call out the compatibility impact (see `docs/release.md`).

## Reporting bugs

Open a GitHub issue with your Zig version, OS, and a minimal command tree that
reproduces the behavior. See `SECURITY.md` for security-sensitive reports.
