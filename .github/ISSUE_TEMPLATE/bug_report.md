---
name: Bug report
about: Report incorrect parsing, generation, or validation behavior
title: ''
labels: bug
assignees: ''
---

## Summary

A clear, one-sentence description of the bug.

## Environment

- `etcli` version / commit:
- Zig version (`zig version`):
- OS:
- Shell (if the issue involves generated completions): bash / zsh / fish

## Minimal command tree

The smallest `Cmd` tree that reproduces the problem:

```zig
const root = cli.Cmd{
    .name = "tool",
    // ...
};
```

## Steps to reproduce

What you ran (e.g. `tool sub --flag value`) and, for generation/validation
issues, which API (`parse` / `dispatch` / `run` / `man` / `schema` /
`completion` / `validate`).

## Expected vs. actual

- Expected:
- Actual (include the exact output or error):
