# dotfiles AGENTS.md

## Overview

Personal dotfiles for Linux/macOS. This is not a buildable project — configs are deployed via `./install.sh`.

## Install

- Run `./install.sh` for an interactive menu (Fedora apps, nvim, config, scripts, GPG, SSH, wallpaper, OpenCode).
- **Do not run non-interactively** — options 1 and 9 launch menus or multi-step installers.
- Backup dirs `~/.config-backup-*` are created on each run; remove with `./clean.sh`.

## Key structure

| Source | Destination | Notes |
|---|---|---|
| `config/*` (most) | `~/.$name` | Exceptions below |
| `config/htoprc` | `~/.config/htop/htoprc` | |
| `config/mpv.conf` | `~/.config/mpv/mpv.conf` | |
| `config/konsole/*` | `~/.konsole/` | Konsole terminal profiles |
| `config/konsolerc` | `~/.config/konsolerc` | Sets default Konsole profile to `ayn.profile` |
| `nvim/` | `~/.config/nvim/` | |
| `scripts/` | `~/scripts/` | |
| `keys/*` | `~/.ssh/` / GPG keyring | Sensitive — only placeholders in repo |
| `wallpapers/` | `~/.local/share/wallpapers/` | Set via `plasma-apply-wallpaperimage` |

## Keys directory — WARNING

`keys/` contains GPG (`gpg_private_key.asc`, `gpg_public_key.asc`) and SSH (`id_ed25519`, `id_ed25519.pub`) credentials. The files tracked in git **must** be placeholders. Never commit real private keys.

## Shell config loading order

1. `$HOME/.export` (from `config/export`) — vars like PATH, EDITOR, BAT_THEME
2. `$HOME/work/.export` — work-specific overrides (conditionally sourced)
3. oh-my-zsh
4. `$HOME/.alias` (from `config/alias`) — aliases (v→nvim, ls→lsd, cat→bat, etc.)
5. nvm
6. tmuxifier

## Git

- All commits GPG-signed (key `0D2909D6BB710138`).
- Default branch: `main`. Merge strategy: `pull.ff=only`, `rebase.autostash=true`.
- Pager: `delta` with side-by-side, Dracula theme.
- Diff/merge tool: kdiff3.
- Conditional include for `~/work/` projects: `~/.work/.gitconfig`.
- Commit template: `~/.gitmessage.txt`.
- Extensive aliases defined in `config/gitconfig` (e.g. `lg` for log graph, `undo` for soft reset, `standup` for daily log).

## Neovim (`nvim/`)

- Entrypoint: `nvim/init.lua`.
- Plugin manager: lazy.nvim (bootstrap on first run). Specs auto-imported from `nvim/lua/plugins/`.
- Config modules in `nvim/lua/config/`:
  - `lazy.lua` — bootstraps lazy.nvim, loads plugin specs
  - `keymap.lua` — leader keybindings (space leader)
  - `vim-options.lua` — editor settings
  - `find.lua` — fuzzy finding
  - `statusline.lua` — custom statusline
  - `command-palette.lua` — Ctrl+P command palette
- Leader key: `<space>` (unmaps default behavior).
- LSP servers configured: gopls, lua-language-server, bash-language-server.
- Formatters (via none-ls): stylua, shfmt, gofmt.

## Tmux (`config/tmux.conf`)

- Prefix: `C-b`. Vi mode keys. Mouse on.
- Plugins via TPM: tmux-sensible, tmux-resurrect, tmux-continuum, vim-tmux-navigator, tmux-fzf.
- `prefix+p` opens fzf-popup (toggle via `scripts/toggle_tmux_popup.sh`).
- `prefix+C-e` — session switcher via fzf popup.
- `prefix+C-f` — window switcher via fzf popup.
- `prefix+y` — copy buffer to system clipboard (xclip).
- Status bar hidden by default (`status-right` empty, toggle with `prefix+t`).

## Tools referenced

- shell: zsh + oh-my-zsh (theme: lambda)
- ls: lsd, cat: bat (gruvbox-light theme), top: btop
- tmuxifier for tmux session/window management
- fzf (zsh integration), ripgrep, delta, nvm
- Plan 9 from User Space (plan9port) at `/usr/local/plan9`

## Cleanup

`./clean.sh` removes all `~/.config-backup-*` directories.

## OpenCode config

`config/opencode.json` — local editor config with LSP (lua, bash, go) and formatters (stylua, shfmt, gofmt). Used when editing this repo.

## What this repo does NOT have

- No CI, no tests, no linter/formatter scripts (configs only).
- No build steps, no package.json, no go.mod.
