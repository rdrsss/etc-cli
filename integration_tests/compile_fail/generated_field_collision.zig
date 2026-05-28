const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--target-id", .kind = .string },
    },
    .positionals = &.{
        .{ .name = "target-id" },
    },
};

comptime {
    cli.validate(root);
}
