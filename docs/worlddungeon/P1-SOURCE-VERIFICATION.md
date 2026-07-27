# P1 — Cleric + Monk source verification

**Status:** in progress · branch `feature/p1-cleric-monk`

The vault marks 11 items `⚠️ [VERIFY IN SOURCE]` across [[Cleric]] §14h and [[Monk]] §14f, and
both docs say to resolve them **before** authoring. Doing that first, because the alternative is
writing ~40 spells against assumptions and finding out later.

---

## 🔴 1. `spellgroup` does **not** drive buff stacking — the vault's central assumption is wrong

**This is the big one.** It underpins the Monk's entire dual-pool system ("literally two
`spellgroup`s"), the Cleric's mantles, the D2 tier-line model, and three rows of the backlog's
*Data-only — no engine work needed* table.

**`Mob::CheckStackConflict()` (`zone/spells.cpp:3069`) never reads `spell_group`.** It keys on
`spellid1 == spellid2` first, then falls through to comparing **effect ids and their slot
positions**. A full sweep of `zone/` and `common/` finds `spell_group` used in exactly three
places, none of them stacking:

| Use | Where |
|---|---|
| **Focus limit filters** — include/exclude a spellgroup from a focus effect | `zone/spell_effects.cpp:4947,4953,5674,5680` |
| **Hardcoded checks** for specific *live* spellgroups (Frenzied Burnout, Rogue's Fury, Illusion of Grandeur…) | `zone/spell_effects.cpp:7861-8431` via `HasBuffWithSpellGroup` |
| **Spell scribing** — which rank of a line you get taught | `zone/spells.cpp:6129` `GetHighestScribedSpellinSpellGroup` |

So two different spells sharing a `spellgroup` do **not** natively overwrite each other as buffs.
Casting Ostrich then Gorilla would not replace the stance; it would run them both through
effect-slot conflict resolution, and they'd partially coexist wherever their effects differ.

### What this does *and does not* break

**The design intent is still achievable data-only.** What's wrong is the named mechanism, not the
feature. Stock EQEmu gives three real ways to get one-at-a-time:

1. **Identical effect layout** — give every stance in a pool the same SPAs in the same slots.
   `CheckStackConflict` then treats them as competing versions of one buff and overwrites. This
   is how live stances actually behave, and it costs nothing but authoring discipline.
   ⚠️ It constrains design: Ostrich (SPA 185 + SPA 3) and Gorilla (SPA 185 only) would need
   padding to matching layouts.
2. **The stacking-command SPAs** — `StackingCommand_Block` (148) and the `AStacker`/`BStacker`
   family (446–449, `common/spdat.h:1509`). Explicit, and independent of effect layout.
3. **Same spell id, different rank** — for the D2 tier lines 1–10, higher rank overwriting lower
   is standard behaviour and is *not* at risk. **Tier lines are fine.** They just work for a
   different reason than the vault states.

**Recommendation:** use **(1)** for stance pools, since it's what the client and live data expect,
and reserve **(2)** for cases where two stances genuinely can't share a layout. Do **not** rely
on `spellgroup` for exclusivity anywhere.

**Still true:** `spellgroup` remains correct and necessary for spell *scribing* ranks (A3 depends
on this) and for focus include/exclude filters. F1's 500,000 spellgroup range stands.

---

## 🟡 2. SPA 153 `BalanceHP` — the sign is inverted from the design

**Answers the Cleric's "average / highest / weighted" question, and finds a trap.**

`Group::BalanceHP()` (`zone/groups.cpp:1352`):

```cpp
dmgtaken_tmp = members[gi]->GetMaxHP() - members[gi]->GetHP();  // damage taken
if (limit && (dmgtaken_tmp > limit)) dmgtaken_tmp = limit;
dmgtaken += dmgtaken_tmp;
...
dmgtaken += dmgtaken * penalty / 100;   // penalty = base_value
dmgtaken /= numMem;                     // <-- average
// each member ends at MaxHP - dmgtaken
```

- **It balances to the *average damage taken*** (absolute HP, not a percentage), so members with
  different max HP end at different ratios. Question answered — and it needs no work.
- **`base_value` is a *penalty*, so the sign runs opposite to §9e.** Positive base **increases**
  the damage spread around — it makes the ability *worse*. **Negative base is the bonus** that
  adds net healing. The vault describes low tiers at "−30%" and high tiers at "+30%"; the engine
  wants **low tiers positive, high tiers negative.** Authoring the vault's numbers literally
  would produce a line that gets *worse* as it ranks up.
- **`limit_value` caps the damage counted per member** — a useful safety valve so one near-dead
  member doesn't drag the group down.
- **It cannot kill:** members floor at 1 HP.
- `range` defaults to 200 if unset.

---

## 🟢 3–5. Resolved cleanly

**Max-HP SPA — 214 vs 69 (`zone/bonuses.cpp:727,786`).** Both exist and differ as suspected:

| SPA | Bonus field | Meaning |
|---:|---|---|
| **69** `TotalHP` | `FlatMaxHPChange` | **flat** max-HP |
| **214** `MaxHPChange` | `PercentMaxHPChange` | **percentage** max-HP |

The Cleric's "best HP buffs" wants **69 for flat baseline buffs and 214 for percentage scaling**.
Both are additive within their kind.

**SPA 178 `MeleeLifetap` as a short buff — Pangolin is viable** (`zone/bonuses.cpp:1349-1355`).
It's an ordinary spell bonus that resolves by **highest value wins** (and most-negative wins for
negatives), so a short-duration buff applied by a defensive proc works exactly as §14c
recommends. **Pangolin needs no custom C++.**

**Block chance — already answered by S3.** SPA **188** `IncreaseBlockChance`, and it is
*multiplicative on block skill*, so it is near-useless pre-50. Badger's block component will not
feel like anything at low level. See [STAGE-2-SPIKES.md](STAGE-2-SPIKES.md); the flat additive
term is W11's problem, not P1's. **Author Badger's other components and don't lean on block.**

---

## Outstanding

| Item | Class | Status |
|---|---|---|
| Flurry SPA number, tunable independently of haste | Monk (Hummingbird) | not yet checked |
| Does same-layout overwrite trigger a recast/GCD? | Monk | **now more important** — decides how fluid swapping feels, given finding #1 |
| Recourse behaviour on partial resist | Cleric (smite) | not yet checked |
| SPA 125 accepts a negative value | Cleric (Zealot's penalty) | not yet checked |
| Darkvision SPA | Monk (Badger) | low priority |
| Weapon types vs. §2.1 | both | design question, not source |

---

## Corrections owed to the design vault

1. **[[Monk]] §14a, [[Cleric]] §14a, and the primer's P3.3** — `spellgroup` does not give
   one-at-a-time overwrite. Rewrite around matching effect layout, with SPA 148/446-449 as the
   fallback. The *feature* survives; the *mechanism* named does not.
2. **[[Cleric]] §9e** — the SPA 153 tier curve runs positive→negative, not negative→positive.
3. **[[Monk]] §14c** — Badger's block component is not viable pre-50 (SPA 188 is multiplicative).
