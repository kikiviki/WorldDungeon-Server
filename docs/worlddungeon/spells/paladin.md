# Paladin — Spell Design

**Class id 3 · band 42,820–42,939 · spellgroups 503,000+**

Source: vault `04 Class Identities/Paladin.md` §9 and §14. Native specialty: **ward-explosion
retribution — absorb damage, then emit a % of it back as AoE**, tier advantage **+2**.

Undead specialty is **removed world-wide**. His identity is *taking the hit and giving it back
tenfold*, and shielding the people beside him. Where the Shadowknight sustains *himself*, the
Paladin sustains *the party*.

---

## 1. The retribution ward

**The marquee mechanic is one hook site plus three data rows.** It decomposes into:

1. **SPA 55 (Rune)** — flat melee absorb until depleted. Already exactly the "absorbs up to X
   damage" half.
2. **W4 accumulator** — the *only* missing piece. EQ decrements the rune but never records how
   much it ate. Hook `Mob::ReduceDamage()` (where SPA 55 already decrements) and write the delta
   to the buff slot. Shared with Shadowknight, Warrior and Rogue.
3. **SPA 373 (Cast on Fade)** ⚠️ — fires the detonation when the ward expires **or** breaks. The
   design wants both.
4. **Detonation spell** — SPA 0, AE targettype, magnitude read from the accumulator.

### Ward X — locked numbers

Derived in Class Pass 1 §F against Mob Scaling §4.1:

> ### **X = 2 × the tier's mob max hit**

| Tier | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10 |
|---|---|---|---|---|---|---|---|---|---|---|
| **Ward X** | 80 | 180 | 360 | 680 | 1,200 | 2,000 | 3,600 | 6,400 | 11,600 | 21,000 |

Because X is a **formula on the §4.1 max-hit column** it auto-follows any mob retune and never
needs re-deriving.

- **Duration:** 2 ticks (12s) — `buffduration` = 2.
- **Recast:** ~20s → ~60% uptime *(tune)*.
- **Detonation %:** 40% at Mk. I → ~75% at Mk. III.
- **Bastion interaction:** the surrounded-bonus path raises **X per nearby enemy**, *not* the
  detonation %. Raising % would double-dip with Bulwark's own scaling.

Sanity check at T6: full fill = 2,000 stored; at 40% → 800 AE **per target**; against the 3-pack
that filled it, ~2,400 effective vs. his ~2,200 melee over the same window. **The ward roughly
matches melee at Mk. I, exceeds it at Mk. III, and is worth nothing if he isn't being hit.**
Correct shape.

At X = 2× max hit the ward **cannot fill against a single mob** — which is deliberate, and is what
keeps it a pack tool. It needs no solo form; it just fills slower.

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### The ward family (6)

| # | base | Spell | Shape | Scaling | Dep. |
|---|---|---|---|---|---|
| 1 ⭐ | 42,820 | **Bulwark of Retribution** | X = 2× max hit, 2 ticks, detonates on fade **or** break | max↑ | **W4**, ⚠️ 373 |
| 2 | 42,823 | **Bulwark of the Vigilant** | half X, 4 ticks — the smaller-cap-longer branch | max↑ | **W4**, ⚠️ 373 |
| 3 | 42,826 | **Wrathful Bulwark** | X unchanged, higher detonation %, longer recast | max↑ | **W4**, ⚠️ 373 |
| 4 | 42,829 | **Shielding Light** | group ward, low X, no detonation — pure protection | max↑ | W2 |
| 5 | 42,832 | **Steadfast Aura** | **pulsing absorb self-buff** — long buff re-applying a short SPA 162 child | flat% | ⚠️ 374 |
| 6 | 42,835 | **Communal Steadfast** | group pulsing absorb, lower % | flat% | ⚠️ 374, W2 |

> ⭐ **The signature ability is spell 1** — soak a pack's damage, then blow it back across all of
> them.

Vault §13 asked whether ward duration scales or branches. **It branches** — 1 is the
bigger-cap-shorter version, 2 the smaller-cap-longer one. That gives the player a real read on the
fight rather than a single dial.

**5/6 stack natively with 1–3** and need no blocker: the pulsing absorb uses **SPA 162 (%
mitigation)** while the burst ward uses **SPA 55 (flat rune)** — different SPAs. That's also the
right design answer: percentage smoothing under flat spike-eating is exactly the two-layer
identity.

### AoE stuns (5)

SPA **21** with AE `targettype`. Stock.

| # | base | Spell | Shape | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 7 | 42,838 | **Rebuking Light** | ST stun, fast | **21** | max↑ | — |
| 8 | 42,841 | **Divine Reproach** | AE stun, radius | **21** (AE) | max↑ | — |
| 9 | 42,844 | **Halt the Wicked** | AE stun, longer, longer recast | **21** (AE) | max↑ | — |
| 10 | 42,847 | **Stunning Blow** | stun + damage, melee-range | **21**, 0 | max↑ | — |
| 11 | 42,850 | **Blinding Radiance** | AE blind — the alternative pack answer | **20** (AE) | flat% | — |

⚠️ **Stun immunity and diminishing returns on repeated AE stuns** are unverified, and *Bastion*
wants a pack-wide stun cadence. If DR is aggressive, 8/9 need longer durations rather than
shorter recasts.

### Party heal-procs (5)

**SPA 85** (add melee proc) where the proc spell is a group heal. **% of hit rather than flat** —
flat procs decouple from his gear progression and go stale; % keeps them scaling per §8.1 for
free. Under D1/W2 these must reach pets and temp-allies; with nothing at all in range the proc
converts to **self-heal at reduced value**.

| # | base | Spell | Proc payload | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 12 | 42,853 | **Hand of Conviction** | group heal, % of hit | **85** | flat% | W2 |
| 13 | 42,856 | **Hand of Mercy** | group heal, larger, lower rate | **85** | flat% | W2 |
| 14 | 42,859 | **Hand of the Watchful** | group **cure** proc | **85** → **27** | flat% | W2 |
| 15 | 42,862 | **Hand of Wrath** | damage proc + small group heal | **85** | flat% | W2 |
| 16 | 42,865 | **Consecrated Blade** | raises the proc **rate** of all of the above | **200** ProcChance | flat% | — |

### Stances (3) — *new per E11*

One spellgroup (`pal_stance`), equal rank, native overwrite. This gives his existing 2H-vs-shield
fork an actual mechanic.

| # | base | Spell | Composition | Scaling | Dep. |
|---|---|---|---|---|---|
| 17 | 42,868 | **Shield of Faith** | **162** mitigation ↑, block ⚠️, **ward fill-rate ↑** (accumulator multiplier) | flat% | **W4** |
| 18 | 42,871 | **Sword of Faith** | **185** 2H damage ↑, **169** crit ↑, **detonation % ↑** | flat% | **W4** |
| 19 | 42,874 | **Beacon** | **85** party heal-proc rate ↑, **185** personal damage ↓ | flat% | — |

> **17 and 18 modify the ward from opposite ends** — one fills it faster, one detonates it
> harder. That's a real choice rather than a stat swap, and it's the best structural idea in the
> class.

⚠️ Note **SPA 188 `IncreaseBlockChance` is multiplicative on block skill** and buys ~4 percentage
points at skill 0 (S3). Do not author 17's block component expecting it to matter pre-50 — that
decision belongs to **W11**.

### Party support (6)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 20 | 42,877 | **Cleansing Light** | group cure / cleanse | **27** | max↑ | W2 |
| 21 | 42,880 | **Oath of Protection** | group AC + mitigation buff | **1**, **162** | max↑ | W2 |
| 22 | 42,883 | **Valorous Presence** | group HP buff — below Cleric magnitude | **69** | max↑ | W2 |
| 23 | 42,886 | **Lay Hands** | single huge heal, very long recast — the classic | **101** | max↑ | — |
| 24 | 42,889 | **Sacrifice of the Bound** | redirect a % of an ally's incoming damage to himself | **W8**-adjacent ⚠️ | flat% | ⚠️ |
| 25 | 42,892 | **Marked for Protection** | ally buff — his heal-procs prioritise this target | targeting rider | flat% | W2 |

24 is proposed against the **W8 damage-redirection** work that the Warrior owns. If W8 slips it
should be cut rather than reimplemented — flag, don't duplicate.

### Threat and self-sustain (5)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 26 | 42,895 | **Righteous Provocation** | AE taunt | **206** | max↑ | — |
| 27 | 42,898 | **Undying Conviction** | hate over time | **192** | max↑ | — |
| 28 | 42,901 | **Zeal** | self hate multiplier + mitigation | **114**, **162** | flat% | — |
| 29 | 42,904 | **Penitent Flame** | self damage shield — retribution texture | **59** | max↑ | — |
| 30 | 42,907 | **Renewal of Faith** | modest self heal-over-time — his only real self-sustain | 0 (duration) | max↑ | — |

30 is deliberately modest. **Lower raw self-sustain than the SK is a designed weakness** — he
protects the party and has no lifetap bailout if procs and heals fall behind.

---

## 3. Payload spells — 42,910–42,939

| id | Payload | Parent |
|---|---|---|
| 42,910 | Ward detonation AE — magnitude read from the accumulator | 1, 2, 3 |
| 42,911 | Pulsing absorb child buff (SPA 162, short) | 5 |
| 42,912 | Group pulsing absorb child buff | 6 |
| 42,913 | Heal-proc payload — group heal, % of hit | 12 |
| 42,914 | Heal-proc payload — large | 13 |
| 42,915 | Heal-proc payload — cure | 14 |
| 42,916 | Heal-proc payload — damage + small heal | 15 |
| 42,917 | Heal-proc payload — **solo fallback**, self-heal at reduced value | 12–15 |
| 42,918–42,939 | *unallocated* | |

⚠️ **Detonation damage type: recommend physical or unresistable.** A3 already found the roster
over-covered on resist answers; adding a ninth is the wrong direction.

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 503,001–503,003 | retribution ward lines |
| 503,004 | group protective ward |
| 503,005–503,006 | pulsing absorb lines |
| 503,010–503,014 | stun and blind lines |
| 503,020–503,024 | heal-proc lines |
| 503,025 | proc-rate line |
| **503,030** | `pal_stance` — **all three share it** (native overwrite) |
| 503,040–503,045 | party support lines |
| 503,050–503,054 | threat and self-sustain |

---

## 5. Build order

Per vault §14h:

1. **W4 (accumulator)** — the gate on everything. Build with Warrior and Shadowknight.
2. **Verify SPA 373**, then the ward data rows (1–3) plus the detonation payload.
3. **Stances, stuns, heal-procs, support (7–30)** — data-only, parallel, and enough to make him
   playable long before W4 lands.

---

## 6. Open items

- [ ] **SPA 373 cast-on-fade — exact behaviour, and whether it distinguishes *expired* from
      *broken/depleted*. The design wants detonation on both.** *(Shared with Shaman and Druid.)*
- [ ] Whether **SPA 55 rune depletion** is exposed anywhere before the W4 hook is added.
- [ ] **Stun immunity / diminishing returns** on repeated AE stuns — gates the Bastion cadence.
- [ ] **Detonation damage type** — recommend physical/unresistable.
- [ ] Re-check ward X against the T7–T10 envelope: at T10, X = 21,000 eats two full max hits.
- [ ] Pulsing absorb pulse interval and absorb %.
- [ ] Whether spell 24 survives — it depends on W8, which the Warrior owns.
- [ ] SPA 188 block is multiplicative and weak pre-50 (S3) — don't author 17's block expecting it
      to matter until W11 decides.
