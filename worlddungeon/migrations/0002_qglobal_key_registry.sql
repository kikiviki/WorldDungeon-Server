-- 0002_qglobal_key_registry
--
-- Purpose: machine-readable copy of A1's qglobal namespace, so scripts and audit
-- queries can check a key exists and is being written at the right scope rather
-- than trusting convention. docs/worlddungeon/A1-QGLOBAL-SCHEMA.md is the prose
-- authority.
--
-- The scope column is the setglobal options bitmask (zone/questmgr.cpp:1769):
-- 1 = all npcs, 2 = all characters, 4 = all zones. Every WorldDungeon
-- entitlement is 5 (this character, any npc, any zone). Bit 2 is forbidden -
-- it would make a per-character entitlement server-wide.
--
-- ID ranges used: none.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS + REPLACE INTO on the natural key.

CREATE TABLE IF NOT EXISTS wd_qglobal_key (
  name        VARCHAR(64)  NOT NULL PRIMARY KEY COMMENT 'wd_<domain>_<key>; a trailing _* marks a key family',
  value_type  VARCHAR(32)  NOT NULL             COMMENT 'int | csv_pairs',
  scope       TINYINT      NOT NULL DEFAULT 5   COMMENT 'setglobal options bitmask',
  written_by  VARCHAR(32)  NOT NULL             COMMENT 'backlog item that owns writes',
  read_by     VARCHAR(64)  NOT NULL DEFAULT '',
  notes       VARCHAR(255) NOT NULL DEFAULT '',
  CONSTRAINT wd_qglobal_key_scope CHECK (scope = 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='WorldDungeon qglobal namespace - see docs/worlddungeon/A1-QGLOBAL-SCHEMA.md';

REPLACE INTO wd_qglobal_key (name, value_type, scope, written_by, read_by, notes) VALUES
  ('wd_paragon_path',  'int',       5, 'A2',  'A3,A5', 'paragon path id; 0 = none chosen'),
  ('wd_paragon_rank',  'int',       5, 'A2',  'A3',    'rank 0-10 within the chosen path; kept separate from path so A3 need not parse'),
  ('wd_paragon_dip',   'csv_pairs', 5, 'A2',  'A3',    'dipped paths as path:rank pairs joined by comma, e.g. 2:3,5:3; rank caps at 3'),
  ('wd_paragon_spec',  'int',       5, 'A2',  'A3',    'specialization flag 0/1; gates ranks 6-10'),
  ('wd_rebirth_count', 'int',       5, 'W12', 'W12,A6', '0 on a fresh character'),
  ('wd_level_ceiling', 'int',       5, 'W12', 'W12',   'per-character level cap'),
  ('wd_mastery_*',     'int',       5, 'A6',  'A5,A6', 'key FAMILY: wd_mastery_<class> using the lowercase class short name');
