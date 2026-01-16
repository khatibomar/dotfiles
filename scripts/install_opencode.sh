#!/bin/bash

# OpenCode Installation Script for Dotfiles
# This script installs OpenCode AI coding agent

set -e

SCRIPT_DIR="$(dirname "$0")"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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

# Check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Install OpenCode using different methods
install_opencode() {
	print_info "Installing OpenCode..."

	# Method 1: Try using the official install script
	if command_exists curl; then
		print_info "Trying official install script..."
		if curl -fsSL https://opencode.ai/install | bash; then
			print_success "OpenCode installed via official script"
			return 0
		fi
	fi

	# Method 2: Try using npm
	if command_exists npm; then
		print_info "Trying npm installation..."
		if npm install -g opencode-ai; then
			print_success "OpenCode installed via npm"
			return 0
		fi
	fi

	# Method 3: Try using bun
	if command_exists bun; then
		print_info "Trying bun installation..."
		if bun install -g opencode-ai; then
			print_success "OpenCode installed via bun"
			return 0
		fi
	fi

	# Method 4: Try using homebrew
	if command_exists brew; then
		print_info "Trying homebrew installation..."
		if brew install anomalyco/tap/opencode; then
			print_success "OpenCode installed via homebrew"
			return 0
		fi
	fi

	# Method 5: Try using pnpm
	if command_exists pnpm; then
		print_info "Trying pnpm installation..."
		if pnpm install -g opencode-ai; then
			print_success "OpenCode installed via pnpm"
			return 0
		fi
	fi

	print_error "Failed to install OpenCode. Please install manually."
	print_info "Visit https://opencode.ai/docs for installation instructions."
	return 1
}

# Verify installation
verify_installation() {
	if command_exists opencode; then
		print_success "OpenCode is installed and available"
		opencode --version
		return 0
	else
		print_error "OpenCode installation verification failed"
		return 1
	fi
}

# Create OpenCode configuration directory
create_config() {
	print_info "Creating OpenCode configuration..."

	CONFIG_DIR="$HOME/.config/opencode"
	mkdir -p "$CONFIG_DIR"

	# Create basic config file
	cat >"$CONFIG_DIR/config.json" <<'EOF'
{
  "theme": "dark",
  "keybinds": "default",
  "providers": {
    "opencode": {
      "enabled": true
    }
  }
}
EOF

	print_success "OpenCode configuration created at $CONFIG_DIR"
}

# Setup shell integration
setup_shell_integration() {
	print_info "Setting up shell integration..."

	# Add opencode alias to shell config
	SHELL_CONFIG=""
	if [[ "$SHELL" == *"zsh"* ]]; then
		SHELL_CONFIG="$HOME/.zshrc"
	elif [[ "$SHELL" == *"bash"* ]]; then
		SHELL_CONFIG="$HOME/.bashrc"
	fi

	if [[ -n "$SHELL_CONFIG" && -f "$SHELL_CONFIG" ]]; then
		if ! grep -q "opencode" "$SHELL_CONFIG"; then
			echo "" >>"$SHELL_CONFIG"
			echo "# OpenCode AI Coding Agent" >>"$SHELL_CONFIG"
			echo "alias oc='opencode'" >>"$SHELL_CONFIG"
			echo "alias opencode='opencode'" >>"$SHELL_CONFIG"
			print_success "Added OpenCode aliases to $SHELL_CONFIG"
		else
			print_warning "OpenCode aliases already exist in $SHELL_CONFIG"
		fi
	fi
}

# Main installation function
main() {
	print_info "Starting OpenCode installation for dotfiles..."

	# Check if already installed
	if command_exists opencode; then
		print_warning "OpenCode is already installed"
		read -p "Do you want to reinstall? (y/N): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			print_info "Skipping installation"
			exit 0
		fi
	fi

	# Install OpenCode
	if install_opencode; then
		# Verify installation
		if verify_installation; then
			# Create configuration
			create_config

			# Setup shell integration
			setup_shell_integration

			print_success "OpenCode installation completed!"
			print_info "To get started:"
			print_info "  1. Restart your terminal or run: source $SHELL_CONFIG"
			print_info "  2. Navigate to a project directory"
			print_info "  3. Run: opencode"
			print_info "  4. Initialize with: /init"
			print_info "  5. Connect to a provider with: /connect"
		else
			print_error "Installation verification failed"
			exit 1
		fi
	else
		print_error "Installation failed"
		exit 1
	fi
}

# Run main function
main "$@"
