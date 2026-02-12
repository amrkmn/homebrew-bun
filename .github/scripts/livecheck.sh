#!/usr/bin/env bash
set -euo pipefail

# livecheck.sh - Script to handle version archiving and creating versioned formulae for bun

MAIN_FORMULA="Formula/bun.rb"
FORMULA_DIR="Formula"

create_archive_formula() {
  local version="$1"
  local versioned_name="bun@${version}"
  local versioned_file="${FORMULA_DIR}/${versioned_name}.rb"
  
  if [[ -f "$versioned_file" ]]; then
    echo "Versioned formula $versioned_file already exists, skipping"
    return 0
  fi
  
  echo "Archiving current version to $versioned_file"
  cp "$MAIN_FORMULA" "$versioned_file"
  
  local class_suffix=$(echo "$version" | tr -d '.-')
  sed -i "s/class Bun /class BunAT${class_suffix} /" "$versioned_file"
  
  echo "Successfully created $versioned_file"
}

create_new_formula() {
  local version="$1"
  local versioned_name="bun@${version}"
  local versioned_file="${FORMULA_DIR}/${versioned_name}.rb"
  
  if [[ -f "$versioned_file" ]]; then
    echo "Versioned formula $versioned_file already exists, skipping"
    return 0
  fi
  
  echo "Creating new version formula $versioned_file"
  cp "$MAIN_FORMULA" "$versioned_file"
  
  local class_suffix=$(echo "$version" | tr -d '.-')
  sed -i "s/class Bun /class BunAT${class_suffix} /" "$versioned_file"
  
  # Update URL
  local new_url="https://registry.npmjs.org/bun/-/bun-${version}.tgz"
  echo "Updating URL to $new_url"
  sed -i "s|url \".*\"|url \"${new_url}\"|" "$versioned_file"
  
  # Calculate SHA256
  echo "Fetching $new_url to calculate SHA256..."
  local sha256
  sha256=$(curl -sL --fail "$new_url" | sha256sum | awk '{print $1}')
  
  if [[ -z "$sha256" ]]; then
    echo "Error: Failed to download or calculate SHA256 for $new_url"
    rm -f "$versioned_file"
    return 1
  fi
  
  echo "SHA256: $sha256"
  sed -i "s/sha256 \".*\"/sha256 \"${sha256}\"/" "$versioned_file"
  
  # Remove bottle block since old bottles won't work with new version
  sed -i '/bottle do/,/end/d' "$versioned_file"
  
  echo "Successfully created $versioned_file"
}

main() {
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
  fi

  # Check if input is from pipe
  if [[ -t 0 ]]; then
    echo "Error: This script expects JSON input from livecheck via stdin" >&2
    echo "Usage: brew livecheck --tap=\"\$GITHUB_REPOSITORY\" --json | ./livecheck.sh" >&2
    exit 1
  fi
  
  # Use a temporary file to store the input to avoid pipe subshell issues
  local input_file=$(mktemp)
  cat > "$input_file"
  
  # Iterate over the JSON array
  jq -c '.[] | select(.status != "skipped") | select(.version.latest != .version.current)' "$input_file" | while read -r formula; do
    local name
    name=$(echo "$formula" | jq -r '.formula')
    local current_ver
    current_ver=$(echo "$formula" | jq -r '.version.current')
    local new_ver
    new_ver=$(echo "$formula" | jq -r '.version.latest')
    
    # Only process 'bun' formula
    if [[ "$name" != "bun" ]]; then
      continue
    fi
    
    echo "Processing bun update: $current_ver -> $new_ver"
    
    # 1. Archive the current (old) version
    create_archive_formula "$current_ver"
    
    # 2. Create the new version formula
    create_new_formula "$new_ver"
  done
  
  rm -f "$input_file"
}

main "$@"
