const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--help", .kind = .bool },
    },
};

comptime {
    cli.validate(root);
}
