# WorldDungeon — Caster Spell Design

Design drafts for the eleven spellcasting classes. **Design only — no SQL here.** These are the
review artifacts that come *before* migrations are written.

Derived from the Obsidian vault (`New Ideas/EQ/WorldDungeon/04 Class Identities/`), specifically
each class's **§9 spell flavour** and **§14 EQEmu implementation** sections, plus
[[Custom Spells]] §8.1, [[Classes & Paragon Paths]] §6, and the repo's
[F1-ID-RANGES.md](../F1-ID-RANGES.md) / [P1-SOURCE-VERIFICATION.md](../P1-SOURCE-VERIFICATION.md).

| Class | id | Doc | Band | Spellgroups |
|---|---:|---|---|---|
| Cleric | 2 | [cleric.md](cleric.md) | 42,700–42,819 | 502,000+ |
| Paladin | 3 | [paladin.md](paladin.md) | 42,820–42,939 | 503,000+ |
| Ranger | 4 | [ranger.md](ranger.md) | 42,940–43,059 | 504,000+ |
| Shadowknight | 5 | [shadowknight.md](shadowknight.md) | 43,060–43,179 | 505,000+ |
| Druid | 6 | [druid.md](druid.md) | 43,180–43,299 | 506,000+ |
| Shaman | 10 | [shaman.md](shaman.md) | 43,300–43,419 | 510,000+ |
| Necromancer | 11 | [necromancer.md](necromancer.md) | 43,420–43,539 | 511,000+ |
| Wizard | 12 | [wizard.md](wizard.md) | 43,540–43,659 | 512,000+ |
| Magician | 13 | [magician.md](magician.md) | 43,660–43,779 | 513,000+ |
| Enchanter | 14 | [enchanter.md](enchanter.md) | 43,780–43,899 | 514,000+ |
| Beastlord | 15 | [beastlord.md](beastlord.md) | 43,900–44,019 | 515,000+ |

Excluded per scope: Bard (8) and the pure-melee classes Warrior (1), Monk (7), Rogue (9),
Berserker (16). Their bands are reserved below but unauthored.

---

## 1. The Mk. I / II / III contract

Locked in [F1-ID-RANGES.md](../F1-ID-RANGES.md) and migration `0004`. Restated because every
table in these docs depends on it:

- **Three tiers**, `rank` **1 / 5 / 10** — the stock convention. `rank` is a position on a 1–10
  scale, not a counter.
- **Tiers raise the ceiling, not the floor.** Same `formula`, rising `max`. Most players live on
  Mk. I and it stays relevant because it scales with level and stats. Mk. II lands after a few
  rebirths; Mk. III is the elite chase. **Do not** copy stock's flat 9→10→11 bumps.
- **Level and stat scaling are primary; tiers are secondary.** Per [[Custom Spells]] §8.1 nothing
  is a flat number — every value is tier × AA × gear spell-stat.

### The one exception, and how to tell

Migration `0004`'s scaling note is the rule: **the model applies to output magnitudes, not to
percentages.**

| Spell expresses… | Formula | Tiering |
|---|---|---|
| HP / mana / damage / healing | 101–105 or 111–112, rising `max` per tier | ceiling rises |
| A percentage (focus %, mitigation %, proc rate, absorb %) | **100** (flat) | the percentage itself steps |

A percentage does not want level scaling. Every table below marks which of the two a row is, in
the **Scaling** column: `max↑` or `flat%`.

Each spell in these docs therefore occupies **three consecutive ids**: `base+0` = Mk. I,
`base+1` = Mk. II, `base+2` = Mk. III.

---

## 2. ID budget

The client caps `spells_new.id` at **45,000** (`rof2_limits.h:346`). Stock max is 42,602. The
whole custom spell budget is therefore **42,700–44,999 ≈ 2,300 ids**, and it must cover all
sixteen classes.

| Consumer | Ids |
|---|---:|
| 11 caster classes × 120 | 1,320 |
| 5 melee/bard classes × 120 (reserved) | 600 |
| **Total claimed** | **1,920** |
| Spare | 380 |

**120 ids per class**, split inside the band:

| Offset | Purpose | Count |
|---|---|---:|
| `+000` … `+089` | **30 player-facing spells** × Mk. I/II/III | 90 |
| `+090` … `+119` | **payload spells** — proc targets, recourses, triggered children, detonation payloads, swarm summons | 30 |

Payload spells are usually **not** tiered — one payload serves all three Mk. tiers, with the
parent's slot value carrying the scaling (the pattern migration `0004` uses for the mantle
procs at 42,710–42,712). Where a payload *is* tiered it takes three consecutive ids from the
payload sub-band and the class doc says so.

### Band map

| Class | Band | Spells | Payloads |
|---|---|---|---|
| Cleric | 42,700–42,819 | 42,700–42,793 ⚠️ | 42,794–42,819 ⚠️ |
| Paladin | 42,820–42,939 | 42,820–42,909 | 42,910–42,939 |
| Ranger | 42,940–43,059 | 42,940–43,029 | 43,030–43,059 |
| Shadowknight | 43,060–43,179 | 43,060–43,149 | 43,150–43,179 |
| Druid | 43,180–43,299 | 43,180–43,269 | 43,270–43,299 |
| Shaman | 43,300–43,419 | 43,300–43,389 | 43,390–43,419 |
| Necromancer | 43,420–43,539 | 43,420–43,509 | 43,510–43,539 |
| Wizard | 43,540–43,659 | 43,540–43,629 | 43,630–43,659 |
| Magician | 43,660–43,779 | 43,660–43,749 | 43,750–43,779 |
| Enchanter | 43,780–43,899 | 43,780–43,869 | 43,870–43,899 |
| Beastlord | 43,900–44,019 | 43,900–43,989 | 43,990–44,019 |
| *(reserved)* Warrior | 44,020–44,139 | | |
| *(reserved)* Monk | 44,140–44,259 | | |
| *(reserved)* Bard | 44,260–44,379 | | |
| *(reserved)* Rogue | 44,380–44,499 | | |
| *(reserved)* Berserker | 44,500–44,619 | | |
| **Spare** | 44,620–44,999 | | |

> ⚠️ **Cleric 42,700–42,712 is already occupied** by migration `0004` (three mantles ×3 + three
> mantle procs). That migration is applied and immutable. The Cleric doc keeps those rows where
> they are and lays the remaining 27 spells around them — see [cleric.md](cleric.md) §0.
>
> ⚠️ The knock-on is that his 30th spell lands at 42,791–42,793, so **the Cleric's payload floor
> moves to 42,794** rather than the standard `+090`. His payload needs are small (7 rows), so this
> costs nothing. He is the only class with this offset.

### Spellgroups

Server-side only, uncapped, base 500,000. Allocation is **`500,000 + (class_id × 1,000) + n`**,
which makes any spellgroup self-identifying by EQ class id.

Legacy exception: `clr_mantle` = **500,001** and the mantle proc lines **500,002–500,004**, set
by migration `0003`/`0004` before this scheme existed. Grandfathered, not renumbered —
renumbering a live spellgroup is exactly the expensive failure F1 warns about.

---

## 3. What "unique to the class" means here

Every spell below was written from that class's vault doc, not from a shared template. Concretely
that means:

- **No shared lines.** Where two classes both have, say, a rune, they get *different SPAs and
  different payoffs* — the Paladin ward **stores and detonates** (SPA 55 + accumulator + 373),
  the Shaman ward **absorbs and re-arms** (SPA 55/78 + 373 + reapply roll). That contrast is
  deliberate in the vault and is preserved here.
- **The native +2 is in the numbers.** Where a class owns a specialty (§6.1), its Mk. III value
  sits visibly above anyone else's equivalent. Cross-class dips get the same *mechanism* at a
  lower ceiling via the D2 rank-6–10 gate, not a different spell.
- **The marquee ability is present and named.** Each doc flags its class's signature "wow"
  ability from vault §9 with a ⭐.

---

## 4. Engine dependencies

Many spells are data-only. The ones that are not are flagged in each table's **Dep.** column
against the backlog item that must land first:

| Tag | Backlog item | Blocks |
|---|---|---|
| `W1` | ✅ **built** — spellgroup-on-target restriction (`SpellRestriction` **60000**, not 1000 — that id was stock; see F1) | every detonator — pattern is normative in [DETONATION-PATTERN.md](../DETONATION-PATTERN.md) |
| `W2` | Ally-target expansion (P3.6) | group heals/buffs reaching pets and temp-allies — the solo forms |
| `W3` | Pet owner-redirect for beneficial effects | Beastlord reciprocal procs, SK Blood Golem, Magician support |
| `W4` | Accumulator (P3.2) | Paladin retribution ward, SK Banked Taps |
| `W5` | Threshold trigger (P3.4) | Necro life ward, SK Famine |
| `W7` | Swarm AI extensions (P3.5) | Enchanter dopplegangers, Necro minions, Ranger warhorns |
| `W9` | DoT spread engine | Druid spreading DoT |
| — | no tag = **data-only**, authorable today | |

**Roughly 70% of the 330 spells are data-only.** That is the point of the ordering: each class
has a playable data-only core that ships before its engine bill lands.

### SPA verification

Every SPA id cited across these eleven docs was checked against `common/spdat.h` on this
checkout. All resolve and all are marked `// implemented`. Notable confirmations:

| SPA | Name | Note |
|---|---|---|
| 55 / 78 | `Rune` / `AbsorbMagicAtt` | melee and spell absorb — the ward split |
| 85 / 323 | `WeaponProc` / `DefensiveProc` | offensive and defensive proc grants |
| 108 | `Familiar` | **natively single-instance** — free enforcement for Shaman/Wizard/Mage familiars |
| 149 | `StackingCommand_Overwrite` | the mandatory rider on parallel tiered lines |
| 152 | `TemporaryPets` | swarm pets — dopplegangers, minions, warhorns |
| 153 | `BalanceHP` | ⚠️ **sign inverted** — positive base is a *penalty*. Tier curve runs positive→negative. |
| 178 | `MeleeLifetap` | the SK engine; also the Beastlord Vampiric payload |
| 373 | `CastOnFadeEffectAlways` | ward break-riders — **fires-on-depletion still unverified** |
| 374 | `ApplyEffect` | the trigger primitive behind every combo |
| 385 | `LimitSpellGroup` | **exists and is implemented** — focus limits can name a spellgroup |
| 442 | `TriggerOnReqTarget` | trigger gated on a `SpellRestriction` id — W1's consumer |
| 457 | `ResourceTap` | damage→hp/mana/end conversion; closed W6 |

---

## 5. Carried-forward open items

These are unresolved *in the vault* and every doc that touches them says so rather than papering
over it:

| Item | Owner | Affects |
|---|---|---|
| **SPA 373 fires on depletion, not just expiry** | shared | Paladin ward, Shaman ward, Druid DS. **Gates three classes — verify first.** |
| `not_focusable` column unidentified | shared | any spell that must be non-focusable |
| Focus effects select best/worst, they don't sum | shared | Zealot's negative SPA 125 vs. a heal-focus AA |
| Ranged combat viability in ROF2 | Ranger | half his identity; **spike before authoring** |
| Can a pet's proc target its owner? | Beastlord / SK / Mage | three features on one question |
| Can a swarm pet take a runtime-generated spell list? | Enchanter | gates the whole E7 doppleganger rework |
| Chromatic / lowest-resist `resisttype` | Enchanter | chaos damage |
| Can a Limit read the caster's active pet type? | Magician | familiar pairing data-only or not |
| Recourse behaviour on partial resist | Cleric | smite recourse frequency |

---

## 6. Review order

Read [cleric.md](cleric.md) first — it extends work already in the database and shows the format
against a known-good reference. Then [wizard.md](wizard.md), which per **C13** is the detonation
reference template every other combo class copies.
