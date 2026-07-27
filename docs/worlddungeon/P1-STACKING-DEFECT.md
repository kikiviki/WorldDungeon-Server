# P1 — The mantle stacking design cannot work as authored

**Status:** 🔴 confirmed by source trace against `zone/spells.cpp` on this checkout.
Found while preparing the `0004` test matrix, before running it.

**Headline:** the two decisions locked in the last session are mutually exclusive. Migration
`0004`'s mantles will fail matrix steps 2, 3, 4 and 5. This is not a tuning problem and no
amount of in-game testing will make it pass.

---

## 1. The contradiction

Both of these are recorded as locked decisions in [BACKLOG.md](BACKLOG.md):

> **Stance exclusivity = matching effect layout** (all 12 `effectid` slots identical)

> **SPA 149 as the mandatory rider** wherever parallel tiered lines must swap in both directions

`Mob::CheckStackConflict()` (`zone/spells.cpp:3069`) makes them incompatible.

At `zone/spells.cpp:3145-3156` it computes `effect_match` — true when **all twelve `effect_id`
slots are identical** between the worn spell and the incoming one. The entire SPA 148/149 block
is then wrapped in:

```cpp
if (!effect_match) {          // zone/spells.cpp:3164
    ...
    if (effect2 == SpellEffect::StackingCommand_Overwrite) { ... }   // :3208
} else {
    LogSpells("... appear to be in the same line, skipping Stacking Overwrite/Blocking checks");
}                             // zone/spells.cpp:3269-3272
```

**Identical layouts are exactly the condition that disables SPA 149.** The mechanism chosen to
make stances exclusive is the mechanism that switches off the rider meant to let them swap. The
nine mantles all carry the same layout — `125 / 132 / 220 / 177 / 323 / 149 / 254×6` — so
`effect_match` is always true among them and slot 6 is never read.

---

## 2. What actually happens instead

With SPA 149 skipped, control falls to the plain value-arbitration loop (`:3283-3395`). Two
filters decide which slots get a vote:

- `IsBlankSpellEffect()` (`common/spdat.cpp:920`) skips slot 6 — **SPA 149 is itself classified
  as blank** — and slots 7–12.
- `IsEffectIgnoredInStacking()` (`common/spdat.cpp:2035`) skips **125 `ImprovedHeal`**,
  **132 `ReduceManaCost`** and **220 `SkillDamageAmount`**.

So of six populated slots, only **two** arbitrate: slot 4 (`177 DoubleAttackChance`) and slot 5
(`323 DefensiveProc`). Values as authored (`formula 100` = base, `zone/spell_effects.cpp:3534`):

| Spell | slot 4 · 177 | slot 5 · 323 |
|---|---:|---:|
| Zealot Mk. I / II / III | 5 / 12 / 20 | 42710 |
| Standard Mk. I / II / III | 0 / 0 / 0 | 42711 |
| Warden Mk. I / II / III | 0 / 0 / 0 | 42712 |

### Matrix step by step

| Step | Trace | Result |
|---|---|---|
| 1. Standard Mk. I lands | nothing worn | ✅ **passes** |
| 2. Standard Mk. III over Mk. I | slots 1–3 ignored, 6 blank; slots 4 (0 v 0) and 5 (42711 v 42711) are **equal** → `will_overwrite` never set → `return 0` | 🔴 **both buffs coexist** |
| 3. Zealot Mk. I over Standard Mk. III | slot 5: `sp2_value 42710 < sp1_value 42711` → `return -1` (`:3383`) | 🔴 **rejected** — the gate fails |
| 4. Warden Mk. II over Zealot Mk. I | slot 4: `0 < 5` → `return -1` | 🔴 **rejected** |
| 5. Exactly one mantle present | step 2 already produces two | 🔴 **fails** |

Step 3 fails for a reason the migration header never anticipated. The header predicts *"if it
fails, SPA 149 does not behave as `zone/spells.cpp:3208` reads."* **Line 3208 reads correctly —
it is simply never reached.**

### The proc slot is the sharpest edge

Slot 5 holds SPA 323, whose base value is a **spell id**. The arbitration loop compares base
values as if they were magnitudes, so `CheckStackConflict` is ranking mantles by **which proc
spell has the larger row id**. `42710 < 42711` is why Zealot loses to Standard. Renumbering the
procs would flip the outcome — which is the clearest possible sign the comparison is meaningless
here. This lands directly on the *"each stance gets its own proc"* decision: giving every stance
a distinct proc id is what puts an arbitrary, id-ordered tiebreak into the one slot that votes.

---

## 3. Blast radius

- **Cleric mantles** (`0004`, applied) — the whole exclusivity mechanism.
- **Monk dual stance pool** — same mechanism, twice over. Not yet authored. Fix before it is.
- **BACKLOG's *Data-only — no engine work needed* table**, rows *"Stances, one-at-a-time (P3.3)"*
  and *"Monk dual stance pool"*, both currently marked "still data-only" — that claim does not
  survive this trace.
- **Not affected: the D2 1–10 tier lines.** Same-name lines differing only in magnitude arbitrate
  correctly on value, which is what the existing entry already says.

This is the **second** correction to the same P3.3 assumption. [P1-SOURCE-VERIFICATION.md](P1-SOURCE-VERIFICATION.md)
§1 already established that `spellgroup` does not drive stacking, and matching-layout was the
replacement. The replacement is also wrong.

---

## 3b. ✅ Resolved — W13, decided and built

**Option B was chosen and is implemented.** `Mob::CheckStackConflict()` now carries a
WorldDungeon exclusivity check placed **above** the `effect_match` branch:

```cpp
if (spellid1 != spellid2 &&
    sp1.spell_group >= WD_EXCLUSIVE_SPELLGROUP_BASE &&
    sp1.spell_group == sp2.spell_group) {
    return 1;   // overwrite — newest always wins
}
```

- `common/spdat.h` — `WD_EXCLUSIVE_SPELLGROUP_BASE = 500000`, documented next to W1's constant.
- `zone/spells.cpp` — the check, sited above `effect_match` precisely because everything native
  lives below it.

**The rule:** two different spells sharing a `spell_group` at or above 500,000 are one stance
pool. Exactly one may be worn and the incoming one always wins — **magnitude is deliberately not
consulted**, because swapping to a weaker stance is a legitimate tactical choice and picking is
the entire point of a pool. Same-id casts never reach the check (handled earlier at `:3097`), so
a refresh keeps its normal level comparison.

Why this shape:

- **No new column, no new SPA.** F1 already allocates WorldDungeon spellgroups from 500,000 and
  the nine mantles already share `500001`. The pool concept was already in the data.
- **Beneficial spells only** — added while authoring the Necromancer, and load-bearing.
  `spell_group` now carries **two unrelated meanings**: an exclusivity pool here, and a
  **combo-flag family** for W1's `IS_TARGET_HAS_WD_SPELLGROUP`. Combo families deliberately hold
  several spells — the Necro's single-target and AE flavour DoTs share a group precisely so
  Reap's Limit matches either — and those must keep stacking normally. Every stance pool is a
  beneficial self-buff and every combo flag is detrimental, so one test separates them with no
  new field. It also keeps the check clear of stock's multi-caster DoT handling. **Do not widen
  this without auditing every custom spellgroup.**
- **Stock behaviour is untouched.** PEQ's highest `spell_group` is **100,276** and **zero** stock
  rows sit at or above 500,000 (checked on the live DB), so the branch cannot fire on stock content.
- **The Monk's two pools are just two spellgroups.** No per-class code, and the mechanism serves
  all sixteen classes.
- **Layout is now irrelevant to exclusivity.** Families may share an effect layout or not; the
  fragile unenforced invariant that option A depended on is gone.

**Option C is now moot.** Arbitration is bypassed entirely for same-group spells, so the proc slot
no longer participates in stacking and the spell-id tiebreak cannot fire. Leaving each stance its
own proc — the earlier locked decision — is safe again.

**Built clean and deployed** (208/208, restarted, 25 zones up, `Loaded [40,734] spells`).
**Not yet cast in-game** — see §5.

---

## 4. Options as they stood — retained for the record

**⚠️ First, the finding that collapses it: SPA 446–449 are inside the same branch.**

The obvious escape hatch is the `AStacker`…`DStacker` chain — the engine's purpose-built "these
buffs are mutually exclusive" primitive. It does not help. Those checks sit at
`zone/spells.cpp:3181-3205`, which is **inside the `if (!effect_match)` block that opens at
`:3164`** — the same guard that disables SPA 149.

Generalising: **every native exclusivity primitive the engine has — 148, 149, and 446–449 — lives
behind `!effect_match`.** A design that makes layouts identical forfeits all of them at once.
There is no data-only exclusivity mechanism that survives matching layouts. That leaves two real
options.

**A. Deliberately break the layout match.** Give each mantle family one distinguishing slot so
`effect_match` is false, then use SPA 149 (or 446–449) as intended. No code, ships today — but it
is the exact *inverse* of the locked decision, and correctness then depends on every stance line
ever authored keeping its layouts deliberately **un**matched, with nothing enforcing it and a
silent failure mode when someone forgets. The Monk's two pools multiply that risk.

**B. One C++ check at the buff-application site.** An explicit "at most one buff from exclusivity
group N" test, keyed on a custom field rather than inferred from layout. Small and bounded — in
the same family as W1, which is already built — and it fixes stances **once for all sixteen
classes** instead of being re-derived per class. It also removes the invariant A depends on, so
layouts become free to match or not. The owner has said C++ or Lua is acceptable if it stays KISS
and performant.

**C. Move the proc out of the arbitrating slot — do this regardless.** Independent of A and B.
Slot 5 currently makes the engine rank mantles by proc **spell id**; that is a latent bug under
either option and should not survive the fix.

---

## 5. What is verified and what is not

**Verified by source read:** everything in §1 and §2. The line numbers are from this checkout;
the values are read from the live `spells_new` rows.

**Verified by build and deploy:** W13 compiles clean and is running on all 25 zones.

**Not verified in-game — this is the one thing still owed.** Nothing here has been cast. With
W13 in place the `0004` matrix should now read:

| Step | Expected with W13 |
|---|---|
| 1. Standard Mk. I lands | ✅ |
| 2. Standard Mk. III over Mk. I | ✅ replaces — same group 500001 |
| 3. **Zealot Mk. I while Standard Mk. III up** | ✅ **takes hold** — the gate, now by W13 rather than SPA 149 |
| 4. Warden Mk. II over Zealot Mk. I | ✅ replaces |
| 5. Exactly one mantle ever present | ✅ |
| 6. Standard Mantle improves a heal | **genuinely open** — unaffected by any of this; proves the focus path and `not_focusable = 0` |

Run it with a GM client and `#cast` (the mantles are `classes2 = 254`, AA-granted, so they are
not scribable). Zone logs will show `share WorldDungeon exclusivity group [500001], overwriting`
on each swap — that line is the direct confirmation W13 fired. **Step 6 is the one that can still
surprise us**; steps 1–5 are now predicted by two independent traces.
