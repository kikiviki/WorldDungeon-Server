-- 0020_t0_morphing_weapons
--
-- A13: the morphing newbie weapon. Seven items, not one - itemtype is static
-- shared-memory item data with no per-instance override, so "one weapon that
-- morphs" is seven ids plus a click script that swaps them.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   items.id  1,001,000-1,001,006  (A13 band; 1,001,007-1,001,099 reserved
--                                   for later starter gear)
--
-- Script: quests/global/items/script_1001000.lua (quests repo), shared by all
-- seven via scriptfileid = 1001000. EVENT_ITEM_CLICK fires server-side before
-- the no-effect rejection (zone/client_packet.cpp Handle_OP_ItemVerifyRequest),
-- so no click-effect spell is needed.
--
-- T0 stat line (BACKLOG.md A13, ~2/3 of T1): 1H/martial dmg 8, 2H dmg 14.
-- Delay is FIXED across all tiers by decision - 28 for 1H, 26 for martial,
-- 45 for 2H. 45 because GetWeaponDamageBonus pays its first meaningful
-- 2H delay bonus (4) at delay >= 45; below 40 pays nothing.
--
-- Flags per A13's gotchas:
--   * loregroup 1001000 on ALL SEVEN - one shared lore group, or a player
--     can hold all seven forms at once.
--   * nodrop = 0 (No Drop). norent stays 255 - NORENT would make the weapon
--     vanish on logout.
--   * regen / manaregen / enduranceregen = 1 on every form.
--   * all/all (classes 65535, races 65535, deity 0): the class only decides
--     which form 0021 GRANTS at creation; anyone can cycle to anything.
--
-- Visuals borrow stock idfile/icon per weapon type (rusty-tier graphics).
--
-- Idempotent: DELETE over the owned id range, then INSERT.

DELETE FROM items WHERE id BETWEEN 1001000 AND 1001006;

INSERT INTO items
  (id, Name, itemtype, damage, delay, weight, size, slots, classes, races, deity,
   reqlevel, reclevel, icon, idfile, lore, loregroup, magic, nodrop, norent,
   regen, manaregen, enduranceregen, scriptfileid, price)
VALUES
  (1001000, 'Training Blade',      0,  8, 28, 10, 2, 24576, 65535, 65535, 0, 0, 0, 590, 'IT10649', 'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0),
  (1001001, 'Training Greatblade', 1, 14, 45, 10, 3,  8192, 65535, 65535, 0, 0, 0, 519, 'IT10648', 'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0),
  (1001002, 'Training Dirk',       2,  8, 28, 10, 1, 24576, 65535, 65535, 0, 0, 0, 592, 'IT10650', 'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0),
  (1001003, 'Training Cudgel',     3,  8, 28, 10, 2, 24576, 65535, 65535, 0, 0, 0, 737, 'IT18',    'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0),
  (1001004, 'Training Maul',       4, 14, 45, 10, 3,  8192, 65535, 65535, 0, 0, 0, 601, 'IT8',     'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0),
  (1001005, 'Training Pike',      35, 14, 45, 10, 3,  8192, 65535, 65535, 0, 0, 0, 742, 'IT197',   'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0),
  (1001006, 'Training Wraps',     45,  8, 26, 10, 1, 24576, 65535, 65535, 0, 0, 0, 975, 'IT71',    'A shifting training weapon - right-click to change its form', 1001000, 1, 0, 255, 1, 1, 1, 1001000, 0);
