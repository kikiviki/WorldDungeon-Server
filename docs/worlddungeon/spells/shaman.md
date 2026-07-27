# Shaman — Spell Design

**Class id 10 · band 43,300–43,419 · spellgroups 510,000+**

Source: vault `04 Class Identities/Shaman.md` §9a–§9f and §14. Native specialty: **talisman group
buffs and warding**, tier advantage **+2**.

Per **C12** the *headline* strength is **warding**, not buffs — talismans stay high-magnitude with
real upkeep, but the ward is what the class is pitched on. Per **E11** he gets **no stances**:
the familiars are his posture dial, and adding stances would be two systems doing one job.

---

## 1. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9b — Warding: the headline (6)

Three layers, only one of which needs code.

1. **The absorb** — **SPA 55** (melee rune) and **SPA 78** (spell rune). The melee-vs-spell ward
   split is just these two SPAs. Stock.
2. **Break-riders** — **SPA 373 cast-on-fade** ⚠️ fires a bonus spell when the ward expires *or*
   depletes.
3. **The reapply focus** — *"wards have a % chance to reapply when broken."* The custom piece,
   implemented on the same cast-on-fade path: if 373 fires on depletion, the reapply is just a
   conditional trigger on the same hook.

> **The deliberate contrast:** the Paladin ward *stores and detonates* (needs W4's accumulator);
> the Shaman ward *absorbs and re-arms* (needs a fade trigger). Same SPA 55 primitive, opposite
> payoff, different custom dependency. That's what stops the two ward classes feeling the same.

| # | base | Spell | Type | Target | Rider | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 1 ⭐ | 43,300 | **Spirit Ward** | melee, **55** | group | on break: bonus heal | max↑ | ⚠️ 373, W2 |
| 2 | 43,303 | **Ancestral Ward** | melee, **55** | single | on break: bonus heal, larger | max↑ | ⚠️ 373 |
| 3 | 43,306 | **Ward of Warding Winds** | spell, **78** | group | on break: resist buff | max↑ | ⚠️ 373, W2 |
| 4 | 43,309 | **Runic Skin** | spell, **78** | single | on break: short mitigation buff | max↑ | ⚠️ 373 |
| 5 | 43,312 | **Enduring Talisman** | melee, **55** | self | **% chance to reapply on break** | flat% | ⚠️ custom |
| 6 | 43,315 | **Spirit Anchor** | melee, **55** | group | on break: group cure | max↑ | ⚠️ 373, W2 |

> ⭐ **The signature ability is spell 1** — a group ward that, when it breaks, fires off a bonus
> heal, layered under a wolverine pact and a familiar spirit.

**Absorb cap sizing:** express X as a **multiple of the tier's mob max hit**, the same derivation
the Paladin's ward X uses, so the whole ward family auto-follows any §4.1 mob retune.
**Recommend ~1.5× tier max hit for the group ward** — below the Paladin's 2×, since his re-applies.

**Reapply-% ceiling: cap well under 100%.** A ward that always re-arms is permanent immunity.
**Recommend topping out ~40% at Mk. III.**

⚠️ A ward re-casting itself from its own fade trigger **needs an infinite-loop guard.**

Wards stack with **Cleric defensive procs** (55/78 runes vs. 323 procs are different SPA
families) — intended, no blocker needed.

### §9a — Talismans (6)

Stock group buffs. Per **E4** the Shaman needs **no targeting restriction at all** — he's the
stock case, and can buff anyone: self, pets, party, friends, guildmates, strangers. The Bard is
the one carrying the custom constraint.

| # | base | Spell | Grants | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 7 | 43,318 | **Talisman of the Bull** | major STR/STA | stat SPAs | max↑ | W2 |
| 8 | 43,321 | **Talisman of the Serpent** | major DEX/AGI | stat SPAs | max↑ | W2 |
| 9 | 43,324 | **Talisman of the Owl** | major INT/WIS/CHA | stat SPAs | max↑ | W2 |
| 10 | 43,327 | **Talisman of Cohesion** | **minor** haste | **11** | flat% | W2 |
| 11 | 43,330 | **Talisman of Persistence** | **minor** regen + **minor** HP | 0 (duration), **69** | max↑ | W2 |
| 12 | 43,333 | **Talisman of the Ages** | heroic-stat / stat-cap raise | **262** RaiseStatCap | max↑ | W2 |

**Keep haste, regen and HP deliberately "minor"** so they don't step on the classes that own
those identities. That's a data value, not a mechanism — but it is the whole reason the Shaman
doesn't flatten the Bard, Druid and Cleric.

### §9d — Animal familiars (4)

**SPA 108**, natively single-instance — **E1's** unique-ID rule is free. Swappable mid-fight at
the cost of mana and cast time, which is stance behaviour and is exactly why **E11** gives him no
stances.

| # | base | Spell | Grants | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 13 | 43,336 | **Spirit of the Bear** | damage reduction; **root/snare immunity** ⚠️ | **108**, **162** | flat% | ⚠️ |
| 14 | 43,339 | **Spirit of the Wolf** | melee haste + run speed | **108**, **11**/98, **3** | flat% | — |
| 15 | 43,342 | **Spirit of the Bat** | perma-levitate, crit ↑, darkvision; vampiric variant → lifeleech | **108**, **169**, **178** ⚠️ | flat% | ⚠️ |
| 16 | 43,345 | **Spirit of the Wyrm** | **breath potency ↑** — SPA 124 with a Limit on the breath spellgroup | **108**, **124**, **385** | flat% | — |

16 is the one that matters mechanically: it uses **SPA 385 `LimitSpellGroup`** (confirmed
implemented) to focus only the breath lines, which is how the Draconic familiar amplifies §9e
without leaking into everything else he casts.

⚠️ Which global models are hookable per animal needs verification, but all four are common ROF2
models so this is low-risk.

### §9e — Breath lines (5)

**The one uncertain system.** §9e asks for cone or line AoEs, which EQ largely doesn't do — its
AEs are radius-based.

**Recommend radius PBAE for launch**, with directional cones as a post-launch enhancement if
they prove worth the risk. A cone feels bad the moment the client's facing and the server's
disagree. The three breath lines work identically as PBAEs and keep every mechanical property.

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 17 | 43,348 | **Breath of Toxicity** | AE DoT, poison/disease | 0 (duration), **36**/35 counters | max↑ | — |
| 18 | 43,351 | **Breath of Malo** | AE debuff — melee slow + resist/stat shred | **11** neg, resist debuffs | max↑ | — |
| 19 | 43,354 | **Breath of Frost** | AE direct damage — the burst one | 0 | max↑ | — |
| 20 | 43,357 | **Breath of Cinders** | AE DoT, fire — the second damage flavour | 0 (duration) | max↑ | — |
| 21 | 43,360 | **Withering Breath** | AE — attack-power and accuracy debuff | **11** neg, **184** neg | max↑ | — |

Three elements was the vault's recommendation and it covers DoT / debuff / burst cleanly; 20 and
21 are the two additions that give the line depth without a fourth mechanism.

18 is his best cross-class contribution — **resist-shred makes every caster ally's spells land
harder.**

### §9c — Short-term pacts (4)

All stock: high-magnitude short-duration buffs on cooldowns (`buffduration` + `recast_time`),
distinct from the sustained talismans.

| # | base | Spell | Grants | Scope | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 22 | 43,363 | **Pact of the Wolverine** | big melee damage + attack speed, short | group | flat% | W2 |
| 23 | 43,366 | **Pact of the Black Wolf** | big avoidance + run speed, short | group | flat% | W2 |
| 24 | 43,369 | **Pact of the Boar** | big mitigation + HP, short | group | max↑ | W2 |
| 25 | 43,372 | **Pact of the Rimewind** | big spell-damage + mana regen, short | group | flat% | W2 |

Under **D1/W2** group pacts reach pets and temp-allies — which matters less to him than to most
support classes, since **E4** already lets him buff anything.

### §9e/§9f — Self-melee and secondary heals (5)

He's a real combatant, not a backline caster — but his heals are deliberately authored **below
Cleric magnitude.**

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 26 | 43,375 | **Spirit Warrior** | self melee damage + double attack | **185**, **177** | flat% | — |
| 27 | 43,378 | **Frenzy of Spirit** | self attack speed | **11**/98 | flat% | — |
| 28 | 43,381 | **Spirit Mending** | single-target heal — secondary tier | 0 | max↑ | — |
| 29 | 43,384 | **Ancestral Mending** | group heal — secondary tier | 0 | max↑ | W2 |
| 30 | 43,387 | **Torpor** | heavy self HoT + a real drawback while active | 0 (duration), **11** neg | max↑ | — |

---

## 2. Payload spells — 43,390–43,419

| id | Payload | Parent |
|---|---|---|
| 43,390 | Ward break — bonus heal, small | 1 |
| 43,391 | Ward break — bonus heal, large | 2 |
| 43,392 | Ward break — resist buff | 3 |
| 43,393 | Ward break — mitigation buff | 4 |
| 43,394 | Ward break — group cure | 6 |
| 43,395 | Ward reapply trigger | 5 |
| 43,396 | Bat familiar lifeleech rider | 15 |
| 43,397–43,419 | *unallocated* | |

---

## 3. Spellgroup allocation

| Group | Line |
|---|---|
| 510,001–510,006 | ward lines |
| 510,010–510,015 | talisman lines |
| 510,020–510,023 | familiars |
| **510,030** | `shm_breath` — **the group spell 16's SPA 385 Limit names** |
| 510,031–510,035 | individual breath lines |
| 510,040–510,043 | pacts |
| 510,050–510,054 | self-melee and heals |

510,030 is load-bearing: the Wyrm familiar's focus Limit names it, so every breath spell must
carry that group *in addition to* its own line group, or the familiar silently fails to amplify
part of the suite.

---

## 4. Build order

Per vault §14g:

1. **Talismans, pacts, familiars, heals (7–16, 22–30)** — data-only, immediate. He's playable
   early.
2. **Wards (1–4, 6)** once **SPA 373 is verified** — shared with Paladin and Druid.
3. **Reapply focus (5)** — the one custom piece, on the same hook.
4. **Breath (17–21)** as radius PBAEs; revisit cones later.

---

## 5. Open items

- [ ] **SPA 373 cast-on-fade — fires on *depletion* as well as expiry?** *(Shared with Paladin
      and Druid; gates the whole ward design.)*
- [ ] Whether a ward can re-cast itself from its own fade trigger **without an infinite loop** —
      needs a guard.
- [ ] Cone/line targeting feasibility in ROF2 (decides the breath shape).
- [ ] Root/snare immunity SPA for the Bear familiar.
- [ ] Whether SPA 55 and 78 wards stack with each other (they should — different damage types).
- [ ] Ward absorb caps per tier, break-rider effects, reapply-% ceiling.
- [ ] Talisman magnitudes, and how "minor" the haste/regen/HP stay.
- [ ] Which global models are hookable per familiar.
- [ ] Confirm weapon types vs. §2.1 for a melee-leaning priest hybrid.
- [x] ~~Rabid/Ferocious Bear synergy~~ — **cut** per C12.
