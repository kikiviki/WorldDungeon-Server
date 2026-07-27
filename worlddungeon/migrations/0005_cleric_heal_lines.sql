-- 0005_cleric_heal_lines
--
-- Cleric spells 4-11 (docs/worlddungeon/spells/cleric.md section 9d): the four
-- heal lines, the complete heal, the two HoTs, and the death save. 8 spells x
-- Mk. I/II/III = 24 rows, ids 42713-42736.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  42713-42736  Cleric heal lines, 8 spells x Mk. I/II/III
--   spellgroup     502001-502008  clr_heal_* / clr_hot_* / clr_deathsave
--
-- The Deathward payload id 42800 reserved in cleric.md is NOT used: SPA 150
-- carries its heal amount in its own max field (zone/bonuses.cpp:2692), so no
-- payload spell exists. The id stays reserved in the doc.
--
-- Idempotent: DELETE over the range, then INSERT.
--
-- ------------------------- SCALING MODEL ------------------------------------
-- Unlike the mantles (all percentages, formula 100), these are OUTPUT spells,
-- so the Mk. model applies literally: same formula per line, rising `max` per
-- tier. Heal lines use formula 105 (base + 4*level); caps are placed so
--   Mk. I   caps out around level 30      (the workhorse tier)
--   Mk. II  caps out around level 50      (first rebirths)
--   Mk. III has headroom past level 65    (the elite chase, gear/AA fill it)
-- HoT ticks use formula 102 (base + level), gentler per-tick growth.
--
-- Two deliberate deviations from the "max rises" rule, both percentage-shaped
-- per the README's flat% rule:
--   * Reclamation (SPA 101 CompleteHeal) is binary - its tier axis is the
--     RECAST: 300s / 240s / 180s.
--   * Deathward (SPA 150) tiers its restored-HP max (800/1500/3000); the save
--     CHANCE is engine-side CHA-scaling (zone/spell_effects.cpp:7204), not
--     authorable here.
--
-- TUNING SURFACE (flagged open in cleric.md section 5): mana costs, cast
-- times, and the instant/slow efficiency gap below are first-pass numbers.
-- The line CONTRACT is: instant = expensive + cooldown, slow = cheap + no
-- cooldown, roughly 2x the mana efficiency. Change values, keep the contract.
--
-- classes2 = 1: castable from level 1; tier access is gated by the A3 spell
-- vendor (Paragon entitlement), not by level.
-- Instants explicitly set buffdurationformula 0 - the column DEFAULT is 7,
-- which would wrongly make SPA 0 tick as a buff.
-- Icons/gem art not set - client polish pass later, same as 0004.
-- ----------------------------------------------------------------------------

DELETE FROM spells_new WHERE id BETWEEN 42713 AND 42736;

-- ---------- instant + slow direct heal lines (4-7) and Reclamation (8) ------
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, aoerange, classes2,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 4. Intercession - single instant, short CD, high mana (502001) =====
  (42713, 'Intercession Mk. I',   83,  1, 502001, 5, 1, 0, 0, 0, 12000, 1500, 120, 98, 100, 0, 1,
   0, 60, 105, 180,   254,254,254,254,254, 254,254,254,254,254,254),
  (42714, 'Intercession Mk. II',  83,  5, 502001, 5, 1, 0, 0, 0, 12000, 1500, 120, 98, 100, 0, 1,
   0, 60, 105, 300,   254,254,254,254,254, 254,254,254,254,254,254),
  (42715, 'Intercession Mk. III', 83, 10, 502001, 5, 1, 0, 0, 0, 12000, 1500, 120, 98, 100, 0, 1,
   0, 60, 105, 440,   254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 5. Ward of the Fold - group instant, short CD (502002) [W2] =====
  (42716, 'Ward of the Fold Mk. I',   83,  1, 502002, 3, 1, 0, 0, 0, 18000, 1500, 250, 98, 100, 100, 1,
   0, 45, 105, 150,   254,254,254,254,254, 254,254,254,254,254,254),
  (42717, 'Ward of the Fold Mk. II',  83,  5, 502002, 3, 1, 0, 0, 0, 18000, 1500, 250, 98, 100, 100, 1,
   0, 45, 105, 260,   254,254,254,254,254, 254,254,254,254,254,254),
  (42718, 'Ward of the Fold Mk. III', 83, 10, 502002, 3, 1, 0, 0, 0, 18000, 1500, 250, 98, 100, 100, 1,
   0, 45, 105, 380,   254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 6. Mending Light - single slow, efficient, no CD (502003) =====
  (42719, 'Mending Light Mk. I',   83,  1, 502003, 5, 1, 0, 0, 3500, 0, 1500, 60, 98, 100, 0, 1,
   0, 90, 105, 240,   254,254,254,254,254, 254,254,254,254,254,254),
  (42720, 'Mending Light Mk. II',  83,  5, 502003, 5, 1, 0, 0, 3500, 0, 1500, 60, 98, 100, 0, 1,
   0, 90, 105, 400,   254,254,254,254,254, 254,254,254,254,254,254),
  (42721, 'Mending Light Mk. III', 83, 10, 502003, 5, 1, 0, 0, 3500, 0, 1500, 60, 98, 100, 0, 1,
   0, 90, 105, 580,   254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 7. Communal Light - group slow, efficient, no CD (502004) [W2] =====
  (42722, 'Communal Light Mk. I',   83,  1, 502004, 3, 1, 0, 0, 6000, 0, 1500, 150, 98, 100, 100, 1,
   0, 70, 105, 200,   254,254,254,254,254, 254,254,254,254,254,254),
  (42723, 'Communal Light Mk. II',  83,  5, 502004, 3, 1, 0, 0, 6000, 0, 1500, 150, 98, 100, 100, 1,
   0, 70, 105, 340,   254,254,254,254,254, 254,254,254,254,254,254),
  (42724, 'Communal Light Mk. III', 83, 10, 502004, 3, 1, 0, 0, 6000, 0, 1500, 150, 98, 100, 100, 1,
   0, 70, 105, 500,   254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 8. Reclamation - complete heal, long cast, long CD (502005) =====
  -- SPA 101 CompleteHeal is binary; the tier axis is the recast (see header).
  (42725, 'Reclamation Mk. I',   83,  1, 502005, 5, 1, 0, 0, 9000, 300000, 2250, 400, 98, 100, 0, 1,
   101, 1, 100, 0,    254,254,254,254,254, 254,254,254,254,254,254),
  (42726, 'Reclamation Mk. II',  83,  5, 502005, 5, 1, 0, 0, 9000, 240000, 2250, 400, 98, 100, 0, 1,
   101, 1, 100, 0,    254,254,254,254,254, 254,254,254,254,254,254),
  (42727, 'Reclamation Mk. III', 83, 10, 502005, 5, 1, 0, 0, 9000, 180000, 2250, 400, 98, 100, 0, 1,
   101, 1, 100, 0,    254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- HoTs (9-10) and Deathward (11) - buff spells ----------
-- bdf 3 + buffduration cap = fixed tick count (stock Celestial Healing shape).
-- Sacrament carries the SPA 128 spell-duration rider from cleric.md ("pre-cast
-- and anticipate"): while the HoT runs, the target's own buffs last longer.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, aoerange, classes2,
   effectid1, effect_base_value1, effect_limit_value1, formula1, max1,
   effectid2, effect_base_value2, formula2, max2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 9. Sacrament - single HoT, 4 ticks (24s) + duration rider (502006) =====
  (42728, 'Sacrament Mk. I',   83,  1, 502006, 5, 1, 3, 4, 2500, 0, 1500, 60, 98, 100, 0, 1,
   0, 20, 0, 102, 60,     128, 10, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (42729, 'Sacrament Mk. II',  83,  5, 502006, 5, 1, 3, 4, 2500, 0, 1500, 60, 98, 100, 0, 1,
   0, 20, 0, 102, 95,     128, 15, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (42730, 'Sacrament Mk. III', 83, 10, 502006, 5, 1, 3, 4, 2500, 0, 1500, 60, 98, 100, 0, 1,
   0, 20, 0, 102, 140,    128, 20, 100, 0,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 10. Sacrament of the Fold - group HoT, 4 ticks (502007) [W2] =====
  (42731, 'Sacrament of the Fold Mk. I',   83,  1, 502007, 3, 1, 3, 4, 4500, 0, 1500, 150, 98, 100, 100, 1,
   0, 16, 0, 102, 50,     254, 0, 100, 0,    254,254,254,254, 254,254,254,254,254,254),
  (42732, 'Sacrament of the Fold Mk. II',  83,  5, 502007, 3, 1, 3, 4, 4500, 0, 1500, 150, 98, 100, 100, 1,
   0, 16, 0, 102, 80,     254, 0, 100, 0,    254,254,254,254, 254,254,254,254,254,254),
  (42733, 'Sacrament of the Fold Mk. III', 83, 10, 502007, 3, 1, 3, 4, 4500, 0, 1500, 150, 98, 100, 100, 1,
   0, 16, 0, 102, 120,    254, 0, 100, 0,    254,254,254,254, 254,254,254,254,254,254),

  -- ===== 11. Deathward - single, instant, 10 min CD, 30-tick buff (502008) =====
  -- SPA 150: base 1 = partial save; limit = min level for the heal (1 = always);
  -- max = HP restored on save. Save CHANCE is CHA-driven in the engine (flat%).
  (42734, 'Deathward Mk. I',   83,  1, 502008, 5, 1, 3, 30, 0, 600000, 1500, 300, 98, 100, 0, 1,
   150, 1, 1, 100, 800,   254, 0, 100, 0,    254,254,254,254, 254,254,254,254,254,254),
  (42735, 'Deathward Mk. II',  83,  5, 502008, 5, 1, 3, 30, 0, 600000, 1500, 300, 98, 100, 0, 1,
   150, 1, 1, 100, 1500,  254, 0, 100, 0,    254,254,254,254, 254,254,254,254,254,254),
  (42736, 'Deathward Mk. III', 83, 10, 502008, 5, 1, 3, 30, 0, 600000, 1500, 300, 98, 100, 0, 1,
   150, 1, 1, 100, 3000,  254, 0, 100, 0,    254,254,254,254, 254,254,254,254,254,254);

-- ==============================================================================
-- TEST MATRIX - run in-game after shared memory regen / #reloadspells.
--
--   1. Scribe + cast Mending Light Mk. I at low level -> heal lands, value
--      grows with level (formula 105), stops growing at the max cap.
--   2. Cast Intercession -> instant, then locked out ~12s (recast honored).
--   3. Cast Sacrament -> 4 ticks of healing over 24s; while it runs, a
--      self-buff's duration is extended ~10% (the SPA 128 rider).
--   4. Cast Reclamation on a wounded target -> full heal; recast lockout.
--   5. Cast Deathward, then die to a mob -> save fires sometimes (CHA-based),
--      restoring ~800 HP at Mk. I. Buff persists 3 min if untriggered.
--   6. Group heals (Ward of the Fold, Communal Light, Fold HoT) heal the
--      caster solo; group members in range; NOT pets until W2 lands.
--   7. Mk. II over Mk. I -> higher cap takes hold in place.
-- ==============================================================================

-- ---------------------------------------------------------------------------
-- MANDATORY TAIL — see 0008_spell_text_nulls.sql.
--
-- Six spells_new varchar columns are NULLABLE with a NULL default, and
-- SharedDatabase::LoadSpells() (common/shareddb.cpp:1686-1691) copies them into
-- std::string with no NULL guard. One NULL kills the whole shared-memory build
-- and every custom spell silently vanishes. The INSERTs above do not name them,
-- so normalise the owned range here.
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
WHERE id BETWEEN 42713 AND 42736;
