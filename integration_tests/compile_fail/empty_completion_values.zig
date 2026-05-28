const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .flags = &.{
                .{ .long = "--mode", .completion = .{ .kind = .values } },
            },
        },
    },
};

comptime {
    cli.validate(root);
}
