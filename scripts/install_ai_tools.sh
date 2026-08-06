#!/bin/bash

# AI Tools Installation Script for Dotfiles
# Pick-and-choose installer for the AI coding agents used across machines:
#   - Claude Code (Anthropic)
#   - Antigravity CLI / `agy` (Google)
#   - OpenCode
#   - Go AI tooling: every MCP server / CLI that improves AI agent support for
#     Go specifically -- gograph (call graph / blast-radius analysis), gopls's
#     native `gopls mcp` server (LSP-grade navigation, hover, diagnostics),
#     and delve (debugger CLI, no MCP wiring). MCP servers are wired into
#     whichever of Claude Code, Antigravity (agy), and OpenCode are installed
#     locally.
# Safe to re-run: every step is idempotent and skips what's already installed.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# --- Claude Code ---------------------------------------------------------

install_claude_code() {
	if command_exists claude; then
		print_success "Claude Code already installed ($(claude --version 2>/dev/null))"
		return 0
	fi

	print_info "Installing Claude Code..."
	if curl -fsSL https://claude.ai/install.sh | bash; then
		print_success "Claude Code installed"
	else
		print_error "Failed to install Claude Code"
		return 1
	fi
}

# --- Antigravity CLI (agy) -----------------------------------------------

install_antigravity() {
	if command_exists agy; then
		print_success "Antigravity CLI (agy) already installed"
		return 0
	fi

	print_info "Installing Antigravity CLI (agy)..."
	if curl -fsSL https://antigravity.google/cli/install.sh | bash; then
		print_success "Antigravity CLI (agy) installed"
	else
		print_error "Failed to install Antigravity CLI"
		return 1
	fi
}

# --- gograph --------------------------------------------------------------

install_gograph_binary() {
	if command_exists gograph; then
		print_success "gograph already installed"
		return 0
	fi

	if ! command_exists go; then
		print_warning "Go is required for gograph but not installed, skipping (run install_go.sh first)"
		return 1
	fi

	print_info "Installing gograph..."
	if go install github.com/ozgurcd/gograph/cmd/gograph@latest; then
		print_success "gograph installed via 'go install'"
	else
		print_error "Failed to install gograph"
		return 1
	fi
}

wire_gograph_claude() {
	if ! command_exists claude; then
		return 0
	fi

	print_info "Wiring gograph into Claude Code..."

	if claude plugin marketplace list 2>/dev/null | grep -q "gograph"; then
		print_warning "gograph marketplace already added"
	else
		claude plugin marketplace add ozgurcd/gograph
		print_success "gograph marketplace added"
	fi

	if claude plugin list 2>/dev/null | grep -q "gograph@gograph"; then
		print_warning "gograph plugin already installed"
	else
		claude plugin install gograph@gograph
		print_success "gograph plugin installed"
	fi

	if claude mcp list 2>/dev/null | grep -q "^gograph"; then
		print_warning "gograph MCP server already registered"
	else
		claude mcp add gograph -s user -- gograph mcp .
		print_success "gograph MCP server registered with Claude Code"
	fi
}

# Merges a gograph entry into a JSON config file with jq, creating the file
# (seeded with $2, e.g. '{"mcpServers":{}}') if it doesn't exist yet.
merge_json_config() {
	local config_file="$1"
	local seed="$2"
	local has_entry_filter="$3"
	local set_entry_filter="$4"

	mkdir -p "$(dirname "$config_file")"
	if [ ! -f "$config_file" ]; then
		echo "$seed" >"$config_file"
	fi

	if jq -e "$has_entry_filter" "$config_file" >/dev/null 2>&1; then
		return 1
	fi

	local tmp
	tmp=$(mktemp)
	jq "$set_entry_filter" "$config_file" >"$tmp" && mv "$tmp" "$config_file"
	return 0
}

wire_gograph_agy() {
	if ! command_exists agy; then
		return 0
	fi

	if ! command_exists jq; then
		print_warning "jq not found, skipping Antigravity (agy) MCP wiring"
		return 0
	fi

	print_info "Wiring gograph into Antigravity (agy)..."
	if merge_json_config \
		"$HOME/.gemini/config/mcp_config.json" \
		'{"mcpServers":{}}' \
		'.mcpServers.gograph' \
		'.mcpServers.gograph = {"command": "gograph", "args": ["mcp", "."]}'; then
		print_success "gograph MCP server registered with Antigravity (agy)"
	else
		print_warning "gograph already registered with Antigravity (agy)"
	fi
}

wire_gograph_opencode() {
	if ! command_exists opencode; then
		return 0
	fi

	if ! command_exists jq; then
		print_warning "jq not found, skipping OpenCode MCP wiring"
		return 0
	fi

	print_info "Wiring gograph into OpenCode..."
	if merge_json_config \
		"$HOME/.config/opencode/opencode.json" \
		'{"$schema": "https://opencode.ai/config.json", "mcp": {}}' \
		'.mcp.gograph' \
		'.mcp.gograph = {"type": "local", "command": ["gograph", "mcp", "."], "enabled": true}'; then
		print_success "gograph MCP server registered with OpenCode"
	else
		print_warning "gograph already registered with OpenCode"
	fi
}

setup_gograph_integrations() {
	if ! command_exists gograph; then
		print_warning "gograph binary not found, skipping agent wiring"
		return 0
	fi

	if ! command_exists claude && ! command_exists agy && ! command_exists opencode; then
		print_warning "No locally available AI agent (Claude Code / agy / OpenCode) found to wire gograph into"
		return 0
	fi

	wire_gograph_claude
	wire_gograph_agy
	wire_gograph_opencode
}

install_gograph() {
	install_gograph_binary && setup_gograph_integrations
}

# --- gopls MCP --------------------------------------------------------------
# gopls (v0.20+) exposes an MCP server natively via `gopls mcp` -- no bridge
# tool needed. See https://go.dev/gopls/features/mcp

install_gopls_binary() {
	if command_exists gopls; then
		print_success "gopls already installed ($(gopls version 2>/dev/null | head -n1))"
		return 0
	fi

	if ! command_exists go; then
		print_warning "Go is required for gopls but not installed, skipping (run install_go.sh first)"
		return 1
	fi

	print_info "Installing gopls..."
	if go install golang.org/x/tools/gopls@latest; then
		print_success "gopls installed via 'go install'"
	else
		print_error "Failed to install gopls"
		return 1
	fi
}

wire_gopls_claude() {
	if ! command_exists claude; then
		return 0
	fi

	print_info "Wiring gopls MCP into Claude Code..."
	if claude mcp list 2>/dev/null | grep -q "^gopls"; then
		print_warning "gopls MCP server already registered"
	else
		claude mcp add gopls -s user -- gopls mcp
		print_success "gopls MCP server registered with Claude Code"
	fi
}

wire_gopls_agy() {
	if ! command_exists agy; then
		return 0
	fi

	if ! command_exists jq; then
		print_warning "jq not found, skipping Antigravity (agy) MCP wiring"
		return 0
	fi

	print_info "Wiring gopls MCP into Antigravity (agy)..."
	if merge_json_config \
		"$HOME/.gemini/config/mcp_config.json" \
		'{"mcpServers":{}}' \
		'.mcpServers.gopls' \
		'.mcpServers.gopls = {"command": "gopls", "args": ["mcp"]}'; then
		print_success "gopls MCP server registered with Antigravity (agy)"
	else
		print_warning "gopls MCP already registered with Antigravity (agy)"
	fi
}

wire_gopls_opencode() {
	if ! command_exists opencode; then
		return 0
	fi

	if ! command_exists jq; then
		print_warning "jq not found, skipping OpenCode MCP wiring"
		return 0
	fi

	print_info "Wiring gopls MCP into OpenCode..."
	if merge_json_config \
		"$HOME/.config/opencode/opencode.json" \
		'{"$schema": "https://opencode.ai/config.json", "mcp": {}}' \
		'.mcp.gopls' \
		'.mcp.gopls = {"type": "local", "command": ["gopls", "mcp"], "enabled": true}'; then
		print_success "gopls MCP server registered with OpenCode"
	else
		print_warning "gopls MCP already registered with OpenCode"
	fi
}

setup_gopls_integrations() {
	if ! command_exists gopls; then
		print_warning "gopls binary not found, skipping agent wiring"
		return 0
	fi

	if ! command_exists claude && ! command_exists agy && ! command_exists opencode; then
		print_warning "No locally available AI agent (Claude Code / agy / OpenCode) found to wire gopls MCP into"
		return 0
	fi

	wire_gopls_claude
	wire_gopls_agy
	wire_gopls_opencode
}

install_gopls_mcp() {
	install_gopls_binary && setup_gopls_integrations
}

# --- delve (dlv) ------------------------------------------------------------
# Go debugger CLI. No MCP server exists for it -- installed as a plain CLI
# dependency so agents can drive debugging sessions through it.

install_delve() {
	if command_exists dlv; then
		print_success "delve (dlv) already installed"
		return 0
	fi

	if ! command_exists go; then
		print_warning "Go is required for delve but not installed, skipping (run install_go.sh first)"
		return 1
	fi

	print_info "Installing delve (dlv)..."
	if go install github.com/go-delve/delve/cmd/dlv@latest; then
		print_success "delve (dlv) installed via 'go install'"
	else
		print_error "Failed to install delve"
		return 1
	fi
}

# --- Go AI Tooling (umbrella) ------------------------------------------------
# Everything that improves AI agent support for Go specifically: gograph plus
# whatever else gograph doesn't cover (gopls MCP, delve, ...).

install_go_ai_tools() {
	install_gograph
	install_gopls_mcp
	install_delve
}

# --- OpenCode --------------------------------------------------------------

install_opencode() {
	local script_dir="$(dirname "$0")"
	bash "$script_dir/install_opencode.sh"
}

main() {
	while true; do
		echo ""
		echo "===== AI Tools Installer ====="
		echo "1) Install Claude Code"
		echo "2) Install Antigravity CLI (agy)"
		echo "3) Install Go AI tooling"
		echo "4) Install OpenCode"
		echo "5) Install ALL of the above"
		echo "0) Exit"
		echo "==============================="
		echo ""

		read -rp "Choose an option: " choice
		echo ""

		case $choice in
		1) install_claude_code ;;
		2) install_antigravity ;;
		3) install_go_ai_tools ;;
		4) install_opencode ;;
		5)
			install_claude_code
			install_antigravity
			install_opencode
			install_go_ai_tools
			;;
		0)
			print_info "Exiting..."
			break
			;;
		*) print_error "Invalid option, please try again." ;;
		esac
	done

	print_success "Done."
}

main "$@"
