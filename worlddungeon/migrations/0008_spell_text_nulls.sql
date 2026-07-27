-- 0008_spell_text_nulls
--
-- 🔴 UNBREAKS THE ENTIRE SPELL PIPELINE. Nothing authored since 0003 has ever
-- reached a zone, and this is why.
--
-- ---------------------------------------------------------------------------
-- WHAT WAS BROKEN
--
-- `shared_memory` aborts with
--
--     Shared | Error | main basic_string: construction from null is not valid
--
-- while loading spells, and writes no usable spells file. Spells live in
-- SHARED MEMORY, so with the loader dead every custom row is invisible to every
-- zone no matter how many times you restart. Migration 0004 has been applied
-- since 12:35 and had never once been seen by a running zone.
--
-- Cause: `SharedDatabase::LoadSpells()` (common/shareddb.cpp:1686-1691) does
--
--     strn0cpy(sp[tempid].teleport_zone, row[3], ...)   -- and row[4]..row[8]
--
-- straight into std::string with no NULL guard. Six varchar columns in
-- spells_new are NULLABLE with a NULL default:
--
--     teleport_zone  you_cast  other_casts  cast_on_you  cast_on_other
--     spell_fades
--
-- 0003 and 0004 named neither, so all twelve custom rows took the NULL default.
-- **Not one stock row is NULL in any of them** (0 of 40,722) — the loader has
-- simply never been handed a NULL, so the missing guard never surfaced.
--
-- The query is `SELECT * FROM spells_new ORDER BY id ASC`, so it dies on the
-- FIRST custom row (42700) and everything from there up is lost. Custom ids sit
-- above stock's 42,602 max, which is exactly why this presents as "all stock
-- spells work, no custom spell exists."
--
-- ---------------------------------------------------------------------------
-- THE STANDING RULE THIS ESTABLISHES
--
-- **Every spells_new INSERT must name all six text columns explicitly**, even
-- when the value is ''. The column default is NULL and NULL is fatal. The
-- pending 0005/0006/0007 have been amended to do so; the sweep below is the
-- belt-and-braces net for anything that slips through, and it is written to be
-- safely re-runnable over the whole custom band.
--
-- typedescnum / effectdescnum are set to 0 as well. They are not read by
-- LoadSpells, but every stock row carries a real integer and leaving custom
-- rows NULL invites the same class of bug in any consumer that does read them.
--
-- Idempotent: a bounded UPDATE with COALESCE. Re-running is a no-op.
-- ---------------------------------------------------------------------------

UPDATE spells_new
SET teleport_zone = COALESCE(teleport_zone, ''),
    you_cast      = COALESCE(you_cast,      ''),
    other_casts   = COALESCE(other_casts,   ''),
    cast_on_you   = COALESCE(cast_on_you,   ''),
    cast_on_other = COALESCE(cast_on_other, ''),
    spell_fades   = COALESCE(spell_fades,   ''),
    typedescnum   = COALESCE(typedescnum,   0),
    effectdescnum = COALESCE(effectdescnum, 0)
WHERE id BETWEEN 42700 AND 44999;

-- ==============================================================================
-- VERIFY — before anything else in the next session.
--
--   1. Regenerate shared memory. NOTE: ~/server/bin has no `shared_memory`
--      symlink (only zone and world are linked), so run the build output:
--
--        cd ~/server && ../code/build/bin/shared_memory
--
--      It must end on `main Loading spells` WITHOUT the basic_string error, and
--      go on to complete. That line is the whole test.
--
--   2. `strings ~/server/shared/spells | grep "Mantle Mk"` -> 9 hits.
--      Zero hits means the loader is still dying.
--
--   3. Restart, then run 0004's test matrix — which has never actually run.
--      ⚠️ Read docs/worlddungeon/P1-STACKING-DEFECT.md first: static analysis
--      says steps 2-5 of that matrix CANNOT pass as 0004 is authored. Run it
--      anyway to confirm the trace against the live engine, but expect failure
--      and do not treat it as a surprise.
-- ==============================================================================
