#!/bin/sh
# Fetch content-scope-scripts from Git repository with shallow clone and caching
# This script is optimized for speed, especially for repositories with long history
# Reads configuration from content-scope-scripts-config.json

set -e  # Exit on error

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration file path
CONFIG_FILE="${SCRIPT_DIR}/content-scope-scripts-config.json"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at: ${CONFIG_FILE}" >&2
    exit 1
fi

# Parse JSON config using Python (available on macOS)
# Extract repoURL, branch, tag, sourcePath
CONFIG_JSON=$(python3 -c "
import json
import sys
try:
    with open('${CONFIG_FILE}', 'r') as f:
        config = json.load(f)
    repo_url = config.get('repoURL', 'https://github.com/duckduckgo/content-scope-scripts.git')
    branch = config.get('branch')
    tag = config.get('tag')
    source_path = config.get('sourcePath', 'build/apple')
    
    # Determine reference
    if branch and branch != 'null' and branch != '':
        reference = branch
        ref_type = 'branch'
    elif tag and tag != 'null' and tag != '':
        reference = tag
        ref_type = 'tag'
    else:
        print('Error: Must specify branch or tag in config file', file=sys.stderr)
        sys.exit(1)
    
    print(f'{repo_url}|{reference}|{ref_type}|{source_path}')
except Exception as e:
    print(f'Error parsing config file: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1)

if [ $? -ne 0 ]; then
    echo "$CONFIG_JSON" >&2
    exit 1
fi

# Split the output
REPO_URL=$(echo "$CONFIG_JSON" | cut -d'|' -f1)
REFERENCE=$(echo "$CONFIG_JSON" | cut -d'|' -f2)
REFERENCE_TYPE=$(echo "$CONFIG_JSON" | cut -d'|' -f3)
SOURCE_PATH=$(echo "$CONFIG_JSON" | cut -d'|' -f4)

# Resources directory path
RESOURCES_DIR="${PACKAGE_DIR}/Sources/ContentScopeScripts/Resources"

# Create Resources directory if it doesn't exist
mkdir -p "$RESOURCES_DIR"

# Cache directory for git clones (outside plugin work dir to persist across builds)
CACHE_BASE_DIR="${TMPDIR:-/tmp}/spm-content-scope-scripts-cache"
mkdir -p "$CACHE_BASE_DIR"

# Create a cache key based on repo URL and reference
# Use a hash to avoid filesystem issues with special characters
CACHE_KEY=$(echo -n "${REPO_URL}${REFERENCE}" | shasum -a 256 | cut -d' ' -f1)
CACHE_DIR="${CACHE_BASE_DIR}/${CACHE_KEY}"
CLONE_DIR="${CACHE_DIR}/repo"

# Function to check if cached repo is valid
check_cache_valid() {
    if [ ! -d "$CLONE_DIR/.git" ]; then
        return 1  # Cache invalid
    fi
    
    # Check if the reference exists in the cached repo
    cd "$CLONE_DIR"
    
    case "$REFERENCE_TYPE" in
        "branch")
            # Check if branch exists and is up to date
            if git rev-parse --verify "origin/${REFERENCE}" >/dev/null 2>&1; then
                git fetch --depth 1 origin "${REFERENCE}" >/dev/null 2>&1 || return 1
                git checkout -f "${REFERENCE}" >/dev/null 2>&1 || return 1
                return 0
            fi
            return 1
            ;;
        "tag")
            # Check if tag exists and matches
            if git rev-parse --verify "refs/tags/${REFERENCE}" >/dev/null 2>&1; then
                # Fetch latest to ensure tag is up to date
                git fetch --depth 1 origin "refs/tags/${REFERENCE}:refs/tags/${REFERENCE}" >/dev/null 2>&1 || true
                git checkout -f "${REFERENCE}" >/dev/null 2>&1 || return 1
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check network connectivity
check_network() {
    if ! command -v ping >/dev/null 2>&1; then
        # If ping is not available, try a simple DNS lookup
        if ! host github.com >/dev/null 2>&1; then
            return 1
        fi
    else
        # Quick connectivity check (timeout after 2 seconds)
        if ! ping -c 1 -W 2000 github.com >/dev/null 2>&1; then
            return 1
        fi
    fi
    return 0
}

# Function to clone repository
clone_repo() {
    echo "Cloning repository (shallow clone, depth=1)..." >&2
    
    # Check network connectivity first
    if ! check_network; then
        echo "Error: Network connectivity check failed. Cannot reach github.com" >&2
        echo "Please check your internet connection and try again." >&2
        exit 1
    fi
    
    # Remove old cache if it exists
    rm -rf "$CLONE_DIR"
    mkdir -p "$CACHE_DIR"
    
    # Perform shallow clone based on reference type
    case "$REFERENCE_TYPE" in
        "branch")
            # Shallow clone specific branch
            if ! git clone --depth 1 --branch "${REFERENCE}" --single-branch "${REPO_URL}" "$CLONE_DIR" 2>&1; then
                echo "Error: Failed to clone branch '${REFERENCE}' from ${REPO_URL}" >&2
                echo "Please verify:" >&2
                echo "  1. The branch '${REFERENCE}' exists in the repository" >&2
                echo "  2. You have network connectivity" >&2
                echo "  3. The repository URL is correct" >&2
                exit 1
            fi
            ;;
        "tag")
            # For tags, try to clone with the tag directly first (fastest)
            # If that fails, fall back to cloning default branch then fetching tag
            if git clone --depth 1 --branch "${REFERENCE}" --single-branch "${REPO_URL}" "$CLONE_DIR" 2>&1; then
                # Success with direct tag clone
                :
            else
                # Fallback: clone default branch, then fetch and checkout tag
                echo "Direct tag clone failed, using fallback method..." >&2
                rm -rf "$CLONE_DIR"
                if ! git clone --depth 50 "${REPO_URL}" "$CLONE_DIR" 2>&1; then
                    echo "Error: Failed to clone repository from ${REPO_URL}" >&2
                    echo "Please verify:" >&2
                    echo "  1. You have network connectivity" >&2
                    echo "  2. The repository URL is correct" >&2
                    echo "  3. The tag '${REFERENCE}' exists in the repository" >&2
                    exit 1
                fi
                cd "$CLONE_DIR"
                # Fetch the specific tag
                if ! git fetch --depth 1 origin "refs/tags/${REFERENCE}:refs/tags/${REFERENCE}" 2>&1; then
                    # If shallow fetch fails, fetch more history
                    echo "Shallow tag fetch failed, fetching more history..." >&2
                    git fetch --unshallow 2>&1 || true
                    if ! git fetch origin "refs/tags/${REFERENCE}:refs/tags/${REFERENCE}" 2>&1; then
                        echo "Error: Failed to fetch tag '${REFERENCE}'" >&2
                        echo "Please verify the tag exists in the repository." >&2
                        exit 1
                    fi
                fi
                if ! git checkout -f "${REFERENCE}" 2>&1; then
                    echo "Error: Failed to checkout tag '${REFERENCE}'" >&2
                    exit 1
                fi
            fi
            ;;
        *)
            echo "Error: Unknown reference type: ${REFERENCE_TYPE}. Must be 'branch' or 'tag'" >&2
            exit 1
            ;;
    esac
}

# Function to copy files from repo to Resources directory
copy_files() {
    echo "Copying files from ${SOURCE_PATH} to ${RESOURCES_DIR}..." >&2
    
    SOURCE_DIR="${CLONE_DIR}/${SOURCE_PATH}"
    
    # Check if source path exists
    if [ ! -d "$SOURCE_DIR" ] && [ ! -f "$SOURCE_DIR" ]; then
        echo "Error: Source path does not exist: ${SOURCE_PATH}" >&2
        echo "Available paths in repository root:" >&2
        ls -la "$CLONE_DIR" | head -20 >&2
        exit 1
    fi
    
    # Remove all existing files and directories in Resources folder
    if [ -d "$RESOURCES_DIR" ]; then
        echo "Cleaning existing files in Resources directory..." >&2
        rm -rf "${RESOURCES_DIR:?}"/*
        # Also remove hidden files (like .DS_Store)
        find "$RESOURCES_DIR" -mindepth 1 -delete 2>/dev/null || true
    fi
    
    # Ensure Resources directory exists
    mkdir -p "$RESOURCES_DIR"
    
    # Copy contents of source directory to Resources directory
    # This copies the contents, not the directory itself
    if [ -d "$SOURCE_DIR" ]; then
        # Copy all contents from source directory to Resources directory
        # Using rsync for better control, fallback to cp if not available
        if command -v rsync >/dev/null 2>&1; then
            rsync -a "${SOURCE_DIR}/" "${RESOURCES_DIR}/"
        else
            # Copy all files and subdirectories
            cp -R "${SOURCE_DIR}/"* "${RESOURCES_DIR}/" 2>/dev/null || {
                # If that fails (maybe empty directory), try copying directory contents differently
                for item in "${SOURCE_DIR}"/*; do
                    [ -e "$item" ] && cp -R "$item" "$RESOURCES_DIR/"
                done
            }
        fi
    else
        # If it's a single file, copy it to Resources directory
        cp "$SOURCE_DIR" "$RESOURCES_DIR/"
    fi
    
    echo "Successfully copied files to ${RESOURCES_DIR}" >&2
}

# Main execution
echo "Fetching content-scope-scripts..." >&2
echo "  Repository: ${REPO_URL}" >&2
echo "  Reference: ${REFERENCE} (${REFERENCE_TYPE})" >&2
echo "  Source path: ${SOURCE_PATH}" >&2
echo "  Target Resources directory: ${RESOURCES_DIR}" >&2
echo "  Cache directory: ${CACHE_DIR}" >&2

# Check if we can use cached version
if check_cache_valid; then
    echo "Using cached repository..." >&2
else
    echo "Cache invalid or missing, cloning repository..." >&2
    clone_repo
fi

# Copy files to target directory
copy_files

echo "✅ Content-scope-scripts fetched successfully!" >&2
