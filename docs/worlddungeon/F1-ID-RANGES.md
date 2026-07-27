# F1 — Custom ID Range Allocation Policy

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
| `spells_new.id` | 42,602 | 40,722 | **100,000** | 57k before stock |
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
| `spells_new.id` | 100,000–100,999 | Cleric (P1) | **partly claimed** |
| ↳ `spells_new.id` | 100,100–100,108 | Cleric mantles, tiers I–III (`0003`) | **claimed** |
| ↳ `spells_new.id` | 100,109–100,129 | Cleric mantles, tiers IV–X | reserved |
| ↳ `spells_new.id` | 100,110–100,112 | mantle defensive procs (`0003`) | **claimed** |
| `spells_new.spellgroup` | 500,001 | `clr_mantle` — the mantle pool (`0003`) | **claimed** |
| `spells_new.spellgroup` | 500,002–500,004 | mantle proc lines (`0003`) | **claimed** |
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

## Rules

1. **Never author a custom row below its custom base.** No exceptions, including "just for a
   quick test" — test rows become production rows.
2. **Claim the block in this file in the same commit** that first writes rows into it.
3. **A new custom record type gets its range added here before its first row exists.**
4. All of it lands as ordered `.sql` under **F2**. Nothing is hand-mutated in the live DB.
