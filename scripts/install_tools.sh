#!/bin/bash

set -e

# Define installation directory
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Color formatting
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Print section header
section() {
    echo -e "\n${BLUE}=== $1 ===${RESET}\n"
}

# Print success message
success() {
    echo -e "${GREEN}✓ $1${RESET}"
}

# Print info message
info() {
    echo -e "${YELLOW}ℹ $1${RESET}"
}

# Print error message
error() {
    echo -e "${RED}✗ $1${RESET}"
    return 1
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a package is installed (different from command exists)
package_installed() {
    local package="$1"
    case "$OS_TYPE" in
        fedora)
            dnf list installed "$package" &> /dev/null
            return $?
            ;;
        debian)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            return $?
            ;;
        mac)
            brew list "$package" &> /dev/null
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# Detect OS for package manager
detect_os() {
    if [ -f /etc/fedora-release ]; then
        export OS_TYPE="fedora"
        export PKG_MANAGER="dnf"
        export INSTALL_CMD="sudo dnf install -y"
        info "Detected Fedora - will use dnf for installations"
    elif [ -f /etc/debian_version ]; then
        export OS_TYPE="debian"
        export PKG_MANAGER="apt"
        export INSTALL_CMD="sudo apt install -y"
    elif [ "$(uname)" = "Darwin" ]; then
        export OS_TYPE="mac"
        if command_exists brew; then
            export PKG_MANAGER="brew"
            export INSTALL_CMD="brew install"
        else
            error "Homebrew is not installed. Please install it first: https://brew.sh/"
            exit 1
        fi
    else
        export OS_TYPE="unknown"
        error "Unsupported OS. Some tools may not install correctly."
    fi

    info "Detected OS: $OS_TYPE (using $PKG_MANAGER)"
}

# Install git-recover
install_git_recover() {
    section "Installing git-recover"

    # Download the latest git-recover script
    curl -fsSL "https://raw.githubusercontent.com/ethomson/git-recover/refs/heads/main/git-recover" -o "$INSTALL_DIR/git-recover"

    # Make it executable
    chmod +x "$INSTALL_DIR/git-recover"

    success "git-recover installed successfully!"
}

# Install golangci-lint (recommended method)
install_golangci_lint() {
    section "Installing golangci-lint"

    # Use v2 as the minimum version
    V2_VERSION="v2.1.0"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/golangci/golangci-lint/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"tag_name": "//;s/"//')

    # If latest version fetching fails, use a stable v2 version
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION="$V2_VERSION"
        info "Could not determine latest version, will use $LATEST_VERSION"
    fi

    # Ensure we're using at least v2
    if [[ "${LATEST_VERSION#v}" < "2" ]]; then
        LATEST_VERSION="$V2_VERSION"
        info "Enforcing minimum version $V2_VERSION"
    fi

    # Check if golangci-lint is already installed and compare versions
    if command_exists golangci-lint; then
        CURRENT_VERSION=$(golangci-lint --version | awk '{print $4}')
        info "Current golangci-lint version: $CURRENT_VERSION"
        info "Target golangci-lint version: $LATEST_VERSION"

        # Remove the 'v' prefix for version comparison if present
        CURRENT_VERSION_CLEAN=${CURRENT_VERSION#v}
        LATEST_VERSION_CLEAN=${LATEST_VERSION#v}

        # Check if current version is v1.x
        if [[ "${CURRENT_VERSION_CLEAN%%.*}" == "1" ]]; then
            info "Upgrading from v1.x to v2.x"
            curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$INSTALL_DIR" $LATEST_VERSION
        # Compare versions only if both are v2+
        elif [[ "$CURRENT_VERSION_CLEAN" == "$LATEST_VERSION_CLEAN" || "$CURRENT_VERSION_CLEAN" > "$LATEST_VERSION_CLEAN" ]]; then
            info "Current version is up to date or newer than target version. Skipping installation."
        else
            info "Installing newer golangci-lint version $LATEST_VERSION"
            curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$INSTALL_DIR" $LATEST_VERSION
        fi
    else
        info "Installing golangci-lint version $LATEST_VERSION"
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$INSTALL_DIR" $LATEST_VERSION
    fi

    if command_exists golangci-lint; then
        success "golangci-lint installed successfully!"
        golangci-lint --version
    else
        # Try to find it in GOPATH
        if [ -f "$GOPATH/bin/golangci-lint" ]; then
            ln -sf "$GOPATH/bin/golangci-lint" "$INSTALL_DIR/golangci-lint"
            success "golangci-lint installed successfully (linked from GOPATH)"
            golangci-lint --version
        else
            info "golangci-lint not found in PATH after installation"
            info "Try adding this to your shell config and restart your terminal:"
            echo "export PATH=\$PATH:$INSTALL_DIR"
        fi
    fi
}

# Install Go tools
install_go_tools() {
    section "Installing Go tools"

    # Check if Go is installed
    if ! command_exists go; then
        error "Go is not installed. Please install Go first."
        info "For Fedora: sudo dnf install golang"
        return 1
    fi

    # Create or update GOPATH if needed
    if [ -z "$GOPATH" ]; then
        export GOPATH="$HOME/go"
        mkdir -p "$GOPATH/bin"
        info "GOPATH set to $GOPATH"
    fi

    # Add GOPATH/bin to PATH if needed
    if [[ ":$PATH:" != *":$GOPATH/bin:"* ]]; then
        export PATH="$PATH:$GOPATH/bin"
        info "Added $GOPATH/bin to PATH"
    fi

    # Install Go tools
    info "Installing gopls (Go language server)"
    go install golang.org/x/tools/gopls@latest

    info "Installing fieldalignment"
    go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@latest

    info "Installing staticcheck"
    go install honnef.co/go/tools/cmd/staticcheck@latest

    info "Installing gomodifytags"
    go install github.com/fatih/gomodifytags@latest

    info "Installing impl"
    go install github.com/josharian/impl@latest

    info "Installing gotags"
    go install github.com/jstemmer/gotags@latest

    success "Go tools installed successfully!"
}

# Install tmuxifier
install_tmuxifier() {
    section "Installing tmuxifier"

    if [ -d "$HOME/.tmuxifier" ]; then
        info "tmuxifier already installed, updating..."
        cd "$HOME/.tmuxifier" && git pull
        success "tmuxifier updated"
    else
        git clone https://github.com/jimeh/tmuxifier.git "$HOME/.tmuxifier"
        success "tmuxifier installed"
    fi

    # Add to shell config if needed
    if ! grep -q "tmuxifier" "$HOME/.bashrc" 2>/dev/null && ! grep -q "tmuxifier" "$HOME/.zshrc" 2>/dev/null; then
        info "Adding tmuxifier to shell configuration"
        if [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/.tmuxifier/bin:$PATH"' >> "$HOME/.zshrc"
            echo 'eval "$(tmuxifier init -)"' >> "$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/.tmuxifier/bin:$PATH"' >> "$HOME/.bashrc"
            echo 'eval "$(tmuxifier init -)"' >> "$HOME/.bashrc"
        fi
    fi
}

# Install luarocks
install_luarocks() {
    section "Installing luarocks"

    if command_exists luarocks; then
        success "luarocks already installed"
        return 0
    fi

    case "$OS_TYPE" in
        fedora)
            $INSTALL_CMD luarocks
            ;;
        debian)
            $INSTALL_CMD luarocks
            ;;
        mac)
            $INSTALL_CMD luarocks
            ;;
        *)
            error "Manual installation required for luarocks"
            info "Visit https://luarocks.org/install for instructions"
            ;;
    esac

    if command_exists luarocks; then
        success "luarocks installed successfully"
    else
        error "Failed to install luarocks"
    fi
}

# Install Oh My Zsh
install_ohmyzsh() {
    section "Installing Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh is already installed"
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed successfully"
    fi
}

# Install commonly used tools
install_common_tools() {
    section "Installing common tools"

    local tools=()

    case "$OS_TYPE" in
        fedora)
            tools=(
                "fzf" "ripgrep" "bat" "btop" "neovim" "tmux" "npm" "nodejs"
                "clang" "clang-tools-extra" "cppcheck" "lua" "git"
            )
            # lsd requires cargo installation on Fedora
            if ! command_exists lsd; then
                if command_exists cargo; then
                    info "Installing lsd with cargo"
                    cargo install lsd
                else
                    info "Installing cargo for lsd"
                    $INSTALL_CMD cargo
                    cargo install lsd
                fi
            fi
            ;;
        debian)
            tools=(
                "fzf" "ripgrep" "bat" "btop" "neovim" "tmux" "npm" "nodejs"
                "clangd" "cppcheck" "lua5.3" "git"
            )
            # lsd requires cargo installation on Debian
            if ! command_exists lsd; then
                if command_exists cargo; then
                    info "Installing lsd with cargo"
                    cargo install lsd
                else
                    info "Installing cargo for lsd"
                    $INSTALL_CMD cargo
                    cargo install lsd
                fi
            fi
            ;;
        mac)
            tools=(
                "fzf" "ripgrep" "bat" "lsd" "btop" "neovim" "tmux" "node"
                "llvm" "cppcheck" "lua" "git"
            )
            ;;
        *)
            error "Unsupported OS for automatic tool installation"
            return 1
            ;;
    esac

    for tool in "${tools[@]}"; do
        # Special case for tools where command name differs from package name
        local cmd_name="$tool"
        case "$tool" in
            "ripgrep") cmd_name="rg" ;;
            "bat")
                if [ "$OS_TYPE" = "debian" ]; then
                    cmd_name="batcat"
                fi
                ;;
        esac

        if command_exists "$cmd_name" || package_installed "$tool"; then
            success "$tool is already installed"
        else
            info "Installing $tool"
            $INSTALL_CMD "$tool"

            # Check again with both methods
            if command_exists "$cmd_name" || package_installed "$tool"; then
                success "$tool installed successfully"
            else
                # Don't exit on error, just report it
                info "Note: $tool might be installed but not detected correctly"
            fi
        fi
    done
}

# Install bash-language-server
install_bash_language_server() {
    section "Installing bash-language-server"

    if command_exists bash-language-server; then
        success "bash-language-server is already installed"
    else
        info "Installing bash-language-server with npm"
        npm install -g bash-language-server
        if command_exists bash-language-server; then
            success "bash-language-server installed successfully"
        else
            error "Failed to install bash-language-server"
        fi
    fi
}

# Install shfmt (mvdan/sh)
install_shfmt() {
    section "Installing shfmt"

    if command_exists shfmt; then
        success "shfmt is already installed"
    else
        info "Installing shfmt"
        go install mvdan.cc/sh/v3/cmd/shfmt@latest
        if command_exists shfmt; then
            success "shfmt installed successfully"
        else
            error "Failed to install shfmt"
        fi
    fi
}

# Install lua-language-server
install_lua_language_server() {
    section "Installing lua-language-server"

    if command_exists lua-language-server; then
        success "lua-language-server is already installed"
        return 0
    fi

    # Get latest release version
    info "Fetching latest lua-language-server release..."
    local latest_version=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"tag_name": "//;s/"//')

    if [ -z "$latest_version" ]; then
        latest_version="3.7.4"  # Fallback version
        info "Could not determine latest version, using fallback $latest_version"
    fi

    case "$OS_TYPE" in
        fedora)
            info "Installing lua-language-server $latest_version for Linux"
            local download_url="https://github.com/LuaLS/lua-language-server/releases/download/$latest_version/lua-language-server-$latest_version-linux-x64.tar.gz"
            local tmp_dir=$(mktemp -d)

            # Download and extract
            curl -L "$download_url" -o "$tmp_dir/lua-language-server.tar.gz"
            tar -xzf "$tmp_dir/lua-language-server.tar.gz" -C "$tmp_dir"

            # Install to local directory
            mkdir -p "$HOME/.local/share/lua-language-server"
            cp -r "$tmp_dir"/* "$HOME/.local/share/lua-language-server/"

            # Create symlink to binary
            ln -sf "$HOME/.local/share/lua-language-server/bin/lua-language-server" "$INSTALL_DIR/lua-language-server"

            # Cleanup
            rm -rf "$tmp_dir"
            ;;
        debian)
            info "Installing lua-language-server $latest_version for Linux"
            local download_url="https://github.com/LuaLS/lua-language-server/releases/download/$latest_version/lua-language-server-$latest_version-linux-x64.tar.gz"
            local tmp_dir=$(mktemp -d)

            # Download and extract
            curl -L "$download_url" -o "$tmp_dir/lua-language-server.tar.gz"
            tar -xzf "$tmp_dir/lua-language-server.tar.gz" -C "$tmp_dir"

            # Install to local directory
            mkdir -p "$HOME/.local/share/lua-language-server"
            cp -r "$tmp_dir"/* "$HOME/.local/share/lua-language-server/"

            # Create symlink to binary
            ln -sf "$HOME/.local/share/lua-language-server/bin/lua-language-server" "$INSTALL_DIR/lua-language-server"

            # Cleanup
            rm -rf "$tmp_dir"
            ;;
        mac)
            info "Installing lua-language-server $latest_version for macOS"
            local download_url="https://github.com/LuaLS/lua-language-server/releases/download/$latest_version/lua-language-server-$latest_version-darwin-x64.tar.gz"
            local tmp_dir=$(mktemp -d)

            # Download and extract
            curl -L "$download_url" -o "$tmp_dir/lua-language-server.tar.gz"
            tar -xzf "$tmp_dir/lua-language-server.tar.gz" -C "$tmp_dir"

            # Install to local directory
            mkdir -p "$HOME/.local/share/lua-language-server"
            cp -r "$tmp_dir"/* "$HOME/.local/share/lua-language-server/"

            # Create symlink to binary
            ln -sf "$HOME/.local/share/lua-language-server/bin/lua-language-server" "$INSTALL_DIR/lua-language-server"

            # Cleanup
            rm -rf "$tmp_dir"
            ;;
        *)
            error "Unsupported OS for lua-language-server installation"
            return 1
            ;;
    esac

    if command_exists lua-language-server; then
        success "lua-language-server installed successfully"
    else
        error "Failed to install lua-language-server"
    fi
}

# Install buf (protobuf)
install_buf() {
    section "Installing buf (Protocol Buffers)"

    if command_exists buf; then
        success "buf is already installed"
    else
        info "Installing buf"
        # Official installation method
        if [ "$OS_TYPE" = "mac" ]; then
            curl -sSL https://github.com/bufbuild/buf/releases/latest/download/buf-Darwin-x86_64 -o "$INSTALL_DIR/buf"
        else
            curl -sSL https://github.com/bufbuild/buf/releases/latest/download/buf-Linux-x86_64 -o "$INSTALL_DIR/buf"
        fi
        chmod +x "$INSTALL_DIR/buf"
        if command_exists buf; then
            success "buf installed successfully"
        else
            error "Failed to install buf"
        fi
    fi
}

# Install taplo (TOML language server)
install_taplo() {
    section "Installing taplo (TOML tools)"

    if command_exists taplo; then
        success "taplo is already installed"
    else
        info "Installing taplo"
        if ! command_exists cargo; then
            info "Installing cargo (needed for taplo)"
            $INSTALL_CMD cargo
        fi

        if command_exists cargo; then
            cargo install taplo-cli
            if command_exists taplo; then
                success "taplo installed successfully"
            else
                info "Note: taplo might be installed but not in PATH"
            fi
        else
            error "Could not install cargo, which is required for taplo"
        fi
    fi
}

# Install StyLua
install_stylua() {
    section "Installing StyLua"

    if command_exists stylua; then
        success "StyLua is already installed"
    else
        info "Installing StyLua"
        if ! command_exists cargo; then
            info "Installing cargo (needed for StyLua)"
            $INSTALL_CMD cargo
        fi

        if command_exists cargo; then
            cargo install stylua
            if command_exists stylua; then
                success "StyLua installed successfully"
            else
                info "Note: StyLua might be installed but not in PATH"
            fi
        else
            error "Could not install cargo, which is required for StyLua"
        fi
    fi
}

# Create fieldalignment helper script
create_fieldalignment_helper() {
    section "Creating fieldalignment helper script"

    local HELPER_PATH="$INSTALL_DIR/align_fields"

    cat > "$HELPER_PATH" << 'EOF'
#!/bin/bash
# align_fields - Easy struct field alignment helper for Go
# This script helps optimize Go struct memory usage by reordering fields

set -e

if [ $# -eq 0 ]; then
    echo "Usage: align_fields [package path]"
    echo "Example: align_fields ./pkg/models"
    echo "         align_fields ."
    exit 1
fi

PKG_PATH="$1"

# Check if fieldalignment is installed
if ! command -v fieldalignment &> /dev/null; then
    echo "Error: fieldalignment not installed"
    echo "Installing fieldalignment..."
    go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@latest

    if ! command -v fieldalignment &> /dev/null; then
        echo "Failed to install fieldalignment. Make sure your Go bin directory is in your PATH."
        echo "Try running: export PATH=\$PATH:\$(go env GOPATH)/bin"
        exit 1
    fi
fi

echo "Analyzing package: $PKG_PATH"
echo

# Check if golangci-lint is available for enhanced detection
if command -v golangci-lint &> /dev/null; then
    echo "Using golangci-lint for enhanced field alignment detection:"
    golangci-lint run --disable-all --enable=fieldalignment "$PKG_PATH"
    RESULT=$?

    if [ $RESULT -eq 0 ]; then
        echo "No alignment issues found. Your structs are already optimized!"
    else
        # Ask for confirmation
        read -p "Do you want to apply these changes? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Applying changes..."
            fieldalignment -fix "$PKG_PATH"
            echo "Done! Fields have been realigned for better memory usage."
        else
            echo "No changes applied."
        fi
    fi
else
    # Fallback to direct fieldalignment usage
    echo "Potential struct alignment improvements:"
    fieldalignment "$PKG_PATH"

    # Check if there were any results
    if [ $? -eq 0 ]; then
        # Ask for confirmation
        read -p "Do you want to apply these changes? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Applying changes..."
            fieldalignment -fix "$PKG_PATH"
            echo "Done! Fields have been realigned for better memory usage."
        else
            echo "No changes applied."
        fi
    else
        echo "No alignment issues found. Your structs are already optimized!"
    fi
fi
EOF

    chmod +x "$HELPER_PATH"
    success "Created fieldalignment helper at $HELPER_PATH"
    info "You can now use 'align_fields [package]' to check and fix struct field alignment"
}

# Main execution
main() {
    section "Starting tools installation"

    # Set dotfiles directory path for copying configurations
    SCRIPT_PATH=$(readlink -f "$0")
    SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
    DOTFILES_DIR=$(dirname "$SCRIPT_DIR")

    info "Dotfiles directory: $DOTFILES_DIR"

    # Ensure local bin directory is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        export PATH="$PATH:$INSTALL_DIR"

        # Add to shell config if needed
        if [ -f "$HOME/.zshrc" ] && ! grep -q "$INSTALL_DIR" "$HOME/.zshrc"; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ] && ! grep -q "$INSTALL_DIR" "$HOME/.bashrc"; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
        fi

        info "Added $INSTALL_DIR to PATH"
    fi

    # Detect OS
    detect_os

    # Install tools
    install_common_tools  # Install basic tools first
    install_git_recover
    install_golangci_lint
    install_go_tools
    install_tmuxifier
    install_luarocks
    install_ohmyzsh
    install_bash_language_server
    install_shfmt
    install_lua_language_server
    install_buf
    install_taplo
    install_stylua

    # Create helper scripts
    create_fieldalignment_helper

    section "Installation Complete"
    success "All tools have been installed successfully!"
    info "Some tools may require a shell restart to be available in your PATH."
    info "You may need to source your shell configuration file:"
    echo "  source ~/.bashrc  # for Bash"
    echo "  source ~/.zshrc   # for Zsh"

    if [ -f "$HOME/.golangci.yml" ]; then
        info "golangci-lint is configured with fieldalignment support"
        info "Run 'golangci-lint run' in your Go projects to check field alignment"
        info "Or use the 'align_fields' helper script for interactive alignment fixes"
    fi

    # Check golangci-lint version to provide specific guidance
    if command_exists golangci-lint; then
        GLCI_VERSION=$(golangci-lint --version | awk '{print $4}')
        if [[ "${GLCI_VERSION#v}" < "2" ]]; then
            info "Note: You're using golangci-lint $GLCI_VERSION. Version 2.x is recommended."
            info "Run the script again to upgrade, or manually upgrade with:"
            echo "  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$GOPATH/bin v2.1.0"
        else
            success "Using golangci-lint version $GLCI_VERSION (v2+) ✓"
        fi
    fi
}

# Run the main function
main
