#!/bin/bash
# Fetches and pulls the latest changes for the current branch

set -e

echo "Fetching latest changes from origin..."
git fetch origin

current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Pulling updates for branch '$current_branch'..."
git pull origin "$current_branch"

echo "Branch '$current_branch' is up to date."
