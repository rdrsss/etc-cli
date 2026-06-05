const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--cache", .kind = .bool },
        .{
            .long = "--no-cache",
            .kind = .string,
            .hidden = true,
            .deprecated = .{ .message = "Use --cache instead." },
        },
    },
};

comptime {
    cli.validate(root);
}
