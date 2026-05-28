const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .doc = .{
        .examples = &.{
            .{ .title = "Empty", .command = "" },
        },
    },
};

comptime {
    cli.validate(root);
}
