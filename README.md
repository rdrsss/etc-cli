# etc-cli

`etc-cli` is a standalone Zig package for the comptime-driven CLI parser
extracted from Planar. It is intended to be shared by multiple tools that want
typed command trees, generated help, shell completion scripts, and a small
runtime parser with no dependencies beyond Zig `std`.

## Use

Add this package as a dependency from another Zig project, then import it under
the local name you want. The package exposes the same root under both `cli`
and `etc_cli`; `cli` matches Planar's existing module name.

```zig
const cli = @import("cli");
```

In the consuming project's `build.zig`, wire the dependency module into an
executable or library:

```zig
const etc_cli_dep = b.dependency("etc_cli", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("cli", etc_cli_dep.module("cli"));
```

## Example

```zig
const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "hello",
            .desc = "Print a greeting",
            .flags = &.{
                .{
                    .long = "--name",
                    .short = 'n',
                    .kind = .string,
                    .default = .{ .string = "world" },
                },
            },
            .run = cli.handler(handleHello),
        },
    },
};

comptime cli.validate(root);

fn handleHello(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{ "hello" }, args_ptr);
    std.debug.print("hello, {s}\n", .{args.name});
}
```

## Flag Values

String and integer flags accept both common value forms:

```sh
--name value
--name=value
```

Boolean flags are presence-based. `--verbose` is supported; `--verbose=true` is
not part of the current contract.

## Environment Metadata

`Flag.env` is currently reserved metadata. The parser does not read environment
variables, and an `env` setting does not satisfy a required flag. Consumers
should pass environment-derived defaults explicitly until env fallback behavior
is added as a deliberate feature.

## Completion Scripts

Completion scripts are generated at comptime for bash, zsh, and fish. Command
and flag descriptions are escaped for zsh and fish completion output so common
description text containing quotes or colons remains valid shell syntax.

## Man Pages

Man pages are generated at comptime from the same command tree:

```zig
const page = comptime cli.man.page(root, &.{ "hello" }, .{
    .title = "TOOL-HELLO",
    .source = "tool 1.0",
    .manual = "User Commands",
});
```

The generator infers command paths, subcommands, inherited flags, local flags,
flag kinds, defaults, required markers, positionals, `desc`, and `long_desc`
from `Cmd`, `Flag`, and `Positional` declarations. Use `Flag.value_name` when a
string or integer flag should render a domain-specific placeholder such as
`PATH` or `COUNT`; otherwise the generator falls back to `VALUE` for strings
and `N` for integers.

Manual-only content belongs in `Cmd.doc`. Examples, exit statuses, notes, and
see-also references enrich generated man pages but do not affect parsing,
dispatch, or generated argument types.

`Flag.env` renders in the man page ENVIRONMENT section as metadata only. The
parser still does not read environment variables, and generated text says so
explicitly.

Downstream projects can write generated pages from an opt-in build step. A
common shape is a tiny generator executable that imports the application's
command tree, calls `cli.man.page`, and writes files under a caller-provided
output directory:

```zig
const gen_man = b.addExecutable(.{
    .name = "gen-man",
    .root_source_file = b.path("tools/gen_man.zig"),
    .target = target,
    .optimize = optimize,
});
gen_man.root_module.addImport("cli", etc_cli_dep.module("cli"));

const run_gen_man = b.addRunArtifact(gen_man);
run_gen_man.addArg("zig-out/share/man/man1");

const man_step = b.step("man", "Generate man pages");
man_step.dependOn(&run_gen_man.step);
```

The generator executable can then write root and subcommand pages:

```zig
try dir.writeFile(.{
    .sub_path = "tool.1",
    .data = comptime cli.man.page(root, &.{}, .{}),
});
try dir.writeFile(.{
    .sub_path = "tool-hello.1",
    .data = comptime cli.man.page(root, &.{ "hello" }, .{}),
});
```

`etc-cli` intentionally returns plain roff text and does not install, compress,
or write man pages during normal tests. Packaging code should decide the output
directory, whether to gzip pages, and how to install them into `man1`.

## Validation

Call `comptime cli.validate(root);` near each command tree declaration. The
validator rejects duplicate subcommands, duplicate inherited flags, mismatched
default kinds, and required flags that also define defaults.

Negative validation behavior is covered by compile-fail fixtures under
`integration_tests/compile_fail/`. The default `zig build test` step runs those
fixtures through `scripts/compile_fail.sh` and asserts the expected compile-time
diagnostics.

## Tests

Run the extracted package's tests with:

```sh
zig build test
```

That command runs source-local unit tests, downstream-style import tests for both
`cli` and `etc_cli`, parser contract tests, dispatch tests, completion/help
tests, man-page generation tests, and compile-fail validation fixtures.
