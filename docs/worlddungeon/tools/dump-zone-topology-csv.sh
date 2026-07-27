#!/bin/bash
# Dump a per-zone topology CSV for planning the World Dungeon world map.
#
# One row per zone, 482 of them, including the 94 with no connections at all -
# an unconnected stock zone is a candidate to repurpose, so it belongs in the
# planning sheet rather than being filtered out.
#
# WHAT COUNTS AS A CONNECTION
#
# "Standard" travel only, per the request this was built for: things a player
# walks through or clicks. Specifically:
#
#   zoneline   zone_points -> target_zone_id            walk through
#   teleport   doors, opentype 57-58, with dest_zone    clicky portal / orb / book
#              (zone/doors.cpp:542 "// teleport door")
#   door       doors, other opentypes, with dest_zone   zones on open or pass
#
# DELIBERATELY EXCLUDED:
#   * quest-script ports (MovePC / eq.move_pc) - not a fixed piece of world
#     geometry; a script can send you anywhere from anywhere.
#   * translocate / gate / port SPELLS - same reason, and they are not in the
#     zone graph at all.
#   * same-zone destinations - intra-zone warps, not edges
#     (Doors::IsDestinationZoneSame).
#   * doors whose dest_zone holds a NUMERIC zone id - ZoneID()
#     (common/zone_store.cpp:77) compares short names only and returns 0, so
#     these never fire. 46 such rows exist; they are broken data, not edges.
#     See ZONE-CONNECTIVITY.md.
#
# DIRECTION MATTERS. 25% of stock connections are one-way, so `connections` is
# the count of distinct NEIGHBOURS in either direction, and the breakdown
# columns tell you which. A zone with connections=3 but in_only=3 is a
# roach motel.
#
# COLUMNS
#   zone_name          zone.long_name
#   short_name         zone.short_name - the real constraint on a custom zone,
#                      since the client loads geometry by name (F1-ID-RANGES.md)
#   zone_id            zone.zoneidnumber
#   connections        distinct neighbouring zones, either direction
#   two_way            neighbours reachable both ways - a true round trip
#   out_only           you can leave to these, but not come back the same way
#   in_only            you can arrive from these, but not go back
#   connected_zones    every neighbour, semicolon-separated, sorted, each
#                      suffixed (both) / (out) / (in)
#
# The zone table has 618 ROWS but only 482 distinct zones - the rest are
# per-version rows. This groups by short_name; count rows and every ratio comes
# out wrong.
#
# Usage:  dump-zone-topology-csv.sh [outfile]     (default: ./zone-topology.csv)

set -euo pipefail

STACK="${STACK_DIR:-/opt/eqemu-servers/akk-stack}"
OUT="${1:-./zone-topology.csv}"

cd "$STACK"
set -a; . ./.env; set +a
export MARIADB_USER MARIADB_PASSWORD MARIADB_DATABASE

run_sql() {
  SQL="$1"; export SQL
  local runner="docker compose exec -T -e MYSQL_PWD=\"\$MARIADB_PASSWORD\" \
    mariadb mysql -u\"\$MARIADB_USER\" \"\$MARIADB_DATABASE\" --batch --skip-column-names -e \"\$SQL\""
  if docker info >/dev/null 2>&1; then
    bash -c "$runner"
  else
    sg docker -c "$runner"   # docker group not active until a fresh login (akk-stack README section 6)
  fi
}

# GROUP_CONCAT truncates at 1024 bytes by default. potranquility has 36
# neighbours; silent truncation would look like real data.
run_sql "
SET SESSION group_concat_max_len = 65535;

WITH
-- One canonical row per zone. 618 rows, 482 zones.
zones AS (
  SELECT short_name, MIN(zoneidnumber) AS zone_id, MIN(long_name) AS long_name
  FROM zone WHERE short_name IS NOT NULL AND short_name <> ''
  GROUP BY short_name
),
-- Directed edges, standard mechanisms only. See header.
edges AS (
  SELECT DISTINCT LOWER(zp.zone) AS a, LOWER(z2.short_name) AS b
  FROM zone_points zp
  JOIN zone z2 ON z2.zoneidnumber = zp.target_zone_id
  WHERE zp.zone <> '' AND z2.short_name <> '' AND LOWER(zp.zone) <> LOWER(z2.short_name)
  UNION
  SELECT DISTINCT LOWER(d.zone), LOWER(d.dest_zone)
  FROM doors d
  WHERE d.dest_zone NOT IN ('','NONE')
    AND LOWER(d.dest_zone) <> LOWER(d.zone)
    AND d.dest_zone NOT REGEXP '^-?[0-9]+\$'
),
-- Keep only edges whose endpoints are both real zones.
clean AS (
  SELECT e.a, e.b FROM edges e
  JOIN zones za ON za.short_name = e.a
  JOIN zones zb ON zb.short_name = e.b
),
-- State each directed fact twice - once from each endpoint's point of view -
-- then fold. A pair seen from both sides ends up with has_out = has_in = 1.
pairs AS (
  SELECT a AS zone, b AS nb, 1 AS has_out, 0 AS has_in FROM clean
  UNION ALL
  SELECT b AS zone, a AS nb, 0 AS has_out, 1 AS has_in FROM clean
),
folded AS (
  SELECT zone, nb, MAX(has_out) AS has_out, MAX(has_in) AS has_in
  FROM pairs GROUP BY zone, nb
)
SELECT
  z.long_name,
  z.short_name,
  z.zone_id,
  COALESCE(COUNT(f.nb), 0),
  COALESCE(SUM(f.has_out = 1 AND f.has_in = 1), 0),
  COALESCE(SUM(f.has_out = 1 AND f.has_in = 0), 0),
  COALESCE(SUM(f.has_out = 0 AND f.has_in = 1), 0),
  COALESCE(GROUP_CONCAT(
    CONCAT(f.nb, CASE WHEN f.has_out = 1 AND f.has_in = 1 THEN ' (both)'
                      WHEN f.has_out = 1 THEN ' (out)'
                      ELSE ' (in)' END)
    ORDER BY f.nb SEPARATOR '; '), '')
FROM zones z
LEFT JOIN folded f ON f.zone = z.short_name
GROUP BY z.short_name, z.zone_id, z.long_name
ORDER BY COUNT(f.nb) DESC, z.short_name;
" | awk -F'\t' '
BEGIN {
  OFS = ","
  print "zone_name,short_name,zone_id,connections,two_way,out_only,in_only,connected_zones"
}
{
  # Quote every field and escape embedded quotes - long_name is free text.
  for (i = 1; i <= NF; i++) { gsub(/"/, "\"\"", $i); $i = "\"" $i "\"" }
  print
}' > "$OUT"

rows=$(( $(wc -l < "$OUT") - 1 ))
echo "Wrote $OUT  ($rows zones)"
echo
# No `| head` here: awk would take SIGPIPE, and under `set -o pipefail` that
# fails the whole script before the summary below ever runs.
echo "Most-connected zones:"
awk -F'","' 'NR>1 && NR<=9 {print "  " $2 "  " $4 " connections"}' "$OUT"
echo
awk -F'","' '
  NR>1 { total++; if ($4+0 == 0) isolated++; sum += $4; if ($6+0 > 0) oneway++ }
  END {
    printf "  %d zones, %d isolated, %.1f connections on average\n", total, isolated, sum/total
    printf "  %d zones have at least one outbound-only edge (no way back)\n", oneway
  }' "$OUT"
