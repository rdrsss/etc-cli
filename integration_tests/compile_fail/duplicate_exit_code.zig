const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .doc = .{
        .exit_codes = &.{
            .{ .code = 2, .desc = "Invalid input." },
            .{ .code = 2, .desc = "Also invalid input." },
        },
    },
};

comptime {
    cli.validate(root);
}
