const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{ .name = "run" },
        .{ .name = "run" },
    },
};

comptime {
    cli.validate(root);
}
