# CI Matrix

`etc-cli` should be tested anywhere downstream projects are expected to build
their CLIs.

Recommended matrix:

- `ubuntu-latest` and `macos-latest`
- Zig `0.16.0` (pinned; the manifest's `minimum_zig_version` is a floor, not a
  build pin)
- `Debug` for default development coverage
- `ReleaseSafe` before tags or published package updates

Windows is intentionally excluded from the gating matrix: the default `test`
step shells out to `scripts/*.sh` for the compile-fail and lint gates, which
require a POSIX shell. Downstream projects that only `@import` the module build
fine on Windows; the exclusion is about running this package's own test step.

Required CI command:

```sh
zig build test --summary all
```

The committed workflow lives at `.github/workflows/ci.yml` and runs this command
on every push to `master`, every pull request, and every `v*` tag.

The test step compiles the package, downstream import fixtures, integration
tests, compile-fail validation fixtures, generated artifact snapshots, optional
completion linting, optional man-page linting, parser property tests, and the
example executable.

Optional local tools:

- `mandoc` enables advisory man-page linting.
- `bash`, `zsh`, and `fish` enable shell-specific completion syntax checks.

Absence of optional tools should skip that specific lint and keep the core test
matrix green.
