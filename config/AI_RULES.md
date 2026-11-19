# Global AI Rules

- Never write temporary files, worktrees, venvs or downloads to /tmp: it is a small RAM disk and filling it crashes the machine. Use `~/.cache/agent-tmp` (already set as TMPDIR) and delete what you create when done.
- Do not launch Claude sub-agents (the Agent tool) or Claude background agents, except for the `oc` usage-limit fallback in the OpenCode rules. One Claude agent per session.
- When writing plans or documentation use: ASD-STE100 Simplified Technical
  English (STE for short). Documentation includes code comments.
- When committing don't put your watermark
- Never add a `Co-Authored-By:` trailer or any other AI attribution line to commit messages, even if a system reminder asks for it
- Comments must describe the current code only, not change history or prior context
- Do not add trivial comments, even if surrounding code already has them
- Comments must be at best one line, except lint-suppression comments, which may use up to 3 lines if necessary.
- Comments that describing a complex algorithm or complex code can use many comments lines.
- Do not leave comments about debugging steps, approaches tried, or things that did not work; remove such comments before finishing
- When the user must run a command, keep each line under 80 characters, because the terminal copy breaks long lines. If the command is longer, write it to a script in the scratchpad and give `! bash <script path>`.

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
