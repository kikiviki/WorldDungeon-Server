# Engine caps reference

**Status:** first pass · branch `feature/p1-cleric-monk`

Hard ceilings the engine applies to bonus and focus values. **Author against these.** The
`0005` cap bug — where every Mk. III ceiling sat above what level 65 could reach, making the
elite chase tier worth 0–7% over the mid tier — is what this file exists to prevent repeating.

Two failure modes it guards against:

- **Authoring above a cap**, where the surplus silently evaporates and a chase item feels flat.
- **Authoring below a reachable ceiling**, where a tier never binds and does nothing at all.

---

## 1. Item stat caps — `common/ruletypes.h`, enforced `zone/bonuses.cpp:238-260, 346-360`

These cap what **worn gear** contributes. They are the ceiling on gear progression.

| Rule | Cap | Notes |
|---|---:|---|
| `ItemHealAmtCap` | ~~250~~ → **1000** | raised by `0013`; a second clamp binds first — see §1a |
| `ItemSpellDmgCap` | ~~250~~ → **1000** | raised by `0013`; same caveat |
| `ItemATKCap` | 250 | **extensible** — `+ itembonuses/spellbonuses/aabonuses.ItemATKCap` |
| `ItemAccuracyCap` | 150 | |
| `ItemExtraDmgCap` | 150 | bonuses to Bash, Frenzy, etc. |
| `ItemAvoidanceCap` | 100 | |
| `ItemCombatEffectsCap` | 100 | proc rate |
| `ItemClairvoyanceCap` | 250 | |
| `ItemDSMitigationCap` | 50 | |
| `ItemShieldingCap` / `SpellShielding` / `DoTShielding` | 35 each | |
| `ItemStunResistCap` / `ItemStrikethroughCap` | 35 each | |
| `ItemDamageShieldCap` | 30 | |
| `ItemHealthRegenCap` | 30 | |
| `ItemManaRegenCap` / `ItemEnduranceRegenCap` | 15 each | |

> 🔴 **`+heal` and `+spell damage` gear stops mattering at 250.** Both are clamped against a bare
> `RuleI(...)` with **no bonus term to raise them** — unlike `ItemATKCap`, which items, spells and
> AA can all extend (`bonuses.cpp:346`). So the entire gear ladder for those two stats must land
> **under 250**, or top-tier gear will read as an upgrade and do nothing.
>
> Note the clamp is `IsOfClientBotMerc()`-gated and applies to **`itembonuses` only** — heal
> amount granted by *spells* or *AA* is not subject to it.

### 1a. 🔴 The item contribution is *also* capped at half the spell's base value

Raised to 1000 by migration `0013`. **But the rule is rarely the binding constraint.**
`Mob::GetExtraSpellAmt()` (`zone/effects.cpp:392`) clamps the contribution to half the spell's
own base:

```cpp
//Confirmed with parsing 10/9/21 ~Kayen
if (extra_spell_amt * 2 > std::abs(base_spell_dmg)) {
    extra_spell_amt = std::abs(base_spell_dmg) / 2;   // hardcoded, not a rule
}
```

And before that it is scaled by **total cast time** (`effects.cpp:383-389`): spells at or under
2.5s receive only **25%** of the stat; longer casts scale toward full value at 7s.

**Worked example.** Intercession Mk. III heals 320 at 65 → the item contribution caps at **160**,
whatever the item says. A 250 heal-amt item already exceeds that, so raising the rule to 1000
changes nothing for today's spell values.

**So the real lever on +heal / +spell-damage gear is the base spell value, not the cap.** An item
can contribute 1000 only against a spell that heals 2000+.

Three ways to make 1000 genuinely reachable, none yet chosen:

| | Approach | Cost |
|---|---|---|
| **(a)** | Raise base spell values | none — all stock balancing intact. **Preferred.** |
| **(b)** | `Spells:FlatItemExtraSpellAmt = true` | one rule; `GetExtraSpellAmt` returns early (`effects.cpp:368`), skipping **both** the cast-time scaling **and** the base/2 clamp. But a fast nuke then gains as much as a long heal. |
| **(c)** | Patch the base/2 clamp in C++ | smallest behavioural change, but it is a stock formula — merge surface. |

### 1b. Order of operations — heal calculation

`Mob::GetActSpellHealing()`, `zone/effects.cpp:421-500`. **Percentages apply to `base_value`, not
to the running total**, so they add rather than compound:

```
base_value = <spell value after level scaling>

value  = base_value
value += base_value × ClericInnateHealFocus%     (5%)
value += base_value × focusImprovedHeal%         (SPA 125)
value += base_value × focusFcAmplifyMod%
value += base_value × focusFcHealPctIncoming%    (SPA 393, on target)
value += focusFcHealAmtCrit                      (SPA 396, flat)
value += GetExtraSpellAmt(...)                   ← ITEM +heal, capped at base/2
value += value × GetHealRate()%                  (SPA 120, on running total)
value *= critical_modifier                       ← CRIT (×2)
value += focusFcHealAmt                          (SPA 392, flat, AFTER crit)
value += focusFcHealAmtIncoming                  (SPA 394, flat, after crit)
```

**Answering the worked question directly:** a 100-heal spell with a 25% focus and +10 item heal
gives **100 + 25 + 10 = 135**. The first model is right — the item bonus is *not* multiplied by
the focus percentage.

Two consequences worth designing around:

- **Percentages are additive against base, not multiplicative with each other.** 25% focus + 5%
  innate = `base × 1.30`, not `base × 1.25 × 1.05`. Predictable, and it means focus stacking
  degrades linearly rather than exploding.
- 🔑 **Item +heal is doubled by crits; SPA 392 is not.** `GetExtraSpellAmt` is added *before*
  `value *= critical_modifier`, while `focusFcHealAmt` (392) is added *after*. So on a crit-heavy
  build, item +heal is worth roughly **twice** the same number delivered via SPA 392.

---

## 2. Focus caps — the important asymmetry

| Focus | Cap | Where |
|---|---|---|
| `focusSpellHaste` (SPA 127, cast time) | 🔴 **50%, hard** | `zone/mob.cpp:5269` |
| `focusManaCost` (SPA 132) | **uncapped** | `zone/effects.cpp:~587` |
| `focusImprovedHeal` (SPA 125) | **uncapped** | `zone/effects.cpp:454` |

```cpp
cast_reducer = std::min(cast_reducer, 50);   // mob.cpp:5269 — applies to the SUM
casttime = casttime * (100 - cast_reducer) / 100;
```

```cpp
cost -= cost * PercentManaReduction / 100;   // effects.cpp — no clamp at all
```

**Cast haste is capped on the summed total**, across item + buff + AA + worn. So the Standard
Mantle's 15% at Mk. III is not free budget — it consumes **30% of the entire class's cast-haste
allowance**, leaving 35% for gear and AA combined. Anything past 50% total is discarded silently.

**Mana cost reduction has no ceiling whatsoever.** Stack enough and spells become free, then
negative. This is the most dangerous lever in the Cleric's kit and the one to watch as gear and
AA are authored — the engine will not stop us.

**Heal focus percentage is uncapped**, which is why the *design* has to impose the discipline. It
is also why moving the mantle to a sustain posture was the right call: an uncapped throughput
percentage stacking with uncapped gear focus has no natural brake.

> ⚠️ **All focus values are flat.** `CalcFocusEffect` assigns raw `base_value` and never routes
> through `CalcSpellEffectValue`, so `formula` is ignored on **every** focus SPA — verified across
> 125, 127, 132, 392, 393, 394, 395, 396, 413. Focus never scales with level. Design accordingly.
>
> **Focus sources SUM**: `return realTotal + realTotal2 + realTotal3 + worneffect_bonus`
> (`zone/spell_effects.cpp:6886`) — item + buff + AA + worn. "Best wins" applies only *within* a
> source.

---

## 3. Haste caps — directly constrains the Monk

| Rule | Cap |
|---|---:|
| `HasteCap` | **100** |
| `Hastev3Cap` | **25** |

> 🔴 **This binds Hummingbird.** The Monk's overhaste stance uses **SPA 119 `AttackSpeed3`**,
> which is v3 haste — capped at **25%**. Authoring Hummingbird Mk. III at, say, 40% overhaste
> would silently deliver 25%, making Mk. II and Mk. III indistinguishable — the exact `0005`
> failure again, in a different subsystem.
>
> **Budget Hummingbird's three tiers inside 0–25.** Suggest 10 / 18 / 25.

---

## 4. Level-scaling formulas — the reachability rule

`formula` on ordinary (non-focus) effects, `Mob::CalcSpellEffectValue_formula`
(`zone/spell_effects.cpp:3517`):

| `formula` | Value | Raw at level 65 |
|---:|---|---|
| 100 / 0 | `base` | `base` |
| 101 | `base + level/2` | `base + 32` |
| 102 | `base + level` | `base + 65` |
| 103 | `base + level×2` | `base + 130` |
| 104 | `base + level×3` | `base + 195` |
| 105 | `base + level×4` | `base + 260` |
| `< 100` | `base + level×formula` | `base + 65×formula` |

`max` clamps the result (`zone/spell_effects.cpp:~3814`).

> ### 🔑 The reachability rule
>
> **A `max` above the raw value at max level does nothing.** With `formula 105`, anything above
> `base + 260` is inert at level 65.
>
> **Set caps as a fraction of the reachable range**, so each tier binds at a chosen level. The
> convention adopted in `0005`:
>
> | Tier | Cap | Fills at |
> |---|---|---|
> | Mk. I | `base + 120` | L30 |
> | Mk. II | `base + 200` | L50 |
> | Mk. III | `base + 260` | L65 |
>
> Yields roughly **+40%** Mk. I→II and **+22%** Mk. II→III at level 65. Each tier extends the
> scaling window rather than sitting inert.

---

## 5. Audit of the unapplied migrations — 59 inert caps found

Run by loading `0005`/`0006`/`0007`/`0009` into a scratch database and testing each damage/heal
slot against the reachable value at level 65. **Method matters here:** a first attempt with a
regex over the SQL text produced ~185 false positives, because it mis-handled negative bases and
matched effect-id/parameter triples that are not value triples at all. `updownsign` is `-1` when
`max < base` (`zone/spell_effects.cpp:3569`), so damage spells clamp on **magnitude** — a naive
comparison is meaningless. Audit against a loaded table, per slot, not against the text.

| Migration | Inert caps |
|---|---:|
| `0005` Cleric | 3 *(remaining after the formula-105 fix; these are the `formula 102` lines)* |
| `0006` Wizard | **22** |
| `0007` Wizard riders | 4 |
| `0009` Necromancer | **30** |
| **Total** | **59** |

**Worst case — Meteor.** All three tiers have `base -120, formula 105`, so raw magnitude at 65 is
380, against caps of 450 / 750 / 1100:

| | cap | delivered @65 |
|---|---:|---:|
| Meteor Mk. I | 450 | **380** |
| Meteor Mk. II | 750 | **380** |
| Meteor Mk. III | 1100 | **380** |

**All three tiers are identical at max level.** Asteroid is the same. Fire Burst and Ice Burst
Mk. II/III likewise collapse together, as do both Shower lines and the Lure lines. For the
Wizard, the tier system currently does nothing at all on its headline nukes.

Remaining checks before applying:
- [x] ~~Cap reachability~~ — **done, 59 found.** Retune before applying.
- [ ] **Nuke damage** vs `ItemSpellDmgCap` 250 on the gear side of the equation.
- [ ] **Any SPA 127** against the 50% shared cast-haste ceiling.
- [ ] **Any SPA 119** against `Hastev3Cap` 25.
- [ ] **Mana-cost reduction** totals — uncapped, so nothing will warn us.

---

## Open

- Damage focus (`focusImprovedDamage`, SPA 124/`ImprovedDamage2`) cap — not yet checked; relevant
  to the Wizard.
- Crit chance / crit damage caps — not yet checked.
- Resist caps — relevant to `Combat Balance Envelope` §11.8 and W11.
- Buff slot counts (`MaxBuffSlotsNPC` 60) vs the number of simultaneous WD buffs a Cleric expects
  to maintain.
