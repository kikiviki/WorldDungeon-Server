-- 0022_kerra_isle_spawn_point
--
-- Purpose: move the Kerra Isle (zone_id 74) character-creation spawn off the
-- zone-in point to the intended starting spot.
--
-- ⚠️ SUPERSEDES PART OF 0019_kerra_entry_point. That migration created the 256
-- start_zones rows deliberately at zero coordinates, relying on the safe-point
-- fallback described below. This one fills those coordinates in, so the
-- fallback no longer fires for Kerra Isle. 0019 is otherwise untouched and
-- still owns the rows themselves.
--
--   X = 395, Y = 507, Z = 18
--
-- ID ranges claimed: none. Updates existing start_zones rows only.
--
-- Idempotent: plain UPDATE to absolute values. Re-running is a no-op.
--
-- Takes effect on the NEXT character created. Requires a world restart so the
-- new rows are read (world queries start_zones per creation, but restart is the
-- safe assumption). Existing characters keep their current character_data
-- position and character_bind rows - this migration deliberately does not touch
-- them. Move an existing test character with #goto / #loc instead.
--
--
-- ======================== WHY THE ROWS LOOKED "EMPTY" =======================
--
-- All 240 kerraridge rows in start_zones carry x = y = z = heading = 0. That is
-- not "no spawn point" - it is a sentinel. WorldDatabase::GetStartZone
-- (world/worlddb.cpp) reads the row, then:
--
--     if (pp->x == 0 && pp->y == 0 && pp->z == 0 && pp->heading == 0) {
--         auto zone = GetZone(pp->zone_id);
--         if (zone) { pp->x = zone->safe_x; ... }
--     }
--
-- so every new character was being placed at kerraridge's safe point
-- (-859.97, 474.96, 23.75) - the zone-in location. Writing real coordinates
-- into the row defeats the fallback.
--
-- ⚠️ The fallback needs ALL FOUR fields zero. Setting x/y/z while leaving
-- heading at 0 is fine and is what this migration does - heading 0 is a real
-- facing, not a sentinel, once x is non-zero.
--
-- The zone table's safe_x/safe_y/safe_z are deliberately NOT changed. Those are
-- the /succor, #zonesafe and death-respawn destination; repointing them would
-- move far more than the creation spawn. If Kerra Isle should also respawn the
-- dead at 395/507/18, that is a separate decision and a separate migration.
--
--
-- ============================ WHY BIND TOO ==================================
--
-- bind_id is 74 on every row (non-zero), so the bind branch in
-- WorldDatabase::CharacterData bind handling takes the zone safe point as well.
-- bind_x/y/z are set to match so a freshly created character binds where they
-- stand rather than back at the zone-in.

UPDATE `start_zones`
   SET `x`      = 395,
       `y`      = 507,
       `z`      = 18,
       `bind_x` = 395,
       `bind_y` = 507,
       `bind_z` = 18
 WHERE `zone_id` = 74;
