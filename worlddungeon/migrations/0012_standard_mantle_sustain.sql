-- 0012_standard_mantle_sustain
--
-- Purpose: rebuild the Standard Mantle as a SUSTAIN posture rather than a raw
-- throughput buff. 0004 and 0011 are applied and immutable, so this supersedes
-- their Standard Mantle values.
--
-- ID ranges claimed: none. Rewrites existing rows 42703-42705.
--
-- Idempotent: plain UPDATEs to fixed values.
--
--
-- ============================ WHY THE REWORK =================================
--
-- The mantle was carrying SPA 125 ImprovedHeal as its identity, aiming at a
-- ~150% heal bonus by level 65. That could not work, for a reason that is
-- structural rather than a tuning problem:
--
--   FOCUS VALUES NEVER SCALE WITH LEVEL. CalcFocusEffect assigns the raw column
--   (spell_effects.cpp:5166 and every sibling case), never routing through
--   CalcSpellEffectValue, so `formula` is ignored. Checked all six heal-focus
--   SPAs - 392, 393, 394, 395, 396, 413 - and every one is raw base_value.
--
-- So a growing heal percentage would have had to come from AA ranks, which the
-- owner rightly rejected: that hands out power the player did not specifically
-- invest in.
--
-- The resolution is to stop asking the mantle to scale at all:
--
--   EFFICIENCY PERCENTAGES DO NOT NEED LEVEL SCALING. THROUGHPUT PERCENTAGES DO.
--
-- A 25% mana discount is worth exactly as much at 65 as at 10, because it is a
-- ratio against a cost that scales alongside. A 25% heal bonus is not, because
-- gear focus and +heal stats are also stacking onto the same number. Rebuilding
-- the mantle around efficiency makes the flat-focus constraint irrelevant
-- instead of something to fight.
--
-- It also restores the vault's own wording. Cleric.md 9a: "Standard Mantle -
-- +healing EFFICIENCY, no melee bonuses (the default healing posture)."
-- Efficiency was always the design; the implementation drifted to throughput.
--
-- W13 is what makes this possible: exclusivity is now a shared spell_group, so
-- the mantles no longer have to share an effect layout and each can carry the
-- effects it actually wants.
--
--
-- =========================== THE SUSTAIN POSTURE =============================
--
--   SPA 132 ReduceManaCost      10 / 18 / 25 %    throughput per mana
--   SPA 127 IncreaseSpellHaste   5 / 10 / 15 %    casts per second
--   SPA 125 ImprovedHeal        10 / 20 / 30 %    still "a bit more healing"
--
-- Cast haste is the thematically right lever: 9d makes the SLOW heals the
-- workhorse, with real cast times demanding anticipation. Shaving them is
-- exactly what a default healing posture should do, and it is felt on every
-- cast rather than only when a heal lands short.
--
-- SPA 127 sign and cap, verified at mob.cpp:5257-5275:
--     casttime = casttime * (100 - cast_reducer) / 100;   // POSITIVE = faster
--     cast_reducer = std::min(cast_reducer, 50);          // hard 50% ceiling
-- The ceiling is on the SUM of all spell-haste focus, so 15% from the mantle
-- leaves 35% of headroom for gear rather than crowding it out.
--
-- SPA 132 takes base as min pct and limit as max pct; both are set equal so the
-- discount is deterministic rather than a random band.
--
-- Slot 4 (was 177 DoubleAttackChance) is cleared - double attack was never a
-- healer stat and only existed to pad the old shared layout.
-- Slot 5 keeps the mantle's own defensive proc.
-- Slot 6 (was 149 StackingCommand_Overwrite) is cleared on ALL THREE mantles:
-- W13 superseded it, and P1-STACKING-DEFECT.md showed it was never reached.

-- ---------- Standard Mantle: rebuild as sustain ----------
UPDATE spells_new SET
  effectid1 = 125, effect_base_value1 = 10, effect_limit_value1 = 0,   formula1 = 100,
  effectid2 = 132, effect_base_value2 = 10, effect_limit_value2 = 10,  formula2 = 100,
  effectid3 = 127, effect_base_value3 = 5,  effect_limit_value3 = 0,   formula3 = 100,
  effectid4 = 254, effect_base_value4 = 0,  effect_limit_value4 = 0,   formula4 = 100
WHERE id = 42703;  -- Mk. I

UPDATE spells_new SET
  effectid1 = 125, effect_base_value1 = 20, effect_limit_value1 = 0,   formula1 = 100,
  effectid2 = 132, effect_base_value2 = 18, effect_limit_value2 = 18,  formula2 = 100,
  effectid3 = 127, effect_base_value3 = 10, effect_limit_value3 = 0,   formula3 = 100,
  effectid4 = 254, effect_base_value4 = 0,  effect_limit_value4 = 0,   formula4 = 100
WHERE id = 42704;  -- Mk. II

UPDATE spells_new SET
  effectid1 = 125, effect_base_value1 = 30, effect_limit_value1 = 0,   formula1 = 100,
  effectid2 = 132, effect_base_value2 = 25, effect_limit_value2 = 25,  formula2 = 100,
  effectid3 = 127, effect_base_value3 = 15, effect_limit_value3 = 0,   formula3 = 100,
  effectid4 = 254, effect_base_value4 = 0,  effect_limit_value4 = 0,   formula4 = 100
WHERE id = 42705;  -- Mk. III

-- ---------- retire the dead SPA 149 rider on all three mantles ----------
UPDATE spells_new SET
  effectid6 = 254, effect_base_value6 = 0, formula6 = 100, max6 = 0
WHERE id BETWEEN 42700 AND 42708;
