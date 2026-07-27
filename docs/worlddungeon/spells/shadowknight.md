# Shadowknight — Spell Design

**Class id 5 · band 43,060–43,179 · spellgroups 505,000+**

Source: vault `04 Class Identities/Shadowknight.md` §9 and §14. Native specialty: **lifetap
sustain — HP-return baked into hits, procs and self-buffs**, tier advantage **+2**.

> **He is the roster's low-complexity class (A6) — protect that.** Blood Golem and stances add
> *depth*, not buttons: the golem is fire-and-forget and stances are set-once-per-fight. Resist
> the urge to give him a rotation.

DoT and disease flavour is **intentionally trimmed** — the old Plaguebringer path is gone.

---

## 1. The lifetap engine

Two distinct mechanisms, easy to conflate:

- **Cast lifetaps** — a normal spell with SPA 0 damage to target plus a self-heal component.
  Stock. ST and AE versions differ only by `targettype`.
- **Melee lifetap** — **SPA 178 `MeleeLifetap`** (confirmed in `common/spdat.h`, marked
  implemented), a % of melee damage returned as HP. **This is the engine**, delivered as a
  self-buff via SPA 85 and as passive AA ranks.

**AE lifetap return on big packs: per-target with diminishing returns, not a flat cap.** A cap
makes packs feel *worse* past the threshold; diminishing returns keeps every extra body worth
something while flattening the curve. Implement as the heal component scaling by `1/sqrt(targets)`
⚠️ or a tuned table.

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### Cast lifetaps (6)

| # | base | Spell | Target | Shape | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 1 | 43,060 | **Siphon Vitality** | single | fast, efficient — the filler tap | max↑ | — |
| 2 | 43,063 | **Drain Soul** | single | long cast, big return | max↑ | — |
| 3 ⭐ | 43,066 | **Harrowing Wave** | **AE** | taps a whole pack, diminishing per target | max↑ | ⚠️ |
| 4 | 43,069 | **Consume the Weak** | single | damage scales up as target HP drops | max↑ | — |
| 5 | 43,072 | **Grasp of the Grave** | single | tap + snare rider | max↑ | — |
| 6 | 43,075 | **Communal Siphon** | AE | tap where the **heal routes to the group**, not self | max↑ | W2 |

> ⭐ **The signature ability is spell 3** — a big AoE lifetap that tags a whole pack for hate *and*
> heals him off all of them at once.

6 is the one concession to party play in a class built around self-sustain, and it exists so a duo
partner has a reason to want him tapping.

### Lifetap proc self-buffs (5)

The engine, delivered as buffs. SPA **85** grants the proc; **178** is the return.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 7 | 43,078 | **Shroud of Leeching** | melee swings return HP | **85**, **178** | flat% | — |
| 8 | 43,081 | **Vampiric Embrace** | higher return, shorter duration | **85**, **178** | flat% | — |
| 9 | 43,084 | **Unholy Aura** | lower return, group-wide | **85**, **178** | flat% | W2 |
| 10 | 43,087 | **Touch of the Grave** | proc adds damage **and** tap | **85** → 0 + **178** | flat% | — |
| 11 | 43,090 | **Blood Frenzy** | raises proc **rate** of all of the above | **200** | flat% | — |

### Banked Taps (3) — *new per E2*

**Per A3, spike-eating is the roster's thinnest coverage.** This converts his signature weakness
into a reward for his signature strength.

1. When a lifetap heal would **overheal** (W5 threshold check at/near full HP), capture the excess.
2. Convert `overheal × bank_rate` *(suggest 50%)* into an **SPA 55 rune** on the SK, accumulating
   to a cap.
3. **Cap = 1 × tier max hit** — eats one spike, not two. The **Paladin at 2× stays the dedicated
   spike-eater**; this is a byproduct of playing well, not a competing claim.
4. **Decays out of combat**, so it can't be pre-charged on trash and carried into a boss.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 12 | 43,093 | **Banked Taps** | overheal → SPA 55 rune, cap 1× tier max hit | accumulator + **55** | max↑ | **W4/W5** |
| 13 | 43,096 | **Blood Bank** | raises the cap and the bank rate | **55** | max↑ | **W4/W5** |
| 14 | 43,099 | **Spend the Bank** | instantly converts the banked rune into a burst heal | 0 | max↑ | **W4/W5** |

### Stances (3) — *new per E11*

One spellgroup (`sk_stance`), equal rank, native overwrite.

| # | base | Spell | Composition | Scaling | Dep. |
|---|---|---|---|---|---|
| 15 | 43,102 | **Reaping** (2H) | **178** tap-per-hit ↑, **185** 2H damage ↑ | flat% | — |
| 16 | 43,105 | **Black Bulwark** (shield) | **162** mitigation ↑, **114** hate ↑, block ⚠️ | flat% | — |
| 17 | 43,108 | **Famine** | at full HP, tap return converts toward **damage** instead of healing | flat% | **W5** |

**Famine needs the same W5 threshold hook as Banked Taps.** Build them together — it is one
condition check feeding two effects. That's deliberate: both key off being at full HP, so a
well-played SK is always converting surplus into something.

⚠️ SPA 188 block is multiplicative on block skill and weak pre-50 (S3) — don't author 16's block
component expecting it to matter until **W11** decides.

### Blood Golem (4) — *new per E2*

Replaces the three-mode pet selector entirely, which makes the §13 pet-mode swap-cost question
**disappear**.

⚠️ **Check first:** SPA 178 may be applicable *to the pet* with the owner as heal recipient. If
so, this whole feature is **data-only** and the custom work vanishes. Worth an hour of source
reading before writing code. Otherwise it's **W3** (pet owner-redirect).

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 18 | 43,111 | **Summon Blood Golem** | commanded pet; a % of its dealt damage returns to the SK as HP | **33**, **167**, transfer | max↑ | **W3** ⚠️ |
| 19 | 43,114 | **Golem's Vigour** | pet heal + pet HP buff | 0, **69** | max↑ | — |
| 20 | 43,117 | **Sanguine Bond** | raises the transfer % | transfer rider | flat% | **W3** |
| 21 | 43,120 | **Golem's Provocation** | pet AE taunt — the golem holds while he taps | **206** on pet | max↑ | — |

Two clean §8.1 knobs: **golem damage** × **transfer %**.

### AoE hate and fear (5)

Entirely stock. His AE-hate and AE-lifetap pairing is mechanically ideal: **the same pull that
gives him threat gives him sustain.** No implementation tension — independent spells that happen
to want the same situation.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 22 | 43,123 | **Terror of Darkness** | AE taunt | **206** | max↑ | — |
| 23 | 43,126 | **Unrelenting Hate** | hate over time | **192** | max↑ | — |
| 24 | 43,129 | **Voice of Command** | ST taunt, high magnitude | **199** | max↑ | — |
| 25 | 43,132 | **Scream of Death** | fear — the Fearlord tool | **23** | max↑ | — |
| 26 | 43,135 | **Horrifying Visage** | AE fear, short — the panic button | **23** (AE) | flat% | — |

### Self-buffs and utility (4)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 27 | 43,138 | **Shroud of Endurance** | self HP + mitigation | **69**, **162** | max↑ | — |
| 28 | 43,141 | **Insidious Retreat** | self — feign / escape | feign | — | — |
| 29 | 43,144 | **Dark Pact** | mana ← HP conversion, keeping the tap engine fuelled | **15**, 0 self | max↑ | — |
| 30 | 43,147 | **Leech Touch** | melee-range instant tap on a short recast | 0 dual-component | max↑ | — |

27 matters more than it looks: he **wants HP/STA set-dressing to widen the pool the taps refill
into.** A bigger bucket makes lifetaps smoother against spikes, which is his whole weakness.

---

## 3. Payload spells — 43,150–43,179

| id | Payload | Parent |
|---|---|---|
| 43,150 | Melee tap proc payload | 7–9 |
| 43,151 | Melee tap proc payload — damage + tap | 10 |
| 43,152 | Banked Taps rune application | 12, 13 |
| 43,153 | Blood Golem damage-transfer rider | 18, 20 |
| 43,154 | Famine damage conversion payload | 17 |
| 43,155 | Communal Siphon group heal recourse | 6 |
| 43,156–43,179 | *unallocated* | |

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 505,001–505,006 | cast lifetap lines |
| 505,010–505,014 | lifetap proc self-buff lines |
| **505,020** | `sk_banked_taps` — ⚠️ **must be its own group so its rune stacks with externally-cast runes** (Shaman wards) rather than overwriting |
| 505,021–505,022 | bank cap / spend lines |
| **505,030** | `sk_stance` — all three share it |
| 505,040–505,043 | Blood Golem lines |
| 505,050–505,054 | hate and fear lines |
| 505,060–505,063 | self-buffs and utility |

The 505,020 note is a real risk: a Shaman ward landing on the SK must not blow away his banked
rune. Different spellgroup **and** a deliberately different effect layout — per
P1-SOURCE-VERIFICATION §1, layout is what actually drives stacking.

---

## 5. Build order

Per vault §14g:

1. **Read SPA 178 semantics first** — it determines whether the Blood Golem is data-only or needs
   W3.
2. **Cast lifetaps, AE hate, fear (1–6, 22–26)** — stock, immediate. He is playable on day one.
3. **W4 + W5** (accumulator + threshold) with Warrior and Paladin → **Banked Taps and Famine**.
4. **Stances and golem (15–21)** in parallel.

---

## 6. Open items

- [ ] **SPA 178 — flat vs. %, and whether it can be applied to a *pet* with the owner as heal
      target.** *(Decides the Blood Golem's cost. Check first.)*
- [ ] Whether **overheal is exposed** at the heal-application site, or needs computing pre-clamp.
- [ ] **SPA 206 AE taunt radius / target cap** vs. §4.2 pack sizes.
- [ ] Whether **SPA 55 runes from Banked Taps stack with externally-cast runes** (Shaman wards) or
      overwrite — **recommend separate spellgroup and layout, stack.**
- [ ] AE lifetap diminishing curve — `1/sqrt(targets)` vs. a tuned table.
- [ ] Lifetap rate vs. spike: define target HP pool and tap rate against the §4.1 T7–T10 hit curve.
- [ ] Confirm 2H / 1H+shield weapon types vs. §2.1.
- [ ] SPA 188 block weak pre-50 (S3) — 16's block component waits on W11.
