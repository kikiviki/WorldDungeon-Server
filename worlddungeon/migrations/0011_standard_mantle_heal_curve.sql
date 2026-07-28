-- 0011_standard_mantle_heal_curve
--
-- Purpose: retune the Standard Mantle's heal focus to the decided curve -
-- roughly +10% early, reaching about +150% at level 65 with no gear focus.
--
-- 0004 is applied and immutable, so this adjusts its rows rather than editing it.
--
-- ID ranges claimed: none. Retunes existing rows 42703-42705.
--
-- Idempotent: plain UPDATE to fixed values.
--
--
-- ================= WHY THE MANTLE ALONE CANNOT DELIVER THE CURVE =============
--
-- SPA 125 ImprovedHeal is a FOCUS effect, and focus values do NOT scale with
-- caster level. CalcFocusEffect takes the raw column:
--
--     case SpellEffect::ImprovedHeal:                  // spell_effects.cpp:5166
--         if (type == focusImprovedHeal && base_value > value) {
--             value = base_value;                      // <-- raw, no formula
--         }
--
-- Unlike ordinary effects it never goes through CalcSpellEffectValue, so the
-- `formula` field is ignored entirely. A single spell cannot ramp 10% -> 150%.
--
-- What makes the curve reachable is that focus SOURCES SUM. GetFocusEffect
-- returns (spell_effects.cpp:6886):
--
--     return realTotal + realTotal2 + realTotal3 + worneffect_bonus;
--              item        spell/buff    AA          worn
--
-- "Best wins" applies only WITHIN a source - the best item, the best buff. The
-- three sources themselves add. So the curve is built by stacking sources, not
-- by scaling one value.
--
--
-- ========================= THE DECIDED CURVE =================================
--
--   Cleric innate focus         5%    free - RuleI(Spells, ClericInnateHealFocus),
--                                     stock, confirmed on live (ruletypes.h:510)
--   Standard Mantle Mk. I      10%    this migration
--                  Mk. II      20%
--                  Mk. III     30%
--   Passive heal-potency AA   ~115%   NOT YET AUTHORED - the bulk of the curve.
--                                     AA rank effects carry SPA 125 natively
--                                     (bonuses.cpp:4126) and land in realTotal3.
--
--   Early game, Mk. I, no AA:        5 + 10        =  ~15%   ("a bit")
--   Level 65, Mk. III, full AA:      5 + 30 + 115  =  ~150%  (2.5x heal output)
--
-- Gear focus adds ON TOP of all of this, so heal-focus items keep their value
-- rather than being masked - which a single large mantle value would have done.
--
-- The split is deliberate. Putting the bulk in AA means the curve tracks
-- INVESTMENT and levelling, which is what "scales to 150% by 65" actually
-- describes, while the mantle stays a posture choice rather than the whole
-- power budget. It also keeps Mk. I relevant: the gap between Mk. I and Mk. III
-- is 20 percentage points out of ~150, not a 15x cliff.
--
-- NOTE the total heal at 65 grows far more than 2.5x, because the heal SPELLS
-- themselves scale with level via formula 105 (migration 0005). This focus
-- multiplies an already level-scaled base.
-- ============================================================================

UPDATE spells_new SET effect_base_value1 = 10 WHERE id = 42703;  -- Standard Mantle Mk. I
UPDATE spells_new SET effect_base_value1 = 20 WHERE id = 42704;  -- Standard Mantle Mk. II
UPDATE spells_new SET effect_base_value1 = 30 WHERE id = 42705;  -- Standard Mantle Mk. III

-- Zealot's penalty rescaled to stay meaningful against a ~150% total rather
-- than against the old ~45% ceiling. Still a real cost, still not crippling.
UPDATE spells_new SET effect_base_value1 = -25 WHERE id = 42700;  -- Zealot's Mk. I
UPDATE spells_new SET effect_base_value1 = -20 WHERE id = 42701;  -- Zealot's Mk. II
UPDATE spells_new SET effect_base_value1 = -15 WHERE id = 42702;  -- Zealot's Mk. III

-- TODO (next): author the passive heal-potency AA line carrying ~115% of SPA 125
-- across its ranks. Until it exists the Cleric tops out near +35%, so the
-- in-game step 6 check will show a real but modest improvement, not the full
-- design curve. That is expected, not a failure.
