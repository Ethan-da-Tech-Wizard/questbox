-- ==============================================================================
-- Program: schema.sql
-- Programmer: Ethan-da-Tech-Wizard
-- Last Modified: November 18, 2026
-- Purpose: SQLite relational database schema definition for the questbox engine.
--          Defines tables, relationships, and constraints for sessions, categories,
--          tags, questions, full-text indexing, and analytical recursive views.
-- ==============================================================================

-- questbox schema
-- A personal question-tracking database: every question you fire off gets
-- filed here with enough metadata to later mine for patterns (scope, flow,
-- timing, obsessions, follow-through).

-- Who uses this file: `qb init` (question-tracker/qb) reads it and runs it with executescript(), once, to
-- create an empty database. Everything is IF NOT EXISTS, so applying it again to an existing database is
-- harmless and only adds objects that are missing (it never alters or drops existing ones, so a column change
-- needs a manual migration).
--
-- Layout: five tables (sessions, categories, tags, questions, question_tags), indexes on the columns the
-- CLI filters by, an FTS5 full-text index kept in sync by triggers, and views that hold all the
-- analytics. The Python side stays thin because these views do the counting.
--
-- Timestamps are stored as text 'YYYY-MM-DDTHH:MM:SS' in local time, which sorts correctly as a string and
-- works with SQLite's date functions. The foreign_keys pragma below only affects this one connection (the
-- setup run); qb's connect() sets it again on every connection, which is what actually enforces the rules
-- during normal use.
PRAGMA foreign_keys = ON;

-- A "session" is an auto-detected burst of questions asked close together in
-- time. This is what lets you later ask "when do I go on a tear?".
CREATE TABLE IF NOT EXISTS sessions (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    ended_at   TEXT,
    note       TEXT
);

-- Categories: one row per distinct name (UNIQUE), so get_or_create() in qb can look names up. A question
-- has at most one category.
CREATE TABLE IF NOT EXISTS categories (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Tags: free-form labels, many per question (see question_tags). Same UNIQUE-name pattern as categories.
CREATE TABLE IF NOT EXISTS tags (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- The central table: one row per question asked.
-- created_at defaults to local "now" in the same text format qb uses, so rows inserted with plain SQL
-- (qb sql) stay consistent. ON DELETE SET NULL on category, parent and session means deleting those
-- rows keeps the question and only drops the link, so history is never lost by tidying categories.
-- status is limited to four values by the CHECK below (and by argparse in qb).
CREATE TABLE IF NOT EXISTS questions (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime')),
    text         TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    -- self-rated intensity at the moment you asked it, 1 (idle curiosity) to
    -- 5 (can't stop thinking about this)
    energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 5),
    status       TEXT NOT NULL DEFAULT 'open'
                 CHECK (status IN ('open', 'exploring', 'answered', 'abandoned')),
    answer       TEXT,
    answered_at  TEXT,
    -- follow-up chains: a question can branch off an earlier one
    parent_id    INTEGER REFERENCES questions(id) ON DELETE SET NULL,
    session_id   INTEGER REFERENCES sessions(id) ON DELETE SET NULL
);

-- Many-to-many link between questions and tags. The composite primary key stops the same tag being attached
-- twice (qb relies on that with INSERT OR IGNORE). CASCADE: removing a question or a tag removes its links.
CREATE TABLE IF NOT EXISTS question_tags (
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    tag_id      INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, tag_id)
);

-- Indexes for the columns qb filters or groups on: time (list --since/--today, daily/hourly views), status
-- (list --status, status breakdown), parent (follow-up chains), session (burst view) and category.
-- For a personal-sized database they matter little for speed, but they keep the recursive chain queries cheap.
CREATE INDEX IF NOT EXISTS idx_questions_created ON questions(created_at);
CREATE INDEX IF NOT EXISTS idx_questions_status  ON questions(status);
CREATE INDEX IF NOT EXISTS idx_questions_parent  ON questions(parent_id);
CREATE INDEX IF NOT EXISTS idx_questions_session ON questions(session_id);
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category_id);

-- Full-text search over question + answer text.

-- content='questions' makes this an "external content" FTS5 table: it stores only the search index, not a
-- second copy of the text; rowid matches questions.id. That saves space but means the index has to be
-- updated by hand, which the three triggers below do.
CREATE VIRTUAL TABLE IF NOT EXISTS questions_fts USING fts5(
    text, answer, content='questions', content_rowid='id'
);

-- Keep the index in step with the table. After an insert: add the new text and answer to the index.
CREATE TRIGGER IF NOT EXISTS questions_ai AFTER INSERT ON questions BEGIN
    INSERT INTO questions_fts(rowid, text, answer) VALUES (new.id, new.text, new.answer);
END;

-- After a delete: FTS5's special 'delete' command must be given the OLD values so it can remove the
-- right index entries; passing anything else would corrupt the index.
CREATE TRIGGER IF NOT EXISTS questions_ad AFTER DELETE ON questions BEGIN
    INSERT INTO questions_fts(questions_fts, rowid, text, answer)
    VALUES ('delete', old.id, old.text, old.answer);
END;

-- After an update (for example `qb answer`): remove the old index entries, then add the new ones. Done as
-- two statements because FTS5 external-content tables have no direct "update".
CREATE TRIGGER IF NOT EXISTS questions_au AFTER UPDATE ON questions BEGIN
    INSERT INTO questions_fts(questions_fts, rowid, text, answer)
    VALUES ('delete', old.id, old.text, old.answer);
    INSERT INTO questions_fts(rowid, text, answer) VALUES (new.id, new.text, new.answer);
END;

-- ---------------------------------------------------------------------
-- Views: the "insane data combos" layer. Query these directly, or build
-- more with `qb sql` / `qb shell`.
-- ---------------------------------------------------------------------

-- Rhythm: how many questions land on each calendar day.

-- (v_daily_counts is not used by `qb stats`; query it with `qb sql "select * from v_daily_counts"`.)
CREATE VIEW IF NOT EXISTS v_daily_counts AS
SELECT date(created_at) AS day, count(*) AS n
FROM questions GROUP BY day ORDER BY day;

-- Rhythm: what hour of the day you tend to spiral in.
CREATE VIEW IF NOT EXISTS v_hourly_pattern AS
SELECT strftime('%H', created_at) AS hour, count(*) AS n
FROM questions GROUP BY hour ORDER BY hour;

-- Day-of-week pattern (0 = Sunday).

-- The CASE turns SQLite's weekday number (%w) into a name; the number is kept as column `w` so the view
-- sorts Sunday to Saturday rather than alphabetically.
CREATE VIEW IF NOT EXISTS v_weekday_pattern AS
SELECT CASE strftime('%w', created_at)
         WHEN '0' THEN 'Sun' WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue'
         WHEN '3' THEN 'Wed' WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri'
         ELSE 'Sat' END AS weekday,
       strftime('%w', created_at) AS w,
       count(*) AS n
FROM questions GROUP BY weekday, w ORDER BY w;

-- Tag usage counts, most used first (qb tags, qb stats). Tags with no questions do not appear because the
-- count starts from the link table.
CREATE VIEW IF NOT EXISTS v_tag_freq AS
SELECT t.name, count(*) AS n
FROM question_tags qt JOIN tags t ON t.id = qt.tag_id
GROUP BY t.name ORDER BY n DESC;

-- Category usage counts, most used first. The inner JOIN leaves out questions that have no category.
CREATE VIEW IF NOT EXISTS v_category_freq AS
SELECT c.name, count(*) AS n
FROM questions q JOIN categories c ON c.id = q.category_id
GROUP BY c.name ORDER BY n DESC;

-- Which two tags show up together most (self-join on the junction table).
CREATE VIEW IF NOT EXISTS v_tag_cooccurrence AS
SELECT t1.name AS tag_a, t2.name AS tag_b, count(*) AS n
FROM question_tags qt1
JOIN question_tags qt2 ON qt1.question_id = qt2.question_id AND qt1.tag_id < qt2.tag_id
JOIN tags t1 ON t1.id = qt1.tag_id
JOIN tags t2 ON t2.id = qt2.tag_id
GROUP BY t1.name, t2.name ORDER BY n DESC;

-- Bursts: sessions with 3+ questions, i.e. the manic tears.

-- span_minutes: julianday() counts in days, so the difference is multiplied by 24 * 60 to get minutes.
-- HAVING n >= 3 is the definition of a "burst". `end` is an unusual column name but accepted by SQLite
-- here; qb reads it by name.
CREATE VIEW IF NOT EXISTS v_bursts AS
SELECT s.id AS session_id, count(*) AS n,
       min(q.created_at) AS start, max(q.created_at) AS end,
       round((julianday(max(q.created_at)) - julianday(min(q.created_at))) * 24 * 60, 1) AS span_minutes
FROM questions q JOIN sessions s ON s.id = q.session_id
GROUP BY s.id HAVING n >= 3 ORDER BY n DESC;

-- How many questions are open, exploring, answered or abandoned: a quick measure of follow-through.
CREATE VIEW IF NOT EXISTS v_status_breakdown AS
SELECT status, count(*) AS n FROM questions GROUP BY status ORDER BY n DESC;

-- Average self-rated energy (1-5) per category, rounded to 2 places. Questions without a rating are
-- excluded so they do not drag the average down.
CREATE VIEW IF NOT EXISTS v_avg_energy_by_category AS
SELECT c.name, round(avg(q.energy_level), 2) AS avg_energy, count(*) AS n
FROM questions q JOIN categories c ON c.id = q.category_id
WHERE q.energy_level IS NOT NULL
GROUP BY c.name ORDER BY avg_energy DESC;

-- How long questions sit open before you answer them (or don't).

-- hours_to_answer: days difference * 24. Only answered questions appear. Not shown by `qb stats`; use qb sql.
CREATE VIEW IF NOT EXISTS v_time_to_answer AS
SELECT id, text, category_id,
       round((julianday(answered_at) - julianday(created_at)) * 24, 1) AS hours_to_answer
FROM questions
WHERE answered_at IS NOT NULL
ORDER BY hours_to_answer DESC;

-- Root questions with the size of their whole follow-up tree (recursive CTE).

-- Recursive CTE: start from every root (no parent) and repeatedly add children, remembering which root each
-- descendant belongs to. The final count includes the root itself; HAVING chain_size > 1 hides questions
-- that never got a follow-up. A loop in parent_id would make this recursion endless (see qb cmd_link).
CREATE VIEW IF NOT EXISTS v_chain_sizes AS
WITH RECURSIVE descendants(root_id, id) AS (
    SELECT id, id FROM questions WHERE parent_id IS NULL
    UNION ALL
    SELECT d.root_id, q.id
    FROM questions q JOIN descendants d ON q.parent_id = d.id
)
SELECT root_id, count(*) AS chain_size
FROM descendants GROUP BY root_id HAVING chain_size > 1 ORDER BY chain_size DESC;
