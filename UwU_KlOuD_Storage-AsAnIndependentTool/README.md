# kloud

A cloud drive you actually own. Four small Python files, stdlib only, no
accounts, no third-party relay, nothing phoning home. Stores files on
whatever folder you point it at — an external SSD, say — serves them over
HTTP(S) to whoever holds the access token, reaches a second machine over
a self-hosted VPN, keeps both machines' drives in sync, and can turn
itself on and off on a schedule so nothing has to run 24/7.

This is the first tool in the questbox toolbox
(`UwU_KlOuD_Storage-AsAnIndependentTool` — rename the folder whenever you
like, nothing depends on the name).

## Start here: the menu

You should never need to remember a command. Run:

```
./kloud
```

with no arguments and you get this:

```
================ kloud ================
storage: set up  |  server: ON  |  VPN: connected  |  sync: set up
-----------------------------------------
 1) First time here? Start guided setup
 2) Turn the server ON
 3) Turn the server OFF
 4) Connect this machine to another one (VPN)
 5) Sync files with the other machine now
 6) Set an automatic schedule (so it's not on 24/7)
 7) Show full status
 8) Manage my access token
 9) Security tips
10) Quit
```

Option 1 is a straight line through everything a first-time user needs:
pick a folder, generate a token, turn the server on. Options 4–6 are
guided wizards for the VPN, sync, and rotation schedule — each one asks
plain-language questions (a name, an address, a time) and does the work;
you're never expected to know rsync flags or wg-quick syntax yourself.
Every action is wrapped so a mistake (bad path, unreachable peer, no
`cron` installed) prints a plain sentence and drops you back at the menu
— it will not crash out to a stack trace.

Every menu option also exists as a direct command (`kloud init`, `kloud
start`, `kloud-vpn`, `kloud-sync`, `kloud-schedule`) if you'd rather
script it — see below.

## 1. Storage — `kloud`

```
./kloud init --root /Volumes/YourSSD/kloud-data   # generates and prints a one-time token
./kloud start                                      # runs the server in the background
./kloud status                                     # storage/server/VPN/sync/schedule at a glance
./kloud stop
```

From another machine (same LAN, or over the VPN once that's set up):

```
curl -H "Authorization: Bearer <token>" http://<host>:8443/api/files
curl -X PUT -H "Authorization: Bearer <token>" --data-binary @file.txt \
  http://<host>:8443/api/files/file.txt
```

Or open `http://<host>:8443/` in a browser — paste the token in the box
at the top, then drag files in or click to download/delete.

**Security model:** the token is hashed (PBKDF2) before it's ever written
to disk, compared with a constant-time check, and never logged. Add
`--tls` on `init` for HTTPS with a self-signed cert (generated locally
via the system `openssl` binary — no CA, no outside party sees it). Off
your LAN, always go through the VPN below rather than exposing this raw.
`kloud token-new` (or menu option 8) revokes the old token and issues a
new one if a device holding it needs to be cut off.

## A note on dual-band / self-switching WiFi

If your router auto-switches devices between 2.4GHz/5GHz (band steering,
or a mesh system), the Mac's local IP can drift over time even though
it's the same physical network. `kloud start`/`status` now print the
Mac's Bonjour `.local` hostname alongside its current IP — use the
`.local` one for LAN access, since it keeps resolving correctly through
band switches and DHCP renewals; the IP is just a snapshot of right now.

That only fixes access *within* the same network, though. For the VPN
below, your router's port-forward rule for WireGuard's UDP port targets
one specific internal IP — if the Mac's IP drifts, that forwarding rule
quietly starts pointing at nothing. This needs a one-time fix in your
router's admin page, not in this code: give the Mac a **DHCP reservation**
(pin its WiFi MAC address to one IP forever), then point the port-forward
rule at that reserved IP. Look for "DHCP reservation," "static lease," or
"address reservation" in your router's settings.

## 2. VPN — `kloud-vpn`

Lets two machines reach each other securely when they're **not** on the
same LAN. Self-hosted WireGuard: no account, no coordination server run
by a company — just a protocol, and two machines that each hold the
other's public key. Needs `wireguard-tools` on each real machine
(`brew install wireguard-tools` on macOS). Not installed on this dev
sandbox, so `kloud-vpn` was tested here with a stubbed `wg` binary to
verify the config-generation logic; run the real thing on your Mac and
laptop.

Do menu option 4 (or the commands below) on **each** machine:

```
./kloud-vpn doctor                                         # confirm wg is installed
./kloud-vpn init --name mac --address 10.66.0.1/24
# -> prints this machine's public key + address, send it to the other side
./kloud-vpn peer add --name laptop --pubkey <their pubkey> \
  --endpoint <their-address-or-ddns>:51820 --allowed-ips 10.66.0.2/32
./kloud-vpn config                                          # writes .kloud/wg/wg0.conf
sudo wg-quick up /path/to/.kloud/wg/wg0.conf
```

Once both sides are up, the Mac's `kloud` is reachable at `10.66.0.1` from
the laptop over the tunnel. If neither machine has a static IP, put a
free dynamic-DNS hostname (or your router's own DDNS) in `--endpoint` —
it's just a hostname→IP lookup, it never sees your files.

## 3. Sync — `kloud-sync`

Two-way sync between this machine's storage and the other machine's, over
plain `rsync` + `ssh` (both already on macOS/Linux — system tools, not
services), meant to run over the VPN tunnel above.

```
./kloud-sync setup --peer-host 10.66.0.2 --peer-user ethan --peer-root /Users/ethan/kloud-data
./kloud-sync now       # pushes your changes, then pulls theirs
./kloud-sync status    # who it's paired with, when it last ran
```

Honest limitation: this is two `rsync --update` passes, not real conflict
resolution — whichever side's file is newer wins. Fine for "I'm working
from one machine at a time"; if both machines touch the *same* file in
the *same* window, the older edit silently loses. Good enough for a
personal rotation setup; not a substitute for real version control on
files you're actively co-editing.

## 4. Rotation schedule — `kloud-schedule`

Turns the server (and a sync pass) on and off on a daily window, so nothing
has to run around the clock.

```
./kloud-schedule set --start 21:00 --end 07:00   # live overnight, off during the day
./kloud-schedule status                           # is it currently inside the window?
./kloud-schedule install                          # adds a cron job that checks every 5 min
./kloud-schedule run                              # the check itself — what cron calls
```

`run` is idempotent: inside the window it starts the server if it isn't
running and syncs; outside the window it syncs one last time, then stops
the server. `install` needs `cron`/`crontab` on the machine — standard on
macOS and Linux, but if it's genuinely unavailable you'll get a plain
message telling you so, and you can still call `run` by hand (or from
any other scheduler you prefer) instead.

## Roadmap — what's still hand-built vs. still to come

Done: single-machine storage, self-hosted VPN, two-way sync, on/off
scheduling per machine. Not yet built: a shared rotation log so two
machines that were *both* offline for a while reconcile deterministically
instead of just trusting whoever's `rsync --update` ran last (a small
SQLite log, same pattern as `question-tracker`, is the planned fix —
useful once this moves from "two machines, mostly one active" to genuine
multi-node rotation with more than two participants).

## Files

- `kloud` — file-store server + daemon control (start/stop/status) +
  the interactive menu + the safety checklist, one file
- `kloud-vpn` — WireGuard identity/peer/config generator, one file
- `kloud-sync` — two-way rsync-over-ssh between two `kloud` machines
- `kloud-schedule` — daily on/off window + cron installer
- `.kloud/` — local config, token hash, TLS cert, WireGuard keys, sync
  and schedule config, pid/log of the running server (created as you use
  the tools above; never commit this — it's machine-specific, holds
  private key material, and is already gitignored)
