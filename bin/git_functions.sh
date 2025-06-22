#!/usr/bin/env bash

# Git enhancement functions
# Simple, conflict-free functions with unique names
# Source this file: [ -f ~/.local/bin/git_functions.sh ] && source ~/.local/bin/git_functions.sh

# Interactive git add with fzf (if available)
git_add_interactive() {
    if command -v fzf >/dev/null 2>&1; then
        local files
        files=$(git status --porcelain | sed 's/^...//')
        if [[ -z "$files" ]]; then
            echo "No changes to add"
            return 0
        fi

        echo "$files" | \
        fzf --multi --preview 'if [[ -f {} ]]; then git diff --color=always -- {} 2>/dev/null || echo "No diff available"; else echo "File not found"; fi' | \
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                git add -- "$file"
            fi
        done
    else
        echo "fzf not available, using git add -p"
        git add -p
    fi
}

# Interactive checkout branch with fzf (if available)
git_checkout_interactive() {
    if command -v fzf >/dev/null 2>&1; then
        local branch
        branch=$(git branch --all | \
            grep -v HEAD | \
            sed 's/.* //' | \
            sed 's#remotes/[^/]*/##' | \
            sort -u | \
            fzf --preview 'git log --oneline --color=always {}')

        if [[ -n "$branch" ]]; then
            git checkout "$branch"
        fi
    else
        echo "fzf not available. Use: git checkout <branch-name>"
        git branch -vv
    fi
}

# Create and push new branch
git_new_branch() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_new_branch <branch-name>"
        return 1
    fi

    git checkout -b "$1"
    git push -u origin "$1"
}

# Delete local and remote branch safely
git_delete_branch() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_delete_branch <branch-name>"
        return 1
    fi

    echo "Deleting branch: $1"
    git branch -d "$1" 2>/dev/null || git branch -D "$1"
    git push origin --delete "$1" 2>/dev/null || echo "Remote branch doesn't exist or already deleted"
}

# Clean up merged branches (safe) - renamed to avoid oh-my-zsh conflict
git_cleanup_merged() {
    echo "Cleaning up merged branches (excluding main/master/develop)..."
    # Mac-compatible version without -r flag for xargs
    local branches=$(git branch --merged | grep -v "\*\|main\|master\|develop")
    if [[ -n "$branches" ]]; then
        echo "$branches" | while IFS= read -r branch; do
            git branch -d "$branch"
        done
    else
        echo "No merged branches to clean up"
    fi
    echo "Done!"
}

# Show file history with follow
git_file_history() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_file_history <file-path>"
        return 1
    fi

    git log --follow --patch -- "$1"
}

# Find commits that changed a file
git_file_commits() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_file_commits <file-path>"
        return 1
    fi

    git log --oneline --follow -- "$1"
}

# Show what changed in last commit
git_show_last() {
    git show --stat --summary HEAD
}

# Undo last commit (keep changes staged)
git_undo_last() {
    git reset --soft HEAD~1
    echo "Last commit undone, changes kept in staging area"
}

# Search commits by message
git_search_commits() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_search_commits <search-term>"
        return 1
    fi

    git log --oneline --grep="$1" -i
}

# Show contributors with commit counts
git_contributors() {
    git shortlog -sn --all --no-merges
}

# Launch lazygit if available
git_ui() {
    if command -v lazygit >/dev/null 2>&1; then
        lazygit
    else
        echo "lazygit not installed. Install with: go install github.com/jesseduffield/lazygit@latest"
    fi
}

# Run git setup check
git_check_setup() {
    if command -v git-setup-check >/dev/null 2>&1; then
        git-setup-check
    else
        echo "git-setup-check not found. Run ./install.sh to install Git enhancement tools"
    fi
}

# Show current branch and recent commits
git_current_status() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        echo "Current branch: $branch"
        echo ""
        git log --oneline -5
    else
        echo "Not in a git repository"
    fi
}

# Show help for Git enhancement functions
git_help() {
    echo "🚀 Git Enhancement Functions"
    echo "============================"
    echo ""
    echo "📋 Available Functions & Aliases:"
    echo "  gai  / git_add_interactive      - Interactive file staging with fzf"
    echo "  gci  / git_checkout_interactive - Interactive branch switching with fzf"
    echo "  gnb  / git_new_branch <name>    - Create and push new branch"
    echo "  gdb  / git_delete_branch <name> - Delete local and remote branch"
    echo "  gcmp / git_cleanup_merged       - Clean up merged branches"
    echo "  gfh  / git_file_history <file>  - Show file history with follow"
    echo "  gfc  / git_file_commits <file>  - Find commits that changed file"
    echo "  gsl  / git_show_last            - Show last commit details"
    echo "  gul  / git_undo_last            - Undo last commit (keep changes)"
    echo "  gsc  / git_search_commits <term> - Search commits by message"
    echo "  gcon / git_contributors         - Show contributors with commit counts"
    echo "  gui  / git_ui                   - Launch lazygit"
    echo "  gcs  / git_check_setup          - Check Git enhancement setup"
    echo "  gcur / git_current_status       - Show current branch and recent commits"
    echo "  gig  / git_create_ignore <lang> - Create gitignore file"
    echo "  git_help                        - Show this help"
    echo ""
    echo "🎯 Built-in Git Aliases (work everywhere):"
    echo "  git s       - Short status with branch info"
    echo "  git lg      - Beautiful graph log"
    echo "  git dt      - Enhanced diff tool (Delta)"
    echo "  git mt      - Enhanced merge tool (nvimdiff)"
    echo "  git aliases - Show all available Git aliases"
    echo ""
    echo "🔧 Other Tools:"
    echo "  lazygit           - Interactive Git UI"
    echo "  git-setup-check   - Verify Git enhancement setup"
    echo ""
    echo "💡 Note: Shell functions work in zsh. Use Git aliases for scripts/bash."
    echo "🍎 Mac users: Install tools with 'brew install git-delta lazygit'"
}

# Create .gitignore for language/framework using toptal API
git_create_ignore() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_create_ignore <language/framework>"
        echo "Example: git_create_ignore node"
        echo "Example: git_create_ignore python,node,go"
        return 1
    fi

    if command -v curl >/dev/null 2>&1; then
        if curl -sL "https://www.toptal.com/developers/gitignore/api/$1" >> .gitignore; then
            echo "Added $1 gitignore rules to .gitignore"
        else
            echo "Failed to download gitignore template for $1"
        fi
    else
        echo "curl not available for downloading gitignore templates"
    fi
}

# Convenient aliases for the functions (avoiding oh-my-zsh conflicts)
alias gai='git_add_interactive'
alias gci='git_checkout_interactive'
alias gnb='git_new_branch'
alias gdb='git_delete_branch'
alias gcmp='git_cleanup_merged'
alias gfh='git_file_history'
alias gfc='git_file_commits'
alias gsl='git_show_last'
alias gul='git_undo_last'
alias gsc='git_search_commits'
alias gcon='git_contributors'
alias gui='git_ui'
alias gcs='git_check_setup'
alias gcur='git_current_status'
alias gig='git_create_ignore'
alias ghelp='git_help'

# Git enhancement functions loaded silently
# Use 'git_check_setup' to see available functions
# Use Git aliases for basic operations: git s, git lg, git dt, git mt
