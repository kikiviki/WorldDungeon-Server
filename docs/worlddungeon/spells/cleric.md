# Cleric — Spell Design

**Class id 2 · band 42,700–42,819 · spellgroups 502,000+ (legacy 500,001–500,004)**

Source: vault `04 Class Identities/Cleric.md` §9a–§9f and §14. Native specialty: **primary
healing + best HP buffs + defensive procs + deity worship**, tier advantage **+2**.

Per vault §14.0 the Cleric needs **essentially zero custom C++** — his entire cost is data
authoring plus W2 (ally-target expansion) for solo viability. That is why he is built first.

---

## 0. What already exists

Migration `0004` is **applied and immutable**. It authored:

| ids | Rows |
|---|---|
| 42,700–42,708 | Zealot's / Standard / Warden's Mantle, Mk. I/II/III |
| 42,710–42,712 | their proc payloads (Zealous Retribution, Standard Absolution, Warden's Bulwark) |

Those nine mantles are **spells 1–3** below and are *not* re-authored. The 27 remaining spells
start at **42,713**, which deliberately runs the mantle procs and the new lines together in the
low band rather than renumbering anything. Payload sub-band starts at 42,790 as normal.

> ⚠️ The mantles are **untested in a running zone.** The step-3 gate in `0004`'s header — casting
> *Zealot Mk. I* while *Standard Mk. III* is active — must pass before anything below is authored.
> It is the SPA 149 rider proving it overrides the engine's normal "reject the weaker spell"
> behaviour.

---

## 1. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a — Religious mantles (3) · *already authored*

Layout family `clr_mantle`, spellgroup **500,001**. All three carry the identical 12-slot layout
(the precondition for clean overwrite): 125 heal focus · 132 mana cost · 220 melee damage ·
177 double attack · 323 own proc · 149 swap rider.

| # | base | Spell | Composition | Scaling | Dep. |
|---|---|---|---|---|---|
| 1 | 42,700 | **Zealot's Mantle** | 125 heal focus **−20/−15/−10** · 220 melee dmg 15/35/60 · 177 double attack 5/12/20 · proc *Zealous Retribution* | flat% | — |
| 2 | 42,703 | **Standard Mantle** | 125 heal focus +15/+28/+45 · 132 mana cost 5/11/18 · proc *Standard Absolution* | flat% | — |
| 3 | 42,706 | **Warden's Mantle** | 125 heal focus +5/+9/+14 · proc *Warden's Bulwark* at 250/400/600 rate | flat% | — |

Note the Zealot's heal focus is **negative and gets less negative** as it tiers — the tradeoff
shrinks rather than the bonus growing. ⚠️ Open: focus effects select one best/worst, they don't
sum, so this will not simply add to a heal-focus AA. Needs a design pass before final numbers.

### §9d — The four heal lines (8)

The **design contract is the field values**. Efficiency is literally the `mana` ratio between
rows; there is no mechanism here at all.

| # | base | Spell | Target | Cast | Recast | Mana | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|---|---|---|
| 4 | 42,713 | **Intercession** | single | 0 | short CD | **high** | 0 | max↑ | — |
| 5 | 42,716 | **Ward of the Fold** | group | 0 | short CD | **high** | 0 | max↑ | W2 |
| 6 | 42,719 | **Mending Light** | single | real | 0 | **low** | 0 | max↑ | — |
| 7 | 42,722 | **Communal Light** | group | real | 0 | **low** | 0 | max↑ | W2 |
| 8 | 42,725 | **Reclamation** | single | long | long CD | very high | **101** CompleteHeal | max↑ | — |
| 9 | 42,728 | **Sacrament** | single | real | 0 | low | 0 (duration) + 128 | max↑ | — |
| 10 | 42,731 | **Sacrament of the Fold** | group | real | 0 | low | 0 (duration) | max↑ | W2 |
| 11 | 42,734 | **Deathward** | single | 0 | long CD | high | **150** DeathSave | flat% | — |

4–7 are the four-line model exactly. 8 is the once-a-fight full heal that gives the line a top
end. 9–10 are the sustain HoT texture the vault gives him under §9d's "pre-cast and anticipate"
contract. 11 is the *divine intervention–style save* listed in §14g's activated-AA column,
authored as a spell so it competes for a gem.

**Instant CDs and slow cast times are the tuning surface.** AAs shave cast via SPA 127 and CD via
SPA 227 — vault §14d confirms both are native, answering his §13 question.

**Solo form (D1):** group heals need a self-recourse cast with no allies. W2 makes pets and
temp-allies valid targets, which covers most cases.

### §9c — Deity worship (4)

Four gods per **E9**. Each is its own spellgroup, and per vault §14c the recommendation is **all
four accessible at rank 5, only one specializable to 10** — reusing D2 rather than inventing a
devotion-lock.

| # | base | Spell | God | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 12 | 42,737 | **Wrath of the Warlord** | Rallos | AoE DD + stun — his only real pack answer | 0 (AE), **21** | max↑ | — |
| 13 | 42,740 | **Tides of Prexus** | Prexus | group cure / cleanse | **27**, counter removal | max↑ | W2 |
| 14 | 42,743 | **Growth of Tunare** | Tunare | group heal over time | 0 (duration) | max↑ | W2 |
| 15 | 42,746 | **Fire of Solusek Ro** | Solusek Ro | group spell-haste — works on himself solo | **127** | flat% | W2 |

Spellgroups 502,010–502,013.

⚠️ Prexus's counter-removal must be checked against the **Necromancer's** counter SPAs (35 disease
/ 36 poison / 116 curse) so a cleanse doesn't accidentally strip an ally-cast effect. Flagged in
the Necro doc too.

### §9b — Defensive procs (4)

SPA **323** on a self or group buff; the proc payload is either SPA 0 (heal % of damage taken) or
SPA 162 (mitigate melee). **Both variants ship** — different spellgroups keep them from
overwriting. Amplified by Warden's Mantle.

| # | base | Spell | Target | Proc payload | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 16 | 42,749 | **Faithful Recompense** | self | 323 → SPA 0, heal % of damage taken | flat% | — |
| 17 | 42,752 | **Aegis of the Faithful** | group | 323 → SPA 0, heal % of damage taken | flat% | W2 |
| 18 | 42,755 | **Stonefaith** | self | 323 → SPA 162, mitigate melee | flat% | — |
| 19 | 42,758 | **Communal Stonefaith** | group | 323 → SPA 162, mitigate melee | flat% | W2 |

**Stacking with Shaman wards is a non-issue** — 323 procs and 55/78 runes are different SPA
families, so they stack natively. Vault §14b confirms that's intended: the Cleric is proactive
mitigation, the Shaman is absorb. No stacking-blocker needed.

### HP buffs (4)

His best-in-game line. Vault §14h verified the SPA split: **69 `TotalHP` is flat, 214
`MaxHPChange` is a percentage** (`zone/bonuses.cpp:727,786`), both additive within their kind.

| # | base | Spell | Target | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 20 | 42,761 | **Symbol of the Divine** | single | **69** flat HP | max↑ | — |
| 21 | 42,764 | **Communal Symbol** | group | **69** flat HP | max↑ | W2 |
| 22 | 42,767 | **Vessel of Faith** | single | **214** % max HP | flat% | — |
| 23 | 42,770 | **Communal Vessel** | group | **214** % max HP | flat% | W2 |

Use 69 for the baseline buff and 214 for percentage scaling. The 69 line is what makes every
other heal in the game work against a bigger pool — that's the "+2 in HP buffs" made concrete.

### §9e — Health balancing (2)

**SPA 153 is exactly this ability**, already in the engine.

> ⚠️ **The sign is inverted from vault §9e.** In `Group::BalanceHP()` (`zone/groups.cpp:1352`)
> `base_value` is a **penalty** — it inflates the damage spread around. **Positive makes it
> worse; negative is the bonus.** §9e describes low tiers at −30% and high tiers at +30%. That is
> backwards. **The tier curve must run positive at Mk. I → negative at Mk. III.** Authored
> literally the line would degrade as it ranks up.

| # | base | Spell | Target | SPAs | Mk. I → II → III | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 24 | 42,773 | **Divine Equilibrium** | group | **153** | base_value **+30 → 0 → −30** | flat% | W2 |
| 25 | 42,776 | **Covenant of Blood** | self | 0 + **15** — HP↔mana convert | | max↑ | — |

Two free properties worth using on 24: `limit_value` **caps the damage counted per member** (a
safety valve so one near-dead member can't drag the group down), and **it cannot kill** — members
floor at 1 HP. `range` defaults to 200 if unset. It balances to the **average damage taken in
absolute HP**, not a ratio — so a plate cleric next to a cloth caster end at different
percentages, which is worth knowing.

25 is the **D1 solo form** per C10.2: balancing alone does nothing, so the solo job is a different
one. HP↔mana conversion is thematically adjacent and genuinely useful to a soloing cleric.

### §9f — Divine smite (5)

Promoted to **class baseline** per **C10.3** — under D1 a solo engine isn't optional.

**SPA 0 direct damage, `resisttype` = magic**, deliberately not fire or cold so it dodges the
elemental resist gates. The heal recourse uses `spells_new`'s native **recourse** field: the
smite casts a party-heal spell on success. Stock behaviour, no code.

| # | base | Spell | Cadence | Recourse | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 26 ⭐ | 42,779 | **Divine Smite** | fast filler | party heal, on-hit chance | max↑ | W2 |
| 27 | 42,782 | **Censure** | long cast, big | party heal, larger, lower chance | max↑ | W2 |
| 28 | 42,785 | **Rebuke** | AE, small | party heal | max↑ | W2 |
| 29 | 42,788 | **Zealot's Reproach** | melee-range, gated on Zealot's Mantle | party heal | max↑ | W1 |
| 30 | 42,791 | **Sanctified Ground** | self, pulsing PBAE damage + group HoT | — | max↑ | W2 |

> ⭐ **The signature ability.** Vault §14f's recommendation stands: make 26 a **fast-cast filler,
> not a big nuke.** Recourse *frequency* is what makes the loop feel good, and frequency beats
> magnitude for that. 27 exists as the alternative for players who want the big number.

29 is the one Cleric spell that needs **W1** — it's gated on his own Zealot's Mantle being up,
which is the same "target has a buff in spellgroup N" restriction, pointed at self.

⚠️ Open: **whether the recourse field fires on partial resist.** If it doesn't, the smite loop
feels much worse against resistant targets and 26's cast time should drop further to compensate.

> **ID note:** spell 30 at 42,791 crosses into the payload sub-band by one row. Either move the
> payload floor to 42,794 for this class or drop spell 30. Recommend the former — 30 is a real
> ability and the Cleric's payload needs are small.

---

## 2. Payload spells — 42,794–42,819

Not player-facing. One payload serves all three Mk. tiers, with the parent's slot value carrying
the scaling (the pattern `0004` already uses at 42,710–42,712).

| id | Payload | Parent |
|---|---|---|
| 42,710–42,712 | *existing* — Zealous Retribution / Standard Absolution / Warden's Bulwark | mantles |
| 42,794 | Heal-on-damage-taken proc | 16, 17 |
| 42,795 | Mitigate-melee proc | 18, 19 |
| 42,796 | Smite party-heal recourse — **small** | 26, 28, 29 |
| 42,797 | Smite party-heal recourse — **large** | 27 |
| 42,798 | Sanctified Ground pulse damage | 30 |
| 42,799 | Sanctified Ground group HoT | 30 |
| 42,800 | ~~Deathward save payload~~ — **not needed**: SPA 150 carries its heal amount in its own `max` field (`zone/bonuses.cpp:2692`). Id stays reserved. | 11 |
| 42,801–42,819 | *unallocated* | |

---

## 3. Spellgroup allocation

| Group | Line |
|---|---|
| **500,001** | `clr_mantle` — layout family *(legacy)* |
| **500,002–500,004** | mantle proc lines *(legacy)* |
| 502,001 | `clr_heal_instant_st` |
| 502,002 | `clr_heal_instant_grp` |
| 502,003 | `clr_heal_slow_st` |
| 502,004 | `clr_heal_slow_grp` |
| 502,005 | `clr_heal_complete` |
| 502,006 | `clr_hot_st` |
| 502,007 | `clr_hot_grp` |
| 502,008 | `clr_deathsave` |
| 502,010–502,013 | `clr_worship_rallos` / `_prexus` / `_tunare` / `_solro` |
| 502,020–502,023 | `clr_defproc_heal_st` / `_grp`, `clr_defproc_mit_st` / `_grp` |
| 502,030–502,033 | `clr_hp_flat_st` / `_grp`, `clr_hp_pct_st` / `_grp` |
| 502,040 | `clr_balance` |
| 502,041 | `clr_convert` |
| 502,050–502,054 | smite lines |

Per **P1-SOURCE-VERIFICATION §1**, `spellgroup` does **not** drive buff stacking —
`Mob::CheckStackConflict()` (`zone/spells.cpp:3069`) keys on spell id then on effect ids and slot
positions. Spellgroups are still required for scribing ranks and focus limiters; they just do
nothing for exclusivity. **Exclusivity comes from matching effect layout**, plus SPA 149 wherever
parallel tiered lines must swap in both directions.

---

## 4. Build order

Per vault §14h, and unchanged:

1. 🔴 **Run the `0004` test matrix.** Nothing below is authored until step 3 passes.
2. ✅ **Heal lines (4–11)** — authored as migration `0005_cleric_heal_lines.sql`, unapplied
   pending the `0004` gate. Formula 105 + rising `max` (HoTs 102); Reclamation tiers recast,
   Deathward tiers restored HP.
3. **HP buffs (20–23)** — biggest downstream leverage, trivially cheap.
4. **Smite + recourse (26–30)** — remembering C10.3 promoted it to baseline.
5. **Defensive procs (16–19)**, then **worship (12–15)**, then **balance (24–25)** — remembering
   SPA 153's inverted sign.

Only external dependency is **W2**. Nine of the thirty spells want it; none of them are blocked
from *authoring* by it, only from being good solo.

---

## 5. Open items

- [ ] **The `0004` gate** — SPA 149 overriding weaker-spell rejection, in a running zone.
- [ ] Whether the recourse field fires on **partial resist** (spell 26's whole loop).
- [ ] Confirm **SPA 125 accepts a negative value** for Zealot's penalty.
- [ ] Focus effects select best/worst rather than summing — resolve before mantle numbers are
      final.
- [ ] Prexus cleanse vs. Necromancer counter SPAs (35/36/116) — unintended cure interactions.
- [ ] Exact efficiency gap between instant and slow heals; instant CD lengths; slow cast times.
- [ ] `not_focusable` column still unidentified — find it before authoring any non-focusable spell.
- [ ] Confirm weapon types (blunt) vs. §2.1.
