# The Detonation Pattern (P3.1) — Reference Implementation

The Wizard's lure→combo system, built in migrations `0006`/`0007` on top of **W1**. This is
the shape Necromancer, Beastlord, Druid, Enchanter and Rogue copy — per **C13**, shortcuts
taken here get inherited five times, so deviations from this doc need a reason written down.

Status: **authored and SQL-validated, unapplied** (behind the `0004` gate), engine half
**built and deployed, untested in-game**. The in-game test matrix is in `0007`'s footer and
doubles as W1's done-when criterion.

---

## 1. The engine half (W1)

One custom `SpellRestriction`:

| | |
|---|---|
| Id | **60000** — `IS_TARGET_HAS_WD_SPELLGROUP` (`common/spdat.h`) |
| Band | 60,000–60,999 reserved for WD custom restrictions |
| Meaning | this mob has an active buff whose spell belongs to spellgroup *N* |
| Where *N* rides | the **`max` field of the same SPA 442/443 effect slot** |
| Evaluation site | `Mob::TryTriggerOnCastRequirement()` (`zone/mob.cpp`), called from damage/cast events |
| On success | payload is `SpellFinished` **on the buff holder**, and the 442-carrier buff fades |
| On failure | nothing — custom ids have no client message; the miss is silent by design |

⚠️ F1 originally allocated id 1000 for this; **1000 is stock** (`IS_BETWEEN_LEVEL_1_AND_75`).
F1-ID-RANGES.md carries the correction.

## 2. The data half — three spells per combo branch

```
FLAG        the lure: fast, ResistDiff -300, tiny DD + resist debuff, ~30s buff.
            Its PRESENCE on the target is the entire combo state.

CARRIER     the nuke: SPA 374 ApplyEffect slot (base = 100 chance, limit = rider id)
            alongside its damage slot. AE nukes fire the 374 per target.

RIDER       1-tick, unresistable, zero-cost, never-scribed buff with ONE effect:
            SPA 442 · base = payload id · limit = 60000 · max = lure spellgroup.

PAYLOAD     whatever the combo pays: instant damage (matched), DoT+control
            (opposite), anything castable. Fired on the rider's holder.
```

Rules that came out of building it:

- **Lures of one element share ONE spellgroup** (fire 512,001 / cold 512,002 — single-target
  and AE forms both), because the rider's `max` names exactly one group. A class whose
  single/AE flags sit in different groups silently breaks its own combos.
- **Riders are untiered.** All three Mk. tiers of a carrier point at one rider; tier scaling
  lives in the carrier's own damage and the payload's level formula. (The class doc may
  reserve tiered triples; use the base id, leave +1/+2 spare.)
- **Payloads are untiered** and scale with caster level (formula 102/105 + max).
- **Matched combos keep the flag for free** — the 442 path fades only the rider. Repeatable
  amplification needs no extra mechanism.
- A carrier with **two 374 slots** hosts both the matched and the opposite branch; whichever
  lure is present decides which rider's 442 passes. Both present → both fire (that's Thermal
  Shock's design space, see §4).

## 3. Copying it: per-class checklist

1. Pick the flag line and give every spell in it **one spellgroup per branch**.
2. Author flag / carrier / rider / payload rows; riders + payloads live in the class's
   payload sub-band (`+090…+119`).
3. Rider: copy a `0007` rider row verbatim, change id, spellgroup, payload id, and the
   `max` (flag spellgroup).
4. Nothing else. No C++, no new restriction ids — 60000 is shared by every class forever.

## 4. Known limits (verify once, in the Wizard tests — not per class)

| Limit | Detail |
|---|---|
| **Attribution** | the payload is self-cast by the target via `SpellFinished(payload, this)`. Kill credit / XP for payload damage is unverified. If broken, fix in `TryTriggerOnCastRequirement` (attribute to rider's caster), not in data. |
| **Timing** | the 442 check runs on damage/cast events, not on rider application. Expected: the payoff lands with the triggering nuke's own damage event or the next one. Confirm which. |
| **Strip-on-detonate** | no stock SPA removes a specific spellgroup's buff. Scald/Sear ship *without* the lure strip. Candidates: a fade-by-spellgroup flag on the 442 path (small C++), or accepting no-strip. Decide before the Necro's Reap copies it — Reap *requires* consumption. |
| **AND of two flags** | one 442 slot = one group. Thermal Shock (both lures) and any "requires two flags" design waits on a W1 extension (e.g. second custom id meaning "has BOTH groups", encoded as `max = groupA * 100000 + groupB`). |
| **Count across targets** | Cascade (per-lured-target scaling) has no data-only expression. |

## 5. Files

| | |
|---|---|
| Engine | `common/spdat.h` (enum), `zone/mob.h`, `zone/spell_effects.cpp` (`PassCastRestriction`), `zone/mob.cpp` (442 site) |
| Data | `worlddungeon/migrations/0006_wizard_core.sql`, `0007_wizard_combo_riders.sql` |
| Design | `docs/worlddungeon/spells/wizard.md` §1, §9d |
| Id policy | `docs/worlddungeon/F1-ID-RANGES.md` (restriction id correction + claims) |
