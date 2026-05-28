# Release And API Policy

`etc-cli` is a source package consumed by Zig projects. Releases should keep the
public module contract predictable and make generated artifact changes explicit.

## Versioning

- Use semantic versioning once the first public tag is cut.
- Bump patch for bug fixes and documentation-only improvements.
- Bump minor for additive APIs, new metadata fields, new generated artifact
  options, or broader accepted parser syntax.
- Bump major for breaking changes to public types, generated `ArgsType` field
  names, parser semantics, schema shape, artifact naming, or validation rules.

## API Stability

Public API includes exports from `src/cli/root.zig`, generated help/man/schema
contracts, completion script behavior, parse error kinds, and validation
diagnostics that downstream tests reasonably match.

Schema JSON includes `schemaVersion`. Increment it when consumers need to branch
on shape changes. Additive fields may remain on the current version when old
consumers can ignore them.

## Release Checklist

1. Update `CHANGELOG.md`.
2. Run `zig build test --summary all`.
3. Confirm generated snapshot diffs are intentional.
4. Tag the release.
5. Push the tag and publish package metadata used by downstream projects.
