# Modern JavaScript Syntax (ES2025+)

## Optional Chaining and Nullish Coalescing

```javascript
// Optional chaining - safe property access
const userName = user?.profile?.name;
const firstItem = items?.[0];
const result = api?.fetchData?.();

// Nullish coalescing - default only for null/undefined
const port = config.port ?? 3000;
const name = user.name ?? 'Anonymous';

// Combining both patterns
const displayName = user?.profile?.name ?? user?.email ?? 'Guest';

// Optional chaining with delete
delete user?.temporaryData?.cache;
```

## Private Class Fields

```javascript
class BankAccount {
  // Private fields
  #balance = 0;
  #accountNumber;

  // Private method
  #validateAmount(amount) {
    if (amount <= 0) throw new Error('Invalid amount');
  }

  constructor(accountNumber, initialBalance = 0) {
    this.#accountNumber = accountNumber;
    this.#balance = initialBalance;
  }

  deposit(amount) {
    this.#validateAmount(amount);
    this.#balance += amount;
    return this.#balance;
  }

  getBalance() {
    return this.#balance;
  }
}

// Static private fields
class Config {
  static #apiKey = process.env.API_KEY;

  static getApiKey() {
    return this.#apiKey;
  }
}
```

## Top-Level Await

```javascript
// No need for async IIFE wrapper
const data = await fetch('/api/config').then(r => r.json());
const db = await connectDatabase(data.dbUrl);

// Dynamic imports with await
const module = await import(`./modules/${moduleName}.js`);

// Error handling at top level
try {
  const config = await loadConfig();
  startServer(config);
} catch (error) {
  console.error('Failed to start:', error);
  process.exit(1);
}
```

## Array Methods (Modern)

```javascript
// at() - negative indexing
const last = items.at(-1);
const secondLast = items.at(-2);

// findLast() and findLastIndex()
const lastEven = numbers.findLast(n => n % 2 === 0);
const lastIndex = numbers.findLastIndex(n => n > 10);

// toSorted(), toReversed(), toSpliced() - non-mutating
const sorted = items.toSorted((a, b) => a - b);
const reversed = items.toReversed();
const spliced = items.toSpliced(1, 2, 'new');

// with() - replace at index
const updated = items.with(2, 'newValue');

// flatMap() for transform and flatten
const nestedResults = users.flatMap(user => user.posts);
```

## Array Grouping (ES2024)

```javascript
// Object.groupBy() - group array elements into object
const users = [
  { name: 'Alice', role: 'admin' },
  { name: 'Bob', role: 'user' },
  { name: 'Charlie', role: 'admin' },
];

const byRole = Object.groupBy(users, user => user.role);
// { admin: [Alice, Charlie], user: [Bob] }

const byAge = Object.groupBy(people, p => p.age >= 18 ? 'adult' : 'minor');

// Map.groupBy() - group into Map (useful when keys are non-strings)
const byDate = Map.groupBy(events, event => event.date);
// Map { Date(2025-01-01) => [...], Date(2025-01-02) => [...] }

const byObj = Map.groupBy(items, item => item.category);
// Map keys are object references, not coerced to strings
```

## Object and String Enhancements

```javascript
// Object.hasOwn() - safer hasOwnProperty
if (Object.hasOwn(obj, 'key')) {
  // safer than obj.hasOwnProperty('key')
}

// String.prototype.at()
const firstChar = str.at(0);
const lastChar = str.at(-1);

// replaceAll()
const cleaned = text.replaceAll('old', 'new');
const sanitized = input.replaceAll(/[<>]/g, '');
```

## WeakRef and FinalizationRegistry

```javascript
// WeakRef - hold weak references to objects
class Cache {
  #cache = new Map();

  set(key, value) {
    this.#cache.set(key, new WeakRef(value));
  }

  get(key) {
    const ref = this.#cache.get(key);
    return ref?.deref(); // undefined if GC'd
  }
}

// FinalizationRegistry - cleanup callbacks
const registry = new FinalizationRegistry((heldValue) => {
  console.log(`Cleanup: ${heldValue}`);
  // Release resources
});

class Resource {
  constructor(id) {
    this.id = id;
    registry.register(this, id, this);
  }

  dispose() {
    registry.unregister(this);
  }
}
```

## Logical Assignment Operators

```javascript
// ||= - assign if falsy
config.timeout ||= 5000;
user.name ||= 'Anonymous';

// &&= - assign if truthy
user.profile &&= sanitize(user.profile);

// ??= - assign if nullish
options.port ??= 3000;
settings.theme ??= 'dark';
```

## Numeric Separators and BigInt

```javascript
// Numeric separators for readability
const billion = 1_000_000_000;
const bytes = 0xFF_EC_DE_5E;
const trillion = 1_000_000_000_000n;

// BigInt for large integers
const hugeNumber = 9007199254740991n;
const result = hugeNumber + 1n;
const mixed = BigInt(123) + 456n;

// BigInt operations
const divided = 10n / 3n; // 3n (truncates)
const power = 2n ** 64n;
```

## Pattern Matching (Stage 3 Proposal)

```javascript
// Using switch with enhanced patterns (when available)
function processValue(value) {
  switch (true) {
    case typeof value === 'string':
      return value.toUpperCase();
    case typeof value === 'number':
      return value * 2;
    case Array.isArray(value):
      return value.length;
    default:
      return null;
  }
}

// Object destructuring patterns
function handleResponse({ status, data, error }) {
  if (error) throw error;
  if (status === 200) return data;
  return null;
}
```

## Iterator Helpers (ES2025)

```javascript
// Chaining lazy iterator operations — no intermediate arrays
const result = [1, 2, 3, 4, 5]
  .values()
  .map(x => x * 2)
  .filter(x => x > 5)
  .toArray(); // [6, 8, 10]

// Works on ANY iterable — Maps, Sets, generators
const activeUsers = users.values()
  .filter(u => u.active)
  .map(u => u.name)
  .take(10)
  .toArray();

// Available methods on Iterator.prototype:
// .map(fn)        — lazy transform
// .filter(fn)     — lazy predicate
// .take(n)        — first n elements
// .drop(n)        — skip first n elements
// .flatMap(fn)    — lazy flatten + map
// .reduce(fn, init) — eager reduction
// .toArray()      — collect into array
// .forEach(fn)    — eager side effects
// .some(fn)       — short-circuit test
// .every(fn)      — short-circuit test
// .find(fn)       — short-circuit search

// Lazy evaluation — great for large/infinite sequences
function* naturals() {
  let i = 1;
  while (true) yield i++;
}

const firstTenSquares = naturals()
  .map(n => n ** 2)
  .take(10)
  .toArray(); // [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

// Iterator.from() — wrap any iterable into an iterator with helpers
const mapIter = Iterator.from(myMap.entries())
  .filter(([key]) => key.startsWith('user_'))
  .map(([, value]) => value);
```

## Set Methods (ES2025)

```javascript
const frontend = new Set(['Alice', 'Bob', 'Charlie']);
const backend = new Set(['Bob', 'Diana', 'Charlie']);

// union() — all elements from both sets
frontend.union(backend);
// Set {'Alice', 'Bob', 'Charlie', 'Diana'}

// intersection() — elements in both sets
frontend.intersection(backend);
// Set {'Bob', 'Charlie'}

// difference() — elements in this but not other
frontend.difference(backend);
// Set {'Alice'}

// symmetricDifference() — elements in either but not both
frontend.symmetricDifference(backend);
// Set {'Alice', 'Diana'}

// isSubsetOf() — all elements of this are in other
new Set(['Bob']).isSubsetOf(frontend); // true

// isSupersetOf() — all elements of other are in this
frontend.isSupersetOf(new Set(['Bob'])); // true

// isDisjointFrom() — no elements in common
new Set(['Eve']).isDisjointFrom(frontend); // true

// Real-world: permission checking
const userPerms = new Set(['read', 'write']);
const requiredPerms = new Set(['read', 'admin']);
const missing = requiredPerms.difference(userPerms); // Set {'admin'}
if (missing.size > 0) {
  throw new Error(`Missing permissions: ${[...missing].join(', ')}`);
}
```

## Promise.withResolvers (ES2024)

```javascript
// Create a Promise with externally accessible resolve/reject
const { promise, resolve, reject } = Promise.withResolvers();

// Replaces the common pattern:
// let resolve, reject;
// const promise = new Promise((res, rej) => { resolve = res; reject = rej; });

// Use case: event-driven resolution
function waitForEvent(target, eventName) {
  const { promise, resolve } = Promise.withResolvers();
  target.addEventListener(eventName, resolve, { once: true });
  return promise;
}

// Use case: deferred pattern
class Deferred {
  constructor() {
    Object.assign(this, Promise.withResolvers());
  }
}

const deferred = new Deferred();
setTimeout(() => deferred.resolve('done'), 1000);
await deferred.promise; // 'done'
```

## Temporal API (enabled by default in Node.js 26)

```javascript
// No polyfill needed in Node.js 26+ — Temporal is globally available
const now = Temporal.Now.instant();
const date = Temporal.PlainDate.from('2025-06-15');
const time = Temporal.PlainTime.from('14:30:00');
const dateTime = Temporal.PlainDateTime.from('2025-06-15T14:30:00');

// Duration calculations
const duration = Temporal.Duration.from({ hours: 2, minutes: 30 });
const meeting = Temporal.PlainDateTime.from('2025-06-15T09:00:00');
const endTime = meeting.add(duration); // 2025-06-15T11:30:00

// Timezone-aware date/time
const zonedNow = Temporal.Now.zonedDateTimeISO('America/New_York');
const tokyoTime = zonedNow.withTimeZone('Asia/Tokyo');

// Compare dates safely (no more Date gotchas)
const start = Temporal.PlainDate.from('2025-01-01');
const end = Temporal.PlainDate.from('2025-12-31');
const diff = start.until(end); // P365D
console.log(diff.days); // 365

// Format with Intl
const formatted = zonedNow.toLocaleString('en-US', {
  weekday: 'long',
  year: 'numeric',
  month: 'long',
  day: 'numeric',
});

// NOTE: In browsers, Temporal is still Stage 3 — use @js-temporal/polyfill
// In Node.js 26+, it works natively with no imports
```

## Quick Reference

| Feature | ES Version | Syntax |
|---------|-----------|--------|
| Optional chaining | ES2020 | `obj?.prop` |
| Nullish coalescing | ES2020 | `value ?? default` |
| Private fields | ES2022 | `#fieldName` |
| Top-level await | ES2022 | `await import()` |
| Logical assignment | ES2021 | `x ??= y` |
| Array.at() | ES2022 | `arr.at(-1)` |
| Object.hasOwn() | ES2022 | `Object.hasOwn(obj, 'key')` |
| Array.findLast() | ES2023 | `arr.findLast(fn)` |
| toSorted() | ES2023 | `arr.toSorted()` |
| Object.groupBy() | ES2024 | `Object.groupBy(arr, fn)` |
| Map.groupBy() | ES2024 | `Map.groupBy(arr, fn)` |
| Promise.withResolvers | ES2024 | `Promise.withResolvers()` |
| Iterator Helpers | ES2025 | `iter.map(fn).filter(fn).toArray()` |
| Set.union() | ES2025 | `setA.union(setB)` |
| Set.intersection() | ES2025 | `setA.intersection(setB)` |
| Set.difference() | ES2025 | `setA.difference(setB)` |
