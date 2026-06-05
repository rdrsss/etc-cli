const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--color", .aliases = &.{"--colour"}, .kind = .bool },
    },
    .cmds = &.{
        .{
            .name = "paint",
            .flags = &.{
                .{ .long = "--mode", .aliases = &.{"--no-colour"}, .kind = .string },
            },
        },
    },
};

comptime {
    cli.validate(root);
}
