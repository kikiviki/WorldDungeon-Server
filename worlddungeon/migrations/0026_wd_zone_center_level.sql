-- 0026_wd_zone_center_level
--
-- Purpose: re-anchor wd_zone from "entry level" to "zone level" — the level a
-- player should BE while here, with the content spread +/-2 around it.
--
--   A zone declared level 5 holds mobs 3-7.
--
-- ID ranges claimed: none. Alters the table created by 0025.
--
-- Idempotent: the ALTER is guarded on the old column still existing; the
-- REPLACE INTO is on the primary key.
--
--
-- ====================== WHY CENTERED BEATS BOTTOM-ANCHORED ==================
--
-- 0025 stored entry_level with an implied band of entry .. entry+3. Same rule,
-- worse anchor. Measured against the con table (zone/mob_ai.cpp, with
-- UseOldConSystem false), a player standing at a centered zone's level sees:
--
--     mob at level-2   diff -2   Dark Blue   easy, still pays experience
--     mob at level     diff  0   White
--     mob at level+2   diff +2   Yellow      hard but winnable
--
-- Nothing red, nothing gray, and both easy and hard targets are in reach at all
-- times. Bottom-anchoring instead gives a zone that is uniformly punishing on
-- arrival and uniformly trivial by the time you leave.
--
-- The binding constraint is the red threshold: +4 cons RED, so the hard limit
-- is +/-3, a 7-level span. +/-2 sits one level inside that deliberately, as
-- headroom for players who arrive early or who lag behind their gear.
--
-- Gray (no experience) is diff <= -6 below level 15, so a 5-level span never
-- contains gray content for a player anywhere inside it. The whole zone stays
-- worth killing for the entire time you are there — which a 7-level span would
-- not manage.
--
--
-- ⚠️ ================= THIS DOES NOT REPLACE THE SPATIAL RULE =================
--
-- +/-2 describes WHAT is in the zone, never WHERE. A player arriving at
-- level-2 still meets +4 red at the top of the band, so the level+2 mobs must
-- sit deeper in the zone than the level-2 mobs. "Level is a property of place"
-- (ZONE-AND-MOB-SCALING.md §2) remains load-bearing; if anything this makes it
-- more so, because the band is now wider.
--
--
-- ======================= THE STARTING ZONE IS SPECIAL =======================
--
-- Every other zone can assume players arrive somewhere near its middle, having
-- outgrown the zone before it. Kerra Isle cannot: characters are created there
-- at level 1 exactly, so they always arrive at the floor.
--
-- Its level is therefore 2, not 3 — band 1-4 once the bottom clamps at 1. At
-- level 3 the band would be 1-5, and a brand new level 1 character would meet
-- +4 RED content in the first zone they ever see.
--
-- This is the one zone where the bottom of the band, not the centre, is the
-- number that matters.

SET @has_old := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME   = 'wd_zone'
       AND COLUMN_NAME  = 'entry_level'
);

SET @sql := IF(
    @has_old > 0,
    'ALTER TABLE `wd_zone` CHANGE `entry_level` `level` TINYINT UNSIGNED NOT NULL',
    'DO 0'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

REPLACE INTO `wd_zone` (`short_name`, `level`, `notes`) VALUES
    ('kerraridge', 2,
     'Starting zone - band 1-4. Level 2 not 3: characters are created here at exactly level 1, so they arrive at the floor rather than the middle, and a level 3 centre would put +4 red content in front of a brand new character. WD mirror spawns not built yet.');
