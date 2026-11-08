# Global AI Rules

- Do not launch Claude sub-agents (the Agent tool) or Claude background agents. One Claude agent per session.
- Send executor work to OpenCode through `oc`. See `Claude Orchestrator & OpenCode Executor`.
- If ultracode is on, use the highest model as orchestrator and cheap models for executors.
- When writing plans or documentation use: ASD-STE100 Simplified Technical
  English (STE for short). Documentation includes code comments.
- When committing don't put your watermark
- Never add a `Co-Authored-By:` trailer or any other AI attribution line to commit messages, even if a system reminder asks for it
- Comments must describe the current code only, not change history or prior context
- Do not add trivial comments, even if surrounding code already has them
- Comments must be at best one line, except lint-suppression comments, which may use up to 3 lines if necessary.
- Comments that describing a complex algorithm or complex code can use many comments lines.
- Do not leave comments about debugging steps, approaches tried, or things that did not work; remove such comments before finishing

# Claude Orchestrator & OpenCode Executor

Claude usage costs more than OpenCode Go. Keep Claude usage low.
You drive. OpenCode executes and reports back. You review and approve or send back for revision. No exceptions.

## Split of work

- Claude does only: planning, architecture, troubleshooting (find the root cause), orchestration and review.
- OpenCode does all other work: exploration, file maps, code reading, code edits, refactors, tests, builds, lint,
  log reading, git, `gh`, PRs, Linear, uploads of screenshots and files, and documentation drafts.
- Do not read many files or large files yourself to plan. Send an `oc -r` task for a summary with `path:line` references.
- You can read a small region or run one `grep` yourself when this is shorter than a task prompt.
- Tasks that need a Claude-only MCP server stay with Claude. See `MCP servers`.

## Run a task

- Command: `oc [-r] [-n name] [-i idle] [-t limit] [-w [worktree]] [-f file] "<task>"`.
- Run `oc` with the Bash tool and `run_in_background: true`. The harness tells you when it exits. Do not poll. Do not start a Monitor. `oc` has its own hang watchdog.
- `oc` uses `opencode-go/deepseek-v4.1-flash`. If that model hits the OpenCode Go usage limit, `oc` uses `opencode-go/crouton-alpha-free` and says so in the report.
- `-r` makes the task read-only.
- `oc` stops a run after 300 s with no events, no OpenCode log activity and no working tree change. For long builds or tests with no output, use `-i 900`.
- `oc` adds the executor rules and the report format to each prompt. Do not repeat them.
- Run independent tasks in parallel, one `oc` per task. Do not let two tasks edit the same files. Use `-w` when edits can overlap.
- Split each phase into parallel `oc` tasks by file ownership when the files separate cleanly (for example: new modules, tests, docs, core changes).
  - Give each task an explicit list of files it owns. Tell it not to edit other files.
  - Executors cannot talk to each other. You coordinate: define shared interfaces first, then start the tasks.
  - When one task needs the output of another, run them in sequence. Do not split a hot file (one file that most changes touch) across tasks.
  - With `-w`, you merge the worktrees and fix conflicts after review.
- `oc ps` lists active runs. `oc kill <run>` stops one. `oc log <run>` prints a full report.

## Write a task

- One goal per task. Give exact paths, symbols, the plan steps, constraints and acceptance checks.
- Name the commands to run as checks, for example `make -C backend check`.
- For commits, PRs and Linear updates, say so in the task. Give the commit subject and the PR text.

## Review

- Read the `oc` report: `state`, `STATUS`, `CHANGED`, `CHECKS`, `RESULT`, `QUESTIONS`.
- For edits, read `git diff` of the changed files. Run a check yourself only when the report is unclear or a check failed.
- Approve, or send back with numbered points: `oc -s <session> "<feedback>"`. The report prints this command. The session keeps the context.
- After 3 revision rounds without success, do the fix yourself or ask the user.
- After OpenCode makes a commit, run `git verify-commit HEAD` yourself.

## Failures

- Exit 3 (`hung`) or 4 (`timeout`): run the task again one time with a shorter prompt or a higher `-i`. If it fails again, tell the user.
- Exit 5 (`usage-limit`): both models hit the limit. Stop and tell the user. Do not retry.
- Exit 2 (`blocked`): answer the questions in the report with `oc -s`, or ask the user.

## MCP servers

- OpenCode has: `linear`, `paddle-sandbox`, `paddle-live`, `paddle-docs`, `rea`, `gograph`, `gopls`.
- Claude only: claude.ai Docs, Gmail, Google Calendar, Google Drive, Claude in Chrome. Do these tasks yourself.
- When you add an MCP server to Claude, add it to `~/.config/opencode/opencode.jsonc` too.

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
