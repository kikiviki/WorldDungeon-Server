# Enchanter — Spell Design

**Class id 14 · band 43,780–43,899 · spellgroups 514,000+**

Source: vault `04 Class Identities/Enchanter.md` §9a–§9e and §14. Native specialty:
**dopplegangers, mana rip, crowd control**, tier advantage **+2**.

Per **E7** the class was substantially reworked. **New identity line: *"Tank through making
copies; damage while restoring mana to self and party."*** Mez is demoted from headline strength —
the lines stay, the pitch changes. The charm line is **cut**.

---

## 1. The doppleganger rework, stated once

Copies are **SPA 152 swarm pets** created carrying a **snapshot of the enchanter's
currently-memmed spells**:

1. On summon, read the enchanter's memmed gems.
2. **Filter through an allow-list by spell category** — an allow-list, *not* a block-list. A
   block-list leaks the moment a new spell is added; an allow-list fails safe.
3. Assign the filtered set as the swarm NPC's spell list.
4. Standard swarm AI casts from it.

**Allow-list:** direct damage, DoTs, mana rip, resist and melee debuffs.
**Excluded:** Gate, Bind Affinity, teleports, summon corpse, invis/illusion, anything
self-targeting, anything with a reagent, and **mez**.

**Mez exclusion is a correctness issue, not a balance one** — copies casting mez would break
their own mez and each other's.

**Why this beats the old "~1 tier below chaos proc":** the copies stop being a downtuned proc and
become *him*. Power comes from **spell access** rather than a damage multiplier, so his damage
scales with his own spell tiers automatically and needs no separate balance pass.

**Copies inherit spell-damage stats but not AA crit/potency** — otherwise copy count multiplies
his entire gear profile and the class becomes unboundable.

This whole system is **W7**, and it is gated on one question: *can a swarm pet be assigned a
runtime-generated spell list?* **Check that before anything else in this doc.**

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a — Dopplegangers (5)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 1 ⭐ | 43,780 | **Doppleganger** | summons copies carrying a filtered spellbar snapshot | **152** + spell-list assignment | max↑ | **W7** |
| 2 | 43,783 | **Legion of Self** | fewer, stronger copies — the burst variant | **152** | max↑ | **W7** |
| 3 | 43,786 | **Fractured Reflection** | more, weaker copies — the aggro-soak variant | **152** | max↑ | **W7** |
| 4 | 43,789 | **Shared Fate** | the **per-copy survival buff** — stacks with live copy count | **1**, **162**, **172** | flat% | ⚠️ W7 |
| 5 | 43,792 | **Persistence of Self** | extends copy duration and raises the standing cap | **128**, **398** | max↑ | **W7** |

> ⭐ **The signature moment:** popping a full set of dopplegangers that grab the pack, buff his
> survival, and open the chaos rotation.

**Spell 4 is his tanking**, and it is the ⚠️ piece: it needs a **count-driven buff** whose stack
tracks how many copies are currently alive — incrementing on summon and **decrementing on copy
death.** Hook the swarm-pet death path to refresh the owner's stack. Small, and it shares the W7
work.

> **A hard cap on both copy count and per-copy magnitude is required, not optional.** This is his
> primary defence and it compounds with copy count.

⚠️ Swarm AI should **inherit the owner's current target and not acquire independently** — that
keeps copies off mezzed adds. Without it copies will break mez by attacking mezzed mobs.

### §9b/§9e — Mana rip → chaos detonation (7)

Per **D3/P3.1**, joining the server's core combat verb. This is his kill mechanic and it is
data-only.

1. **Mana rip** — SPA 15 drain, **now also dealing damage** (SPA 0 rider), plus a
   casting-reduction debuff.
2. It leaves a **mana-rip debuff** on the target.
3. **Chaos damage detonates it** — SPA 374 trigger with a Limit checking the mana-rip spellgroup,
   stripping it on success.
4. **Transfer** — ripped mana to self and group; under D1/W2 the group side reaches pets and
   temp-allies, which is what makes the mana-battery identity work solo.

| # | base | Spell | Cadence | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 6 | 43,795 | **Mind Flay** | immediate | mana drain + damage + casting debuff | **15**, 0, **112** neg | max↑ | — |
| 7 | 43,798 | **Slow Bleed of Thought** | over time | sustained mana drain + damage | **15**, 0 | max↑ | — |
| 8 | 43,801 | **Mind Flay: Mass** | immediate, **AE** | pack-wide rip — sets up AE chaos | **15**, 0 | max↑ | — |
| 9 | 43,804 | **Chaos Bolt** | — | **detonates** the rip debuff, strips it | 0 + **374** | max↑ | **W1** |
| 10 | 43,807 | **Chaos Storm** | AE | AE detonation across every ripped target | 0 (AE) + **374** | max↑ | **W1** |
| 11 | 43,810 | **Chaotic Whisper** | — | fast filler chaos, no detonation | 0 | max↑ | — |
| 12 | 43,813 | **Communal Reservoir** | — | transfers banked ripped mana to self and group | **15** + recourse | max↑ | W2 |

**Chaos resist behaviour: lowest-resist check, not fully resist-agnostic.** Truly unresistable
damage is a balance hazard and undercuts the resist system entirely. A lowest-resist check
delivers the "reliably lands" fantasy *and* still interacts with his own magic-resist debuff — so
shredding resists still improves his damage, which is a nice internal synergy.

⚠️ Verify whether ROF2 EQEmu has a chromatic / lowest-resist `resisttype`; if not, this is a small
addition to the resist calc.

### §9c — Crowd control (6)

All stock, all data-only. Demoted from headline per E7 — the lines stay in full.

| # | base | Spell | Shape | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 13 | 43,816 | **Enthrall** | ST mez | **31** | max↑ | — |
| 14 | 43,819 | **Enveloping Sleep** | AE mez, target cap | **31** (AE) | max↑ | — |
| 15 | 43,822 | **Lull** | pacify — pull-splitting | **31**-adjacent | max↑ | — |
| 16 | 43,825 | **Whirl of Confusion** | AE stun | **21** (AE) | max↑ | — |
| 17 | 43,828 | **Vertigo** | ST spin/disorient | **64** SpinTarget | flat% | — |
| 18 | 43,831 | **Fetter** | root | root | flat% | — |

⚠️ Mez duration, AoE target cap and break rules are all unset. The doppleganger-vs-mez conflict is
resolved structurally by excluding mez from the copy allow-list (§1) plus target inheritance.

### §9d — Debuffs (5)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 19 | 43,834 | **Cripple** | melee slow — the big one | **11** neg | flat% | — |
| 20 | 43,837 | **Tashan** | magic resist shred — **force-multiplies the whole party's damage** | MR debuff | max↑ | — |
| 21 | 43,840 | **Malaise** | multi-resist shred, smaller per-resist | resist debuffs | max↑ | — |
| 22 | 43,843 | **Silence of the Mind** | casting reduction — fizzle and effective level down | **112** neg ⚠️ | flat% | ⚠️ |
| 23 | 43,846 | **Mass Cripple** | AE melee slow | **11** neg (AE) | flat% | — |

20 is his best cross-class contribution and pairs directly with his own chaos damage under the
lowest-resist rule.

### §9d — Casting buffs (5)

Self and group, reaching pets and temp-allies under W2.

| # | base | Spell | Grants | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 24 | 43,849 | **Clarity** | mana regen — the classic | mana regen | max↑ | W2 |
| 25 | 43,852 | **Focus of the Adept** | **effective casting level** ↑ | **112** | max↑ | W2 |
| 26 | 43,855 | **Steady Hand** | fizzle-rate reduction | fizzle ⚠️ | flat% | W2 |
| 27 | 43,858 | **Alacrity** | melee haste for the group | **11**/**98** | flat% | W2 |
| 28 | 43,861 | **Rune of the Mind** | self spell-absorb rune — the between-copies gap-filler | **78** | max↑ | — |

28 exists because his survivability is **conditional** on copies being up; between summons he's a
cloth caster with nothing. One self-rune is the honest answer to that weakness without erasing it.

### Utility (2)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 29 | 43,864 | **Illusion: Self** | illusion suite — cosmetic plus faction/utility riders | illusion | — | — |
| 30 | 43,867 | **Gift of Insight** | group buff — spell crit chance | **170** | flat% | W2 |

---

## 3. Payload spells — 43,870–43,899

| id | Payload | Parent |
|---|---|---|
| 43,870 | Chaos Bolt detonation damage | 9 |
| 43,871 | Chaos Storm AE detonation damage | 10 |
| 43,872 | Mana transfer recourse — self and group | 6–8, 12 |
| 43,873 | Per-copy survival stack buff | 4 |
| 43,874–43,899 | *unallocated* | |

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 514,001–514,003 | doppleganger summon lines |
| 514,004 | `enc_copy_survival` |
| 514,005 | copy duration extension |
| **514,010** | `enc_manarip` — **spells 6, 7 and 8 all share it**; the chaos detonators' Limits name it |
| 514,011–514,013 | chaos damage lines |
| 514,020–514,025 | mez and control lines |
| 514,030–514,034 | debuff lines |
| 514,040–514,044 | casting buff lines |
| 514,050–514,051 | utility |

514,010 is load-bearing — all three rip cadences must share it or the detonators only fire off
some of them.

---

## 5. Build order

Per vault §14g:

1. **Mana rip + chaos detonation (6–12)** — data-only once W1 lands, and it establishes his damage
   identity **independently of the copies.** That matters: it means he's playable before W7.
2. **Buffs, debuffs, mez (13–30)** — stock, immediate.
3. **W7 swarm work (1–5)**: spellbar snapshot + allow-list + count-driven survival buff. **This is
   the class.**
4. **Tune copy caps last**, with the survival buff and damage both in place.

---

## 6. Open items

- [ ] **Can a swarm pet be assigned a runtime-generated spell list?** *(Gates the entire E7
      rework — check first.)*
- [ ] **Swarm-pet death hook** for the count-driven survival buff.
- [ ] Whether a **chromatic / lowest-resist `resisttype`** exists.
- [ ] **Fizzle-rate SPA number.**
- [ ] Whether swarm AI can be **constrained to the owner's target** (prevents mez-breaking).
- [ ] **SPA 15 transfer mechanics** — does ripped mana have a natural recipient field, or does it
      need a recourse?
- [ ] Max simultaneous copies; per-copy survival magnitude and stack cap.
- [ ] Mez durations, AE target cap, break rules.
- [x] ~~Charm line~~ — **cut** per E7. Confirm nobody wants it back as a minor tool.
