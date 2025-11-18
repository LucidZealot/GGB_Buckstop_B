#!/bin/bash
# Stages all changes and commits with a custom message

set -e

echo "Staging all changes..."
git add -A

echo
read -p "Enter commit message: " commit_msg

if [ -z "$commit_msg" ]; then
    echo "Commit message cannot be empty."
    exit 1
fi

git commit -m "$commit_msg"
echo "Changes committed successfully."
