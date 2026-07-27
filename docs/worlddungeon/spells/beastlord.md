# Beastlord — Spell Design

**Class id 15 · band 43,900–44,019 · spellgroups 515,000+**

Source: vault `04 Class Identities/Beastlord.md` §9a–§9e and §14. Native specialty:
**beastlord↔warder synergy — reciprocal proc buffs and shared combos make the pair stronger than
the sum**, tier advantage **+2**.

He is the **second-strongest stance class** (§6.5, behind Monk) but implementationally simpler —
**one pool, not two.**

---

## 1. The one question that unblocks three features

> **Can a pet's proc target its owner?**

Beastlord→warder is straightforward: **SPA 85** on the beastlord, proc spell `targettype` = pet.
**Warder→beastlord is the hard direction** — the pet needs a proc that targets its **owner**.

If a pet proc can resolve `owner` as a target, most of this class is data-only. If not, it needs
**W3** (pet owner-redirect for beneficial effects), which hooks two sites: `Mob::MeleeLifeTap()`
at `zone/mob.cpp:6850` and `Mob::ExecWeaponProc()` at `zone/mob.cpp:5366`.

**Solve it once and three features work:** reciprocal procs, the support-warder spec, and
warder-triggered combos. **Check this before authoring anything below.**

---

## 2. Spell roster

30 spells. `base` is Mk. I; Mk. II and Mk. III take `base+1` and `base+2`.

### §9a — Reciprocal procs: the synergy engine (5)

**The buffs grant different things in each direction** — warder→beastlord gives **damage** (the
pet feeds your offense), beastlord→warder gives **haste/proc rate** (you feed the pet's uptime).
Asymmetry makes the loop legible and gives each side a reason to want the other alive.

**Short-term by design** — they must be *maintained through active fighting*, so the pair ramps
during a sustained engagement and lulls when idle.

| # | base | Spell | Direction | Grants | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|---|
| 1 | 43,900 | **Hunter's Rapport** | beastlord → warder | haste + proc rate on the warder | **85** → 11/**200** | flat% | — |
| 2 | 43,903 | **Warder's Gift** | warder → beastlord | melee damage on the beastlord | pet **85** → **185** | flat% | **W3** ⚠️ |
| 3 | 43,906 | **Pack Bond** | both | escalating stack, refreshed on each proc | stacking buff + `max` | flat% | **W3** ⚠️ |
| 4 | 43,909 | **Shared Instinct** | warder → beastlord | crit chance instead of raw damage | pet **85** → **169** | flat% | **W3** ⚠️ |
| 5 | 43,912 | **Blooded Rapport** | beastlord → warder | pet damage + pet mitigation | **85** → 185/**162** | flat% | — |

3's escalation uses a **stacking buff with a `max` and refresh-on-proc duration** — the same shape
as the Berserker's Reprisal. Data-only once the direction problem is solved.

### §9b — Warder specialization (4)

Two pet lines in one spellgroup — native overwrite means **you have one warder.**
**Mutually exclusive, swapped by re-summoning.** A slider adds tuning surface without adding a
decision, and re-summoning is already the natural cost.

| # | base | Spell | Spec | Composition | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 6 | 43,915 | **Summon Warder: Fang** | heavy-hitter | higher `npc_types` damage/HP, **167** weighted to offense | max↑ | — |
| 7 | 43,918 | **Summon Warder: Spirit** | support | pet carries **85** procs whose payload **targets the owner** with buffs/heals | max↑ | **W3** ⚠️ |
| 8 | 43,921 | **Warder's Vigour** | — | pet heal + pet HP | 0, **69** | max↑ | — |
| 9 | 43,924 | **Warder's Fortitude** | — | pet mitigation + pet avoidance | **162**, **215** ⚠️ | flat% | — |

7's "the warder procs better beastlord spells" is **the same owner-targeting mechanism as spell 2**
— that's why the question in §1 is worth an hour of source reading before anything else.

⚠️ Whether **SPA 167 pet power can be weighted toward offense vs. defense per spec**, or is a
single scalar, is unverified. If it's a single scalar the two specs differentiate purely on the
`npc_types` template, which still works.

### §9c — Animal stances (4)

One spellgroup (`bst_stance`), equal rank, native overwrite. Per §6.5 magnitudes sit **below Monk,
above all other melee.**

> **That ordering is purely a base-value comparison, so set all melee stance values in one shared
> table** — Monk, Beastlord, Paladin, SK, Ranger, Warrior, Rogue, Berserker, Bard. Otherwise the
> ordering drifts the moment anyone tunes one class in isolation.

| # | base | Spell | Composition | Scaling | Dep. |
|---|---|---|---|---|---|
| 10 | 43,927 | **Crane** | **172–175** avoidance ↑, **323** defensive proc → heal | flat% | — |
| 11 | 43,930 | **Rhino** | **185** damage ↑, **323** defensive proc → **162** damage reduction | flat% | — |
| 12 ⚠️ | 43,933 | **Pack Tactics** | **the escalation loop** — two capped stacking buffs, one per side | flat% | ⚠️ |
| 13 | 43,936 | **Serpent** | **177** double attack ↑, **11** attack speed ↑, no proc | flat% | — |

**Crane's heal fires on *being hit*** (defensive proc, SPA 323) — matching Rhino's shape and the
avoidance theme.

> ⚠️ **Pack Tactics needs care.** "Your damage raises pet damage raises your damage…" is a mutual
> escalation loop and a **runaway risk**. Implement as **two stacking buffs with hard caps** (one
> on each side), each incremented by the other's damage events — **not** as multiplicative
> feedback. **The cap isn't a tuning detail here, it's a correctness requirement.**

### §9d — Bite / rake combos (7)

Straight P3.1 detonation family — the **same detection mechanism** as Necromancer combos, Rogue
finishers and Wizard lures. Data-only once **W1** lands.

- **Rake** = bleed DoT (SPA 0, short duration, high damage), its own spellgroup.
- **Bite** = quick short-range direct damage carrying a **SPA 374 trigger with a Limit checking
  for Rake** on the target.
- On match → applies the **Vampiric** buff to **both beastlord and warder** (SPA 178-style
  lifesteal ⚠️, short duration).

| # | base | Spell | Type | Effect | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 14 | 43,939 | **Rake** | rake | bleed DoT — high damage, low duration | max↑ | — |
| 15 | 43,942 | **Savage Rake** | rake | deeper bleed, longer, higher total | max↑ | — |
| 16 ⭐ | 43,945 | **Bite** | bite | quick DD; **on Rake → Vampiric to both** | max↑ | **W1** |
| 17 | 43,948 | **Crushing Bite** | bite | slower, bigger; **on Rake → strips it for burst** | max↑ | **W1** |
| 18 | 43,951 | **Rending Bite** | bite | **on Rake → warder gains a free attack round** | max↑ | **W1** |
| 19 | 43,954 | **Howl** | — | AE fear-adjacent debuff; **on Rake → spreads the bleed** | max↑ | **W1** |
| 20 | 43,957 | **Feeding Frenzy** | — | **on Vampiric being active → damage window for both** | flat% | **W1** |

> ⭐ **The signature moment:** rake→bite triggering the shared **Vampiric** buff, both hunter and
> warder leeching health mid-fight.

**Curate the combo list — 4–6 marquee pairs, not all permutations**, matching the §6.2 precedent.
The five above (16–20) are the proposed marquee set.

⚠️ **Do combos proc off the warder's attacks?** **Recommend yes for Bite triggering**, since the
pair-as-one-unit fantasy is the whole class and it rewards the reciprocal loop. Needs the pet's
attacks to check owner-applied debuffs ⚠️.

### §9e — Healing (4)

Pet heals are the primary target of his healing; self-heals are **modest** — enough to stay in
melee, not to main-heal a duo.

| # | base | Spell | Target | Scaling | Dep. |
|---|---|---|---|---|---|
| 21 | 43,960 | **Mend Warder** | pet | max↑ | — |
| 22 | 43,963 | **Salve of the Wild** | self | max↑ | — |
| 23 | 43,966 | **Shared Vitality** | **both**, split | max↑ | W2 |
| 24 | 43,969 | **Spiritwalker's Grace** | pet + self HoT | max↑ | — |

The support-warder spec (7) amplifies these via owner-targeted procs — that's the *Spiritwalker*
path made mechanical.

### Self-buffs and utility (6)

| # | base | Spell | Effect | SPAs | Scaling | Dep. |
|---|---|---|---|---|---|---|
| 25 | 43,972 | **Ferocity** | self melee damage + attack speed | **185**, **11** | flat% | — |
| 26 | 43,975 | **Spiritual Brawn** | self + group STR/STA buff | stat SPAs | max↑ | W2 |
| 27 | 43,978 | **Sha's Legacy** | melee slow debuff — his support contribution | **11** neg | flat% | — |
| 28 | 43,981 | **Spirit of the Panther** | group run speed + avoidance | **3**, **172** | flat% | W2 |
| 29 | 43,984 | **Feral Vigor** | self damage shield — bleed texture | **59** | max↑ | — |
| 30 | 43,987 | **Call of the Pack** | short group buff — **also refreshes both reciprocal stacks** | stacking refresh | flat% | **W3** |

27 is deliberately kept: slow is his one real group contribution and dropping it would leave him
with nothing to offer a duo partner but damage.

---

## 3. Payload spells — 43,990–44,019

| id | Payload | Parent |
|---|---|---|
| 43,990 | Beastlord→warder proc payload (haste/proc rate) | 1 |
| 43,991 | Warder→beastlord proc payload (damage) | 2 |
| 43,992 | Warder→beastlord proc payload (crit) | 4 |
| 43,993 | Beastlord→warder proc payload (damage/mitigation) | 5 |
| 43,994 | Pack Bond stack buff — beastlord side | 3 |
| 43,995 | Pack Bond stack buff — warder side | 3 |
| 43,996 | Pack Tactics stack buff — beastlord side, **capped** | 12 |
| 43,997 | Pack Tactics stack buff — warder side, **capped** | 12 |
| 43,998 | **Vampiric** — shared lifesteal buff, both targets | 16 |
| 43,999 | Crane defensive heal proc | 10 |
| 44,000 | Rhino defensive mitigation proc | 11 |
| 44,001 | Rending Bite — warder free attack round | 18 |
| 44,002 | Support-warder owner-targeted buff/heal proc | 7 |
| 44,003–44,019 | *unallocated* | |

---

## 4. Spellgroup allocation

| Group | Line |
|---|---|
| 515,001–515,005 | reciprocal proc lines |
| **515,010** | `bst_warder` — **both specs share it** (native overwrite = one warder) |
| 515,011–515,012 | pet heal/buff lines |
| **515,020** | `bst_stance` — all four share it |
| **515,030** | `bst_rake` — **spells 14 and 15 both**; every Bite Limit names it |
| 515,031–515,035 | bite lines |
| 515,036 | `bst_vampiric` — what spell 20 checks for |
| 515,040–515,043 | healing lines |
| 515,050–515,055 | self-buffs and utility |

515,030 is load-bearing — both rake lines must share it or Bite only combos off one of them.

---

## 5. Build order

Per vault §14g:

1. **Solve owner-targeting from a pet proc (§1).** It unblocks reciprocal procs, the
   support-warder spec, *and* warder-triggered combos. One question, three features.
2. **Stances and bite/rake combos (10–20)** — data-only once W1 lands, parallel.
3. **Warder summons, heals, self-buffs (6, 8–9, 21–29)** — stock, immediate.
4. **Pack Tactics (12) last**, with caps designed in from the start rather than bolted on.

---

## 6. Open items

- [ ] **Can a pet's proc target its owner?** *(Gates three features — check first.)*
- [ ] Can **pet attacks evaluate Limit SPAs against owner-applied debuffs** (warder-triggered
      combos)?
- [ ] **SPA 178 or equivalent** for the Vampiric shared lifesteal.
- [ ] Whether **SPA 167 pet power can be weighted** toward offense vs. defense per spec.
- [ ] **Cross-check stance magnitudes against Monk in a single shared table** (§6.5 ordering) —
      Monk > Beastlord > everyone else.
- [ ] Pack Tactics stacking caps — a correctness requirement, not a tuning detail.
- [ ] Vampiric % and duration; which 4–6 combo pairs ship.
- [ ] Confirm DW / H2H weapon types vs. §2.1.
