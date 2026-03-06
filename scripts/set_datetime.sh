#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  set_datetime.sh  –  Interactive TUI to change system date/time
#  Requires: bash 4+, tput
#
#  Flags:
#    -s, --sync   Sync time via NTP instead of setting manually
#    -r           Alias for -s
#    -h, --help   Show usage
# ─────────────────────────────────────────────────────────────

# ── Colours & styles ──────────────────────────────────────────
RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
BLU='\033[1;34m'
CYN='\033[1;36m'
WHT='\033[1;37m'
DIM='\033[2m'
BLD='\033[1m'
RST='\033[0m'
BGD='\033[44m' # blue background accent

# ── Helpers ───────────────────────────────────────────────────
clear_screen() { clear; }

center() { # center text in current terminal width
	local text="$1"
	local cols
	cols=$(tput cols)
	local len=${#text}
	local pad=$(((cols - len) / 2))
	printf "%${pad}s%s\n" "" "$text"
}

draw_box() { # draw a titled box  draw_box "Title" rows cols top left
	local title="$1" rows="$2" cols="$3" top="$4" left="$5"
	local r c
	tput cup $top $left
	printf "${CYN}╔"
	printf '═%.0s' $(seq 1 $((cols - 2)))
	printf "╗${RST}"
	for ((r = 1; r < rows - 1; r++)); do
		tput cup $((top + r)) $left
		printf "${CYN}║${RST}"
		printf "%$((cols - 2))s"
		printf "${CYN}║${RST}"
	done
	tput cup $((top + rows - 1)) $left
	printf "${CYN}╚"
	printf '═%.0s' $(seq 1 $((cols - 2)))
	printf "╝${RST}"
	# title
	local tlen=${#title}
	local tcol=$((left + (cols - tlen - 4) / 2))
	tput cup $top $((tcol))
	printf "${CYN}╣ ${WHT}${BLD}${title}${RST}${CYN} ╠${RST}"
}

show_usage() {
	printf "\n  ${BLD}${WHT}Usage:${RST}  %s [OPTIONS]\n\n" "$(basename "$0")"
	printf "  ${CYN}-s, --sync, -r${RST}   Sync system clock via NTP (skips manual entry)\n"
	printf "  ${CYN}-h, --help${RST}       Show this help message\n\n"
	printf "  ${DIM}Without flags, the interactive TUI lets you set date/time manually.${RST}\n\n"
}

spinner_wait() { # spinner for 1.5 s
	local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
	local end=$((SECONDS + 2))
	while [[ $SECONDS -lt $end ]]; do
		for f in "${frames[@]}"; do
			printf "\r  ${GRN}${f}${RST}  Applying…"
			sleep 0.08
		done
	done
	printf "\r%-30s\r" " "
}

spinner_sync() { # spinner with custom message, runs until killed
	local msg="$1"
	local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
	while true; do
		for f in "${frames[@]}"; do
			printf "\r  ${CYN}${f}${RST}  %s" "$msg"
			sleep 0.08
		done
	done
}

# ── NTP Sync mode ─────────────────────────────────────────────
do_sync() {
	clear_screen
	echo
	printf "${BGD}${WHT}${BLD}"
	center "  🔄  NTP TIME SYNC  "
	printf "${RST}\n"
	printf "${DIM}"
	center "Synchronise the system clock with internet time servers"
	printf "${RST}\n"
	echo

	local now
	now=$(date '+%Y-%m-%d %H:%M:%S %Z')
	printf "  ${DIM}Time before sync :${RST}  ${YLW}${BLD}%s${RST}\n\n" "$now"

	# Detect available sync tool
	local tool=""
	if command -v timedatectl &>/dev/null; then
		tool="timedatectl"
	elif command -v ntpdate &>/dev/null; then
		tool="ntpdate"
	elif command -v chronyd &>/dev/null || command -v chronyc &>/dev/null; then
		tool="chrony"
	elif command -v sntp &>/dev/null; then
		tool="sntp"
	else
		printf "  ${RED}${BLD}✖  No NTP tool found.${RST}\n"
		printf "  ${DIM}Install one of: systemd-timesyncd, ntpdate, chrony, or sntp.${RST}\n\n"
		exit 1
	fi

	printf "  ${DIM}Sync method      :${RST}  ${CYN}${BLD}%s${RST}\n\n" "$tool"
	printf "  ${YLW}Proceed with NTP sync? [Y/n] :${RST} "
	tput cnorm
	local confirm
	IFS= read -r confirm
	confirm="${confirm,,}"
	[[ -z "$confirm" ]] && confirm="y"

	if [[ "$confirm" != "y" ]]; then
		echo
		printf "  ${RED}Aborted. No changes made.${RST}\n\n"
		exit 0
	fi

	echo
	tput civis
	spinner_sync "Contacting NTP servers…" &
	local spin_pid=$!

	local rc=0
	case "$tool" in
	timedatectl)
		timedatectl set-ntp true 2>/dev/null
		rc=$?
		# Wait for sync to settle (up to 10 s)
		local waited=0
		while ((waited < 10)); do
			sleep 1
			((waited++))
			if timedatectl status 2>/dev/null | grep -q 'synchronized: yes'; then
				break
			fi
		done
		;;
	ntpdate)
		ntpdate -u pool.ntp.org 2>/dev/null
		rc=$?
		;;
	chrony)
		chronyc makestep 2>/dev/null
		rc=$?
		;;
	sntp)
		sntp -s pool.ntp.org 2>/dev/null
		rc=$?
		;;
	esac

	kill "$spin_pid" 2>/dev/null
	wait "$spin_pid" 2>/dev/null
	printf "\r%-50s\r" " "
	tput cnorm

	echo
	if ((rc == 0)); then
		printf "  ${GRN}${BLD}✔  NTP sync successful!${RST}\n"
		printf "  ${DIM}Time after sync  :  %s${RST}\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
		# Show timedatectl summary if available
		if command -v timedatectl &>/dev/null; then
			printf "  ${DIM}"
			timedatectl status 2>/dev/null |
				grep -E 'Local time|Time zone|NTP|synchronized' |
				sed 's/^/  /'
			printf "${RST}\n"
		fi
	else
		printf "  ${RED}${BLD}✖  NTP sync failed (rc=%d).${RST}\n" "$rc"
		printf "  ${DIM}Check network connectivity and that you are running as root.${RST}\n\n"
		exit 1
	fi
}

is_int() { [[ "$1" =~ ^[0-9]+$ ]]; }
in_range() {
	local v=$1 lo=$2 hi=$3
	is_int "$v" && ((v >= lo && v <= hi))
}

validate_date() { # validate_date YYYY MM DD
	local y=$1 m=$2 d=$3
	in_range "$m" 1 12 || return 1
	in_range "$d" 1 31 || return 1
	in_range "$y" 2000 2099 || return 1
	# days-in-month check
	local dim=(0 31 28 31 30 31 30 31 31 30 31 30 31)
	if ((y % 4 == 0 && (y % 100 != 0 || y % 400 == 0))); then dim[2]=29; fi
	((d <= dim[m]))
}

validate_time() { # validate_time HH MM SS
	in_range "$1" 0 23 && in_range "$2" 0 59 && in_range "$3" 0 59
}

# ── Read one field with inline validation ─────────────────────
read_field() {
	# read_field  "Label"  default  min  max  varname
	local label="$1" default="$2" lo="$3" hi="$4" varname="$5"
	local val=""
	while true; do
		printf "  ${WHT}%-12s${RST}[${DIM}%s${RST}] : " "$label" "$default"
		IFS= read -r val
		[[ -z "$val" ]] && val="$default"
		if in_range "$val" "$lo" "$hi"; then
			printf '\033[1A\033[2K' # erase prompt line
			printf "  ${WHT}%-12s${RST}${GRN}%-6s${RST}\n" "$label" "$val"
			printf -v "$varname" '%s' "$val"
			return 0
		else
			printf "  ${RED}  ✖ Must be %d–%d. Try again.${RST}\n" "$lo" "$hi"
			printf '\033[1A\033[2K'
			printf '\033[1A\033[2K'
		fi
	done
}

# ── Main TUI ──────────────────────────────────────────────────
main() {
	clear_screen
	local COLS
	COLS=$(tput cols)
	local ROWS
	ROWS=$(tput lines)

	# ── Header ────────────────────────────────────────────────
	tput civis # hide cursor
	echo
	printf "${BGD}${WHT}${BLD}"
	center "  🕐  SYSTEM DATE & TIME CONFIGURATOR  "
	printf "${RST}\n"
	printf "${DIM}"
	center "Change the system clock interactively"
	printf "${RST}\n"
	echo

	# ── Current date/time ─────────────────────────────────────
	local now
	now=$(date '+%Y-%m-%d %H:%M:%S %Z')
	printf "  ${DIM}Current time :${RST}  ${CYN}${BLD}%s${RST}\n\n" "$now"

	# Pull apart current values for defaults
	local CY CM CD CH CMi CS
	CY=$(date +%Y)
	CM=$(date +%-m)
	CD=$(date +%-d)
	CH=$(date +%-H)
	CMi=$(date +%-M)
	CS=$(date +%-S)

	tput cnorm # show cursor

	# ── DATE section ──────────────────────────────────────────
	printf "  ${YLW}${BLD}── DATE ─────────────────────────────────${RST}\n"
	local year month day
	read_field "Year   (YYYY)" "$CY" 2000 2099 year
	read_field "Month  (MM)" "$CM" 1 12 month
	# max day depends on month; use 31 and validate after
	read_field "Day    (DD)" "$CD" 1 31 day

	while ! validate_date "$year" "$month" "$day"; do
		printf "  ${RED}✖  Invalid date %04d-%02d-%02d. Re-enter day.${RST}\n" \
			"$year" "$month" "$day"
		read_field "Day    (DD)" "$CD" 1 31 day
	done

	echo
	# ── TIME section ──────────────────────────────────────────
	printf "  ${YLW}${BLD}── TIME ─────────────────────────────────${RST}\n"
	local hour minute second
	read_field "Hour   (HH)" "$CH" 0 23 hour
	read_field "Minute (MM)" "$CMi" 0 59 minute
	read_field "Second (SS)" "$CS" 0 59 second

	echo
	# ── Summary & confirm ─────────────────────────────────────
	local newdt
	newdt=$(printf '%04d-%02d-%02d %02d:%02d:%02d' \
		"$year" "$month" "$day" "$hour" "$minute" "$second")
	printf "  ${BLD}${WHT}New datetime :  ${GRN}%s${RST}\n\n" "$newdt"
	printf "  ${YLW}Apply this change? [Y/n] :${RST} "
	tput cnorm
	local confirm
	IFS= read -r confirm
	confirm="${confirm,,}" # lowercase
	[[ -z "$confirm" ]] && confirm="y"

	if [[ "$confirm" != "y" ]]; then
		echo
		printf "  ${RED}Aborted. No changes made.${RST}\n\n"
		exit 0
	fi

	# ── Apply ─────────────────────────────────────────────────
	echo
	tput civis
	spinner_wait &
	local spin_pid=$!

	local rc=0
	# Try timedatectl first (systemd), then date command
	if command -v timedatectl &>/dev/null; then
		# Disable NTP to allow manual set
		timedatectl set-ntp false 2>/dev/null
		timedatectl set-time "$newdt" 2>/dev/null
		rc=$?
	else
		# BSD / macOS: date MMDDHHmmYYYY.SS
		local bsd_fmt
		bsd_fmt=$(printf '%02d%02d%02d%02d%04d.%02d' \
			"$month" "$day" "$hour" "$minute" "$year" "$second")
		date "$bsd_fmt" 2>/dev/null
		rc=$?
		if ((rc != 0)); then
			# GNU date fallback
			date -s "$newdt" 2>/dev/null
			rc=$?
		fi
	fi

	wait $spin_pid 2>/dev/null
	tput cnorm

	echo
	if ((rc == 0)); then
		printf "  ${GRN}${BLD}✔  Date/time updated successfully!${RST}\n"
		printf "  ${DIM}New system time: %s${RST}\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
	else
		printf "  ${RED}${BLD}✖  Failed to set date/time (rc=%d).${RST}\n" "$rc"
		printf "  ${DIM}Tip: run as root / with sudo.${RST}\n\n"
		exit 1
	fi
}

# ── Entry point ───────────────────────────────────────────────
# Check we're in an interactive terminal
if [[ ! -t 0 || ! -t 1 ]]; then
	echo "Error: must be run in an interactive terminal." >&2
	exit 1
fi

# Parse flags
SYNC_MODE=false
for arg in "$@"; do
	case "$arg" in
	-s | --sync | -r) SYNC_MODE=true ;;
	-h | --help)
		show_usage
		exit 0
		;;
	*)
		printf "${RED}Unknown option: %s${RST}\n" "$arg" >&2
		show_usage
		exit 1
		;;
	esac
done

if $SYNC_MODE; then
	do_sync
else
	main
fi
