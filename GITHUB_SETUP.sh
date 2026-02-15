#!/bin/bash

# AI Recovery Linux - GitHub Setup & Auto-Build
# This script pushes your project to GitHub and triggers the ISO build

set -euo pipefail

echo "╔════════════════════════════════════════════════════╗"
echo "║  AI Recovery Linux - GitHub Setup                  ║"
echo "╚════════════════════════════════════════════════════╝"
echo

# Check if git is installed
if ! command -v git &>/dev/null; then
    echo "ERROR: git not installed!"
    echo "Install with: brew install git"
    exit 1
fi

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USER

if [ -z "$GITHUB_USER" ]; then
    echo "ERROR: GitHub username required"
    exit 1
fi

REPO_NAME="ai-recovery-linux"
REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"

echo
echo "Setting up git repository..."
echo "Repository: $REPO_URL"
echo

# Initialize git if not already done
if [ ! -d ".git" ]; then
    git init
    echo "✓ Git initialized"
fi

# Configure git
git config user.email "builder@airecovery.local" 2>/dev/null || true
git config user.name "AI Recovery Builder" 2>/dev/null || true

# Add all files
git add .
echo "✓ Files staged"

# Create initial commit if no commits exist
if ! git rev-parse --git-dir > /dev/null 2>&1 || [ -z "$(git log -1 --oneline 2>/dev/null)" ]; then
    git commit -m "Initial commit: AI Recovery Linux Builder"
    echo "✓ Initial commit created"
else
    echo "ℹ Repository already has commits"
fi

# Set remote
if ! git remote get-url origin &>/dev/null; then
    git remote add origin "$REPO_URL"
    echo "✓ Remote added"
else
    git remote set-url origin "$REPO_URL"
    echo "✓ Remote updated"
fi

# Create main branch if needed
if ! git rev-parse --verify main &>/dev/null && ! git rev-parse --verify master &>/dev/null; then
    git branch -M main
    echo "✓ Branch set to main"
fi

echo
echo "╔════════════════════════════════════════════════════╗"
echo "║  Ready to Push!                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo

echo "Next steps:"
echo
echo "1. Create an EMPTY repository on GitHub:"
echo "   https://github.com/new"
echo "   - Name: $REPO_NAME"
echo "   - Description: AI Recovery Linux with Claude Code"
echo "   - DON'T add README or .gitignore"
echo
echo "2. Push to GitHub:"
echo "   git push -u origin main"
echo
echo "3. GitHub Actions will automatically:"
echo "   - Build the ISO on every push"
echo "   - Create a Release with the ISO file"
echo "   - You can download it from the Releases page"
echo
echo "4. View build status:"
echo "   https://github.com/$GITHUB_USER/$REPO_NAME/actions"
echo
echo "5. Download ISO from:"
echo "   https://github.com/$GITHUB_USER/$REPO_NAME/releases"
echo
