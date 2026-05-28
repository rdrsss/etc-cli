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

Run the extracted package's tests with:

```sh
zig build test
```
