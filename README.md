# Questbox

Small self-hosted tools for tracking questions, serving personal storage, synchronizing drives, and scheduling access.

**Status:** Command-line toolbox  
**Built with:** Python standard library, SQLite, WireGuard helpers

[Project guide](docs/PROJECT_GUIDE.md) · [Every file explained](docs/FILE_GUIDE.md) · [Licenses and dependencies](docs/LICENSE_REVIEW.md)

## Start here

- [PROJECT_NOTES.md](PROJECT_NOTES.md) — Preserved detailed setup, usage, architecture, and development notes from the earlier README.
- [question-tracker/README.md](question-tracker/README.md) — Documentation: questbox. Covers Setup; Day to day; Making sense of it.
- [UwU_KlOuD_Storage-AsAnIndependentTool/README.md](UwU_KlOuD_Storage-AsAnIndependentTool/README.md) — Documentation: kloud. Covers Start here: the menu; 1. Storage — `kloud`; A note on dual-band / self-switching WiFi.

[Detailed setup, usage, and development notes](PROJECT_NOTES.md) preserve the previous project documentation.

## Repository layout

| Path | Role |
| --- | --- |
| [UwU_KlOuD_Storage-AsAnIndependentTool/](UwU_KlOuD_Storage-AsAnIndependentTool/) | Project-specific UwU KlOuD Storage-AsAnIndependentTool components (5 tracked entries). |
| [docs/](docs/) | Project documentation, decisions, and reference material (5 tracked entries). |
| [question-tracker/](question-tracker/) | Project-specific question-tracker components (3 tracked entries). |

## Scope and current limits

The question database, storage contents, and generated access tokens belong in local runtime storage, not in Git.

## License

Original project code retains **MIT** terms in [LICENSE](LICENSE). Third-party libraries, media, data, models, and tools retain their own terms. See the [license review](docs/LICENSE_REVIEW.md) and [dependency inventory](docs/DEPENDENCIES.csv).
