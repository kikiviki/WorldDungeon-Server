# GM NPC spawning — best practices

Operating notes for populating zones live, in-game, as a GM. Written for the
"rough it in now, specialise it later" workflow: drop bodies in place, convert them
to merchants / guards / quest givers / monsters afterward.

Companion to [F1-ID-RANGES.md](F1-ID-RANGES.md) — read the `npc_types.id` section there
before you create anything persistent. The interaction between that convention and what
`#npcspawn create` actually does is the main trap on this page.

---

## 1. The two commands do completely different things

| | `#spawn` | `#npcspawn create` |
|---|---|---|
| Writes to DB | **no** | **yes** — `npc_types`, `spawngroup`, `spawnentry`, `spawn2` |
| Survives `#repop` | no | yes |
| Survives zone shutdown | no | yes |
| Needs a target | no | **yes** — copies the targeted NPC |

`#spawn` is a throwaway body in memory. `#npcspawn create` is a database write across four
tables. Reach for `#spawn` while you are still deciding, and only persist once the NPC is
where and what you want.

```
#spawn Kerran_Guard 75 10 - - - -
```

`Name Format: NPCFirstname_NPCLastname` — underscores become spaces and **digits are stripped
from names**, so `Guard2` becomes `Guard`. Number your NPCs in the database, never in the name.

`-` means "use the default" for gender and HP, which is almost always what you want.

## 2. The normal loop

1. `#spawn <name> <race> <level>` — a placeholder at your feet.
2. Move it where you want it. Position is taken from **your** location at the moment you
   persist, so stand exactly where the NPC should be.
3. Target it, then `#npcspawn create [respawntime]`.
4. `#npcedit` to tune stats and appearance.
5. `#npcspawn update` to write appearance changes back.

Related commands worth knowing: `#npcspawn add` (new spawn2 + spawngroup reusing the same
`npc_types` id — this is how you place the *same* NPC in several spots), and `#npcspawn clone`
(copies NPC and spawngroup, spawn2 only, at your current location).

## 3. ⚠️ The ID allocation trap

`#npcspawn create` picks its id via `NpcTypesRepository::GetOpenIDInZoneRange`
(`common/repositories/npc_types_repository.h:64`):

```cpp
const uint32 min_id = zone_id * 1000;
const uint32 max_id = min_id + 999;
// ...
const uint32 npc_id = row[0] ? Strings::ToUnsignedInt(row[0]) + 1 : 0;
return npc_id < max_id ? npc_id : 0;
```

It takes **`MAX(id)` in the band, plus one** — it allocates *bottom-up from the highest row
already present*. F1-ID-RANGES says to "allocate from the top of that zone's free space
downward". **These two rules disagree**, and the engine wins, because the GM command does not
consult the doc.

Concretely, Kerra Isle (zone 74) has stock ids at `n = 0..120`, so the next
`#npcspawn create` there lands on **74121**, not near the top of the band.

Two consequences:

- **Don't hand-allocate custom ids from the top for zones you intend to populate with GM
  commands.** You will strand the space between the stock block and your block, and worse,
  a later `#npcspawn create` will march upward into ids you already reserved on paper. Either
  populate a zone entirely by GM command and let it pack upward, or entirely by migration —
  not both.
- **A full band fails silently-ish.** When `npc_id >= max_id` the function returns `0`. Watch
  the id you get back; if you see 0 or a surprise, stop and check the band before continuing.

The convention is an authoring and tooling contract, not an engine constraint — nothing in
`zone/`, `common/` or `world/` infers zone from NPC id at runtime. So a collision is a
bookkeeping problem, not a crash. It is still a problem.

## 4. GM spawning bypasses the migration discipline

This is the big one for this project. `#npcspawn create` writes **straight to the live
database**. It produces no SQL file, no diff, and nothing to review or replay. Content built
this way exists only in that one database — it is not reproducible, and a DB restore loses it.

Given the dev → prod flow, pick one:

- **Rough in with GM commands on dev, then capture.** Dump the affected tables before and
  after a session and diff them into a numbered migration:

  ```bash
  docker-compose exec -T mariadb mysqldump -uroot -p"$PASS" --skip-extended-insert \
    peq npc_types spawngroup spawnentry spawn2 > before.sql
  # ...spawn things in-game...
  # ...dump again to after.sql, diff, hand-edit into worlddungeon/migrations/00NN_*.sql
  ```

  Filter to the zone's id band so the diff stays readable.

- **Or treat GM spawning as sketching only** — use it to find positions, record the
  coordinates with `#loc`, and write the migration by hand from those numbers. Slower per
  NPC, but the migration is clean from the start and needs no diffing.

The second is usually less work than it sounds, because the thing GM commands are genuinely
best at is *finding the right spot*, and that is exactly the part `#loc` captures.

## 5. Cleaning up

- `#npcspawn remove [remove_spawngroups]` — deletes the `spawn2` row; also removes
  `spawngroup` and `spawnentry` if the argument is `> 0`. Leaves `npc_types` intact.
- `#npcspawn delete` — deletes `spawn2`, `spawngroup`, `spawnentry` **and** `npc_types`.

Use `remove` when the NPC definition is worth keeping and only the placement was wrong. Use
`delete` for genuine mistakes. `delete` is the one that orphans things if the `npc_types` row
is referenced by another zone's `spawn2` — see F1-ID-RANGES on NPC rows not being owned by a
zone. Check before deleting anything you have placed more than once.

## 6. Leave these for the conversion pass

Spawn the body now; these are all pure data changes you can make later without respawning:

| Becomes | What changes |
|---|---|
| Merchant | `npc_types.merchant_id` → a `merchantlist` set |
| Guard | faction, aggro radius, `npc_types.body_type`; pathing grid |
| Quest giver | a script keyed on NPC id or name in the zone's quest directory |
| Townsfolk | usually just faction + a `#npcemote`-style idle script |
| Monster | levels, `npc_types` combat stats, `#npcloot` for drops |

Pathing grids are the exception — they are their own tables (`grid`, `grid_entries`) and are
easier to build once the NPC is already standing where its route should begin.

## 7. Quick reference

```
#spawn <Name_Name> <race> <level> [texture] [hp] [gender] [class]
#npcspawn create [respawn]     persist targeted NPC (new npc_types + spawn)
#npcspawn add [respawn]        place the SAME npc_types id again here
#npcspawn clone [respawn]      copy NPC + spawngroup, spawn2 only
#npcspawn update               save appearance edits
#npcspawn remove [1]           delete spawn2 (and spawngroup/entry if 1)
#npcspawn delete               delete everything incl. npc_types
#npcedit <field> <value>       edit targeted NPC
#npcloot ...                   loot table work
#loc                           record a position for a hand-written migration
#repop                         reload spawns — proves what actually persisted
```

**`#repop` is the test.** Anything that survives it is in the database; anything that
vanishes was a `#spawn` placeholder. Run it before you walk away from a session, or you will
write down positions for NPCs that were never saved.
