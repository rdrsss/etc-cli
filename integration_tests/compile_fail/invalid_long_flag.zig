const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "-verbose", .kind = .bool },
    },
};

comptime {
    cli.validate(root);
}
