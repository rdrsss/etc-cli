const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--json", .kind = .bool },
        .{ .long = "--yaml", .kind = .bool },
    },
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_one, .flags = &.{ "--json", "--json", "--yaml" } },
    },
};

comptime {
    cli.validate(root);
}
