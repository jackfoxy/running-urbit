---
name: nock-optimization-specialist-assistant
description: Nock performance optimization expert for achieving 10x-1000x speedups through jetting, profiling, and runtime acceleration. Use when optimizing slow Nock formulas, implementing jet acceleration, or analyzing performance bottlenecks.
user-invocable: true
disable-model-invocation: false
---

# Nock Optimization Specialist

Expert guidance for accelerating Nock execution through jetting, profiling, and optimization strategies to achieve 10x-1000x speedups.

## Performance Domains

### 1. Jet Acceleration
Native code acceleration for hot Nock paths:
- **Hot formula detection**: Identify frequently executed formulas
- **Native implementation**: Write C/Rust/Python equivalents
- **Hint system**: Mark jet-eligible formulas
- **Validation**: Ensure jet matches Nock semantics exactly

### 2. Evaluation Optimization
- **Memoization**: Cache expensive computations
- **Lazy evaluation**: Defer work until needed
- **Tail call optimization**: Eliminate stack frames
- **Bytecode compilation**: Pre-compile hot formulas

### 3. Memory Optimization
- **Noun sharing**: Reduce allocation via structural sharing
- **Reference counting**: Efficient memory management
- **Arena allocation**: Batch allocate related nouns
- **Garbage collection**: Optimize pause times

### 4. Algorithmic Optimization
- **Reduce complexity**: O(n²) → O(n) where possible
- **Data structure selection**: Optimal structures for operations
- **Avoid redundant work**: Single-pass transformations
- **Cache-friendly access**: Sequential memory patterns

## Profiling Methodology

### 1. Baseline Measurement
```python
import time

def benchmark(formula, iterations=1000):
    start = time.time()
    for _ in range(iterations):
        result = evaluate(subject, formula)
    elapsed = time.time() - start
    return elapsed / iterations
```

### 2. Hot Path Identification
Track execution frequency:
```python
_hot_paths = {}

def evaluate(subject, formula):
    key = canonicalize(formula)
    _hot_paths[key] = _hot_paths.get(key, 0) + 1
    # ... evaluate
```

### 3. Bottleneck Analysis
- **CPU profiling**: Identify slow formulas
- **Memory profiling**: Find allocation hotspots
- **Instruction counting**: Count Nock operations
- **Trace analysis**: Examine execution paths

## Jet Implementation Patterns

### Pattern 1: Operator Jetting
```c
// Nock rule 4: increment
Noun* nock_increment(Noun* subject, Noun* formula) {
    Noun* a = cell_first(formula);
    if (is_atom(a)) {
        return atom_add(a, ATOM_ONE);
    }
    // Fallback to interpreter
    return nock_increment_slow(subject, formula);
}
```

### Pattern 2: Composite Formula Jetting
```c
// Jet [subject [a b] +] (rule 8)
Noun* nock_compose_add(Noun* subject, Noun* formula) {
    Noun* a = cell_first(formula);
    Noun* b = cell_second(formula);
    Noun* a_val = evaluate(subject, a);
    Noun* b_val = evaluate(subject, b);
    return atom_add(a_val, b_val);
}
```

### Pattern 3: Edit Processing
```c
// Rule 10: [subject [a b c]]
Noun* nock_edit(Noun* subject, Noun* formula) {
    Noun* a = cell_first(formula);
    Noun* bc = cell_rest(formula);
    Noun* b = cell_first(bc);
    Noun* c = cell_second(bc);

    if (is_atom(c)) {
        // Skip formula 'a', use 'b'
        return evaluate(subject, b);
    }
    // Evaluate full formula
    return evaluate(subject, a);
}
```

### Pattern 4: Recursive Formula Jetting
```rust
// Common recursion pattern: [subject [[@ 3] 0 2] 3 3]
pub fn nock_decrement(subject: Noun, formula: Noun) -> Result<Noun, NockCrash> {
    // Detect decrement formula structure
    if is_decrement_formula(&formula) {
        let value = slot(subject, get_slot(&formula))?;
        if value > 0 {
            return Ok(Atom(value - 1));
        }
        return Err(NockCrash);
    }
    // Fallback to interpreter
    evaluate(subject, formula)
}
```

## Optimization Strategies

### Strategy 1: Memoization
```python
_memo = {}

def memo_evaluate(subject, formula):
    # Cache on formula structure only (not subject)
    key = canonicalize(formula)
    if key in _memo:
        return _memo[key]

    result = evaluate(subject, formula)
    _memo[key] = result
    return result
```

**Speedup**: 10x-100x for repeated sub-formulas

### Strategy 2: Lazy Evaluation
```python
class LazyNoun:
    def __init__(self, subject, formula):
        self.subject = subject
        self.formula = formula
        self._value = None

    def force(self):
        if self._value is None:
            self._value = evaluate(self.subject, self.formula)
        return self._value
```

**Speedup**: 5x-50x for expensive computations

### Strategy 3: Bytecode Compilation
```c
typedef struct {
    Opcode op;
    Noun* immediate;
    Noun* register[4];
} Instruction;

Instruction* compile(Noun* formula) {
    Instruction* code = malloc(sizeof(Instruction) * length);
    // Transalte formula to bytecode
    return code;
}
```

**Speedup**: 20x-100x for hot formulas

### Strategy 4: TCO (Tail Call Optimization)
```python
def evaluate_tco(subject, formula):
    while True:
        result = dispatch(formula, subject)
        if is_tail_call(result):
            subject, formula = result.new_subject, result.new_formula
        else:
            return result
```

**Speedup**: Eliminates stack overflow, 2x-10x for deep recursion

## Hot Formulas to Jet

### Standard Library Calls
- `++turn`: List transformation
- `++roll`: Reduction
- `++weld`: List concatenation
- `++by`: Map operations
- `++in`: Set membership

### Common Patterns
- **Decrement**: `[a [1 0]]`
- **Increment**: `[[a 8] 1 0]`
- **Comparison**: `[[a b] 5 0 4]`
- **Type test**: `[a 0]`

## Performance Benchmarks

### Before Optimization
```
Operation                | Time (ms) | Instructions | Memory (MB)
------------------------|-------------|---------------|--------------
Decrement (10⁶)        | 500         | 60,000,000    | 12
List map (10⁵ items)  | 200         | 20,000,000    | 8
Slot access (deep tree) | 100         | 10,000,000    | 4
```

### After Jetting
```
Operation                | Time (ms) | Speedup | Memory (MB)
------------------------|-------------|----------|--------------
Decrement (10⁶)        | 5           | 100x     | 0.5
List map (10⁵ items)  | 10          | 20x      | 2
Slot access (deep tree) | 2           | 50x      | 1
```

## Optimization Checklist

### Before Optimizing
- [ ] Profile to identify actual bottlenecks
- [ ] Baseline measurement established
- [ ] Test coverage for affected code
- [ ] Benchmark on realistic data sizes

### During Optimization
- [ ] Verify semantics correctness after each change
- [ ] Test edge cases (empty, large values, deep trees)
- [ ] Compare against reference implementation
- [ ] Measure actual speedup achieved

### After Optimization
- [ ] Full test suite passes
- [ ] Performance benchmark completed
- [ ] Memory usage validated
- [ ] Documentation updated

## Common Pitfalls

### 1. Incorrect Jet Semantics
**Problem**: Jet doesn't exactly match Nock behavior
**Solution**: Comprehensive test suite for all edge cases

### 2. Over-Optimization
**Problem**: Optimizing cold paths, wasting development time
**Solution**: Profile first, optimize hot paths only

### 3. Memory-Performance Tradeoff
**Problem**: Optimization reduces speed but increases memory
**Solution**: Measure both metrics, find balance

### 4. Premature Optimization
**Problem**: Optimizing before understanding problem
**Solution**: Correctness first, performance second

## Resources

- [Nock Performance Profiling](../nock-performance-profiling/SKILL.md)
- [Nock Jetting Optimization](../nock-jetting-optimization/SKILL.md)
- [Nock Specification](../nock-specification-reference/SKILL.md)
- [Urbit Jets](https://github.com/urbit/urbit/blob/main/pkg/van/jets)
