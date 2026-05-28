const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .doc = .{
        .exit_codes = &.{
            .{ .code = 2, .desc = "" },
        },
    },
};

comptime {
    cli.validate(root);
}
