#!/bin/sh
# Claude Code status line: model, dir, git branch, context usage,
# 5-hour / weekly rate limits, session cost, lines changed.
# Input JSON spec: https://docs.claude.com/en/docs/claude-code/statusline
input=$(cat)

# Single jq pass, tab-separated fields.
parsed=$(printf '%s' "$input" | jq -r '
  [
    (.model.display_name // "unknown"),
    (.effort.level // "-"),
    (.workspace.current_dir // .cwd // "-"),
    (.context_window.used_percentage // "-" | tostring),
    ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0) | tostring),
    (.context_window.context_window_size // "-" | tostring),
    (.rate_limits.five_hour.used_percentage // "-" | tostring),
    (.rate_limits.five_hour.resets_at // "-" | tostring),
    (.rate_limits.seven_day.used_percentage // "-" | tostring),
    (.rate_limits.seven_day.resets_at // "-" | tostring),
    (.cost.total_cost_usd // "-" | tostring),
    (.cost.total_lines_added // 0 | tostring),
    (.cost.total_lines_removed // 0 | tostring)
  ] | @tsv
' 2>/dev/null) || exit 0
[ -n "$parsed" ] || exit 0

oldIFS=$IFS
IFS='	'
set -f
# shellcheck disable=SC2086
set -- $parsed
IFS=$oldIFS

model=$1; effort=$2; dir=$3; used=$4
tokens=$5; ctx_size=$6
rl5h=$7; rl5h_reset=$8; rl7d=$9; rl7d_reset=${10}
cost=${11}; added=${12}; removed=${13}

branch=""
if [ "$dir" != "-" ] && [ -n "$dir" ] && git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
fi
base=""
[ "$dir" != "-" ] && base=$(basename "$dir" 2>/dev/null)

now=$(date +%s)

# Print "(↺ Xd Xh Xm)" / "(↺ Xh Xm)" / "(↺ Xm)" for epoch-seconds arg:
# countdown with minute precision, no seconds. ↺ is the plain unicode
# (non-emoji) equivalent of 🔄, so it blends with terminal text.
reset_hint() {
    resets_at=$(printf '%.0f' "$1" 2>/dev/null)
    [ -n "$resets_at" ] || return
    diff=$(( resets_at - now ))
    [ "$diff" -gt 0 ] || return
    days=$(( diff / 86400 ))
    hrs=$(( (diff % 86400) / 3600 ))
    mins=$(( (diff % 3600) / 60 ))
    if [ "$days" -ge 1 ]; then
        printf '(↺ %dd %dh %dm)' "$days" "$hrs" "$mins"
    elif [ "$hrs" -ge 1 ]; then
        printf '(↺ %dh %dm)' "$hrs" "$mins"
    else
        printf '(↺ %dm)' "$mins"
    fi
}

fmt_k() {
    # 97000 -> 97k, 200000 -> 200k
    n=$1
    if [ -z "$n" ] || [ "$n" = "0" ] || [ "$n" = "-" ]; then echo ""; return; fi
    printf '%dk' "$(( (n + 500) / 1000 ))"
}

DIM='\033[2m'
RESET='\033[0m'

out="${DIM}${model}${RESET}"
[ "$effort" != "-" ] && [ -n "$effort" ] && out="$out ${DIM}(${effort})${RESET}"
[ -n "$base" ] && out="$out ${DIM}${base}${RESET}"
[ -n "$branch" ] && out="$out ${DIM}(${branch})${RESET}"

if [ "$used" != "-" ]; then
    ctx=$(printf '%.0f' "$used")
    tok=$(fmt_k "$tokens"); size=$(fmt_k "$ctx_size")
    if [ -n "$tok" ] && [ -n "$size" ]; then
        out="$out ${DIM}| ctx ${ctx}% (${tok}/${size})${RESET}"
    else
        out="$out ${DIM}| ctx ${ctx}%${RESET}"
    fi
fi

# 5-hour limit (resets hourly-window)
if [ "$rl5h" != "-" ]; then
    p=$(printf '%.0f' "$rl5h")
    hint=$(reset_hint "$rl5h_reset")
    out="$out ${DIM}| 5h: ${p}%"
    [ -n "$hint" ] && out="$out $hint"
    out="$out${RESET}"
fi

# 7-day weekly limit
if [ "$rl7d" != "-" ]; then
    p=$(printf '%.0f' "$rl7d")
    hint=$(reset_hint "$rl7d_reset")
    out="$out ${DIM}| 7d: ${p}%"
    [ -n "$hint" ] && out="$out $hint"
    out="$out${RESET}"
fi

# Session cost ($ usage)
if [ "$cost" != "-" ]; then
    out="$out ${DIM}| \$$(printf '%.2f' "$cost")${RESET}"
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
