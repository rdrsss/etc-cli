const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cli_mod = b.addModule("cli", .{
        .root_source_file = b.path("src/cli/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const etc_cli_mod = b.addModule("etc_cli", .{
        .root_source_file = b.path("src/cli/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_tests = b.addRunArtifact(tests);

    const package_import_cli_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/package_import_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli_mod },
            },
        }),
    });
    const run_package_import_cli_tests = b.addRunArtifact(package_import_cli_tests);

    const package_import_etc_cli_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/package_import_etc_cli_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "etc_cli", .module = etc_cli_mod },
            },
        }),
    });
    const run_package_import_etc_cli_tests = b.addRunArtifact(package_import_etc_cli_tests);

    const parser_contract_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/parser_contract_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli_mod },
            },
        }),
    });
    const run_parser_contract_tests = b.addRunArtifact(parser_contract_tests);

    const parser_edge_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/parser_edge_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli_mod },
            },
        }),
    });
    const run_parser_edge_tests = b.addRunArtifact(parser_edge_tests);

    const dispatch_contract_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/dispatch_contract_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli_mod },
            },
        }),
    });
    const run_dispatch_contract_tests = b.addRunArtifact(dispatch_contract_tests);

    const help_completion_contract_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/help_completion_contract_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli_mod },
            },
        }),
    });
    const run_help_completion_contract_tests = b.addRunArtifact(help_completion_contract_tests);

    const man_contract_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("integration_tests/man_contract_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "cli", .module = cli_mod },
            },
        }),
    });
    const run_man_contract_tests = b.addRunArtifact(man_contract_tests);

    const run_compile_fail_tests = b.addSystemCommand(&.{ "sh", "scripts/compile_fail.sh" });

    const test_step = b.step("test", "Run unit and integration tests");
    test_step.dependOn(&run_tests.step);
    test_step.dependOn(&run_package_import_cli_tests.step);
    test_step.dependOn(&run_package_import_etc_cli_tests.step);
    test_step.dependOn(&run_parser_contract_tests.step);
    test_step.dependOn(&run_parser_edge_tests.step);
    test_step.dependOn(&run_dispatch_contract_tests.step);
    test_step.dependOn(&run_help_completion_contract_tests.step);
    test_step.dependOn(&run_man_contract_tests.step);
    test_step.dependOn(&run_compile_fail_tests.step);
}
