#!/bin/bash
# Dump the full zone connectivity graph from the EQEmu database.
#
# Zones connect by more than zonelines. This extracts every mechanism as a typed
# edge list so the graph can be audited as a whole.
#
#   zoneline   zone_points -> target_zone_id           (walk through)
#   teleport   doors, opentype 57-58, with dest_zone    (clicky portals: PoK books,
#                                                        Blackburrow ruby, etc.)
#              source: zone/doors.cpp:542 "// teleport door"
#   door       doors, other opentypes, with dest_zone   (zone on open/pass)
#   script     quest MovePC / eq.move_pc with a zone id (scripted ports)
#
# Same-zone destinations are excluded throughout - those are intra-zone warps,
# not graph edges (see Doors::IsDestinationZoneSame).
#
# Usage:  dump-zone-graph.sh [outdir]     (default: ./zone-graph)
#
# Writes edges.csv (from_zone,to_zone,type,detail) plus per-type files.
# Requires: docker access to the akk-stack mariadb container, and the quests
# directory for script edges.

set -euo pipefail

STACK="${STACK_DIR:-/opt/eqemu-servers/akk-stack}"
QUESTS="${QUESTS_DIR:-$STACK/server/quests}"
OUT="${1:-./zone-graph}"

mkdir -p "$OUT"
cd "$STACK"
set -a; . ./.env; set +a
export MARIADB_USER MARIADB_PASSWORD MARIADB_DATABASE

run_sql() {
  SQL="$1" ; export SQL
  local runner="docker compose exec -T -e MYSQL_PWD=\"\$MARIADB_PASSWORD\" \
    mariadb mysql -u\"\$MARIADB_USER\" \"\$MARIADB_DATABASE\" --batch --skip-column-names -e \"\$SQL\""
  if docker info >/dev/null 2>&1; then
    bash -c "$runner"
  else
    sg docker -c "$runner"   # docker group not active in this shell (see README section 6)
  fi
}

echo "==> zonelines"
run_sql "
  SELECT DISTINCT LOWER(zp.zone), LOWER(z2.short_name), 'zoneline', CONCAT('point ', zp.number)
  FROM zone_points zp
  JOIN zone z2 ON z2.zoneidnumber = zp.target_zone_id
  WHERE zp.zone <> z2.short_name AND zp.zone <> '' AND z2.short_name <> '';
" > "$OUT/edges-zoneline.tsv"

echo "==> teleport doors (clicky portals)"
run_sql "
  SELECT DISTINCT LOWER(d.zone), LOWER(d.dest_zone), 'teleport', d.name
  FROM doors d
  WHERE d.opentype IN (57,58)
    AND d.dest_zone NOT IN ('','NONE') AND d.dest_zone <> d.zone
    AND d.dest_zone NOT REGEXP '^-?[0-9]+$';
" > "$OUT/edges-teleport.tsv"

echo "==> other doors with a destination zone"
run_sql "
  SELECT DISTINCT LOWER(d.zone), LOWER(d.dest_zone), 'door', CONCAT(d.name,' [opentype ',d.opentype,']')
  FROM doors d
  WHERE d.opentype NOT IN (57,58)
    AND d.dest_zone NOT IN ('','NONE') AND d.dest_zone <> d.zone
    AND d.dest_zone NOT REGEXP '^-?[0-9]+$';
" > "$OUT/edges-door.tsv"

# Doors whose dest_zone holds a numeric zone id instead of a short name.
# ZoneID() (common/zone_store.cpp:77) compares short names only and returns 0 on
# failure, so these never fire - they are broken data, not edges. Reported
# separately so the graph stays honest and the bug stays visible.
echo "==> broken doors (numeric dest_zone)"
run_sql "
  SELECT DISTINCT LOWER(d.zone), LOWER(COALESCE(z.short_name, CONCAT('zoneid:', d.dest_zone))),
         'BROKEN-dest-is-numeric', CONCAT(d.name,' [dest_zone=',d.dest_zone,']')
  FROM doors d
  LEFT JOIN zone z ON z.zoneidnumber = CAST(d.dest_zone AS UNSIGNED)
  WHERE d.dest_zone REGEXP '^-?[0-9]+$' AND d.dest_zone NOT IN ('0','-1');
" > "$OUT/edges-broken.tsv"

echo "==> zone id -> short_name map"
run_sql "SELECT zoneidnumber, short_name FROM zone WHERE short_name <> '' GROUP BY zoneidnumber;" \
  > "$OUT/zone-ids.tsv"

echo "==> script ports (quest MovePC)"
: > "$OUT/edges-script.tsv"
if [ -d "$QUESTS" ]; then
  awk -F'\t' 'NF>=2 {id[$1]=$2} END{for(k in id) print k"\t"id[k]}' "$OUT/zone-ids.tsv" \
    > "$OUT/.idmap"
  # Perl quest::MovePC(zoneid,...) and Lua eq.move_pc(zoneid,...)
  grep -rhoEn --include=*.pl --include=*.lua \
      '(MovePC|move_pc)[[:space:]]*\([[:space:]]*[0-9]+' "$QUESTS" 2>/dev/null \
    | grep -oE '[0-9]+$' | sort -n | uniq -c \
    | while read -r count zid; do
        dest=$(awk -F'\t' -v z="$zid" '$1==z{print $2; exit}' "$OUT/.idmap")
        [ -n "$dest" ] && printf 'SCRIPT\t%s\tscript\t%s call sites\n' "$dest" "$count"
      done > "$OUT/edges-script.tsv"
  rm -f "$OUT/.idmap"
else
  echo "    (skipped: $QUESTS not found)"
fi

echo "==> combining"
{
  echo -e "from_zone\tto_zone\ttype\tdetail"
  cat "$OUT"/edges-zoneline.tsv "$OUT"/edges-teleport.tsv \
      "$OUT"/edges-door.tsv "$OUT"/edges-script.tsv 2>/dev/null
} > "$OUT/edges.tsv"

echo
echo "Edge counts by type:"
awk -F'\t' 'NR>1{c[$3]++} END{for(t in c) printf "  %-10s %6d\n", t, c[t]}' "$OUT/edges.tsv"
echo
echo "Distinct zone pairs (undirected, zoneline+teleport+door):"
awk -F'\t' 'NR>1 && $3!="script"{a=$1;b=$2; if(a>b){t=a;a=b;b=t} print a"|"b}' "$OUT/edges.tsv" \
  | sort -u | wc -l
echo
echo "Wrote $OUT/edges.tsv"
