# Stage 2 — Re-scope spikes (S1, S2, S3)

**Status:** all three answered · branch `feature/foundations`

Cheap source reads whose only job is to stop us building things the engine already has. Phase 0
shrank three bill items this way; these shrink four more and **correct one design assumption
that was simply wrong**.

Every line/file reference below was read on `feature/foundations` at commit `518c051`.

---

## S1 — Threshold / resource SPA gap analysis

**Gates:** W4 scope, W5 scope, W6's existence.

### What already exists

| SPA | Name | `common/spdat.h` | Behaviour |
|---:|---|---:|---|
| 450 | `MitigateDotDamage` | 1513 | % mitigation of incoming DoT until rune fades |
| 451 | `MeleeThresholdGuard` | 1514 | partial melee rune, only decremented by hits over X |
| 452 | `SpellThresholdGuard` | 1515 | partial spell rune, only decremented by hits over X |
| 453 | `TriggerMeleeThreshold` | 1516 | trigger effect on X melee damage **in a single hit** |
| 454 | `TriggerSpellThreshold` | 1517 | trigger effect on X spell damage **in a single hit** |
| 457 | `ResourceTap` | 1520 | convert % of DD/DoT damage dealt to hp/mana/end |

### The gap, precisely

`Mob::TryTriggerThreshHold()` (`zone/spell_effects.cpp:9761`) is called from **inside
`Mob::CommonDamage()`** — `zone/attack.cpp:4171` (melee) and `:4196` (spell). `CommonDamage`
begins at `zone/attack.cpp:4027`.

That function already does almost everything W5 needs:

- scans the whole buff array for a buff carrying the effect,
- reads the payload spell from `base_value[i]`,
- **fades the source buff** (`BuffFadeBySlot`),
- casts the payload, routing beneficial → self and detrimental → attacker.

**The only thing that differs is the predicate.** It tests

```cpp
if (damage > spells[buffs[slot].spellid].limit_value[i])   // single-hit damage
```

where the design needs *"resulting HP is below X% of max"*.

### Verdict — W5 shrinks from S to XS

W5 is **one new SPA id plus one new predicate**, reusing `TryTriggerThreshHold` wholesale.
There is no need for a new hook site, new buff scanning, new fade logic, or new payload routing.

Two placement notes for whoever builds it:

- **HP has not been subtracted yet** at the existing call sites. `SetHP(GetHP() - damage)` is at
  `zone/attack.cpp:~4265`, *after* the trigger call. So the predicate must use the **projected**
  ratio, `(GetHP() - damage) * 100 / GetMaxHP()`, rather than `GetHPRatio()`. This is a feature,
  not a workaround — it's deterministic and avoids depending on where the call sits.
- `CommonDamage` already computes `previous_hp_ratio` (`:4088`) and `old_hp_ratio` (`:4210`) for
  its own purposes, and already does a crossing test at `:4292`
  (`GetHPRatio() < 16 && previous_hp_ratio >= 16`). **That is the exact edge-triggered shape
  W5 wants** — copy it, so the buff fires on *crossing* the threshold rather than every hit
  taken while already below it.

### Verdict — W6 probably does not exist

SPA 457 `ResourceTap` converts a percentage of damage from DD/DoT into hp/mana/endurance. The
Wizard mana ward is the same operation. **Assume W6 is closed as covered by 457** and reopen it
only if authoring an actual mana-ward spell hits a wall.

### Verdict — W4 is unchanged, and is the real work

Nothing above tracks *cumulative* absorbed or dealt damage. 451/452 decrement a rune; they don't
bank a total that something else can read. W4's accumulator stands as specced — **M**, and it is
now the only genuinely new mechanism in Stage 3.

**Net effect on Stage 3: three items become one and a bit.**

---

## S2 — Swarm-pet death hook

**Gates:** W7 scope, and the Enchanter's count-driven survival buff.

### It already exists

Phase 0 didn't find it because it isn't near `StartSwarmTimer()`. It's in **`NPC::Death()`**,
`zone/attack.cpp:2542`:

```cpp
if (GetSwarmOwner()) {
    Mob* owner = entity_list.GetMobID(GetSwarmOwner());
    if (owner) {
        owner->SetTempPetCount(owner->GetTempPetCount() - 1);
    }
}
```

`NPC::Death()` starts at `zone/attack.cpp:2470`. The site **already resolves the owner pointer
and already maintains a live count**, which is precisely what the Enchanter buff needs to read.

### Which of the three sites to hook

`SetTempPetCount(... - 1)` appears three times. They are not equivalent:

| Site | Meaning |
|---|---|
| `zone/attack.cpp:2545` | swarm body **died** — ← **this one** |
| `zone/npc.cpp:3266` | swarm body expired / depopped |
| `zone/pets.cpp:327` | pet teardown |

A count-driven *survival* buff must distinguish "my copies were killed" from "my copies timed
out", so hook **attack.cpp:2545** only. Hooking the other two would make the buff fire on the
duration expiring, which is the opposite of the intended feel.

### Verdict — W7 shrinks again

W7's four documented sub-items are now:

- ~~Independent caps per swarm subtype~~ — free (Phase 0 / V4).
- ~~Enchanter copies breaking mez~~ — already built (Phase 0 / V4).
- ~~Swarm-pet death hook~~ — **already built.** One call added at an existing site that has the
  owner in hand. Effectively free.
- **Doppleganger runtime spell list** — still real. Seam at `zone/aa.cpp:103-109`.
- **Necro target inheritance** — still real.

W7 goes from **M** to **S**, and is now two narrow features rather than four.

---

## S3 — Block-chance SPA and aura range

### S3a — Block chance is SPA 188, and it is multiplicative

**Answers vault V6.** `IncreaseBlockChance` = **188** (`common/spdat.h:1251`), implemented.
Related: `BlockBehind` 222, `ShieldBlock` 320, `TwoHandBluntBlock` 405.

The formula, `zone/attack.cpp:537-546`:

```cpp
if (CanThisClassBlock() && (InFront || bBlockFromRear)) {
    ...
    int chance = GetSkill(EQ::skills::SkillBlock) + 100;
    chance += (chance * (aabonuses + spellbonuses + itembonuses).IncreaseBlockChance) / 100;
    chance /= 25;
```

**This directly answers the pre-50 viability question, and the answer is unfavourable.**

- SPA 188 is a **percentage modifier on the block skill**, not a flat addition. With
  `SkillBlock` at 0, base chance is `(0 + 100) / 25` = **4%**. A +100% SPA 188 bonus doubles that
  to 8% — it adds four percentage points.
- So **SPA 188 is weakest exactly where the design wants block to matter**: low level, low skill.
  Any pre-50 block identity built on 188 alone will feel like it does nothing.
- It is also gated on **`CanThisClassBlock()`**, so it is not available to arbitrary classes
  without engine work.

Two escape hatches, both already in the source:

- **`IncreaseBlockChance == 10000` is a hardcoded guaranteed block** (`zone/attack.cpp:540-543`)
  — an exact-match sentinel, not a threshold. Useful for a short auto-block cooldown; useless as
  a scaling stat.
- Heroic DEX contributes a **flat** `itembonuses.HeroicDEX / 25` to the same chance — the only
  additive term in the formula, and therefore the lever that actually works pre-50.

> **Design decision this forces, and it belongs to W11:** if WorldDungeon wants block to be a
> meaningful pre-50 defensive layer, SPA 188 is not sufficient and **a flat additive block term
> is required in C++**. Either fold it into W11 or drop pre-50 block from the design. Don't
> author spells against 188 expecting them to matter.

### S3b — SPA 270 is bard **song** range (V20 stands; my first reading of it did not)

> [!warning] **Corrected 2026-07-27.** An earlier revision of this file claimed V20 was wrong and
> that W10 shrank to XS because "aura radius is the `auras.distance` column". **That conclusion
> was mistaken.** It was drawn from the backlog's one-line summary of V20 rather than from the
> *Bard Aura Patch* itself. Reading the patch: it does **not** use the `auras` table at all. It is
> a custom C++ patch that projects beneficial bard songs from the spellbar as permanent buffs,
> range-gating group members. In that design **SPA 270 `BardSongRange` is exactly the right
> effect** and the vault uses it correctly. **W10 remains an S-sized C++ item, not XS.**
> The `auras.distance` facts below are accurate but describe the *aura-entity* system, which W10
> does not use.

**SPA 270 is `BardSongRange`** (`common/spdat.h:1333`) — "increase range of beneficial bard
songs", documented at `zone/client_mods.cpp:1490` with Sionachie's Crescendo as the example. It
modifies **song** range. It has nothing to do with aura radius.

**Aura radius is a database column**, `auras.distance`:

- `Aura::Aura()` reads `record.distance` (`zone/aura.cpp:27`) into a `float distance` member
  (`zone/aura.h:93`).
- Every range test is `DistanceSquared(...) <= distance` (`zone/aura.cpp:104`, `:162`, `:196`,
  `:270`, and others).
- That is consistent because the value is **squared once at load time**:
  `r.distance = e.distance * e.distance;` (`zone/aura.cpp:967`).

**Authoring note:** `auras.distance` is a plain radius in world units — the engine squares it,
so do not pre-square it when writing rows. Stock values are 25 and 60.

The **E4 scope filter** likewise needs no new SPA: `auras.spawn_type` already selects who the
aura applies to, surfaced as `AuraSpawns::GroupMembers` and friends (`zone/aura.h:88`, `:99`).

### Verdict

- **W10 is unchanged at S.** It is a real C++ patch (spellbar reconcile pass + range-gated
  projection), and its use of SPA 270 is correct. **No vault correction is owed.** The
  `auras.distance` detail is useful only if some *other* feature uses aura entities.
- **W11 grows slightly** — it now owns the flat-additive block term, if pre-50 block is wanted.

---

## Summary of scope changes

| Item | Was | Now |
|---|---|---|
| W4 accumulator | M | **M** — unchanged, and now the only new mechanism in Stage 3 |
| W5 threshold trigger | S | **XS** — one SPA id + one predicate, reusing `TryTriggerThreshHold` |
| W6 wizard mana ward | S | **closed** — covered by SPA 457 `ResourceTap` |
| W7 swarm extensions | M | **S** — death hook already exists; 2 real sub-items left |
| W10 bard aura | S | **S — unchanged.** (An earlier revision wrongly reduced this to XS.) |
| W11 AC/avoidance cap | M | **M+** — inherits the flat block term, if pre-50 block is wanted |

## Corrections owed to the design vault

1. **V6's pre-50 concern is confirmed and worse than assumed.** SPA 188 is multiplicative on
   block skill, so it is near-useless at low skill. Heroic DEX is the only additive term.
2. ~~V20 is wrong~~ — **withdrawn, V20 is correct.** See the correction box in S3b.
