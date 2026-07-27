#!/usr/bin/env python3
"""
Generate a live zone-connection map: real zone geometry from the Brewall client
maps, laid out as a flowchart, wired with connections read from the database.

  node   one zone, drawn from its Brewall map file(s), headed "shortname (id)"
  solid  zoneline        - walk through
  dashed teleport/door   - clicky portal (doors, opentype 57-58)
  dotted script          - quest MovePC
  arrow  direction of travel; two-way connections get arrows at both ends

Connections attach at the REAL exit coordinates on each map - the zone line or
clicky you actually walk into - not at node centres. A dot marks each anchored
end; faded lines with no dots had no usable coordinate. --center-edges reverts
to centre-to-centre.

Output is a single self-contained HTML file (inline SVG, pan/zoom, no external
assets). Regenerate any time - nothing is cached.

COORDINATES
    Brewall map files store NEGATED world coordinates: map(x,y) = -db(x,y).
    Verified against zone_points, e.g. blackburrow -> everfrost is db(-345.2,
    94.5) and the map's "to_Everfrost_Peaks" marker is (343.7, -90.1).

    In map space +x is EAST and -y is NORTH, so map coordinates plot directly
    into SVG (which is y-down) with north up and east right - no transform.
    Verified against known geography: freportw's East Commonlands exit sits at
    2% of its x-range (west), ecommons' West Freeport exit at 97% (east),
    oasis' North Ro exit at 3% of y (north) and South Ro at 70% (south).

    Database coordinates are negated on the way in so overlays line up.

Examples
    zone-map-graph.py --from buriedsea                  everything reachable (island check)
    zone-map-graph.py --from blackburrow --depth 2      stop 2 connections out
    zone-map-graph.py --from bazaar --directed          only where you can actually GET TO
    zone-map-graph.py --components                      text report: find every island
    zone-map-graph.py --zones blackburrow,everfrost,qeytoqrg
    zone-map-graph.py --all --engine sfdp --limit 0 -o world.html
"""

import argparse
import glob
import html
import math
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict

STACK = os.environ.get("STACK_DIR", "/opt/eqemu-servers/akk-stack")
MAPS = os.environ.get("BREWALL_DIR", "/opt/eqemu-servers/brewell")

EDGE_STYLE = {  # type -> (svg dash, colour, legend label)
    "zoneline": ("", "#7ecbff", "zoneline (walk)"),
    "teleport": ("9,5", "#ffcf5c", "clicky portal"),
    "door":     ("9,5", "#ffcf5c", "door"),
    "script":   ("2,5", "#c08bff", "script port"),
}


# ---------------------------------------------------------------- database

def run_sql(sql):
    """Run SQL in the akk-stack mariadb container. Credentials stay in env."""
    env = dict(os.environ)
    for line in open(os.path.join(STACK, ".env"), errors="ignore"):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()

    inner = (
        'docker compose exec -T -e MYSQL_PWD="$MARIADB_PASSWORD" mariadb '
        'mysql -u"$MARIADB_USER" "$MARIADB_DATABASE" --batch --skip-column-names -e "$SQL"'
    )
    env["SQL"] = sql
    probe = subprocess.run(["docker", "info"], capture_output=True, env=env)
    cmd = ["bash", "-c", inner] if probe.returncode == 0 else ["sg", "docker", "-c", inner]

    r = subprocess.run(cmd, capture_output=True, text=True, cwd=STACK, env=env)
    if r.returncode != 0:
        sys.exit("SQL failed:\n" + (r.stderr or "").strip())
    return [ln.split("\t") for ln in r.stdout.splitlines() if ln.strip()]


def load_zones():
    """short_name -> (id, long_name)"""
    rows = run_sql(
        "SELECT LOWER(short_name), zoneidnumber, long_name FROM zone "
        "WHERE short_name<>'' GROUP BY short_name;"
    )
    return {r[0]: (r[1], r[2] if len(r) > 2 else "") for r in rows}


def load_edges():
    """(from, to, type) -> detail. Same-zone and unresolvable rows excluded."""
    edges = {}
    for a, b, d in run_sql(
        "SELECT DISTINCT LOWER(zp.zone), LOWER(z2.short_name), CONCAT('point ',zp.number) "
        "FROM zone_points zp JOIN zone z2 ON z2.zoneidnumber=zp.target_zone_id "
        "WHERE zp.zone<>z2.short_name AND zp.zone<>'' AND z2.short_name<>'';"
    ):
        edges.setdefault((a, b, "zoneline"), d)

    for a, b, t, d in run_sql(
        "SELECT DISTINCT LOWER(d.zone), LOWER(d.dest_zone), "
        "IF(d.opentype IN (57,58),'teleport','door'), d.name FROM doors d "
        "WHERE d.dest_zone NOT IN ('','NONE') AND d.dest_zone<>d.zone "
        "AND d.dest_zone NOT REGEXP '^-?[0-9]+$';"
    ):
        edges.setdefault((a, b, t), d)
    return edges


def load_anchors():
    """
    Where on each zone's map a connection physically attaches.

    anchors[(a, b)] = (x, y) in MAP space - the spot in zone a you leave from
    when travelling to b.

    Coverage is imperfect, so three sources are tried in order:

      1. zone_points.x/y      - the exit itself. Present for only 48% of pairs;
                                the rest are client-driven zone lines whose
                                server row exists to define the destination.
      2. zone_points.target_* - of the REVERSE edge. Where you land in a when
                                coming from b is right beside where you leave a
                                for b. Recovers another 30%.
      3. doors.pos_x/pos_y    - for clicky portals, which nearly always have it.

    The remaining ~21% get no anchor and fall back to the node centre.
    Several exits for one pair (a long border split into segments) are averaged.
    """
    own, back, door = defaultdict(list), defaultdict(list), defaultdict(list)

    for a, b, x, y, tx, ty in run_sql(
        "SELECT LOWER(zp.zone), LOWER(z2.short_name), zp.x, zp.y, zp.target_x, zp.target_y "
        "FROM zone_points zp JOIN zone z2 ON z2.zoneidnumber=zp.target_zone_id "
        "WHERE zp.zone<>z2.short_name AND zp.zone<>'' AND z2.short_name<>'';"
    ):
        x, y, tx, ty = float(x), float(y), float(tx), float(ty)
        if (x, y) != (0.0, 0.0):
            own[(a, b)].append((x, y))
        if (tx, ty) != (0.0, 0.0):
            back[(b, a)].append((tx, ty))      # arriving in b anchors b's side

    for a, b, px, py, dx, dy in run_sql(
        "SELECT LOWER(d.zone), LOWER(d.dest_zone), d.pos_x, d.pos_y, d.dest_x, d.dest_y "
        "FROM doors d WHERE d.dest_zone NOT IN ('','NONE') AND d.dest_zone<>d.zone "
        "AND d.dest_zone NOT REGEXP '^-?[0-9]+$';"
    ):
        px, py, dx, dy = float(px), float(py), float(dx), float(dy)
        if (px, py) != (0.0, 0.0):
            door[(a, b)].append((px, py))
        if (dx, dy) != (0.0, 0.0):
            door[(b, a)].append((dx, dy))

    anchors = {}
    for key in set(own) | set(back) | set(door):
        pts = own.get(key) or back.get(key) or door.get(key)
        if pts:
            # Negate into map space (map(x,y) = -db(x,y)), then average.
            anchors[key] = (-sum(p[0] for p in pts) / len(pts),
                            -sum(p[1] for p in pts) / len(pts))
    return anchors


# ---------------------------------------------------------------- map files

_num = re.compile(r"-?\d+(?:\.\d+)?")


def brighten(r, g, b, floor=170):
    """
    Lift dark map colours so they read on a dark background. Brewall uses a lot
    of deep blues and greens that are nearly invisible at 5% of screen size.
    Scales the whole triple so hue is preserved and only brightness changes.
    """
    r, g, b = int(r) & 255, int(g) & 255, int(b) & 255
    peak = max(r, g, b)
    if 0 < peak < floor:
        k = floor / peak
        r, g, b = min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k))
    elif peak == 0:
        r = g = b = floor
    return "#%02x%02x%02x" % (r, g, b)


def load_map(zone, max_segments):
    """
    All z-levels stacked: zone.txt, zone_1.txt, zone_2.txt ...
    Returns (segments, markers, bbox) in map space, or None.
    Segments: (x1,y1,x2,y2,'#rrggbb'). Markers: (x,y,text).
    """
    files = sorted(glob.glob(os.path.join(MAPS, zone + ".txt")) +
                   glob.glob(os.path.join(MAPS, zone + "_[0-9].txt")))
    if not files:
        return None

    segs, marks = [], []
    for path in files:
        for line in open(path, errors="ignore"):
            if line[:1] == "L":
                v = _num.findall(line)
                if len(v) >= 9:
                    x1, y1, _z1, x2, y2, _z2, r, g, b = (float(t) for t in v[:9])
                    segs.append((x1, y1, x2, y2, brighten(r, g, b)))
            elif line[:1] == "P":
                parts = line.split(",")
                if len(parts) >= 8:
                    v = _num.findall(",".join(parts[:3]))
                    if len(v) >= 2:
                        marks.append((float(v[0]), float(v[1]),
                                      parts[-1].strip().replace("_", " ")))
    if not segs:
        return None

    # Decimate by dropping the shortest segments - preserves silhouette.
    if len(segs) > max_segments:
        segs.sort(key=lambda s: (s[0] - s[2]) ** 2 + (s[1] - s[3]) ** 2, reverse=True)
        segs = segs[:max_segments]

    xs = [s[0] for s in segs] + [s[2] for s in segs]
    ys = [s[1] for s in segs] + [s[3] for s in segs]
    return segs, marks, (min(xs), min(ys), max(xs), max(ys))


# ---------------------------------------------------------------- selection

def adjacency(edges, directed):
    """
    Neighbour map. Undirected answers "what cluster is this in"; directed
    answers "where can a player starting here actually get to" - a different
    question, since a quarter of all connections are one-way.
    """
    adj = defaultdict(set)
    for a, b, _t in edges:
        adj[a].add(b)
        if not directed:
            adj[b].add(a)
    return adj


def reachable(seed, adj, depth):
    """BFS from seed. depth=None walks until the frontier is exhausted."""
    seen, frontier, hops = {seed}, {seed}, 0
    while frontier and (depth is None or hops < depth):
        nxt = set()
        for z in frontier:
            nxt |= adj[z]
        frontier = nxt - seen
        seen |= frontier
        hops += 1
    return seen


def select_zones(args, zones, edges):
    adj = adjacency(edges, args.directed)

    if args.zones:
        want = {z.strip().lower() for z in args.zones.split(",") if z.strip()}
    elif args.start:
        seed = args.start.lower()
        if seed not in zones:
            sys.exit(f"unknown zone: {seed}")
        want = reachable(seed, adj, args.depth)
        if len(want) == 1:
            print(f"    {seed} has no connections at all - it is isolated.", file=sys.stderr)
        elif args.depth is None:
            kind = "reachable from" if args.directed else "connected to"
            print(f"    {len(want)} zones {kind} {seed}", file=sys.stderr)
    else:
        want = set(zones)

    have = {z for z in want if z in zones and os.path.exists(os.path.join(MAPS, z + ".txt"))}
    missing = sorted(want - have)

    if args.limit and len(have) > args.limit:
        ranked = sorted(have, key=lambda z: -len(adj[z]))
        dropped = len(have) - args.limit
        have = set(ranked[:args.limit])
        print(f"    WARNING: --limit {args.limit} dropped {dropped} zones - this view is "
              f"PARTIAL and will look more isolated than it is. Use --limit 0 for all of them.",
              file=sys.stderr)
    return have, missing


# ---------------------------------------------------------------- components

def undirected_components(nodes, adj):
    seen, comps = set(), []
    for n in sorted(nodes):
        if n in seen:
            continue
        stack, comp = [n], set()
        while stack:
            z = stack.pop()
            if z in comp:
                continue
            comp.add(z)
            stack.extend(adj[z] - comp)
        seen |= comp
        comps.append(comp)
    return comps


def strong_components(nodes, out):
    """
    Iterative Kosaraju. A strongly-connected component is a set of zones you can
    round-trip between - with 25% of edges one-way, that is a much stricter and
    more useful notion than "same cluster".
    """
    order, seen = [], set()
    for s in sorted(nodes):                       # pass 1: finish order
        if s in seen:
            continue
        stack = [(s, iter(sorted(out.get(s, ()))))]
        seen.add(s)
        while stack:
            node, it = stack[-1]
            nxt = next(it, None)
            if nxt is None:
                order.append(node)
                stack.pop()
            elif nxt not in seen:
                seen.add(nxt)
                stack.append((nxt, iter(sorted(out.get(nxt, ())))))

    rev = defaultdict(set)                        # transpose
    for a, bs in out.items():
        for b in bs:
            rev[b].add(a)

    seen, comps = set(), []                       # pass 2: descending finish time
    for s in reversed(order):
        if s in seen:
            continue
        stack, comp = [s], set()
        while stack:
            z = stack.pop()
            if z in comp:
                continue
            comp.add(z)
            stack.extend(rev[z] - comp - seen)
        seen |= comp
        comps.append(comp)
    return comps


def report_components(zones, edges, directed, full_under=12):
    nodes = set(zones)
    connected = {z for a, b, _t in edges for z in (a, b) if z in nodes}
    orphans = sorted(nodes - connected)

    directed_pairs = {(a, b) for a, b, _t in edges}
    one_way = sum(1 for a, b in directed_pairs if (b, a) not in directed_pairs)

    if directed:
        comps = strong_components(connected, adjacency(edges, True))
        title = "STRONGLY-CONNECTED components (round-trip reachable)"
    else:
        comps = undirected_components(connected, adjacency(edges, False))
        title = "CONNECTED components (ignoring direction)"
    comps.sort(key=len, reverse=True)

    print(f"\n{title}\n{'=' * len(title)}")
    print(f"{len(zones)} zones total  |  {len(connected)} with at least one connection  "
          f"|  {len(comps)} components")
    print(f"{one_way} of {len(directed_pairs)} directed connections are ONE-WAY "
          f"({100 * one_way / max(len(directed_pairs), 1):.0f}%)\n")

    for i, c in enumerate(comps, 1):
        tag = "  <-- mainland" if i == 1 and len(c) > 50 else ""
        print(f"[{i}] {len(c)} zones{tag}")
        members = sorted(c)
        if len(c) <= full_under:
            print(f"      {', '.join(members)}")
        else:
            print(f"      {', '.join(members[:8])} ... (+{len(c) - 8} more)")

    print(f"\nISOLATED zones (no connections at all): {len(orphans)}")
    if orphans:
        print(f"      {', '.join(orphans[:12])}"
              f"{f' ... (+{len(orphans) - 12} more)' if len(orphans) > 12 else ''}")
    print("\nA small component is an island: reachable only from within itself.")


# ---------------------------------------------------------------- layout

def layout(zone_ids, edges, geom, engine, scale):
    """Graphviz for positions only; everything is drawn by hand afterwards."""
    if not shutil.which(engine):
        sys.exit(f"graphviz '{engine}' not found - install graphviz")

    lines = ["graph G {", "  overlap=prism; splines=false;",
         f"  sep=\"+{max(30, scale // 3)}\"; esep=\"+{max(14, scale // 8)}\";"]
    for z in sorted(zone_ids):
        w, h = geom[z]["w"] / 72.0, geom[z]["h"] / 72.0
        lines.append(f'  "{z}" [shape=box fixedsize=true width={w:.3f} height={h:.3f}];')
    seen = set()
    for a, b, _t in edges:
        if a in zone_ids and b in zone_ids:
            k = tuple(sorted((a, b)))
            if k not in seen:
                seen.add(k)
                lines.append(f'  "{k[0]}" -- "{k[1]}";')
    lines.append("}")

    r = subprocess.run([engine, "-Tplain"], input="\n".join(lines),
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("graphviz failed:\n" + r.stderr)

    pos = {}
    for ln in r.stdout.splitlines():
        f = ln.split()
        if f and f[0] == "node":
            pos[f[1].strip('"')] = (float(f[2]) * 72, float(f[3]) * 72)
    return pos


# ---------------------------------------------------------------- rendering

HEADER_H = 26


def node_transform(g):
    """
    Scale/offset placing a zone's map inside its node box, below the header.
    Used both to draw the map and to place connection anchors on it, so the two
    cannot drift apart.
    """
    _segs, _marks, (x0, y0, x1, y1) = g["map"]
    bw, bh = max(x1 - x0, 1e-6), max(y1 - y0, 1e-6)
    avail_w, avail_h = g["w"] - 12, g["h"] - HEADER_H - 8
    s = min(avail_w / bw, avail_h / bh)
    return s, 6 + (avail_w - bw * s) / 2, HEADER_H + 4 + (avail_h - bh * s) / 2


def anchor_xy(zone, other, geom, pos, anchors):
    """
    Page-space point where zone's connection to other attaches, or the node
    centre when there is no coordinate for it. Clamped inside the node box so
    bad data can't fling an endpoint across the canvas.
    """
    g = geom[zone]
    cx, cy = pos[zone]
    a = anchors.get((zone, other))
    if not a:
        return cx, cy, False
    s, ox, oy = node_transform(g)
    _segs, _marks, (x0, y0, _x1, _y1) = g["map"]
    lx = ox + (a[0] - x0) * s
    ly = oy + (a[1] - y0) * s
    lx = min(max(lx, 4), g["w"] - 4)
    ly = min(max(ly, HEADER_H + 2), g["h"] - 4)
    return cx - g["w"] / 2 + lx, cy - g["h"] / 2 + ly, True


def exit_point(px, py, cx, cy, w, h, tx, ty):
    """
    Where the segment from an interior point (px,py) toward (tx,ty) leaves the
    node box centred at (cx,cy). Used to split an edge into the part outside the
    node and the part inside it, so the inside part can be drawn back on top.

    Only intersections that actually lie ON the rectangle and within the segment
    are accepted. Taking the nearest positive slab crossing is not enough: for a
    point already on the boundary the true crossing is at t=0, which rounds away,
    and the next candidate can be far outside the box - which is what made edges
    appear to start in empty space.
    """
    dx, dy = tx - px, ty - py
    if dx == 0 and dy == 0:
        return px, py
    x0, x1 = cx - w / 2, cx + w / 2
    y0, y1 = cy - h / 2, cy + h / 2
    eps = 1e-6
    ts = []
    if dx:
        ts += [(x0 - px) / dx, (x1 - px) / dx]
    if dy:
        ts += [(y0 - py) / dy, (y1 - py) / dy]

    best = None
    for t in ts:
        if t <= eps or t > 1.0:
            continue
        cxx, cyy = px + dx * t, py + dy * t
        if x0 - 1e-3 <= cxx <= x1 + 1e-3 and y0 - 1e-3 <= cyy <= y1 + 1e-3:
            best = t if best is None else min(best, t)
    if best is None:
        return px, py          # already on/outside the boundary
    return px + dx * best, py + dy * best


def clip_to_box(cx, cy, w, h, tx, ty):
    """Point where the ray (cx,cy)->(tx,ty) leaves the box, for arrow placement."""
    dx, dy = tx - cx, ty - cy
    if dx == 0 and dy == 0:
        return cx, cy
    sx = (w / 2) / abs(dx) if dx else math.inf
    sy = (h / 2) / abs(dy) if dy else math.inf
    s = min(sx, sy)
    return cx + dx * s, cy + dy * s


def render(zone_ids, zones, edges, geom, pos, anchors, args):
    xs = [pos[z][0] - geom[z]["w"] / 2 for z in zone_ids]
    ys = [pos[z][1] - geom[z]["h"] / 2 for z in zone_ids]
    xe = [pos[z][0] + geom[z]["w"] / 2 for z in zone_ids]
    ye = [pos[z][1] + geom[z]["h"] / 2 for z in zone_ids]
    pad = 80
    minx, miny, maxx, maxy = min(xs) - pad, min(ys) - pad, max(xe) + pad, max(ye) + pad
    W, H = maxx - minx, maxy - miny

    out = []
    add = out.append
    over = []      # drawn ABOVE the nodes

    # --- edges, drawn under the nodes -------------------------------------
    pairs = defaultdict(set)
    detail = {}
    for (a, b, t), d in edges.items():
        if a in zone_ids and b in zone_ids:
            pairs[tuple(sorted((a, b)))].add((a, b, t))
            detail[(a, b, t)] = d

    add('<g id="edges" fill="none">')
    for (za, zb), members in sorted(pairs.items()):
        types = {t for _a, _b, t in members}
        # Strongest mechanism wins the styling: walking beats clicking.
        t = ("zoneline" if "zoneline" in types else
             "teleport" if "teleport" in types else
             "door" if "door" in types else "script")
        dash, colour, _ = EDGE_STYLE[t]

        if args.center_edges:
            ax, ay = pos[za]
            bx, by = pos[zb]
            a1x, a1y = clip_to_box(ax, ay, geom[za]["w"], geom[za]["h"], bx, by)
            b1x, b1y = clip_to_box(bx, by, geom[zb]["w"], geom[zb]["h"], ax, ay)
            exact_a = exact_b = False
        else:
            # Attach at the real exit locations rather than the node centres.
            a1x, a1y, exact_a = anchor_xy(za, zb, geom, pos, anchors)
            b1x, b1y, exact_b = anchor_xy(zb, za, geom, pos, anchors)
            # No coordinate on either side: fall back to centre-to-centre so the
            # line still reads as a connection instead of vanishing into a corner.
            if not exact_a:
                a1x, a1y = clip_to_box(*pos[za], geom[za]["w"], geom[za]["h"], b1x, b1y)
            if not exact_b:
                b1x, b1y = clip_to_box(*pos[zb], geom[zb]["w"], geom[zb]["h"], a1x, a1y)

        fwd = any(a == za for a, _b, _t in members)
        rev = any(a == zb for a, _b, _t in members)
        approx = "" if (exact_a and exact_b) else "  [approximate: no exit coords]"
        tip = html.escape(f"{za} <-> {zb}: " + ", ".join(sorted(
            f"{t2} ({detail.get((a, b, t2), '')})" for a, b, t2 in members)) + approx)
        dashattr = f' stroke-dasharray="{dash}"' if dash else ""
        op = ".8" if (exact_a and exact_b) else ".35"

        # Where the line crosses each node's edge. Everything between those two
        # points is outside both nodes and can be drawn underneath; the two
        # stubs from boundary to anchor sit inside a node and must be redrawn on
        # top, or the node paints over them and the arrowheads vanish.
        ea = exit_point(a1x, a1y, *pos[za], geom[za]["w"], geom[za]["h"], b1x, b1y)
        eb = exit_point(b1x, b1y, *pos[zb], geom[zb]["w"], geom[zb]["h"], a1x, a1y)

        # under-layer: the span between the two nodes, with a dark halo so it
        # stays legible where it crosses an unrelated node
        seg = (f'M{ea[0] - minx:.1f},{ea[1] - miny:.1f}'
               f'L{eb[0] - minx:.1f},{eb[1] - miny:.1f}')
        add(f'<path d="{seg}" stroke="#1b1f27" stroke-width="4.5" stroke-opacity=".55"/>')
        add(f'<path d="{seg}" stroke="{colour}" stroke-width="1.8" '
            f'stroke-opacity="{op}"{dashattr}><title>{tip}</title></path>')

        # over-layer: the occluded stubs, arrowheads pointing at the true exit
        for (bx_, by_), (ax_, ay_), ok, arrow in (
                (ea, (a1x, a1y), exact_a, rev),      # arrow into za = reverse travel
                (eb, (b1x, b1y), exact_b, fwd)):     # arrow into zb = forward travel
            if not ok:
                continue
            d = (f'M{bx_ - minx:.1f},{by_ - miny:.1f}L{ax_ - minx:.1f},{ay_ - miny:.1f}')
            mk = f' marker-end="url(#arw-{t})"' if arrow else ""
            over.append(f'<path d="{d}" stroke="#1b1f27" stroke-width="4.5" '
                        f'stroke-opacity=".7" fill="none"/>')
            over.append(f'<path d="{d}" stroke="{colour}" stroke-width="1.8" '
                        f'stroke-opacity=".95" fill="none"{dashattr}{mk}>'
                        f'<title>{tip}</title></path>')
            over.append(f'<circle cx="{ax_ - minx:.1f}" cy="{ay_ - miny:.1f}" r="3" '
                        f'fill="{colour}" stroke="#1b1f27" stroke-width="1"/>')
    add("</g>")

    # --- nodes ------------------------------------------------------------
    add('<g id="nodes">')
    for z in sorted(zone_ids):
        g = geom[z]
        w, h = g["w"], g["h"]
        x = pos[z][0] - w / 2 - minx
        y = pos[z][1] - h / 2 - miny
        zid, long_name = zones[z]

        add(f'<g class="zone" transform="translate({x:.1f},{y:.1f})">')
        add(f'<rect width="{w:.1f}" height="{h:.1f}" rx="7" class="zbox"/>')
        add(f'<rect width="{w:.1f}" height="{HEADER_H}" rx="7" class="zhdr"/>')
        add(f'<rect y="{HEADER_H - 7}" width="{w:.1f}" height="7" class="zhdr"/>')
        add(f'<text x="8" y="18" class="zttl">{html.escape(z)} '
            f'<tspan class="zid">({html.escape(str(zid))})</tspan></text>'
            f'<title>{html.escape(long_name)}</title>')

        # map geometry, scaled into the body area below the header
        segs, marks, (x0, y0, _x1, _y1) = g["map"]
        s, ox, oy = node_transform(g)

        add(f'<g transform="translate({ox:.2f},{oy:.2f}) scale({s:.5f}) '
            f'translate({-x0:.2f},{-y0:.2f})" class="mapg">')
        by_colour = defaultdict(list)
        for sx1, sy1, sx2, sy2, col in segs:
            by_colour[col].append(f"M{sx1:.0f},{sy1:.0f}L{sx2:.0f},{sy2:.0f}")
        for col, d in by_colour.items():
            add(f'<path d="{"".join(d)}" stroke="{col}" '
                f'stroke-width="{1.25 / s:.2f}" fill="none" stroke-opacity=".92"/>')
        if args.labels:
            for mx, my, txt in marks:
                if txt.lower().startswith("to "):
                    add(f'<circle cx="{mx:.0f}" cy="{my:.0f}" r="{3.2 / s:.1f}" '
                        f'fill="#ff5c7a"><title>{html.escape(txt)}</title></circle>')
        add("</g></g>")
    add("</g>")

    # arrowheads and exit stubs last, so nodes cannot occlude them
    add('<g id="edge-tips" fill="none">' + "".join(over) + "</g>")

    legend = "".join(
        f'<div><span class="sw" style="border-top-color:{c};'
        f'border-top-style:{"dashed" if d else "solid"}"></span>{lbl}</div>'
        for _k, (d, c, lbl) in
        {k: v for k, v in EDGE_STYLE.items() if k != "door"}.items()
    )
    defs = "".join(
        f'<marker id="arw-{t}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" '
        f'markerHeight="6" orient="auto-start-reverse">'
        f'<path d="M0,0L10,5L0,10z" fill="{c}"/></marker>'
        # orient="auto" (not auto-start-reverse): the geometry already points
        # backwards, so letting SVG flip it too would cancel out.
        f'<marker id="arwr-{t}" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="6" '
        f'markerHeight="6" orient="auto">'
        f'<path d="M10,0L0,5L10,10z" fill="{c}"/></marker>'
        for t, (_d, c, _l) in EDGE_STYLE.items()
    )

    return f"""<!doctype html><html><head><meta charset="utf-8">
<title>WorldDungeon zone graph</title><style>
:root{{color-scheme:dark}}
body{{margin:0;background:#272c35;color:#e6ecf5;
     font:13px/1.4 ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif}}
#bar{{position:fixed;top:0;left:0;right:0;padding:8px 12px;background:#1b1f27ee;
     border-bottom:1px solid #3d4757;display:flex;gap:20px;align-items:center;z-index:9}}
#bar b{{color:#fff}} #legend{{display:flex;gap:16px}}
#legend div{{display:flex;align-items:center;gap:6px;color:#b6c5da}}
.sw{{display:inline-block;width:26px;border-top:2.5px solid}}
#hint{{margin-left:auto;color:#8b9ab0}}
svg{{display:block;width:100vw;height:100vh}}
#root{{will-change:transform}}
svg.panning path{{shape-rendering:optimizeSpeed}}
.zbox{{fill:#12161e;stroke:#5b6d88;stroke-width:1.2}}
.zhdr{{fill:#3a4a64}}
.zttl{{fill:#f2f7ff;font:600 12px ui-monospace,monospace}}
.zid{{fill:#a8bcd6;font-weight:400}}
.zone:hover .zbox{{stroke:#7ecbff;stroke-width:2.5}}
#edge-tips{{pointer-events:none}}
</style></head><body>
<div id="bar"><b>Zone graph</b>
<span>{len(zone_ids)} zones &middot; {len(pairs)} connections</span>
<div id="legend">{legend}</div>
<span id="hint">drag to pan &middot; scroll to zoom &middot; hover for detail</span></div>
<svg id="v" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     viewBox="0 0 {W:.0f} {H:.0f}"><defs>{defs}</defs>
<g id="root">{''.join(out)}</g></svg>
<script>
const svg=document.getElementById('v'),root=document.getElementById('root');
let k=1,tx=0,ty=0,drag=false,px=0,py=0;
const apply=()=>root.setAttribute('transform',`translate(${{tx}},${{ty}}) scale(${{k}})`);
svg.addEventListener('wheel',e=>{{e.preventDefault();
  const r=svg.getBoundingClientRect(),vb=svg.viewBox.baseVal,sc=vb.width/r.width;
  const mx=(e.clientX-r.left)*sc,my=(e.clientY-r.top)*sc;
  const f=e.deltaY<0?1.12:1/1.12,nk=Math.min(30,Math.max(.03,k*f));
  tx=mx-(mx-tx)*(nk/k); ty=my-(my-ty)*(nk/k); k=nk; apply();}},{{passive:false}});
let queued=false;
const schedule=()=>{{if(queued)return;queued=true;
  requestAnimationFrame(()=>{{queued=false;apply();}});}};
svg.addEventListener('mousedown',e=>{{drag=true;px=e.clientX;py=e.clientY;
  svg.classList.add('panning');e.preventDefault();}});
addEventListener('mouseup',()=>{{drag=false;svg.classList.remove('panning');apply();}});
addEventListener('mousemove',e=>{{if(!drag)return;
  const r=svg.getBoundingClientRect(),vb=svg.viewBox.baseVal,sc=vb.width/r.width;
  tx+=(e.clientX-px)*sc; ty+=(e.clientY-py)*sc; px=e.clientX; py=e.clientY; schedule();}});
</script></body></html>"""


# ---------------------------------------------------------------- main

def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    g = p.add_mutually_exclusive_group()
    g.add_argument("--zones", help="comma-separated short names")
    g.add_argument("--from", dest="start", help="seed zone for a neighbourhood walk")
    g.add_argument("--all", action="store_true", help="every zone with a map file")
    p.add_argument("--depth", type=int, default=None, metavar="N",
                   help="stop N connections out from --from (default: no limit, "
                        "walk everything reachable)")
    p.add_argument("--directed", action="store_true",
                   help="follow only outbound connections - where you can actually GET TO "
                        "from the seed, rather than what cluster it belongs to")
    p.add_argument("--components", action="store_true",
                   help="text report: partition every zone into connected components to find "
                        "islands, then exit without rendering")
    p.add_argument("--limit", type=int, default=120,
                   help="cap zones, keeping the best-connected (default 120; 0 = no cap)")
    p.add_argument("--node-size", type=int, default=210, help="node width in px")
    p.add_argument("--max-segments", type=int, default=1400,
                   help="map line segments per zone before decimation")
    p.add_argument("--engine", default="neato", choices=["neato", "sfdp", "fdp", "dot", "circo"])
    p.add_argument("--labels", action="store_true", help="mark zone exits on each map")
    p.add_argument("--center-edges", action="store_true",
                   help="draw connections node-centre to node-centre instead of from "
                        "their real exit coordinates")
    p.add_argument("-o", "--out", default="zone-graph.html")
    args = p.parse_args()

    if not args.components and not os.path.isdir(MAPS):
        sys.exit(f"map directory not found: {MAPS} (set BREWALL_DIR)")

    print("==> reading database", file=sys.stderr)
    zones, edges = load_zones(), load_edges()

    if args.components:
        report_components(zones, edges, args.directed)
        return

    sel, missing = select_zones(args, zones, edges)
    if not sel:
        sys.exit("no zones selected (none had map files?)")
    if missing:
        print(f"    {len(missing)} selected zones have no map file, skipped: "
              f"{', '.join(missing[:10])}{' ...' if len(missing) > 10 else ''}", file=sys.stderr)

    print(f"==> loading {len(sel)} maps", file=sys.stderr)
    geom, dropped = {}, []
    for z in sorted(sel):
        m = load_map(z, args.max_segments)
        if not m:
            dropped.append(z)
            continue
        x0, y0, x1, y1 = m[2]
        aspect = (y1 - y0) / max(x1 - x0, 1e-6)
        w = args.node_size
        h = max(70.0, min(w * 2.2, w * aspect)) + HEADER_H
        geom[z] = {"map": m, "w": float(w), "h": float(h)}
    sel = set(geom)
    for z in dropped:
        print(f"    no drawable geometry: {z}", file=sys.stderr)

    print(f"==> layout ({args.engine})", file=sys.stderr)
    pos = layout(sel, edges, geom, args.engine, args.node_size)
    sel = {z for z in sel if z in pos}

    anchors = {} if args.center_edges else load_anchors()
    if anchors:
        wanted = [(a, b) for a, b, _t in edges if a in sel and b in sel]
        hit = sum(1 for k in wanted if k in anchors)
        print(f"    {hit}/{len(wanted)} connections anchored at real exit "
              f"coordinates; the rest use node centres", file=sys.stderr)
    print("==> rendering", file=sys.stderr)
    open(args.out, "w").write(render(sel, zones, edges, geom, pos, anchors, args))
    n_edges = len({tuple(sorted((a, b))) for a, b, _t in edges if a in sel and b in sel})
    print(f"Wrote {args.out}  ({len(sel)} zones, {n_edges} connections)", file=sys.stderr)


if __name__ == "__main__":
    main()
