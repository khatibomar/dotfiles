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

    print_info "Updating system packages..."
    sudo dnf update -y

    # Core development tools
    print_info "Installing core development tools..."
    sudo dnf groupinstall -y "Development Tools" "C Development Tools and Libraries"

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

    if [ ! -f "$fonts_dir/FiraCodeNerdFont-Regular.ttf" ]; then
        print_info "Installing FiraCode Nerd Font..."
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip" -O /tmp/FiraCode.zip
        unzip -q /tmp/FiraCode.zip -d /tmp/FiraCode/
        cp /tmp/FiraCode/*.ttf "$fonts_dir/"
        fc-cache -f
        rm -rf /tmp/FiraCode*
        print_success "FiraCode Nerd Font installed"
    else
        print_success "FiraCode Nerd Font already installed"
    fi
}

# Install optional applications
install_optional_apps() {
    print_header "Installing Optional Applications"

    # Docker
    read -p "Do you want to install Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
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
    fi

    # Tectonic (LaTeX)
    read -p "Do you want to install Tectonic (LaTeX engine)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local script_dir="$(dirname "$0")"
        if [ -f "$script_dir/install_tectonic.sh" ]; then
            bash "$script_dir/install_tectonic.sh"
        else
            print_info "Tectonic install script not found, skipping..."
        fi
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

# Main installation function
main() {
    print_header "Fedora Apps Installation for Dotfiles"
    print_info "This script will install all applications used in your dotfiles configuration"

    # Confirm installation
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi

    # Run installation steps
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

    print_header "Installation Complete!"
    print_success "All applications have been installed successfully!"
    print_info ""
    print_info "Next steps:"
    print_info "1. Restart your terminal or run: source ~/.zshrc"
    print_info "2. Configure your applications using the dotfiles"
    print_info "3. In tmux, press 'prefix + I' to install tmux plugins"
    print_info "4. Restart your session to apply all changes"
    print_info ""
    print_info "You may need to log out and back in for all changes to take effect."
}

# Run main function
main "$@"
