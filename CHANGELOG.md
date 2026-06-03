# Changelog

All notable changes to `etc-cli` are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New flag/positional value kinds:
  - `.choice` — values constrained to a declared `choices` set, rejected at
    parse time with a "did you mean" suggestion and validated at compile time
    (non-empty, unique, shell-safe, default must be a member). Choices
    auto-populate shell completion and render in help, man pages, and the schema
    (new `"choices"` field).
  - `.float` — `f64` values via `std.fmt.parseFloat`.
  - `.duration` — human durations (`500ms`, `10m`, `1h`, bare seconds) parsed to
    nanoseconds (`u64`); defaults render human-readable in help/man and as exact
    nanoseconds in the schema.
  - `.path` — string-typed filesystem path; auto-completes files and renders a
    `PATH` placeholder.
- Positional arguments support a `default`, making the slot optional and the
  generated field non-optional (validated like flag defaults).
- `cli.man.page` accepts man sections 1–9 (was section 1 only).
- The `cli.run` runner prints a stderr warning when a deprecated command is
  invoked (flag-level warnings remain a follow-up).

### Fixed

- `cli.validate` raises its comptime branch quota so large command trees no
  longer trip the default 1000-branch limit.

## [0.1.0] - 2026-06-02

### Added

- Standalone Zig package for the comptime-driven CLI parser, exposed under both
  `cli` and `etc_cli`.
- Parser expansion for `--flag=value`, explicit bool values, negation, and short
  flag bundles.
- Generated help, shell completion (bash/zsh/fish), man pages, command schema,
  and package artifact helpers.
- Comptime validation with compile-fail fixtures, golden snapshots, lint gates,
  and parser property coverage.
- Bare negative-number tokens (e.g. `-5`) parse as integer positionals.
- `zig build snapshots-update` regenerates the golden snapshots from a shared
  command tree.
- MIT `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, GitHub issue/PR templates, and
  a GitHub Actions CI workflow.

### Fixed

- Use-after-return when returning a `--help` result path (now backed by a
  module-static buffer).
- `--help`/`-h` after a `--` terminator is treated as a positional, not a help
  request.
- `dispatch` flushes the writer after formatting a parse error so buffered
  diagnostics are not lost.
- Duration parsing returns `error.InvalidValue` on overflow instead of
  saturating to the max value.
- zsh completion descriptions escape `$` and backtick.

### Changed

- Reject, at compile time, reserved `--help`/`-h` flag names, a required
  positional declared after an optional one, and shell-unsafe static completion
  values.
- The `version`/`about` runner builtins no longer shadow a user-declared
  subcommand of the same name.
- Validation and generator diagnostics are name-agnostic (no `cli.` prefix) so
  `etc_cli` importers see matching messages.

[Unreleased]: https://github.com/rdrsss/etc-cli/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/rdrsss/etc-cli/releases/tag/v0.1.0
