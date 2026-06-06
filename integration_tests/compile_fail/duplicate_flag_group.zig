const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--json", .kind = .bool },
        .{ .long = "--yaml", .kind = .bool },
    },
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_one, .flags = &.{"--json"} },
        .{ .name = "output", .mode = .mutually_exclusive, .flags = &.{"--yaml"} },
    },
};

comptime {
    cli.validate(root);
}
