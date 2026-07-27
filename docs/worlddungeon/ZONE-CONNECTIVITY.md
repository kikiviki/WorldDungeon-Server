# Zone Connectivity — How Zones Actually Connect

Findings from dumping the live PEQ database with
[`tools/dump-zone-graph.sh`](tools/dump-zone-graph.sh). Regenerate any time:

```bash
docs/worlddungeon/tools/dump-zone-graph.sh /tmp/zone-graph
```

This is the **classic-EQ adjacency reference** the vault's *Open Decisions* asks for:

> *"Any bespoke edges that still accidentally match a classic EQ adjacency should be re-wired;
> audit against a zone-connection reference before world-build (§1.3)"*

Core Pillar 1 says no two zones may connect the way they do on a live EQ server. You can't
enforce that without knowing what live actually does — this is that list.

---

## The four connection mechanisms

| Type | Source | Directed edges | Distinct pairs |
|---|---|---|---|
| **zoneline** | `zone_points` → `target_zone_id` | 1,107 | 534 |
| **teleport** | `doors`, `opentype` 57–58, with `dest_zone` | 290 | 196 (with `door`) |
| **door** | `doors`, other opentypes, with `dest_zone` | 35 | ” |
| **script** | quest `MovePC` / `eq.move_pc` | 46 destinations | — |

Totals: 618 zones, 591 distinct connected pairs.

### Teleport doors are the clicky-portal mechanism

Source-confirmed at [`zone/doors.cpp:542`](../../zone/doors.cpp):

```cpp
// teleport door
if (EQ::ValueWithin(m_open_type, 57, 58) && HasDestinationZone()) {
```

`opentype` 57 or 58 plus a `dest_zone` **is** the PoK-book / clicky-orb behaviour. Nothing
else is needed — no script, no spell, no custom code. Key gating is built in via
`doors.keyitem`, and the door auto-adds to the key ring.

Worked examples straight from the DB:

- **PoK books** — `poknowledge` has 22 `opentype` 58 doors named `POK*PORT500`, one per
  destination (`POKQNSPORT500` → `qeynos2`, `POKNRKPORT500` → `nektulos`, …).
- **Blackburrow's ruby** — `ACRUBY301`, `opentype` 58, `blackburrow` → `jaggedpine`.
  The reverse side is `DSROCK301`/`DSROCK302` in `jaggedpine`.

### Important gotchas

- **Same-zone destinations are not edges.** `Doors::IsDestinationZoneSame()` handles
  intra-zone warps through the same code path. Filter them or the graph inflates.
- **`ZoneID()` resolves short names only** — [`common/zone_store.cpp:77`](../../common/zone_store.cpp)
  is a plain string compare returning 0 on failure. It does **not** parse numeric strings.
- **`doors.zone` casing is inconsistent** (`PoKnowledge` vs `poknowledge`). Harmless at
  runtime — the `const char*` overload of `GetZoneID` lowercases — but it will silently split
  your counts in any analysis. Normalize.

---

## PEQ data bug found: 46 dead clicky doors

46 `doors` rows store a **numeric zone id** in `dest_zone` instead of a short name — e.g.
`OBJ_PORTAL_4STAGE` in `chapterhouse` with `dest_zone = '752'` (Shard's Landing).

Since `ZoneID()` only compares short names, these resolve to **zone 0**. The clickies are
dead. All of them are House of Thule–era content (Shard's Landing and its satellites), so
this is well outside v1 scope — recorded so nobody rediscovers it later. They're segregated
into `edges-broken.tsv` by the dump tool rather than silently dropped.

---

## The finding that matters for our design

**57 zone pairs are reachable by clicky only, with no zoneline at all.** Almost all of them
are one pattern, and it is *exactly the World Dungeon model*:

| Hub zone | Clicky portals out | What it is |
|---|---|---|
| `sro` | `ruja` … `rujj` (10) | Rujarkian Hills |
| `lfaydark` | `mmca` … `mmcj` (10) | Miragul's Menagerie |
| `nro` | `takb` … `takj` (9) | Takish-Hiz |
| `everfrost` | `mira` … `mirj` (5) | Miragul's |
| `innothule` / `guktop` | `guka` … `gukh` (7) | Guk |
| `provinggrounds` | `chambersa` … `chambersf` (6) | The Chambers |

**LDoN already implements hub-and-wing.** One overworld zone, ten `opentype` 58 doors, ten
dungeon wings that are otherwise unreachable. That is Kerra → Nexus → wing zones, built and
shipping, with no custom code.

Practical consequences for the roadmap:

1. **A7 (zone topology build-out) needs no engine work for bespoke edges.** Connections are
   `doors` rows and `zone_points` rows — pure data, which lands squarely in **F2's**
   migration mechanism. This should reduce A7's estimate.
2. **A8 (safe-zone travel and ports)** is likewise data. `doors.keyitem` gates a portal on an
   item; the qglobal-based gating from **A2/A3** covers the rest via the same script hooks.
3. **The §1.3 audit is now mechanical.** Diff our proposed adjacency list against
   `edges.tsv`; any pair appearing in both is an accidental live-EQ match and must be rewired.

The other clicky-only edges are progression gates (`ikkinz`→`kodtaz`, `uqua`→`yxtta`,
`tacvi`→`txevu`, `inktuta`→`qvic`) and a few one-offs worth knowing —
`cobaltscar`→`mischiefplane`, `guildhall`→`guildlobby`, `poknowledge`→`shadowrest`.

---

## Hub sizes for calibration

Distinct neighbours, all mechanisms:

| Zone | Neighbours |
|---|---|
| `potranquility` | 36 |
| `poknowledge` | 34 |
| `nexus` | 16 |
| `lfaydark` | 15 |
| `timorous`, `sro`, `oldfieldofbone`, `nro` | 12 |
| `everfrost` | 11 |

A classic overworld zone runs **3–6** neighbours; the outliers above are all deliberate hubs.
Useful calibration for the vault's connection-count targets — our safe-zone hubs should sit
nearer `nexus` (16) than `poknowledge` (34), which is a travel terminal rather than a place.

---

## Visual map: `zone-map-graph.py`

Renders the graph with **real zone geometry** — each node is the zone's actual Brewall map,
headed `shortname (id)`, wired with connections read live from the database.

```bash
docs/worlddungeon/tools/zone-map-graph.py --from blackburrow --depth 2 -o bb.html
docs/worlddungeon/tools/zone-map-graph.py --zones sro,ruja,rujb,rujc
docs/worlddungeon/tools/zone-map-graph.py --all --engine sfdp --limit 0 -o world.html
```

Output is one self-contained HTML file — inline SVG, drag to pan, scroll to zoom, hover an
edge for the mechanism and the door/point name. No external assets, nothing cached.

| Line | Meaning |
|---|---|
| Solid blue | zoneline — walk through |
| Dashed amber | clicky portal or destination door |
| Dotted violet | quest-script port |
| Arrowheads | direction of travel; two-way connections get both ends |

Where a pair has several mechanisms the strongest wins the styling — walking beats clicking —
so `blackburrow ↔ jaggedpine` draws solid even though it also has the ruby clicky. The hover
tooltip lists every mechanism regardless.

Same-name map files are stacked: `acrylia.txt`, `acrylia_1.txt`, `acrylia_2.txt` are one node.

**469 of 618 zones have Brewall maps**; the rest (mostly instanced content) are skipped and
reported. The full world takes ~12s and produces a ~5 MB file. Dense dungeon maps are
decimated to `--max-segments` per zone, dropping the *shortest* segments so the silhouette
survives.

### Coordinates — the part that bites

**Brewall map files store negated world coordinates:** `map(x,y) = -db(x,y)`. Verified against
`zone_points` — `blackburrow → everfrost` is `db(-345.2, 94.5)`, and the map's
`to_Everfrost_Peaks` marker sits at `(343.7, -90.1)`.

In map space **+x is east and −y is north**, so map coordinates plot *directly* into SVG
(which is y-down) with north up and east right — no transform at all. Confirmed against known
geography rather than assumed:

| Zone | Exit | Position in range | Expected |
|---|---|---|---|
| `freportw` | East Commonlands | 2% of x | west ✓ |
| `ecommons` | West Freeport | 97% of x | east ✓ |
| `oasis` | North Ro | 3% of y | north ✓ |
| `oasis` | South Ro | 70% of y | south ✓ |
| `qeytoqrg` | Western Karana | 92% of x | east of Qeynos ✓ |

Database coordinates are negated on the way in, so DB overlays line up with map geometry.

---

## Output files

`dump-zone-graph.sh` writes to its output directory:

| File | Contents |
|---|---|
| `edges.tsv` | Combined typed edge list — `from_zone`, `to_zone`, `type`, `detail` |
| `edges-zoneline.tsv` | Zonelines only |
| `edges-teleport.tsv` | Clicky portals only |
| `edges-door.tsv` | Other destination doors |
| `edges-script.tsv` | Quest-script ports, by destination |
| `edges-broken.tsv` | The 46 numeric-`dest_zone` rows |
| `zone-ids.tsv` | `zoneidnumber` → `short_name` |

Deliberately **not** committed — it's regenerable, ~1,500 rows, and would churn on every PEQ
update. Regenerate on demand.
