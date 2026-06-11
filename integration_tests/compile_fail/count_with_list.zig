const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--verbose", .kind = .bool, .count = true, .list = true },
    },
};

comptime {
    cli.validate(root);
}
