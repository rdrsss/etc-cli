const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{ .name = "run" },
        .{ .name = "execute", .aliases = &.{"run"} },
    },
};

comptime {
    cli.validate(root);
}
