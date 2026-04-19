# Rust Data Track

An optional track for becoming an idiomatic Rust developer focused on practical data manipulation —
iterators, collections, parsing, error handling, traits, and I/O. These are the patterns you reach
for every day in real Rust code.

This track is **independent** of both the algorithm track and the Rust Fundamentals track. Progress
is tracked in the `## Rust Data (optional track)` section of `progress.md`. Invoke it with
`train rust data`.

Available crates (always in `Cargo.toml`): `anyhow`, `serde` + `serde_json`, `regex`. Templates may
freely use `use anyhow::Result;`, `use serde::Deserialize;`, `use regex::Regex;`, etc. The one-file
constraint still applies — no `mod`, no multi-file crates.

Apply the same level-progression rules (0–4+), prerequisite gating, ASCII art introductions, and
scaffolding rules that govern the algorithm track. For level 0, introduce the concept with explanation
and ASCII art before presenting the first problem.

---

## 1. rust-data-parsing
(requires: rust-types ≥ 1, rust-iterators ≥ 1)

**Topics:** `str::parse::<T>()`, `split` / `split_whitespace` / `split_once`, tokenizing a line of
text, `trim`, converting between `&str` and numeric types, handling parse errors with `Result`.

**Level 0:** Parse a single integer from a string: `"42".parse::<i32>()`. Observe the return type is
`Result<i32, _>`. Unwrap it. Then call `.expect("not a number")` to get a clearer panic message if
parsing fails.

**Level 1:** Tokenize a space-delimited line (`"10 20 30"`) into a `Vec<i32>` using
`.split_whitespace()`, `.map(|s| s.parse().unwrap())`, `.collect()`.

**Level 2:** Handle parse failures gracefully — collect `Result`s and propagate the first error:
`.collect::<Result<Vec<i32>, _>>()?`.

**Level 3:** Parse a structured line like `"key: value"` using `split_once(':')`. Handle missing
delimiter (returns `None`).

**Teaching notes:** The `.parse::<T>()` method is the entry point to all Rust parsing. Always
establish the `Result` return type at level 0 — users who expect a raw value will be confused by the
type mismatch. The turbofish (`::<T>`) is often needed because the type can't be inferred; explain
it as "telling the compiler which type to parse into."

```
"  42  ".trim()  →  "42"
         ↓
    .parse::<i32>()
         ↓
    Ok(42)   or   Err(ParseIntError)
```

---

## 2. rust-data-strings
(requires: rust-data-parsing ≥ 1)

**Topics:** `.chars()` vs `.bytes()`, `.lines()`, `.split_whitespace()`, case conversion
(`.to_lowercase()`, `.to_uppercase()`), `.contains()`, `.starts_with()`, `.ends_with()`,
`.replace()`, `format!`, string building with `String::new()` + `.push_str()` / `.push()`.

**Level 0:** Count vowels in a string using `.chars().filter(|c| "aeiou".contains(*c)).count()`.
Observe the double-deref / copy: `char` is `Copy`, so the closure gets `&char` from `.chars()`'s
iterator — either dereference it or use `|&c|`.

**Level 1:** Reverse the words in a sentence: split on whitespace, collect to a Vec, reverse in
place, join with spaces. Use `.split_whitespace().collect::<Vec<_>>()`, `.reverse()`,
`.join(" ")`.

**Level 2:** Build a new string character by character — use `String::with_capacity(n)` and
`.push(char)`. Run-length encode a string: `"aaabbc"` → `"3a2b1c"`.

**Level 3:** Decode a string that contains percent-encoding (`%20` → space) by iterating with
`.chars()` and a state machine.

**Teaching notes:** `.chars()` iterates over Unicode scalar values (`char`); `.bytes()` iterates
over raw bytes (`u8`). For ASCII-only strings they differ only in type; for multi-byte UTF-8
characters they diverge. Default to `.chars()` unless bytes are explicitly needed. Consult
`docs/rust-gotchas.md` before writing any example that mixes char/byte indexing.

```
String indexing:
  "hello" [0]     ← COMPILE ERROR: String does not support [] indexing
  "hello".chars().nth(0)  → Some('h')
  "hello".as_bytes()[0]   → 104  (ASCII 'h')
```

---

## 3. rust-data-options
(requires: rust-enums ≥ 1)

**Topics:** `Option<T>` combinators: `.map()`, `.and_then()`, `.or()`, `.or_else()`, `.filter()`,
`.unwrap_or()`, `.unwrap_or_else()`, `.unwrap_or_default()`, the `?` operator on `Option` (inside
a function returning `Option`).

**Level 0:** Given `Option<i32>`, double the inner value if present: `opt.map(|x| x * 2)`. Compare
to the equivalent `match`. Establish mental model: "map transforms the inside without unwrapping."

**Level 1:** Chain with `.and_then()` — apply a function that itself returns an `Option`:
```
find_first_word(s)       // → Option<&str>
    .and_then(|w| w.parse::<i32>().ok())  // → Option<i32>
```

**Level 2:** `.filter(|x| *x > 0)` to gate on a predicate. `?` to propagate `None` early:
```rust
fn first_positive(v: &[i32]) -> Option<i32> {
    let n = v.iter().find(|&&x| x > 0)?;  // returns None if not found
    Some(*n * 2)
}
```

**Level 3:** Combine multiple `Option` sources: `.zip()` on two `Option`s, converting `Option` to
`Result` with `.ok_or(ErrorValue)`.

**Teaching notes:** Option combinators replace verbose `match` chains with a functional pipeline.
The key insight: **map keeps you inside the Option**, while `unwrap_or` exits it. Avoid pattern-
matching everything — show how `.map().and_then().unwrap_or_default()` reads like a sentence.

```
None.map(|x| x + 1)     →  None     (transform skipped)
Some(5).map(|x| x + 1)  →  Some(6)  (transform applied)

Some(5).and_then(|x| if x > 3 { Some(x) } else { None })  →  Some(5)
Some(2).and_then(|x| if x > 3 { Some(x) } else { None })  →  None
```

---

## 4. rust-data-results
(requires: rust-data-options ≥ 1)

**Topics:** `Result<T, E>` combinators mirroring `Option`: `.map()`, `.map_err()`, `.and_then()`,
`.or()`, `.unwrap_or()`. The `?` operator for error propagation. Custom error enums (simple version).
`collect::<Result<Vec<T>, E>>()`. `anyhow::Result` as a drop-in for quick prototyping.

**Level 0:** Parse a list of integers; surface the first parse error instead of panicking:
```rust
use anyhow::Result;
fn parse_ints(s: &str) -> Result<Vec<i32>> {
    s.split_whitespace().map(|t| Ok(t.parse::<i32>()?)).collect()
}
```
Step through each combinator until the user can write it unaided.

**Level 1:** `.map_err()` to convert one error type to another. Wrapping a standard library error
in a custom error message with `anyhow::Context` / `.context("while parsing foo")`.

**Level 2:** Custom error enum:
```rust
#[derive(Debug)]
enum MyError { ParseFailed(String), NotFound }
```
`impl std::fmt::Display for MyError` (or `#[derive(thiserror::Error)]` — introduce as bonus if
user is comfortable). Return `Result<T, MyError>`.

**Level 3:** Composing multiple error sources with `?` in a function that can fail in several ways.
Convert between error types using `From` impl or `.map_err(MyError::ParseFailed)`.

**Teaching notes:** Teach `anyhow::Result` first — it removes the error-type friction so the user
can focus on the `?` propagation pattern. Once `?` is intuitive, show the custom-error version as
"what anyhow does for you under the hood." The `collect::<Result<_, _>>()` idiom is a classic
Rust pattern worth a dedicated sub-problem if the user struggles.

```
Without ?:                         With ?:
match s.parse::<i32>() {           let n: i32 = s.parse()?;
    Ok(n)  => Ok(n * 2),           Ok(n * 2)
    Err(e) => Err(e.into()),
}
```

---

## 5. rust-data-hashmaps
(requires: rust-data-strings ≥ 1, rust-iterators ≥ 1)

**Topics:** `HashMap<K, V>` and `BTreeMap<K, V>` (sorted vs unsorted), `.insert()`, `.get()`,
`.contains_key()`, the **entry API** (`.entry(k).or_insert(v)`, `.or_insert_with()`, `.and_modify()`),
counting occurrences, grouping values, iterating over `(key, value)` pairs, `HashSet<T>` operations
(`.insert()`, `.contains()`, set intersection/union/difference).

**Level 0:** Count character frequencies in a string using the entry API:
```rust
let mut freq: HashMap<char, usize> = HashMap::new();
for c in s.chars() {
    *freq.entry(c).or_insert(0) += 1;
}
```
Emphasize the entry API vs. the insert/get pattern — entry avoids a double lookup.

**Level 1:** Group strings by their first character — value type is `Vec<String>`:
```rust
.entry(ch).or_insert_with(Vec::new).push(word);
```

**Level 2:** Iterate with `.iter()` over `(key, value)` pairs. Sort entries by value descending.
`BTreeMap` for when iteration order matters (sorted by key automatically).

**Level 3:** `HashSet` — find the intersection of two word lists. Set operations: `&` (intersection),
`|` (union), `-` (difference).

**Teaching notes:** The entry API is the idiomatic Rust way to do conditional insert-or-update. It's
worth a dedicated level-0 problem because beginners habitually reach for `.contains_key()` first.
`HashMap` is unordered; if a problem requires sorted output, either collect and sort, or use
`BTreeMap`.

```
Entry API:
HashMap: { "a": 1, "b": 2 }
                         ↓
.entry("a").or_insert(0) → returns &mut 1  (key exists)
.entry("c").or_insert(0) → inserts 0, returns &mut 0  (new key)
```

---

## 6. rust-data-iterators
(requires: rust-iterators ≥ 1, rust-data-hashmaps ≥ 1)

**Topics:** Advanced iterator combinators: `.fold()`, `.scan()`, `.chain()`, `.zip()`,
`.flat_map()`, `.take_while()`, `.skip_while()`, `.enumerate()` (in depth), `.peekable()`,
`.windows()`, `.chunks()` (on slices), building pipelines that combine multiple combinators.

**Level 0:** `.fold()` as a generalization of sum/max/min — implement `sum` and then `max` using
only `fold`. Establish mental model: `fold` is "reduce with explicit state."

**Level 1:** `.chain()` to combine two iterators. `.zip()` to produce `(a, b)` pairs. `.flat_map()`
to flatten one level: `vec!["one two", "three"].iter().flat_map(|s| s.split_whitespace())`.

**Level 2:** `.scan()` for stateful transformation (running total, not just final value).
`.take_while(|x| ...)` and `.skip_while(|x| ...)` for conditional early stop / skip.

**Level 3:** `.peekable()` — look at the next element without consuming it; useful for lexers.
`.windows(n)` and `.chunks(n)` on slices for sliding-window and batch processing.

**Teaching notes:** This concept builds on the fundamentals-track `rust-iterators` (`.map`, `.filter`,
`.collect`) and teaches the combinators that come up in practice but are less well-known. Prioritize
`.fold()`, `.flat_map()`, and `.chain()` as the highest-value additions. A pipeline like:
```rust
lines.iter()
    .map(|l| l.trim())
    .filter(|l| !l.is_empty())
    .flat_map(|l| l.split(','))
    .map(|t| t.parse::<i32>().unwrap_or(0))
    .filter(|&n| n > 0)
    .sum::<i32>()
```
is an excellent capstone at level 3 — ask the user to write it from a prose spec.

---

## 7. rust-data-sorting
(requires: rust-data-iterators ≥ 1)

**Topics:** `Vec::sort()`, `.sort_by(|a, b| a.cmp(b))`, `.sort_by_key(|x| key_fn(x))`,
`.sort_unstable_by_key()`, `.iter().min()` / `.max()`, `.iter().min_by_key()` / `.max_by_key()`,
`.partition(|x| pred(x))`, `.dedup()`, `.rev()` on iterators, sorting strings.

**Level 0:** Sort a `Vec<i32>` ascending and descending. Descending: `.sort_by(|a, b| b.cmp(a))`
— walk through why `b.cmp(a)` reverses the order vs `a.cmp(b)`.

**Level 1:** Sort a `Vec<String>` by length (`.sort_by_key(|s| s.len())`). Then by length
descending, breaking ties lexicographically.

**Level 2:** `.partition()` — split a `Vec<i32>` into even and odd halves. `.dedup()` — remove
consecutive duplicates (note: must be sorted first to dedup all duplicates globally).

**Level 3:** Sort structs — `sort_by_key` with a key derived from a field. Introduce `Ordering`
manually for multi-key sort: sort by (field1 desc, field2 asc).

**Teaching notes:** `.sort_by_key()` is idiomatic Rust for most sorting needs — prefer it over
`.sort_by()` unless a more complex comparator is needed. `sort_unstable_*` variants are faster when
stability doesn't matter (most cases). The `.rev()` trap: `.rev()` on an iterator is not the same
as `.sort()` + `.reverse()` on the vec — one reverses the order of an already-ordered iterator,
the other reverses in-place. Be explicit about this.

```
sort_by_key(|s| s.len()):
  ["banana", "fig", "apple", "kiwi"]
       ↓
  ["fig", "kiwi", "apple", "banana"]   (stable: kiwi before apple if equal length)
```

---

## 8. rust-data-traits
(requires: rust-traits ≥ 1, rust-data-results ≥ 1)

**Topics:** Implementing `FromStr` so a type is parseable with `.parse()`. `std::fmt::Display`
for custom `{}` formatting. `Debug` customization (manual `impl` vs `#[derive]`). `From<T>` /
`Into<T>` for type conversions. `Ord` / `PartialOrd` for sorting custom types.

**Level 0:** Implement `FromStr` for a simple type:
```rust
use std::str::FromStr;
struct Point { x: i32, y: i32 }
impl FromStr for Point {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> { ... }
}
// Now: "3,4".parse::<Point>()? works.
```

**Level 1:** `impl Display for Point` — custom `{}` output. Compose with `.to_string()`.
`impl From<&str> for Point` — lets you write `Point::from("3,4")` and `"3,4".into()`.

**Level 2:** `impl PartialOrd` and `impl Ord` for a struct so it can be used with `.sort()`,
`.min()`, and `BTreeMap`. Introduce the ordering: `Ord` requires `Eq`; derive `Eq` +
`PartialEq` first.

**Level 3:** Combine: parse a CSV line into a custom struct via `FromStr`, sort a `Vec` of structs
by a field, display them with `Display`.

**Teaching notes:** `FromStr` is the unlock that makes `.parse()` work for your own types. It's
the cleanest end-to-end story for this concept. `From`/`Into` are dual — `impl From<A> for B`
gives you `B::from(a)` and also `a.into()` (the compiler derives `Into` automatically). Teach `From`
and explain `Into` as "free" rather than asking the user to implement both.

---

## 9. rust-data-closures
(requires: rust-data-iterators ≥ 1)

**Topics:** The three closure traits: `Fn` (can be called multiple times, borrows captures),
`FnMut` (can be called multiple times, mutably borrows captures), `FnOnce` (called once, may
move captures). `move` closures. Closures that capture and mutate state. Passing closures as
parameters (`fn apply<F: Fn(i32) -> i32>(f: F, x: i32) -> i32`). Returning closures
(`Box<dyn Fn>`).

**Level 0:** Write a closure that captures a variable from its enclosing scope:
```rust
let offset = 10;
let add_offset = |x| x + offset;  // captures &offset (Fn)
println!("{}", add_offset(5));     // 15
```
Show that the closure borrows `offset` — the variable stays accessible.

**Level 1:** `FnMut` — a closure that mutates captured state:
```rust
let mut count = 0;
let mut inc = || { count += 1; count };
println!("{}", inc()); // 1
println!("{}", inc()); // 2
```
Note: while `inc` exists, `count` is exclusively borrowed — you can't read `count` directly.

**Level 2:** `move` closures — transfer ownership into the closure:
```rust
let name = String::from("Alice");
let greet = move || println!("Hello, {name}!");
// `name` is moved; can't use it here
greet();
```
Use case: closures passed to `thread::spawn` (conceptual intro — no threading required in the
problem).

**Level 3:** Write a generic higher-order function that accepts `F: Fn(i32) -> i32` and applies it
to every element of a `Vec`. Return a closure from a function (`-> Box<dyn Fn(i32) -> i32>`).

**Teaching notes:** The three traits form a hierarchy: every `FnOnce` is callable once; `FnMut` is
also `FnOnce`; `Fn` is also `FnMut`. When writing generic bounds, use the least-restrictive one
that works: `Fn` for read-only, `FnMut` for mutable captures, `FnOnce` for "called exactly once."
Most iterator combinators take `FnMut`.

```
Closure trait selection:
  |x| x + constant       →  Fn      (immutable capture)
  || { count += 1; }     →  FnMut   (mutable capture)
  move || drop(owned)    →  FnOnce  (moves captured value out)
```

---

## 10. rust-data-io
(requires: rust-data-results ≥ 1)

**Topics:** `io::stdin()` + `.read_line(&mut buf)`, `io::BufReader` + `.lines()` iterator for
reading stdin line by line, `fs::read_to_string(path)` for reading a whole file, `fs::write()`
for writing a file, `println!` / `eprintln!` / `format!` / `write!` / `writeln!`.

**Level 0:** Read a single line from stdin, trim the newline, parse as an integer:
```rust
use std::io;
fn main() {
    let mut input = String::new();
    io::stdin().read_line(&mut input).expect("failed to read");
    let n: i32 = input.trim().parse().expect("not an integer");
    println!("{}", n * 2);
}
```
Trace why `.trim()` is required (`.read_line()` includes the `\n`).

**Level 1:** Read multiple lines until EOF using `.lines()` on a `BufRead`:
```rust
use std::io::{self, BufRead};
fn main() {
    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        let line = line.expect("read error");
        println!("{}", line.to_uppercase());
    }
}
```

**Level 2:** `fs::read_to_string("input.txt")` — read an entire file into memory, process it,
write results to a new file with `fs::write()`. Propagate errors with `anyhow::Result`.

**Level 3:** Structured I/O — parse a multi-line format (e.g., first line is a count `N`, next `N`
lines are key-value pairs separated by `:`) into a `HashMap`. Emit results as JSON using
`serde_json::to_string_pretty(&map)` + `println!`.

**Teaching notes:** `.read_line()` appends to the buffer (does not clear it) and includes the
newline — both are beginners' first bugs. Always show `.trim()` in the first example. `BufRead`
is a trait (not a type) — to use it on stdin, call `.stdin().lock()` to get a `StdinLock` that
implements `BufRead`. The `.lines()` iterator strips newlines automatically.

```
read_line gotcha:
  let mut buf = String::new();
  stdin.read_line(&mut buf);   // buf = "hello\n"
  buf.trim()                   // → "hello"  ← always trim
  buf.parse::<i32>()           // Err: "hello\n" is not a number without trim
```

---

## Teaching Order Summary

```
rust-data-parsing  (requires: rust-types ≥ 1, rust-iterators ≥ 1)
    └── rust-data-strings
            └── rust-data-hashmaps  (also requires rust-iterators ≥ 1)
                    └── rust-data-iterators (also requires rust-iterators ≥ 1)
                            ├── rust-data-sorting
                            └── rust-data-closures

rust-data-options  (requires: rust-enums ≥ 1)
    └── rust-data-results
            ├── rust-data-traits  (also requires rust-traits ≥ 1)
            └── rust-data-io
```

Earliest unblocked order (assuming fundamentals prerequisites are met):
parsing → (strings || options) → results → hashmaps → iterators → (sorting || closures || traits || io)
