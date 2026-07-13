---
name: brainstorming
description: Use when user has a vague idea, says 'let's brainstorm', or asks 'X or Y' — explores intent before coding.
user-invocable: true
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs through natural collaborative dialogue: understand the current project context, ask questions one at a time to refine the idea, then present the design and get approval.

**Scope guard**: For trivial tasks (a single-file edit, a rename, a quick lookup), skip this skill entirely — just do the work. Use this process only when the idea is genuinely underspecified or the change is non-trivial (2+ files, 3+ distinct steps, or unclear requirements).

<HARD-GATE>
For non-trivial work: do NOT write code, scaffold a project, or take implementation action until you have presented a design and the user has approved it.
</HARD-GATE>

## Checklist

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time; understand purpose, constraints, success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to their complexity, get approval
5. **Write design doc** — only for larger work: save to `docs/plans/YYYY-MM-DD-<topic>-design.md`
6. **Transition to implementation** — proceed directly with the approved design; for multi-file work use the built-in plan mode (EnterPlanMode). Do NOT chain into additional planning skills.

## The Process

**Understanding the idea:**
- Check the current project state first (files, docs, recent commits)
- Ask questions one at a time; prefer multiple choice when possible
- Focus on: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Lead with your recommended option and explain why

**Presenting the design:**
- Scale each section to its complexity: a few sentences if straightforward
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## Key Principles

- **One question at a time** — don't overwhelm with multiple questions
- **YAGNI ruthlessly** — remove unnecessary features from all designs
- **Explore alternatives** — propose 2-3 approaches before settling
- **Right-size the ceremony** — short design for small tasks; skip the doc for quick approved changes
