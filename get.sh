#!/usr/bin/env bash
#
# One-line installer — downloads the latest Learn@VCS Homework Tools
# release straight from GitHub and runs its installer.
#
#     curl -fsSL https://raw.githubusercontent.com/godzilla158/homework-release/main/get.sh | bash
#
# What it does:
#   1. Downloads the homework-release repo into a temp folder
#   2. Hands off to that copy's own install.sh (see that file for what
#      IT does — installs to ~/.homework, sets up shortcuts, etc.)
#
set -euo pipefail

REPO_URL="https://github.com/godzilla158/homework-release.git"
TMP_DIR="$(mktemp -d -t homework-download)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Downloading Learn@VCS Homework Tools..."
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 "$REPO_URL" "$TMP_DIR/homework-release" --quiet
else
  echo "git not found — downloading a zip instead."
  command -v curl >/dev/null 2>&1 || { echo "Need either git or curl installed. Get git from https://git-scm.com/downloads"; exit 1; }
  curl -fsSL "https://github.com/godzilla158/homework-release/archive/refs/heads/main.zip" -o "$TMP_DIR/repo.zip"
  command -v unzip >/dev/null 2>&1 || { echo "Need 'unzip' installed."; exit 1; }
  unzip -q "$TMP_DIR/repo.zip" -d "$TMP_DIR"
  mv "$TMP_DIR"/homework-release-main "$TMP_DIR/homework-release"
fi

echo "Running the installer..."
bash "$TMP_DIR/homework-release/install.sh"
