# CI Matrix

`etc-cli` should be tested anywhere downstream projects are expected to build
their CLIs.

Recommended matrix:

- `ubuntu-latest`, `macos-latest`, and `windows-latest`
- Zig `0.16.x`
- `Debug` for default development coverage
- `ReleaseSafe` before tags or published package updates

Required CI command:

```sh
zig build test --summary all
```

The test step compiles the package, downstream import fixtures, integration
tests, compile-fail validation fixtures, generated artifact snapshots, optional
completion linting, optional man-page linting, parser property tests, and the
example executable.

Optional local tools:

- `mandoc` enables advisory man-page linting.
- `bash`, `zsh`, and `fish` enable shell-specific completion syntax checks.

Absence of optional tools should skip that specific lint and keep the core test
matrix green.
