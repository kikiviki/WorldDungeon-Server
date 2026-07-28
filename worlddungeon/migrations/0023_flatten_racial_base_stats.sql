-- 0023_flatten_racial_base_stats
--
-- Purpose: A12. Flatten racial base attributes onto a common footing.
--
--   Baseline 80 per attribute, 7 x 80 = 560 total per race.
--   One flagship attribute at 95 (+15), paid for by -15 spread across the
--   other six, so every race sums to exactly 560.
--
-- ID ranges claimed: none. UPDATEs existing char_create_point_allocations rows.
--
-- Idempotent: absolute values, no arithmetic on current state. Re-running is a
-- no-op.
--
-- Takes effect on the NEXT character created. Existing characters keep the
-- stats already written to character_data - this migration does not touch them.
--
--
-- ========================= WHAT THIS FIXES ==================================
--
-- Stock base totals ran 545-586 across 19 distinct totals, so races were not
-- on equal footing. Worked example, Barbarian Berserker before this migration:
--
--   base_str 113, base_sta 100, base_agi 82, base_dex 80,
--   base_wis  70, base_int  60, base_cha 55   (total 560)
--
-- STR was +33 over baseline and CHA -25, both far outside the agreed +/-15.
--
--
-- ⚠️ ================== alloc_* IS DELIBERATELY UNTOUCHED ===================
--
-- char_create_point_allocations also carries alloc_str..alloc_cha, the points
-- pre-assigned at creation on top of the base. Barbarian Berserker carries
-- alloc_str = 25, which is why that character arrived at 138 STR rather than
-- the 113 in its base row.
--
-- The A12 decision fixes the BASE row ("every race sums to exactly 560") and
-- says nothing about the allocation pool, so this migration implements exactly
-- that and no more. THE CONSEQUENCE IS THAT A FLAGSHIP ATTRIBUTE CAN STILL BE
-- DELIVERED AT 95 + 25 = 120. If +/-15 was meant to bound the delivered
-- character rather than the base row, alloc_* needs its own migration and the
-- decision in BACKLOG.md A12 needs rewording first.
--
--
-- ===================== HOW THE NUMBERS WERE DERIVED =========================
--
-- Flagship = the attribute with the highest stock average across that race's
-- own allocation rows, so flattening preserves each race's existing flavour
-- direction rather than inventing a new one. The remaining six are ranked by
-- the same stock average: the top three take -2 (78), the bottom three take -3
-- (77). 95 + 78*3 + 77*3 = 560.
--
-- Human is the deliberate exception: its stock profile is already flat
-- (77-79 across the board), so it gets a true 80 baseline with no flagship.
-- Human is the yardstick every other race is measured against.
--
-- Two flagships were near-ties and are the ones to revisit first if any of this
-- feels wrong in play:
--
--   Dwarf   - STR 99 vs STA 95. Data picked STR; canon leans STA.
--   Drakkin - INT 88 vs AGI 88. Broken toward INT.
--   Froglok - AGI 101 vs DEX 101. Broken toward AGI.
--
-- Half Elf resolved to DEX (93) over AGI (92) on its own, which usefully
-- separates it from Wood Elf's AGI flagship.
--
-- Safe because no allocation_id is shared between races - verified with:
--   SELECT allocation_id, COUNT(DISTINCT race) FROM char_create_combinations
--    GROUP BY allocation_id HAVING COUNT(DISTINCT race) > 1;   -- empty
--
-- Race ids: 1 Human, 2 Barbarian, 3 Erudite, 4 Wood Elf, 5 High Elf,
-- 6 Dark Elf, 7 Half Elf, 8 Dwarf, 9 Troll, 10 Ogre, 11 Halfling, 12 Gnome,
-- 128 Iksar, 130 Vah Shir, 330 Froglok, 522 Drakkin.
--
-- 🔴 RoF2 only. CheckCharCreateInfoTitanium() (world/client.cpp) validates
-- against a hardcoded BaseRace[16][7] C++ matrix that ignores this table
-- entirely. Harmless while A11 routes Titanium clients to qcat.

-- Human - flat baseline, no flagship.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 1) c ON c.a = p.id
   SET p.base_str = 80, p.base_sta = 80, p.base_agi = 80, p.base_dex = 80,
       p.base_wis = 80, p.base_int = 80, p.base_cha = 80;

-- Barbarian - flagship STR.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 2) c ON c.a = p.id
   SET p.base_str = 95, p.base_sta = 78, p.base_agi = 78, p.base_wis = 78,
       p.base_dex = 77, p.base_int = 77, p.base_cha = 77;

-- Erudite - flagship INT.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 3) c ON c.a = p.id
   SET p.base_int = 95, p.base_wis = 78, p.base_sta = 78, p.base_cha = 78,
       p.base_dex = 77, p.base_agi = 77, p.base_str = 77;

-- Wood Elf - flagship AGI.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 4) c ON c.a = p.id
   SET p.base_agi = 95, p.base_dex = 78, p.base_cha = 78, p.base_wis = 78,
       p.base_int = 77, p.base_str = 77, p.base_sta = 77;

-- High Elf - flagship WIS.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 5) c ON c.a = p.id
   SET p.base_wis = 95, p.base_int = 78, p.base_agi = 78, p.base_cha = 78,
       p.base_sta = 77, p.base_dex = 77, p.base_str = 77;

-- Dark Elf - flagship INT.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 6) c ON c.a = p.id
   SET p.base_int = 95, p.base_agi = 78, p.base_wis = 78, p.base_dex = 78,
       p.base_sta = 77, p.base_str = 77, p.base_cha = 77;

-- Half Elf - flagship DEX.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 7) c ON c.a = p.id
   SET p.base_dex = 95, p.base_agi = 78, p.base_cha = 78, p.base_str = 78,
       p.base_int = 77, p.base_sta = 77, p.base_wis = 77;

-- Dwarf - flagship STR (STA is the near-tie; see header).
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 8) c ON c.a = p.id
   SET p.base_str = 95, p.base_dex = 78, p.base_sta = 78, p.base_wis = 78,
       p.base_agi = 77, p.base_int = 77, p.base_cha = 77;

-- Troll - flagship STA.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 9) c ON c.a = p.id
   SET p.base_sta = 95, p.base_str = 78, p.base_agi = 78, p.base_dex = 78,
       p.base_wis = 77, p.base_int = 77, p.base_cha = 77;

-- Ogre - flagship STR.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 10) c ON c.a = p.id
   SET p.base_str = 95, p.base_sta = 78, p.base_wis = 78, p.base_agi = 78,
       p.base_dex = 77, p.base_int = 77, p.base_cha = 77;

-- Halfling - flagship AGI.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 11) c ON c.a = p.id
   SET p.base_agi = 95, p.base_dex = 78, p.base_wis = 78, p.base_sta = 78,
       p.base_str = 77, p.base_int = 77, p.base_cha = 77;

-- Gnome - flagship INT.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 12) c ON c.a = p.id
   SET p.base_int = 95, p.base_agi = 78, p.base_dex = 78, p.base_sta = 78,
       p.base_wis = 77, p.base_str = 77, p.base_cha = 77;

-- Iksar - flagship AGI.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 128) c ON c.a = p.id
   SET p.base_agi = 95, p.base_wis = 78, p.base_dex = 78, p.base_sta = 78,
       p.base_int = 77, p.base_str = 77, p.base_cha = 77;

-- Vah Shir - flagship STR.
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 130) c ON c.a = p.id
   SET p.base_str = 95, p.base_agi = 78, p.base_dex = 78, p.base_sta = 78,
       p.base_cha = 77, p.base_wis = 77, p.base_int = 77;

-- Froglok - flagship AGI (DEX is the near-tie; see header).
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 330) c ON c.a = p.id
   SET p.base_agi = 95, p.base_dex = 78, p.base_sta = 78, p.base_wis = 78,
       p.base_int = 77, p.base_str = 77, p.base_cha = 77;

-- Drakkin - flagship INT (AGI is the near-tie; see header).
UPDATE `char_create_point_allocations` p
  JOIN (SELECT DISTINCT `allocation_id` AS a FROM `char_create_combinations` WHERE `race` = 522) c ON c.a = p.id
   SET p.base_int = 95, p.base_agi = 78, p.base_sta = 78, p.base_wis = 78,
       p.base_dex = 77, p.base_cha = 77, p.base_str = 77;


-- ======================== ORPHANED ALLOCATION ROWS ==========================
--
-- Rows 66 and 69 are not referenced by ANY char_create_combinations row, so the
-- per-race joins above cannot reach them. Their stock profile (140 STR, 127/132
-- STA, 37 CHA) is unmistakably Ogre - almost certainly leftovers from a stock
-- combination that no longer exists.
--
-- They are unreachable at character creation today and so change nothing in
-- play. They are flattened anyway, to the same Ogre line as race 10 above, so
-- that the invariant "every row in this table totals 560 and sits within
-- 65-95" holds for the whole table. That invariant is what the verification
-- query checks, and a table with two permanent exceptions is a table nobody
-- can verify at a glance later.
--
-- If a future migration ever points a combination at one of these ids, it now
-- delivers a compliant stat line instead of stock Ogre.

UPDATE `char_create_point_allocations`
   SET `base_str` = 95, `base_sta` = 78, `base_wis` = 78, `base_agi` = 78,
       `base_dex` = 77, `base_int` = 77, `base_cha` = 77
 WHERE `id` IN (66, 69);
