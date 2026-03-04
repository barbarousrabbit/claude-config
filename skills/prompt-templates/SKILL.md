---
name: prompt-templates
description: Anthropic official 10-component prompt framework with comprehensive and minimal templates. Use when crafting system prompts, creating reusable prompt templates, or structuring complex prompts with role/tone/background/task/rules/examples/thinking/format components.
---

# Prompt Templates (Anthropic 10-Component Framework)

When the user needs to create a high-quality prompt (for Claude API, system prompts, or reusable templates), use the templates in `references/` as your foundation.

## Two Templates Available

### 1. Comprehensive Template (`references/comprehensive-prompt-template.md`)
For complex, high-stakes, or production prompts. Includes all 10 components:
- System Prompt (role/expertise)
- Tone (communication style)
- Background (context/data)
- Task (objective + constraints + success criteria)
- Rules (MUST / MUST NOT / CONSIDER)
- Examples (good + bad)
- Thinking (reasoning guidance)
- Format (output structure)

**Use when**: Architecture design, code review prompts, production AI workflows, critical decisions.

### 2. Minimal Template (`references/minimal-prompt-template.md`)
For quick, straightforward tasks. Uses 3-5 core components.

**Use when**: Simple questions, quick formatting, single-step tasks.

## Workflow

1. Read the appropriate template from `references/`
2. Help the user fill in each component
3. Generate the complete prompt in XML-tagged format
4. Offer to iterate and refine

## Key Principle

> "More context = better output. Include real data, concrete examples, and explicit success criteria."
