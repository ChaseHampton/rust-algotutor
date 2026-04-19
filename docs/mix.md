# Mix Mode

Mix mode tests *transfer* — whether the user can switch contexts between concepts in a single session. Research shows
interleaved practice beats blocked practice for long-term retention, even though it feels harder in the moment. Mix
sessions do NOT raise concept levels; they update a separate **retention** score per concept in `retention.json`. Cold
concepts (not exercised recently) are weighted heavier when picking which concepts to mix.

## `mix.json` format

If the file doesn't exist, treat it as `{"last_mix_at": null, "active_session": null}` and create it on first write.

```json
{
  "last_mix_at": "2026-04-16T00:00:00Z",
  "active_session": {
    "id": "mix_1713268800",
    "started_at": "2026-04-16T10:00:00Z",
    "concepts": ["arrays", "sliding-window", "stacks"],
    "problems": ["034", "035", "036"],
    "current_index": 1,
    "outcomes": ["clean"]
  }
}
```

- `last_mix_at` — RFC3339 timestamp when the last mix session **completed or was abandoned**. Never updated on session
  start — so an in-progress session does not burn the cooldown.
- `active_session` — null when no mix is in progress. When non-null, the user is working through `problems` in order.
  `outcomes` records per-problem results (clean/recovered/failed) matching position in `problems`.

## `retention.json` format

If missing, treat as `{}`. Keyed by concept name. Missing concept behaves as `{retention: 0, last_touched: null}`.

```json
{
  "arrays": {"retention": 0.8, "last_touched": "2026-04-10T00:00:00Z"},
  "binary-search": {"retention": 0.4, "last_touched": "2026-03-22T00:00:00Z"}
}
```

- `retention` — float in [0, 1]. Updated **only** by mix outcomes.
- `last_touched` — RFC3339 timestamp of the last engagement with this concept (any solve: first-solve, re-solve, or
  mix). Updated broadly because any activity refreshes the cold-concept clock.

## Retention decay

Retention decays lazily on read: `0.1` per full 14-day period since `last_touched`.

```
days = (now - last_touched) / 86400
periods = floor(days / 14)            # 0 if days < 14
effective = max(0, stored_retention - 0.1 * periods)
```

On any write to retention (mix outcome), apply decay first, then the delta, then update `last_touched`:

```
new_retention = clamp(0, 1, effective_before + delta)
```

Missing concepts behave as retention 0; no decay applied.

## Unlock

Mix is available only when **≥ 5 concepts are at level ≥ 2** in `progress.md`. Below that threshold, the mix-start
check is a no-op.

## Timing trigger

The Mix-start check in the `train` preamble fires a new session when **all three** conditions are true:

1. Unlock threshold met (≥ 5 concepts at level ≥ 2).
2. `mix.json.last_mix_at` is null OR more than 7 days ago.
3. At least **3 eligible concepts** (level ≥ 2) are **cold** — `retention.json[<concept>].last_touched` is null or
   older than 14 days.

If any condition fails, skip to digest. Do NOT start a mix session.

## Starting a new session

1. **Pick 3 concepts.** Pool = concepts at level ≥ 2. Weight each cold concept (last_touched null or > 14 days ago) at
   **2×**, non-cold concepts at 1×. Draw 3 distinct concepts via weighted random.
2. **Pick a problem per concept.** For each selected concept:
   - Eligible level = `max(1, current_level - 1)` — one step below the user's working level. Interleaving is the
     challenge; don't stack novelty on top.
   - Pool = bank problems at that level the user has NOT solved in the last 30 days. This includes fresh bank
     problems the user has never seen (preferred) and previously solved ones that have cooled off.
   - Prefer fresh bank problems over reused ones; random pick from the eligible pool. If the pool is empty, generate
     a new bank-style variation for that concept at the same level.
3. **Generate session ID:** `mix_<unix_timestamp>`.
4. **Create problem files:**
   - Fresh bank problems → create `problems/NNN.md` as normal, with two extra header fields: `**Kind:** mix` and
     `**Mix Session:** <session_id>`.
   - Reused problems → do NOT duplicate the file; reuse the existing `NNN.md` in place.
5. **Write `mix.json.active_session`:**
   ```json
   {
     "id": "<session_id>",
     "started_at": "<now, RFC3339>",
     "concepts": ["<c1>", "<c2>", "<c3>"],
     "problems": ["<n1>", "<n2>", "<n3>"],
     "current_index": 0,
     "outcomes": []
   }
   ```
6. **Set `current.md`** to `<n1>:mix`.
7. **Write a fresh `src/main.rs` template** for problem `<n1>`.
8. **Announce** in one sentence: "Mix of 3: `<c1>`, `<c2>`, `<c3>` — cold concepts surfacing. First up: problem `<n1>`
   (<title>)."

## Mix problem outcomes (on `check`)

When `current.md` ends in `:mix`, classify the outcome for this single problem:

- **Clean** — `check` passes first try; no "I don't know"; no prior failed `check` on this mix problem.
- **Recovered** — passes eventually, but scaffolding was used OR a prior `check` failed OR a hint was given.
- **Failed** — user says "skip", "next", "give up on this one", or equivalent before a successful `check`.

State updates per outcome, applied to `retention.json[<concept>]`:

| outcome   | `retention` delta   | `last_touched` |
|-----------|---------------------|----------------|
| clean     | +0.2 (cap 1.0)      | now            |
| recovered | 0                   | now            |
| failed    | −0.3 (floor 0)      | now            |

Apply decay first (see "Retention decay"), then the delta. Append the outcome to
`mix.json.active_session.outcomes`.

Do NOT raise the concept level. Do NOT register in `resolve.json`. Do NOT re-create spaced-repetition cards for
reused problems; fresh mix problems follow normal card-creation rules on clean solve.

Mistake tracking works normally for mix problems — failed `check` logs with `trigger: "check"`; scaffolding uses
`trigger: "scaffold"`.

## Advancing the session

After classifying a mix problem's outcome:

- If `current_index + 1 < len(problems)`:
  - Increment `current_index`.
  - Set `current.md` to `<next_problem>:mix`.
  - Write a fresh `src/main.rs` template for the next problem.
  - Announce: "Next in mix: `<concept>` — problem `<num>` (<title>), <i+1>/<len>."
- Else (last problem in the session):
  - Set `mix.json.last_mix_at` = now.
  - Set `mix.json.active_session` = null.
  - Reset `current.md` to empty.
  - Summarize: "Mix session complete. Outcomes: clean×N, recovered×M, failed×K. Retention updated."

## Skipping one problem vs abandoning the session

- **Skip one** — "skip", "next", "move on this one" → classify as **failed**, update retention, advance to next.
- **Abandon session** — "end mix", "quit mix", "abandon session" → classify the current problem as **failed**, mark
  any remaining problems as **failed** too (applying retention deltas for each), set `last_mix_at = now`, clear
  `active_session`, reset `current.md`. Summarize as normal.

## Scaffolding during mix

Scaffolding is allowed during mix. It downgrades the current mix problem's outcome to **recovered** at best, even if
the user eventually passes cleanly. Mistake entries logged during mix scaffolding use `trigger: "scaffold"` (not a
new value — scaffolds during mix are ordinary scaffolds).

Sub-problem files generated during mix scaffolding follow the normal `NNNa.md`, `NNNb.md` convention. They are NOT
part of the mix session and are NOT registered in `resolve.json`.

## Resume semantics

If `mix.json.active_session` is non-null when `train` runs, the Active-mix-resume preamble step preempts everything
else — no drill check, no re-solve check, no digest. Rationale: abandoning a session half-complete fragments the
retention signal, and drills/re-solves will queue patiently until the user finishes (or explicitly abandons).

## Exclusions

- Mix problems are NOT added to `resolve.json` (they don't enter the reproduction ladder).
- Drills and scaffold sub-problems are never picked *for* a mix session.
- Reused problems that already have an upcoming re-solve within 3 days are skipped (avoid back-to-back re-exposure).
