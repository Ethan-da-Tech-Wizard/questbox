# questbox

A personal question-tracking database. Every question you fire off gets
filed with a timestamp, category, tags, an energy rating, and (optionally) a
link back to whatever question spawned it. It's backed by real SQLite, so you
can ask arbitrary questions about your own questions.

## Setup

Already done: `questbox.db` exists in this folder, built from `schema.sql`.
If you ever want to nuke and restart:

```
rm questbox.db
./qb init
```

## Day to day

```
./qb add "could a fridge be a load-bearing wall" -c engineering -t "weird,structural" -e 4
./qb add "what's the actual math on that"        -c engineering -t weird -e 3 -p 1   # -p = follow-up of #1
./qb answer 1 "no, but you could fake it with a false panel"
./qb status 2 exploring
./qb list --today
./qb show 1
./qb chain 1
./qb search "fridge"
```

Adding questions within 20 minutes of each other auto-groups them into the
same **session** — this is how the stats report finds your bursts. Tune it
with `--session-gap MINUTES` on `add`, or skip grouping with `--no-session`.

## Making sense of it

```
./qb stats
```

prints: status breakdown, category/tag frequency, tag co-occurrence, hourly
and weekday rhythm, burst sessions (3+ questions in one sitting), longest
follow-up chains, and average energy per category.

For anything the built-in report doesn't cover, you have full SQL:

```
./qb sql "SELECT date(created_at), count(*) FROM questions GROUP BY 1 ORDER BY 1"
./qb shell   # drops you straight into `sqlite3 questbox.db`
```

Useful views already defined in `schema.sql` (query these directly in `sql`/`shell`):

| view | what it shows |
|---|---|
| `v_daily_counts` | questions per calendar day |
| `v_hourly_pattern` | questions by hour of day |
| `v_weekday_pattern` | questions by day of week |
| `v_tag_freq` / `v_category_freq` | frequency tables |
| `v_tag_cooccurrence` | which tags cluster together |
| `v_bursts` | sessions with 3+ questions (your manic tears) |
| `v_status_breakdown` | open/exploring/answered/abandoned counts |
| `v_time_to_answer` | hours between asking and answering |
| `v_chain_sizes` | size of each question's whole follow-up tree |
| `v_avg_energy_by_category` | where your intensity actually goes |

Some starter "insane combos" once you have real data in here:

```sql
-- what do I ask about most right before I go quiet for a week?
SELECT c.name, count(*) FROM questions q
JOIN categories c ON c.id = q.category_id
WHERE q.id IN (SELECT max(id) FROM questions GROUP BY session_id)
GROUP BY c.name ORDER BY 2 DESC;

-- energy trend over time (is it escalating?)
SELECT date(created_at), avg(energy_level) FROM questions
GROUP BY 1 ORDER BY 1;

-- abandoned rate by tag -- which obsessions never get finished
SELECT t.name, count(*) FILTER (WHERE q.status='abandoned') * 1.0 / count(*) AS abandon_rate
FROM questions q JOIN question_tags qt ON qt.question_id=q.id JOIN tags t ON t.id=qt.tag_id
GROUP BY t.name HAVING count(*) >= 3 ORDER BY abandon_rate DESC;
```

## Files

- `schema.sql` — table + view definitions, the source of truth for structure
- `qb` — the CLI (Python 3 stdlib only, no deps)
- `questbox.db` — your actual data, plain SQLite file, back it up like you
  mean it (`cp questbox.db questbox.db.bak`)

## Command reference

`qb {init, add, answer, status, tag, untag, link, list, show, chain, search, categories, tags, sql, shell, stats}` — `qb <command> -h` for flags on any of them.
