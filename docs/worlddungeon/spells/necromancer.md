# Necromancer — Spell Design

**Class id 11 · band 43,420–43,539 · spellgroups 511,000+**

Source: vault `04 Class Identities/Necromancer.md` §9a–§9e and §14. Native specialty: **master of
death — DoT-flavour combos, corpse-raised minions, life manipulation**, tier advantage **+2**.

He is the **cleanest fit to stock EQEmu of the caster classes** — most of his identity is native
spell mechanics, and his two real custom asks (curse-raise, life ward) both share code with other
classes.

Where the Druid *spreads* rot, the Necromancer **stacks and compounds** it. Necro DoTs are
explicitly **non-spreading**.

---

## 1. The combo system

**Flavours = `resisttype`.** Poison, disease and fire are already distinct resist types with
distinct counter SPAs (**35** disease, **36** poison, **116** curse), so "three flavours active"
is **natively queryable — no new state needed.**

The combo bonus is a detonation-family state check. Two options existed:

- **(a) bonus raw damage** — requires modifying each DoT's tick, i.e. C++ in the DoT tick path.
  **Avoid.**
- **(b) secondary synergy DoT** ✅ — when a DoT lands, a SPA 374 trigger checks for the other
  flavours via Limit SPAs and applies a separate **Synergy DoT** spell.

**(b) at all tiers**, not a per-tier split. One mechanism, it's purely data-driven, and the player
can *see* the combo landed as its own buff icon. The bonus scales by having a Mk. II and Mk. III
synergy spell.

Attach **Limit SPAs (134–147)** to every DoT focus so DoT-damage AAs don't leak into his nukes or
leech returns.

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a — Flavour DoTs and the combo (8)

| # | base | Spell | Flavour | Role | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 1 | 43,420 | **Venom of Nagafen** | poison | the poison line | max↑ | — |
| 2 | 43,423 | **Plaguebloom** | disease | the disease line | max↑ | — |
| 3 | 43,426 | **Ashen Rot** | fire | the fire line | max↑ | — |
| 4 | 43,429 | **Synergy: Duality** | — | 2-flavour combo payload | max↑ | **W1** |
| 5 ⭐ | 43,432 | **Synergy: Trinity** | — | 3-flavour combo payload | max↑ | **W1** |
| 6 | 43,435 | **Miasma** | poison, **AE** | establish flavour across a pack | max↑ | — |
| 7 | 43,438 | **Pall of Contagion** | disease, **AE** | establish flavour across a pack | max↑ | — |
| 8 | 43,441 | **Cinderblight** | fire, **AE** | establish flavour across a pack | max↑ | — |

> ⭐ **The signature moment:** three DoT flavours ticking at once erupting into the full combo
> bonus, while curse-raised minions peel off the dying pack. **Spell 5 is the mechanical
> expression of it.**

Per-flavour spellgroups (`nec_dot_poison` / `_disease` / `_fire`) with the AE version **in the
same group as its single-target counterpart**, so the combo Limit matches either.

### Reap — the detonator (2)

Standard P3.1 detonator, approved as **C4**. Delivered as a **spell on a recast timer, not an
AA** — it should compete for a gem slot.

| # | base | Spell | Effect | Scaling | Dep. |
|---|---|---|---|---|---|
| 9 | 43,444 | **Reap** | 374 trigger reading each flavour spellgroup; damage scales by **flavour count**; **strips all flavour DoTs** on success | max↑ | **W1** |
| 10 | 43,447 | **Harvest** | AE Reap — resolves across every target carrying ≥2 flavours | max↑ | **W1** |

Reap yields ~85–90% of remaining tick damage per A2. Because its damage scales by flavour count
it **inherits the combo tier automatically** — 1 flavour is weak, 3 is the payoff. That is why
Reap reinforces the combo system rather than bypassing it.

### §9b — Life ward (3)

**W5 (threshold trigger)**, sharing a hook site with the Paladin/SK accumulator work — P3.2 and
P3.4 are the same `Mob::CommonDamage()` site. **Build together.**

A dormant buff sits on the bar doing nothing. Post-damage HP check: if HP crosses the threshold %
and the dormant buff is present → fire payload via SPA 374 → start internal cooldown.

**Payload = two effects in one spell:** SPA 0 instant heal + SPA 124 spell-damage buff — the
"near-death becomes a damage window" beat.

| # | base | Spell | Threshold | Payload | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 11 | 43,450 | **Dying Breath** | ~35% | heal + spell-damage window | max↑ | **W5** |
| 12 | 43,453 | **Deathless Vigil** | ~20%, larger payload, longer CD | heal + larger window | max↑ | **W5** |
| 13 | 43,456 | **Deny the Reaper** | on **lethal** damage rather than a threshold | **150** DeathSave — stock | max↑ | — |

13 is the stock analog and worth authoring first: **SPA 150 Death Save fires on lethal damage —
same code path, different predicate.** Read it before writing W5; if Death Save's hook is
well-placed the threshold variant is a small addition.

**Re-arms automatically on cooldown, not by recast.** It's his signature death-defiance and making
him re-mem it under pressure fights the fantasy. Damage-buff duration fixed; magnitude scales.

### §9c — Life-leech DoTs (4)

Standard DoT plus heal recourse. The interesting part is the **split across self / group / pets**,
which under **D1/W2** is exactly the ally-target expansion rule — his minions and Beefy Boy are
valid targets at the reduced swarm weight.

| # | base | Spell | Shape | Scaling | Dep. |
|---|---|---|---|---|---|
| 14 | 43,459 | **Leeching Rot** | ST DoT, trickle return to self + group + pets | max↑ | W2 |
| 15 | 43,462 | **Exsanguinate** | ST DoT, higher leech, no group share | max↑ | — |
| 16 | 43,465 | **Communal Drain** | **AE** DoT, trickle return | max↑ | W2 |
| 17 | 43,468 | **Bloodlink** | buff — routes a % of *all* his DoT damage as leech for a window | flat% | W2 |

**Pets count at the reduced (50%) weight, and the split is proportional, not equal** — so six
minions don't starve the necro of his own leech.

### §9d — Pets: two systems, deliberately different SPAs (5)

> The Beefy Boy and the minions are **not the same mechanic** and shouldn't share code.

**Big Beefy Boy — SPA 33.** Standard commanded pet, binds the pet window, `pets` table entry,
scaled by SPA **167**. Entirely stock.

**Curse-raised minions — SPA 152 (temporary pets).** The custom part is the *trigger*: the curse
DoT carries a flag; on the cursed enemy's **death**, roll `raise%` → summon a swarm pet. Model and
tier picked by curse rank and victim level, using existing generic models (skeleton / brown
skeleton / zombie / ghost / spectre) — **no new art.**

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 18 | 43,471 | **Summon Bonelord** | the Big Beefy Boy — commanded, pet window | **33**, **167** | max↑ | — |
| 19 | 43,474 | **Malediction** | curse DoT — on victim's death, % chance to raise a minion | **116**, **152** + on-death | max↑ | **W7** |
| 20 | 43,477 | **Mass Malediction** | AE curse — the pack-into-army spell | **116**, **152** | max↑ | **W7** |
| 21 | 43,480 | **Bind the Risen** | extends minion duration and raises the standing cap | **128** | max↑ | **W7** |
| 22 | 43,483 | **Grave Bulwark** | pet heal + pet rune | 0, **55** | max↑ | — |

Minions **auto-assist and work down the xtarget list** while enemies remain — no manual command.
That autonomy is exactly what SPA 152 swarm AI already does; **the extension needed is target
inheritance, not the autonomy itself** (W7).

⚠️ **Verify SPA 152's cap enforces a *standing* cap across multiple casts**, not per-cast.
⚠️ **Verify a "killed while debuffed by caster X" hook exists** — **shared with the Wizard's black
hole.** If the DoT's caster is tracked through death this is nearly free.

### §9e — Health as a resource (3)

**The one genuinely awkward piece.** EQ spells cost mana; there is **no stock HP-cost field** on
`spells_new`.

**Option 2 is recommended**: a short self-buff that costs HP and applies SPA 124 spell damage; the
next nuke benefits. Fully data-only, and it reads well — **a visible buff icon is a visible cost.**
The safety floor becomes a simple "can't cast below X% HP" check on the buff.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 23 | 43,486 | **Blood Pact** | self-damage cost → spell-damage window | 0 self, **124** | flat% | — |
| 24 | 43,489 | **Dark Covenant** | HP → mana conversion (the Lich engine) | 0 self, **15** | max↑ | — |
| 25 | 43,492 | **Vampiric Pact** | HP cost → leech-rate window | 0 self, **178**-adjacent | flat% | — |

### Nukes and utility (5)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 26 | 43,495 | **Siphon Life** | ST lifetap nuke — damage + self heal | 0 dual-component | max↑ | — |
| 27 | 43,498 | **Ignite Bones** | fast fire DD — the filler | 0 | max↑ | — |
| 28 | 43,501 | **Screaming Terror** | fear — the Necro's disengage | **23** | flat% | — |
| 29 | 43,504 | **Shroud of Undeath** | self buff — mana regen + undead-flavour mitigation | 0 (duration), **162** | max↑ | — |
| 30 | 43,507 | **Feign Death** | self — the classic escape | feign | — | — |

---

## 3. Payload spells — 43,510–43,539

| id | Payload | Parent |
|---|---|---|
| 43,510–43,512 | Synergy: Duality Mk. I/II/III | 4 |
| 43,513–43,515 | Synergy: Trinity Mk. I/II/III | 5 |
| 43,516 | Reap detonation damage | 9, 10 |
| 43,517 | Life ward payload — heal + damage window | 11, 12 |
| 43,518 | Leech recourse — self/group/pet split | 14, 16, 17 |
| 43,519 | Curse-raise minion summon | 19, 20 |
| 43,520–43,539 | *unallocated* | |

Note 43,510–43,515 are the exception to the one-payload-per-line rule: the synergy DoTs are
**tiered**, because the combo bonus is what scales.

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| **511,001** | `nec_dot_poison` — **spells 1 and 6 both** |
| **511,002** | `nec_dot_disease` — **spells 2 and 7 both** |
| **511,003** | `nec_dot_fire` — **spells 3 and 8 both** |
| 511,004–511,005 | synergy DoT lines |
| 511,006–511,007 | Reap, Harvest |
| 511,010–511,012 | life ward lines |
| 511,020–511,023 | leech lines |
| 511,030–511,034 | pet and minion lines |
| 511,040–511,042 | HP-as-resource lines |
| 511,050–511,054 | nukes and utility |

The shared flavour groups at 511,001–511,003 are load-bearing — Reap's and the synergy triggers'
Limits name them, so the AE and single-target versions of a flavour must share a group.

---

## 5. Build order

> [!warning] **Corrected while authoring migration `0009`.** Step 1 below said spells 1–10 need
> "no code beyond W1". **That is wrong for 4, 5, 9 and 10.** W1 as built tests *one* spellgroup
> and returns a boolean — see `Mob::PassCastRestriction`. The synergy DoTs need "target has 2 of
> these 3 groups" and Reap needs a flavour **count** plus strip-on-detonate, which no stock SPA
> provides. `DETONATION-PATTERN.md` §4 already flagged both ("AND of two flags", "strip-on-
> detonate… decide before the Necro's Reap copies it — Reap *requires* consumption").
> **The class's marquee ability is engine-blocked, not data-only.**

Revised:

1. ✅ **Flavour DoTs 1–3 and 6–8** — done, migration `0009`. The combo *flags* are data-only even
   though the combo is not, so the class has a working damage rotation today.
2. ✅ **Beefy Boy (18), Exsanguinate (15), Deny the Reaper (13), Grave Bulwark (22),
   HP-as-resource (23–25), nukes and utility (26–30)** — done, migration `0009`.
3. 🔴 **W1 extension, then synergy DoTs + Reap (4, 5, 9, 10)** — the marquee. Needs a
   multi-group predicate and a consumption mechanism. **This is now the class's critical path**,
   and it is shared with the Wizard's deferred Thermal Shock and Cascade.
4. **W5 life ward (11–12)** with the Paladin/SK accumulator package. SPA 150 is already read —
   see `0009`'s Deny the Reaper notes, including the charisma problem.
5. **W2 leech split (14, 16, 17)** — 15 already ships because it has no group share.
6. **W7 swarm AI**, then the **curse-raise trigger (19–20)** last.

---

## 6. Open items

- [x] ~~Whether Limit SPAs can test for a spellgroup on the *target*~~ — **yes, via W1**
      (`IS_TARGET_HAS_WD_SPELLGROUP`), built. But **one group per 442 slot**, boolean, which is
      what blocks 4/5/9/10. See §5.
- [ ] **W1 multi-group predicate** — "target carries ≥ K of groups G₁…Gₙ". Gates 4, 5, 9, 10.
      A data-only alternative exists and should be weighed first: **chained riders**, where a
      rider's 442 payload is *another rider* testing the next group, giving an AND with no engine
      change. Cost is latency — each link resolves on a later damage/cast event, so Trinity could
      take 2–3 ticks to pay off, which may or may not read as sluggish.
- [ ] **Strip-on-detonate for Reap.** Reap must consume the flavour DoTs; no stock SPA removes a
      buff by spellgroup. Shared with the Wizard's lure strip.
- [ ] **SPA 150 fire chance is charisma-driven** — `(CHA * 3 + 1) / 10`, capped 95
      (`zone/spell_effects.cpp:7204`). CHA is a Necromancer dump stat, so Deny the Reaper fires
      ~20–25% of the time. Rule override, CHA-independent variant, or accept.
- [ ] **No stock "cannot cast below X% HP" guard** for the §9e HP-cost spells. The safety floor
      the design assumes does not exist in data.
- [ ] **Does a duration lifetap return HP per tick or only on application?** 14/16/17 are designed
      against the per-tick assumption. In `0009`'s test matrix.
- [ ] **SPA 152 standing-cap behaviour** across multiple casts.
- [ ] Whether a **"killed while debuffed by caster X"** hook exists on the NPC death path —
      shared with the Wizard.
- [ ] Whether swarm pets can **inherit a target list** (W7) or need AI extension.
- [ ] Confirm counter SPAs (35/36/116) don't create unintended cure interactions with the
      **Cleric's Prexus cleanse** — flagged in both docs.
- [ ] Curse-raise % chance, minion model/tier scaling rule, duration, standing cap Y.
- [ ] Life ward threshold %, internal cooldown, damage-boost magnitude.
- [ ] Leech split across self / group / pets; trickle rate.
- [ ] Whether more DoT flavours ship later than poison/disease/fire.
