---
name: performance-profiler
description: Use when code is slow or user asks 'why is this slow' — profiles execution, identifies bottlenecks.
---

# Performance Profiler

Systematic performance profiling for Node.js, Python, and Go. Measures before and after every change.

**Rule #1: Profile first, optimize second. Never guess.**

## Core Capabilities

- CPU flamegraphs (clinic.js, py-spy, pprof)
- Memory leak detection (heap snapshots, memory_profiler)
- Bundle size analysis (webpack-bundle-analyzer, next/bundle-analyzer)
- Database query optimization (EXPLAIN ANALYZE, N+1 detection)
- Load testing (k6, Artillery)

---

## Node.js

```bash
# CPU flamegraph
npm install -g clinic autocannon
autocannon -c 50 -d 30 http://localhost:3000/api/endpoint &
clinic flame -- node dist/server.js

# Heap profiler
clinic heapprofiler -- node dist/server.js

# Event loop blocking detection
clinic bubbles -- node dist/server.js
```

```bash
# Built-in profiler
node --prof dist/server.js && node --prof-process isolate-*.log | head -100
```

---

## Python

```bash
# Live CPU top (no code changes)
pip install py-spy
py-spy top --pid $(pgrep -f "uvicorn")

# Flamegraph SVG
py-spy record -o flamegraph.svg --pid $(pgrep -f "uvicorn") --duration 30

# Line-by-line memory
pip install memory-profiler
python -m memory_profiler scripts/profile_function.py
```

---

## Go

```go
// Add to main.go
import _ "net/http/pprof"
go func() { log.Println(http.ListenAndServe(":6060", nil)) }()
```

```bash
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/profile?seconds=30
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/heap
curl http://localhost:6060/debug/pprof/goroutine?debug=1
```

---

## Bundle Size (Next.js)

```bash
pnpm add -D @next/bundle-analyzer
ANALYZE=true pnpm build          # Opens treemap in browser
pnpm dedupe --check               # Find duplicate packages
npx source-map-explorer .next/static/chunks/*.js
```

---

## Database

```sql
-- Top 20 slowest queries
SELECT round(mean_exec_time::numeric,2) AS mean_ms, calls, left(query,80)
FROM pg_stat_statements WHERE calls > 10
ORDER BY mean_exec_time DESC LIMIT 20;

-- Explain with real timing
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

**N+1 fix pattern:** See `references/perf-patterns.md`

---

## Quick Wins Checklist

```
Database:  missing index on WHERE/ORDER BY columns · N+1 queries · SELECT * · no LIMIT
Node.js:   sync I/O in hot path · missing caching · no gzip · deps loaded per-request
Bundle:    moment → dayjs · lodash full import · static heavy imports → dynamic
API:       no pagination · no Cache-Control · serial awaits → Promise.all
```

---

## Output Template

Record before/after for every optimization. See `references/perf-patterns.md` for
measurement template and k6 load test script.

**Common pitfalls:** Optimizing without measuring · testing with dev data · ignoring P99 · not re-measuring
