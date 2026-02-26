#!/usr/bin/env bash
set -euo pipefail

# create-prs.sh - Script to create PRs for versioned bun formulae

FORMULA_DIR="Formula"

git config --global user.name "BrewTestBot"
git config --global user.email "brew-test-bot@users.noreply.github.com"

for versioned_file in "${FORMULA_DIR}/bun@"*.rb; do
    if [[ -f "$versioned_file" ]]; then
        # Check if file has changes (untracked or modified)
        if [[ -z $(git status --porcelain "$versioned_file") ]]; then
            echo "No changes in $versioned_file, skipping"
            continue
        fi

        version=$(basename "$versioned_file" .rb | sed 's/bun@//')
        versioned_name="bun@${version}"
        branch="add-${versioned_name}"

        # Check if PR/branch already exists
        if ! git ls-remote --heads origin "$branch" | grep -q .; then
            git checkout -b "$branch"
            git add "$versioned_file"
            git commit -m "Add ${versioned_name} formula"
            git push -u origin "$branch"

            gh pr create \
                --title "Add ${versioned_name} formula" \
                --body "Adds versioned formula for bun ${version}" \
                --head "$branch" \
                --base main

            git checkout -
        else
            echo "Branch $branch already exists, skipping PR for $versioned_file"
        fi
    fi
done