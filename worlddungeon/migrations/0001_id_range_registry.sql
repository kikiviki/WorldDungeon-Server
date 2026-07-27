-- 0001_id_range_registry
--
-- Purpose: put F1's ID allocation policy in the database, so tooling, quest
-- scripts and audit queries can read the custom ranges instead of hardcoding
-- them. docs/worlddungeon/F1-ID-RANGES.md remains the prose authority; this
-- table is the machine-readable copy of the same numbers.
--
-- ID ranges used: none — this migration allocates no content ids. It is also
-- the first exercise of the migration mechanism itself (F2).
--
-- Idempotent: CREATE TABLE IF NOT EXISTS + REPLACE INTO on a natural key.

CREATE TABLE IF NOT EXISTS wd_id_range (
  target        VARCHAR(64)     NOT NULL PRIMARY KEY COMMENT 'table.column the range governs',
  custom_base   BIGINT UNSIGNED NOT NULL             COMMENT 'first id WorldDungeon may use',
  stock_max     BIGINT UNSIGNED NOT NULL             COMMENT 'max stock id measured when the policy was set',
  notes         VARCHAR(255)    NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='WorldDungeon custom ID allocation policy - see docs/worlddungeon/F1-ID-RANGES.md';

REPLACE INTO wd_id_range (target, custom_base, stock_max, notes) VALUES
  ('spells_new.id',          100000,   42602, 'custom spells'),
  ('spells_new.spellgroup',  500000,  100276, 'custom spellgroups; tier lines use ranks within a group'),
  ('items.id',              1000000,  147494, 'custom items, incl. A4 tokens'),
  ('aa_ability.id',          100000,   30195, 'custom AA abilities'),
  ('aa_ranks.id',            100000,   49999, 'custom AA ranks'),
  ('doors.id',               100000,   40569, 'incl. opentype 57-58 clicky portals for A7/A8'),
  ('zone_points.id',         100000,    4519, 'walk-through zone edges for A7'),
  ('npc_types.id',                0, 2000040, 'NO flat base: follows zoneidnumber*1000+n. Overflow range is 3000000+.');

-- Per-zone NPC band claims. F1 requires a conflict check before claiming a band,
-- because 38 zones already have stock NPCs at n >= 500 - there is no blanket-safe
-- sub-band. Rows are added by the migration that first authors NPCs in that zone.
CREATE TABLE IF NOT EXISTS wd_npc_band (
  zoneidnumber  INT UNSIGNED NOT NULL,
  n_low         SMALLINT UNSIGNED NOT NULL COMMENT 'inclusive, within the zone*1000 band',
  n_high        SMALLINT UNSIGNED NOT NULL COMMENT 'inclusive',
  claimed_by    VARCHAR(128) NOT NULL      COMMENT 'backlog item or content name',
  PRIMARY KEY (zoneidnumber, n_low),
  CONSTRAINT wd_npc_band_order CHECK (n_high >= n_low),
  CONSTRAINT wd_npc_band_range CHECK (n_high <= 999)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Claimed npc_types id sub-bands per zone - see docs/worlddungeon/F1-ID-RANGES.md';
