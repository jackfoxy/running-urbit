---
name: batch-thread-patterns
description: Patterns for batch operations via conn.c threads including chunking strategies, poke batches, string accumulation, and sequential bind chains. Use when performing bulk operations on a ship, processing large datasets through threads, or building multi-step thread workflows.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Batch Thread Patterns for conn.c

Patterns for performing bulk operations on Urbit ships via conn.c threads. Covers chunking, batching, string accumulation, and sequential operations.

## Core Principle: File-Based Threads

Always write threads to files and execute with `click -k -i`. Never attempt complex batch operations via inline `-kp` — shell escaping will break.

```bash
# Write thread to file
cat > /tmp/batch-op.hoon << 'HOON'
=/  m  (strand ,vase)
::  ... thread code ...
(pure:m !>(result))
HOON

# Execute
click -k -i /tmp/batch-op.hoon /path/to/pier
```

## Pattern 1: Conversion Chunks (~200 Items)

Large data conversions (e.g., point numbers to @p) can cause stack overflow if processed all at once. Chunk into groups of ~200.

### The Problem

```hoon
::  BAD: Processing 10,000 items in one turn causes stack overflow
=/  results  (turn huge-list converter)  ::  Stack overflow!
```

### The Solution: Chunked Processing

```hoon
::  /tmp/chunked-convert.hoon
=/  m  (strand ,vase)
=/  items=(list @ud)  ~[1 2 3 ...]  ::  Large input list
=/  chunk-size=@ud  200
=/  results=(list @t)  ~
|-
=/  chunk  (scag chunk-size items)
=/  rest   (slag chunk-size items)
=/  converted=(list @t)
  (turn chunk |=(i=@ud (scot %p `@p`i)))
=/  results  (weld results converted)
?~  rest
  (pure:m !>(results))
$(items rest)
```

### Python-Side Chunking

When the data originates outside the ship, chunk before sending:

```python
def chunk_list(lst, size=200):
    return [lst[i:i+size] for i in range(0, len(lst), size)]

points = [...]  # Large list
for chunk in chunk_list(points, 200):
    # Generate thread for this chunk
    hoon = generate_conversion_thread(chunk)
    write_and_execute(hoon)
```

## Pattern 2: Poke Batches (~50 Items)

Pokes are heavier than pure computations — each one is an event that modifies ship state. Batch ~50 pokes per thread to avoid thread timeouts.

### Sequential Poke Chain

```hoon
::  /tmp/batch-poke.hoon
=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
::  Poke 1
;<  ~  bind:m  (poke [our %target-app] %mark !>(data-1))
::  Poke 2
;<  ~  bind:m  (poke [our %target-app] %mark !>(data-2))
::  Poke 3
;<  ~  bind:m  (poke [our %target-app] %mark !>(data-3))
::  ... up to ~50 pokes per thread
(pure:m !>('batch complete'))
```

### Why ~50?

- Each `;<` bind is a sequential operation — the thread waits for the poke-ack
- Threads have a default timeout; too many sequential pokes can exceed it
- 50 pokes balances throughput with reliability
- If you need more, split into multiple thread executions

### Multi-Batch Orchestration (Python/bash)

```bash
#!/bin/bash
# Execute poke batches sequentially
PIER="/path/to/pier"
BATCH_DIR="/tmp/poke-batches"

for batch_file in "$BATCH_DIR"/batch-*.hoon; do
    echo "Executing: $batch_file"
    click -k -i "$batch_file" "$PIER"
    if [ $? -ne 0 ]; then
        echo "FAILED: $batch_file"
        exit 1
    fi
    sleep 1  # Brief pause between batches
done
echo "All batches complete"
```

## Pattern 3: String Accumulation (roll+weld)

Building string output from list processing. The `roll`+`weld` pattern is the standard approach.

**Note**: `roll` is a left fold — it processes items left-to-right but the accumulator argument comes second. Be aware of ordering when building strings, and note that separators add a trailing/leading space that may need trimming when parsing output externally.

### Basic roll+weld

```hoon
::  Build a comma-separated string from a list
=/  items=(list @t)  ~['alice' 'bob' 'carol']
=/  result=tape
  %+  roll  items
  |=  [item=@t acc=tape]
  ?~  acc
    (trip item)
  (weld acc (weld ", " (trip item)))
(crip result)
```

### With Formatting

```hoon
::  Build a report string with line breaks
=/  entries=(list [@t @ud])  ~[['alice' 42] ['bob' 17]]
=/  result=tape
  %+  roll  entries
  |=  [[name=@t count=@ud] acc=tape]
  =/  line  "{(trip name)}: {(scow %ud count)}"
  ?~  acc  line
  (weld acc (weld "\0a" line))  ::  \0a is newline
(crip result)
```

### Efficient Accumulation (snoc-free)

For large lists, avoid `weld` in the accumulator (O(n) per call, O(n^2) total). Instead, accumulate in reverse and flip:

```hoon
::  O(n) accumulation pattern
=/  items=(list @t)  ~['a' 'b' 'c']
=/  parts=(list tape)  ~
=/  parts
  %+  roll  items
  |=  [item=@t acc=(list tape)]
  [(trip item) acc]
=/  reversed  (flop parts)
(crip (join ", " reversed))
```

## Pattern 4: Sequential ;<  Bind Chains

The `;<` rune chains sequential asynchronous operations in threads. Each step waits for completion before the next begins.

### Basic Chain

```hoon
=/  m  (strand ,vase)
::  Step 1: Get ship identity
;<  our=@p  bind:m  get-our
::  Step 2: Get current time
;<  now=@da  bind:m  get-time
::  Step 3: Scry for data
;<  data=@  bind:m  (scry @ /gx/[app]/[path]/noun)
::  Step 4: Poke with result
;<  ~  bind:m  (poke [our %target] %mark !>(processed-data))
::  Return result
(pure:m !>('done'))
```

### Error Handling in Chains

If any step in a `;<` chain fails, the entire thread fails. For partial-failure tolerance, use `mule` around individual operations:

```hoon
=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
::  Try a poke that might fail
=/  result  (mule |.((poke [our %maybe-app] %mark !>(data))))
?-  -.result
  %&  (pure:m !>('poke succeeded'))
  %|  (pure:m !>('poke failed, continuing'))
==
```

### Multi-Ship Operations

```hoon
::  /tmp/multi-ship-op.hoon
=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
::  Poke ship A
;<  ~  bind:m  (poke [~ship-a %app] %mark !>(data))
::  Poke ship B
;<  ~  bind:m  (poke [~ship-b %app] %mark !>(data))
::  Poke ship C
;<  ~  bind:m  (poke [~ship-c %app] %mark !>(data))
(pure:m !>('all ships poked'))
```

## Recommended Batch Sizes

| Operation | Recommended Chunk Size | Reason |
|-----------|----------------------|--------|
| Pure computation (turn, roll) | ~200 items | Stack depth limit |
| Pokes (sequential ;< chain) | ~50 items | Thread timeout |
| Scries (sequential) | ~100 items | Lower overhead than pokes |
| String building (weld) | ~500 items | Memory, depends on string size |

## Complete Example: Batch Planet Lookup

```hoon
::  /tmp/batch-planet-lookup.hoon
::  Look up spawned planets for a star and format as report
=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
::  Get list of planets (example: reading from agent state)
;<  planets=(list @p)  bind:m  (scry (list @p) /gx/pals/mutuals/noun)
::  Format as report
=/  report=tape
  %+  roll  planets
  |=  [p=@p acc=tape]
  =/  line  (scow %p p)
  ?~  acc  (trip line)
  (weld acc (weld "\0a" (trip line)))
(pure:m !>((crip report)))
```

```bash
click -k -i /tmp/batch-planet-lookup.hoon /path/to/pier
```

## Parsing click Output

When click returns a cord result from a thread, the output format is:

```
[0 %avow 0 %noun 'your-result-string']
```

To extract just the result string in bash:

```bash
click -k -i /tmp/thread.hoon /path/to/pier | sed "s/.*%noun '//;s/'.*//"
```

This strips the `[0 %avow 0 %noun '` prefix and trailing `']`.

## Resources

- [Thread Guide](https://docs.urbit.org/userspace/threads/overview)
- [Khan Vane (Thread Execution)](https://docs.urbit.org/system/kernel/khan)
- [Strand Library](https://docs.urbit.org/userspace/threads/reference/api)
