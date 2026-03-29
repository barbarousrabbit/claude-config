---
name: feature-planning
description: Use when user describes a new feature and wants to plan before coding — task breakdown and acceptance criteria.
user-invocable: true
---

# Feature Planning

Systematically analyze feature requests and create detailed, actionable implementation plans.

## When to Use

- Requests new feature ("add user authentication", "build dashboard")
- Asks for enhancements ("improve performance", "add export")
- Describes complex multi-step changes
- Explicitly asks for planning ("plan how to implement X")
- Provides vague requirements needing clarification

## Planning Workflow

### 1. Understand Requirements

**Ask clarifying questions:**
- What problem does this solve?
- Who are the users?
- Specific technical constraints?
- What does success look like?

**Explore the codebase:**
Use Task tool with `subagent_type='Explore'` and `thoroughness='medium'` to understand:
- Existing architecture and patterns
- Similar features to reference
- Where new code should live
- What will be affected

### 2. Analyze & Design

**Identify components:**
- Database changes (models, migrations, schemas)
- Backend logic (API endpoints, business logic, services)
- Frontend changes (UI, state, routing)
- Testing requirements
- Documentation updates

**Consider architecture:**
- Follow existing patterns (check CLAUDE.md)
- Identify reusable components
- Plan error handling and edge cases
- Consider performance implications
- Think about security and validation

**Check dependencies:**
- New packages/libraries needed
- Compatibility with existing stack
- Configuration changes required

### 3. Create Implementation Plan

Break feature into **discrete, sequential tasks**:

```markdown
## Feature: [Feature Name]

### Overview
[Brief description of what will be built and why]

### Architecture Decisions
- [Key decision 1 and rationale]
- [Key decision 2 and rationale]

### Implementation Tasks

#### Task 1: [Component Name]
- **File**: `path/to/file.py:123`
- **Description**: [What needs to be done]
- **Details**:
  - [Specific requirement 1]
  - [Specific requirement 2]
- **Dependencies**: None (or list task numbers)

#### Task 2: [Component Name]
...

### Testing Strategy
- [What types of tests needed]
- [Critical test cases to cover]

### Integration Points
- [How this connects with existing code]
- [Potential impacts on other features]
```

**Include specific references:**
- File paths with line numbers (`src/utils/auth.py:45`)
- Existing patterns to follow
- Relevant documentation

### 4. Review Plan with User

Confirm:
- Does this match expectations?
- Missing requirements?
- Adjust priorities or approach?
- Ready to proceed?

### 5. Execute Implementation

**Chain handoff — invoke the next skill in the planning chain:**

- **For multi-file implementations:** invoke `writing-plans` to produce a detailed plan file, then `executing-plans` to implement it
- **For parallel independent tasks:** invoke `dispatching-parallel-agents` to run agents concurrently
- **For same-session execution:** invoke `subagent-driven-development` if tasks are independent

**Execution strategy:**
- Implement sequentially (respect dependencies)
- Verify each task before next
- Adjust plan if issues discovered
- Use `systematic-debugging` for failures
- Use `git-pushing` for commits

## Best Practices

**Planning:**
- Start broad, then specific
- Reference existing code patterns
- Include file paths and line numbers
- Think through edge cases upfront
- Keep tasks focused and atomic

**Communication:**
- Explain architectural decisions
- Highlight trade-offs and alternatives
- Be explicit about assumptions
- Provide context for future maintainers

**Execution:**
- Implement one task at a time
- Verify before moving forward
- Keep user informed
- Adapt based on discoveries

## Chain Position

```
brainstorming (vague idea) → feature-planning (requirements) → writing-plans (detailed plan) → executing-plans (implementation)
```

**This skill sits between brainstorming and writing-plans.** After creating the implementation plan, invoke `writing-plans` to produce a formal plan file ready for execution.

## Related Skills

- **writing-plans**: Produces formal plan files from the breakdown created here
- **executing-plans**: Implements plan files in a separate session
- **systematic-debugging**: For debugging issues found during implementation
- **git-pushing**: For committing completed work
