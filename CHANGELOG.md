# Changelog

All notable changes to `etc-cli` are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
