#!/bin/bash
# Script to merge a specific version from upstream n8n into the feature branch

set -e

FEATURE_BRANCH="feat/add-workflow-execute-endpoint"
UPSTREAM_REMOTE="upstream"

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <tag-or-commit-hash>"
    echo "Example: $0 n8n@1.0.0"
    echo "Example: $0 abc123def456..."
    exit 1
fi

VERSION="$1"

echo "Merging upstream version: $VERSION"
echo "Target branch: $FEATURE_BRANCH"
echo ""

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Warning: You have uncommitted changes."
    read -p "Do you want to stash them? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash push -m "Stashed before merging upstream $VERSION"
        STASHED=true
    else
        echo "Aborting. Please commit or stash your changes first."
        exit 1
    fi
fi

# Fetch from upstream
echo "Fetching from upstream..."
git fetch "$UPSTREAM_REMOTE" --tags

# Check if the version exists
if ! git rev-parse --verify "$UPSTREAM_REMOTE/$VERSION" >/dev/null 2>&1 && ! git rev-parse --verify "$VERSION" >/dev/null 2>&1; then
    echo "Error: Version '$VERSION' not found in upstream."
    echo "Trying to fetch it directly..."
    git fetch "$UPSTREAM_REMOTE" "$VERSION" || {
        echo "Error: Could not fetch version '$VERSION' from upstream."
        exit 1
    }
fi

# Checkout feature branch
echo "Checking out feature branch: $FEATURE_BRANCH"
git checkout "$FEATURE_BRANCH" || git checkout -b "$FEATURE_BRANCH" origin/"$FEATURE_BRANCH"

# Merge the specific version
echo "Merging $VERSION from upstream..."
git merge "$VERSION" --no-edit -m "Merge upstream $VERSION into $FEATURE_BRANCH"

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    echo "Restoring stashed changes..."
    git stash pop || echo "Note: There were conflicts when restoring stashed changes. Resolve them manually."
fi

echo ""
echo "✓ Successfully merged $VERSION into $FEATURE_BRANCH"
echo "Review the changes and resolve any conflicts if needed."
