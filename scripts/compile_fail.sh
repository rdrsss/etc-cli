#!/bin/sh
set -eu

run_case() {
    fixture="$1"
    expected="$2"

    output="$(zig test --dep cli -Mroot="$fixture" -Mcli=src/cli/root.zig 2>&1)" && {
        printf 'compile-fail fixture unexpectedly passed: %s\n' "$fixture" >&2
        exit 1
    }

    printf '%s' "$output" | grep -F "$expected" >/dev/null || {
        printf 'compile-fail fixture did not emit expected text: %s\n' "$fixture" >&2
        printf 'expected: %s\n' "$expected" >&2
        printf '%s\n' "$output" >&2
        exit 1
    }
}

run_case integration_tests/compile_fail/duplicate_subcommand.zig "duplicate sub-command name"
run_case integration_tests/compile_fail/alias_collision.zig "duplicate sub-command name or alias 'run'"
run_case integration_tests/compile_fail/invalid_command_name.zig "invalid command name '-tool'"
run_case integration_tests/compile_fail/duplicate_inherited_flag.zig "duplicate flag long name"
run_case integration_tests/compile_fail/invalid_long_flag.zig "invalid long flag '-verbose'"
run_case integration_tests/compile_fail/invalid_short_flag.zig "invalid short flag '--'"
run_case integration_tests/compile_fail/generated_field_collision.zig "generated args field 'target_id' collides"
run_case integration_tests/compile_fail/rest_field_collision.zig "generated args field 'tail' collides"
run_case integration_tests/compile_fail/default_kind_mismatch.zig "has default of kind"
run_case integration_tests/compile_fail/required_with_default.zig "required AND has a default"
run_case integration_tests/compile_fail/bool_value_name.zig "flag '--verbose' is bool and cannot define value_name"
run_case integration_tests/compile_fail/reserved_help_flag.zig "flag long name '--help' in command 'tool' is reserved"
run_case integration_tests/compile_fail/required_after_optional_positional.zig "required positional 'second' follows an optional positional"
run_case integration_tests/compile_fail/empty_value_name.zig "flag '--name' has empty value_name"
run_case integration_tests/compile_fail/duplicate_exit_code.zig "command 'tool' has duplicate exit code 2"
run_case integration_tests/compile_fail/empty_exit_description.zig "command 'tool' has exit code 2 with empty description"
run_case integration_tests/compile_fail/empty_example_command.zig "command 'tool' has doc example with empty command"
run_case integration_tests/compile_fail/duplicate_example_title.zig "duplicate doc example title 'Run target'"
run_case integration_tests/compile_fail/empty_doc_note.zig "command 'tool' has empty doc note"
run_case integration_tests/compile_fail/empty_doc_see_also.zig "command 'tool' has empty see_also entry"
run_case integration_tests/compile_fail/empty_completion_values.zig "completion kind .values with no values"
run_case integration_tests/compile_fail/unsafe_completion_value.zig "with an unsafe character"
run_case integration_tests/compile_fail/choice_without_choices.zig "must declare at least one entry"
run_case integration_tests/compile_fail/choices_on_non_choice.zig "declares \`choices\` but kind is not .choice"
run_case integration_tests/compile_fail/choice_default_not_member.zig "default 'c' is not one of its choices"
run_case integration_tests/compile_fail/bad_handler_arity.zig "handler must take exactly one parameter"
run_case integration_tests/compile_fail/bad_handler_param.zig "handler parameter must be"
run_case integration_tests/compile_fail/bad_handler_return.zig "handler must return"
run_case integration_tests/compile_fail/invalid_man_section.zig "man.page: section must be between 1 and 9"
