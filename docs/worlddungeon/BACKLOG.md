# WorldDungeon — Engine Work Backlog

Actionable code items derived from the design vault
(`New Ideas/EQ/WorldDungeon/` in Obsidian). The vault holds the *design*; this file holds
the *work*, with the file and hook targets it lands on.

Ordered by unblock-count, then by dependency. Sizes: **S** ≈ one sitting, **M** ≈ multi-day,
**L** ≈ spike first.

Evidence for every source claim is in [PHASE-0-SOURCE-VERIFICATION.md](PHASE-0-SOURCE-VERIFICATION.md).

Status: `open` · `in-progress` · `blocked` · `done`

---

## W1 — Spellgroup-on-target cast restriction · **S** · open

**Unblocks:** Wizard, Necromancer, Rogue, Druid, Berserker, Beastlord, Enchanter, Paladin (8)

Add a `SpellRestriction` ID meaning *"target has an active buff whose spell belongs to
spellgroup N"*, so the detonation pattern becomes data-only.

- `common/spdat.h:298` — new enum entry in `SpellRestriction`. Pick an ID in an unused range;
  the enum is sparse and live-derived, so avoid anything Live might claim.
- `zone/spell_effects.cpp:7571` — one branch in `Mob::PassCastRestriction()`. Scan the buff
  array, map each buff's `spell_id` to `spells[].spellgroup`, compare.
- No new consumers needed. It inherits `cast_restriction`, `caster_requirement_id`,
  SPA 442/443, and the SPA 0/79 LIMIT field for free.

**Design note:** the restriction ID has to encode *which* spellgroup. The existing enum is
flat constants, so either reserve a block (`base + spellgroup_id`) or read the spellgroup from
the spell's limit/max field alongside a single restriction ID. **Prefer the second** — the
enum stays clean and there is no ceiling on spellgroup count.

**Done when:** a builder spell leaves a buff, a detonator spell with the restriction fails to
land on an unbuffed target and lands on a buffed one, with no C++ per class.

---

## W2 — Ally-target expansion (primer P3.6) · **S** · open

**Unblocks:** Warrior, Cleric, Bard, Shaman, Paladin — *and the entire solo-first premise (D1)*

Group-target resolution must also resolve the caster's owned NPCs: pets, warders, blood
golems, dopplegangers, warhorn mercs, curse-raised minions, swarm bodies. Design calls for
temp/swarm bodies at reduced weight (suggest 50%).

- Extend the group-target path used by `Mob::EntityListToSpellTargets`.
- Swarm bodies are identified by `GetSwarmInfo()->owner_id` (`zone/aa.cpp:159`); commanded
  pets by `GetOwnerID()`.

One change site. Highest priority after W1 because every support class is non-functional solo
without it.

---

## W3 — Pet owner-redirect for beneficial effects · **S** · open

**Unblocks:** Shadowknight (Blood Golem), Beastlord (reciprocal procs, support-warder spec,
warder-triggered combos)

Pet self-benefit currently lands on the pet. Two hardcoded sites:

- `zone/mob.cpp:6850` — `Mob::MeleeLifeTap()` calls `HealDamage()` on `this`.
- `zone/mob.cpp:5366` — `Mob::ExecWeaponProc()` calls `SpellFinished(spell_id, this, ...)`
  for beneficial procs.

Gate the redirect on something opt-in (a pet flag, or a rule) rather than changing default
pet behaviour server-wide — stock pets should keep healing themselves.

`ExecWeaponProc` already has an `EVENT_WEAPON_PROC` quest hook (`mob.cpp:5336`) if per-case
script control is wanted instead.

---

## W4 — Accumulator (primer P3.2) · **M** · open

**Unblocks:** Paladin (ward → detonation), Shadowknight (banked taps), Warrior (damage
spread), Rogue (combo counter)

Track how much a buff has absorbed or dealt. No native equivalent exists.

- Absorb: hook `Mob::ReduceDamage()` in `zone/attack.cpp`, where SPA 55/161/162 already
  decrement.
- Damage dealt: hook the `Mob::CommonDamage()` out-path.
- Storage: a server-side field on the buff struct, never sent to the client. Preferred over
  data buckets — bucket churn on every swing is unacceptable.
- Readout: on fade via SPA 373 (confirmed to fire on depletion, see V2) or on detonation
  via W1.

**Build with W5 and W6 — same hook site.**

---

## W5 — Threshold trigger (primer P3.4) · **S** · open · *re-scope first*

**Unblocks:** Necromancer (life ward), Shadowknight (Famine stance), Berserker (execute)

**Do not start by writing C++.** SPAs 451/452 (`MeleeThresholdGuard`, `SpellThresholdGuard`),
453/454 (`TriggerMeleeThreshold`, `TriggerSpellThreshold`) and 450 (`MitigateDotDamage`) are
all marked implemented and cover part of this. Determine what they do *not* cover — the design
needs "below X% max HP", whereas 453/454 are "single hit over X damage" — then build only the
gap: a post-damage HP-ratio check in `Mob::CommonDamage()` firing a dormant buff's payload.

Shares its hook site with W4.

---

## W6 — Wizard mana ward conversion · **S** · open · *re-scope first*

Same `Mob::CommonDamage()` hook as W4/W5. Check SPA 457 `ResourceTap` (`spdat.h:1520`,
converts a % of DD/DoT damage to hp/mana/end) before writing anything — it may cover this
outright.

> **W4 + W5 + W6 are one work package.** One hook site, three features, eight classes.

---

## W7 — Swarm AI extensions (primer P3.5) · **M** · open · *reduced scope*

**Unblocks:** Necromancer, Enchanter, Ranger, Rogue

Two of the four documented sub-items are already handled — see V4:

- ~~Independent caps per swarm subtype~~ — **free.** The cap is per-cast; no cross-cast
  accounting exists (`zone/aa.cpp:114`).
- ~~Enchanter copies breaking mez~~ — **already built.** `RuleB(Spells, SwarmPetTargetLock)`
  or the `sticktarg` argument sets `SetPetTargetLockID` + `AggroImmunity`
  (`zone/aa.cpp:161-172`).

Genuinely remaining:

- **Doppleganger runtime spell list (Enchanter E7).** Swarm spell lists are static, from the
  `npc_types` row. Needs a runtime assignment path: snapshot the enchanter's memmed spellbar
  at summon, filter by an allow-list of spell categories. The per-cast `NPCType` copy at
  `zone/aa.cpp:103-109` is the existing seam.
- **Necro target inheritance / xtarget-clearing.** Target-lock is the opposite behaviour —
  it pins one target. Needs "acquire the owner's next target after the current one dies."
- **Swarm-pet death hook.** Not found; gates the Enchanter's count-driven survival buff.
  Start at `StartSwarmTimer()` and the `SwarmPet` struct.

---

## W8 — Damage redirection · **M** · open

**Unblocks:** Warrior (§9c interception, §9e Human Shield)

Build interception first with a direction parameter; derive Human Shield from it (per C1).

---

## W9 — DoT spread engine · **M** · open

**Unblocks:** Druid (§9a). Per-tick target scan plus duration copy. **Profile the cost** —
this is the one item with a real performance budget risk; see the vault's
*Performance Budget & Determinism Rules*.

---

## W10 — Bard aura projection · **S** · open

Already fully specced in the vault's *Bard Aura Patch*. Add the E4 scope filter.
Verify the SPA 270 aura-range assumption (vault V20) before starting.

---

## W11 — AC / avoidance cap override · **M** · open

**Unblocks:** all classes. Per *Combat Balance Envelope* §11.8. Interacts with vault V6
(block-chance SPA and its pre-50 viability).

---

## W12 — Rebirth level-unlock · **S** · open

Marked **[VERIFIED]** feasible in the vault's *Open Decisions*: `MaxExpLevel` = 50 plus
`quest::level()` grants on rebirth. Mostly script, not C++.

Remaining verification: ROF2 skill-cap curves for levels 51–65; per-character qglobal
level-ceiling enforcement.

**This is on the MVP critical path** — see *Build Order & MVP* — while most of W1–W11 are not.

---

## Critical-path note

The vault's *Build Order & MVP* puts the **entitlement/economy plumbing** first — Paragon →
qglobal → spell-vendor, token → AA NPC, mastery tracking, safe-zone travel,
Recommended-Level gear scaling, rebirth level-unlock. That work is **quest script and data,
not engine code**, so it does not appear as W-items above and is not blocked by any of them.

**These two tracks are parallel.** The engine backlog makes classes feel right; the
entitlement track makes the server playable at all. v1 ships on the entitlement track plus
W1, W2 and W12.

---

## Data-only — no engine work needed

Recorded so nobody re-opens them:

| Design element | Mechanism |
|---|---|
| Stances, one-at-a-time (primer P3.3) | Same `spellgroup`, same rank — native overwrite |
| Monk dual stance pool | Two spellgroups, `monk_offense` / `monk_defense` |
| 1–10 tier lines (D2) | `spellgroup` ranks 1–10, higher auto-overwrites |
| Bard group lifesteal | SPA 178 as a buff — each member taps for themselves (V3) |
| Ward fires on depletion, not just timeout | SPA 373 `CastOnFadeEffectAlways` (V2) |
| Ranger archery specialization (E6) | Real archery — full impl + Lua bindings (V15) |
| Swarm bodies and pet power | `pets` table via `GetPoweredPetEntry()` |
| Cleric, Monk | Zero custom C++ — build these first to validate the pipeline |
