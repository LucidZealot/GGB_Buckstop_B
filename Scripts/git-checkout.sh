#!/bin/bash
# Switch to an existing branch only

set -e

read -p "Enter branch name to checkout: " branch_name

if [ -z "$branch_name" ]; then
    echo "Branch name cannot be empty."
    exit 1
fi

# Fetch latest branches first
git fetch -q

# Check for branch existence
if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git checkout "$branch_name"
elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    git checkout "$branch_name"
else
    echo "Branch '$branch_name' not found."
    exit 1
fi

echo "Now on branch '$branch_name'."
