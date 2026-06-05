const std = @import("std");
const cli = @import("cli");

fn listFlags() []const cli.Flag {
    comptime {
        var flags: [17]cli.Flag = undefined;
        for (0..flags.len) |idx| {
            flags[idx] = .{
                .long = std.fmt.comptimePrint("--list-{d}", .{idx}),
                .kind = .string,
                .list = true,
            };
        }
        const final = flags;
        return &final;
    }
}

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .flags = listFlags(),
        },
    },
};

comptime {
    cli.validate(root);
}

test "parser rejects commands over the list flag row cap" {
    var detail: cli.Detail = undefined;
    _ = try cli.parse(root, &.{ "tool", "run", "--list-16", "value" }, &detail);
}
