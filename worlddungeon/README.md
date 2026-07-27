# WorldDungeon — custom data

Everything WorldDungeon owns in the database lives here as version-controlled SQL.

**Why this exists (backlog F2):** without it, custom content exists only as mutations in one
MariaDB volume. `make init-peq-database` overwrites the database, the prod box needs the same
content from scratch, and there is no diff, no review and no rollback. This was the single
highest-risk omission in the plan.

This directory is deliberately **top-level and outside every upstream path**, so a future
`upstream/master` merge can never conflict with it.

```
worlddungeon/
  bin/wd-migrate      the runner
  migrations/         ordered, immutable .sql files
```

Design authority lives in the Obsidian vault; the *work* lives in
[`docs/worlddungeon/BACKLOG.md`](../docs/worlddungeon/BACKLOG.md); **ID allocation** is governed
by [`docs/worlddungeon/F1-ID-RANGES.md`](../docs/worlddungeon/F1-ID-RANGES.md).

---

## Usage

```bash
./worlddungeon/bin/wd-migrate status
```

```bash
./worlddungeon/bin/wd-migrate up
```

| Command | Does |
|---|---|
| `status` | applied / pending / drifted, per migration. Exits non-zero on any problem. |
| `up [--dry-run]` | applies every pending migration in numeric order |
| `verify` | re-checksums applied migrations against the files on disk |
| `new <name>` | scaffolds the next numbered file with the header checklist |

The runner handles the `sg docker` fallback automatically — the docker group isn't active in a
non-interactive shell until a fresh login (akk-stack README §6).

---

## Rules

**1. An applied migration is immutable.** Its sha256 is recorded in `wd_migration`. Editing a
file that has already run makes `status` report `DRIFTED` and makes `up` refuse to do anything
until it's resolved. To change something already applied, **write a new migration.**

**2. Every migration must be idempotent.** MySQL DDL is not transactional, so a migration that
mixes DDL and DML can partially apply and leave you re-running it. Write files that survive
that:

- `CREATE TABLE IF NOT EXISTS`, `DROP ... IF EXISTS`
- `REPLACE INTO` or `INSERT ... ON DUPLICATE KEY UPDATE`, never a bare `INSERT`
- for content, `DELETE FROM t WHERE id BETWEEN <our range>` then insert — safe because F1
  guarantees the range is ours alone

A migration that fails is **not** recorded as applied, so it will be retried on the next `up`.

**3. Keep migrations small.** One concern each. A 2,000-row spell import and a schema change do
not belong in the same file.

**4. Never write a custom row below its F1 custom base**, and claim the id block in
`F1-ID-RANGES.md` in the same commit that first uses it.

**5. Nothing is hand-mutated in the live database.** If you find yourself in the PEQ editor or a
mysql prompt changing custom data, that change is invisible to everyone else and will be lost at
the next reinit. Write a migration.

---

## Rebuilding from empty

The point of all this is that the custom layer is reproducible:

```bash
make init-peq-database && ./worlddungeon/bin/wd-migrate up
```

Stock PEQ, then every custom migration in order. See backlog **F3** for the backup/restore
discipline that proves this path actually works.

---

## Tracking table

`wd_migration` — `version`, `name`, `checksum`, `applied_at`, `duration_ms`. It is created
automatically on first run and is itself part of the custom layer, so a `make init-peq-database`
wipes it along with everything else, and `up` correctly replays from scratch.
