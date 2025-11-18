#!/bin/bash
# Pushes the current branch to origin

set -e

current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Pushing branch '$current_branch' to origin..."
git push origin "$current_branch"

echo "Successfully pushed '$current_branch' to origin."
