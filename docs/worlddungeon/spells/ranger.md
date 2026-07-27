# Ranger — Spell Design

**Class id 4 · band 42,940–43,059 · spellgroups 504,000+**

Source: vault `04 Class Identities/Ranger.md` §9a–§9e and §14. Native specialty: **weapon-stance
versatility (bow / dual-wield / 2HS) plus warhorn mini-mercs**, tier advantage **+2**.

> 🔴 **Read this before authoring anything.** Per §6.3 and vault §14b, **EQ ranged combat is
> engine-weak** and this is **the single highest-uncertainty item in the whole class set.**
> Everything else in the roster has a known stock analog; archery does not. **Spike it first.**
> If ranged proves substantially broken in ROF2 EQEmu, that finding changes **E6** — his archery
> specialization — and it is far cheaper to learn now than after the content exists.
>
> **Fallback if ranged is intractable:** archery becomes a *skill-attack line* (SPA **193**
> `SkillAttack`, like Monk kicks) flavoured as shots — sidesteps the ranged combat system entirely
> while keeping the fantasy. Ugly but shippable. Spells 1–5 below are written so that fallback is
> a value change, not a redesign.

---

## 1. How he's best at two things (E6)

Per **D2** every line runs 1→10, soft-capped at 5 without specialization:

```
Ranger, specialized into Dart Master:      archery 10 · warhorns 5 · melee 5
Ranger, specialized into Warden of Horns:  warhorns 10 · archery 5 · melee 5
```

**No new mechanism needed** — the vendor script gates ranks 6–10 on the specialization qglobal.
That's how E6 resolves "specialist *and* generalist" without granting two +2s: the +2 is real, and
*which* +2 is a player choice.

In Mk. I/II/III terms: **Mk. III of a non-specialized line is simply not vended.** The rank 1/5/10
mapping means the unspecialized ranger tops out at Mk. II.

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### Archery (5) — ⚠️ all gated on the spike

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 1 | 42,940 | **Marksman's Focus** | ranged damage + accuracy self-buff | **185** (archery), **184** ⚠️ | flat% | ⚠️ |
| 2 | 42,943 | **True Shot** | ranged crit chance + crit damage | **169** ⚠️, **216** ⚠️ | flat% | ⚠️ |
| 3 | 42,946 | **Piercing Shot** | activated high-damage shot | **193** / ranged attack | max↑ | ⚠️ |
| 4 | 42,949 | **Rain of Arrows** | activated AE shot | **193** (AE) | max↑ | ⚠️ |
| 5 | 42,952 | **Called Shot** | shot + snare rider — his Fleer answer at range | **193**, **3** neg | max↑ | ⚠️ |

⚠️ **SPA 169 (crit) and 184 (hit chance) may be melee-only** — there may need to be ranged-specific
equivalents. Also unverified: whether **SPA 85 fires on bow attacks** (needed for spell 8 to
combine with Marksman stance), the ammo damage contribution, and autofire cadence vs.
`attack_delay`.

3–5 are deliberately authored as **activated abilities** rather than passive scaling, because
under the SPA 193 fallback they still work unchanged.

### §9a — Warhorn mini-mercs (5)

Three **SPA 152** swarm-pet lines, each summoning a different `npc_types` template with a
different **AI role**. The AI differentiation is **NPC spell lists + `npc_types` stats, not custom
code** — EQEmu NPCs already cast from assigned lists. **W7's extension is target inheritance**
(assist the owner's target), not the roles themselves.

| # | base | Spell | Companion | Role | Template behaviour | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 6 ⭐ | 42,955 | **Warhorn of Valor** | warrior | taunts / tanks | taunt-heavy AI — **199**/**206** on its spell list, high defensive stats | max↑ | **W7** |
| 7 | 42,958 | **Warhorn of the Hunt** | archer | ranged DPS | ranged DPS AI — **depends on the archery spike** | max↑ | **W7** ⚠️ |
| 8 | 42,961 | **Warhorn of Mending** | priest | heals | heal AI — heal spells on its NPC spell list, targets owner | max↑ | **W7** |
| 9 | 42,964 | **Warhorn of the Wild** | beast | melee DPS + snare | melee AI with a snare proc | max↑ | **W7** |
| 10 | 42,967 | **Endless Horn** | — | extends companion duration | **128**, **398** SwarmPetDuration | max↑ | **W7** |

> ⭐ **The signature ability:** blowing a warhorn mid-fight to summon the companion that fills the
> duo's missing role, then swapping weapon stance to match.

**One companion at a time.** Three simultaneous mercs on a solo-first server is a lot of body, it
steps on the Magician's pet claim, and *"pick the role you're missing"* is a **better decision**
than *"summon everything."* Enforced via a **shared spellgroup across all four horns** — native
overwrite, the same trick as stances.

**None of them bind the pet window** (they're autonomous, per P3.5). That keeps Magician,
Beastlord, Necromancer and Shadowknight as the only pet-window classes.

9 is an addition to the vault's three — it exists so the *Wildstalker* melee build has a horn that
matches its stance, rather than three horns all pointing at other builds.

### §9b — Weapon-proc self-buffs (5)

**SPA 85** (add melee proc) and its ranged equivalent ⚠️. These are his primary "spells" — offense
delivered through the weapon, not spellcasting.

**What the procs do: off-type damage plus a snare rider.** That gives him a native answer to the
§4.2 **Fleer** prefix through his *core buff* rather than a separate utility button — a real
economy of design.

| # | base | Spell | Applies to | Payload | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 11 | 42,970 | **Call of the Predator** | melee swings | off-type damage + snare | **85** | flat% | — |
| 12 | 42,973 | **Wind's Edge** | bow attacks | off-type damage + snare | **85** ⚠️ ranged | flat% | ⚠️ |
| 13 | 42,976 | **Venomed Arrows** | bow attacks | poison DoT proc | **85** ⚠️ ranged | flat% | ⚠️ |
| 14 | 42,979 | **Bleeding Edge** | melee swings | bleed DoT proc | **85** | flat% | — |
| 15 | 42,982 | **Hunter's Instinct** | both | raises proc **rate** of all of the above | **200** | flat% | — |

**Ranged and melee proc buffs get separate spellgroups and both stack.** The stance already
commits him to one mode; forcing a second exclusive choice is redundant friction.

### §9d — Weapon stances (3)

One spellgroup (`rng_stance`), equal rank, native overwrite. Ranger stances sit in the **"other
melee" tier** — below Monk and Beastlord, per §6.5. Set the values in the **shared melee stance
table** so that ordering can't drift.

| # | base | Spell | Mode | Composition | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 16 | 42,985 | **Marksman** | archery | ranged damage ↑, ranged crit ↑, accuracy ↑ | flat% | ⚠️ |
| 17 | 42,988 | **Blademaster** | dual-wield | **177** double attack ↑, **176** dual wield ↑ | flat% | — |
| 18 | 42,991 | **Greatblade** | 2HS | **185** 2HS damage ↑, **169** crit ↑ | flat% | — |

Choosing a stance commits him to a weapon mode for the fight — the Aragorn "right tool" fantasy.

### §9e — Defensive swarm procs (3)

**SPA 323** defensive proc whose payload is a **SPA 152** swarm summon. Small, short-lived,
autonomous, chip damage plus a little aggro spread.

| # | base | Spell | Swarm | Scaling | Dep. |
|---|---|---|---|---|---|
| 19 | 42,994 | **Call the Swarm** | rats — chip damage on his attackers | max↑ | **W7** |
| 20 | 42,997 | **Hornet's Nest** | wasps — smaller, faster, adds a poison DoT | max↑ | **W7** |
| 21 | 43,000 | **Thornguard** | vines — root the attacker instead of damaging | flat% | **W7** |

⚠️ **These must not compete with warhorns against a pet cap.** Recommend the swarm critters use a
**separate swarm subtype exempt from the warhorn cap**, so a defensive proc never eats his
summoned merc. Verify SPA 152's cap behaviour — and note **S2 found caps are per-cast with no
cross-cast accounting** (`zone/aa.cpp:114`), which is promising.

### §9c — Mini-heals (4)

Small heals **like the Druid's but far weaker** — self-sustain and emergency top-offs, not a
healer role.

> **Set magnitudes as a % of the Druid's equivalent-tier value**, not as absolute numbers. That
> way the relationship stays proportional automatically when the Druid is retuned, and the
> "druid-lite" contract can't quietly drift into "second healer."

| # | base | Spell | Target | Shape | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 22 | 43,003 | **Woodland Mending** | single | fast small heal | max↑ | — |
| 23 | 43,006 | **Nature's Salve** | single | small HoT | max↑ | — |
| 24 | 43,009 | **Camp Restoration** | group | small regen — out-of-combat leaning | max↑ | W2 |
| 25 | 43,012 | **Second Wind** | self | instant, short recast — the emergency | max↑ | — |

### Utility and self-buffs (5)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 26 | 43,015 | **Ensnaring Roots** | snare — his kiting tool | **3** neg | flat% | — |
| 27 | 43,018 | **Trueshot Vigil** | self AC + HP buff | **1**, **69** | max↑ | — |
| 28 | 43,021 | **Pathfinder's Stride** | group run speed | **3** | flat% | W2 |
| 29 | 43,024 | **Track Prey** | tracking — ⚠️ availability as a Paragon-granted skill | tracking | — | ⚠️ |
| 30 | 43,027 | **Camouflage** | self invis / stealth for repositioning | invis | — | — |

---

## 3. Payload spells — 43,030–43,059

| id | Payload | Parent |
|---|---|---|
| 43,030 | Melee proc payload — off-type damage + snare | 11 |
| 43,031 | Ranged proc payload — off-type damage + snare | 12 |
| 43,032 | Ranged proc payload — poison DoT | 13 |
| 43,033 | Melee proc payload — bleed DoT | 14 |
| 43,034 | Defensive proc → rat swarm summon | 19 |
| 43,035 | Defensive proc → wasp swarm summon | 20 |
| 43,036 | Defensive proc → vine root | 21 |
| 43,037 | Called Shot snare rider | 5 |
| 43,038–43,059 | *unallocated* | |

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 504,001–504,005 | archery lines |
| **504,010** | `rng_warhorn` — **all four horns share it** (native overwrite = one companion) |
| 504,011 | horn duration extension |
| **504,020** | `rng_proc_melee` — stacks with 504,021 |
| **504,021** | `rng_proc_ranged` — stacks with 504,020 |
| 504,022 | proc-rate line |
| **504,030** | `rng_stance` — all three share it |
| 504,040–504,042 | defensive swarm lines |
| 504,050–504,053 | mini-heal lines |
| 504,060–504,064 | utility and self-buffs |

504,020 and 504,021 being **separate and both stacking** is the deliberate decision from §9b —
and per P1-SOURCE-VERIFICATION §1 that means they also need **deliberately different effect
layouts**, since layout is what actually drives stacking, not spellgroup.

---

## 5. Build order

Per vault §14h:

1. 🔴 **Spike archery (§2, spells 1–5).** The only genuinely unknown system in the roster, and it
   gates half his identity. Do not author archery lines before this resolves.
2. **Stances, proc buffs, mini-heals, utility (11, 14–18, 22–30)** — data-only, immediate. He is
   playable as a melee ranger on day one.
3. **Warhorns (6–10)** with **W7**, shared with Necromancer, Enchanter and Rogue.
4. **Defensive swarms (19–21)** last.

---

## 6. Open items

- [ ] 🔴 **Ranged combat generally** — damage formula, crit, accuracy, proc firing, ammo
      contribution, autofire cadence. *(Highest-uncertainty item in the class set.)*
- [ ] Whether **SPA 169 / 184 are melee-only** and need ranged equivalents.
- [ ] Whether **SPA 85 fires on bow attacks** (gates spells 12, 13 and the Marksman combination).
- [ ] **SPA 152 cap behaviour** and whether swarm subtypes can have independent caps.
- [ ] Whether **NPC spell lists give sufficient AI differentiation** for the four merc roles.
- [ ] **Track availability** as a Paragon-granted skill.
- [ ] Mini-heal magnitudes as a **% of the Druid's** equivalent tier — set the ratio explicitly.
- [ ] Confirm bow / DW 1H / 2HS weapon types vs. §2.1.
- [ ] Whether spell 9 (Warhorn of the Wild) is wanted — it is an addition to the vault's three.
