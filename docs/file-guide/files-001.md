# Files 1 of 1 — Questbox

[All pages](../FILE_GUIDE.md) · [Project guide](../PROJECT_GUIDE.md)

| File | Role and useful details |
| --- | --- |
| [.gitignore](../../.gitignore) | Defines local data, credentials, dependencies, and generated outputs that Git should leave untracked. |
| [LICENSE](../../LICENSE) | Preserved license, copyright, or attribution terms; read the full text before reusing the covered component. |
| [PROJECT_NOTES.md](../../PROJECT_NOTES.md) | Preserved detailed setup, usage, architecture, and development notes from the earlier README. |
| [README.md](../../README.md) | Project overview, current status, entry points, setup navigation, and documentation links. |
| [UwU_KlOuD_Storage-AsAnIndependentTool/README.md](../../UwU_KlOuD_Storage-AsAnIndependentTool/README.md) | Documentation: kloud. Covers Start here: the menu; 1. Storage — `kloud`; A note on dual-band / self-switching WiFi. |
| [UwU_KlOuD_Storage-AsAnIndependentTool/kloud](../../UwU_KlOuD_Storage-AsAnIndependentTool/kloud) | kloud -- a self-hosted, zero-dependency file store. Defines `load_config`, `save_config`, `hash_token`, `_read_state`, `_pid_alive`, `_running_info` and 22 more top-level symbols. |
| [UwU_KlOuD_Storage-AsAnIndependentTool/kloud-schedule](../../UwU_KlOuD_Storage-AsAnIndependentTool/kloud-schedule) | kloud-schedule -- turns this machine's kloud server (and a sync pass) on and off on a daily time window, so it isn't running 24/7. Driven by cron (standard on macOS/Linux, not a se… Defines `_parse_hhmm`, `cmd_set`, `_in_window`, `load_schedule`, `cmd_status`, `_is_running` and 6 more top-level symbols. |
| [UwU_KlOuD_Storage-AsAnIndependentTool/kloud-sync](../../UwU_KlOuD_Storage-AsAnIndependentTool/kloud-sync) | kloud-sync -- two-way delta sync between this machine's kloud storage and another machine's, over plain rsync+ssh (both standard system tools, already on your machine, not a hosted… Defines `local_root`, `load_sync_config`, `cmd_setup`, `_rsync`, `cmd_now`, `cmd_status` and 1 more top-level symbols. |
| [UwU_KlOuD_Storage-AsAnIndependentTool/kloud-vpn](../../UwU_KlOuD_Storage-AsAnIndependentTool/kloud-vpn) | kloud-vpn -- generate and manage a self-hosted WireGuard tunnel by hand. Defines `require_wg`, `cmd_doctor`, `load_peers`, `save_peers`, `cmd_init`, `cmd_peer_add` and 4 more top-level symbols. |
| [docs/DEPENDENCIES.csv](../../docs/DEPENDENCIES.csv) | Machine-readable inventory of declared and locked dependencies, versions, reported licenses, and evidence URLs. |
| [docs/FILE_GUIDE.md](../../docs/FILE_GUIDE.md) | Index of the complete tracked-file guide, with one entry for every file and links to the paginated descriptions. |
| [docs/LICENSE_REVIEW.md](../../docs/LICENSE_REVIEW.md) | Original-code license, preserved component notices, dependency-license evidence, and unresolved distribution questions. |
| [docs/PROJECT_GUIDE.md](../../docs/PROJECT_GUIDE.md) | Maintainer orientation: purpose, important entry points, source layout, commands, and project-specific boundaries. |
| [docs/file-guide/files-001.md](../../docs/file-guide/files-001.md) | One page of the tracked-file catalog; links each listed path to its role and source-derived details. |
| [question-tracker/README.md](../../question-tracker/README.md) | Documentation: questbox. Covers Setup; Day to day; Making sense of it. |
| [question-tracker/qb](../../question-tracker/qb) | questbox (qb) -- a personal question-tracking CLI backed by SQLite. Defines `connect`, `now_str`, `print_table`, `get_or_create`, `resolve_session`, `cmd_init` and 16 more top-level symbols. |
| [question-tracker/schema.sql](../../question-tracker/schema.sql) | Database definition or migration for schema; creates `sessions`, `categories`, `tags`, `questions`, `question_tags`. |
