# Rust Gotchas — Precision Traps When Teaching

A checklist of Rust-specific semantics that, if glossed over, produce sloppy teaching and bake latent
bugs into the user's mental model. Consult this file before writing any problem statement, example, or
nudge that touches the affected mechanic. When a gotcha applies, either (a) state the narrowing contract
in the problem, or (b) use the fully general form. Never silently pick the simpler form without saying so.

---

## String types: &str vs String vs bytes

- `&str` is an immutable string slice — a reference to UTF-8 bytes stored somewhere, not a heap
  allocation. String literals (`"hello"`) are `&str`.
- `String` is a heap-allocated, growable UTF-8 string. Use `.to_string()` or `String::from()` to convert.
- `s.chars()` iterates over Unicode scalar values (char). `s.bytes()` iterates over raw bytes (u8).
- `s.chars().nth(i)` is O(n), not O(1). Rust has no O(1) Unicode character indexing.
- `s[i]` is a **compile error** for strings — Rust does not allow byte-index subscripting on `&str` or
  `String`. Use `s.as_bytes()[i]` for raw bytes (ASCII-only), or `s.chars().nth(i)` for chars.
- `s.len()` returns byte length. `s.chars().count()` returns character count. These differ for non-ASCII.

**Teaching rule:** If a problem uses byte-level access (`s.as_bytes()[i]`, byte comparisons with `b'a'`),
state ASCII-only in the contract. Otherwise default to `.chars()` or `.char_indices()` for correct
Unicode handling. Never nudge from `.chars()` toward `.as_bytes()[i]` unless the ASCII contract is
already stated.

---

## Ownership and move semantics

- Assigning a non-Copy value to a new variable (or passing it to a function) **moves** it. The original
  binding becomes unusable. `let b = a; use(a);` is a compile error for `String` and `Vec`.
- Primitives (`i32`, `bool`, `char`, `f64`, `usize`, etc.) implement `Copy` — assignment copies, no move.
- `.clone()` explicitly deep-copies. It is always correct but potentially expensive. Nudge toward
  borrowing first; use `.clone()` only when the owned value is genuinely needed.
- Passing `T` to a function transfers ownership. Passing `&T` or `&mut T` borrows without moving.

**Teaching rule:** State in every problem whether the function takes ownership (`T`) or borrows (`&T`).
Never show code that moves a value and then uses it without calling this out. If the user hits a
"value used after move" error, name the mechanic before asking them to fix it.

---

## Borrowing rules

- You can have either **one `&mut T`** or **any number of `&T`** at the same time — never both.
- A borrow must not outlive the value it refers to.
- These rules are enforced at compile time. "Cannot borrow as mutable because it is also borrowed as
  immutable" is the canonical error.

**Teaching rule:** If a problem's solution requires mutable access to a slice while also reading it
(common in two-pointer or partition problems), route the user toward index-based mutation (`v[i] = x`)
or `split_at_mut` rather than two simultaneous references. State this constraint in the problem file
if it is a likely stumbling point.

---

## Integer types and usize

- Array and Vec indexing requires `usize`. Mixing `i32` and `usize` without casting is a compile error.
- `v.len()` returns `usize`. Computing `v.len() - 1` on an empty Vec **underflows** — `usize` wraps to
  a very large number (panics in debug mode). Always bounds-check before subtracting from `usize`.
- Integer overflow panics in debug builds; wraps silently in release builds. `i32::MAX + 1` panics in
  debug. Use `checked_add`, `saturating_add`, or `wrapping_add` for overflow-aware arithmetic.
- Cast explicitly with `as`: `let i: usize = n as usize;`. No implicit integer widening in Rust.
- Use `i32` for algorithm logic (cleaner arithmetic); use `usize` for indexing. Cast at the boundary.

**Teaching rule:** State whether inputs can be empty before any `len() - 1` access. State whether
overflow is possible for sum/product problems. Never silently use `len() - 1` on an input that could
be empty.

---

## Vec indexing panics, not returns None

- `v[i]` panics if `i >= v.len()` — there is no automatic `None`.
- `v.get(i)` returns `Option<&T>` — safe when the index might be out of bounds.

**Teaching rule:** Problems that access by index must state the bounds contract. Show `.get(i)` when
safety is needed; show `v[i]` only when the index is proven in-bounds by the problem's invariant.

---

## Iterator laziness

- Iterators in Rust are lazy — `.map()`, `.filter()`, `.zip()`, `.enumerate()` do **nothing** until
  consumed.
- Consuming adapters: `.collect()`, `.sum()`, `.count()`, `.for_each()`, `.fold()`, `.any()`, `.all()`.
- Forgetting `.collect()` after a chain produces a compile error (type cannot be inferred) or a
  warning (unused iterator). The values are not produced until consumed.

**Teaching rule:** If a problem uses iterators, the chain must end in a consuming adapter. Do not show
`.map(|x| x * 2)` without telling the user how to consume it. When introducing iterators, demonstrate
the laziness explicitly — show that the map alone produces only a type, not values.

---

## HashMap non-determinism

- Iteration order over a `HashMap` is **not defined** and randomizes between runs (uses a random seed
  by default).
- If a problem requires deterministic output from a map, either sort the keys, use a `BTreeMap`
  (sorted by key), or collect into a `Vec` and sort.

**Teaching rule:** Any example or expected output that iterates a `HashMap` must sort first, use a
`BTreeMap`, or explicitly disclaim non-determinism in the problem statement.

---

## Two mutable references: use split_at_mut or index-based mutation

- Rust's borrow checker prevents two `&mut` references to the same `Vec` simultaneously. This is a
  compile error, not a runtime error.
- Two-pointer patterns that write to both `v[left]` and `v[right]` work fine when done via integer
  indices (`v[left] = x; v[right] = y;`). They fail if you try to hold two `&mut` refs simultaneously.
- `slice.split_at_mut(mid)` splits a mutable slice into two non-overlapping mutable parts.

**Teaching rule:** Two-pointer and partition problems should use index-based mutation. If the user
tries to hold two `&mut` references, name the rule before asking them to fix it.

---

## Pattern matching exhaustiveness

- `match` must cover all cases or have a `_` wildcard arm. Missing arms are **compile errors**.
- `Option<T>`: must handle both `Some(x)` and `None`.
- `Result<T, E>`: must handle both `Ok(x)` and `Err(e)`.
- `.unwrap()` panics on `None`/`Err`. Acceptable when the contract guarantees a value exists — say so
  when using it in problem templates. Do not silently `.unwrap()` fallible operations.

**Teaching rule:** If a problem uses `Option` or `Result`, state whether the problem guarantees a
non-None/Ok value. If `.unwrap()` appears in example code, add a brief comment explaining why it is
safe under the stated contract.

---

## char vs byte in ASCII problems

- `'a'` is a `char` (Unicode scalar, 4 bytes). `b'a'` is a byte literal (`u8`, 1 byte).
- Comparing a `char` to a byte requires different syntax: `c == 'a'` (char); `b == b'a'` (u8).
- For ASCII-only problems, byte-level operations (`s.as_bytes()`, `b'a'`) are fine and often simpler.
  For general strings, use `.chars()` and `char` comparisons.

**Teaching rule:** If the problem is ASCII-only, stating that contract allows byte-level solutions.
Without the ASCII contract, use char-based operations. Never mix byte literals and char literals in
the same comparison without an explicit cast.

---

## Teaching discipline

Two rules derived from the above:

1. **State the contract.** Every problem file must declare the input domain (ASCII vs Unicode,
   non-empty, non-negative, sorted, bounded, no-duplicates). If the contract is missing, the user's
   "overcomplicated" solution may be the correct general one.

2. **Verify the nudge.** Before nudging the user toward a simpler form, confirm that form is correct
   under the stated contract. Consult this file before nudging on anything touching strings/bytes/chars,
   ownership, borrowing, indexing, iterators, or overflow. Never nudge toward a narrower-but-buggier
   solution.
