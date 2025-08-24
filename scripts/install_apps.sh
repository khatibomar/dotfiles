#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
	echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
	echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
	echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
	echo -e "${RED}✗ $1${NC}"
}

# Check if running on Fedora
check_fedora() {
	if [ ! -f /etc/fedora-release ]; then
		print_error "This script is designed for Fedora Linux only."
		print_info "For other distributions, please install packages manually."
		exit 1
	fi
	print_success "Detected Fedora Linux"
}

# Install system packages via DNF
install_system_packages() {
	print_header "Installing System Packages"

	# Ensure local bin directory exists
	mkdir -p "$HOME/.local/bin"

	# Add to PATH if not already there
	if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
		export PATH="$PATH:$HOME/.local/bin"
	fi

	print_info "Updating system packages..."
	sudo dnf update -y

	# Core development tools
	print_info "Installing core development tools..."
	sudo sudo dnf5 install @development-tools @c-development

	# Essential packages used in dotfiles
	local packages=(
		# Shell and terminal
		"zsh"
		"tmux"
		"alacritty"

		# Editors
		"neovim"
		"vim"

		# Version control
		"git"
		"git-delta"

		# File management and utilities
		"fzf"
		"ripgrep"
		"bat"
		"btop"
		"htop"
		"tree"
		"lsd"
		"fd-find"
		"hyperfine"
		"sed"

		# Network tools
		"curl"
		"wget"
		"openssh-clients"
		"openssh-server"

		# Compression and archives
		"unzip"
		"tar"
		"gzip"
		"zip"

		# Development languages and runtimes
		"nodejs"
		"npm"
		"python3"
		"python3-pip"
		"lua"
		"luarocks"

		# Build tools
		"gcc"
		"clang"
		"clang-tools-extra"
		"make"
		"cmake"
		"ninja-build"
		"ninja"

		# Code analysis tools
		"cppcheck"
		"shellcheck"
		"valgrind"

		# Media tools
		"ffmpeg"
		"mpv"

		# Security and encryption
		"gnupg2"
		"pinentry"

		# Additional utilities
		"xclip"
		"xsel"
		"jq"
		"yq"
	)

	for package in "${packages[@]}"; do
		if rpm -q "$package" &>/dev/null; then
			print_success "$package already installed"
		else
			print_info "Installing $package..."
			sudo dnf install -y "$package" || print_error "Failed to install $package"
		fi
	done

	print_success "System packages installation completed"
}

# Install programming languages
install_languages() {
	print_header "Installing Programming Languages"

	# Install Go using the custom script
	print_info "Installing Go..."
	if command -v go &>/dev/null; then
		print_success "Go already installed: $(go version)"
	else
		local script_dir="$(dirname "$0")"
		if [ -f "$script_dir/install_go.sh" ]; then
			bash "$script_dir/install_go.sh"
			print_success "Go installed successfully"
		else
			print_info "Go install script not found, installing via DNF..."
			sudo dnf install -y golang
		fi
	fi

	# Install Rust via rustup
	print_info "Installing Rust..."
	if command -v rustc &>/dev/null; then
		print_success "Rust already installed: $(rustc --version)"
	else
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
		source "$HOME/.cargo/env"
		print_success "Rust installed successfully"
	fi

	# Add Rust tools
	if command -v cargo &>/dev/null; then
		print_info "Installing Rust-based tools..."
		cargo install stylua
		cargo install taplo-cli
		print_success "Rust tools installed"
	fi
}

# Install Oh My Zsh and plugins
install_oh_my_zsh() {
	print_header "Installing Oh My Zsh"

	if [ -d "$HOME/.oh-my-zsh" ]; then
		print_success "Oh My Zsh already installed"
	else
		print_info "Installing Oh My Zsh..."
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
		print_success "Oh My Zsh installed"
	fi

	# Install popular plugins
	local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

	# zsh-autosuggestions
	if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
		print_info "Installing zsh-autosuggestions..."
		git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
		print_success "zsh-autosuggestions installed"
	fi

	# zsh-syntax-highlighting
	if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
		print_info "Installing zsh-syntax-highlighting..."
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
		print_success "zsh-syntax-highlighting installed"
	fi

	# powerlevel10k theme
	if [ ! -d "$zsh_custom/themes/powerlevel10k" ]; then
		print_info "Installing powerlevel10k theme..."
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
		print_success "powerlevel10k theme installed"
	fi

	# Set zsh as default shell
	if [ "$SHELL" != "$(which zsh)" ]; then
		print_info "Setting zsh as default shell..."
		chsh -s $(which zsh)
		print_success "Default shell changed to zsh"
	fi
}

# Install tmux and tmuxifier
install_tmux_tools() {
	print_header "Installing Tmux Tools"

	# Install tmuxifier
	if [ -d "$HOME/.tmuxifier" ]; then
		print_info "Updating tmuxifier..."
		cd "$HOME/.tmuxifier" && git pull
		print_success "tmuxifier updated"
	else
		print_info "Installing tmuxifier..."
		git clone https://github.com/jimeh/tmuxifier.git "$HOME/.tmuxifier"
		print_success "tmuxifier installed"
	fi

	# Install TPM (Tmux Plugin Manager)
	if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
		print_info "Installing Tmux Plugin Manager..."
		git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
		print_success "TPM installed"
		print_info "Run 'prefix + I' in tmux to install plugins"
	fi
}

# Install Node.js tools
install_nodejs_tools() {
	print_header "Installing Node.js Tools"

	if command -v npm &>/dev/null; then
		# Configure npm global directory
		print_info "Configuring npm global directory..."
		mkdir -p ~/.npm-global
		npm config set prefix '~/.npm-global'

		print_info "Installing Node.js development tools..."

		# Language servers and linters
		npm install -g bash-language-server
		npm install -g vscode-langservers-extracted
		npm install -g typescript-language-server typescript
		npm install -g eslint
		npm install -g prettier

		print_success "Node.js tools installed"
	else
		print_error "npm not found, skipping Node.js tools"
	fi
}

# Install Go tools
install_go_tools() {
	print_header "Installing Go Tools"

	if command -v go &>/dev/null; then
		export GOPATH="${GOPATH:-$HOME/go}"
		export PATH="$PATH:$GOPATH/bin"
		mkdir -p "$GOPATH/bin"

		print_info "Installing Go development tools..."

		# Language server and tools
		go install golang.org/x/tools/gopls@latest
		go install golang.org/x/tools/cmd/goimports@latest
		go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@latest
		go install honnef.co/go/tools/cmd/staticcheck@latest
		go install github.com/fatih/gomodifytags@latest
		go install github.com/josharian/impl@latest
		go install github.com/jstemmer/gotags@latest
		go install mvdan.cc/sh/v3/cmd/shfmt@latest

		# Install golangci-lint
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$GOPATH/bin"

		print_success "Go tools installed"
	else
		print_error "Go not found, skipping Go tools"
	fi
}

# Install Python tools
install_python_tools() {
	print_header "Installing Python Tools"

	if command -v pip3 &>/dev/null; then
		print_info "Installing Python development tools..."

		# Neovim support
		pip3 install --user neovim pynvim

		# Development tools
		pip3 install --user black isort flake8 mypy
		pip3 install --user autopep8 pylint

		print_success "Python tools installed"
	else
		print_error "pip3 not found, skipping Python tools"
	fi
}

# Install fonts
install_fonts() {
	print_header "Installing Fonts"

	# Install Nerd Fonts
	local fonts_dir="$HOME/.local/share/fonts"
	mkdir -p "$fonts_dir"

	print_info "Installing IosevkaTerm Nerd Font..."
	wget "https://github.com/ryanoasis/nerd-fonts/raw/refs/heads/master/patched-fonts/IosevkaTerm/IosevkaTermNerdFont-Regular.ttf" -O "$fonts_dir/IosevkaTermNerdFont-Regular.ttf"
	wget "https://github.com/ryanoasis/nerd-fonts/raw/refs/heads/master/patched-fonts/IosevkaTerm/IosevkaTermNerdFont-Bold.ttf" -O "$fonts_dir/IosevkaTermNerdFont-Bold.ttf"
	wget "https://github.com/ryanoasis/nerd-fonts/raw/refs/heads/master/patched-fonts/IosevkaTerm/IosevkaTermNerdFont-Italic.ttf" -O "$fonts_dir/IosevkaTermNerdFont-Italic.ttf"
	fc-cache -f

	print_success "IosevkaTerm Nerd Font already installed"
}

# Install optional applications
install_optional_apps() {
	print_header "Installing Optional Applications"

	# Install Docker automatically
	print_info "Installing Docker..."
	local script_dir="$(dirname "$0")"
	if [ -f "$script_dir/install_docker.sh" ]; then
		bash "$script_dir/install_docker.sh"
	else
		print_info "Installing Docker via DNF..."
		sudo dnf install -y docker docker-compose
		sudo systemctl enable --now docker
		sudo usermod -aG docker $USER
	fi
	print_success "Docker installation completed"

	# Install additional tools from install_tools.sh functionality
	print_info "Installing additional development tools..."

	# Install git-recover
	if ! command -v git-recover &>/dev/null; then
		print_info "Installing git-recover..."
		curl -fsSL "https://raw.githubusercontent.com/ethomson/git-recover/refs/heads/main/git-recover" -o "$HOME/.local/bin/git-recover"
		chmod +x "$HOME/.local/bin/git-recover"
		print_success "git-recover installed"
	fi

	# Install golangci-lint
	if ! command -v golangci-lint &>/dev/null; then
		print_info "Installing golangci-lint..."
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$HOME/.local/bin"
		print_success "golangci-lint installed"
	fi

	# Install lua-language-server
	if ! command -v lua-language-server &>/dev/null; then
		print_info "Installing lua-language-server..."
		local latest_version=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"tag_name": "//;s/"//' || echo "3.7.4")
		local download_url="https://github.com/LuaLS/lua-language-server/releases/download/$latest_version/lua-language-server-$latest_version-linux-x64.tar.gz"
		local tmp_dir=$(mktemp -d)
		curl -L "$download_url" -o "$tmp_dir/lua-language-server.tar.gz"
		tar -xzf "$tmp_dir/lua-language-server.tar.gz" -C "$tmp_dir"
		mkdir -p "$HOME/.local/share/lua-language-server"
		cp -r "$tmp_dir"/* "$HOME/.local/share/lua-language-server/"
		ln -sf "$HOME/.local/share/lua-language-server/bin/lua-language-server" "$HOME/.local/bin/lua-language-server"
		rm -rf "$tmp_dir"
		print_success "lua-language-server installed"
	fi

	# Install buf (Protocol Buffers)
	if ! command -v buf &>/dev/null; then
		print_info "Installing buf..."
		curl -sSL https://github.com/bufbuild/buf/releases/latest/download/buf-Linux-x86_64 -o "$HOME/.local/bin/buf"
		chmod +x "$HOME/.local/bin/buf"
		print_success "buf installed"
	fi
}

# Configure system services
configure_services() {
	print_header "Configuring Services"

	# Enable SSH
	if systemctl list-unit-files | grep -q sshd.service; then
		sudo systemctl enable --now sshd
		print_success "SSH service enabled and started"
	fi

	# Configure firewall for SSH if firewalld is running
	if systemctl is-active --quiet firewalld; then
		sudo firewall-cmd --permanent --add-service=ssh
		sudo firewall-cmd --reload
		print_success "Firewall configured for SSH"
	fi
}

main() {
	print_header "Fedora Apps Installation for Dotfiles"
	print_info "This script will install applications used in your dotfiles configuration"
	print_info ""

	while true; do
		echo "Select an option:"
		echo "1) Install system packages"
		echo "2) Install languages"
		echo "3) Install Oh My Zsh"
		echo "4) Install tmux tools"
		echo "5) Install Node.js tools"
		echo "6) Install Go tools"
		echo "7) Install Python tools"
		echo "8) Install fonts"
		echo "9) Install optional apps"
		echo "10) Configure services"
		echo "11) Run ALL steps"
		echo "0) Exit"
		echo ""

		read -rp "Enter your choice: " choice
		echo ""

		case $choice in
		1) check_fedora && install_system_packages ;;
		2) install_languages ;;
		3) install_oh_my_zsh ;;
		4) install_tmux_tools ;;
		5) install_nodejs_tools ;;
		6) install_go_tools ;;
		7) install_python_tools ;;
		8) install_fonts ;;
		9) install_optional_apps ;;
		10) configure_services ;;
		11)
			check_fedora
			install_system_packages
			install_languages
			install_oh_my_zsh
			install_tmux_tools
			install_nodejs_tools
			install_go_tools
			install_python_tools
			install_fonts
			install_optional_apps
			configure_services
			;;
		0)
			print_info "Exiting..."
			break
			;;
		*) print_error "Invalid option, please try again." ;;
		esac

		echo ""
	done

	print_header "Installation Complete!"
	print_success "Selected applications have been installed!"
	print_info ""
	print_info "Next steps:"
	print_info "1. Restart your terminal or run: source ~/.zshrc"
	print_info "2. Configure your applications using the dotfiles"
	print_info "3. In tmux, press 'prefix + I' to install tmux plugins"
	print_info "4. Restart your session to apply all changes"
	print_info ""
	print_info "You may need to log out and back in for all changes to take effect."
}
