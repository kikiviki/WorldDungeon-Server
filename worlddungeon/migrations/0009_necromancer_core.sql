-- 0009_necromancer_core
--
-- The Necromancer's data-only core (docs/worlddungeon/spells/necromancer.md).
-- 18 of his 30 spells x Mk. I/II/III = 54 rows. The other 12 are engine-blocked
-- and are enumerated at the bottom of this header - read that before assuming a
-- spell is missing by accident.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   spells_new.id  43420-43443  flavour DoTs, single-target and AE (1-3, 6-8)
--   spells_new.id  43456-43458  Deny the Reaper (13)
--   spells_new.id  43462-43464  Exsanguinate (15)
--   spells_new.id  43471-43473  Summon Bonelord (18)
--   spells_new.id  43483-43509  Grave Bulwark, HP-as-resource, nukes, utility
--   spellgroup     511001-511003, 511012, 511021, 511030, 511034,
--                  511040-511042, 511050-511054
--
-- No payload rows here. Every payload the class doc reserves (43,510-43,519)
-- belongs to a deferred spell.
--
-- classes11 = 1: Necromancer, castable from level 1; tier access is A3-vendor
-- gated, as 0005/0006. Icons and gem art deferred to the client polish pass.
--
-- Idempotent: DELETE over the owned ranges, then INSERT.
--
-- ------------------- THE SHARED FLAVOUR GROUPS ------------------------------
-- 511001 poison / 511002 disease / 511003 fire each hold BOTH the
-- single-target and the AE form of that flavour. This is load-bearing and is
-- called out in necromancer.md section 4: the deferred synergy and Reap
-- triggers name a spellgroup in W1's `max` field, and one 442 slot reads
-- exactly one group. Split the AE form into its own group and the class's
-- combos silently stop matching half its own DoTs.
--
-- ⚠️ This is why W13 was narrowed to beneficial spells (zone/spells.cpp).
-- spell_group now carries two unrelated meanings - W13's exclusivity pool and
-- W1's combo-flag family - and a combo family deliberately holds several
-- spells that must go on stacking normally. Stances are beneficial, flags are
-- detrimental, so the two never collide. Do not widen W13 without revisiting
-- every group in this file.
--
-- ------------------- FLAVOURS ARE resisttype ---------------------------------
-- poison = 4 (counter SPA 36), disease = 5 (counter SPA 35), fire = 2. Fire has
-- no counter SPA, so Ashen Rot and Cinderblight carry none - they are still a
-- full flavour for combo purposes, because W1 reads the SPELLGROUP, not the
-- counter. Cure interaction with the Cleric's Prexus cleanse is an open item in
-- both class docs and is NOT resolved here.
--
-- ------------------- DEVIATIONS FROM THE CLASS DOC ---------------------------
-- Written down per C13, which requires a reason for departing from a design doc.
--
-- 1. Summon Bonelord uses SPA 71 (NecPet), not the doc's SPA 33 (SummonPet).
--    SPA 33, 71, 106 and 108 all fall through to the same MakePet() handler
--    (zone/spell_effects.cpp:1283-1297), so this is behaviourally identical and
--    matches every stock Necromancer pet spell.
--
-- 2. The tiers use three different stock pet types rather than the doc's SPA
--    167 PetPowerIncrease. 167 is a FOCUS: it takes effect through the caster's
--    bonuses, so putting it in a later slot of the summon itself would apply
--    after MakePet() has already run and do nothing. Stock puts pet power on
--    AAs and gear, which is where it belongs. skel_pet_43_ / _44_ / _47_ are
--    existing rows in `pets` with existing npc_types - no new art, no new data.
--
-- 3. Lifetaps are expressed as targettype 13 (ST_Tap), which is what
--    IsLifetapSpell() actually keys on (common/spdat.cpp:108-120) - not a SPA.
--
-- ------------------- WHAT IS DEFERRED, AND WHY -------------------------------
-- Twelve spells. None of this is authorable today; see the notes at the foot.
--
--   4, 5   Synergy: Duality / Trinity   W1 EXTENSION - needs "target has 2 of
--                                       these 3 groups". One 442 slot reads one
--                                       group. This is the class's marquee.
--   9, 10  Reap / Harvest               W1 EXTENSION - flavour-COUNT scaling,
--                                       plus strip-on-detonate, which no stock
--                                       SPA provides. Reap REQUIRES consumption
--                                       (DETONATION-PATTERN.md section 4).
--   11,12  Dying Breath / Deathless Vigil   W5 threshold trigger.
--   14,16,17  Leeching Rot / Communal Drain / Bloodlink   W2 ally-target
--                                       expansion - the self/group/pet split IS
--                                       the design. 15 ships because the doc
--                                       explicitly gives it no group share.
--   19,20,21  Malediction / Mass Malediction / Bind the Risen   W7 swarm AI.
-- ============================================================================

DELETE FROM spells_new WHERE id BETWEEN 43420 AND 43443;
DELETE FROM spells_new WHERE id BETWEEN 43456 AND 43458;
DELETE FROM spells_new WHERE id BETWEEN 43462 AND 43464;
DELETE FROM spells_new WHERE id BETWEEN 43471 AND 43473;
DELETE FROM spells_new WHERE id BETWEEN 43483 AND 43509;

-- ---------- 1-3: single-target flavour DoTs ----------
-- The combo flags. buffdurationformula 1 = fixed tick count. Damage is per-tick
-- (SPA 0 in a duration spell repeats), formula 102 = base + level, max rises
-- per tier: the ceiling moves, the floor does not.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype, ResistDiff,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes11,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, formula2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 1. Venom of Nagafen - poison (511001, shared with 6) =====
  (43420, 'Venom of Nagafen Mk. I',   83,  1, 511001, 5, 0, 4, -20, 1,  8, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -12, 4, -90,    36, 4, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43421, 'Venom of Nagafen Mk. II',  83,  5, 511001, 5, 0, 4, -20, 1,  9, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -12, 4, -160,   36, 6, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43422, 'Venom of Nagafen Mk. III', 83, 10, 511001, 5, 0, 4, -20, 1, 10, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -12, 4, -272,   36, 8, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 2. Plaguebloom - disease (511002, shared with 7) =====
  (43423, 'Plaguebloom Mk. I',   83,  1, 511002, 5, 0, 5, -20, 1, 10, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -10, 3, -80,    35, 4, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43424, 'Plaguebloom Mk. II',  83,  5, 511002, 5, 0, 5, -20, 1, 11, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -10, 3, -145,   35, 6, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43425, 'Plaguebloom Mk. III', 83, 10, 511002, 5, 0, 5, -20, 1, 12, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -10, 3, -205,   35, 8, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 3. Ashen Rot - fire (511003, shared with 8). No counter SPA. =====
  -- Shortest and hardest-hitting of the three: fire is the burst flavour.
  (43426, 'Ashen Rot Mk. I',   83,  1, 511003, 5, 0, 2, -20, 1, 6, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -18, 5, -110,   254, 0, 100,  254,254,254,254, 254,254,254,254,254,254),
  (43427, 'Ashen Rot Mk. II',  83,  5, 511003, 5, 0, 2, -20, 1, 7, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -18, 5, -195,   254, 0, 100,  254,254,254,254, 254,254,254,254,254,254),
  (43428, 'Ashen Rot Mk. III', 83, 10, 511003, 5, 0, 2, -20, 1, 8, 2500, 1500, 1500, 60, 98, 200, 1,
   0, -18, 5, -343,   254, 0, 100,  254,254,254,254, 254,254,254,254,254,254);

-- ---------- 6-8: AE flavour DoTs ----------
-- Same spellgroup as their single-target counterpart - see the header. These
-- are how a flavour gets established across a pack before Harvest (deferred).
-- Lower per-tick damage, higher mana, longer cast: breadth costs.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype, ResistDiff,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, aoerange, classes11,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, formula2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 6. Miasma - AE poison (511001) =====
  (43435, 'Miasma Mk. I',   83,  1, 511001, 8, 0, 4, -20, 1,  8, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -8, 2, -55,     36, 3, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43436, 'Miasma Mk. II',  83,  5, 511001, 8, 0, 4, -20, 1,  9, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -8, 2, -100,    36, 4, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43437, 'Miasma Mk. III', 83, 10, 511001, 8, 0, 4, -20, 1, 10, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -8, 2, -138,    36, 5, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 7. Pall of Contagion - AE disease (511002) =====
  (43438, 'Pall of Contagion Mk. I',   83,  1, 511002, 8, 0, 5, -20, 1, 10, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -7, 2, -50,     35, 3, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43439, 'Pall of Contagion Mk. II',  83,  5, 511002, 8, 0, 5, -20, 1, 11, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -7, 2, -90,     35, 4, 100,   254,254,254,254, 254,254,254,254,254,254),
  (43440, 'Pall of Contagion Mk. III', 83, 10, 511002, 8, 0, 5, -20, 1, 12, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -7, 2, -137,    35, 5, 100,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 8. Cinderblight - AE fire (511003) =====
  (43441, 'Cinderblight Mk. I',   83,  1, 511003, 8, 0, 2, -20, 1, 6, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -11, 3, -70,    254, 0, 100,  254,254,254,254, 254,254,254,254,254,254),
  (43442, 'Cinderblight Mk. II',  83,  5, 511003, 8, 0, 2, -20, 1, 7, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -11, 3, -125,   254, 0, 100,  254,254,254,254, 254,254,254,254,254,254),
  (43443, 'Cinderblight Mk. III', 83, 10, 511003, 8, 0, 2, -20, 1, 8, 3500, 6000, 1500, 175, 98, 200, 50, 1,
   0, -11, 3, -206,   254, 0, 100,  254,254,254,254, 254,254,254,254,254,254);

-- ---------- 13: Deny the Reaper - SPA 150 Death Save ----------
-- The stock analog of the deferred W5 life ward, and worth having early because
-- it is the same code path with a different predicate (necromancer.md 9b).
--
-- SPA 150 field mapping, read off zone/bonuses.cpp:2686-2692:
--   base  = save TYPE, 1 = partial / 2 = full. NOT a magnitude.
--   limit = minimum caster level for the bonus heal to apply.
--   max   = BONUS heal on top of the hardcoded amount. <- the tier lever.
-- The base heal is hardcoded in TryDeathSave() (300 for type 1;
-- RuleI(Spells, DivineInterventionHeal), stock 8000, for type 2), so tiering
-- has to ride on `max`. Type stays 1 across all three tiers - jumping to 2
-- would hand a level-1 Necromancer an 8000 HP save.
--
-- ⚠️ OPEN, and it matters: the fire chance is CHARISMA-driven -
-- (CHA * RuleI(Spells, DeathSaveCharismaMod)) + 1) / 10, capped 95
-- (zone/spell_effects.cpp:7204). CHA is a Necromancer dump stat, so his
-- signature death-defiance fires around 20-25% of the time at typical CHA.
-- Options are a rule override, a CHA-independent WD variant, or accepting it.
-- Do not tune the numbers below until that is decided.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes11,
   effectid1, effect_base_value1, effect_limit_value1, formula1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  (43456, 'Deny the Reaper Mk. I',   83,  1, 511012, 6, 1, 3, 10, 3000, 90000, 1500, 200, 98, 100, 1,
   150, 1, 1, 100, 500,     254,254,254,254,254, 254,254,254,254,254,254),
  (43457, 'Deny the Reaper Mk. II',  83,  5, 511012, 6, 1, 3, 12, 3000, 75000, 1500, 200, 98, 100, 1,
   150, 1, 1, 100, 1500,    254,254,254,254,254, 254,254,254,254,254,254),
  (43458, 'Deny the Reaper Mk. III', 83, 10, 511012, 6, 1, 3, 15, 3000, 60000, 1500, 200, 98, 100, 1,
   150, 1, 1, 100, 3500,    254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- 15: Exsanguinate - single-target leech DoT ----------
-- targettype 13 (ST_Tap) is the lifetap flag - IsLifetapSpell() keys on target
-- type, not on any SPA (common/spdat.cpp:108-120). The doc gives this one no
-- group share, which is exactly why it ships while 14/16/17 wait on W2.
-- ⚠️ Whether a DURATION tap returns HP per tick or only on application is
-- unverified. First thing to watch in the test matrix.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype, ResistDiff,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes11,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  (43462, 'Exsanguinate Mk. I',   83,  1, 511021, 13, 0, 1, -20, 1, 7, 3000, 9000, 1500, 110, 98, 200, 1,
   0, -14, 4, -100,   254,254,254,254,254, 254,254,254,254,254,254),
  (43463, 'Exsanguinate Mk. II',  83,  5, 511021, 13, 0, 1, -20, 1, 8, 3000, 9000, 1500, 110, 98, 200, 1,
   0, -14, 4, -180,   254,254,254,254,254, 254,254,254,254,254,254),
  (43464, 'Exsanguinate Mk. III', 83, 10, 511021, 13, 0, 1, -20, 1, 9, 3000, 9000, 1500, 110, 98, 200, 1,
   0, -14, 4, -274,   254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- 18: Summon Bonelord - the Big Beefy Boy ----------
-- SPA 71 and a rising stock pet type per tier; see deviations 1 and 2 in the
-- header. teleport_zone carries the `pets` row key. targettype 6 = self,
-- buffdurationformula 0 = instant, matching every stock pet summon.
INSERT INTO spells_new
  (id, name, teleport_zone, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes11,
   effectid1, effect_base_value1, formula1,
   effectid2, effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  (43471, 'Summon Bonelord Mk. I',   'skel_pet_43_', 83,  1, 511030, 6, 1, 0, 0, 12000, 6000, 1500, 300, 98, 100, 1,
   71, 1, 100,   254,254,254,254,254, 254,254,254,254,254,254),
  (43472, 'Summon Bonelord Mk. II',  'skel_pet_44_', 83,  5, 511030, 6, 1, 0, 0, 12000, 6000, 1500, 350, 98, 100, 1,
   71, 1, 100,   254,254,254,254,254, 254,254,254,254,254,254),
  (43473, 'Summon Bonelord Mk. III', 'skel_pet_47_', 83, 10, 511030, 6, 1, 0, 0, 12000, 6000, 1500, 400, 98, 100, 1,
   71, 1, 100,   254,254,254,254,254, 254,254,254,254,254,254);

-- ---------- 22-25: Grave Bulwark and health-as-a-resource ----------
-- 23-25 are the necromancer.md 9e "option 2" shape: a self-buff that costs HP
-- up front and grants a window. The cost is a POSITIVE-magnitude SPA 0 with a
-- negative base on self, paid once at cast; the window is what follows.
-- ⚠️ There is no stock "cannot cast below X% HP" guard. The doc names one as
-- the safety floor and it does not exist in data - it needs a Lua cast gate or
-- an accepted risk. Flagged, not solved.
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes11,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, effect_limit_value2, formula2, max2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 22. Grave Bulwark - pet heal + pet rune (targettype 14 = pet) =====
  (43483, 'Grave Bulwark Mk. I',   83,  1, 511034, 14, 1, 3, 6, 2000, 12000, 1500, 120, 98, 100, 1,
   0, 60, 21, 400,     55, 100, 0, 102, 500,    254,254,254,254, 254,254,254,254,254,254),
  (43484, 'Grave Bulwark Mk. II',  83,  5, 511034, 14, 1, 3, 6, 2000, 12000, 1500, 120, 98, 100, 1,
   0, 60, 21, 750,     55, 100, 0, 102, 1100,   254,254,254,254, 254,254,254,254,254,254),
  (43485, 'Grave Bulwark Mk. III', 83, 10, 511034, 14, 1, 3, 6, 2000, 12000, 1500, 120, 98, 100, 1,
   0, 60, 21, 1425,    55, 100, 0, 102, 2400,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 23. Blood Pact - HP cost -> spell damage window (SPA 124) =====
  -- SPA 124 is a PERCENTAGE focus, so per the README's scaling contract it is
  -- formula 100 and the percentage itself steps. The HP cost also steps, so the
  -- trade stays a real decision at every tier rather than becoming free.
  (43486, 'Blood Pact Mk. I',   83,  1, 511040, 6, 1, 3, 5, 0, 30000, 1500, 20, 98, 100, 1,
   0, -150, 100, 0,     124, 15, 0, 100, 0,      254,254,254,254, 254,254,254,254,254,254),
  (43487, 'Blood Pact Mk. II',  83,  5, 511040, 6, 1, 3, 5, 0, 30000, 1500, 20, 98, 100, 1,
   0, -400, 100, 0,     124, 25, 0, 100, 0,      254,254,254,254, 254,254,254,254,254,254),
  (43488, 'Blood Pact Mk. III', 83, 10, 511040, 6, 1, 3, 5, 0, 30000, 1500, 20, 98, 100, 1,
   0, -900, 100, 0,     124, 40, 0, 100, 0,      254,254,254,254, 254,254,254,254,254,254),

  -- ===== 24. Dark Covenant - HP -> mana, the Lich engine =====
  -- Instant: pay HP in slot 1, receive mana in slot 2. Both scale on level.
  (43489, 'Dark Covenant Mk. I',   83,  1, 511041, 6, 1, 0, 0, 3000, 12000, 1500, 0, 98, 100, 1,
   0, -8, 6, -120,    15, 6, 0, 102, 100,      254,254,254,254, 254,254,254,254,254,254),
  (43490, 'Dark Covenant Mk. II',  83,  5, 511041, 6, 1, 0, 0, 3000, 12000, 1500, 0, 98, 100, 1,
   0, -8, 6, -220,    15, 7, 0, 102, 200,      254,254,254,254, 254,254,254,254,254,254),
  (43491, 'Dark Covenant Mk. III', 83, 10, 511041, 6, 1, 0, 0, 3000, 12000, 1500, 0, 98, 100, 1,
   0, -8, 6, -398,    15, 8, 0, 102, 380,      254,254,254,254, 254,254,254,254,254,254),

  -- ===== 25. Vampiric Pact - HP cost -> leech-rate window (SPA 178) =====
  -- flat% per the scaling contract. SPA 178 is a melee lifetap; on a caster it
  -- pairs with the Bonelord rather than with his own swings, which is the
  -- intended read - he pays HP to make the pet sustain him.
  (43492, 'Vampiric Pact Mk. I',   83,  1, 511042, 6, 1, 3, 5, 0, 45000, 1500, 30, 98, 100, 1,
   0, -120, 100, 0,     178, 5, 0, 100, 0,       254,254,254,254, 254,254,254,254,254,254),
  (43493, 'Vampiric Pact Mk. II',  83,  5, 511042, 6, 1, 3, 5, 0, 45000, 1500, 30, 98, 100, 1,
   0, -320, 100, 0,     178, 9, 0, 100, 0,       254,254,254,254, 254,254,254,254,254,254),
  (43494, 'Vampiric Pact Mk. III', 83, 10, 511042, 6, 1, 3, 5, 0, 45000, 1500, 30, 98, 100, 1,
   0, -700, 100, 0,     178, 15, 0, 100, 0,      254,254,254,254, 254,254,254,254,254,254);

-- ---------- 26-30: nukes and utility ----------
INSERT INTO spells_new
  (id, name, spell_category, `rank`, spellgroup, targettype, goodEffect, resisttype, ResistDiff,
   buffdurationformula, buffduration, cast_time, recast_time, recovery_time,
   mana, skill, `range`, classes11,
   effectid1, effect_base_value1, formula1, max1,
   effectid2, effect_base_value2, formula2, max2,
   effectid3, effectid4, effectid5, effectid6,
   effectid7, effectid8, effectid9, effectid10, effectid11, effectid12)
VALUES
  -- ===== 26. Siphon Life - lifetap nuke (targettype 13 = ST_Tap) =====
  (43495, 'Siphon Life Mk. I',   83,  1, 511050, 13, 0, 1, -20, 0, 0, 3000, 6000, 1500, 90, 98, 200, 1,
   0, -40, 14, -300,   254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43496, 'Siphon Life Mk. II',  83,  5, 511050, 13, 0, 1, -20, 0, 0, 3000, 6000, 1500, 90, 98, 200, 1,
   0, -40, 14, -560,   254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43497, 'Siphon Life Mk. III', 83, 10, 511050, 13, 0, 1, -20, 0, 0, 3000, 6000, 1500, 90, 98, 200, 1,
   0, -40, 14, -950,   254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 27. Ignite Bones - fast fire DD, the filler =====
  (43498, 'Ignite Bones Mk. I',   83,  1, 511051, 5, 0, 2, -10, 0, 0, 1500, 1500, 1500, 45, 98, 200, 1,
   0, -30, 9, -200,   254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43499, 'Ignite Bones Mk. II',  83,  5, 511051, 5, 0, 2, -10, 0, 0, 1500, 1500, 1500, 45, 98, 200, 1,
   0, -30, 9, -370,   254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43500, 'Ignite Bones Mk. III', 83, 10, 511051, 5, 0, 2, -10, 0, 0, 1500, 1500, 1500, 45, 98, 200, 1,
   0, -30, 9, -615,   254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 28. Screaming Terror - fear, the disengage (SPA 23) =====
  -- flat%: fear is a duration, not a magnitude. Tiers buy duration and a better
  -- resist adjust, not "more fear".
  (43501, 'Screaming Terror Mk. I',   83,  1, 511052, 5, 0, 5,  -50, 1, 4, 2000, 30000, 1500, 70, 98, 200, 1,
   23, 1, 100, 0,       254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43502, 'Screaming Terror Mk. II',  83,  5, 511052, 5, 0, 5, -100, 1, 6, 2000, 27000, 1500, 70, 98, 200, 1,
   23, 1, 100, 0,       254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43503, 'Screaming Terror Mk. III', 83, 10, 511052, 5, 0, 5, -175, 1, 8, 2000, 24000, 1500, 70, 98, 200, 1,
   23, 1, 100, 0,       254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 29. Shroud of Undeath - self buff: mana regen + mitigation =====
  (43504, 'Shroud of Undeath Mk. I',   83,  1, 511053, 6, 1, 0, 0, 5, 0, 3000, 6000, 1500, 100, 98, 100, 1,
   15, 3, 100, 0,       162, 20, 102, 200,   254,254,254,254, 254,254,254,254,254,254),
  (43505, 'Shroud of Undeath Mk. II',  83,  5, 511053, 6, 1, 0, 0, 5, 0, 3000, 6000, 1500, 100, 98, 100, 1,
   15, 6, 100, 0,       162, 20, 102, 420,   254,254,254,254, 254,254,254,254,254,254),
  (43506, 'Shroud of Undeath Mk. III', 83, 10, 511053, 6, 1, 0, 0, 5, 0, 3000, 6000, 1500, 100, 98, 100, 1,
   15, 10, 100, 0,      162, 20, 102, 800,   254,254,254,254, 254,254,254,254,254,254),

  -- ===== 30. Feign Death - the classic escape (SPA 74) =====
  -- flat%: base is the success chance. Tiers buy reliability and recast only.
  (43507, 'Feign Death Mk. I',   83,  1, 511054, 6, 1, 0, 0, 0, 0, 500, 12000, 1500, 25, 98, 100, 1,
   74, 60, 100, 0,      254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43508, 'Feign Death Mk. II',  83,  5, 511054, 6, 1, 0, 0, 0, 0, 500,  9000, 1500, 25, 98, 100, 1,
   74, 80, 100, 0,      254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254),
  (43509, 'Feign Death Mk. III', 83, 10, 511054, 6, 1, 0, 0, 0, 0, 500,  6000, 1500, 25, 98, 100, 1,
   74, 95, 100, 0,      254, 0, 100, 0,   254,254,254,254, 254,254,254,254,254,254);

-- ==============================================================================
-- TEST MATRIX - run after the 0004 gate. Regenerate shared memory first:
--   cd ~/server && ../code/build/bin/shared_memory     (no bin/ symlink exists)
--
--  1. FLAVOURS STACK. Land Venom of Nagafen + Plaguebloom + Ashen Rot on one
--     mob. All THREE must tick simultaneously - three separate buff icons.
--     This is the precondition for the entire deferred combo system, and it is
--     the single most important row in this matrix. If W13 is leaking onto
--     detrimental spells they will overwrite each other instead.
--  2. SAME-FLAVOUR REPLACEMENT. Venom of Nagafen, then Miasma on the same mob:
--     one poison DoT, not two. Same group, and both detrimental, so this is
--     stock value arbitration - NOT W13.
--  3. Mk. III over Mk. I of the same line replaces cleanly.
--  4. Exsanguinate: confirm HP returns to the caster, and whether it returns
--     PER TICK or only once on application. Record which - 14/16/17 are
--     designed against the per-tick assumption.
--  5. Summon Bonelord Mk. I/II/III each summon a visibly stronger skeleton and
--     bind the pet window. Only one Bonelord at a time (stock ONLY_ONE_PET).
--  6. Blood Pact: HP actually drops at cast, and the next nuke hits harder.
--     Confirm SPA 124 applies to DoT ticks or only to direct damage.
--  7. Deny the Reaper: survive a killing blow. EXPECT IT TO FAIL OFTEN - the
--     fire chance is CHA-driven; see the header. Measure the real rate before
--     touching the numbers.
--  8. Feign Death drops aggro and Screaming Terror sends a mob running.
--  9. Dark Covenant converts HP to mana without being castable into death.
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
WHERE id BETWEEN 43420 AND 43539;
