-- 0019_kerra_entry_point
--
-- A11 item 4 (front half): the start_zones rows that let world resolve the
-- Kerra Isle start for every combo 0018 now offers. GetStartZone
-- (world/worlddb.cpp) on SoF+ clients queries:
--
--   WHERE zone_id = <cc.start_zone> AND player_class AND player_deity AND player_race
--
-- so it needs one row per (class, race) at zone_id 74 / deity 396: 256 rows.
--
-- WHY player_choice = 74 AND NOT 0. The table's PK is (player_choice,
-- player_class, player_deity, player_race) - it does NOT include zone_id -
-- and stock carries rows at player_choice 0 with deity 396 (e.g. Erudite
-- 12/13/14 into Erudin). player_choice is only ever consulted by the
-- Titanium query path, and Titanium city choices are small integers, so
-- claiming choice 74 (mnemonic: the zone id) keeps every stock row intact
-- and can never be reached by a Titanium client.
--
-- Coordinates are ALL ZERO on purpose: GetStartZone falls back to the zone
-- table's safe point when x=y=z=heading are all 0 - kerraridge's is
-- (-859.97, 474.96, 23.75), stock data we inherit instead of duplicating.
-- Same fallback applies to the bind point (bind_id 74, bind coords 0).
--
-- Stock start_zones rows are left untouched; they are unreachable from
-- creation because every 0018 combo points at zone 74, but a Titanium
-- client creating a canonical combo still resolves its stock city. Routing
-- Titanium players to the qcat "get RoF2" room is the deferred back half of
-- A11 item 4 (first-login script), not this migration.
--
-- Idempotent: DELETE over the claimed player_choice, then INSERT.

DELETE FROM start_zones WHERE player_choice = 74 AND player_deity = 396;

INSERT INTO start_zones
  (x, y, z, heading, zone_id, bind_id, player_choice, player_class, player_deity, player_race,
   start_zone, bind_x, bind_y, bind_z, select_rank)
SELECT 0, 0, 0, 0, 74, 74, 74, c.class, 396, r.race, 74, 0, 0, 0, 50
FROM (SELECT 1 race UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
      UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
      UNION SELECT 11 UNION SELECT 12 UNION SELECT 128 UNION SELECT 130
      UNION SELECT 330 UNION SELECT 522) r
CROSS JOIN
     (SELECT 1 class UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
      UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
      UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14
      UNION SELECT 15 UNION SELECT 16) c;
