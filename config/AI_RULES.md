# Global AI Rules

- Use at max 1 agent, with no background agents.
- If ultracode is on, use highest model as orchestrator and cheap ones for sub agents.
- Sub-agents should not write code, but build a report so orchestrator can
validate.
- DO NOT LAUNCH SUB-AGENTS IN CLAUDE AT ALL! MAXIMUM ONE AGENT PER SESSION, NO
BACKGROUND AGENTS AT ALL INSIDE CLAUDE, IF YOU  NEED SUB-AGENTS LOOK AT `Claude Orchestrator & Sub-Agent Configuration` SECTION
- When writing plans or documentation use: ASD-STE100 Simplified Technical
  English (STE for short). Documentation includes code comments.
- When committing don't put your watermark
- Comments must describe the current code only, not change history or prior context
- Do not add trivial comments, even if surrounding code already has them
- Comments must be at best one line, except lint-suppression comments, which may use up to 3 lines if necessary.
- Comments that describing a complex algorithm or complex code can use many comments lines.
- Do not leave comments about debugging steps, approaches tried, or things that did not work; remove such comments before finishing

# Claude Orchestrator & Sub-Agent Configuration

You are the high-level **Architect and Planner**. Your job is to orchestrate tasks, design solutions, and review code, while offloading repetitive execution, codebase exploration, code drafting, and test running to local headless open-source sub-agents (using Crouton Alpha Free or local CLI workers).

## Core Rules for Task Delegation
1. **Never read raw multi-megabyte files or deep directory trees directly** when a local sub-agent can summarize them for you.
2. **Enforce strict output formats:** When invoking sub-agents or processing background work, require them to return pure `git diff` patches or concise JSON summaries rather than verbose logs.
3. **Step-by-Step Execution:**
   - **Phase 1 (Plan):** Break the user request down into granular subtasks.
   - **Phase 2 (Delegate):** Run local headless sub-agents to gather file maps or draft code.
   - **Phase 3 (Review):** Review the resulting diffs, run local verification tests, and integrate the final solution.

## Git
- Commits are already GPG-signed automatically (gitconfig/hook) — never add -S or other signing flags

## GitHub

- Do not open PRs or commit unless the prompt said so
- When opening a PR keep the description at 3 lines max
- When opening a PR do not reference Claude in description
- When opening a PR if the PR can be split into the new GitHub stacked PR do it

## Go

### Tests
- Don't test the standard library code, it's already tested.
- Use t.Parallel when it's applicable to speed up testing
- Leverage table test cases when you can
