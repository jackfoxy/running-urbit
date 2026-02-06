---
name: nock-specification-reference
description: Complete formal Nock specification including all reduction rules (0-12), pseudo-functions (slot, type test, increment, equality), crash conditions, and canonical semantics. Authoritative reference for implementation validation. Use when verifying interpreter correctness, resolving edge cases, or understanding formal behavior.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Nock Specification Reference

Complete authoritative specification for Nock 4K ('Kelvin 4' specification).

## Official Specification

**Source**: https://docs.urbit.org/nock/specification

**Version**: Nock 4K (final, frozen forever at 0k, counting down)

## Complete Reduction Rules

### Rule 0: Slot
```
*[a 0 b]  →  /[b a]
```
Extract subtree at axis `b` from subject `a`

### Rule 1: Constant
```
*[a 1 b]  →  b
```
Return constant `b`, ignoring subject

### Rule 2: Evaluate
```
*[a 2 b c]  →  *[*[a b] *[a c]]
```
Evaluate `b` and `c`, then nock first with second

### Rule 3: Cell Test
```
*[a 3 b]  →  ?*[a b]
```
Test if result is cell (0) or atom (1)

### Rule 4: Increment
```
*[a 4 b]  →  +*[a b]
```
Increment result (crash if cell)

### Rule 5: Equality
```
*[a 5 b c]  →  =*[a b] *[a c]
```
Deep equality test (0=equal, 1=not equal)

### Rule 6: If-Then-Else
```
*[a 6 b c d]  →  *[a *[[c d] [0 *[[2 3] [0 *[a 4 4 b]]]]]]
```
**Simplified**: If `*[a b]` = 0 then `*[a c]` else `*[a d]`

Note: The formal expansion above reduces to selecting `c` or `d` based on whether `*[a b]` is 0 or 1. In practice, implementations use the simplified form directly.

### Rule 7: Composition
```
*[a 7 b c]  →  *[*[a b] c]
```
Evaluate `b`, use as new subject for `c`

### Rule 8: Push
```
*[a 8 b c]  →  *[[*[a b] a] c]
```
Extend subject with evaluated `b`

### Rule 9: Call
```
*[a 9 b c]  →  *[*[a c] 2 [0 1] 0 b]
```
Evaluate `c` to produce a core, extract formula at axis `b` from the core (not just the battery), execute with core as subject

### Rule 10: Edit (Tree Mutation)
```
*[a 10 [b c] d]  →  #[b *[a c] *[a d]]
```
Evaluate target `d`, evaluate value `c`, edit target at axis `b` with value. Only one form (with `[axis value]` pair).

### Rule 11: Hint (Static and Dynamic)
```
*[a 11 b c]      →  *[a c]     # Static hint (b is atom)
*[a 11 [b c] d]  →  *[a d]     # Dynamic hint (evaluates c as clue)
```
Provides hints to runtime without changing result. Actively used for %fast (jet registration), %memo (memoization), %spot (source location), %mean (error context), %slog (debug print).

### Rule 12: Scry (Namespace Lookup)
```
*[a 12 b c]  →  scry(*[a b], *[a c])
```
Evaluate `b` (ref) and `c` (path), perform namespace lookup via scry gate. NOT a slot operation. Used for referentially transparent namespace reads (.^ in Hoon).

## Pseudo-Functions

### / (Slot - Tree Addressing)
```
/[1 a]          →  a
/[2 a b]        →  a
/[3 a b]        →  b
/[(2 * n) a]    →  /[n /[2 a]]
/[(2 * n + 1) a]→  /[n /[3 a]]
```

**Crashes**:
- `/[0 a]` always crashes (axis 0 forbidden)
- `/[n atom]` crashes if `n > 1` (cannot slot into atom)

### ? (Type Test)
```
?[cell]  →  0  # Yes, is a cell
?[atom]  →  1  # No, is not a cell
```
Tests "is this a cell?" -- 0 means yes (is cell), 1 means no (is atom).

### + (Increment)
```
+[atom]  →  atom + 1
+[cell]  →  CRASH
```

### = (Equality)
```
=[a a]  →  0  # Equal
=[a b]  →  1  # Not equal (if a ≠ b)
```
Deep structural equality

## Crash Conditions (Complete List)

1. **Axis 0**: `/[0 a]` always crashes
2. **Slot in atom**: `/[n atom]` where `n > 1`
3. **Increment cell**: `+[cell]`
4. **Unknown operator**: Formula head not in 0-12
5. **Malformed formula**: Formula is atom (must be cell)

## Type System

### Nouns
```
noun := atom | cell
atom := 0 | 1 | 2 | ...  (natural numbers)
cell := [noun noun]      (ordered pair)
```

**No other types exist**: Everything is a noun

### Loobean Logic
```
0 = yes (true)
1 = no  (false)

Why backwards? Historical Lisp convention
```

## Formal Properties

### Determinism
```
∀ subject formula:
  *[subject formula] always produces same result
```

### Purity
```
No side effects
No I/O
No mutation
Purely functional evaluation
```

### Turing Completeness
```
Nock can compute any computable function
Proven via encoding of λ-calculus
```

### Termination
```
NOT guaranteed: Nock can loop forever
Example: [8 [1 0] 9 2 0 1]  # Infinite loop
```

## Edge Cases

### Empty Structures
```
[]  →  INVALID (not a noun)
Nouns must be atom or non-empty cell
```

### Large Atoms
```
Atoms can be arbitrarily large (no limit)
340282366920938463463374607431768211455  # Valid atom
```

### Deep Trees
```
Nesting depth unlimited:
[[[[[...]]]]]  # Valid (subject to memory)
```

### Axis Calculation Edge Cases
```
/[1 anything]      →  anything  # Always identity
/[2 atom]          →  CRASH     # Cannot take head of atom
/[999999 [a b]]    →  CRASH     # Eventually hits atom
```

## Implementation Requirements

### Minimal Requirements
1. Represent atoms (natural numbers, arbitrary precision)
2. Represent cells (ordered pairs)
3. Implement 13 reduction rules (pattern matching)
4. Handle crashes (axis 0, slot in atom, increment cell)
5. Deep equality comparison

### Recommended Features
1. Memoization (cache slot lookups)
2. Tail call optimization (avoid stack overflow)
3. Jetting (accelerate with native code)
4. Error reporting (meaningful crash messages)
5. Debugging support (trace execution)

## Validation Against Spec

### Test Suite (Minimal)
```python
tests = [
    # Rule 0: Slot
    ([[1, 2], [0, 2]], 1),      # Head
    ([[1, 2], [0, 3]], 2),      # Tail
    ([42, [0, 1]], 42),         # Identity

    # Rule 1: Constant
    ([_, [1, 42]], 42),

    # Rule 4: Increment
    ([_, [4, [1, 41]]], 42),

    # Rule 5: Equality
    ([_, [5, [1, 10], [1, 10]]], 0),  # Equal
    ([_, [5, [1, 10], [1, 20]]], 1),  # Not equal

    # Crashes
    ([_, [0, 0]], CRASH),       # Axis 0
    ([42, [0, 2]], CRASH),      # Slot in atom
    ([_, [4, [1, [1, 2]]]], CRASH),  # Increment cell
]

for (subject, formula), expected in tests:
    result = nock(subject, formula)
    assert result == expected
```

### Compliance Checklist
- [ ] All 13 rules implemented correctly
- [ ] Slot addressing with binary navigation
- [ ] Deep equality for nouns
- [ ] Arbitrary-precision atoms
- [ ] All crash conditions handled
- [ ] Deterministic evaluation
- [ ] No side effects (pure functional)

## Official Resources

- **Specification**: https://docs.urbit.org/nock/specification
- **Definition**: https://docs.urbit.org/nock/definition
- **Explanation**: https://docs.urbit.org/nock/what-is-nock
- **Examples**: https://docs.urbit.org/nock/decrement
- **Implementations**: https://docs.urbit.org/nock/implementations

## Summary

Nock 4K specification: 13 reduction rules (0-12), 4 pseudo-functions (/, ?, +, =), 2 data types (atom, cell). Deterministic, pure functional, Turing complete, non-terminating. Crashes: axis 0, slot in atom (n>1), increment cell, unknown operator, atom formula. Implementation requirements: arbitrary precision atoms, cell pairs, pattern matching, crash handling, deep equality. Validation: test all rules, verify crashes, check determinism. Frozen forever (Nock 4K final version).
