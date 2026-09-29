# Global AI Rules

- When writing plans or documentation use: ASD-STE100 Simplified Technical
  English (STE for short). Documentation includes code comments.
- When committing don't put your watermark
- Comments must describe the current code only, not change history or prior context
- Do not add trivial comments, even if surrounding code already has them
- Comments must be at best one line, except lint-suppression comments, which may use up to 3 lines if necessary.
- Comments that describing a complex algorithm or complex code can use many comments lines.
- Commits are already GPG-signed automatically (gitconfig/hook) — never add -S or other signing flags
- Do not leave comments about debugging steps, approaches tried, or things that did not work; remove such comments before finishing
- Do not open PRs or commit unless the prompt said so
- When opening a PR keep the description at 3 lines max
- When opening a PR do not reference Claude in description
- When opening a PR if the PR can be split into the new GitHub stacked PR do it
