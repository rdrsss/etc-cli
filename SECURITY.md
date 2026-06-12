# Security Policy

## Supported versions

`etcli` is pre-1.0. Security fixes are applied to the latest released tag on
the `master` branch.

## Reporting a vulnerability

Please report security-sensitive issues privately rather than opening a public
issue:

- Preferred: open a [GitHub security advisory](https://github.com/rdrsss/etcli/security/advisories/new)
  for this repository.
- Alternatively, email **manuel.rdrs@gmail.com** with details and, if possible,
  a minimal reproduction.

You can expect an initial acknowledgement within a few days. Once a fix is
available, it will be released and the advisory published with credit unless you
prefer to remain anonymous.

## Scope notes

`etcli` is a parsing and code-generation library with no network or
filesystem access of its own. The relevant attack surface is:

- **Runtime argv parsing** — untrusted command-line input handled by `parse`,
  `dispatch`, and `run`.
- **Generated artifacts** — bash/zsh/fish completion scripts, man pages, and
  JSON schema generated at comptime from an author-declared command tree.
  Completion values are validated to be shell-safe at compile time, but report
  any case where author-declared metadata can produce unsafe generated output.

Command trees are author-supplied compile-time constants, so issues stemming
from a project's own tree definition are configuration concerns, not
vulnerabilities in `etcli`.
