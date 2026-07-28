-- 0010_spell_text_not_null
--
-- Purpose: make the shared-memory NULL defect STRUCTURALLY IMPOSSIBLE, replacing
-- the standing rule introduced by 0008 with a schema guarantee.
--
-- Background. SharedDatabase::LoadSpells() (common/shareddb.cpp:1685-1692) copies
-- eight text columns straight out of the row with no NULL guard. A single NULL
-- aborts the whole loader, it writes no usable spells file, and every zone then
-- boots with stock spells only - presenting as "custom spells silently do not
-- exist" rather than as an error. 0008 cleaned up the rows that had already hit
-- this and left a rule: every INSERT must name the text columns explicitly.
--
-- A rule that must be remembered on every future INSERT is not a fix. Migration
-- 0006 already only half-follows it (familiars only), and 0005/0007/0009 are
-- queued behind the 0004 gate in the same state. This migration removes the need
-- to remember.
--
-- NOTE THE COUNT: 0008 and the backlog both say SIX columns. It is EIGHT.
-- `name` (row[1]) and `player_1` (row[2]) are copied by the same unguarded loop
-- and are equally nullable. They have not bitten us only because our migrations
-- happen to set `name`, and 0008 set `player_1` to BLUE_TRAIL.
--
-- ID ranges claimed: none. Schema only, no content.
--
-- Idempotent: the UPDATE is a no-op when already clean, and MODIFY COLUMN to an
-- identical definition is a no-op. Safe to re-run.
--
-- Ordering: safe regardless of where it lands relative to 0005-0009. The UPDATE
-- runs first, so even if content migrations insert NULLs before this applies,
-- they are converted before the constraint is added. Applying it EARLY is still
-- better - then the constraint is already in force when that content lands, and
-- a bad INSERT fails loudly at migration time instead of silently killing the
-- loader later.
--
-- Reversibility: this narrows the schema. `make init-peq-database` restores the
-- stock nullable definition, and replaying migrations re-applies this - which is
-- the intended behaviour. Stock PEQ has zero NULLs in these columns across all
-- 40,722 rows, so nothing upstream depends on them being nullable.

-- 1. Clean any existing NULLs. Currently a no-op (verified 0 of 40,734), but it
--    must run first or the MODIFY below would fail on a dirty table.
UPDATE spells_new SET name          = '' WHERE name          IS NULL;
UPDATE spells_new SET player_1      = '' WHERE player_1      IS NULL;
UPDATE spells_new SET teleport_zone = '' WHERE teleport_zone IS NULL;
UPDATE spells_new SET you_cast      = '' WHERE you_cast      IS NULL;
UPDATE spells_new SET other_casts   = '' WHERE other_casts   IS NULL;
UPDATE spells_new SET cast_on_you   = '' WHERE cast_on_you   IS NULL;
UPDATE spells_new SET cast_on_other = '' WHERE cast_on_other IS NULL;
UPDATE spells_new SET spell_fades   = '' WHERE spell_fades   IS NULL;

-- 2. Forbid NULL, and default to '' so an INSERT that simply omits the column
--    gets a loader-safe value instead of a landmine. Column types are preserved
--    exactly as they are in stock PEQ.
ALTER TABLE spells_new
  MODIFY COLUMN `name`          VARCHAR(64)  NOT NULL DEFAULT '',
  MODIFY COLUMN `player_1`      VARCHAR(64)  NOT NULL DEFAULT '',
  MODIFY COLUMN `teleport_zone` VARCHAR(64)  NOT NULL DEFAULT '',
  MODIFY COLUMN `you_cast`      VARCHAR(120) NOT NULL DEFAULT '',
  MODIFY COLUMN `other_casts`   VARCHAR(120) NOT NULL DEFAULT '',
  MODIFY COLUMN `cast_on_you`   VARCHAR(120) NOT NULL DEFAULT '',
  MODIFY COLUMN `cast_on_other` VARCHAR(120) NOT NULL DEFAULT '',
  MODIFY COLUMN `spell_fades`   VARCHAR(120) NOT NULL DEFAULT '';

-- After this, 0005 / 0006 / 0007 / 0009 need NO amendment: any text column they
-- omit resolves to '' and the loader is safe. The standing rule from 0008 is
-- superseded by this constraint.
