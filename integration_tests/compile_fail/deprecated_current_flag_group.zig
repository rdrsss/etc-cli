const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--json", .kind = .bool },
        .{ .long = "--old", .deprecated = .{ .message = "Use --json instead." }, .kind = .bool },
    },
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_one, .flags = &.{ "--json", "--old" } },
    },
};

comptime {
    cli.validate(root);
}
