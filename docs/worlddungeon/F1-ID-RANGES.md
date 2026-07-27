# F1 — Custom ID Range Allocation Policy

> [!danger] 🔴 **BLOCKER — the spell range below is WRONG and must change. Found 2026-07-27.**
> **The ROF2 client caps spell ids at 45,000.** `common/patches/rof2_limits.h:346` —
> `SPELL_ID_MAX = 45000` — and it is enforced when the spellbook is serialised
> (`common/patches/rof2.cpp:2720`):
> ```cpp
> if (emu->spell_book[r] <= spells::SPELL_ID_MAX)
>     outapp->WriteUInt32(emu->spell_book[r]);
> else
>     outapp->WriteUInt32(0xFFFFFFFFU);   // <-- written as an EMPTY SLOT
> ```
> Any scribed spell above 45,000 is sent to the client as an empty spellbook slot. It is
> invisible and uncastable. **The 100,000 spell base is unusable as written**, and that
> invalidates the Cleric block, the ALL/ALL range, the AA-granted range, and the rows already
> written by migration `0003`.
>
> **Nothing is lost** — `0003` is 12 rows and no player has ever seen them — but **do not author
> further spells until the range is re-decided.** Items, AA, doors, zone_points and npc_types
> ranges are all unaffected; this is a spells-only problem.
>
> **The hard part is that the free band is small.** Stock max is 42,602, so ids
> **42,603–45,000 = ~2,398 slots** are all that fit under the cap. A design of 16 classes with
> ~40 abilities at 10 tiers each wants far more than that. Three ways out, none yet chosen:
> 1. **Raise `SPELL_ID_MAX`** — one constant, but the *client's* own capacity is the real limit
>    and this needs empirical testing, not a source read. ⚠️ Also note the client loads spell
>    text from its local `spells_us.txt`, so custom spells need a client-side file shipped to
>    players regardless.
> 2. **Spend the 2,398 slots deliberately** — fewer tiers, or tiers via AA rank scaling on one
>    spell id rather than ten ids.
> 3. **Reuse stock ids** for spells being replaced anyway, since most stock class assignments are
>    being stripped (see the `baseline-stock-spells-aa` snapshot).
>
> **✅ RESOLVED — see "The Rk. I/II/III model" below. Three tiers makes it fit with room to
> spare, and no cap change is needed.**
>
> See also: `SPELLBOOK_SIZE = 720` and `SPELL_GEM_COUNT` in the same file — the spellbook is
> also finite, which matters for the ALL/ALL scroll plan.



**Status:** decided · branch `feature/foundations`

Every custom record WorldDungeon authors gets an id from the ranges below. The point is that
custom data never collides with stock ROF2/PEQ data, and never collides with a future
`upstream/master` merge or a fresh `make init-peq-database`.

**Renumbering later is the expensive failure.** A custom spell id appears in `spells_new`, in a
spellgroup, in an AA rank effect, in a vendor Lua script, and in a quest global. Pick once.

---

## The ranges

| Table / column | Max stock id | Stock rows | **Custom base** | Headroom |
|---|---:|---:|---:|---:|
| `spells_new.id` | 42,602 | 40,722 | **42,700** ⚠️ *(client-capped at 45,000 — see above)* | ~2.3k |
| `spells_new.spellgroup` | 100,276 | 3,233 groups | **500,000** | 400k |
| `items.id` | 147,494 | 117,944 | **1,000,000** | 852k |
| `aa_ability.id` | 30,195 | 1,568 | **100,000** | 70k |
| `aa_ranks.id` | 49,999 | 6,653 | **100,000** | 50k |
| `doors.id` | 40,569 | 19,249 | **100,000** | 59k |
| `zone_points.id` | 4,519 | 1,831 | **100,000** | 95k |
| `npc_types.id` | 2,000,040 | 67,530 | **per-zone — see below** | — |

Stock maxima measured against the live `peq` database. Rule of thumb for anything not listed:
**next power-of-ten above the stock maximum**, and record it in this table.

### Sub-blocks within a range

Ranges are allocated in blocks of 1,000, assigned as content is authored. Record each
assignment here as it's taken so two work streams can't claim the same block.

| Range | Block | Assigned to | Status |
|---|---|---|---|
| `spells_new.id` | 42,700–42,708 | Cleric mantles, Mk. I/II/III (`0004`) | **claimed** |
| `spells_new.id` | 42,710–42,712 | mantle defensive procs (`0004`) | **claimed** |
| ~~`spells_new.id` 100,000–100,999~~ | — | ~~Cleric~~ — **retired, above the client cap** | void |
| `spells_new.spellgroup` | 500,001 | `clr_mantle` — the mantle pool (`0003`) | **claimed** |
| `spells_new.spellgroup` | 500,002–500,004 | mantle proc lines (`0003`) | **claimed** |
| `spells_new.id` | **110,000–114,999** | **ALL/ALL universal spells** — scroll/drop-earned, not class-gated | reserved |
| `spells_new.id` | **115,000–119,999** | **AA-granted spell-like abilities** | reserved |
| `spells_new.spellgroup` | **510,000–519,999** | ALL/ALL lines | reserved |
| `spells_new.spellgroup` | **520,000–529,999** | AA-granted ability lines | reserved |
| `spells_new.id` | 101,000–101,999 | Monk (P1) | unclaimed |
| `spells_new.id` | 102,000–102,999 | Wizard (P2 — reference detonation template) | unclaimed |
| `items.id` | 1,000,000–1,000,999 | A4 tokens | unclaimed |
| `aa_ability.id` | 100,000–100,999 | A2 Paragon paths | unclaimed |

---

## `npc_types.id` — follow the convention

**Decision: keep `zoneidnumber * 1000 + n`.** Custom NPCs are numbered inside the band of the
zone that is their authoring home.

The observed max of 2,000,040 looked like the convention was already broken. It isn't, in any
way that matters — measured against the live DB:

- **27 rows** sit at or above 2,000,000 (a band for zone id 2000, which does not exist —
  `MAX(zoneidnumber)` is 999). These are off-convention outliers.
- **98 rows** sit between 999,000 and 2,000,000.
- Everything else — **67,405 of 67,530 rows** — obeys the convention.

**Nothing in the C++ derives zone from NPC id at runtime.** A source sweep of `zone/`,
`common/` and `world/` found no `id / 1000` zone inference. The only place that assumes it is
`utils/sql/git/optional/2017_01_16_NPCCombatRebalance.sql`, which uses
`floor(n.id/1000)` to join back to `zone`. So the convention is an *authoring and tooling*
contract, not an engine constraint — which is exactly why it's cheap to keep and worth keeping.

### The per-zone cap is not a real constraint

1,000 ids per zone reads like a ceiling. It isn't, because **`npc_types` rows are not owned by a
zone.** A row is placed by `spawn2`, which carries its own `zoneid`. One `npc_types` row can be
spawned in as many zones as you like. For a project that reuses NPCs heavily across zones —
which is the plan — the zone band is just the *home* the row is filed under, not where it can
appear.

So the practical budget per zone is "how many NPC *definitions* originate here", which for a
hand-authored dungeon zone is tens, not hundreds.

### Conflict check before claiming a band

Reusing a stock zone id means its stock NPCs already occupy part of the band. Occupancy varies:

| Band region | Zones with stock NPCs there |
|---|---:|
| `n >= 500` | 38 |
| `n >= 700` | 26 |
| `n >= 900` | 5 |

So there is **no blanket safe sub-band** — a fixed "custom NPCs use n ≥ 500" rule would collide
in 38 zones. Check per zone instead, before authoring:

```bash
# Replace 999 with the target zoneidnumber
SELECT MOD(id,1000) AS n, name FROM npc_types
WHERE id BETWEEN 999*1000 AND 999*1000+999 ORDER BY n;
```

Then allocate from the top of that zone's free space downward, and record the zone in the table
below.

**If a zone's band is genuinely too full**, fall back to the flat overflow range
**3,000,000+**, documented per NPC. This is the deliberate escape hatch, not the default.

| zoneidnumber | Zone | Stock `n` used | Custom `n` claimed |
|---|---|---|---|
| _(fill in as A7 allocates zones)_ | | | |

---

## `zone.zoneidnumber` — 999 is convention, not a hard ceiling

The backlog flagged this as unverified. Findings:

- `zone.zoneidnumber` is **`int32_t`** in `common/repositories/base/base_zone_repository.h:40`.
- On the wire the field is a **mix of `uint16` and `uint32`** across packet structs
  (`common/eq_packet_structs.h`) — the narrowest occurrence, `uint16`, sets the real protocol
  ceiling at **65,535**, not 999.
- The live DB has `MAX(zoneidnumber) = 999` across **482 distinct zones**, so ~517 ids below
  1000 are unused.

**The zone id is not the constraint. The short name is.** The server sends
`zone_short_name[32]` to the client in the zone-entry struct
(`common/eq_packet_structs.h:363`), and the client loads geometry by that name from the files
it ships. A custom zone therefore needs a **short name whose `.s3d`/`.eqg` the ROF2 client
already has** — it can carry any zone id.

**Practical rule for A7:** allocate custom zones from the free ids **below 999** (517 available,
~48 needed — ample), and pick short names from unused stock zones with usable geometry. Going
above 999 is possible but buys nothing and risks the `uint16` structs.

> ⚠️ **Still unverified:** whether the ROF2 client itself keeps a client-side zone-id table that
> must agree with the server's. Evidence above says short name drives loading, but this has not
> been proven end-to-end. **Prove it in A7 by booting one custom zone id > 482's range before
> authoring all ~48.**

---

## qglobal key naming convention

Detailed schema is **A1**'s job. F1 fixes only the naming so A1 doesn't have to relitigate it:

```
wd_<domain>_<key>
```

Lowercase, underscore-separated, always the `wd_` prefix so custom globals are greppable and
never collide with stock quest scripts. Examples:

- `wd_paragon_path` — Paragon path rank
- `wd_paragon_spec` — specialization flag
- `wd_rebirth_count`
- `wd_level_ceiling`
- `wd_mastery_<class>`

Values: integers where possible. Where structure is unavoidable, a colon-delimited flat string
(`3:1:0`) with the field order documented in A1 — **never JSON**, which is painful to compare in
Lua and in SQL.

---

## `SpellRestriction` ID for W1

W1 adds one new entry to `enum SpellRestriction` (`common/spdat.h:298`). The enum is
live-derived, so any value Live might later claim is a merge hazard.

**Allocated: `1000` — `SpellRestrictionTargetHasSpellGroup`.**

Sparse, far above anything the live-derived values occupy, and a round number that reads as
obviously custom in a diff. Per W1's own design note, the restriction encodes only *that* a
spellgroup is required; *which* spellgroup is read from the spell's limit/max field — so this is
**one id, permanently**, with no block to reserve and no ceiling on spellgroup count.

---

---

## The Rk. I/II/III model — how tiers are delivered

**Copied from stock live data, which is the model to follow.** A real example, `spellgroup 1010`:

| id | name | spellgroup | `rank` | effect layout | base | mana | classes2 |
|---:|---|---:|---:|---|---:|---:|---:|
| 9703 | Blessing of Purpose | 1010 | **1** | 127,134,139 | 9 | 390 | 71 |
| 9704 | Blessing of Purpose **Rk. II** | 1010 | **5** | 127,134,139 | 10 | 390 | 71 |
| 9705 | Blessing of Purpose **Rk. III** | 1010 | **10** | 127,134,139 | 11 | 390 | 71 |

Five things worth copying exactly:

1. **Live ships three tiers, not ten.** This is the client-native convention.
2. **`rank` is 1 / 5 / 10**, not 1 / 2 / 3. The gaps are deliberate — the field is a *position*
   on a 1–10 scale, not a counter. Author 1/5/10.
3. **Consecutive spell ids**, one per tier. **Tiers are not free** — each is its own id. There is
   no "direct upgrade" that reuses one id; the Rk. II mechanism *is* three rows.
4. **Identical effect layout** across all three, ascending base values. This is exactly case 2 of
   the `0003` taxonomy — higher tier overwrites lower through plain value comparison, **no SPA
   149 rider needed**.
5. **Same `classesN` level on all three.** The player scribes whichever they are entitled to, and
   `GetHighestScribedSpellinSpellGroup` (`zone/spells.cpp:6129`) resolves which one they actually
   get — which is precisely the hook A3's spell vendor gates on.

### The budget now works

**DECIDED: three tiers (Rk. I / II / III) at ranks 1 / 5 / 10.**

The free band under the 45,000 cap is **42,603–45,000 ≈ 2,398 ids**. At three tiers:

| | |
|---|---:|
| 16 classes × ~15 distinct lines × 3 tiers | ~720 |
| ALL/ALL universal spells | ~150 |
| AA-granted spell-like abilities | ~200 |
| Procs, recourses, riders | ~200 |
| **Total** | **~1,270** |

**That fits in 2,398 with roughly half the band spare** — without raising `SPELL_ID_MAX` and
without reclaiming a single stock id. Ten tiers would have needed ~2,400 for classes alone and
blown the budget; three tiers is what makes this work.

**Stock-id reuse stays available as headroom, not as a dependency.** Ids freed by stripping
unnecessary stock spells can extend the band if the design grows — and the
`baseline-stock-spells-aa` snapshot means that is reversible. But nothing needs it today.

> ⚠️ **The 5-tier option was considered and is worse than 3**: it costs ~1,200 ids for classes
> alone, and more importantly it is *not* a shape the client or the stock data has ever used, so
> it buys nothing the 3-tier model doesn't already give.

### Scaling: level and stats are primary, tiers are the chase

**DECIDED: Mk. I / II / III.** With scaling carried by `formula` + `max` rather than by flat
per-tier values — so a tier is not "+10 damage", it is **a higher ceiling on what your level and
gear can reach**.

**Level scaling is the `formula` field**, per effect slot
(`Mob::CalcSpellEffectValue_formula`, `zone/spell_effects.cpp:3517`):

| `formula` | Result |
|---:|---|
| 100 *(or 0)* | `base` — flat, **no level scaling** |
| 101 | `base + level/2` |
| 102 | `base + level` |
| 103 / 104 / 105 | `base + level×2 / ×3 / ×4` |
| 109 / 110 | `base + level/4` / `level/6` |
| 111 / 112 | `base + 6×(level−16)` / `8×(level−24)` |
| *(120s)* | `base + N×(level−50)` — post-50 curves |
| `< 100` | `base + (level × formula)` — arbitrary linear slope |

**`max` is the cap on the scaled result** (`zone/spell_effects.cpp:~3814`):

```cpp
if (max_value != 0) {
    if (result > max_value) result = max_value;   // and the mirror for negatives
}
```

#### The tier model this enables

> **Mk. I / II / III share one `formula` and differ mainly in `max`.**
>
> Mk. I scales with level to a modest ceiling. Mk. II raises the ceiling. Mk. III raises it
> again. The spell keeps growing with the *character* the whole way; the tier decides how far it
> is allowed to go.

That fits the intent exactly — **most players live on Mk. I**, and it stays relevant because it
scales with level and stats. **Mk. II arrives after a few rebirths** as a ceiling-raise on
something already familiar. **Mk. III is the elite chase**, and it is valuable precisely because
the player already knows what that spell does and can feel the cap lift.

It also fails gracefully: a player at Mk. I is *behind*, not *broken*, which matters for a
solo-first design.

**Do not express tiers as flat base bumps.** The stock example (base 9 → 10 → 11) is a live
convention we should **not** copy — it makes a tier feel like nothing.

#### Stat scaling

Heal and nuke output already scales with the caster's primary stat and with spell-damage /
heal-amount bonuses natively — that is engine-side and needs no per-spell field.

#### Focus effects — one field decides it

`spells_new.not_focusable` gates the whole focus system for a spell
(`zone/spell_effects.cpp:4708, 5444`). **It must be `0`** on anything meant to benefit from
focus items, mantles, or AA. Since the Cleric's mantles *are* focus effects (SPA 125/132), a
stray `not_focusable = 1` on a heal would silently make the Standard Mantle do nothing to it.

**Author rule: `not_focusable = 0` unless there is a stated reason.** It is a plausible source of
"why is my focus not working" bugs that no log will explain.

### Revised spell ranges

| Purpose | Range |
|---|---|
| Per-class spells | **42,700–44,199** |
| ALL/ALL universal | **44,200–44,499** |
| AA-granted abilities | **44,500–44,899** |
| Procs / recourses / riders | **44,900–44,999** |
| *Reserved buffer* | 42,603–42,699 |

Spellgroups are **not** capped by the client — they are server-side only — so the 500,000+
spellgroup ranges stand unchanged.

---

## Two delivery classes beyond the per-class blocks

The per-class blocks (100,000–109,999) cover spells a class learns as that class. Two other
kinds of spell exist and need their own space, because they are **not** class-scoped and would
otherwise be impossible to audit apart from class content.

### ALL/ALL universal spells — `110,000–114,999`

Earned by item, drop or purchase (a *Scroll of Poke I* grants *Poke I*), usable regardless of
class. In the data these set **all sixteen `classesN` columns to a real level**, not 254 —
254 means AA-granted and would make the scroll unscribable.

> ⚠️ **Stacking hazard, and it is the reason these get their own range.** An ALL/ALL buff will be
> on the same character as class buffs, cast by a class that was never considered when the class
> buff was authored. Per the taxonomy in migration `0003`:
> - ALL/ALL **instant** spells — safe, no interaction possible.
> - ALL/ALL **buffs** — must be given a **deliberately distinct effect layout** from any class
>   pool, or they will land in case-2 value comparison against a class buff and one will silently
>   reject the other. **Never reuse a class pool's layout for an ALL/ALL buff.**
> - An ALL/ALL buff meant to be *exclusive* with something is case 3 and needs the SPA 149 rider.
>
> Practical rule: **give every ALL/ALL buff line its own spellgroup in 510,000+ and its own
> layout.** If two ALL/ALL lines are meant to compete with each other, that is a pool, and pools
> follow the stance rules.

### AA-granted spell-like abilities — `115,000–119,999`

The spell behind an activated AA. These use **`classesN = 254`** (granted, never scribed), which
is the convention stock stance rows already follow and what migration `0003`'s mantles use.

Kept separate from both the class blocks and ALL/ALL because they are **reachable only through
`aa_rank_effects`** — if an AA row is wrong the spell is simply unreachable, and having them in
one contiguous range makes that class of bug findable with a single join.

---

## Rules

1. **Never author a custom row below its custom base.** No exceptions, including "just for a
   quick test" — test rows become production rows.
2. **Claim the block in this file in the same commit** that first writes rows into it.
3. **A new custom record type gets its range added here before its first row exists.**
4. All of it lands as ordered `.sql` under **F2**. Nothing is hand-mutated in the live DB.
5. **A spell's delivery mechanism decides its range**, not its theme: class-scoped → the class
   block; scroll/drop-earned and classless → ALL/ALL; reachable only via an AA → AA-granted.
   A *Scroll of Poke* that only Clerics can read is a **Cleric** spell, not ALL/ALL.
