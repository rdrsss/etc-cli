const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--color", .aliases = &.{"--colour"}, .kind = .bool },
        .{ .long = "--no-colour", .kind = .string },
    },
};

comptime {
    cli.validate(root);
}
