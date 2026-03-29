---
name: prompt-engineering
description: Use when designing system prompts, AI agent workflows, or multi-agent orchestrations with CoT/few-shot.
user-invocable: true
---

# Prompt Engineering Expert

Design effective prompts, system instructions, and multi-agent architectures for LLM applications.

## When to Use
- Writing system prompts for AI applications
- Designing multi-agent orchestration
- Optimizing prompt performance (accuracy, cost, latency)
- Creating custom Claude Code skills (use with `skill-creator`)
- Building tool-use / function-calling patterns
- Debugging poor LLM outputs

## Prompt Design Principles

1. **Be specific** — Vague instructions produce vague outputs
2. **Structure with XML tags** — `<context>`, `<instructions>`, `<examples>`, `<output_format>`
3. **Give role context** — "You are a senior Python developer" focuses expertise
4. **Show don't tell** — One good example beats a paragraph of description
5. **Chain of thought** — "Think step by step" for complex reasoning
6. **Constrain output** — Specify format (JSON, markdown, bullet points)

## Common Patterns

**Few-Shot Template:**
```
Here are examples of the task:

Input: {example_input_1}
Output: {example_output_1}

Input: {example_input_2}
Output: {example_output_2}

Now complete this:
Input: {actual_input}
Output:
```

**Chain-of-Thought:**
```
Think through this step by step:
1. First, identify...
2. Then, analyze...
3. Finally, conclude...
```

**Tool Use Pattern:**
```
You have access to these tools:
- search(query) — Search the web
- calculate(expression) — Evaluate math

When you need information, call the appropriate tool.
```

## Anti-Patterns
- NEVER put critical instructions at the end — LLMs weight beginnings more
- NEVER use double negatives — "do not avoid" confuses models
- NEVER mix instructions with examples without clear separation
- ALWAYS test with edge cases before deploying
- ALWAYS version your prompts (track changes over time)

## Multi-Agent Architecture
```
Orchestrator → Router → Specialist Agents
                    ├── Research Agent (web search, docs)
                    ├── Code Agent (implementation)
                    ├── Review Agent (quality check)
                    └── Output Agent (formatting)
```

## Cost Optimization
- Use `haiku` for classification/routing, `sonnet` for generation, `opus` for complex reasoning
- Cache system prompts (prompt caching reduces cost 90%)
- Batch similar requests
- Minimize context by extracting only relevant information
