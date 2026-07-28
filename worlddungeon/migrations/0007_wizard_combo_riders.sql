-- 0007_wizard_combo_riders
--
-- The Wizard's combo riders and payloads (wizard.md sections 1 and 9d) - the
-- P3.1 DETONATION REFERENCE TEMPLATE that Necromancer, Beastlord, Druid,
-- Enchanter and Rogue copy. First consumer of W1.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  43570, 43573, 43576, 43579  riders 11-14 (single rows -
--                  the doc reserved tiered triples; +1/+2 stay unused, see below)
--   spells_new.id  43630-43633                 their payloads
--   spellgroup     512020-512023               rider lines
--
-- ------------------------- THE PATTERN --------------------------------------
-- nuke  --SPA 374 (base 100% / limit rider)-->  RIDER lands on target
-- rider = 1-tick unresistable buff, one effect:
--   SPA 442 TriggerOnReqTarget: base = payload id, limit = 60000
--   (IS_TARGET_HAS_WD_SPELLGROUP), max = the lure spellgroup to look for
-- engine (W1, zone/mob.cpp TryTriggerOnCastRequirement): if the rider's
-- holder has any buff in that spellgroup -> payload fires on the holder and
-- the RIDER fades. The lure is untouched - matched combos repeat for free.
-- No lure -> rider sits its single tick and fades silently. Custom
-- restriction ids have no client message, so the miss is silent by design.
--
-- RIDERS ARE NOT TIERED. All three Mk. tiers of a nuke point at the same
-- rider; tier scaling lives in the nuke and in the payload's level formula.
-- The doc reserved triples (43570-43581); base ids are used, +1/+2 spare.
--
-- KNOWN LIMITS of the data-only shape - verify in-game, fix in the pattern
-- (not per class) if wrong:
--   * ATTRIBUTION: TryTriggerOnCastRequirement fires the payload as
--     SpellFinished(payload, this) ON THE HOLDER - the payload is self-cast
--     by the mob. Damage credit may not accrue to the wizard. Check kill
--     credit / XP on a combo kill.
--   * TIMING: the trigger check runs on damage/cast events, not instantly on
--     rider application. Expected feel: the lure primes, the FOLLOWING nuke
--     (or next hit) pays off. Confirm the payoff isn't delayed a full tick.
--   * LURE STRIP: Scald/Sear are authored WITHOUT the "strips the lure"
--     behaviour - no stock SPA removes a specific spellgroup's buff from a
--     target. Open item; candidates: small C++ (fade-by-spellgroup on the
--     442 path) or accepting refresh-blocked Scald as the limiter.
--   * DEFERRED SPELLS: Thermal Shock (15) needs an AND of two restrictions;
--     Cascade (16) needs a lure-count-across-targets predicate. Neither is
--     expressible with one 442 slot - they wait on a W1 extension.
--
-- SPA 20 blind vs NPCs is an open item (wizard.md) - Scald/Sear payloads
-- carry it as designed; if NPC blind proves degenerate, tune there.
--
-- Idempotent: DELETE over both ranges, then INSERT.

DELETE FROM spells_new WHERE id BETWEEN 43570 AND 43581;
DELETE FROM spells_new WHERE id BETWEEN 43630 AND 43633;

-- ---------- riders 11-14: 1-tick 442 carriers ----------
-- Unresistable (resisttype 0), no cost, never scribed (classes all default
-- 255). goodEffect 0 so they land on hostiles.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time, mana, skill, `range`,
   effectid1, effect_base_value1, effect_limit_value1, formula1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- 11. Ignition: fire nuke + fire lure -> amplified fire damage, lure kept
  (43570, 'Ignition',      83, 1, 512020, 5, 0, 0, 3, 1, 0, 0, 0, 0, 98, 200,
   442, 43632, 60000, 100, 512001,   254,254,254,254,254, 254,254,254,254,254,254),
  -- 12. Rime: cold nuke + cold lure -> amplified cold damage, lure kept
  (43573, 'Rime',          83, 1, 512021, 5, 0, 0, 3, 1, 0, 0, 0, 0, 98, 200,
   442, 43633, 60000, 100, 512002,   254,254,254,254,254, 254,254,254,254,254,254),
  -- 13. Scald: cold nuke + FIRE lure -> steam DoT + blind (lure strip: open)
  (43576, 'Scald',         83, 1, 512022, 5, 0, 0, 3, 1, 0, 0, 0, 0, 98, 200,
   442, 43630, 60000, 100, 512001,   254,254,254,254,254, 254,254,254,254,254,254),
  -- 14. Sear: fire nuke + COLD lure -> mirror of Scald
  (43579, 'Sear',          83, 1, 512023, 5, 0, 0, 3, 1, 0, 0, 0, 0, 98, 200,
   442, 43631, 60000, 100, 512002,   254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- payloads 43630-43633 ----------
-- Untiered; they scale with caster level (the parent nuke's tier already
-- gated access). Self-cast by the holder via the 442 path (see header).
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time, mana, skill, `range`,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, formula2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- Scald: 2-tick steam DoT + blind. Does not restack - refresh only (stock
  -- same-spell behaviour), per wizard.md "a blind that stacks is a hard lock".
  (43630, 'Scald Payload', 83, 1, 512022, 5, 0, 2, 3, 2, 0, 0, 0, 0, 98, 200,
   0, -30, 1, -95,    20, 1, 100,   254,254,254,254, 254,254,254,254,254,254),
  -- Sear: the cold mirror
  (43631, 'Sear Payload',  83, 1, 512023, 5, 0, 3, 3, 2, 0, 0, 0, 0, 98, 200,
   0, -30, 1, -95,    20, 1, 100,   254,254,254,254, 254,254,254,254,254,254),
  -- Ignition: instant amplified fire damage (matched-combo payoff)
  (43632, 'Ignition Payload', 83, 1, 512020, 5, 0, 2, 0, 0, 0, 0, 0, 0, 98, 200,
   0, -60, 10, -710,    254, 0, 100,  254,254,254,254, 254,254,254,254,254,254),
  -- Rime: instant amplified cold damage
  (43633, 'Rime Payload',  83, 1, 512021, 5, 0, 3, 0, 0, 0, 0, 0, 0, 98, 200,
   0, -60, 10, -710,    254, 0, 100,  254,254,254,254, 254,254,254,254,254,254);

-- ==============================================================================
-- TEST MATRIX - the W1 done-when criterion lives here. Regen shared memory /
-- #reloadspells first. Requires 0006 applied (nukes carry the 374 slots).
--
--   1. Fire Burst on an UNLURED mob -> normal damage only; no extra hit, no
--      combat-log noise (the rider applies, finds nothing, fades silently).
--   2. Lure of Flame, then Fire Burst -> Ignition payload fires: extra fire
--      damage ON TOP of the nuke. THE LURE MUST STILL BE ON THE TARGET.
--      Repeat the nuke - it combos again (matched = repeatable).
--   3. Lure of Flame, then Ice Burst -> Scald: 2 ticks of DoT + target blind.
--      Note whether the lure survives (strip is a known open item, expected
--      NOT to strip yet).
--   4. Check ATTRIBUTION on a combo killing blow - does the wizard get XP?
--   5. Check TIMING - does the payload land with the same cast, or one event
--      late? (Both are acceptable v1; document which.)
--   6. Conflagrant Lure on a pack, then Asteroid Shower -> every lured target
--      takes the Scald payload (the marquee line, per-target 374).
--   7. SPA 20 vs NPC: does blind actually degrade NPC melee/pathing?
-- ==============================================================================

-- ---------------------------------------------------------------------------
-- MANDATORY TAIL — see 0008_spell_text_nulls.sql.
--
-- Six spells_new varchar columns are NULLABLE with a NULL default, and
-- SharedDatabase::LoadSpells() (common/shareddb.cpp:1686-1691) copies them into
-- std::string with no NULL guard. One NULL kills the whole shared-memory build
-- and every custom spell silently vanishes.
--
-- Every future migration that writes spells_new must end with this block over
-- its own id range. `wd-migrate new` scaffolds it.
-- ---------------------------------------------------------------------------
UPDATE spells_new
SET teleport_zone = COALESCE(teleport_zone, ''),
    you_cast      = COALESCE(you_cast,      ''),
    other_casts   = COALESCE(other_casts,   ''),
    cast_on_you   = COALESCE(cast_on_you,   ''),
    cast_on_other = COALESCE(cast_on_other, ''),
    spell_fades   = COALESCE(spell_fades,   ''),
    typedescnum   = COALESCE(typedescnum,   0),
    effectdescnum = COALESCE(effectdescnum, 0)
WHERE id BETWEEN 43570 AND 43659;
