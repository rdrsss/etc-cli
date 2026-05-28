const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--verbose", .kind = .bool, .value_name = "BOOL" },
    },
};

comptime {
    cli.validate(root);
}
