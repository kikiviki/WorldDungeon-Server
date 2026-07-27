-- 0006_wizard_core
--
-- Wizard data-only core (docs/worlddungeon/spells/wizard.md): lures (1-4),
-- nukes (5-10), familiars (24-26) and Sculpt Spell (27). 14 spells x
-- Mk. I/II/III = 42 rows.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  43540-43569  lures + nukes (spells 1-10)
--   spells_new.id  43609-43620  familiars + Sculpt Spell (spells 24-27)
--   spellgroup     512001-512002, 512010-512015, 512050-512052, 512060
--
-- DEFERRED, not forgotten (see wizard.md):
--   * Combo riders 11-16 and their payloads 43630-43635: blocked on W1
--     (SpellRestriction 1000) and the SPA 374 semantics check. The lures
--     authored here already carry the load-bearing spellgroups (fire lures
--     share 512001, cold lures 512002) that every future combo Limit names.
--   * Mana ward 17-19: blocked on the W4 CommonDamage() package.
--   * Black hole 20-23, Careful Caster 28, ports 29-30: engine/script items.
--   * The Sculpt Spell -> AE-lure gate: the AE lures are authored UNGATED
--     because encoding "caster has buff in spellgroup N" is W1's restriction;
--     a follow-up migration sets cast_restriction once W1 defines the field
--     encoding. Until then the AE lures are simply castable.
--
-- SCALING: nukes and lure DDs are output spells - formula 105 / 102 with
-- rising negative max per tier (damage is negative SPA 0; caps cap the
-- magnitude). Resist debuffs and familiar focus percentages are flat% -
-- formula 100, the percentage itself steps per tier.
-- The +2 native advantage lives in Meteor/Asteroid Mk. III caps (-1100):
-- keep every dipped class's long-nuke cap visibly below this.
--
-- Lures: ResistDiff -300 = "almost always lands" - their presence IS the
-- combo flag, so a resisted lure means no combo. 5-tick (30s) window.
-- Familiars: stock shape (SPA 108 + teleport_zone pet, bdf 3600 permanent,
-- pets Familiar1/2/3 reused - cosmetic model only, no npc authoring).
-- Focus is SPA 124 ImprovedDamage; mono familiars carry SPA 135 LimitResist
-- (2 fire / 3 cold); Prismatic is unlimited at a lower % - it boosts ALL his
-- damage slightly, tuned to lose to the right mono familiar (wizard.md 24-26).
-- Sculpt Spell: SPA 10 base 0 blank buff (stock spacer); its only job is
-- presence. Tier axis = duration 36s/48s/60s.
--
-- classes12 = 1: Wizard, castable from level 1; tier access is A3-vendor
-- gated. Nukes explicitly set buffdurationformula 0 (column default is 7).
-- Icons/gem art deferred to the client polish pass, as 0004/0005.
--
-- Idempotent: DELETE over both ranges, then INSERT.

DELETE FROM spells_new WHERE id BETWEEN 43540 AND 43569;
DELETE FROM spells_new WHERE id BETWEEN 43609 AND 43620;

-- ---------- lures (1-4): small DD + resist debuff, the combo flag ----------
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype, ResistDiff,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, aoerange, classes12,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, formula2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 1. Lure of Flame - single fire lure (512001, shared with 3) =====
  (43540, 'Lure of Flame Mk. I',   83,  1, 512001, 5, 0, 2, -300, 3, 5, 1000, 0, 1500, 40, 98, 200, 0, 1,
   0, -10, 102, -60,    46, -30, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43541, 'Lure of Flame Mk. II',  83,  5, 512001, 5, 0, 2, -300, 3, 5, 1000, 0, 1500, 40, 98, 200, 0, 1,
   0, -10, 102, -90,    46, -45, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43542, 'Lure of Flame Mk. III', 83, 10, 512001, 5, 0, 2, -300, 3, 5, 1000, 0, 1500, 40, 98, 200, 0, 1,
   0, -10, 102, -130,   46, -60, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 2. Lure of Chill - single cold lure (512002, shared with 4) =====
  (43543, 'Lure of Chill Mk. I',   83,  1, 512002, 5, 0, 3, -300, 3, 5, 1000, 0, 1500, 40, 98, 200, 0, 1,
   0, -10, 102, -60,    47, -30, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43544, 'Lure of Chill Mk. II',  83,  5, 512002, 5, 0, 3, -300, 3, 5, 1000, 0, 1500, 40, 98, 200, 0, 1,
   0, -10, 102, -90,    47, -45, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43545, 'Lure of Chill Mk. III', 83, 10, 512002, 5, 0, 3, -300, 3, 5, 1000, 0, 1500, 40, 98, 200, 0, 1,
   0, -10, 102, -130,   47, -60, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 3. Conflagrant Lure - AE fire lure (512001) [Sculpt gate: W1] =====
  (43546, 'Conflagrant Lure Mk. I',   83,  1, 512001, 8, 0, 2, -300, 3, 5, 2500, 0, 1500, 120, 98, 200, 60, 1,
   0, -10, 102, -60,    46, -30, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43547, 'Conflagrant Lure Mk. II',  83,  5, 512001, 8, 0, 2, -300, 3, 5, 2500, 0, 1500, 120, 98, 200, 60, 1,
   0, -10, 102, -90,    46, -45, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43548, 'Conflagrant Lure Mk. III', 83, 10, 512001, 8, 0, 2, -300, 3, 5, 2500, 0, 1500, 120, 98, 200, 60, 1,
   0, -10, 102, -130,   46, -60, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 4. Glacial Lure - AE cold lure (512002) [Sculpt gate: W1] =====
  (43549, 'Glacial Lure Mk. I',   83,  1, 512002, 8, 0, 3, -300, 3, 5, 2500, 0, 1500, 120, 98, 200, 60, 1,
   0, -10, 102, -60,    47, -30, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43550, 'Glacial Lure Mk. II',  83,  5, 512002, 8, 0, 3, -300, 3, 5, 2500, 0, 1500, 120, 98, 200, 60, 1,
   0, -10, 102, -90,    47, -45, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43551, 'Glacial Lure Mk. III', 83, 10, 512002, 8, 0, 3, -300, 3, 5, 2500, 0, 1500, 120, 98, 200, 60, 1,
   0, -10, 102, -130,   47, -60, 100,   254,254,254,254, 254,254,254,254,254,254);

-- ---------- nukes (5-10): three cadences x two elements ----------
-- Every nuke carries two SPA 374 (ApplyEffect, base = 100% chance, limit =
-- rider spell) slots: slot 2 = its MATCHED rider, slot 3 = its OPPOSITE rider.
-- The riders (43570/43573/43576/43579, migration 0007) are 1-tick buffs whose
-- SPA 442 checks W1's restriction; without the right lure they apply and fade
-- doing nothing. On an AE nuke the 374 fires per target - the marquee line.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, aoerange, classes12,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, effect_limit_value2, formula2,
   effectid3, effect_base_value3, effect_limit_value3, formula3,
   effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 5/6. Fire Burst / Ice Burst - fast filler (512010/512011) =====
  (43552, 'Fire Burst Mk. I',   83,  1, 512010, 5, 0, 2, 0, 0, 2000, 0, 1500, 80, 98, 200, 0, 1,
   0, -50, 105, -200,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43553, 'Fire Burst Mk. II',  83,  5, 512010, 5, 0, 2, 0, 0, 2000, 0, 1500, 80, 98, 200, 0, 1,
   0, -50, 105, -340,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43554, 'Fire Burst Mk. III', 83, 10, 512010, 5, 0, 2, 0, 0, 2000, 0, 1500, 80, 98, 200, 0, 1,
   0, -50, 105, -500,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43555, 'Ice Burst Mk. I',    83,  1, 512011, 5, 0, 3, 0, 0, 2000, 0, 1500, 80, 98, 200, 0, 1,
   0, -50, 105, -200,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),
  (43556, 'Ice Burst Mk. II',   83,  5, 512011, 5, 0, 3, 0, 0, 2000, 0, 1500, 80, 98, 200, 0, 1,
   0, -50, 105, -340,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),
  (43557, 'Ice Burst Mk. III',  83, 10, 512011, 5, 0, 3, 0, 0, 2000, 0, 1500, 80, 98, 200, 0, 1,
   0, -50, 105, -500,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),

  -- ===== 7/8. Meteor / Asteroid - long cast, biggest numbers (512012/512013) =====
  -- The +2 native advantage lives in these Mk. III caps.
  (43558, 'Meteor Mk. I',    83,  1, 512012, 5, 0, 2, 0, 0, 6500, 0, 2250, 220, 98, 200, 0, 1,
   0, -120, 105, -450,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43559, 'Meteor Mk. II',   83,  5, 512012, 5, 0, 2, 0, 0, 6500, 0, 2250, 220, 98, 200, 0, 1,
   0, -120, 105, -750,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43560, 'Meteor Mk. III',  83, 10, 512012, 5, 0, 2, 0, 0, 6500, 0, 2250, 220, 98, 200, 0, 1,
   0, -120, 105, -1100,  374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43561, 'Asteroid Mk. I',   83,  1, 512013, 5, 0, 3, 0, 0, 6500, 0, 2250, 220, 98, 200, 0, 1,
   0, -120, 105, -450,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),
  (43562, 'Asteroid Mk. II',  83,  5, 512013, 5, 0, 3, 0, 0, 6500, 0, 2250, 220, 98, 200, 0, 1,
   0, -120, 105, -750,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),
  (43563, 'Asteroid Mk. III', 83, 10, 512013, 5, 0, 3, 0, 0, 6500, 0, 2250, 220, 98, 200, 0, 1,
   0, -120, 105, -1100,  374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),

  -- ===== 9/10. Meteor Shower / Asteroid Shower - long cast AE (512014/512015) =====
  (43564, 'Meteor Shower Mk. I',    83,  1, 512014, 8, 0, 2, 0, 0, 7000, 12000, 2250, 300, 98, 200, 80, 1,
   0, -80, 105, -300,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43565, 'Meteor Shower Mk. II',   83,  5, 512014, 8, 0, 2, 0, 0, 7000, 12000, 2250, 300, 98, 200, 80, 1,
   0, -80, 105, -500,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43566, 'Meteor Shower Mk. III',  83, 10, 512014, 8, 0, 2, 0, 0, 7000, 12000, 2250, 300, 98, 200, 80, 1,
   0, -80, 105, -750,   374, 100, 43570, 100,  374, 100, 43579, 100,  254,254,254, 254,254,254,254,254,254),
  (43567, 'Asteroid Shower Mk. I',   83,  1, 512015, 8, 0, 3, 0, 0, 7000, 12000, 2250, 300, 98, 200, 80, 1,
   0, -80, 105, -300,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),
  (43568, 'Asteroid Shower Mk. II',  83,  5, 512015, 8, 0, 3, 0, 0, 7000, 12000, 2250, 300, 98, 200, 80, 1,
   0, -80, 105, -500,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254),
  (43569, 'Asteroid Shower Mk. III', 83, 10, 512015, 8, 0, 3, 0, 0, 7000, 12000, 2250, 300, 98, 200, 80, 1,
   0, -80, 105, -750,   374, 100, 43573, 100,  374, 100, 43576, 100,  254,254,254, 254,254,254,254,254,254);

-- ---------- familiars (24-26) and Sculpt Spell (27) ----------
-- Familiars: SPA 108 is natively single-instance (E1 - swap replaces, stock).
-- Pet model comes from teleport_zone -> pets table; Familiar1/2/3 are stock.
INSERT INTO spells_new
  (id, name, teleport_zone, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes12,
   effectid1, effect_base_value1, formula1,
   effectid2, effect_base_value2, effect_limit_value2, formula2,
   effectid3, effect_base_value3, formula3,
   effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 24. Summon Mephit - fire specialist (512050) =====
  (43609, 'Summon Mephit Mk. I',   'Familiar1', 83,  1, 512050, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 5, 5, 100,    135, 2, 100,   254,254,254, 254,254,254,254,254,254),
  (43610, 'Summon Mephit Mk. II',  'Familiar1', 83,  5, 512050, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 8, 8, 100,    135, 2, 100,   254,254,254, 254,254,254,254,254,254),
  (43611, 'Summon Mephit Mk. III', 'Familiar1', 83, 10, 512050, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 12, 12, 100,  135, 2, 100,   254,254,254, 254,254,254,254,254,254),

  -- ===== 25. Summon Abyssal - cold specialist (512051) =====
  (43612, 'Summon Abyssal Mk. I',   'Familiar2', 83,  1, 512051, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 5, 5, 100,    135, 3, 100,   254,254,254, 254,254,254,254,254,254),
  (43613, 'Summon Abyssal Mk. II',  'Familiar2', 83,  5, 512051, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 8, 8, 100,    135, 3, 100,   254,254,254, 254,254,254,254,254,254),
  (43614, 'Summon Abyssal Mk. III', 'Familiar2', 83, 10, 512051, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 12, 12, 100,  135, 3, 100,   254,254,254, 254,254,254,254,254,254),

  -- ===== 26. Summon Prismatic - flexible, boosts everything a little (512052) =====
  -- No 135 limit: one focus can't carry two element limits (limits AND
  -- together), so "both" = unlimited at ~60% of mono. Beats the WRONG mono
  -- familiar, loses to the right one - the wizard.md tuning contract.
  (43615, 'Summon Prismatic Mk. I',   'Familiar3', 83,  1, 512052, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 3, 3, 100,    254, 0, 100,   254,254,254, 254,254,254,254,254,254),
  (43616, 'Summon Prismatic Mk. II',  'Familiar3', 83,  5, 512052, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 5, 5, 100,    254, 0, 100,   254,254,254, 254,254,254,254,254,254),
  (43617, 'Summon Prismatic Mk. III', 'Familiar3', 83, 10, 512052, 6, 1, 3600, 0, 4000, 0, 1500, 150, 98, 100, 1,
   108, 0, 100,   124, 7, 7, 100,    254, 0, 100,   254,254,254, 254,254,254,254,254,254),

  -- ===== 27. Sculpt Spell - blank presence buff gating the AE lures (512060) =====
  -- SPA 10 base 0 = stock blank effect. Tier axis: duration 6/8/10 ticks.
  (43618, 'Sculpt Spell Mk. I',   '', 83,  1, 512060, 6, 1, 3, 6,  0, 30000, 1500, 50, 98, 100, 1,
   10, 0, 100,    254, 0, 0, 100,    254, 0, 100,   254,254,254, 254,254,254,254,254,254),
  (43619, 'Sculpt Spell Mk. II',  '', 83,  5, 512060, 6, 1, 3, 8,  0, 30000, 1500, 50, 98, 100, 1,
   10, 0, 100,    254, 0, 0, 100,    254, 0, 100,   254,254,254, 254,254,254,254,254,254),
  (43620, 'Sculpt Spell Mk. III', '', 83, 10, 512060, 6, 1, 3, 10, 0, 30000, 1500, 50, 98, 100, 1,
   10, 0, 100,    254, 0, 0, 100,    254, 0, 100,   254,254,254, 254,254,254,254,254,254);

-- ==============================================================================
-- TEST MATRIX - run in-game after shared memory regen / #reloadspells.
--
--   1. Cast Lure of Flame on a fire-resistant mob -> lands anyway
--      (ResistDiff -300), small hit, fire-resist debuff visible ~30s.
--   2. Fire Burst / Meteor -> damage grows with level, stops at the Mk. cap;
--      Meteor Mk. I cap (-450) visibly above Fire Burst's (-200).
--   3. Meteor Shower on a pack -> hits multiple targets in 80 range, 12s CD.
--   4. Summon Mephit -> familiar appears, persists; fire nuke damage up ~5%,
--      cold nukes UNCHANGED (the 135 element limit).
--   5. Summon Abyssal while Mephit up -> replaces it (SPA 108 single-instance,
--      the E1 behaviour). Prismatic -> both elements up ~3%.
--   6. Sculpt Spell -> blank 36s self-buff appears. (The AE-lure gate arrives
--      with W1; until then Conflagrant/Glacial Lure cast ungated.)
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
WHERE id BETWEEN 43540 AND 43629;
