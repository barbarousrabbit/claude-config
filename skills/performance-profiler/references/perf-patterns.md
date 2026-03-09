# Performance Reference Patterns

## Before/After Measurement Template

```markdown
## Performance Optimization: [What You Fixed]

**Date:** YYYY-MM-DD | **Ticket:** PROJ-123

### Baseline (Before)
| Metric | Value |
|--------|-------|
| P50 latency | |
| P95 latency | |
| P99 latency | |
| RPS @ 50 VUs | |
| DB queries/req | |

### After
| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| P50 latency | | | |
| P95 latency | | | |
| P99 latency | | | |

### Root Cause / Fix Applied
[What the profiler revealed → what changed]
```

---

## k6 Load Test Script

```javascript
// tests/load/api-load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'
import { Rate, Trend } from 'k6/metrics'

const errorRate = new Rate('errors')
const apiDuration = new Trend('api_duration')

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m',  target: 50 },
    { duration: '2m',  target: 50 },
    { duration: '30s', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    errors: ['rate<0.01'],
  },
}

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000'

export function setup() {
  const res = http.post(`${BASE_URL}/api/auth/login`,
    JSON.stringify({ email: 'loadtest@example.com', password: 'loadtest123' }),
    { headers: { 'Content-Type': 'application/json' } }
  )
  return { token: res.json('token') }
}

export default function(data) {
  const headers = { 'Authorization': `Bearer ${data.token}` }
  const start = Date.now()
  const res = http.get(`${BASE_URL}/api/endpoint`, { headers })
  apiDuration.add(Date.now() - start)
  check(res, { 'status 200': (r) => r.status === 200 }) || errorRate.add(1)
  sleep(0.5)
}
```

```bash
k6 run tests/load/api-load-test.js --env BASE_URL=https://staging.myapp.com
```

---

## Node.js Memory Profiling Script

```javascript
// scripts/memory-profile.mjs — node --expose-gc scripts/memory-profile.mjs
function formatBytes(b) { return (b/1024/1024).toFixed(2) + ' MB' }

function measureMemory(label) {
  const m = process.memoryUsage()
  console.log(`[${label}] heapUsed=${formatBytes(m.heapUsed)} rss=${formatBytes(m.rss)}`)
  return m
}

const before = measureMemory('Baseline')
for (let i = 0; i < 1000; i++) { await yourOperation() }
global.gc?.()
const after = measureMemory('After GC')
if (after.heapUsed > before.heapUsed * 1.1) {
  console.warn('⚠️  Possible memory leak (>10% growth after GC)')
}
```

---

## N+1 Fix Pattern

```typescript
// Before: N+1
const tasks = await db.select().from(tasksTable)
for (const task of tasks) {
  task.assignee = await db.select().from(usersTable)
    .where(eq(usersTable.id, task.assigneeId)).then(r => r[0])
}

// After: single JOIN
const tasks = await db
  .select({ id: tasksTable.id, title: tasksTable.title, assigneeName: usersTable.name })
  .from(tasksTable)
  .leftJoin(usersTable, eq(usersTable.id, tasksTable.assigneeId))
  .where(eq(tasksTable.projectId, projectId))
```

---

## Bundle Quick Wins

```typescript
import _ from 'lodash'           // 71kB → import debounce from 'lodash/debounce'  // 2kB
import moment from 'moment'      // 67kB → import dayjs from 'dayjs'               // 7kB
import HeavyChart from './Heavy' // always loaded → dynamic(() => import('./Heavy'))
```
