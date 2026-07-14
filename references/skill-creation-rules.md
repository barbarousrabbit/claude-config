# Skill Creation Meta-Rules (Reference)

Loaded on demand from the `## Skill Creation (Meta-Rules)` pointer in CLAUDE.md. Apply when creating a new skill or editing an existing SKILL.md.

- Skill value = **safety override** (force-correct bad input) + **consistency** (shared patterns) + **explanation-driven** output
- Good evals: `without_skill` must NOT pass by common sense alone; must be verifiable from output files
- ALWAYS include an explicit override: *"If user provides [bad input], change to [correct] and explain why"*
- **Description must describe trigger scenarios, not capabilities** — "When user asks to compare competitors", not "Competitive analysis tool"
- **Description length ~80 chars, SKILL.md body ≤200 lines** — expand the description (more trigger keywords = higher hit rate), compress the SKILL.md body (shorter = more context window left for the actual task = better output). Move detailed templates to `references/`. One up, one down.
- Chinese trigger keywords inside `description` are allowed and intentional (they match Chinese user input); all surrounding prose stays English.
- After creating/renaming/deleting a skill, sync `references/skill-routing.md` (and `skill-chains.md` if chained) — a routing row pointing at a missing skill is worse than no row.
