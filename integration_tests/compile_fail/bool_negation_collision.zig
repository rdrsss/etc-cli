const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--color", .kind = .bool },
        .{ .long = "--no-color", .kind = .string },
    },
};

comptime {
    cli.validate(root);
}
