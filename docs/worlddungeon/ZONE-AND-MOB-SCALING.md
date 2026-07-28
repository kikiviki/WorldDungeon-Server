# Zone conversion and mob scaling

How a stock zone becomes a WorldDungeon zone, and how its mobs get their numbers.

Foundational — every zone built from here follows this. Companion to
[F1-ID-RANGES.md](F1-ID-RANGES.md) (id allocation) and
[LIVE-DEV-LOOP.md](LIVE-DEV-LOOP.md) (what needs a reload vs a restart).

---

## 1. 📏 A zone is a level, ±2. This is the rule everything else serves.

**Decided.** A zone declares the level a player should **be** while there, and
holds content **±2** around it. A level 5 zone spans **3–7**.

It is not an aesthetic preference; it falls out of the con table. With
`Character:UseOldConSystem` = `false` (our setting), `Mob::GetLevelCon`
(`zone/mob_ai.cpp`) gives:

| Level difference | Con | Meaning |
|---|---|---|
| 0 | White | even fight |
| +1 to +3 | Yellow | hard but winnable |
| **+4 or more** | **Red** | not a fight, a death |
| −6 or more | Gray | no experience awarded |

A player standing at a level 5 zone's centre therefore sees:

| Mob | diff | Con |
|---|---|---|
| 3 | −2 | Dark Blue — easy, still pays experience |
| 5 | 0 | White |
| 7 | +2 | Yellow — hard but winnable |

**Nothing red, nothing gray, and both easy and hard targets in reach at all
times.** That last part is why this is centred rather than bottom-anchored: a
zone measured from its floor is uniformly punishing on arrival and uniformly
trivial by the time you leave, which is worse pacing even though it satisfies
the same con constraint.

**Why ±2 and not ±3.** +4 is the red threshold, so ±3 is the hard limit — a
7-level span. ±2 sits one level inside it deliberately, as headroom for players
who arrive early or lag behind their gear. Gray is −6 below level 15, so a
5-level span also never contains dead content for anyone inside it; a 7-level
span would.

> ⚠️ **±2 describes what is in the zone, never where.** A player arriving at
> `level − 2` still meets +4 red at the top of the band. The `level + 2` mobs
> must sit deeper in than the `level − 2` mobs — §2 is what makes this rule
> survive contact with a real player.

> **The starting zone is the one exception.** Everywhere else, players arrive
> near the middle having outgrown the previous zone. Kerra Isle's characters
> are *created* there at exactly level 1, so they always arrive at the floor.
> It is declared level **2** (band 1–4, clamped) — at level 3 the band would
> reach 5 and put red content in front of a brand new character.

Two consequences worth stating explicitly:

- **A tier is several zones, not one.** T1 covers levels 1–10, so T1 is
  **two or three zones**, each a level ±2. Never one ten-level zone.
- **A zone empties out from the bottom.** Gray is −6, so a level 5 zone's
  weakest mobs (level 3) stop paying experience at player level 9, and its
  strongest (level 7) at 11. In practice a zone is thinning by `level + 4` and
  done by `level + 6`. That is the spacing guide: the **next** zone has to be
  ready before players reach `level + 4`, which for 10-level tiers lands them
  two or three zones deep per tier.

Tiers themselves stay simple: with a level 100 cap and 10-level tiers,
**`tier = ceil(level / 10)`**. The level *is* the tier — no separate tier flag
is needed anywhere in the schema.

---

## 2. ⚠️ Level must be a property of place, never of chance

`NPC::LevelScale()` (`zone/npc.cpp:2558`) does:

```cpp
uint8 random_level = (zone->random.Int(level, maxlevel));
```

and it is called from the **NPC constructor** (`npc.cpp:210`), gated only on
`if (maxlevel > level)`. So **the level is re-rolled on every single respawn.**
Kill a level 1 gnoll and it can come back at level 10, with no visual
difference between the two.

That is strictly worse than a hard zone: the player cannot learn it, cannot
route around it, and cannot tell bad luck from bad play.

**Rule: every WorldDungeon npc_types row sets `maxlevel = 0` or
`maxlevel = level`.** That makes `maxlevel > level` false and the level fixed
forever. Author several rows at fixed levels and place them deliberately —
entrance at level 2, back caves at level 5. Respawns are then always exactly
what was there before, and the zone reads as a designed gradient.

### Variety comes from `spawnentry.chance`, not from level rolls

`spawnentry` has a `chance` column for weighted selection inside a spawngroup:

| npcID | level | chance |
|---|---|---|
| `gnoll_pup` | 2 | 60 |
| `gnoll_scout` | 3 | 30 |
| `gnoll_sentry` | 4 | 10 |

Variation in *which* mob appears, with the level band staying tight. Each is a
real npc_types row carrying its own name, model and loot, so the variety is
something the player can see — unlike an invisible stat reroll.

If a level roll is genuinely wanted somewhere, keep it to **±1**
(`level 2, maxlevel 3`). Never tier-wide.

---

## 3. The zone swap — one flag, both columns

`spawn2` and `spawnentry` both carry `content_flags` **and**
`content_flags_disabled`. One flag per zone, named `wd_<zone>`, flips it:

| Rows | Column | Value |
|---|---|---|
| Stock spawns | `content_flags_disabled` | `wd_<zone>` |
| WD mirror spawns | `content_flags` | `wd_<zone>` |

Flag off → vanilla zone. Flag on → stock hidden, WD mobs live. Nothing is ever
deleted, the swap is atomic, and zones are enabled one at a time as they are
built.

- **`spawn2.pathgrid`** — mirror rows point at the *same grid id* as the stock
  row they replace. Paths are shared, not copied.
- **`npc_types` has no `content_flags` column.** Flags live on *placement*,
  never on the definition. That is a feature: one WD npc_types row can be
  placed in many zones.

> Kerra Isle currently uses the opposite polarity (`wd_kerra_populated` off =
> empty). Migrate it onto this convention so there is one mental model.

---

## 4. Where the numbers live

The engine already has a scaling system: **`npc_scale_global_base`**, keyed on
`(type, level, zone_id_list, instance_version_list)`, carrying ac, hp,
accuracy, attack, all seven stats, all resists, min/max damage, regen,
attack_delay, spell_scale, heal_scale, avoidance.

Split by what changes:

| Concern | Lives in | Why |
|---|---|---|
| Tier curve — hp/ac/stats per level | **DB** `npc_scale_global_base` | engine-native, no code, it is a spreadsheet |
| Which level an archetype is | **DB** `npc_types.level` | fixed per §2 |
| Trash / named / boss multiplier | **DB** the `type` dimension | already a key in the table |
| Per-spawn jitter, conditional rules | **Lua** `EVENT_SPAWN` | anything not expressible as per-level-per-type |

### Drive scaling explicitly from Lua, not by auto-scale

Auto-scale fires at spawn, but `IsAutoScaled()` requires HP, min damage, max
damage **and all seven stats** to be 0. Set a custom AC on one mob and it
silently stops scaling *everything*, including HP.

**So: author WD mobs with zeroed stats and call `npc:ScaleNPC(level)` from
`EVENT_SPAWN`.** That passes `always_scale = true`, which bypasses the
all-or-nothing check entirely, then apply jitter and overrides with
`ModifyNPCStat` afterward. One predictable path instead of two interacting
ones.

---

## 5. Traps

**⚠️ Scale `type` is derived from the NPC's name, including capitalization.**
`NpcScaleManager::GetNPCScalingType` (`zone/npc_scale_manager.cpp:554`):

```cpp
if (npc->IsRaidTarget()) return 2;
if (npc->IsRareSpawn() || npc_name.find('#') != std::string::npos || isupper(npc_name[0])) return 1;
return 0;
```

`Gnoll Sentry` silently gets **named-tier** stats; `a_gnoll_sentry` gets trash
stats. The type cannot be assigned in the database — it is inferred. Adopt a
naming convention deliberately or this bites constantly and invisibly.

**The scale table stops at level 90.** Currently 3 types × 90 levels = 270
rows, all global (`zone_id_list = 0`). A level 100 cap needs 30 more rows
(3 types × levels 91–100). No rows means no scaling at all.

**No live reload for scaling.** `LoadScaleData()` runs once at zone boot
(`zone/main.cpp:420`) and there is no reload type for it. Iterating on the
curve costs a **zone restart**, unlike nearly everything else. Get the curve
shape roughly right in one pass rather than nudging it live.

---

## 6. Pre-flight check before enabling a zone

Two invariants, one query each. Both must pass before a zone's flag goes on.

Both are automated by **`worlddungeon/bin/wd-zone-check`**, which reads the
declared level from `wd_zone` (migrations 0025/0026) and diffs it against what
the spawn tables actually contain. It exits non-zero on any failure, so it can
gate a deploy. The queries it runs, for reference:

**Level histogram — no holes, nothing outside level ±2:**

```sql
SELECT n.level, COUNT(*) AS spawn_points
FROM spawn2 s
JOIN spawnentry se ON se.spawngroupID = s.spawngroupID
JOIN npc_types  n  ON n.id = se.npcID
WHERE s.zone = 'kerraridge' AND s.content_flags = 'wd_kerraridge'
GROUP BY n.level ORDER BY n.level;
```

**No rerolls anywhere:**

```sql
SELECT n.id, n.name, n.level, n.maxlevel
FROM spawn2 s
JOIN spawnentry se ON se.spawngroupID = s.spawngroupID
JOIN npc_types  n  ON n.id = se.npcID
WHERE s.zone = 'kerraridge' AND s.content_flags = 'wd_kerraridge'
  AND n.maxlevel > n.level;      -- must return zero rows
```

A hole in the histogram, or a tail more than 3 levels above the zone's entry
level, means the zone is not ready. These are pre-flight checks, not something
to discover in play.
