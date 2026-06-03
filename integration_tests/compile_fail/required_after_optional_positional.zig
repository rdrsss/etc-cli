const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .positionals = &.{
                .{ .name = "first", .kind = .string, .required = false },
                .{ .name = "second", .kind = .string, .required = true },
            },
        },
    },
};

comptime {
    cli.validate(root);
}
