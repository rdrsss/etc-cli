const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .flags = &.{
                .{ .long = "--mode", .kind = .string, .completion = cli.Completion.valueChoices(&.{ "json", "text" }) },
                .{ .long = "--input", .kind = .string, .completion = cli.Completion.files },
                .{ .long = "--directory", .kind = .string, .completion = cli.Completion.directories },
                .{ .long = "--host", .kind = .string, .completion = cli.Completion.dynamic(completeHosts) },
            },
            .positionals = &.{
                .{ .name = "target", .completion = cli.Completion.valueChoices(&.{ "alpha", "beta" }) },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

fn completeHosts(prefix: []const u8) []const []const u8 {
    if (std.mem.eql(u8, prefix, "none")) return &.{};
    if (prefix.len == 0) return &.{ "alpha.example", "beta.example" };
    if (std.mem.startsWith(u8, "alpha.example", prefix)) return &.{"alpha.example"};
    if (std.mem.startsWith(u8, "beta.example", prefix)) return &.{"beta.example"};
    return &.{};
}

test "static flag and positional value completions render for bash zsh and fish" {
    const bash = comptime cli.completion.script(root, .bash);
    try expectContains(bash, "--mode)");
    try expectContains(bash, "json text");
    try expectContains(bash, "compgen -f");
    try expectContains(bash, "compgen -d");
    try expectContains(bash, "alpha beta");

    const zsh = comptime cli.completion.script(root, .zsh);
    try expectContains(zsh, "--mode)");
    try expectContains(zsh, "_values 'values' \"json\" \"text\"");
    try expectContains(zsh, "_files -/");
    try expectContains(zsh, "\"alpha\" \"beta\"");

    const fish = comptime cli.completion.script(root, .fish);
    try expectContains(fish, "-l 'mode' -a 'json text'");
    try expectContains(fish, "-l 'input'");
    try expectContains(fish, "__fish_complete_directories");
    try expectContains(fish, "-a 'alpha beta'");
}

test "static value completions produce filtered candidate output" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try expectBashCandidates(tmp.dir, &.{ "tool", "run", "--mode", "j" }, "json\n", &.{}, &.{"text\n"});
    try expectBashCandidates(tmp.dir, &.{ "tool", "run", "b" }, "beta\n", &.{}, &.{"alpha\n"});
}

test "bash completion with no matching static values returns no candidates" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try expectBashCandidates(tmp.dir, &.{ "tool", "run", "--mode", "xml" }, "", &.{}, &.{ "json\n", "text\n" });
}

test "path completions produce filesystem candidate output" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "alpha.txt", .data = "" });
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "beta.txt", .data = "" });
    try tmp.dir.createDir(std.testing.io, "alpha-dir", .default_dir);

    try expectBashCandidates(tmp.dir, &.{ "tool", "run", "--input", "alpha" }, null, &.{ "alpha.txt\n", "alpha-dir\n" }, &.{"beta.txt\n"});
    try expectBashCandidates(tmp.dir, &.{ "tool", "run", "--directory", "alpha" }, "alpha-dir\n", &.{}, &.{ "alpha.txt\n", "beta.txt\n" });
}

test "dynamic completion with empty prefix output returns normally" {
    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try cli.complete(root, &.{ "--host", "a" }, &writer);
    try std.testing.expectEqualStrings("alpha.example\n", writer.buffered());

    writer = std.Io.Writer.fixed(&buf);
    try cli.complete(root, &.{ "--host", "none" }, &writer);
    try std.testing.expectEqualStrings("", writer.buffered());
}

test "schema exposes completion metadata" {
    const schema = comptime cli.schema.json(root, .{});
    try expectContains(schema, "\"completion\":{\"kind\":\"values\",\"values\":[\"json\",\"text\"]}");
    try expectContains(schema, "\"completion\":{\"kind\":\"files\",\"values\":[]}");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}

fn expectBashCandidates(
    dir: std.Io.Dir,
    words: []const []const u8,
    expected_stdout: ?[]const u8,
    present: []const []const u8,
    absent: []const []const u8,
) !void {
    const gpa = std.testing.allocator;
    try dir.writeFile(std.testing.io, .{
        .sub_path = "tool.bash",
        .data = comptime cli.completion.script(root, .bash),
    });

    const source = try bashCompletionSource(gpa, words);
    defer gpa.free(source);

    const result = std.process.run(gpa, std.testing.io, .{
        .argv = &.{ "bash", "-c", source },
        .cwd = .{ .dir = dir },
    }) catch |err| switch (err) {
        error.FileNotFound => return error.SkipZigTest,
        else => return err,
    };
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);
    try std.testing.expectEqualStrings("", result.stderr);
    if (expected_stdout) |expected| {
        try std.testing.expectEqualStrings(expected, result.stdout);
    }
    for (present) |needle| {
        try expectContains(result.stdout, needle);
    }
    for (absent) |needle| {
        try std.testing.expect(std.mem.indexOf(u8, result.stdout, needle) == null);
    }
}

fn bashCompletionSource(gpa: std.mem.Allocator, words: []const []const u8) ![]u8 {
    var source: std.ArrayList(u8) = .empty;
    defer source.deinit(gpa);

    try source.appendSlice(gpa,
        \\source ./tool.bash
        \\COMP_WORDS=(
    );
    for (words) |word| {
        try source.append(gpa, ' ');
        try appendBashSingleQuoted(&source, gpa, word);
    }
    try source.appendSlice(gpa, " )\nCOMP_CWORD=");
    var index_buf: [32]u8 = undefined;
    try source.appendSlice(gpa, try std.fmt.bufPrint(&index_buf, "{d}", .{words.len - 1}));
    try source.appendSlice(gpa,
        \\
        \\_tool
        \\if ((${#COMPREPLY[@]})); then
        \\    printf '%s\n' "${COMPREPLY[@]}"
        \\fi
        \\
    );
    return try source.toOwnedSlice(gpa);
}

fn appendBashSingleQuoted(list: *std.ArrayList(u8), gpa: std.mem.Allocator, value: []const u8) !void {
    try list.append(gpa, '\'');
    for (value) |c| {
        if (c == '\'') {
            try list.appendSlice(gpa, "'\\''");
        } else {
            try list.append(gpa, c);
        }
    }
    try list.append(gpa, '\'');
}
