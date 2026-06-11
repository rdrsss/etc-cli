const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--level", .kind = .int, .count = true },
    },
};

comptime {
    cli.validate(root);
}
