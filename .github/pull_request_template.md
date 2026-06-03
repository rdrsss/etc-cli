## What

Briefly describe the change and the motivation.

## Checklist

- [ ] `zig build test --summary all` is green locally.
- [ ] `CHANGELOG.md` updated under `## Unreleased` for any user-visible change.
- [ ] Added/updated a `compile_fail` fixture for any new `comptime` validation rule.
- [ ] Updated `integration_tests/snapshots/` if generated output changed (diff is intentional).
- [ ] Noted any compatibility impact on public types, generated artifacts, parser semantics, schema shape, or validation rules (see `docs/release.md`).

## Notes

Anything reviewers should pay particular attention to.
