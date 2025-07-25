#!/usr/bin/env bash

# Git Setup Verification Script
# Checks if all Git enhancements are properly installed and configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS for compatibility checks
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS_TYPE="linux"
fi

# Print functions
print_header() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_header "Git Enhancement Setup Verification"

if [[ "$OS_TYPE" == "mac" ]]; then
  print_info "Running on macOS - checking compatibility"
elif [[ "$OS_TYPE" == "linux" ]]; then
  print_info "Running on Linux"
else
  print_warning "Unknown OS type - some checks may not be accurate"
fi

# Basic Git check
if command_exists git; then
  git_version=$(git --version)
  print_success "Git installed: $git_version"
else
  print_error "Git not found! Please install Git first."
  exit 1
fi

# Check delta
print_header "Delta (Better Git Diff)"
if command_exists delta; then
  delta_version=$(delta --version)
  print_success "Delta installed: $delta_version"
else
  if [[ "$OS_TYPE" == "mac" ]]; then
    print_error "Delta not found! Install with: brew install git-delta"
  else
    print_error "Delta not found! Install with: sudo dnf install git-delta"
  fi
fi

# Check lazygit
print_header "Lazygit (Interactive Git UI)"
if command_exists lazygit; then
  print_success "Lazygit installed and available"
else
  if [[ "$OS_TYPE" == "mac" ]]; then
    print_warning "Lazygit not found. Install with: brew install lazygit"
  else
    print_warning "Lazygit not found. Install with: go install github.com/jesseduffield/lazygit@latest"
  fi
fi

# Check nvim
print_header "Neovim (Enhanced Diff/Merge Tool)"
if command_exists nvim; then
  nvim_version=$(nvim --version | head -n1)
  print_success "Neovim installed: $nvim_version"
else
  print_error "Neovim not found! Please install neovim for enhanced diff/merge."
fi

# Check fzf
print_header "FZF (Fuzzy Finding)"
if command_exists fzf; then
  print_success "FZF installed - enhanced Git functions available"
else
  print_warning "FZF not found - some interactive Git functions won't work"
fi

# Check custom scripts
print_header "Custom Git Tools"

if [[ -x "$HOME/.local/bin/git-setup-check" ]]; then
  print_success "Git setup check script installed"
else
  print_error "Git setup check script not found in ~/.local/bin/ (run install.sh)"
fi

if [[ -f "$HOME/.local/bin/git_functions.sh" ]]; then
  print_success "Git shell functions installed and enabled"
  print_info "Use 'git_help' or 'ghelp' to see all available functions"
else
  print_error "Git shell functions not found in ~/.local/bin/ (run install.sh)"
fi

# Check Git configuration
print_header "Git Configuration"

# Check if delta is configured as pager
if git config --get core.pager | grep -q delta; then
  print_success "Delta configured as Git pager"
else
  print_warning "Delta not configured as pager"
fi

# Check diff tool
diff_tool=$(git config --get diff.tool 2>/dev/null || echo "not set")
if [[ "$diff_tool" == "nvimdiff" ]]; then
  print_success "Enhanced nvimdiff configured as diff tool"
else
  print_warning "Diff tool: $diff_tool"
fi

# Check merge tool
merge_tool=$(git config --get merge.tool 2>/dev/null || echo "not set")
if [[ "$merge_tool" == "nvimdiff" ]]; then
  print_success "Enhanced nvimdiff configured as merge tool"
else
  print_warning "Merge tool: $merge_tool"
fi

# Check useful aliases
print_header "Git Aliases"
aliases_to_check=("s" "lg" "aliases" "recent")
for alias_name in "${aliases_to_check[@]}"; do
  if git config --get "alias.$alias_name" >/dev/null 2>&1; then
    print_success "Alias '$alias_name' configured"
  else
    print_warning "Alias '$alias_name' not found"
  fi
done

# Check PATH for custom tools
print_header "PATH Configuration"
if echo "$PATH" | grep -q ".local/bin"; then
  print_success "~/.local/bin in PATH"
else
  print_warning "~/.local/bin not in PATH - add to your shell configuration"
fi

# Test basic functionality
print_header "Functionality Tests"

# Test if we're in a git repo
if git rev-parse --git-dir >/dev/null 2>&1; then
  print_success "Currently in a Git repository"

  # Test some aliases
  if git config --get alias.s >/dev/null 2>&1; then
    print_info "Testing 'git s' alias..."
    if git s >/dev/null 2>&1; then
      print_success "Git aliases working"
    else
      print_warning "Git alias test failed"
    fi
  fi
else
  print_info "Not in a Git repository - some tests skipped"
fi

# Summary
print_header "Summary"
echo ""
print_info "Quick start commands:"
echo "  git s              - Short status"
echo "  git lg             - Pretty log"
echo "  git aliases        - Show all aliases"
echo "  git dt             - Enhanced diff tool"
echo "  git mt             - Enhanced merge tool"
echo "  lazygit            - Interactive Git UI"
echo ""
print_info "Shell functions (if sourced):"
echo "  gs                 - Short status"
echo "  gaf                - Interactive add with fzf"
echo "  gcof               - Interactive checkout with fzf"
echo "  glazy              - Launch lazygit"
echo "  gnb <name>         - Create and push new branch"
echo "  gclean             - Clean merged branches"
echo ""
print_info "To install Git enhancement tools:"
echo "  ./install.sh"
echo ""
print_info "To apply shell changes, restart your shell or run:"
echo "  source ~/.zshrc"
echo ""

if command_exists delta && command_exists nvim; then
  print_success "Core Git enhancements are ready!"
else
  print_warning "Some enhancements are missing. See errors above."
fi
