# docs folder guide

This folder stores the public-facing non-code materials that are suitable for a
shared repository.

```text
docs/
|-- assets/
|-- 01_presentation/
|-- 02_report_materials/
|-- 03_specifications/
`-- 04_references/
```

## Public vs local-only assets

Public repository:

- keeps selected preview figures for the top-level `README.md`
- keeps lightweight summaries and index files
- keeps scenario notes and reference lists
- avoids storing personal or institution-specific materials

Local-only assets:

- private slide decks
- private course report drafts
- assignment PDF handouts
- downloaded reference paper binaries
- generated outputs and defense build artifacts

Local-only assets should live under `private_local/` and are ignored by Git.
