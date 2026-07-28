-- 0014_magician_bolt_and_rain
--
-- Magician §9f — bolt and rain (spells 18-22), Mk. I / II / III.
--
-- WHY THIS SLICE. The Magician is the next class because it is the only one of
-- the eleven with ZERO engine dependencies (docs/worlddungeon/spells/magician.md
-- cites no W-items). But most of the class is NOT authorable yet:
--
--   * Spells 1-4, the four elemental servants, are the class core and their
--     identities live on `npc_types` TEMPLATES plus `pets` rows, not on the
--     player-side spell. Those templates do not exist. Authoring the summon
--     spells first would produce SPA 33 rows pointing at nothing.
--     -> That is a per-zone npc_types band claim under F1 and belongs in its own
--        migration. It is a genuine prerequisite, not a detail.
--   * Spells 6, 7, 11, 12, 13, 14-17 carry unresolved ⚠️ in the design doc
--     (AEMelee shape, pet avoidance SPA, non-caster aura anchoring, the familiar
--     graft mechanism). Those need source verification first.
--   * Spells 23-27 summon ITEMS and need item ids from the 1,000,000+ band.
--
-- §9f is the one section with no prerequisite of any kind: five plain damage
-- lines, SPA 0, no pet, no item, no ⚠️. So it ships now and the rest follows
-- once the servant templates exist.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  43711-43725   Magician bolt/rain, 5 lines x Mk. I/II/III
--   spellgroup     513018-513022 one per line
--
-- Idempotent: DELETE over the owned range, then INSERT.
--
--
-- SCALING. Authored correctly from the start per ENGINE-CAPS.md §4: caps are
-- REACHABLE, derived as base + 65*slope so Mk. III fills exactly at level 65,
-- with Mk. I and Mk. II filling at ~L30 and ~L50. This is the rule that
-- 0005/0006/0007/0009 all had to be retuned to satisfy - 59 inert caps between
-- them, including three Meteor tiers that delivered identical damage at 65.
--
-- Positioned against the Wizard deliberately: the Magician's personal damage
-- SUPPLEMENTS the pet, which is the class's main engine (magician.md §9f). So
-- these land well under Wizard equivalents - Emberbolt Mk. III at 780 against
-- Meteor's 1,095 - and the shortfall is the pet's share.
--
-- All eight loader-read text columns are omitted deliberately; migration 0010
-- made them NOT NULL DEFAULT '' so they resolve safely.

DELETE FROM spells_new WHERE id BETWEEN 43711 AND 43725;

INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   resisttype, buffdurationformula, buffduration, cast_time, recovery_time, recast_time, mana, skill,
   classes13,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 18. Emberbolt - ST bolt, fire (513018) =====
  -- base 90, slope 10.6 -> 11: caps 420 / 640 / 805
  (43711, 'Emberbolt Mk. I',    83,  1, 513018, 5, 0, 2, 0, 0, 2500, 1500, 4000, 130, 98, 200,
   0, -90, 11, -420,   254,254,254,254,254, 254,254,254,254,254,254),
  (43712, 'Emberbolt Mk. II',   83,  5, 513018, 5, 0, 2, 0, 0, 2500, 1500, 4000, 130, 98, 200,
   0, -90, 11, -640,   254,254,254,254,254, 254,254,254,254,254,254),
  (43713, 'Emberbolt Mk. III',  83, 10, 513018, 5, 0, 2, 0, 0, 2500, 1500, 4000, 130, 98, 200,
   0, -90, 11, -805,   254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 19. Shardbolt - ST bolt, magic (513019) =====
  -- magic resist so the pair is not both stopped by one elemental gate
  (43714, 'Shardbolt Mk. I',    83,  1, 513019, 5, 0, 6, 0, 0, 2500, 1500, 4000, 130, 98, 200,
   0, -90, 11, -420,   254,254,254,254,254, 254,254,254,254,254,254),
  (43715, 'Shardbolt Mk. II',   83,  5, 513019, 5, 0, 6, 0, 0, 2500, 1500, 4000, 130, 98, 200,
   0, -90, 11, -640,   254,254,254,254,254, 254,254,254,254,254,254),
  (43716, 'Shardbolt Mk. III',  83, 10, 513019, 5, 0, 6, 0, 0, 2500, 1500, 4000, 130, 98, 200,
   0, -90, 11, -805,   254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 20. Rain of Cinders - ground-target AE, fire (513020) =====
  -- targettype 4 = point-blank/ground AE. Lower per-target than the bolts.
  (43717, 'Rain of Cinders Mk. I',   83,  1, 513020, 4, 0, 2, 0, 0, 3000, 1500, 9000, 210, 98, 200,
   0, -60, 8, -350,    254,254,254,254,254, 254,254,254,254,254,254),
  (43718, 'Rain of Cinders Mk. II',  83,  5, 513020, 4, 0, 2, 0, 0, 3000, 1500, 9000, 210, 98, 200,
   0, -60, 8, -460,    254,254,254,254,254, 254,254,254,254,254,254),
  (43719, 'Rain of Cinders Mk. III', 83, 10, 513020, 4, 0, 2, 0, 0, 3000, 1500, 9000, 210, 98, 200,
   0, -60, 8, -580,    254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 21. Rain of Shards - ground-target AE, magic (513021) =====
  (43720, 'Rain of Shards Mk. I',    83,  1, 513021, 4, 0, 6, 0, 0, 3000, 1500, 9000, 210, 98, 200,
   0, -60, 8, -350,    254,254,254,254,254, 254,254,254,254,254,254),
  (43721, 'Rain of Shards Mk. II',   83,  5, 513021, 4, 0, 6, 0, 0, 3000, 1500, 9000, 210, 98, 200,
   0, -60, 8, -460,    254,254,254,254,254, 254,254,254,254,254,254),
  (43722, 'Rain of Shards Mk. III',  83, 10, 513021, 4, 0, 6, 0, 0, 3000, 1500, 9000, 210, 98, 200,
   0, -60, 8, -580,    254,254,254,254,254, 254,254,254,254,254,254),

  -- ===== 22. Elemental Barrage - fast filler (513022) =====
  -- Short cast and recast; the between-cooldowns filler, so low per-cast.
  (43723, 'Elemental Barrage Mk. I',   83,  1, 513022, 5, 0, 2, 0, 0, 1200, 1000, 1500, 55, 98, 200,
   0, -35, 4, -160,    254,254,254,254,254, 254,254,254,254,254,254),
  (43724, 'Elemental Barrage Mk. II',  83,  5, 513022, 5, 0, 2, 0, 0, 1200, 1000, 1500, 55, 98, 200,
   0, -35, 4, -230,    254,254,254,254,254, 254,254,254,254,254,254),
  (43725, 'Elemental Barrage Mk. III', 83, 10, 513022, 5, 0, 2, 0, 0, 1200, 1000, 1500, 55, 98, 200,
   0, -35, 4, -295,    254,254,254,254,254, 254,254,254,254,254,254);

-- Cap reachability check (ENGINE-CAPS.md §4) - all fill inside 1-65:
--   Emberbolt/Shardbolt  base 90 slope 11 -> raw@65 = 805  caps 420/640/805  (L30/L50/L65)
--   Rain lines           base 60 slope  8 -> raw@65 = 580  caps 350/460/580  (L36/L50/L65)
--   Elemental Barrage    base 35 slope  4 -> raw@65 = 295  caps 160/230/295  (L31/L49/L65)
