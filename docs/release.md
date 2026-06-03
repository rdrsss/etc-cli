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

1. Bump `.version` in `build.zig.zon` to the release version.
2. Move the `## [Unreleased]` entries in `CHANGELOG.md` under a new
   `## [x.y.z] - <date>` heading and refresh the comparison links.
3. Run `zig build snapshots-update` and confirm any snapshot diffs are
   intentional.
4. Run `zig build test --summary all`.
5. Verify `LICENSE` is present and that the README `## License` section matches.
6. Confirm a clean checkout containing only the `build.zig.zon` `.paths`
   entries builds and tests (`zig build test`).
7. Tag the release (`vX.Y.Z`) and push the tag.
8. Publish package metadata used by downstream projects.
