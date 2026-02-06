---
name: nock-jetting-optimization
description: Jet acceleration system for replacing Nock formulas with native code implementations. Covers hint processing (rules 10-11), cold/hot/warm state management, jet registration, validation strategies, and common jet patterns. Use when implementing performance-critical jets or building production Nock runtimes.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Nock Jetting Optimization

Complete guide to jet acceleration: replacing slow Nock formulas with fast native code.

## Jetting Fundamentals

### What is a Jet?
```
Jet = native code implementation of Nock formula

Formula (slow):  [8 [1 0] 8 [1 6 [5 [0 7] 4 0 6] [0 6] 9 2 [0 2] [4 0 6] 0 7] 9 2 0 1]
Jet (fast):      fn decrement(n: u64) -> u64 { n - 1 }

Speedup: 1000-10000x
```

### Why Jets?
- **Performance**: Native code is 100-1000x faster
- **Correctness**: Must compute identical results
- **Transparency**: Nock semantics unchanged

## Hint System (Rule 11)

### Rule 11: Hint (Static and Dynamic)
```
*[a 11 b c]      → *[a c]     # Static hint (b is atom tag)
*[a 11 [b c] d]  → *[a d]     # Dynamic hint (evaluates c as clue)
```

**%fast Hint** (jet registration, dynamic):
```
[11 [%fast [1 %add]] body]

Tells runtime: "this core implements %add, use native jet"
```

### Rule 10: Edit (NOT hints)
```
*[a 10 [b c] d] → #[b *[a c] *[a d]]
```
Rule 10 is EDIT (tree mutation), not hints. It evaluates target `d`, evaluates value `c`, then replaces the subtree at axis `b` in the target with the value.

### Actively Used Hint Tags
- **%fast**: Jet registration (tells runtime a core has a native implementation)
- **%memo**: Memoization (cache computation results)
- **%spot**: Source location (file/line for stack traces)
- **%mean**: Error context (descriptive crash messages)
- **%slog**: Debug print (emit debug output during evaluation)

## Cold/Hot/Warm States

In Urbit's jet system (as implemented in Vere), cold/warm/hot refer to different layers of the jet state, not validation frequency:

### Cold State (Persistent Jet Registrations)
The cold state is the **persistent** record of jet registrations that survives across snapshots (i.e., stored on disk). When a core is registered with a %fast hint, the association between the core's identity and its jet is recorded in the cold state. This persists across restarts.

### Warm State (Transient Computed State)
The warm state is **transient** and computed from the cold state at startup. It contains the lookup tables and caches needed to quickly match a core to its jet at runtime. Rebuilt whenever the cold state changes or the runtime restarts.

### Hot State (Static Jet Dashboard)
The hot state is the **static** jet dashboard compiled into the runtime binary. It contains the actual native C/Rust function pointers for each jet. This does not change at runtime -- it is fixed at compile time.

### How They Work Together
```
1. Hot state: "Here are all the native jet functions we have"
2. Cold state: "Here are all the cores registered to use jets" (persisted)
3. Warm state: "Here is the fast-lookup table matching cores to jets" (computed)

At runtime:
  - %fast hint fires → registration added to cold state
  - Cold state change → warm state recomputed
  - Core encountered → warm state lookup → hot state function pointer → native execution
```

## Jet Registration

### Registry Pattern
```rust
use std::collections::HashMap;

type Jet = fn(&Noun) -> Result<Noun, NockError>;

struct JetRegistry {
    jets: HashMap<Noun, Jet>,       // hot: available native implementations
    registrations: HashMap<Noun, Noun>, // cold: persistent core-to-jet mappings
}

impl JetRegistry {
    fn register(&mut self, formula: Noun, jet: Jet) {
        self.jets.insert(formula.clone(), jet);
    }

    fn accelerate(&self, subject: &Noun, formula: &Noun) -> Option<Noun> {
        self.jets.get(formula).map(|jet| jet(subject).ok()).flatten()
    }
}
```

### Common Jets

**Increment** (trivial speedup):
```rust
fn jet_increment(subject: &Noun) -> Result<Noun, NockError> {
    match subject {
        Noun::Atom(n) => Ok(Noun::Atom(n + 1)),
        Noun::Cell(_, _) => Err(NockError::IncrementCell),
    }
}
```

**Decrement** (massive speedup):
```rust
fn jet_decrement(subject: &Noun) -> Result<Noun, NockError> {
    match subject {
        Noun::Atom(0) => Err(NockError::DecrementZero),
        Noun::Atom(n) => Ok(Noun::Atom(n - 1)),
        Noun::Cell(_, _) => Err(NockError::DecrementCell),
    }
}

// Nock decrement: O(n) counting loop
// Jetted: O(1) subtraction
// Speedup: 1000-10000x
```

**Addition**:
```rust
fn jet_add(subject: &Noun) -> Result<Noun, NockError> {
    let args = slot(subject, 6);  // [a b]
    let a = slot(args, 2).as_atom()?;
    let b = slot(args, 3).as_atom()?;
    Ok(Noun::Atom(a + b))
}

// Nock: O(a) increments
// Jetted: O(1) addition
// Speedup: 100-1000x
```

## Validation Strategies

Jet validation is a separate concern from the cold/warm/hot state model. These are common strategies:

### Always Validate (Development/Debug)
```rust
fn validate_always(formula: &Noun, subject: &Noun) -> Noun {
    let nock_result = nock(subject.clone(), formula.clone());
    let jet_result = jet(subject);

    assert_eq!(nock_result, jet_result, "Jet mismatch!");
    jet_result
}
```

### Statistical Sampling (Testing)
```rust
fn validate_sampled(formula: &Noun, subject: &Noun, rate: f64) -> Noun {
    if rand::random::<f64>() < rate {
        let nock_result = nock(subject.clone(), formula.clone());
        let jet_result = jet(subject);
        assert_eq!(nock_result, jet_result);
    }

    jet(subject)
}
```

### Trust (Production)
```rust
fn validate_never(formula: &Noun, subject: &Noun) -> Noun {
    jet(subject)  // Full trust in production
}
```

## Performance Impact

### Benchmark Results (Illustrative/Approximate)
Note: These numbers are approximate and illustrative of relative magnitudes. Actual performance depends on input size, implementation, and hardware.
```
Operation    | Nock Time   | Jet Time  | Approx Speedup
-------------|-------------|-----------|----------------
Increment    | ~100 ns     | ~10 ns    | ~10x
Decrement    | ~10 ms      | ~10 ns    | ~1,000,000x
Add          | ~1 ms       | ~10 ns    | ~100,000x
Multiply     | ~100 ms     | ~10 ns    | ~10,000,000x
SHA-256      | very slow   | ~1 ms     | orders of magnitude
```

### Jet Profitability
High-value jets (biggest speedups):
1. **Cryptography**: SHA-256, ed25519, AES
2. **Arithmetic**: Multiply, divide, modulo
3. **List operations**: Reverse, concatenate, map/filter
4. **Parsing**: Large text processing

## Summary

Jets accelerate Nock by replacing formulas with native code. Hint system: Rule 11 provides hints (%fast registers jets, %memo enables memoization, %spot/%mean/%slog for debugging). Rule 10 is EDIT (tree mutation), not hints. Jet states: cold = persistent jet registrations across snapshots, warm = transient computed lookup tables, hot = static jet dashboard compiled into binary. High-value jets: decrement (O(n) to O(1)), arithmetic, cryptography. Validation is a separate concern from the cold/warm/hot state model.
