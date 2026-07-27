# Phase 0 — Source Verification Results

Answers to the Tier-1 questions in the design vault's *Source Verification & Build Order*,
read against this tree at `b69fa9cbc` (upstream `master`, pre-fork).

Every claim below cites `file:line`. Re-verify after any upstream merge that touches
`zone/attack.cpp`, `zone/mob.cpp`, `zone/spell_effects.cpp`, `zone/aa.cpp`, or `common/spdat.h`.

Legend: **RESOLVED** — answered, no further reading needed. **CHANGED** — the answer
invalidates an assumption in the design docs.

---

## V1 — Can Limit SPAs (134–147) test for a spellgroup on the *target*? **NO — CHANGED**

`common/spdat.h:1234-1247`. All fourteen Limits filter **the spell being focused**, never
the target's state:

| SPA | Filters on |
|---|---|
| 134 / 142 | Spell's max / min level |
| 135 | Spell's resist type |
| 136 | Spell's target type |
| 137 | Presence of a given SPA id *in the focused spell* |
| 138 | Beneficial vs detrimental |
| 139 | Specific spell id |
| 140 | Minimum duration |
| 141 | Instant-cast include/exclude |
| 143 / 144 | Cast time min / max |

There is no Limit that reads buff state on a target. **The detonation pattern (primer P3.1)
is not data-only as written**, and six classes' signature mechanics rested on that.

### The fallback is far cheaper than the design docs assumed

The engine already has a target-condition system the primer does not mention:

- `enum SpellRestriction` — `common/spdat.h:298`. Body type, class, HP-percent thresholds.
- `Mob::PassCastRestriction(int value)` — `zone/spell_effects.cpp:7571`. **A single switch.**
- Consumed in four places:
  - `spells_new.cast_restriction` → target gate, `zone/spells.cpp:788`
  - `spells_new.caster_requirement_id` → caster gate, `zone/spells.cpp:583`
  - **SPA 442 `TriggerOnReqTarget`** — `common/spdat.h:1505`, handled at
    `zone/spell_effects.cpp:3334`, `zone/bonuses.cpp:3378`, `zone/mob.cpp:5900`.
    Fires a spell when a target requirement is met. Marked implemented.
  - The LIMIT field of SPA 0 / 79 damage and heal spells — per the comment at
    `zone/spell_effects.cpp:7579`.

So adding **one restriction ID** meaning *"target has a buff whose spell is in spellgroup N"*
— one enum entry plus one branch in `PassCastRestriction()` — makes detonation data-only
across all its consumers at once, through a mechanism that is already wired into cast gating,
trigger SPAs, and damage/heal limits.

**This is Small, not Medium, and it belongs at the top of the C++ bill — above the Accumulator.**
It unblocks Wizard, Necromancer, Rogue, Druid, Berserker, Beastlord, Enchanter and Paladin.

---

## V2 — SPA 373 (Cast on Fade) exact semantics **RESOLVED**

`common/spdat.h:1436`:

```
constexpr int CastOnFadeEffectAlways = 373; // implemented - Triggers if fades after natural duration OR from rune/numhits fades.
```

Fires on **depletion as well as timeout** — exactly the distinction the Paladin ward
detonation and Shaman ward break-riders required. No fallback hook needed.

The self-recast loop guard for the Shaman reapply focus is still wanted, but that is a
data-authoring concern, not an engine one.

Related, and *not* in the design docs — these are all marked implemented and cover most of
custom bill #5 (threshold trigger) plus the Wizard mana ward:

| SPA | Name | `spdat.h` |
|---|---|---|
| 451 | `MeleeThresholdGuard` — partial rune, only lowered by hits over X | :1514 |
| 452 | `SpellThresholdGuard` | :1515 |
| 453 | `TriggerMeleeThreshold` — trigger on X melee damage in one hit | :1516 |
| 454 | `TriggerSpellThreshold` | :1517 |
| 457 | `ResourceTap` — converts % of DD/DoT damage to hp/mana/end | :1520 |
| 450 | `MitigateDotDamage` | :1513 |

---

## V3 — SPA 178 (Melee Lifetap) number, semantics, target flexibility **RESOLVED**

`Mob::MeleeLifeTap(int64 damage)` — `zone/mob.cpp:6850`.

- **Percentage, not flat**: `lifetap_amt = damage * (mod / 100.0f)`.
- Aggregates SPA 178 **and** SPA `Vampirism` from spell + item + AA bonuses into one modifier.
- Negative values self-damage instead of healing — a usable design lever.
- **Stacking is take-highest, not additive** — `zone/bonuses.cpp:1349` and `:2426`. Multiple
  sources do not sum unless `AdditiveWornBonus` is set. Tier progression works naturally;
  layering separate sources does not.

Sub-questions:

- **Can it be applied to other players as a buff?** Yes. It is an ordinary spellbonus, so any
  buff carrying SPA 178 works on any target. **The Bard group-lifesteal song is data-only** —
  each member lifetaps for themselves.
- **Can it be applied to a pet with the *owner* as heal recipient?** **No.** `HealDamage()` is
  called on `this` — the attacker heals itself, hardcoded. **The Shadowknight Blood Golem
  needs code.**

---

## V5 — Can a pet's proc target its owner? **NO — resolve with V3**

`Mob::ExecWeaponProc` — `zone/mob.cpp:5278`. Beneficial procs land on `this`, the proccing
mob: `SpellFinished(spell_id, this, ...)` at `:5366`. A pet's beneficial proc buffs the pet.

**V3's second sub-question and V5 are the same defect, so they are one work item:**
*pet-sourced beneficial effects redirect to owner*, at two sites —
`Mob::MeleeLifeTap` (`mob.cpp:6850`) and `Mob::ExecWeaponProc` (`mob.cpp:5366`).
Small. Unblocks SK Blood Golem, Beastlord reciprocal procs, Beastlord support-warder spec,
Beastlord warder-triggered combos.

Note `ExecWeaponProc` already carries a `focusTwincast` roll (`:5347`) and an
`EVENT_WEAPON_PROC` quest hook for client-held items (`:5336`) — the quest hook is a
script-level escape valve if the redirect turns out to need per-case control.

---

## V4 — SPA 152 (Temporary/Swarm Pets) caps, duration, spell lists **RESOLVED**

`Mob::TemporaryPets(...)` — `zone/aa.cpp:48`. Note it lives in `aa.cpp`, not `pets.cpp`.

- **Count and duration are per-SPA-slot data**: `pet.count = base_value[x]`,
  `pet.duration = max_value[x]` (`:84-85`). Duration is extended by the
  `focusSwarmPetDuration` focus (`:89`), in whole seconds.
- **`MAX_SWARM_PETS` is 12** — `zone/aa.h:20`. Clamped per cast at `:114`.
- **The cap is per-cast, not standing.** There is no cross-cast accounting anywhere in the
  function. This answers two sub-questions at once: swarm subtypes have independent caps for
  free, because *no shared cap exists* — **the Ranger's defensive swarms cannot eat his
  warhorn**. It also means standing swarm totals are unbounded by the engine and must be
  bounded by recast timers and duration in the spell data.
- **Bodies come from the `pets` table**, keyed by `spells[spell_id].teleport_zone` as a name
  string, via `content_db.GetPoweredPetEntry()` (`:69`). Pet Power focus applies to swarms
  (`:62`) — "yep, even these need pet power!".
- **Spell lists are static**, inherited from the `npc_types` row's spell set. There is no
  runtime spell-list assignment path. **The Enchanter doppleganger (E7) needs code.**
- **Target inheritance already exists** — `:161-172`. The pet is added to the target's hate
  list at 1000/1000, and under `RuleB(Spells, SwarmPetTargetLock)` or the `sticktarg`
  argument it gets `SetPetTargetLockID(targ)` plus `SpecialAbility::AggroImmunity`.
  **This is the Enchanter's "copies must not break mez" requirement, already built** —
  enable the rule or pass `sticktarg`. Necro xtarget-clearing needs the opposite (acquire
  after the locked target dies), which target-lock does not do; that remains open.
- Name override allocates a per-cast `NPCType` copy (`:103-109`), so per-summon customization
  has an existing seam.
- The `followme` and `eye_id` arguments exist for follow-behaviour and controlled-mob binding.

**Still open:** no swarm-pet death hook was found — the Enchanter's count-driven survival buff
is unverified. `swarm_pet_npc->StartSwarmTimer()` and the `SwarmPet` struct are the places to
look next.

---

## V15 — Ranged combat **RESOLVED — CHANGED, and much better than feared**

The vault calls this "the highest-uncertainty item in the entire class set" and warns that
"EQ ranged is engine-weak — budget real .lua/C++ work." **That is not true of this tree.**

`Mob::DoArcheryAttackDmg(...)` — `zone/special_attacks.cpp:1016`. A complete implementation
taking weapon damage, damage mod, chance mod, skill, speed and ammo item.

- **Procs do fire on bow attacks.** `TryWeaponProc(..., EQ::invslot::slotRange)` at
  `special_attacks.cpp:1145` and `:1148`, sourced from the ammo item. This was the specific
  doubt raised in the vault, and the answer is yes.
- `Client::RangedAttack` — `:862`, with distance gating against
  `RuleI(Combat, MinRangedAttackDist)` (`:970`).
- **Double ranged attack is a supported SPA** — `Client::CheckDoubleRangedAttack`,
  `zone/attack.cpp:4003`, reading `DoubleRangedAttack` from spell + item + AA bonuses.
  Driven at `special_attacks.cpp:384` and `:394`.
- A projectile system exists (`ProjectileAtk`, `:1308-1314`) with travel time.
- `SpecialAbility::RangedAttackImmunity` is honoured — `zone/attack.cpp:4048`.
- **Exposed to Lua in six overloads** — `zone/lua_mob.cpp:1505-1535`, bound at `:3699-3704`.
  Archery lines are scriptable **without C++**.

**Consequence:** the Ranger's archery specialization (E6) does not need the documented
fallback of re-flavouring archery as a SPA 193 skill-attack line. Build it as real archery.
Remaining unknowns are tuning-shaped, not feasibility-shaped: the damage formula's ammo
contribution, and whether the weapon matrix and socket rules extend to bows.

---

## Net effect on the build order

1. **New item, now first:** spellgroup-on-target restriction ID (V1). Small. Unblocks eight classes.
2. **New item:** pet owner-redirect (V3 + V5 merged). Small. Unblocks two classes.
3. **Reduced:** threshold trigger (bill #5) and the Wizard mana ward — SPAs 451-454 and 457
   already exist; re-scope to what they do not cover before writing any C++.
4. **Reduced:** Enchanter copy aggro control is already built (swarm target lock).
5. **De-risked:** Ranger archery. Removes the largest single unknown in the class set.
6. **Unchanged:** Accumulator (P3.2) and Ally-target expansion (P3.6) are still real work and
   still share the `Mob::CommonDamage()` hook site.
