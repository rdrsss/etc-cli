const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .doc = .{
        .examples = &.{
            .{ .title = "Run target", .command = "tool run a" },
            .{ .title = "Run target", .command = "tool run b" },
        },
    },
};

comptime {
    cli.validate(root);
}
