# A1 — qglobal schema

**Status:** decided · branch `feature/foundations` · *depends: F2 (done)*

Every entitlement script in Track A reads these keys. Design the namespace once — A2, A3, A5,
A6 and W12 all depend on it, and renaming a key later means editing every script that touches
it plus every row already written to a live character.

---

## The one thing that matters most: scoping

`quest_globals` is keyed on **`charid`, `npcid`, `zoneid`, `name`**. A qglobal is only visible in
the scope it was written to, and the scope comes from the `options` bitmask on `setglobal`
(`zone/questmgr.cpp:1769-1778`):

| bit | effect |
|---:|---|
| 1 | `npcid = 0` — visible to all NPCs |
| 2 | `charid = 0` — visible to all characters |
| 4 | `zoneid = 0` — visible in all zones |

**Every WorldDungeon entitlement uses `options = 5`** (`1 | 4`): scoped to **this character**,
readable by **any NPC**, in **any zone**.

```lua
eq.set_global("wd_paragon_path", "3", 5, "F")
```

That combination is not the default. `options = 0` — what you get by forgetting the argument —
writes a global visible only to the one NPC in the one zone that set it, which for an
entitlement is a bug that won't show up until a *different* vendor tries to read it.

- **Never use bit 2.** `charid = 0` makes a global server-wide. Every key here is per-character;
  a stray bit 2 on `wd_rebirth_count` would give the whole server someone's rebirths.
- **Duration is `"F"` (forever)** for all of them. These are entitlements, not timers.

---

## Naming

Per F1: **`wd_<domain>_<key>`** — lowercase, underscore-separated, always the `wd_` prefix so
custom globals are greppable and can never collide with a stock quest script.

## Value encoding

**Integers wherever possible.** Where structure is unavoidable, a **colon-delimited flat
string** with the field order documented here. **Never JSON** — it is painful to compare in Lua
and miserable in SQL, and these values get read far more often than they get written.

`quest_globals.value` is a string column, so an integer is stored as `"3"` and must be compared
as such in Lua (`tonumber(eq.get_global(...))`).

**An unset global reads as an empty string, not `0` or `nil`.** Every read needs a default:

```lua
local path = tonumber(eq.get_global("wd_paragon_path")) or 0
```

---

## The keys

| Key | Type | Meaning | Written by | Read by |
|---|---|---|---|---|
| `wd_paragon_path` | int | Paragon path id, `0` = none chosen | A2 | A3, A5 |
| `wd_paragon_rank` | int | rank within the chosen path, `0`–`10` | A2 | **A3** |
| `wd_paragon_dip` | `p:r` pairs, `,`-separated | dipped secondary paths and their ranks, e.g. `2:3,5:3` | A2 | A3 |
| `wd_paragon_spec` | int | specialization flag, `0`/`1` — gates ranks 6–10 | A2 | **A3** |
| `wd_rebirth_count` | int | times reborn, `0` on a fresh character | W12 | W12, A6 |
| `wd_level_ceiling` | int | current per-character level cap | W12 | W12 |
| `wd_mastery_<class>` | int | mastery points spent in `<class>` | A6 | A5, A6 |

### Notes on the awkward ones

**`wd_paragon_dip`** is the only structured value, and it exists because dipping is inherently a
set. Format is `path:rank` pairs joined by `,`; **dipped paths cap at rank 3** per A3, so the
rank field is always `1`–`3`. Empty string means no dips. Parse in Lua with a
`string.gmatch("(%d+):(%d+)")`.

**`wd_mastery_<class>`** is a key *family*, not one key — `wd_mastery_cleric`, `wd_mastery_monk`
and so on, using the lowercase class short name. This keeps each value a plain integer instead of
forcing a second structured encoding. A6 owns the list.

**`wd_paragon_path` and `wd_paragon_rank` are separate keys** rather than one `path:rank` value.
A3 reads the rank on every spell-scribe check; keeping it a bare integer avoids parsing in the
hottest path in the delivery spine.

---

## Rules

1. **`options = 5`, duration `"F"`, on every write.** No exceptions.
2. **Every read supplies a default** — unset reads as `""`.
3. **A new key is added to this file and to `wd_qglobal_key` before its first write**, in the
   same commit. That table is the machine-readable copy, seeded by migration `0002`.
4. **Never repurpose a key.** Live characters already carry the old meaning. Add a new one.
