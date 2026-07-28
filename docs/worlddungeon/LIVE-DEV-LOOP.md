# Live dev loop

How to get a change in front of a connected client as fast as it can go, now that
testing is real-time. The rule is simple: **match the deploy lever to the layer you
changed.** Most changes do not need a restart, and a few genuinely do.

Companion to [`worlddungeon/README.md`](../../worlddungeon/README.md) (the migration
runner) and the vault's *AkkStack Dual-Environment Workflow* (the dev → prod path).

---

## 1. The ladder — cheapest lever that works

| You changed | Lever | Cost | Restart? |
|---|---|---|---|
| Lua / Perl quest script | `#reload quest` (alias `#rq`) | instant | no |
| A rule (`rule_values`) | `#reload rules` | instant | no |
| A content flag | `#reload content_flags` | instant | no |
| Spawns / spawn2 | `#reload world_repop` | seconds | no |
| Merchant lists | `#reload merchants` | instant | no |
| Loot tables | `#reload loot` | instant | no |
| Factions | `#reload factions` | instant | no |
| Zone points, doors, objects, traps | `#reload zone_points` / `doors` / `objects` / `traps` | instant | no |
| Skill caps, base data | `#reload skill_caps` / `base_data` | instant | no |
| **Existing** item or spell **rows** | `#hotfix` | seconds | no |
| **New** item or spell **rows** | full restart | minutes | **yes** |
| C++ | `n` then `make restart` | minutes | **yes** |

`#reload` with no argument prints the full list in-game. Append `global` (or `globally`)
to push the reload to every running zone instead of just yours — worth the habit, since a
change verified in one zone and stale in the next is a confusing half hour.

Character-creation data (`char_create_combinations`, `char_create_point_allocations`,
`start_zones`) is read by **world**, not zone, and re-read per character creation — so it
needs no reload at all. Make the character and look.

## 2. ⚠️ Items and spells are the exception — know which case you're in

Items and spells live in **shared memory**, not in the zone process, so they do not follow
the reload table above. `#hotfix` rebuilds and swaps shared memory live, but it **refuses
outright** if the row counts drifted (`zone/command.cpp:615`):

```
Your database does not have the same item count as your shared memory.
Database Count: N  Shared Memory Count: M
```

That means:

- **Editing an existing item or spell row → `#hotfix` works.** Damage, delay, stats, spell
  values — all live, no restart.
- **Adding or deleting item or spell rows → `#hotfix` refuses.** You need a full restart to
  regenerate shared memory.

**The workaround the engine itself suggests: pre-allocate placeholder rows.** If you know
you want twenty more T1 weapons, insert twenty placeholder rows in one migration, take the
restart once, and then tune all twenty live with `#hotfix` for as long as you like. This is
worth doing deliberately for the ranges F1-ID-RANGES has already claimed — especially the
6 pending spell migrations, which are all row *additions* and will each otherwise cost a
restart.

## 3. Migration hygiene, now that changes land fast

Two things went wrong in one session and both are cheap to avoid.

**Always scaffold with the runner, never hand-name a file.**

```bash
./worlddungeon/bin/wd-migrate new <short_name>
```

`new` derives the next version from the highest file on disk. Hand-numbering caused a
real collision — two 0018s and two 0019s written minutes apart — which `status` reports as
`DRIFTED` because state is keyed on the version number alone. Renumbering the newer pair
fixed it, but only because neither had been recorded yet.

**Always apply through the runner, never raw `mysql`.**

```bash
./worlddungeon/bin/wd-migrate up --only 0024
```

Applying SQL by hand runs the change but records no checksum, so `status` cannot tell you
what is actually in the database. `--only` is the important half: a bare `up` would apply
every pending migration, and 6 are pending on purpose behind the 0004 spell gate.

**Check `status` before starting and after finishing.** It exits non-zero on any problem,
so it is the one-second answer to "is the database what I think it is".

## 4. Suggested rhythm

1. `git log --oneline -3` and `wd-migrate status` before starting — confirms nothing landed
   underneath you. (Both of this session's collisions would have been caught here.)
2. Make the change; scaffold migrations with `wd-migrate new`.
3. Apply with `up --only`, pull the matching reload lever from §1.
4. Test against the checklist; tick the box in the same pass.
5. Commit per logical change, not per session. Small commits are what make
   `#hotfix`-vs-restart mistakes cheap to unwind.

Commit early and often on the feature branch; the tag discipline in the dual-environment
workflow is what protects prod, so there is no reason to batch work locally.

## 5. What still costs a restart, unavoidably

- Any C++ change. Incremental ninja builds with ccache are ~20-30s for a single file, so
  the restart usually dominates — batch C++ work rather than interleaving it with data work.
- Adding or removing item/spell rows (§2).
- `eqemu_config.json` and `.env` changes.

Everything else should be a reload. If you find yourself restarting for something not on
this list, check the reload list first — it is longer than it looks.
