#!/usr/bin/env bash
#
# One-line installer — downloads the latest Learn@VCS Homework Tools
# release straight from GitHub and runs its installer.
#
#     curl -fsSL https://raw.githubusercontent.com/godzilla158/homework-release/main/get.sh | bash
#
# What it does:
#   1. Fetches homework-release into a small local cache (~/.homework-src)
#      — the FIRST run clones it, every run after that just pulls whatever
#      changed since last time (no full re-download, no duplicate copies).
#   2. Hands off to that copy's own install.sh (see that file for what
#      IT does — installs/updates ~/.homework, sets up shortcuts, etc.,
#      and never touches your already-set-up classes or login).
#
set -euo pipefail

REPO_URL="https://github.com/godzilla158/homework-release.git"
CACHE_DIR="$HOME/.homework-src"

if command -v git >/dev/null 2>&1; then
  if [ -d "$CACHE_DIR/.git" ]; then
    echo "Checking for updates..."
    git -C "$CACHE_DIR" fetch --quiet origin main
    git -C "$CACHE_DIR" reset --quiet --hard origin/main
  else
    echo "Downloading Learn@VCS Homework Tools..."
    rm -rf "$CACHE_DIR"
    git clone --quiet "$REPO_URL" "$CACHE_DIR"
  fi
  SRC_DIR="$CACHE_DIR"
else
  echo "git not found — downloading a zip instead (one-time only, into a temp folder)."
  command -v curl >/dev/null 2>&1 || { echo "Need either git or curl installed. Get git from https://git-scm.com/downloads"; exit 1; }
  command -v unzip >/dev/null 2>&1 || { echo "Need 'unzip' installed."; exit 1; }
  TMP_DIR="$(mktemp -d -t homework-download)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  curl -fsSL "https://github.com/godzilla158/homework-release/archive/refs/heads/main.zip" -o "$TMP_DIR/repo.zip"
  unzip -q "$TMP_DIR/repo.zip" -d "$TMP_DIR"
  SRC_DIR="$TMP_DIR/homework-release-main"
fi

echo "Running the installer..."
bash "$SRC_DIR/install.sh"
