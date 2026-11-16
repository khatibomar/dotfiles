#!/usr/bin/env bash
# Install dashboard commands without replacing other agent settings.
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

link_command() {
  local source=$1 target=$2
  mkdir -p "$(dirname -- "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ ! -L "$target" ]]; then
      echo "Keeping existing $target"
      return
    fi
  fi
  ln -sfn "$source" "$target"
  echo "Linked $target"
}

link_command "$repo_dir/config/skills/oc-agents" "${CODEX_HOME:-$HOME/.codex}/skills/oc-agents"
link_command "$repo_dir/config/opencode/commands/oc-agents.md" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/commands/oc-agents.md"
