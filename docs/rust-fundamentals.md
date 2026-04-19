# Rust Fundamentals Track

An optional language track for users who want to learn Rust mechanics before (or alongside) the
algorithm curriculum. 9 concepts in teaching order.

This track is **separate** from the 32 algorithm concepts. Progress is tracked in the
`[rust-fundamentals]` section of `progress.md`. Neither track blocks the other — it is fine to start
algorithms before or after rust fundamentals.

When training this track, apply the same level-progression rules (0–4+), prerequisite gating, ASCII
art introductions, and scaffolding rules that govern the algorithm track. For level 0, introduce the
concept with explanation and ASCII diagrams before presenting the first problem.

---

## 1. rust-variables
(requires: nothing — always the entry point for this track)

**Topics:** `let`, `mut`, shadowing, `const`, type inference, basic types (`i32`, `f64`, `bool`,
`char`, `usize`).

**Level 0:** Declare variables with and without `mut`. Observe that reassigning an immutable binding
is a compile error. Write a program that shadows a variable (`let x = 5; let x = x + 1;`) and prints
the result.

**Level 1:** `const` vs `let` (evaluated at compile time, must have type annotation, uppercase by
convention). Type annotations: `let x: i32 = 5;`. Integer types: `i32`, `u32`, `usize`, `i64`.

**Level 2:** Block expressions as values (`let x = { let a = 3; a * 2 };`). Scope and shadowing rules
— inner scope shadow doesn't affect outer binding.

**Teaching notes:** Shadowing is Rust's substitute for reassigning with a type change. The compile
error "cannot assign twice to immutable variable" is the first wall beginners hit. The distinction
between shadowing (new binding) and mutation (`mut`) matters and is worth dwelling on.

---

## 2. rust-functions
(requires: rust-variables)

**Topics:** `fn` declaration, parameters with type annotations, return types, expressions vs
statements (no semicolon = expression that is the return value; semicolon = statement that returns
`()`), unit type `()`.

**Level 0:** Write a function `add(a: i32, b: i32) -> i32` that returns the sum. Fix the compile
error that results from accidentally adding a semicolon to the last expression.

**Level 1:** Multiple return via tuple (`-> (i32, i32)`); early return with explicit `return` keyword.

**Level 2:** Nested functions; passing functions as values using `fn` pointer types.

**Teaching notes:** The expression-vs-statement distinction is Rust's most common early gotcha. A
missing semicolon or an extra semicolon produces a type mismatch. Teach it explicitly with a concrete
compiler error — show both versions and compare the error messages.

```
// Returns i32 (expression — no semicolon)
fn double(x: i32) -> i32 {
    x * 2       ← value of the block
}

// Compile error: expected i32, found ()
fn double(x: i32) -> i32 {
    x * 2;      ← statement; block returns ()
}
```

---

## 3. rust-ownership
(requires: rust-variables, rust-functions)

**Topics:** The ownership rule (one owner at a time), move semantics, `drop` and RAII (memory freed
when owner goes out of scope), `Copy` types, `.clone()`, why ownership exists (memory safety without
a garbage collector).

**Level 0:** Write code that moves a `String` into a function. Observe the compile error when you try
to use it after the call. Fix it by either passing a reference or cloning.

**Level 1:** Show that `i32` copies instead of moves (implement `Copy`). Show that `String` moves.
Demonstrate `.clone()` to get an owned copy.

**Level 2:** Ownership of `Vec`; returning ownership from a function.

**Teaching notes:** This is the most important concept in the track and the one most likely to require
scaffolding. Use ASCII art to make ownership concrete: a box on the stack pointing to heap memory,
with an arrow showing the owner.

```
Stack frame:          Heap:
┌─────────────┐      ┌──────────────┐
│ s: String   │─────▶│ "hello"      │
│   ptr, len, │      │ (5 bytes)    │
│   capacity  │      └──────────────┘
└─────────────┘

After `let t = s;` (move):
┌─────────────┐
│ s: INVALID  │   ← compiler prevents use
└─────────────┘
┌─────────────┐      ┌──────────────┐
│ t: String   │─────▶│ "hello"      │
└─────────────┘      └──────────────┘
```

The heap data is not duplicated. Ownership is transferred. When `t` goes out of scope, the heap
memory is freed exactly once — no double-free, no leak.

---

## 4. rust-borrowing
(requires: rust-ownership)

**Topics:** `&T` (shared reference, immutable borrow), `&mut T` (mutable reference, exclusive borrow),
borrow rules (one `&mut` OR many `&T`, never both simultaneously), lifetime intuition (a borrow cannot
outlive the value it refers to).

**Level 0:** Pass a `String` by reference (`&String` or `&str`) so the caller keeps ownership. The
function reads but cannot modify through `&T`.

**Level 1:** `&mut T` — pass a mutable reference. Trigger the compile error by trying to hold two
`&mut` references simultaneously, then fix it.

**Level 2:** Why returning a reference to a local variable fails (dangling reference). Basic lifetime
intuition: `'a` annotations describe how long borrows are valid.

**Teaching notes:** The borrow checker error messages are often the best explanation — read them with
the user rather than around them. Mental model: "a reference is a non-owning pointer with
compiler-enforced rules about who can read or write and for how long."

```
Shared borrows (many readers, no writers):
┌──────────┐     ┌──────────┐
│ &s (r1)  │─┐   │ &s (r2)  │─┐
└──────────┘ │   └──────────┘ │
             ▼                ▼
         ┌─────────────────────┐
         │  s: String ("hi")   │  ← OK: many &T
         └─────────────────────┘

Mutable borrow (one writer, no readers):
┌─────────────┐
│ &mut s (w)  │──▶ s: String  ← OK: one &mut T
└─────────────┘
```

---

## 5. rust-types
(requires: rust-variables, rust-functions)

**Topics:** Primitive types in depth (integer widths, `usize` for indexing, casting with `as`),
`String` vs `&str` (owned vs borrowed — see rust-gotchas.md), `Vec<T>` vs arrays (`[T; N]` vs
`&[T]` slice), tuples.

**Level 0:** Distinguish `&str` (literal) from `String` (owned); convert between them (`.to_string()`,
`String::from()`, `&s[..]`).

**Level 1:** `Vec<i32>` — construction (`vec![]`, `Vec::new()`, `.collect()`), push, indexing,
`.get(i)` vs `v[i]`. Slices `&[T]`.

**Level 2:** `usize` for indexing; casting `i32` to `usize` with `as`; the `len() - 1` underflow
trap on empty Vec (consult docs/rust-gotchas.md).

**Teaching notes:** `&str` vs `String` is the most common type confusion. Bridge it from ownership:
`&str` is a borrow of string data, `String` is ownership of heap-allocated string data. A string
literal `"hello"` has type `&str` — it's a reference into the binary's read-only data segment.

---

## 6. rust-structs
(requires: rust-types, rust-ownership)

**Topics:** `struct` declaration, field access, `impl` blocks, methods (`self`, `&self`, `&mut self`),
associated functions (the `new` convention), `#[derive(Debug)]`.

**Level 0:** Define a `Point { x: f64, y: f64 }` struct. Implement a method that computes the distance
from the origin. Add `#[derive(Debug)]` and print with `{:?}`.

**Level 1:** Methods that mutate (`&mut self`). Implement a counter struct with increment and get
methods.

**Level 2:** Multiple `impl` blocks; struct update syntax (`..other`).

**Teaching notes:** The `self` / `&self` / `&mut self` distinction maps directly to
ownership/borrowing. `self` moves the struct into the method (consumes it); `&self` borrows
immutably; `&mut self` borrows mutably. Bridge this explicitly to what the user learned in
rust-ownership and rust-borrowing.

---

## 7. rust-enums
(requires: rust-structs)

**Topics:** `enum` declaration, pattern matching with `match`, `Option<T>` (`Some` / `None`),
`Result<T, E>` (`Ok` / `Err`), `if let`, exhaustiveness.

**Level 0:** Define a `Direction` enum (`North`, `South`, `East`, `West`). Write a `match` that maps
each variant to a string description. Observe the compile error from a non-exhaustive match.

**Level 1:** `Option<T>` — write a function that returns `Some(x)` or `None`; pattern match to extract
the value safely.

**Level 2:** `Result<T, E>` — return `Err` and `Ok`; propagate errors with `?`.

**Level 3:** Enums with data (`enum Message { Move { x: i32, y: i32 }, Write(String), Color(u8,u8,u8) }`);
nested enums.

**Teaching notes:** `Option` and `Result` replace null and error codes. The exhaustiveness rule is a
feature — emphasize it as safety, not a hurdle. `if let Some(x) = opt { ... }` is the concise form
of a single-arm match; teach it as sugar, not a different concept.

---

## 8. rust-traits
(requires: rust-enums, rust-functions)

**Topics:** `trait` declaration, `impl SomeTrait for Type`, common `#[derive]` macros (`Debug`,
`Clone`, `PartialEq`, `PartialOrd`), generic functions with trait bounds (`fn f<T: Display>(x: T)`),
`impl Trait` in function signatures.

**Level 0:** Define a `Describable` trait with a `describe(&self) -> String` method. Implement it for
two types. Write a generic function that accepts any `T: Describable`.

**Level 1:** `#[derive]` macros — which traits can be derived automatically vs which need manual
implementation. Common derivable traits: `Debug`, `Clone`, `PartialEq`, `Hash`.

**Level 2:** Multiple trait bounds (`T: Display + PartialOrd`); trait objects (`Box<dyn Trait>` vs
generics — conceptual intro, no lifetime depth yet).

**Teaching notes:** Traits are Rust's interfaces. The `derive` macro shortcut covers the majority of
beginner needs — teach it first before manual `impl`. A generic function `fn f<T: Trait>(x: T)` is
resolved at compile time (monomorphization); a `dyn Trait` is resolved at runtime (dynamic dispatch).
Introduce this distinction conceptually without requiring the user to write `dyn Trait` at this level.

---

## 9. rust-iterators
(requires: rust-traits, rust-types)

**Topics:** The `Iterator` trait, `.iter()` vs `.into_iter()` vs `.iter_mut()`, `.map()`, `.filter()`,
`.collect()`, `.sum()`, `.count()`, `.fold()`, `.enumerate()`, `.zip()`, iterator laziness.

**Level 0:** Use `.iter().map(|x| x * 2).collect::<Vec<_>>()` to double every element. Observe that
the chain is lazy until `.collect()` runs.

**Level 1:** `.filter()`; combining `.map()` and `.filter()`; `.collect()` into `Vec<String>` from
`&[&str]`.

**Level 2:** `.fold()` as a generalization of `.sum()`; `.enumerate()` for index-aware iteration;
`.zip()` for parallel iteration over two collections.

**Level 3:** Write a custom iterator — implement the `Iterator` trait with a `next() -> Option<Self::Item>`
method.

**Teaching notes:** Iterator laziness is the most common beginner surprise — demonstrate it explicitly.
Show that `.map(|x| x * 2)` without `.collect()` produces only a `Map<...>` type, not a `Vec`. The
three iteration methods differ by ownership: `.iter()` borrows (`&T`), `.into_iter()` moves (`T`),
`.iter_mut()` mutably borrows (`&mut T`). Consult docs/rust-gotchas.md for the iterator laziness entry.

---

## Teaching Order Summary

```
rust-variables
    └── rust-functions
            ├── rust-ownership
            │       └── rust-borrowing
            └── rust-types
                    └── rust-structs (also requires rust-ownership)
                            └── rust-enums
                                    └── rust-traits (also requires rust-functions)
                                            └── rust-iterators (also requires rust-types)
```

Earliest unblocked order: variables → functions → (ownership || types) → borrowing → structs →
enums → traits → iterators. If the user is learning both tracks simultaneously, ownership and types
can interleave freely — neither blocks the other.
