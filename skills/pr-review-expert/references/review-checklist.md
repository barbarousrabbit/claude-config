# PR Review Checklist (30+ items)

## Code Quality (8 items)
- [ ] Functions are small and single-purpose
- [ ] No duplicated logic — shared code is extracted
- [ ] Variable/function names are descriptive and consistent
- [ ] No commented-out code left behind
- [ ] Error messages are actionable (not generic "something went wrong")
- [ ] Complex logic has inline comments explaining WHY (not what)
- [ ] No magic numbers — constants are named
- [ ] No TODO/FIXME/HACK without a linked issue

## Security (7 items)
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] User input is validated/sanitized at boundaries
- [ ] SQL queries use parameterized statements (no string interpolation)
- [ ] No `eval()`, `dangerouslySetInnerHTML`, or raw HTML injection
- [ ] Auth/permissions checked on all new endpoints
- [ ] Sensitive data not logged or exposed in error responses
- [ ] CORS, CSP, and security headers configured correctly

## Testing (6 items)
- [ ] New functions have corresponding tests
- [ ] Edge cases tested (empty input, null, boundary values)
- [ ] Error paths tested (not just happy path)
- [ ] No flaky assertions (timing-dependent, order-dependent)
- [ ] Auth/payment paths have 100% coverage
- [ ] Coverage delta is positive or neutral (no drop >5%)

## Performance (5 items)
- [ ] No N+1 queries (check loops with DB calls)
- [ ] No unnecessary re-renders (React: deps arrays, memoization)
- [ ] Large data sets have pagination or streaming
- [ ] New dependencies are justified (bundle size checked)
- [ ] No synchronous blocking in async contexts

## Breaking Changes (5 items)
- [ ] No API endpoint removals without deprecation
- [ ] No TypeScript interface/type signature changes without migration
- [ ] No DB destructive operations (DROP TABLE/COLUMN) without migration plan
- [ ] New required env vars documented in README/.env.example
- [ ] Backward compatibility maintained OR migration guide provided

## Operations (5 items)
- [ ] New features have logging for observability
- [ ] Error handling doesn't swallow exceptions silently
- [ ] Database migrations are reversible
- [ ] Feature flags used for risky rollouts
- [ ] Deployment runbook updated if process changes

## Documentation (3 items)
- [ ] Public API changes documented (OpenAPI, JSDoc, README)
- [ ] Non-obvious behavior explained in code comments
- [ ] CHANGELOG updated for user-facing changes
