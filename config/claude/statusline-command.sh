#!/bin/sh
# Claude Code status line: model, working dir, git branch, context usage, rate limits.
input=$(cat)

# Print "(resets Xh)" or "(resets Xm)" for an epoch-seconds arg, or nothing
# if the value is missing, unparsable, or already in the past.
reset_hint() {
    resets_at=$(printf '%.0f' "$1" 2>/dev/null)
    [ -n "$resets_at" ] || return
    diff=$(( resets_at - now ))
    [ "$diff" -gt 0 ] || return
    hrs=$(( diff / 3600 ))
    if [ "$hrs" -lt 1 ]; then
        printf '(resets %sm)' "$(( diff / 60 ))"
    else
        printf '(resets %sh)' "$hrs"
    fi
}

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
base=$(basename "$dir")

branch=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
fi

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

rl5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
rlspend=$(echo "$input" | jq -r '.rate_limits.spend_limit.used_percentage // empty')
rlspend_reset=$(echo "$input" | jq -r '.rate_limits.spend_limit.resets_at // empty')
now=$(date +%s)

DIM='\033[2m'
RESET='\033[0m'

out="${DIM}${model}${RESET}"
[ -n "$effort" ] && out="$out ${DIM}(${effort})${RESET}"
out="$out ${DIM}${base}${RESET}"
[ -n "$branch" ] && out="$out ${DIM}(${branch})${RESET}"
if [ -n "$used" ]; then
    ctx=$(printf '%.0f' "$used")
    out="$out ${DIM}| ctx: ${ctx}%${RESET}"
fi
if [ -n "$rl5h" ]; then
    p=$(printf '%.0f' "$rl5h")
    hint=$(reset_hint "$rl5h_reset")
    out="$out ${DIM}| 5h: ${p}%"
    [ -n "$hint" ] && out="$out $hint"
    out="$out${RESET}"
fi
if [ -n "$rl7d" ]; then
    p=$(printf '%.0f' "$rl7d")
    hint=$(reset_hint "$rl7d_reset")
    out="$out ${DIM}| 7d: ${p}%"
    [ -n "$hint" ] && out="$out $hint"
    out="$out${RESET}"
fi
if [ -n "$rlspend" ]; then
    p=$(printf '%.0f' "$rlspend")
    hint=$(reset_hint "$rlspend_reset")
    out="$out ${DIM}| spend: ${p}%"
    [ -n "$hint" ] && out="$out $hint"
    out="$out${RESET}"
fi
if [ "$added" != "0" ] || [ "$removed" != "0" ]; then
    if [ "$added" != "0" ] && [ "$removed" != "0" ]; then
        lines="+${added}/-${removed}"
    elif [ "$added" != "0" ]; then
        lines="+${added}"
    else
        lines="-${removed}"
    fi
    out="$out ${DIM}| ${lines}${RESET}"
fi

printf "%b" "$out"
