---
name: trailofbits-audit
description: Enables ultra-granular, line-by-line code analysis to build deep architectural context before vulnerability or bug finding. Use when deep comprehension is needed before security auditing, architecture review, or threat modeling.
---

# Deep Context Builder Skill (Ultra-Granular Pure Context Mode)

## 1. Purpose

This skill governs **how Claude thinks** during the context-building phase of an audit.

When active, Claude will:
- Perform **line-by-line / block-by-block** code analysis by default.
- Apply **First Principles**, **5 Whys**, and **5 Hows** at micro scale.
- Continuously link insights -> functions -> modules -> entire system.
- Maintain a stable, explicit mental model that evolves with new evidence.
- Identify invariants, assumptions, flows, and reasoning hazards.

This skill defines a structured analysis format and runs **before** the vulnerability-hunting phase.

## 2. When to Use This Skill

Use when:
- Deep comprehension is needed before bug or vulnerability discovery.
- You want bottom-up understanding instead of high-level guessing.
- Reducing hallucinations, contradictions, and context loss is critical.
- Preparing for security auditing, architecture review, or threat modeling.

Do **not** use for:
- Vulnerability findings
- Fix recommendations
- Exploit reasoning
- Severity/impact rating

## 3. How This Skill Behaves

When active, Claude will:
- Default to **ultra-granular analysis** of each block and line.
- Apply micro-level First Principles, 5 Whys, and 5 Hows.
- Build and refine a persistent global mental model.
- Update earlier assumptions when contradicted ("Earlier I thought X; now Y.").
- Periodically anchor summaries to maintain stable context.
- Avoid speculation; express uncertainty explicitly when needed.

## Rationalizations (Do Not Skip)

| Rationalization | Why It's Wrong | Required Action |
|-----------------|----------------|-----------------|
| "I get the gist" | Gist-level understanding misses edge cases | Line-by-line analysis required |
| "This function is simple" | Simple functions compose into complex bugs | Apply 5 Whys anyway |
| "I'll remember this invariant" | You won't. Context degrades. | Write it down explicitly |
| "External call is probably fine" | External = adversarial until proven otherwise | Jump into code or model as hostile |
| "I can skip this helper" | Helpers contain assumptions that propagate | Trace the full call chain |
| "This is taking too long" | Rushed context = hallucinated vulnerabilities later | Slow is fast |

## 4. Phase 1 -- Initial Orientation (Bottom-Up Scan)

1. Identify major modules/files/contracts.
2. Note obvious public/external entrypoints.
3. Identify likely actors (users, owners, relayers, oracles, other contracts).
4. Identify important storage variables, dicts, state structs, or cells.
5. Build a preliminary structure without assuming behavior.

## 5. Phase 2 -- Ultra-Granular Function Analysis

Every non-trivial function receives full micro analysis.

### Per-Function Microstructure Checklist

1. **Purpose** -- Why the function exists and its role in the system.
2. **Inputs & Assumptions** -- Parameters, implicit inputs, preconditions.
3. **Outputs & Effects** -- Return values, state writes, events, external interactions.
4. **Block-by-Block Analysis** -- What, Why here, Assumptions, Invariants, Dependencies.

Apply per-block: **First Principles**, **5 Whys**, **5 Hows**.

### Cross-Function Flow Analysis

- **Internal Calls**: Jump into callee, perform block-by-block analysis, track data flow caller -> callee -> return -> caller.
- **External Calls with code available**: Treat as internal, continue micro-analysis.
- **External Calls without code**: Analyze as adversarial -- consider all outcomes (revert, incorrect returns, reentrancy).

Treat the entire call chain as **one continuous execution flow**. Never reset context.

## 6. Phase 3 -- Global System Understanding

1. **State & Invariant Reconstruction** -- Map reads/writes, derive multi-function invariants.
2. **Workflow Reconstruction** -- End-to-end flows, state transforms, cross-step assumptions.
3. **Trust Boundary Mapping** -- Actor -> entrypoint -> behavior, untrusted input paths.
4. **Complexity & Fragility Clustering** -- Functions with many assumptions, high branching, coupled state.

## 7. Stability & Consistency Rules

- **Never reshape evidence to fit earlier assumptions.** Update the model and state the correction.
- **Periodically anchor key facts** -- invariants, state relationships, actor roles, workflows.
- **Avoid vague guesses** -- Use "Unclear; need to inspect X." not "It probably..."
- **Cross-reference constantly** -- Connect new insights to previous state and flows.

## 8. Non-Goals

While active, Claude should NOT:
- Identify vulnerabilities
- Propose fixes
- Generate proofs-of-concept
- Model exploits
- Assign severity or impact

This is **pure context building** only.
