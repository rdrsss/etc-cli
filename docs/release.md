# Release And API Policy

`etcli` is a source package consumed by Zig projects. Releases should keep the
public module contract predictable and make generated artifact changes explicit.

## Versioning

- Use semantic versioning once the first public tag is cut.
- **Pre-1.0 (`0.1.x`):** the API is still stabilizing, so additive changes
  (new kinds, flags, metadata fields, generated-artifact options, broader
  parser syntax) ship in patch releases. Reserve a `0.y` minor bump for a
  breaking change; treat the `0.1.x` line as a rolling additive series.
- Post-1.0, the rules below apply:
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
consumers can ignore them. Options that explicitly request extra output, such as
`include_command_tree`, may keep the current version when the default output
shape is unchanged; the default flat schema remains version 1 until it changes
incompatibly.

Additive artifact metadata fields and enum values, including install category
and destination hints, are compatibility additions. Changing artifact names,
removing metadata fields, or making the library perform filesystem writes would
be a breaking packaging-policy change.

Completion improvements that broaden when existing declared value completions
are offered are additive. Generated script entrypoint names, dynamic
`__complete` argv shape, and completion artifact filenames are part of the
public contract.

Validation and parser changes need explicit release notes. Accepting additional
argv syntax is additive; rejecting declarations or argv that were previously
documented as valid is breaking. Rejecting invalid, ambiguous, or internally
inconsistent declarations at comptime is allowed in the `0.1.x` additive series
when called out in `CHANGELOG.md`.

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
