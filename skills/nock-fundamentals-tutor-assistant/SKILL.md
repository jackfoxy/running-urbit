---
name: nock-fundamentals-tutor-assistant
description: Nock fundamentals educator for teaching atoms, cells, nouns, tree addressing, cores, and reduction model. Use when learning Nock from scratch, understanding core concepts before building interpreters, or teaching Nock to implementers.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Nock Fundamentals Tutor

Expert educator for teaching Nock assembly language fundamentals to implementers and engineers planning to build Nock interpreters.

## Learning Philosophy

### For Implementers, Not Just Learners
Focus on:
- **Practical Understanding**: How concepts translate to code
- **Implementation Patterns**: Common approaches across languages
- **Edge Cases**: Boundary conditions implementers must handle
- **Performance Implications**: Why design choices matter

### Progressive Disclosure
Build from simple to complex:
1. **Nouns** (atoms, cells)
2. **Tree Addressing** (slot/axis navigation)
3. **Operators** (?, +, =, /, #, *)
4. **Reduction Rules** (0-12)
5. **Cores** (battery/payload/arm patterns)
6. **Advanced Patterns** (hints, jetting, compilation)

## Core Concepts

### 1. Nouns (Data Model)

#### Atoms
Natural numbers (unsigned integers):
```
0    ::  Zero
1    ::  One
42   ::  Forty-two
100  ::  One hundred
```
**Implementation**: BigInt, GMP, or native integer types

#### Cells
Ordered pairs (cons cells):
```
[1 2]           ::  Cell with atom 1, atom 2
[[1 2] [3 4]]   ::  Nested cells
[1 [2 [3 4]]]   ::  Right-branching cell
```
**Implementation**: Pair struct, tuple, or custom class

#### Noun Type
```
Noun = Atom(Number) | Cell(Noun, Noun)
```

### 2. Tree Addressing (Rule 0)

#### Axis Notation
Binary tree position as axis number:
```
1    ::  [subject slot] / = head of subject
2    ::  [subject slot] / = tail of subject
3    ::  [[subject slot] ...] / = third element
...
6    ::  [[subject slot] [tail]] / = slot of tail
7    ::  [[subject [slot]] ...] / = head of slot
```

#### Slot Calculation Algorithm
```python
def slot(subject, axis):
    """Navigate to position in subject tree."""
    result = subject
    current = axis
    while current > 0:
        if current % 2 == 0:  # Even → go right
            if is_cell(result):
                result = cell_tail(result)
            current = current // 2
        else:  # Odd → go left
            if is_cell(result):
                result = cell_head(result)
            current = (current - 1) // 2
    return result
```

### 3. Core Operators

#### Rule 0: Slot (`/`)
```
[subject axis] / = value_at_position
```
Tree addressing, not array indexing.

#### Rule 1: Constant (`*`)
```
[subject] * = subject
```
Identity operation, returns subject unchanged.

#### Rule 2: Evaluate (`+`)
```
[subject [formula axis]] + = [subject formula] / axis
```
Evaluate formula against subject, then substitute axis position with result.

#### Rule 3: Cell Test (`?`)
```
[subject noun] ? = 0 if noun is cell, 1 if noun is atom
```
Type discrimination for atoms vs cells.

#### Rule 4: Increment (`+`)
```
[subject noun] + = noun + 1
```
Natural number addition.

#### Rule 5: Equality (`=`)
```
[subject a b] = = 0 if a = b, 1 if a ≠ b
```
Structural equality check.

#### Rule 6-9: Composition
Combinations of rules 0-5:
```
Rule 6:  [[subject a] b] / = [[subject a] / b]
Rule 7:  [subject a b c] =  = [a b c]
Rule 8:  [subject a b] +  = a + b
Rule 9:  [subject a b] +  = a + b
```

### 4. Advanced Operators

#### Rule 10: Edit
```
[subject [axis formula target]] = edit(evaluate(subject, formula), axis, evaluate(subject, target))
```
Tree editing; replaces part of the evaluated target at the given axis.

#### Rule 11: Hint
```
[subject [hint formula]] = evaluate(subject, formula)
```
Optimization hint; evaluates formula and may use hint to guide the runtime.

#### Rule 12: Scry
```
[subject [context axis]] ^ = memory[context][axis]
```
Pure referentially-transparent read.

## Hands-On Exercises

### Exercise 1: Implement Slot
```python
def nock_slot(subject, formula):
    """Implement rule 0: [subject axis] /"""
    axis, rest = formula
    return navigate_tree(subject, axis)
```

### Exercise 2: Implement Increment
```python
def nock_increment(subject, formula):
    """Implement rule 4: [subject noun] +"""
    noun, rest = formula
    return noun + 1
```

### Exercise 3: Implement Equality
```python
def nock_equality(subject, formula):
    """Implement rule 5: [subject a b] ="""
    a, b, rest = formula
    return 0 if structurally_equal(a, b) else 1
```

### Exercise 4: Implement Decrement
**Challenge**: Use only rules 0-5 to implement decrement:
```hoon
::  This is complex! Can you figure it out?
[subject formula] =  [complex formula using rules 0-5]
```

### Exercise 5: Build Full Evaluator
```python
def evaluate(subject, formula):
    """Complete Nock evaluator with all rules."""
    if is_atom(formula):
        return formula

    op, rest = formula

    if op == 0:  return slot(subject, rest)
    if op == 1:  return rest
    if op == 2:  return evaluate(subject, evaluate(subject, rest))
    if op == 3:  return 0 if is_cell(rest) else 1
    if op == 4:  return rest + 1
    if op == 5:  return 0 if subject == rest else 1
    # ... implement rules 6-12
```

## Visualizing Nock

### Tree Structure
```
[1 [2 [3 4]]]

         / \
        1   / \
            2   / \
                3   4
```

### Slot Navigation
```
[ [1 [2 3]] 4 ] 7
   ↓ ↓ ↓ ↓ ↓ ↓ ↓
   7 1 2 3 4 [2 3]
```

### Reduction Steps
```
nock([42 0] 8 [1 0] 8 [1 6 [5 [0 7]] 4 0 6] [0 6] 9 2 [0 2] [4 0 6] 0 7] 9 2 0 1])

Step 1: [42 8] / = 1
Step 2: [1 0] + = 42
Step 3: [42 0] + = 42
... (many more steps)
Final: 41
```

## Common Gotchas

### 1. Axis vs Index
```
1  ::  Axis 1 = head of cell
0  ::  Index 0 = array index (doesn't exist in Nock)
```

### 2. Subject Updates
Many operations return `[new_subject new_formula]`, not just values.

### 3. Formula Evaluation
Rule 2 (`+`) evaluates formula BEFORE using result:
```
[subject [[a b] c] +]  =  [subject a] c]
                             ↑ Evaluate a first
```

### 4. Atom vs Cell Discrimination
Rule 3 (`?`) checks STRUCTURE, not value:
```
[subject [[1 2] [3 4]]] ?  =  1  (is cell)
[subject [[1 2] [3 4]]] ?  =  0  (first element is cell)
```

## Teaching Techniques

### 1. Step-by-Step Execution
Break down complex formulas into individual operations with intermediate results.

### 2. Visual Diagrams
Use ASCII art for tree structures, slot navigation, reduction steps.

### 3. Implementation First
Have students build actual code, not just theory.

### 4. Test-Driven Learning
Provide expected results, let students verify their implementations.

### 5. Progressive Complexity
Start with simple rules (0-5), add complexity (6-12) gradually.

## Learning Path

### Beginner
- Understand nouns (atoms and cells)
- Learn tree addressing (rule 0)
- Implement basic operators (rules 1-5)

### Intermediate
- Master formula evaluation (rule 2)
- Understand composition (rules 6-9)
- Build simple evaluator

### Advanced
- Implement edit (rule 10)
- Handle hints (rule 11)
- Add scry (rule 12)
- Optimize with memoization

### Expert
- Implement TCO
- Add jet acceleration
- Build bytecode compiler
- Metacircular evaluation

## Resources

- [Nock 4K Specification](https://github.com/urbit/urbit/blob/main/pkg/arvo/sys/zuse.hoon)
- [nock-essentials](../nock-essentials/SKILL.md)
- [nock-operators](../nock-operators/SKILL.md)
- [nock-instructions](../nock-instructions/SKILL.md)
- [nock-tree-addressing](../nock-tree-addressing/SKILL.md)
