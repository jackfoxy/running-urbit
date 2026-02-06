---
name: roller-azimuth
description: Urbit L2 roller API and Azimuth point lookups. Use when querying Azimuth PKI state, looking up spawned planets, converting point numbers to @p, or interacting with the L2 roller JSON-RPC endpoint.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Roller API & Azimuth Point Lookups

Reference for querying Urbit's Azimuth PKI via the L2 roller API and on-chain contracts.

## L2 Roller JSON-RPC API

The roller provides a JSON-RPC interface for querying L2 (Layer 2) Azimuth state. L2 is where most planet operations happen (spawning, transfers, key changes).

**Endpoint**: There is a publicly available endpoint at `https://roller.urbit.org/v1/roller` which is used for Bridge.urbit.org

### Common Methods

#### Get Spawned Planets for a Star

```bash
curl -s -X POST https://roller.urbit.org/v1/roller \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSpawned","params":{"ship":"~sampel"}}' \
  | jq .
```

**Response**: Array of spawned planet point numbers as raw integers (not dot-formatted, not `@p`). The full list is returned in a single response with no pagination — a star can return thousands of results (e.g., 3,000+) in one call.

**Important**: The raw integer point numbers from the API need dot-formatting before use in Hoon literals (e.g., API returns `123456`, Hoon needs `123.456`).

#### Get Point Info

```bash
curl -s -X POST https://roller.urbit.org/v1/roller \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"getPoint","params":{"ship":"~sampel-palnet"}}' \
  | jq .
```

#### Get Pending Transactions

```bash
curl -s -X POST https://roller.urbit.org/v1/roller \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"getPendingByShip","params":{"ship":"~sampel-palnet"}}' \
  | jq .
```

### Available Methods

| Method | Params | Description |
|--------|--------|-------------|
| `getPoint` | `{ship}` | Full point info (owner, keys, sponsor) |
| `getSpawned` | `{ship}` | List spawned children (planets from star) |
| `getPendingByShip` | `{ship}` | Pending L2 transactions for a ship |
| `getRollerConfig` | none | Roller configuration and batch timing |
| `getAllPending` | none | All pending L2 transactions |
| `getShips` | `{address}` | Ships owned by an Ethereum address |

## Critical Gotcha: L1 vs L2 Spawned Planets

**The L1 Azimuth contract's `getSpawned()` returns empty for L2-spawned planets.** Most planets spawned after ~2022 are L2. If you query the Ethereum contract directly and get an empty result, the planets likely exist on L2. Recommended to check if an ownership or spawn proxy is held by 0x1111...1111 as that is the 'L2 Dominion' address indicating point existence on L2.

**Always use the roller API** (`getSpawned`) instead of the L1 contract for a complete list of spawned planets. The roller aggregates both L1 and L2 state.

```bash
# CORRECT: Use roller API (includes L2)
curl -s -X POST https://roller.urbit.org/v1/roller \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSpawned","params":{"ship":"~sampel"}}' \
  | jq '.result'

# WRONG: L1 contract query (misses L2 planets)
# cast(IAzimuth, azimuth_address).getSpawned(star_point)  # Returns empty for L2!
```

## Point Number to @p Conversion

Azimuth point numbers are integers. Converting to `@p` (ship names) is not a simple encoding — it uses a Feistel cipher for obfuscation.

### Batch Conversion via Thread

For converting lists of point numbers, use a conn.c thread (not individual dojo calls):

```hoon
::  /tmp/points-to-patp.hoon
::  Convert a list of point numbers to @p names
=/  m  (strand ,vase)
=/  points=(list @ud)  ~[123.456 789.012 345.678]
=/  names=(list @t)
  %+  turn  points
  |=  pt=@ud
  (scot %p `@p`pt)
(pure:m !>(names))
```

```bash
click -k -i /tmp/points-to-patp.hoon /path/to/pier
```

### Single Conversion in Dojo

```
::  Point number to @p
`@p`123.456

::  @p to point number
`@ud`~sampel-palnet
```

### Conversion in Python (without a ship)

The `@p` encoding uses a Feistel cipher. Use the `urbit-ob` library:

```bash
pip install urbit-ob
```

```python
import urbit_ob

# Point number to @p
name = urbit_ob.patp(123456)  # Returns '~sampel-palnet' (example)

# @p to point number
point = urbit_ob.patp_to_num('~sampel-palnet')
```

## Azimuth Hierarchy

```
Galaxy (8-bit, 0-255)        →  ~zod, ~nec, ~bud, ...
  └─ Star (16-bit)           →  ~marzod, ~binzod, ...
       └─ Planet (32-bit)    →  ~sampel-palnet, ...
            └─ Moon (64-bit) →  ~doznec-sampel-palnet, ...
```

- Galaxies spawn stars
- Stars spawn planets
- Planets spawn moons (moons are not on Azimuth — managed by the planet directly)

## Ship Type from Point Number

```python
def ship_class(point):
    if point < 256:
        return "galaxy"
    elif point < 65536:
        return "star"
    elif point < 2**32:
        return "planet"
    else:
        return "moon"
```

## Resources

- [Roller API Source](https://github.com/urbit/urbit/tree/master/pkg/arvo/app/roller)
- [Azimuth Contracts](https://github.com/urbit/azimuth)
- [urbit-ob (Python)](https://pypi.org/project/urbit-ob/)
- [Azimuth Documentation](https://docs.urbit.org/system/identity)
