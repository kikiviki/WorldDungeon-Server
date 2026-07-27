-- 0004_cleric_mantles_mk1to3
--
-- SUPERSEDES 0003. That migration is applied and immutable, so this one both
-- removes its rows and re-authors them correctly. Three things were wrong:
--
--   1. ids at 100,100 - ABOVE the ROF2 client cap of 45,000
--      (rof2_limits.h:346). Anything scribed above it reaches the client as an
--      empty spellbook slot. Re-based into the 42,700 class band.
--   2. rank was 1/2/3. Stock uses 1/5/10 for Mk. I/II/III - the field is a
--      position on a 1-10 scale, not a counter. (spellgroup 1010 confirms.)
--   3. ten tiers were planned; three (Mk. I/II/III) is the client-native shape
--      and is what makes the id budget fit.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  42700-42708  Cleric mantles, 3 mantles x Mk. I/II/III
--   spells_new.id  42710-42712  their defensive proc spells
--   spellgroup     500001       clr_mantle   (unchanged - server-side, uncapped)
--   spellgroup     500002-4     proc lines   (unchanged)
--
-- Idempotent: DELETE over both the old and new ranges, then INSERT.
--
--
-- ------------------------- SCALING NOTE -------------------------------------
-- The Mk. I/II/III model is "same formula, higher max cap" - a tier raises the
-- ceiling on what level and gear reach, rather than adding a flat bump.
--
-- That model applies to OUTPUT spells (heals, smites) whose magnitude scales
-- with the caster. It does NOT fit the mantles, whose slots are all
-- PERCENTAGES - heal focus %, mana reduction %, melee damage, double attack %.
-- A percentage does not want level scaling, so these correctly use formula 100
-- (flat) and express tiers as real steps in the percentage itself.
--
-- Use formula 101-105 / 111-112 + a rising max on the heal and smite lines when
-- those are authored. Do not blanket-apply it here.
--
-- FOCUSABILITY: the not_focusable flag is deliberately NOT set here. The spdat
-- struct comments it as field 197 (common/spdat.h:1712) but ordinal 198 in this
-- schema is `not_extendable`, so the struct index and the column name do not
-- line up and the right column has not been identified yet. Omitting it is safe
-- and correct - every spells_new column has a default and the default is 0,
-- which is the value we want (focusable). Identify the true column before
-- authoring any spell that must be NON-focusable.
-- ----------------------------------------------------------------------------

DELETE FROM spells_new WHERE id BETWEEN 100100 AND 100119;  -- 0003's rows
DELETE FROM spells_new WHERE id BETWEEN 42700  AND 42719;   -- this range

-- ---------- proc spells (targets of slot 5) ----------
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time, mana, skill,
   classes2,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- Damage back at the attacker; scales with level, capped.
  (42710, 'Zealous Retribution', 83, 1, 500002, 5, 0, 0, 0, 0, 0, 0, 0, 98, 254,
   0, -40, 102, -400,  254,254,254,254,254, 254,254,254,254,254,254),
  -- Small self-heal; scales with level, capped.
  (42711, 'Standard Absolution', 83, 1, 500003, 6, 1, 0, 0, 0, 0, 0, 0, 98, 254,
   0, 50, 102, 500,    254,254,254,254,254, 254,254,254,254,254,254),
  -- Short mitigation rune.
  (42712, 'Warden''s Bulwark',   83, 1, 500004, 6, 1, 3, 3, 0, 0, 0, 0, 98, 254,
   162, 30, 102, 300,  254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- the three mantles, Mk. I / II / III ----------
-- rank 1 / 5 / 10 per the stock convention.
-- classes2 = 254: AA-granted, never scribed - so these are NOT subject to the
-- spellbook cap themselves, but they are kept in-band anyway for consistency.
-- buffdurationformula 50 = permanent: a mantle persists until swapped.
-- Layout (identical across all nine - the precondition for clean overwrite):
--   1:125 heal focus  2:132 mana cost  3:220 melee dmg  4:177 double attack
--   5:323 own proc    6:149 swap rider 7-12: 254 blank
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time, mana, skill,
   classes2,
   effectid1, effect_base_value1, formula1,
   effectid2, effect_base_value2, formula2,
   effectid3, effect_base_value3, effect_limit_value3, formula3,
   effectid4, effect_base_value4, formula4,
   effectid5, effect_base_value5, effect_limit_value5, formula5,
   effectid6, effect_base_value6, formula6, max6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== Zealot's Mantle (offense): heal focus NEGATIVE, melee up =====
  (42700, 'Zealot''s Mantle Mk. I',   83,  1, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, -20, 100,  132, 0, 100,  220, 15, 10, 100,  177, 5,  100,  323, 42710, 100, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (42701, 'Zealot''s Mantle Mk. II',  83,  5, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, -15, 100,  132, 0, 100,  220, 35, 10, 100,  177, 12, 100,  323, 42710, 175, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (42702, 'Zealot''s Mantle Mk. III', 83, 10, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, -10, 100,  132, 0, 100,  220, 60, 10, 100,  177, 20, 100,  323, 42710, 275, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),

  -- ===== Standard Mantle (balanced): the default healing posture =====
  (42703, 'Standard Mantle Mk. I',   83,  1, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 15, 100,   132, 5,  100,  220, 0, 10, 100,   177, 0, 100,   323, 42711, 100, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (42704, 'Standard Mantle Mk. II',  83,  5, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 28, 100,   132, 11, 100,  220, 0, 10, 100,   177, 0, 100,   323, 42711, 175, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (42705, 'Standard Mantle Mk. III', 83, 10, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 45, 100,   132, 18, 100,  220, 0, 10, 100,   177, 0, 100,   323, 42711, 275, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),

  -- ===== Warden's Mantle (defense): amplifies the defensive proc suite =====
  (42706, 'Warden''s Mantle Mk. I',   83,  1, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 5, 100,    132, 0, 100,  220, 0, 10, 100,    177, 0, 100,   323, 42712, 250, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (42707, 'Warden''s Mantle Mk. II',  83,  5, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 9, 100,    132, 0, 100,  220, 0, 10, 100,    177, 0, 100,   323, 42712, 400, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (42708, 'Warden''s Mantle Mk. III', 83, 10, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 14, 100,   132, 0, 100,  220, 0, 10, 100,   177, 0, 100,   323, 42712, 600, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254);

-- ==============================================================================
-- TEST MATRIX - run in-game before authoring any further pool.
-- Spells live in SHARED MEMORY: regenerate it and restart, or #reloadspells,
-- or none of these rows are visible to a zone.
--
--   1. Cast Standard Mk. I            -> buff lands.
--   2. Cast Standard Mk. III          -> upgrades in place (plain value compare).
--   3. Cast Zealot Mk. I WHILE III up -> MUST take hold. This is the SPA 149
--                                        rider doing its job; without it the
--                                        engine rejects the weaker spell and the
--                                        swap silently fails.
--   4. Cast Warden Mk. II             -> replaces Zealot Mk. I.
--   5. At every step exactly ONE mantle buff is present - never two.
--   6. Confirm the Standard Mantle actually improves a heal's output, which
--      proves the focus path and not_focusable=0 are both correct.
--
-- Step 3 is the gate. If it fails, SPA 149 does not behave as
-- zone/spells.cpp:3208 reads, and custom code becomes the fallback.
-- ==============================================================================
