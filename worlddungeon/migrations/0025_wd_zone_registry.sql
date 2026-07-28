-- 0025_wd_zone_registry
--
-- Purpose: record the ONE thing about a zone that is not derivable — its
-- intended entry level. Everything else about a zone's difficulty can be
-- computed from its spawns; intent cannot.
--
-- ID ranges claimed: none. New WD-owned table.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS + REPLACE INTO on the primary key.
--
-- Read with `worlddungeon/bin/wd-zone-check`, which compares what is declared
-- here against what the spawn tables actually contain. That comparison is the
-- whole point of the table — see below.
--
--
-- =========================== WHY ONLY ONE COLUMN ============================
--
-- Deliberately minimal. A zone's actual level range is already derivable by
-- joining spawn2 -> spawnentry -> npc_types, and per-level hp/ac/stat curves
-- already live in npc_scale_global_base. Storing either here would duplicate a
-- source of truth, and duplicated data drifts until nobody knows which copy is
-- right.
--
-- What is NOT derivable is what the zone was *meant* to be. That is
-- entry_level, and it is one number. From it:
--
--   expected level band   entry_level .. entry_level + 3
--   tier                  ceil(entry_level / 10)
--   successor needed by   entry_level + 6   (cons go gray, XP stops)
--
-- ⚠️ Deliberately NOT stored:
--
--   tier      = ceil(level / 10). A third copy that can disagree with the
--               other two.
--   enabled   content_flags.enabled already holds whether a zone is switched
--               on. Same drift argument.
--   max_level = entry_level + 3 by the rule in ZONE-AND-MOB-SCALING.md §1.
--               A zone wanting a different span wants a rule change, not a
--               column.
--
-- The value of declaring entry_level is precisely that it can be compared
-- against the derived reality. That comparison turns "is this zone balanced?"
-- from a judgement call into a query that either returns rows or does not.
--
--
-- ⚠️ ============ WHY NOT zone.min_level / zone.max_level =====================
--
-- Those columns already exist and look ideal. They are NOT metadata — they are
-- hard enforcement gates. Client::ZoneSummon / zoning.cpp:1432 refuses entry to
-- any non-GM player below min_level or above max_level:
--
--     if (!GetGM() && GetLevel() < z->min_level) { ... refuse ... }
--     if (!GetGM() && GetLevel() > z->max_level) { ... refuse ... }
--
-- Writing intent there would lock players out of zones they have outlevelled,
-- which destroys the soft "cons went gray, time to move on" signal and traps
-- anyone returning for a quest, a corpse, or a friend. Keep intent in this
-- table and leave those columns alone.

CREATE TABLE IF NOT EXISTS `wd_zone` (
    `short_name`  VARCHAR(32)      NOT NULL,
    `entry_level` TINYINT UNSIGNED NOT NULL,
    `notes`       VARCHAR(255)     NOT NULL DEFAULT '',
    PRIMARY KEY (`short_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

REPLACE INTO `wd_zone` (`short_name`, `entry_level`, `notes`) VALUES
    ('kerraridge', 1,
     'Starting zone. Depopulated by 0017; WD mirror spawns not built yet, so wd-zone-check reports it as declared-but-empty until they land.');
