# Magician — Spell Design

**Class id 13 · band 43,660–43,779 · spellgroups 513,000+**

Source: vault `04 Class Identities/Magician.md` §9a–§9g and §14. Native specialty: **true pet
mastery — pet-spell tier upgrades, summoned pet gear, elemental identities**, tier advantage **+2**.

**He is almost entirely data-driven** — the pet-master fantasy maps onto stock EQEmu pet systems
better than any other class's identity maps onto anything.

Per **E10**, Monster Summoning is **cut** — four elementals only. That also tightens the familiar
pairing matrix from 5×4 to 4×4.

---

## 1. The two exclusives, stated once

**The pet-tier ladder is his alone.** Enforced by simply not giving other classes ranks 6–10 of
their pet lines — under **D2** that's automatic: other pet classes cap at 5 unless they
specialize, and even then their line tops out lower. No new mechanism.

**Summoned pet gear is auto-applied by summon tier**, not cast as separate spells onto the pet.
`pets_equipmentset` is the native mechanism: a pet template references an equipment set, and the
set carries weapons with procs. Reasons for auto-apply: it's native (no code), it removes a
tedious re-gearing chore on every summon, and it keeps the *Conjurer* path meaningful by having
it raise the **equipment-set tier** rather than hand out buttons.

Separately-cast summons (mod rods, player-usable items) **stay** as real spells — that's the
Conjurer flavour that should remain interactive.

**Pet-weapon procs use a separate pool** from the §2.3 player proc-gem pool. Pet procs tied to
the elemental identity read better and avoid a balance coupling between player gear and pet
output.

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a/§9d — Pet summons: four elementals (4)

Each rank points at a stronger `npc_types` template and carries a higher **SPA 167** pet-power
value. Each identity is **procs on the `npc_types` template**, not player-side spells.

| # | base | Spell | Element | Self-procs / identity | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 1 ⭐ | 43,660 | **Summon Earth Guardian** | Earth | % damage-reduction ward, **snare**, damage reflect ⚠️ — the durable controller | **33**, **167**; template: **162**, **3** | max↑ | — |
| 2 | 43,663 | **Summon Air Servant** | Air | lightning strikes, suffocate DoTs — the caster servant | **33**, **167**; template: 0 | max↑ | — |
| 3 | 43,666 | **Summon Fire Servant** | Fire | built-in **damage shield** — the retaliator | **33**, **167**; template: **59** | max↑ | — |
| 4 | 43,669 | **Summon Water Servant** | Water | group heal-on-hit, rain procs — the support servant | **33**, **167**; template: proc → 0 | max↑ | — |

> ⭐ **The signature moment:** a fully kitted, Mk. III elemental in its element-specific identity
> wrecking a pack essentially on its own.

**The Mk. I/II/III tiering here is the pet-tier ladder** — Mk. III is the top of the exclusive
ladder no other class reaches.

### §9c — Pet focus modes (4)

A pet-targeted buff in **one spellgroup** — native overwrite gives one-focus-at-a-time free.
Swap cost is free; it's a recast on the pet, and nobody spams a posture.

| # | base | Spell | Focus | Composition | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 5 | 43,672 | **Servant's Fury** | single-target damage | **185** damage ↑ | flat% | — |
| 6 | 43,675 | **Servant's Sweep** | AoE damage | **211** AEMelee ⚠️ / rampage-style | flat% | — |
| 7 | 43,678 | **Servant's Bulwark** | survival | **162** mitigation ↑, **215** pet avoidance ⚠️ | flat% | — |
| 8 | 43,681 | **Servant's Provocation** | AoE taunt | **206** AETaunt on the pet | flat% | — |

Elemental identity **combines with** focus mode: Earth + survival is the maximal off-tank; Air +
AoE is the pack DoT engine. That product is the class's adaptability claim.

### §9e — Pet heals, wards, auras (5)

Pet heals are the mage's *primary* healing — directed at the servant, not himself.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 9 | 43,684 | **Mend Servant** | pet heal, fast | 0 | max↑ | — |
| 10 | 43,687 | **Reforge Servant** | pet heal, large, cast time | 0 | max↑ | — |
| 11 | 43,690 | **Servant's Aegis** | pet ward — absorb shield for spike protection | **210** ⚠️ / **55** | max↑ | ⚠️ |
| 12 | 43,693 | **Elemental Anchor** | **pet-anchored aura** — allies within X of the pet gain damage/HP/regen | ⚠️ non-caster anchor | max↑ | ⚠️ |
| 13 | 43,696 | **Elemental Beacon** | second aura flavour — mana regen and spell damage | ⚠️ | max↑ | ⚠️ |

12/13 are the uncertain ones: *an aura centred on an entity that isn't the caster.*
**Recommend projecting from the pet** — it makes pet positioning matter, which is the class
fantasy, and it differentiates cleanly from Bard auras (which centre on the bard and are
party-only per E4). ⚠️ Verify the aura system supports a non-caster anchor; if not, a **periodic
pet-centred pulse buff** is a workable substitute, the same shape as the Paladin's pulsing absorb.

### §9g — Familiars and the pairing matrix (4)

**SPA 108 is natively single-instance**, so **E1's** one-at-a-time rule is free. Per **E1**
familiars swap **mid-fight** at the cost of mana and cast time, which makes the pairing a **live
tactical layer** rather than a loadout choice — a better version of the mechanic.

The familiar's bonus **changes based on which elemental is currently out.**

| # | base | Spell | Matched (same element) | Graft (different element) | Dep. |
|---|---|---|---|---|---|
| 14 | 43,699 | **Earthen Familiar** | deepen the damage-reduction ward | adds mitigation/snare rider to another pet | ⚠️ |
| 15 | 43,702 | **Zephyr Familiar** | extra lightning/DoT procs | adds lightning-on-hit to a non-Air pet | ⚠️ |
| 16 | 43,705 | **Ember Familiar** | second/stronger damage shield | adds a retaliation DS to a non-Fire pet | ⚠️ |
| 17 | 43,708 | **Tidal Familiar** | bigger group-heal-on-hit / rain procs | adds a group-heal trickle to a non-Water pet | ⚠️ |

**Implementation:** the familiar buff carries multiple conditional riders, each gated by a **Limit
checking the active pet's element** ⚠️. If Limits can't read pet state, fall back to
re-evaluating and re-applying the familiar buff on a pet summon/death hook — slightly more code,
entirely reliable.

**Per C11 ship 8 of the 16 cells:** the 4 matched pairs plus ~4 marquee grafts. Recommended
grafts: Water familiar + Earth pet (durable tank that trickles group heals), Air familiar + Fire
pet (retaliator that lands lightning procs), Earth familiar + Water pet (support servant that
survives), Fire familiar + Air pet (caster servant with a retaliation layer).

### §9f — Bolt and rain (5)

Personal damage supplements the pet; the pet is still the main engine.

| # | base | Spell | Shape | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 18 | 43,711 | **Emberbolt** | ST bolt — direct burst | 0 (bolt) | max↑ | — |
| 19 | 43,714 | **Shardbolt** | ST bolt — second element | 0 (bolt) | max↑ | — |
| 20 | 43,717 | **Rain of Cinders** | ground-target rain, fire | 0 (AE) | max↑ | — |
| 21 | 43,720 | **Rain of Shards** | ground-target rain, second element | 0 (AE) | max↑ | — |
| 22 | 43,723 | **Elemental Barrage** | rapid low-damage bolt volley — the filler | 0 | max↑ | — |

Rain overlaps with the Air and Water pets' own rain procs, which is the intended *Firebrand*
synergy for pack clears.

### §9b — Conjuration: the interactive summons (5)

The Conjurer flavour that deliberately stays as real spells.

| # | base | Spell | Summons | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 23 | 43,726 | **Summon Modulation Rod** | a clickable mana-return item for an ally | **32** | max↑ | — |
| 24 | 43,729 | **Summon Ration** | food/drink — the classic utility | **32** | — | — |
| 25 | 43,732 | **Summon Bandolier** | a temporary weapon for a *player* ally | **32** | max↑ | — |
| 26 | 43,735 | **Summon Wardstone** | a clickable absorb item, charges | **32** | max↑ | — |
| 27 | 43,738 | **Summon Reagent Cache** | consumables the group actually needs | **32** | — | — |

### Self-preservation (3)

He's cloth and his survivability leans on the pet. These are the three things that keep him alive
when the pet isn't there — which vault §13 flags as a real solo-first concern under D1.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 28 | 43,741 | **Elemental Skin** | self damage shield — the long, low, set-and-forget kind | **59** | max↑ | — |
| 29 | 43,744 | **Emergency Conjuration** | instant, high-cost re-summon at reduced pet HP | **33** | max↑ | — |
| 30 | 43,747 | **Elemental Shielding** | self mitigation + AC buff | **162**, **1** | max↑ | — |

29 exists specifically to answer §13's **pet-death recovery** question: a mage whose pet dies
mid-frontier-pull has lost his damage *and* his tank. An expensive instant re-summon at reduced
pet HP is the recovery valve.

**Note his DS (28) is deliberately the opposite of the Druid's** — long-term, lower-scaling, few
riders, recast rarely. Set and forget. The Druid's is short, high, reactive and rider-laden. Two
DS classes, two feels.

---

## 3. Payload spells — 43,750–43,779

| id | Payload | Parent |
|---|---|---|
| 43,750 | Earth pet self-proc: damage-reduction ward | 1 |
| 43,751 | Earth pet self-proc: snare | 1 |
| 43,752 | Air pet self-proc: lightning strike | 2 |
| 43,753 | Air pet self-proc: suffocate DoT | 2 |
| 43,754 | Fire pet damage shield | 3 |
| 43,755 | Water pet group heal-on-hit | 4 |
| 43,756–43,759 | familiar matched riders | 14–17 |
| 43,760–43,763 | familiar graft riders (the 4 marquee cells) | 14–17 |
| 43,764 | pet aura pulse — damage/HP/regen | 12 |
| 43,765 | pet aura pulse — mana/spell damage | 13 |
| 43,766–43,779 | *unallocated* | |

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 513,001–513,004 | pet summon ladders (one per element) |
| **513,010** | `mag_pet_focus` — **all four focus modes share it** (native overwrite = one at a time) |
| 513,020–513,024 | pet heals, wards, auras |
| 513,030–513,033 | familiars |
| 513,040–513,044 | bolt and rain lines |
| 513,050–513,054 | conjuration lines |
| 513,060–513,062 | self-preservation lines |

---

## 5. Build order

Per vault §14h:

1. **Pet ladder + equipment sets + elemental templates (1–4)** — all data, and it is most of the
   class.
2. **Focus modes, pet heals, bolt/rain, conjuration (5–11, 18–27)** — data-only.
3. **Familiar pairing (14–17)** — verify the Limit-reads-pet-state question; fall back to the
   re-apply hook if needed.
4. **Pet-anchored auras (12–13)** last — most uncertain.

---

## 6. Open items

- [ ] **Can a Limit or focus read the caster's active pet type?** *(Decides whether the familiar
      pairing is data-only.)*
- [ ] Whether **auras support a non-caster anchor entity**.
- [ ] **SPA 210 pet shield / SPA 215 pet avoidance** numbers and behaviour.
- [ ] **`pets_equipmentset`** — can proc-carrying weapons be assigned per set, and do pet procs
      scale with the set tier?
- [ ] **SPA 211 AEMelee** for the AoE focus mode.
- [ ] **Pet-death recovery** — re-summon speed and cost. A real solo-first concern under D1;
      spell 29 is the proposed answer but its numbers are unset.
- [ ] Elemental self-proc magnitudes and proc rates per identity.
- [ ] Which 4 grafts ship (recommendation above is a starting set, not a decision).
