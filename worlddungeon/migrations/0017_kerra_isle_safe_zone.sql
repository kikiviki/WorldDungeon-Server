-- 0017_kerra_isle_safe_zone
--
-- Purpose: depopulate Kerra Isle (kerraridge, zone 74) so it can serve as the
-- A11 starting zone. A naked level 1 with no starting gear cannot survive the
-- stock kerran population.
--
-- ID ranges claimed: none. One content_flags row, and an UPDATE over the 155
-- stock spawn2 rows whose zone is 'kerraridge'.
--
-- Idempotent: DELETE + INSERT on the flag; the UPDATE is naturally repeatable.
--
-- Requires a zone reload to take effect: #repop, or bounce the zone.
--
--
-- ===================== WHY A CONTENT FLAG AND NOT A DELETE ==================
--
-- The obvious implementation is DELETE FROM spawn2 WHERE zone = 'kerraridge'.
-- Rejected: those 155 rows are STOCK PEQ DATA, not ours. F1's ownership rule
-- only lets us delete freely inside ranges we allocated, and deleting upstream
-- rows makes a future PEQ database refresh silently reintroduce every mob.
--
-- Content filtering does the same job reversibly. zone/spawn2.cpp:511 applies
-- ContentFilterCriteria to the spawn2 load, and WorldContentService::
-- DoesPassContentFiltering (common/content/world_content_service.cpp:158) is:
--
--     for (const auto &flag: Strings::Split(f.content_flags)) {
--         if (!Strings::Contains(GetContentFlagsEnabled(), flag)) {
--             return false;                      // row does not load
--         }
--     }
--
-- So a row tagged with a flag that is NOT enabled simply never spawns. We tag
-- every kerraridge spawn with 'wd_kerra_populated' and create that flag
-- DISABLED. The rows survive untouched; they just do not load.
--
-- To repopulate Kerra Isle later - it is a real zone in the tier map, not a
-- permanent lobby - flip one row:
--
--     UPDATE content_flags SET enabled = 1 WHERE flag_name = 'wd_kerra_populated';
--
-- Verified before writing: all 155 kerraridge spawn2 rows currently have an
-- EMPTY content_flags, so this claims the column rather than overwriting
-- upstream filtering. If a future PEQ update sets content_flags on any of these
-- rows, this migration would clobber it - hence the exact-match WHERE below.
--
-- ⚠️ SCOPE: this suppresses SPAWNS ONLY. It does not touch spawngroup,
-- spawnentry, or npc_types, and it does not stop anything already spawned in a
-- running zone - hence the #repop.
--
-- ⚠️ NOT A SAFE ZONE FLAG. This empties the zone; it does not mark it safe in
-- any engine sense. PvP rules, bind behaviour, and the zone's `safe_x/y/z` are
-- separate and unchanged. Nothing here prevents a player pulling something
-- through a zone line.

-- The flag, created disabled. DELETE + INSERT rather than REPLACE INTO because
-- content_flags has a surrogate auto_increment PK, so REPLACE would churn ids.
DELETE FROM `content_flags` WHERE `flag_name` = 'wd_kerra_populated';

INSERT INTO `content_flags` (`flag_name`, `enabled`, `notes`) VALUES
    ('wd_kerra_populated', 0,
     'WD 0017: OFF makes Kerra Isle (kerraridge) an empty starting zone. Set 1 to restore the stock kerran population.');

-- Tag every stock kerraridge spawn. Restricted to rows with no existing flag so
-- upstream filtering is never overwritten.
UPDATE `spawn2`
   SET `content_flags` = 'wd_kerra_populated'
 WHERE `zone` = 'kerraridge'
   AND (`content_flags` IS NULL OR `content_flags` = '');
