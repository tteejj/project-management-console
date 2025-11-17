#!/bin/bash
# Quick push script for Vector Moon Lander game

echo "======================================"
echo "PUSH VECTOR MOON LANDER TO GITHUB"
echo "======================================"
echo ""

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "game-main" ]; then
    echo "Switching to game-main branch..."
    git checkout game-main
fi

echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log --oneline -1)"
echo ""

# Get GitHub username
echo "Enter your GitHub username:"
read GITHUB_USER

echo ""
echo "======================================"
echo "STEP 1: CREATE GITHUB REPOSITORY"
echo "======================================"
echo ""
echo "Go to: https://github.com/new"
echo ""
echo "Settings:"
echo "  - Repository name: vector-moon-lander"
echo "  - Description: Spacecraft systems simulator - submarine in space"
echo "  - Public or Private: your choice"
echo "  - DO NOT check: Add a README, Add .gitignore, Choose a license"
echo ""
echo "Press ENTER after you've created the repository..."
read

echo ""
echo "======================================"
echo "STEP 2: PUSHING TO GITHUB"
echo "======================================"
echo ""

# Add remote
REPO_URL="https://github.com/$GITHUB_USER/vector-moon-lander.git"
echo "Adding remote: $REPO_URL"
git remote add game-origin "$REPO_URL" 2>/dev/null || git remote set-url game-origin "$REPO_URL"

# Push
echo ""
echo "Pushing game-main to GitHub as 'main' branch..."
git push -u game-origin game-main:main

echo ""
echo "======================================"
echo "DONE!"
echo "======================================"
echo ""
echo "Your repository is now at:"
echo "https://github.com/$GITHUB_USER/vector-moon-lander"
echo ""
echo "View it in your browser!"
