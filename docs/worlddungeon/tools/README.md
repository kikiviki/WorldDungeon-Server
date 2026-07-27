# WorldDungeon tools

Two tools for reading the zone graph out of the live database.

| Tool | Answers |
|---|---|
| [`zone-map-graph.py`](zone-map-graph.py) | *What is this zone connected to?* — a visual map graph, or a text island report |
| [`dump-zone-graph.sh`](dump-zone-graph.sh) | *Give me every connection as data* — typed edge list for scripting and diffing |

Both read the database live. Nothing is cached; re-run to pick up changes.

Analysis and findings live in [`../ZONE-CONNECTIVITY.md`](../ZONE-CONNECTIVITY.md) — this file
is just how to drive the tools.

---

## Prerequisites

- **Docker access** to the akk-stack mariadb container. If you get
  `permission denied ... /var/run/docker.sock`, your shell doesn't have the `docker` group
  yet — log out and back in (akk-stack README §6). Both tools fall back to `sg docker`
  automatically, so they generally work anyway.
- **graphviz** (`dot`, `neato`, `sfdp`) — layout only, for `zone-map-graph.py`.
- **Brewall client maps** at `/opt/eqemu-servers/brewell`.

Overrides, if your paths differ:

```bash
export STACK_DIR=/opt/eqemu-servers/akk-stack     # holds .env and docker-compose
export BREWALL_DIR=/opt/eqemu-servers/brewell     # holds *.txt map files
```

Credentials are read from `$STACK_DIR/.env` and passed via `MYSQL_PWD` — never printed, never
put on a command line.

---

## `zone-map-graph.py`

Renders a graph where **each node is the zone's real map**, headed `shortname (id)`, wired
with connections read from the database. Output is one self-contained HTML file — inline SVG,
drag to pan, scroll to zoom, hover an edge for the mechanism and door name.

### Start here

```bash
# Everything reachable from a zone - the island check
docs/worlddungeon/tools/zone-map-graph.py --from buriedsea -o island.html

# Just the immediate neighbours
docs/worlddungeon/tools/zone-map-graph.py --from blackburrow --depth 1 -o bb.html

# Is anything stranded? Text report, no rendering, fast
docs/worlddungeon/tools/zone-map-graph.py --components
```

### Choosing zones

| Flag | Effect |
|---|---|
| `--from ZONE` | Walk out from a seed. **Unbounded by default** — the whole reachable set. |
| `--depth N` | Stop N connections out from `--from`. Omit for no limit. |
| `--zones a,b,c` | Exactly these, comma-separated. |
| `--all` | Every zone that has a map file. |

`--from` alone is the island test: if `buriedsea` comes back with 5 zones, that's the entire
cluster. A zone with no connections at all says so explicitly.

### Direction

By default connections are treated as two-way. **25% of them aren't.**

```bash
--directed        # follow only outbound edges
```

Two different questions:

- **undirected** — *what cluster does this zone belong to?* (362 zones from `blackburrow`)
- **directed** — *where can a player standing here actually get to?* (257 from `bazaar`)

With `--components`, `--directed` reports **strongly-connected** components: sets of zones you
can round-trip between. That's a much stricter view — 94 components rather than 4.

### Appearance

| Flag | Default | Notes |
|---|---|---|
| `--limit N` | 120 | Caps zones, keeping the best-connected. **`0` = no cap.** |
| `--node-size PX` | 210 | Node width; height follows the map's aspect ratio. |
| `--max-segments N` | 1400 | Map detail per zone. Lower = smaller, faster files. |
| `--engine E` | `neato` | `neato`, `sfdp`, `fdp`, `dot`, `circo`. Use `sfdp` above ~150 zones. |
| `--labels` | off | Mark zone exits on each map with hoverable dots. |
| `--center-edges` | off | Draw connections centre-to-centre instead of from real exit coords. |
| `-o FILE` | `zone-graph.html` | Output path. |

### Reading the output

| Line | Meaning |
|---|---|
| Solid blue | zoneline — walk through |
| Dashed amber | clicky portal or destination door |
| Dotted violet | quest-script port |
| Arrowheads | direction; two-way connections get both ends |

Where a pair has several mechanisms the strongest wins the styling — walking beats clicking —
so `blackburrow ↔ jaggedpine` draws solid despite also having the ruby clicky. Hover lists
every mechanism regardless.

### Where connections attach

Lines land on the **actual exit coordinates** on each map — the zone line or clicky you walk
into — not on node centres. A small dot marks each anchored end.

Coverage isn't total, so three sources are tried in order:

1. `zone_points.x/y` — the exit itself. Only **48%** of pairs have it; the rest are
   client-driven zone lines whose server row exists only to define the destination.
2. `zone_points.target_*` of the **reverse** edge — where you land coming the other way is
   right beside where you leave. Recovers another **30%**.
3. `doors.pos_x/pos_y` for clicky portals, which nearly always have coordinates.

The remaining ~21% fall back to node centres and are drawn **faded, with no dots** and an
`[approximate: no exit coords]` note in the tooltip, so a guess never looks like a fact. Every
run prints its anchored/total count. In practice: 88% on the full mainland, 100% on most
small graphs.

Arrowheads and the stub of line inside each node are drawn in a **separate layer above the
nodes**. They have to be: the anchor is *inside* the box, so anything drawn before the node
gets painted over and the arrow disappears. Edge lines keep a dark halo so they stay legible
where they cross an unrelated node.

`--center-edges` reverts to centre-to-centre if you prefer the cleaner look.

### Worked examples

```bash
# The two real islands in the current database
zone-map-graph.py --from buriedsea -o island.html        # 5 zones
zone-map-graph.py --from devastation -o rage.html        # 2 zones

# The whole mainland - needs the cap lifted and lighter maps
zone-map-graph.py --from blackburrow --limit 0 --max-segments 400 \
                  --engine sfdp -o mainland.html         # 362 zones

# LDoN hub-and-wing: 2 solid zonelines, 10 dashed portals
zone-map-graph.py --from sro --depth 1 -o hub.html

# Everything
zone-map-graph.py --all --limit 0 --max-segments 500 --engine sfdp -o world.html
```

---

## `dump-zone-graph.sh`

Every connection as a typed edge list, for diffing and scripting.

```bash
docs/worlddungeon/tools/dump-zone-graph.sh /tmp/zone-graph
```

| File | Contents |
|---|---|
| `edges.tsv` | Combined — `from_zone`, `to_zone`, `type`, `detail` |
| `edges-zoneline.tsv` | Zonelines only |
| `edges-teleport.tsv` | Clicky portals only |
| `edges-door.tsv` | Other destination doors |
| `edges-script.tsv` | Quest-script ports by destination |
| `edges-broken.tsv` | 46 doors with a numeric `dest_zone` — dead, see the analysis doc |
| `zone-ids.tsv` | `zoneidnumber` → `short_name` |

Output is **not** committed — it's regenerable and would churn on every PEQ update. Pass an
output directory outside the repo; with no argument it writes to `./zone-graph`.

Main use is the Pillar 1 audit: diff a proposed adjacency list against `edges.tsv`, and
anything in both is an accidental live-EQ match to rewire.

---

## Gotchas

**Counting zones.** The `zone` table has **618 rows but only 482 distinct zones** — the extras
are per-version rows. Always `COUNT(DISTINCT short_name)`, or per-zone ratios come out wrong.

**Zones with no map.** 469 of 482 zones have Brewall maps; the rest are mostly instanced
content. They're skipped and named on stderr, not silently dropped.

**`--limit` truncation.** Hitting the cap prints a loud warning — a truncated graph looks *more
isolated than it is*, which is exactly the wrong impression when hunting islands. If you see
it while investigating connectivity, re-run with `--limit 0`.

**Dark map colours.** Brewall uses deep blues and greens that vanish at thumbnail size, so
line colours are scaled up to a brightness floor - hue preserved, brightness lifted.

**Coordinates.** Brewall files store negated world coordinates (`map(x,y) = -db(x,y)`), and in
map space `+x` is east and `−y` is north, so they plot straight into SVG with north up. Full
derivation and the geography checks that confirm it are in
[`../ZONE-CONNECTIVITY.md`](../ZONE-CONNECTIVITY.md#coordinates--the-part-that-bites).

**Big graphs.** Above ~150 zones use `--engine sfdp` and drop `--max-segments`; `neato` gets
slow and the file gets large. The full world is ~12s and ~5 MB.
