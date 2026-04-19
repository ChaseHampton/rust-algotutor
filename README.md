# algotutor

An AI-powered algorithmic training system. Open a Claude Code session in this directory, type `train`, and start solving
problems.

## How it works

Claude acts as a tutor that generates progressively harder algorithm problems in Rust. It tracks your skill level across
32 concepts — from arrays and strings up through dynamic programming and system design — and picks the next problem
based on where you are.

### Commands

| Command                          | What it does                                                        |
|----------------------------------|---------------------------------------------------------------------|
| `train`                          | Get the next algorithm problem — drill, re-solve, mix, or new      |
| `train rust basics`              | Get the next Rust Fundamentals problem (optional track)             |
| `train rust data`                | Get the next Rust Data problem (optional track)                     |
| `check`                          | Submit your solution for evaluation                                 |
| `I don't know`                   | Break the problem into simpler sub-problems                         |
| `I want to solve [problem name]` | Request a specific problem                                          |
| `review`                         | Review cards due today (inline, Claude-driven)                      |
| `mistakes`                       | Show your recurring-error report                                    |

### Concepts covered

**Fundamentals** — arrays, strings, loops, nested loops, math

**Core Data Structures** — maps, sets, matrix, stacks, queues, linked lists, heaps

**Core Techniques** — sorting, binary search, two pointers, sliding window, prefix sums, bit manipulation

**Recursion and Trees** — recursion, trees, tries

**Graph Algorithms** — graphs, topological sort, union-find, shortest path

**Advanced Techniques** — greedy, intervals, backtracking, divide and conquer, dynamic programming, monotonic stacks,
design

### Optional tracks

Two optional tracks sit alongside the algorithm training. Either can be started at any time without affecting your
algorithm progress.

**Rust Fundamentals** (`train rust basics`) — 9 concepts covering the Rust language itself: variables and types,
ownership, borrowing, structs, enums, traits, iterators, closures, and lifetimes. Start here if you are new to Rust.

**Rust Data** (`train rust data`) — 10 concepts on idiomatic Rust for data manipulation: parsing, string operations,
Option and Result combinators, HashMaps, advanced iterators, sorting, custom traits (`FromStr`, `Display`, `Ord`),
closures, and I/O. Focused on practical, day-to-day Rust patterns. The following crates are always available in this
track: `anyhow`, `serde` + `serde_json`, `regex`.

### Spaced repetition review

As you solve problems, Claude automatically creates review cards capturing what you learned — algorithmic patterns, Rust
syntax, data structure properties. Cards follow the
[SuperMemo 20 Rules for effective memorization](https://www.supermemo.com/en/blog/twenty-rules-of-formulating-knowledge).

Say `review` to start an inline review session. Claude presents each due card, waits for your recalled answer, shows
the back, and asks you to rate 1–4 (Again / Hard / Good / Easy). Cards are scheduled with a spaced-repetition
algorithm; correct recalls push the next due date further out.

### Mistake tracking

Every failed `check` is tagged with a fixed error taxonomy (off-by-one, forgotten-update, missed base case,
empty-input missed, wrong-algorithm, and ~25 more) and logged to `mistakes.json`. Gaps that would otherwise evaporate
at the end of a session stick around as data.

When any category accumulates ≥ 3 unresolved entries in your recent history, `train` stops picking a new concept and
instead hands you a tiny single-category drill — five-line problems stripped of surrounding concept, aimed at exactly
that failure mode. Solve it and the oldest open mistakes in that category close out.

Every 7 days, `train` prints a short digest of your top recurring categories. Run `mistakes` any time to see the full
report on demand.

### Re-solve

Solving a problem once isn't mastery. Every successfully solved problem enters a Leitner schedule (7 / 21 / 60 / 180 /
365 days) in `resolve.json`. When a problem comes due, `train` hands it back with a fresh `src/main.rs` template —
your previous solution is hidden — and you re-solve it from scratch.

A clean re-solve pushes the next due date further out. Needing scaffolding holds the step. Giving up (`give up`,
`fail this`, `skip re-solve`) resets the ladder, and **two consecutive failed re-solves on the same concept** drop
its level by one.

### Mix

Research shows interleaved practice beats grinding one concept at a time. Once you have 5+ concepts at level 2+ and
at least 3 have gone cold (untouched for 14+ days), `train` starts a mix session — 3 problems from 3 different
concepts, one after the other, each drawn one level below your working level so the context switching itself is the
challenge.

Mix doesn't raise concept levels. It updates a per-concept retention score in `retention.json`. Low retention shows up
as a nudge on `train`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Rust](https://www.rust-lang.org/tools/install) (via `rustup`)

## Getting started

1. Clone the repo
2. Open a Claude Code session in the directory
3. Type `train`

On first run, Claude will initialize your progress file and problem directory. Your progress is local and gitignored.

## Recommendations

You can use `claude --dangerously-skip-permissions` to not be prompted all the time.

`Claude Sonnet 4.6` is set as the default model in `.claude/settings.json`.

The working problem is always inside `src/main.rs`. You can validate with `cargo run` before asking `claude check`.

Try to make as much progress as you can before saying `I don't know`. This way Claude can better assess your gaps and
missing prerequisites.

It should feel effortful.

## Model setup

Claude Code defaults to whichever model is set in `.claude/settings.json`. To override per-session, use `/model` in
the Claude Code UI or pass `--model` on the CLI.
