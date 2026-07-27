# Wizard — Spell Design

**Class id 12 · band 43,540–43,659 · spellgroups 512,000+**

Source: vault `04 Class Identities/Wizard.md` §9a–§9g and §14. Native specialty: **fire & ice
mastery — highest single-nuke damage plus the lure/combo system**, tier advantage **+2**.

> Per **C13**, his lure→combo sequence is **the reference implementation of the detonation
> pattern (P3.1)**. Every other combo class — Necromancer, Beastlord, Druid, Enchanter, Rogue —
> copies its shape. Build it first and build it carefully; the shortcuts taken here get inherited
> five times over.

---

## 1. The combo system, stated once

The whole class hangs off one idea, so it is worth being precise before the tables.

- A **lure** is a fast-cast, very-low-`resistdiff` spell carrying a resist debuff plus small
  damage. It almost always lands. **Its presence on the target is the combo flag** — there is no
  separate state to track.
- A **matched combo** (fire lure → fire nuke) carries a **SPA 374 trigger with a Limit checking
  the fire-lure spellgroup**, adding amplified damage. **It does not consume the lure.**
- An **opposite combo** (fire lure → ice nuke) uses the same mechanism, but the payload is
  **Scald** — a ~2-tick DoT (SPA 0) plus **SPA 20 blindness** — and it **strips the lure**.

**Matched is repeatable amplification; opposite is a one-shot conversion into control.** That's a
real decision every cast rather than two cosmetic variants, and it gives the branches distinct
tempos. Vault §14a recommends exactly this and it's adopted here.

**Scald does not restack** — refresh only. A blind that stacks is a hard lock, and per A3 control
is already well covered across the roster.

The "check for a spellgroup on the target" half is **W1** (`SpellRestriction` 1000, consumed via
SPA **442** `TriggerOnReqTarget`). SPA **385** `LimitSpellGroup` exists and is implemented, which
is promising for the focus-limit half — but the trigger-plus-restriction path is what the backlog
actually allocated an id for.

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a — Lures (4)

Extremely low resist, fast cast, strip resistance, flag for combos.

| # | base | Spell | Element | Effect | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 1 | 43,540 | **Lure of Flame** | fire | small DD + fire resist debuff | max↑ | — |
| 2 | 43,543 | **Lure of Chill** | cold | small DD + cold resist debuff | max↑ | — |
| 3 | 43,546 | **Conflagrant Lure** | fire, **AE** | the AoE-lure form — gated by spell 27 | max↑ | — |
| 4 | 43,549 | **Glacial Lure** | cold, **AE** | the AoE-lure form — gated by spell 27 | max↑ | — |

3 and 4 are the data-only implementation of the lure-as-AoE AA. Vault §14d offers two routes —
a buff with a 374 trigger that swaps the cast spell, or **the buff's presence simply gating
access to a parallel AE-lure spell.** The second is data-only and is what these two rows are.

Spellgroups 512,001–512,004. **The fire lures share one group and the cold lures share another**
(512,001 fire, 512,002 cold) so a combo Limit matches either the single or AE form — otherwise
the marquee line breaks the moment he uses the AE lure.

### §9c — Nukes: three cadences × two elements (6)

| # | base | Spell | Element | Cadence | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 5 | 43,552 | **Fire Burst** | fire | fast DD — filler/finisher | max↑ | — |
| 6 | 43,555 | **Ice Burst** | cold | fast DD | max↑ | — |
| 7 | 43,558 | **Meteor** | fire | long cast, big single-target | max↑ | — |
| 8 | 43,561 | **Asteroid** | cold | long cast, big single-target | max↑ | — |
| 9 | 43,564 | **Meteor Shower** | fire | long cast, AE | max↑ | — |
| 10 ⭐ | 43,567 | **Asteroid Shower** | cold | long cast, AE | max↑ | — |

Long-cast spells trade cast time for the biggest numbers. This is where the **+2 native
advantage** lives numerically: 7/8's Mk. III `max` should sit visibly above any dipped nuke of
the same tier.

> ⭐ **The marquee line:** AoE-lure AA → **Conflagrant Lure** (3) → **Asteroid Shower** (10) →
> the whole pack takes a massive ice nuke *and* a blinding Scald, because the elements were
> opposed. Per vault §14d this needs **no additional code** beyond the base combo — combo
> detection is per-target and already handles multiple targets.

### §9d — Combo riders (6)

These are the trigger-carrying variants. They are *not* separate buttons — each is authored as
the combo rider attached to its parent nuke, given its own row so the trigger, Limit and payload
are reviewable and tierable independently.

| # | base | Rider | On | Checks | Payload | Dep. |
|---|---|---|---|---|---|---|
| 11 | 43,570 | **Ignition** | fire nukes | fire lure present | amplified fire damage, **lure kept** | W1 |
| 12 | 43,573 | **Rime** | cold nukes | cold lure present | amplified cold damage, **lure kept** | W1 |
| 13 | 43,576 | **Scald** | cold nukes | **fire** lure present | 2-tick DoT + SPA **20** blind, **lure stripped** | W1 |
| 14 | 43,579 | **Sear** | fire nukes | **cold** lure present | 2-tick DoT + SPA **20** blind, **lure stripped** | W1 |
| 15 | 43,582 | **Thermal Shock** | any nuke | **both** lures present | large burst, strips both | W1 |
| 16 | 43,585 | **Cascade** | AE nukes | any lure on ≥3 targets | per-target bonus scaling with count | W1 |

13 is the named signature from §9d; 14 is its mirror so the cold-lure player isn't a second-class
citizen; 15 and 16 are the payoffs that make a deeper lure investment worth the GCDs.

⚠️ **SPA 20 blindness behaviour against NPCs specifically** is unverified and gates 13/14.

### §9e — Mana ward (3)

The one genuinely custom piece. "Convert a % of incoming damage into mana damage" has **no stock
SPA** — SPA 15 manipulates mana but not as a damage sink.

Implementation hooks `Mob::CommonDamage()` — the same site as W4 (accumulator) and W5
(threshold). **This is the fourth feature sharing that hook; build the package once.**

| # | base | Spell | Effect | Scaling | Dep. |
|---|---|---|---|---|---|
| 17 | 43,588 | **Mana Shroud** | % of incoming damage routed to mana instead of HP | flat% | **W4 pkg** |
| 18 | 43,591 | **Deep Shroud** | higher conversion %, higher per-hit cap, shorter duration | flat% | **W4 pkg** |
| 19 | 43,594 | **Arcane Reservoir** | self mana regen + raises the ward's per-hit cap | max↑ | — |

**Behaviour at zero mana:** the ward **stays up but stops converting** — damage resumes to HP and
conversion resumes when mana returns. Dropping the buff would force a recast at the worst possible
moment; this way the black-hole mana engine can rescue him mid-fight, which is the intended loop.

**Per-hit cap: yes.** Without one a single T10 spike drains his entire mana bar and the ward
becomes a one-shot.

### §9f — Black hole (4)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 20 | 43,597 | **Event Horizon** | ST snare whose magnitude **increases over duration** | **3** neg, stacking-buff ramp | max↑ | — |
| 21 | 43,600 | **Singularity** | on a later tick, casts an AE snare centred on the target | 3 neg + **374** | max↑ | ⚠️ |
| 22 | 43,603 | **Accretion** | enemies dying while afflicted proc mana regen to the wizard | on-death hook | max↑ | ⚠️ |
| 23 | 43,606 | **Gravity Well** | ground-target pull — packs the mobs the AE nukes want | **424** GravityEffect | flat% | — |

20's ramp uses the **stacking-buff approach** — the same shape as the Druid's ramping DoT. Free,
legible, and the stack count gives the player something to see.

21's grow-to-AE has no direct stock analog; the ST snare carries a **SPA 374 trigger** on a later
tick that casts an AE snare centred on the target.

22 needs the **"killed while debuffed by caster X"** hook — **shared with the Necromancer's
curse-raise.** One verification, one implementation, two classes.

23 is not in the vault §9f list. It is proposed because SPA **424 `GravityEffect`** exists and is
implemented, and it does the one thing his kit otherwise lacks: *packing* mobs so the AE nukes and
the AoE lure have a dense target. Flag it as an addition, not a transcription.

**The loop:** black-hole kills proc mana regen → refuels the mana ward → sustains the kite. That
self-contained survival loop is why he can be a cloth caster with no pet on a solo-first server.

### §9b — Familiars (3)

**SPA 108 is natively single-instance** — a new familiar replaces the old. Per **E1** the
one-at-a-time rule is stock behaviour with nothing to build, and swaps happen mid-combat at the
cost of mana and cast time.

The three differ **only** in their SPA **124** spell-damage focus values with element Limits.

| # | base | Spell | Grants | Scaling | Dep. |
|---|---|---|---|---|---|
| 24 | 43,609 | **Summon Mephit** | fire damage + | flat% | — |
| 25 | 43,612 | **Summon Abyssal** | cold damage + | flat% | — |
| 26 | 43,615 | **Summon Prismatic** | minor bonuses to **both** | flat% | — |

Mono-element is the specialist pick, prismatic the flexible one. Set 26's split so that it beats
running the wrong mono familiar but loses to the right one.

### §9g / §6.4 — Signature abilities and ports (4)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 27 | 43,618 | **Sculpt Spell** | ~36s self-buff; **gates access to the AE lures** (3, 4) | buff, no payload | flat% | — |
| 28 | 43,621 | **Careful Caster** | the wizard is **never damaged by his own AoE** | ⚠️ custom AE target exclusion | flat% | ⚠️ |
| 29 | 43,624 | **Translocate** | attunement-gated port, ranks = destinations | **104** | — | script |
| 30 | 43,627 | **Evacuate** | self + group emergency exit to the last safe zone | **88**/104 | — | script |

27 is data-only under the preferred implementation — it grants nothing itself, its *presence* is
what makes 3 and 4 castable.

28 is a small C++ change in AE target resolution. ⚠️ Check whether a stock AE-self-exclusion flag
already exists before writing it.

29/30 are **shared with the Druid** — the attunement system is one zone-entry hook flipping a
per-character qglobal plus a port spell reading it. Build once, both classes use it. Per §6.4
destinations are level-appropriate zones woven into the delve graph and unlock only after being
reached on foot.

---

## 3. Payload spells — 43,630–43,659

| id | Payload | Parent |
|---|---|---|
| 43,630 | Scald DoT + blind | 13 |
| 43,631 | Sear DoT + blind | 14 |
| 43,632 | Ignition amplified fire damage | 11 |
| 43,633 | Rime amplified cold damage | 12 |
| 43,634 | Thermal Shock burst | 15 |
| 43,635 | Cascade per-target bonus | 16 |
| 43,636 | Singularity AE snare | 21 |
| 43,637 | Accretion mana return | 22 |
| 43,638–43,659 | *unallocated* | |

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 512,001 | `wiz_lure_fire` — **spells 1 and 3 both** |
| 512,002 | `wiz_lure_cold` — **spells 2 and 4 both** |
| 512,010–512,015 | nuke lines (fast/long/AE × fire/cold) |
| 512,020–512,025 | combo riders |
| 512,030–512,032 | mana ward lines |
| 512,040–512,043 | black hole lines |
| 512,050–512,052 | familiars |
| 512,060–512,061 | Sculpt Spell, Careful Caster |
| 512,070–512,071 | ports |

The shared lure groups at 512,001/512,002 are load-bearing: every combo Limit names one of those
two groups, so the single-target and AE lures must sit in the same group or the AoE marquee line
silently fails to combo.

---

## 5. Build order

Per vault §14g:

1. **Lures + nukes + combos (1–16).** Data-only once W1 lands, and it is the P3.1 reference for
   five other classes. Get the semantics right here.
   ✅ **Lures + nukes (1–10) authored** (`0006`) and ✅ **combo riders 11–14 + payloads
   authored** (`0007`) — W1 landed, so the full detonation chain is in data. **The pattern is
   now normative: see [DETONATION-PATTERN.md](../DETONATION-PATTERN.md)** — riders and
   payloads are untiered, nukes carry two SPA 374 slots (matched + opposite rider), and the
   442/60000/max encoding is fixed. **Deferred:** Thermal Shock (15, needs AND-of-two-flags)
   and Cascade (16, needs cross-target counting) — both wait on a W1 extension. Scald/Sear
   ship **without the lure strip** (no stock SPA does it; open item in the pattern doc).
   The AE lures remain **ungated** — the Sculpt gate needs a caster-side field to carry the
   spellgroup, still open.
2. ✅ **Familiars (24–26)** — authored in `0006` (stock SPA 108 shape, pets `Familiar1–3`
   reused for models). Sculpt Spell (27) authored too, as a blank presence buff.
3. **Mana ward (17–19)** with the shared `CommonDamage()` package (W4/W5).
4. **Black hole (20–23)** — needs the on-kill hook shared with the Necromancer.
5. **Ports (29–30)** with the Druid.

---

## 6. Open items

- [ ] **SPA 340/374 trigger + Limit-on-target semantics** — the shared gate for every combo class.
      **Check first.**
- [ ] Whether a stock **AE-self-exclusion** flag exists (decides 28's cost).
- [ ] **"Killed while debuffed by caster X"** hook — shared with the Necromancer.
- [ ] **SPA 20 blindness** duration and behaviour vs. NPCs specifically.
- [ ] Whether mana can absorb damage without breaking mana regen or spell-cost interactions.
- [ ] Matched-combo amplify %; confirm matched does **not** consume the lure.
- [ ] Mana ward conversion %, per-hit cap, zero-mana behaviour.
- [ ] Black hole: grow-to-AE timing, snare-power curve, mana-per-kill amount.
- [ ] Whether spell 23 (Gravity Well) is wanted at all — it is an addition to the vault, not a
      transcription of it.
