# Changelog

All notable changes to `etcli` are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-06-12

### Added

- Colorized help output. `help.Options` gains `color: bool`, which wraps
  section headers (bold) and command/flag names (cyan) in ANSI escapes at
  comptime; column alignment is computed from the uncolored label so layout is
  unchanged. `cli.run` gains `color: ColorMode` (`.auto`/`.always`/`.never`,
  default `.auto`) and `stdout_tty: bool`; `.auto` colorizes only when
  `stdout_tty` is set and `NO_COLOR` is absent (resolved via `env_lookup`). The
  runner selects the colored or plain comptime variant at runtime.
- Count flags via `Flag.count = true`: a value-less flag that accumulates its
  occurrences (`-vvv` or `--verbose --verbose --verbose` yields `3`). The
  generated field is `u32` (default `0`, saturating). Requires `kind == .bool`
  and is mutually exclusive with `list`, `default`, `required`, `value_name`,
  and `--no-` negation (all enforced at comptime). Renders as `count`
  `(repeatable)` in help/man and `"count": true` in the schema.
- Command-level flag groups via `FlagGroup`, `FlagGroupMode`, and
  `Cmd.flag_groups`. Groups support `.mutually_exclusive`, `.required_one`, and
  `.required_exactly_one`, validate canonical visible flag members at comptime,
  enforce the selected command path at parse time, and render in help, man
  pages, and schema JSON.
- `cli.run` environment fallback now resolves the command path first and applies
  `Flag.env` to all visible flags on that path, including inherited, local,
  bool, list, and scalar value flags. Precedence remains argv > environment >
  default > required error, and `parse`/`dispatch` remain environment-unaware.
- Schema generation accepts `.include_command_tree = true` to add an opt-in
  nested `commandTree` view while preserving the default flat
  `"schemaVersion": 1` schema. Flat entries and tree nodes carry matching
  command metadata, including flag groups, docs, completion, and
  `cli-run-fallback` env behavior where applicable.
- Shell completion now completes long `--flag=value` prefixes and short
  separated or attached value forms using the same static, file, directory, or
  dynamic value sources, while preserving command-path tracking after consumed
  flag values.
- Packaging artifact helpers now expose advisory `category` and
  `destination_hint` metadata for man pages, bash/zsh/fish completions, and
  schema artifacts without installing, compressing, or writing files.
- Generated help and man pages now render command and flag `aliases` alongside
  the canonical name (e.g. `status, st, stat` and `--output, -o, --out`),
  matching what completion and schema already exposed.
- `cli.run` now emits a stderr deprecation warning for each deprecated *flag*
  actually used on the command line, mirroring the existing command-level
  warning. The parser records used-deprecated flags in a module-static buffer
  exposed as `cli.deprecatedFlagsSeen()`; `parse`/`dispatch` stay quiet and
  env-unaware.

### Fixed

- Schema JSON now escapes C0 control characters in description text (`\b`,
  `\f`, and `\u00XX` for the rest) instead of emitting them raw, which produced
  invalid JSON.

### Changed

- **BREAKING:** The package is renamed from `etc-cli` to `etcli`. The
  `build.zig.zon` package name is now `.etcli` and the dependency module is
  exposed as `etcli` (the canonical `cli` module name is unchanged). Downstream
  consumers must update `zig fetch`/`b.dependency` to `etcli` and re-pin to
  `v0.2.0`; the old `etc_cli` import name no longer resolves.
- The completion lint gate now fails when a supported shell has no committed
  completion snapshots, and syntax-checks bash, zsh, and fish snapshots when the
  corresponding shell is installed.

## [0.1.1] - 2026-06-03

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
- Custom value validators: `Flag.validator`/`Positional.validator`
  (`fn([]const u8) ?[]const u8`) run after kind coercion and surface a custom
  message via `InvalidValue` (new `Detail.message`).
- Repeatable (list) flags: `Flag.list = true` accumulates `--tag a --tag b` into
  a `[]const []const u8` field (string/path/choice elements; choice membership
  enforced per item). Renders as repeatable in help/man and `"list"` in schema.
- Environment fallback in the `cli.run` runner via `Options.env_lookup`: global
  non-bool `.env` flags absent from argv are filled from the environment
  (precedence argv > env > default > required). `parse`/`dispatch` stay
  env-unaware.
- Dynamic shell completion: `cli.Completion.dynamic(fn)` declares a runtime
  completion callback. Generated bash/zsh/fish scripts call the program's
  `__complete` builtin (auto-wired by `cli.run`, or `cli.complete` to wire
  manually); static completion is unchanged.

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

[Unreleased]: https://github.com/rdrsss/etcli/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/rdrsss/etcli/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/rdrsss/etcli/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/rdrsss/etcli/releases/tag/v0.1.0
