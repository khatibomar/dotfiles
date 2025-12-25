#!/bin/bash

# Install Acme (plan9port - Plan 9 tools for Unix) on Fedora
# Based on: https://9fans.github.io/plan9port/

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
        exit 1
    fi
    print_success "Detected Fedora Linux"
}

# Install dependencies
install_dependencies() {
    print_header "Installing Dependencies"

    print_info "Installing required packages..."
    sudo dnf install -y git make gcc libX11-devel libXt-devel fontconfig-devel

    print_success "Dependencies installed"
}

# Install plan9port and Acme
install_acme() {
    print_header "Installing plan9port (Acme)"

    local install_dir="/usr/local/plan9"

    print_info "Creating installation directory..."
    sudo mkdir -p "$install_dir"
    sudo chown -R $(id -u):$(id -g) "$install_dir"

    print_info "Cloning plan9port..."
    if ! git clone https://github.com/9fans/plan9port.git "$install_dir"; then
        print_error "Failed to clone plan9port"
        exit 1
    fi

    cd "$install_dir"

    print_info "Building plan9port..."
    if ! ./INSTALL -b; then
        print_error "Failed to build plan9port"
        exit 1
    fi

    print_info "Installing plan9port..."
    if ! ./INSTALL -c; then
        print_error "Failed to install plan9port"
        exit 1
    fi

    print_success "plan9port (Acme) installed successfully"
}

# Main function
main() {
    print_header "Acme (plan9port) Installation for Fedora"

    check_fedora
    install_dependencies
    install_acme

    print_success "Acme (plan9port) installation completed!"
    print_info "You can now use 'acme' command to launch the Acme text editor"
    print_info "Make sure /usr/local/plan9/bin is in your PATH"
}

# Run main function
main "$@"