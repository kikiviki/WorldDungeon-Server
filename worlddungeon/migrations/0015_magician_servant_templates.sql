-- 0015_magician_servant_templates
--
-- The four elemental servants' npc_types templates + pets rows. This is the
-- PREREQUISITE flagged in 0014: spells 1-4 carry their identity on the template,
-- not on the player-side spell, so the templates must exist before the summon
-- spells can be authored.
--
-- ID ranges claimed (docs/worlddungeon/F1-ID-RANGES.md):
--   npc_types.id  3,000,001-3,000,043   (the flat overflow band)
--   pets.type     'WD<Element>Mk<N>'
--
-- WHY THE OVERFLOW BAND AND NOT zoneidnumber*1000+n. F1 keeps the zone-band
-- convention for NPCs, but it only makes sense for NPCs that HAVE a zone. A pet
-- is summoned anywhere and belongs to no zone, so there is no correct band to
-- file it under. F1 already anticipated this and reserved 3,000,000+ as the
-- documented escape hatch; global pets are its canonical use. Verified empty
-- (0 rows at or above 3,000,000) before claiming.
--
-- Idempotent: DELETE over the owned ranges, then INSERT.
--
--
-- ===================== MODELLED ON THE STOCK LADDER ==========================
--
-- Stock magician pets at R16 (level 65), read from this database:
--
--   name         race class level   hp   AC  mindmg maxdmg bodytype
--   SumAirR16     75    7    65   5600  287    28    104      24
--   SumFireR16    75   12    65   3060  287    28     63      24
--
-- Every stock elemental is race 75, bodytype 24. THE IDENTITY IS IN `class`:
--   Earth = 1  (Warrior) - most HP/AC, least damage: the durable controller
--   Air   = 7  (Monk)    - fastest, highest damage ceiling
--   Fire  = 12 (Wizard)  - lowest HP, caster chassis
--   Water = 9  (Rogue)   - balanced, support chassis
-- (WD keeps Earth and Air, and replaces Fire and Water - see below.)
--
-- WD reassigns the chassis to match the design in magician.md 9a and the
-- owner's calls, rather than inheriting stock's mapping:
--   Earth = 1  Warrior   - unchanged; most HP/AC, least damage. The ward/snare
--                          controller.
--   Air   = 7  Monk      - fastest chassis. The design calls Air "the caster
--                          servant", but see the casting note below: with no
--                          autonomous casting its lightning/DoT identity is
--                          delivered as PROCS, so a striker chassis fits and the
--                          mana pool a caster class implies would be dead weight.
--   Fire  = 16 Berserker - ALL GAS NO BRAKES. Highest damage of the four and the
--                          lowest AC/HP of the melee three, plus the built-in
--                          damage shield. It kills fast and dies fast, which is
--                          the fire fantasy far better than a squishy caster.
--   Water = 4  Ranger    - deliberately NOT Rogue. A Rogue-chassis pet would
--                          bleed into the Rogue player's backstab fantasy;
--                          Ranger keeps the support/utility read without the
--                          overlap.
--
-- ===================== PETS DO NOT CAST ON THEIR OWN =========================
--
-- Decided: the servants only ever do what they are told. Two columns matter and
-- they are NOT the same thing:
--
--   npc_spells_id         = 0  -> the AI casting list. Zero means the pet NEVER
--                                 decides to cast anything by itself.
--   npc_spells_effects_id      -> ALWAYS-ON PASSIVE effects. No AI decision is
--                                 involved, so this is the right vehicle for the
--                                 Fire damage shield, Water's group heal-on-hit
--                                 and Earth's mitigation ward.
--
-- So each element's identity is delivered through PROCS and PASSIVE EFFECTS,
-- never through autonomous casting. This is a real change to magician.md 9a,
-- which describes Air as "the caster servant" - under this decision there is no
-- caster servant, and Air becomes a lightning-proc striker instead. Worth
-- reflecting back into the vault.
--
-- Tiers track the summon spell's Mk. I/II/III at levels 45 / 55 / 65, with stats
-- interpolated from the stock R13 (45) and R16 (65) rows.
--
-- ⚠️ BOTH SPELL COLUMNS ARE 0 ON EVERY TEMPLATE. The elemental identities do not
-- exist yet: they need npc_spells_effects rows (passive/proc effects) authored
-- against the SPAs in magician.md. These templates are correct CHASSIS with no
-- abilities, so until that lands the four servants differ only in stats and
-- will feel far more alike than the design intends. That is the next step.

DELETE FROM pets      WHERE type LIKE 'WD%Mk%';
DELETE FROM npc_types WHERE id BETWEEN 3000001 AND 3000043;

INSERT INTO npc_types
  (id, name, level, race, class, bodytype, hp, mana, gender, texture, size, runspeed,
   AC, MR, CR, DR, FR, PR, mindmg, maxdmg, attack_count,
   STR, STA, AGI, DEX, _INT, WIS, CHA, npc_spells_id, npc_faction_id, loottable_id, merchant_id)
VALUES
  -- ===== Earth Guardian - Warrior chassis: most HP/AC, least damage =====
  (3000001, 'Earth Guardian',   45, 75, 1, 24, 3400,   0, 2, 0, 5, 1.25, 205, 25, 25, 25,  25, 25, 30,  58, -1, 130,145,110,120,110,110,110, 0,0,0,0),
  (3000002, 'Earth Guardian',   55, 75, 1, 24, 4600,   0, 2, 0, 6, 1.25, 245, 30, 30, 30,  30, 30, 34,  74, -1, 145,160,120,130,120,120,120, 0,0,0,0),
  (3000003, 'Earth Guardian',   65, 75, 1, 24, 6200,   0, 2, 0, 7, 1.25, 287, 35, 35, 35,  35, 35, 38,  92, -1, 160,175,130,140,130,130,130, 0,0,0,0),

  -- ===== Air Servant - Wizard chassis: caster, has mana, lowest HP =====
  (3000011, 'Air Servant',      45, 75, 7, 24, 2100,   0, 2, 0, 5, 1.30, 205, 25, 25, 25,  25, 25, 26,  52, -1, 100,110,130,130,150,120,110, 0,0,0,0),
  (3000012, 'Air Servant',      55, 75, 7, 24, 2800,   0, 2, 0, 6, 1.30, 245, 30, 30, 30,  30, 30, 30,  66, -1, 110,120,140,140,165,130,120, 0,0,0,0),
  (3000013, 'Air Servant',      65, 75, 7, 24, 3700,   0, 2, 0, 7, 1.30, 287, 35, 35, 35,  35, 35, 34,  82, -1, 120,130,150,150,180,140,130, 0,0,0,0),

  -- ===== Fire Servant - Monk chassis: fastest, highest damage, damage shield =====
  (3000021, 'Fire Servant',     45, 75,16, 24, 2000,   0, 2, 0, 5, 1.40, 170, 25, 25, 25, 100, 25, 40,  78, -1, 125,120,145,140,110,110,110, 0,0,0,0),
  (3000022, 'Fire Servant',     55, 75,16, 24, 2700,   0, 2, 0, 6, 1.40, 200, 30, 30, 30, 120, 30, 46, 104, -1, 140,130,155,150,120,120,120, 0,0,0,0),
  (3000023, 'Fire Servant',     65, 75,16, 24, 3500,   0, 2, 0, 7, 1.40, 235, 35, 35, 35, 145, 35, 52, 132, -1, 155,140,165,160,130,130,130, 0,0,0,0),

  -- ===== Water Servant - Rogue chassis: balanced support =====
  (3000031, 'Water Servant',    45, 75, 4, 24, 2400,   0, 2, 0, 5, 1.28, 205, 25,100, 25,  25, 25, 32,  60, -1, 120,125,135,140,115,115,115, 0,0,0,0),
  (3000032, 'Water Servant',    55, 75, 4, 24, 3200,   0, 2, 0, 6, 1.28, 245, 30,120, 30,  30, 30, 36,  78, -1, 130,135,145,150,125,125,125, 0,0,0,0),
  (3000033, 'Water Servant',    65, 75, 4, 24, 4200,   0, 2, 0, 7, 1.28, 287, 35,145, 35,  35, 35, 40,  96, -1, 140,145,155,160,135,135,135, 0,0,0,0);

-- pets rows: the `type` string is what SPA 33 on the summon spell references.
-- petcontrol 2 = fully commandable (matches stock SumAirR*), petnaming 3 =
-- "<Owner>`s pet" naming, temp 0 = permanent.
INSERT INTO pets (type, petpower, npcID, temp, petcontrol, petnaming, monsterflag, equipmentset)
VALUES
  ('WDEarthMkI',   0, 3000001, 0, 2, 3, 0, -1),
  ('WDEarthMkII',  0, 3000002, 0, 2, 3, 0, -1),
  ('WDEarthMkIII', 0, 3000003, 0, 2, 3, 0, -1),
  ('WDAirMkI',     0, 3000011, 0, 2, 3, 0, -1),
  ('WDAirMkII',    0, 3000012, 0, 2, 3, 0, -1),
  ('WDAirMkIII',   0, 3000013, 0, 2, 3, 0, -1),
  ('WDFireMkI',    0, 3000021, 0, 2, 3, 0, -1),
  ('WDFireMkII',   0, 3000022, 0, 2, 3, 0, -1),
  ('WDFireMkIII',  0, 3000023, 0, 2, 3, 0, -1),
  ('WDWaterMkI',   0, 3000031, 0, 2, 3, 0, -1),
  ('WDWaterMkII',  0, 3000032, 0, 2, 3, 0, -1),
  ('WDWaterMkIII', 0, 3000033, 0, 2, 3, 0, -1);

-- Next: npc_spells lists giving each element its identity procs, then the
-- summon spells 1-4 (SPA 33 pointing at these `type` strings, plus SPA 167
-- pet power rising per tier).
