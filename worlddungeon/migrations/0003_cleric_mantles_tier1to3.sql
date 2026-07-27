-- 0003_cleric_mantles_tier1to3
--
-- Purpose: the Cleric's three religious mantles (Cleric.md 9a / 14a) at tiers
-- I-III, plus their defensive proc spells. This is deliberately a SLICE, not the
-- full 10 tiers: it exists to PROVE the stacking model before ~30 more rows are
-- written against it. Test matrix at the bottom of this file.
--
-- ID ranges claimed (see docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  100100-100108  Cleric mantles (3 mantles x 3 tiers)
--   spells_new.id  100110-100112  their defensive proc spells
--   spellgroup     500001         clr_mantle (mantle line)
--   spellgroup     500002-500004  one per proc line
--
-- Idempotent: DELETE over the owned id range, then INSERT. Safe because F1
-- guarantees the range is ours alone.
--
--
-- ===================== STACKING TAXONOMY (authoring rule) =====================
--
-- Not every tiered line needs the same treatment. Three cases:
--
--   1. INSTANT / NON-DURATION spells (nukes, heals, DDs).
--      No stacking concern at all - CheckStackConflict only governs buffs with a
--      duration. Fireball I, II and III can all sit on the spellbar together.
--      Tiers differ by damage, mana, cast time, AoE radius. NO 149 rider.
--
--   2. ORDINARY BUFFS, tiering upward (HP buffs, haste, resists).
--      Higher tier should overwrite lower, and that is exactly what same-layout
--      comparison already does - the stronger value wins. NO 149 rider needed.
--
--   3. MUTUALLY-EXCLUSIVE PARALLEL LINES (stances, mantles).
--      Several lines share one pool, each tiered 1-10 independently, and the
--      player must be able to swap in EITHER direction. Plain value comparison
--      rejects the weaker spell, so a player with Zealot III could not switch to
--      Warden I. THESE NEED THE SPA 149 RIDER. See P1-SOURCE-VERIFICATION.md 7.
--
-- Only case 3 pays the extra slot. Most of the spell library is case 1 or 2.
-- ==============================================================================
--
--
-- clr_mantle shared layout - ALL mantles carry ALL of these, in these slots.
-- (All 12 effectid slots must match for the engine to treat them as one line.)
--
--   slot 1  125 ImprovedHeal        heal focus   (negative on Zealot - the tradeoff)
--   slot 2  132 ReduceManaCost      mana cost
--   slot 3  220 SkillDamageAmount   melee damage
--   slot 4  177 DoubleAttackChance  double attack
--   slot 5  323 DefensiveProc       each mantle procs its own spell (never 0 -
--                                   a zero here would register proc spell 0 and
--                                   burn a MAX_AA_PROCS slot)
--   slot 6  149 StackingCommand_Overwrite   the swap-in-either-direction rider:
--                                   base=125 (watch slot 1's effect),
--                                   formula=201 (slot 1), max=999999 (any value)
--   slots 7-12  254 Blank

DELETE FROM spells_new WHERE id BETWEEN 100100 AND 100119;

-- ---------- proc spells (targets of slot 5) ----------
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time, mana, skill,
   classes2,
   effectid1, effect_base_value1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- Zealot procs damage back at the attacker
  (100110, 'Zealous Retribution', 83, 1, 500002, 5, 0, 0, 0, 0, 0, 0, 0, 98, 254,
   0, -60, 0,  254,254,254,254,254, 254,254,254,254,254,254),
  -- Standard procs a small self-heal
  (100111, 'Standard Absolution', 83, 1, 500003, 6, 1, 0, 0, 0, 0, 0, 0, 98, 254,
   0, 75, 0,   254,254,254,254,254, 254,254,254,254,254,254),
  -- Warden procs a short mitigation rune
  (100112, 'Warden''s Bulwark', 83, 1, 500004, 6, 1, 3, 3, 0, 0, 0, 0, 98, 254,
   162, 40, 0, 254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- the three mantles, tiers I-III ----------
-- classes2 = 254: granted by AA, not scribed at a level (matches stock stance rows).
-- buffdurationformula 50 = permanent (a stance persists until swapped).
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time, mana, skill,
   classes2,
   effectid1, effect_base_value1, effect_limit_value1, max1,
   effectid2, effect_base_value2,
   effectid3, effect_base_value3, effect_limit_value3,
   effectid4, effect_base_value4,
   effectid5, effect_base_value5, effect_limit_value5,
   effectid6, effect_base_value6, formula6, max6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== Zealot's Mantle (offense): heal focus NEGATIVE, melee up =====
  (100100, 'Zealot''s Mantle I',   83, 1, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, -15, 0, 0,  132, 0,   220, 10, 10,  177, 3,   323, 100110, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (100101, 'Zealot''s Mantle II',  83, 2, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, -13, 0, 0,  132, 0,   220, 20, 10,  177, 6,   323, 100110, 150,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (100102, 'Zealot''s Mantle III', 83, 3, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, -11, 0, 0,  132, 0,   220, 30, 10,  177, 9,   323, 100110, 200,  149, 125, 201, 999999,
   254,254,254,254,254,254),

  -- ===== Standard Mantle (balanced): the default healing posture =====
  (100103, 'Standard Mantle I',   83, 1, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 10, 0, 0,   132, 5,   220, 0, 10,   177, 0,   323, 100111, 100,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (100104, 'Standard Mantle II',  83, 2, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 15, 0, 0,   132, 8,   220, 0, 10,   177, 0,   323, 100111, 150,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (100105, 'Standard Mantle III', 83, 3, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 20, 0, 0,   132, 11,  220, 0, 10,   177, 0,   323, 100111, 200,  149, 125, 201, 999999,
   254,254,254,254,254,254),

  -- ===== Warden's Mantle (defense): amplifies the defensive proc suite =====
  (100106, 'Warden''s Mantle I',   83, 1, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 3, 0, 0,    132, 0,   220, 0, 10,   177, 0,   323, 100112, 250,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (100107, 'Warden''s Mantle II',  83, 2, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 5, 0, 0,    132, 0,   220, 0, 10,   177, 0,   323, 100112, 325,  149, 125, 201, 999999,
   254,254,254,254,254,254),
  (100108, 'Warden''s Mantle III', 83, 3, 500001, 6, 1, 50, 65534, 0, 0, 0, 0, 98, 254,
   125, 7, 0, 0,    132, 0,   220, 0, 10,   177, 0,   323, 100112, 400,  149, 125, 201, 999999,
   254,254,254,254,254,254);

-- ==============================================================================
-- TEST MATRIX - run in-game before authoring tiers IV-X or any Monk pool.
--
--   1. Cast Standard I           -> buff lands.
--   2. Cast Standard III         -> upgrades in place (case 2 behaviour).
--   3. Cast Zealot I  WHILE III  -> MUST take hold. This is the whole point of
--                                   the 149 rider; without it the engine rejects
--                                   the weaker spell and the swap silently fails.
--   4. Cast Warden II            -> replaces Zealot I.
--   5. At every step, exactly ONE mantle buff is present - never two.
--
-- Step 3 is the one that fails if SPA 149 does not behave as zone/spells.cpp:3208
-- reads. If it fails, fall back to custom code (offered) - but try this first.
-- ==============================================================================
