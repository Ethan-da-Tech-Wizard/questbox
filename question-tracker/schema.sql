-- questbox schema
-- A personal question-tracking database: every question you fire off gets
-- filed here with enough metadata to later mine for patterns (scope, flow,
-- timing, obsessions, follow-through).

PRAGMA foreign_keys = ON;

-- A "session" is an auto-detected burst of questions asked close together in
-- time. This is what lets you later ask "when do I go on a tear?".
CREATE TABLE IF NOT EXISTS sessions (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    ended_at   TEXT,
    note       TEXT
);

CREATE TABLE IF NOT EXISTS categories (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS tags (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

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

CREATE TABLE IF NOT EXISTS question_tags (
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    tag_id      INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_questions_created ON questions(created_at);
CREATE INDEX IF NOT EXISTS idx_questions_status  ON questions(status);
CREATE INDEX IF NOT EXISTS idx_questions_parent  ON questions(parent_id);
CREATE INDEX IF NOT EXISTS idx_questions_session ON questions(session_id);
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category_id);

-- Full-text search over question + answer text.
CREATE VIRTUAL TABLE IF NOT EXISTS questions_fts USING fts5(
    text, answer, content='questions', content_rowid='id'
);

CREATE TRIGGER IF NOT EXISTS questions_ai AFTER INSERT ON questions BEGIN
    INSERT INTO questions_fts(rowid, text, answer) VALUES (new.id, new.text, new.answer);
END;
CREATE TRIGGER IF NOT EXISTS questions_ad AFTER DELETE ON questions BEGIN
    INSERT INTO questions_fts(questions_fts, rowid, text, answer)
    VALUES ('delete', old.id, old.text, old.answer);
END;
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
CREATE VIEW IF NOT EXISTS v_daily_counts AS
SELECT date(created_at) AS day, count(*) AS n
FROM questions GROUP BY day ORDER BY day;

-- Rhythm: what hour of the day you tend to spiral in.
CREATE VIEW IF NOT EXISTS v_hourly_pattern AS
SELECT strftime('%H', created_at) AS hour, count(*) AS n
FROM questions GROUP BY hour ORDER BY hour;

-- Day-of-week pattern (0 = Sunday).
CREATE VIEW IF NOT EXISTS v_weekday_pattern AS
SELECT CASE strftime('%w', created_at)
         WHEN '0' THEN 'Sun' WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue'
         WHEN '3' THEN 'Wed' WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri'
         ELSE 'Sat' END AS weekday,
       strftime('%w', created_at) AS w,
       count(*) AS n
FROM questions GROUP BY weekday, w ORDER BY w;

CREATE VIEW IF NOT EXISTS v_tag_freq AS
SELECT t.name, count(*) AS n
FROM question_tags qt JOIN tags t ON t.id = qt.tag_id
GROUP BY t.name ORDER BY n DESC;

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
CREATE VIEW IF NOT EXISTS v_bursts AS
SELECT s.id AS session_id, count(*) AS n,
       min(q.created_at) AS start, max(q.created_at) AS end,
       round((julianday(max(q.created_at)) - julianday(min(q.created_at))) * 24 * 60, 1) AS span_minutes
FROM questions q JOIN sessions s ON s.id = q.session_id
GROUP BY s.id HAVING n >= 3 ORDER BY n DESC;

CREATE VIEW IF NOT EXISTS v_status_breakdown AS
SELECT status, count(*) AS n FROM questions GROUP BY status ORDER BY n DESC;

CREATE VIEW IF NOT EXISTS v_avg_energy_by_category AS
SELECT c.name, round(avg(q.energy_level), 2) AS avg_energy, count(*) AS n
FROM questions q JOIN categories c ON c.id = q.category_id
WHERE q.energy_level IS NOT NULL
GROUP BY c.name ORDER BY avg_energy DESC;

-- How long questions sit open before you answer them (or don't).
CREATE VIEW IF NOT EXISTS v_time_to_answer AS
SELECT id, text, category_id,
       round((julianday(answered_at) - julianday(created_at)) * 24, 1) AS hours_to_answer
FROM questions
WHERE answered_at IS NOT NULL
ORDER BY hours_to_answer DESC;

-- Root questions with the size of their whole follow-up tree (recursive CTE).
CREATE VIEW IF NOT EXISTS v_chain_sizes AS
WITH RECURSIVE descendants(root_id, id) AS (
    SELECT id, id FROM questions WHERE parent_id IS NULL
    UNION ALL
    SELECT d.root_id, q.id
    FROM questions q JOIN descendants d ON q.parent_id = d.id
)
SELECT root_id, count(*) AS chain_size
FROM descendants GROUP BY root_id HAVING chain_size > 1 ORDER BY chain_size DESC;
