# Questbox

Small self-hosted tools for tracking questions, serving personal storage, synchronizing drives, and scheduling access.

**Status:** Command-line toolbox  
**Built with:** Python standard library, SQLite, WireGuard helpers

## Reading order

1. Read the root README for project purpose and setup navigation.
2. Follow the entry points below to find the implementation.
3. Use the file guide to locate individual modules, tests, assets, and configuration.
4. Check component licenses before redistributing dependencies or assets.

## Important paths

- [PROJECT_NOTES.md](../PROJECT_NOTES.md) — Preserved detailed setup, usage, architecture, and development notes from the earlier README.
- [question-tracker/README.md](../question-tracker/README.md) — Documentation: questbox. Covers Setup; Day to day; Making sense of it.
- [UwU_KlOuD_Storage-AsAnIndependentTool/README.md](../UwU_KlOuD_Storage-AsAnIndependentTool/README.md) — Documentation: kloud. Covers Start here: the menu; 1. Storage — `kloud`; A note on dual-band / self-switching WiFi.

## Structure

| Path | Role |
| --- | --- |
| [UwU_KlOuD_Storage-AsAnIndependentTool/](../UwU_KlOuD_Storage-AsAnIndependentTool/) | Project-specific UwU KlOuD Storage-AsAnIndependentTool components (5 tracked entries). |
| [docs/](../docs/) | Project documentation, decisions, and reference material (5 tracked entries). |
| [question-tracker/](../question-tracker/) | Project-specific question-tracker components (3 tracked entries). |

## Scope

The question database, storage contents, and generated access tokens belong in local runtime storage, not in Git.

## Maintaining the guide

The file catalog is a source-inspection snapshot, not proof that every runtime path works. Update it when moving files or changing module responsibilities. The 2026-10-12 documentation review did not run every application, deploy services, or validate all historical performance claims.
