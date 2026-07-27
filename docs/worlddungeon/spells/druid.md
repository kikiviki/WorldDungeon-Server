# Druid — Spell Design

**Class id 6 · band 43,180–43,299 · spellgroups 506,000+**

Source: vault `04 Class Identities/Druid.md` §9a–§9d and §14. Native specialty: **"over time" —
ramping DoTs plus spreading DoTs**, tier advantage **+2**.

Everything the Druid does is over time, on both sides of the fight. He has **deliberately no big
direct heals** — that's not an omission to fill in later, it is the design. Don't author them.

---

## 1. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a — The spread engine (5)

The only genuinely bespoke system in the class, and **W9** on the backlog.

A spreading DoT is a **two-part debuff from a single cast**. The spreading component deals a small
flat "spread tick" (1 damage per spell tier, per tick), and **every tick** scans for up to X
already-aggro'd enemies within `radius(tier)`, rolls `spread_chance(tier)`, and on success applies
itself to the new target **copying its own remaining duration** — plus the payload damage DoT of
the same tier.

| # | base | Spell | Role | Scaling | Dep. |
|---|---|---|---|---|---|
| 1 ⭐ | 43,180 | **Creeping Blight** | the spreading carrier — radius, spread %, duration all tier | max↑ | **W9** |
| 2 | 43,183 | **Rot** | the payload damage DoT applied on each spread | max↑ | — |
| 3 | 43,186 | **Choking Vines** | second spreading line — slower spread, higher payload | max↑ | **W9** |
| 4 | 43,189 | **Strangleroot** | Choking Vines' payload DoT | max↑ | — |
| 5 | 43,192 | **Bloom** | **detonator** — resolves remaining ticks across every infected target at once, then strips | max↑ | **W1** |

> ⭐ **The signature ability is spell 1** — one cast that visibly creeps across an entire pack on
> its own.

**Bloom is what makes the engine feel good** and it is data-only once the debuff exists. SPA 374
trigger with a Limit checking the spreading debuff's spellgroup; because the state lives as a
debuff on each mob, "every infected target" is just an AE filtered on the debuff — **no central
registry needed.** Strips the debuff, yields ~85–90% of remaining tick damage per A2.

> **Design note worth preserving:** Bloom converts the spread engine's runaway-control limits
> (spread cap X, max infected) from pure restrictions into a **target the player wants to
> maximise** — you want maximum infection *before* you Bloom. Same numbers, opposite psychology.

**Recommended spread rules**, per vault §14a: already-infected targets are **skipped, not
refreshed** — refreshing creates an effectively permanent pack-wide DoT and makes duration
meaningless. Spread **cannot re-infect the origin** (explicit loop guard). Cap total infected per
cast, not just per tick. **Scan the aggro list, not the zone entity list** — the "already
aggro'd" requirement is a performance feature as much as a design one. Tick on the DoT's existing
tick, never a separate timer.

### §9a — Ramping DoTs (4)

"Per-tick damage grows the longer it persists" has no obvious stock SPA. **Option 1 is
recommended**: the DoT applies a stacking "ramp" buff whose count multiplies damage via a
Limit-focused rider. Data-only, and the ramp is **visible to the player as a stack count** —
which is the point of the mechanic, since it gives him something to protect.

| # | base | Spell | Flavour | Scaling | Dep. |
|---|---|---|---|---|---|
| 6 | 43,195 | **Withering Curse** | ramping, magic | max↑ | — |
| 7 | 43,198 | **Immolating Bloom** | ramping, fire | max↑ | — |
| 8 | 43,201 | **Winter's Grasp** | ramping, cold + minor snare rider | max↑ | — |
| 9 | 43,204 | **Blight of the Grove** | AE seed — ramps slower, hits everything in radius | max↑ | — |

Target death **resets** the ramp — automatic under option 1, since the stack is per-target state.

### §9b — Over-time healing: regen (4)

Sustained HP/tick buffs. **Each tier raises per-tick potency** — early regen heals ~**10 HP/tick,
not the vanilla ~4**.

| # | base | Spell | Target | Ratio | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 10 | 43,207 | **Verdant Renewal** | single | baseline | max↑ | — |
| 11 | 43,210 | **Communal Renewal** | group | **≈ ⅓ of single, per tick, at every tier** | max↑ | W2 |
| 12 | 43,213 | **Rootbound Vigour** | single | regen + minor HP buff rider | max↑ | — |
| 13 | 43,216 | **Grove's Embrace** | group | regen + minor mana regen rider | max↑ | W2 |

> ⚠️ **Single-target and group regen must STACK on the same player.** They are separate buffs, not
> exclusive. This needs **separate spellgroups** and possibly a stacking exemption — and per
> P1-SOURCE-VERIFICATION §1 exclusivity actually comes from **matching effect layout**, so the
> two lines must be given **deliberately different slot layouts** to avoid overwriting. This is
> the one place EQ's buff rules might fight the design; verify it early.

The ⅓ ratio is a value held in the data across all tiers, not a mechanism. It lets him choose
spread coverage (group) vs. focused throughput (single, 3× the group tick).

### §9b — HoTs (4)

Short-duration **4–6 tick** heal-over-time — the burst-replacement. High healing packed into a
short window instead of an instant.

| # | base | Spell | Target | Ticks | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 14 | 43,219 | **Quickening Sap** | single | 4–6, high per-tick | max↑ | — |
| 15 | 43,222 | **Communal Sap** | group | 4–6 | max↑ | W2 |
| 16 | 43,225 | **Surge of Life** | single | 3, very high per-tick, short CD | max↑ | — |
| 17 | 43,228 | **Everbloom** | single | long, low per-tick, no CD — the efficient one | max↑ | — |

Extended by **SPA 128** (duration) via AA, amplified by **SPA 125** (healing) via AA and gear.

### §9c — Damage shields (5)

**SPA 59**, but the Druid variant is **short-term or hit-limited and high-magnitude** — the
contrast with the Magician's long-term low-magnitude "set and forget" version is deliberate and
is what keeps two DS classes from feeling the same. His DS is part of his active reactive kit,
like the HoT.

| # | base | Spell | Shape | Rider | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 18 | 43,231 | **Thornskin** | short duration, high magnitude | — | max↑ | — |
| 19 | 43,234 | **Bramblehide** | short duration | + SPA **162** mitigation while active | max↑ | — |
| 20 | 43,237 | **Barkward** | hit-limited ⚠️ | + SPA **172** avoidance while active | max↑ | ⚠️ |
| 21 | 43,240 | **Nettleburst** | short duration | **bonus on fade** — SPA **373** | max↑ | ⚠️ 373 |
| 22 | 43,243 | **Communal Thorns** | group, lower magnitude | — | max↑ | W2 |

⚠️ **Whether SPA 59 supports a hit counter** is unverified — if not, 20 becomes a short-duration
variant instead. ⚠️ **SPA 373 cast-on-fade** is the same shared verification the Paladin and
Shaman wards need.

### Nukes, utility, ports (8)

Secondary by design — the DoT engine is the identity.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 23 | 43,246 | **Sunstrike** | minor fire DD, fast | 0 | max↑ | — |
| 24 | 43,249 | **Winterblast** | minor cold DD | 0 | max↑ | — |
| 25 | 43,252 | **Ensnare** | snare — keeps the pack in spread radius | **3** neg | flat% | — |
| 26 | 43,255 | **Entangling Roots** | root | 3 / root | flat% | — |
| 27 | 43,258 | **Skin like Wood** | self AC + HP buff | **1**, 69 | max↑ | — |
| 28 | 43,261 | **Spirit of the Wolf** | group run speed | **3** | flat% | W2 |
| 29 | 43,264 | **Wayfarer's Passage** | attunement-gated port, ranks = destinations | **104** | — | script |
| 30 | 43,267 | **Succor** | emergency exit for self + group | **88**/104 | — | script |

25 is the highest-value utility spell he has: **spread depends on the pack staying clustered and
aggro'd.** Snare is not a side tool for this class, it's spread uptime.

29/30 are **shared with the Wizard** — one attunement system, built once.

---

## 2. Payload spells — 43,270–43,299

| id | Payload | Parent |
|---|---|---|
| 43,270 | Spread-tick carrier payload | 1 |
| 43,271 | Choking Vines spread-tick carrier | 3 |
| 43,272 | Bloom detonation damage | 5 |
| 43,273–43,275 | ramp stack buffs (one per ramping line) | 6–8 |
| 43,276 | Nettleburst on-fade bonus | 21 |
| 43,277 | Barkward avoidance rider | 20 |
| 43,278–43,299 | *unallocated* | |

---

## 3. Spellgroup allocation

| Group | Line |
|---|---|
| 506,001 | `dru_spread_blight` — **the group Bloom's Limit names** |
| 506,002 | `dru_spread_vines` |
| 506,003–506,004 | payload DoT lines |
| 506,005 | `dru_bloom` |
| 506,010–506,013 | ramping DoT lines |
| **506,020** | `dru_regen_st` — ⚠️ **must not share a layout with 506,021** |
| **506,021** | `dru_regen_grp` |
| 506,022–506,023 | regen variant lines |
| 506,030–506,033 | HoT lines |
| 506,040–506,044 | damage shield lines |
| 506,050–506,057 | nukes, utility, ports |

---

## 4. Build order

Per vault §14h — and note that the *playable* Druid arrives well before the engine work:

1. **Regen, HoTs, DS (10–22)** — data-only, and it makes him playable while the spread engine is
   built.
2. **Ramping DoTs (6–9)** via the stacked-buff approach — data-only.
3. **Utility and ports (23–30)** — data-only.
4. **W9, the spread engine (1, 3)** — the big one. Budget the per-tick scan carefully.
5. **Bloom (5)** immediately after — data-only once the debuff exists, and it's what makes the
   engine *feel* good.

---

## 5. Open items

- [ ] **Do ST and group regen stack cleanly in EQEmu buff slots** without overwriting? *(The one
      real risk to the healing design.)*
- [ ] **SPA 373 cast-on-fade** — shared with Paladin and Shaman.
- [ ] Whether **SPA 59 supports a hit-count limit** (decides spell 20's shape).
- [ ] **Per-tick scan cost** with many infected mobs — profile before committing to cap values.
      This is the one item on the whole board with real performance-budget risk.
- [ ] Whether "already aggro'd" means aggro on *the druid* or *any player* — recommend **any
      player**: cheaper to evaluate and duo-friendly.
- [ ] Spread cap X per tick and max total infected per cast.
- [ ] Ramp curve — linear vs. accelerating.
- [ ] Regen per-tier potency table (base ~10/tick single) and where it caps.
- [ ] Confirm weapon types vs. §2.1.
