# questbox

A toolbox of niche, self-built tools. Everything in here is meant to be
fully yours: no third-party services, no telemetry, no accounts, free to
run forever — hand-built on open protocols, not wrapped around someone
else's platform.

## Tools

- [`question-tracker/`](question-tracker/README.md) — a personal
  question-tracking database (`qb`). File every question you ask with a
  timestamp, category, tags, and energy rating; query the shape of your
  own thinking with real SQL.
- [`UwU_KlOuD_Storage-AsAnIndependentTool/`](UwU_KlOuD_Storage-AsAnIndependentTool/README.md)
  (`kloud`) — self-hosted cloud storage with a guided menu. Point it at
  an external drive, serve it over your own network with a token only
  you hold, connect a second machine over a self-hosted WireGuard VPN,
  keep both drives in sync, and set a daily on/off schedule so nothing
  has to run 24/7.

Each tool is self-contained in its own folder with its own README. The
shared rule across all of them: Python 3 stdlib only, no dependencies, no
data leaving your own machines unless you explicitly send it somewhere.
