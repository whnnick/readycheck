# Local Codex Fixtures

Fixtures in this directory must be derived from inspected local records with all user text, paths, thread ids, tokens, and account identifiers removed.

The Local Codex provider must fail closed unless fixtures prove the parser can identify:

- the relevant usage field,
- the reset boundary,
- the quota window kind,
- and an independent validation signal.

Do not add raw Codex databases or raw logs to this directory.
