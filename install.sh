#!/usr/bin/env bash
#
# Learn@VCS Homework Tools — one-time installer
# =============================================
# Hand someone this whole folder (a zip is fine). They open Terminal,
# drag the folder in after typing `bash `, and press Return — e.g.:
#
#     bash ~/Downloads/homework/install.sh
#
# It will, automatically, with no prompts:
#   1. Put the project at ~/.homework (macOS requires this exact spot for
#      the 6 AM auto-run to work)
#   2. Make the scripts executable
#   3. Add the `hw` / `ai` / `hwai` / `clean` / ... shortcuts to ~/.zshrc
#   4. Build the Python environment and download the headless browser
#      (shown as one clean progress line, not the raw download output)
#   5. Install the weekday 6 AM auto-run
#
# Safe to run again later — it only adds what's missing.

set -euo pipefail

TARGET="$HOME/.homework"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC="$HOME/.zshrc"
MARKER_BEGIN="# >>> Learn@VCS Homework Tools >>>"
MARKER_END="# <<< Learn@VCS Homework Tools <<<"

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
die()  { printf '\n\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- checks
[ "$(uname)" = "Darwin" ] || die "This installer is for macOS."
command -v python3 >/dev/null 2>&1 || die \
  "python3 is not installed. Get it from https://www.python.org/downloads/ (or 'brew install python'), then re-run."

say "Learn@VCS Homework Tools installer"
info "From : $SOURCE_DIR"
info "To   : $TARGET"

# ------------------------------------------------------- copy into place
# Safe to re-run any time: only NEW/CHANGED code files get copied over
# (rsync skips ones that already match), nothing gets duplicated, and your
# real vcs_schedule.json / license.key / saved data are never touched —
# they're excluded below and never overwritten by a later run.
if [ "$SOURCE_DIR" = "$TARGET" ]; then
  info "Already running from ~/.homework — nothing to copy."
else
  ALREADY_INSTALLED=0
  [ -e "$TARGET" ] && ALREADY_INSTALLED=1
  mkdir -p "$TARGET"
  # Copy code + docs only; skip generated data, caches, any login, and
  # (critically) the buyer's own already-customized vcs_schedule.json —
  # that one's handled separately below so a second run can't wipe it.
  rsync -a --delete \
    --exclude '.git' --exclude '.venv' --exclude 'Debug' \
    --exclude '.last_run_*' --exclude '.gemini_model.txt' \
    --exclude 'Scripts/lib/vcs_schedule.json' \
    --exclude 'license.key' --exclude '.usage.json' --exclude '.usage.lock' \
    "$SOURCE_DIR/Scripts" "$SOURCE_DIR/README.md" "$TARGET/" 2>/dev/null \
    || { cp -R "$SOURCE_DIR/Scripts" "$TARGET/"; cp "$SOURCE_DIR/README.md" "$TARGET/" 2>/dev/null || true; }
  # First install only: seed the empty template. A later run leaves an
  # existing vcs_schedule.json (your real classes) completely alone.
  if [ ! -f "$TARGET/Scripts/lib/vcs_schedule.json" ]; then
    cp "$SOURCE_DIR/Scripts/lib/vcs_schedule.json" "$TARGET/Scripts/lib/vcs_schedule.json" 2>/dev/null || true
  fi
  if [ "$ALREADY_INSTALLED" = "1" ]; then
    info "Updated ~/.homework with what's new (your classes/setup/login were left alone)."
  else
    info "Copied Scripts/ and README.md into ~/.homework."
  fi
fi

# --------------------------------------------------------- executable bits
chmod +x "$TARGET"/Scripts/*.sh "$TARGET"/Scripts/automation/*.sh 2>/dev/null || true
info "Made the scripts executable."

# --------------------------------------------------------------- aliases
if grep -qF "$MARKER_BEGIN" "$ZSHRC" 2>/dev/null; then
  info "Shortcuts already in ~/.zshrc — leaving them."
else
  say "Adding shortcuts to ~/.zshrc"
  {
    echo ""
    echo "$MARKER_BEGIN"
    echo 'alias hw="~/.homework/Scripts/hw.sh"'
    echo 'alias ai="~/.homework/Scripts/ai.sh"'
    echo 'alias hwai="~/.homework/Scripts/hwai.sh"'
    echo 'alias clean="~/.homework/Scripts/clean.sh"'
    echo 'alias clean_all="~/.homework/Scripts/clean_all.sh"'
    echo 'alias arrange="~/.homework/Scripts/arrange.sh"'
    echo 'alias map="~/.homework/Scripts/map.sh"'
    echo 'alias info="~/.homework/Scripts/info.sh"'
    echo 'alias setup="~/.homework/Scripts/setup.sh"'
    echo "$MARKER_END"
  } >> "$ZSHRC"
  info "Added hw / ai / hwai / clean / clean_all / arrange / map / info / setup."
fi

# ----------------------------------------------------- python environment
say "Setting up (first time only, ~1-2 min)"
cd "$TARGET"
[ -d .venv ] || python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

# Runs everything (pip upgrade, playwright install, chromium download —
# normally a wall of scrolling percentage bars) in the background, quietly,
# and shows one clean progress line instead. Full output still goes to a
# log file, so a real failure is never silently hidden.
PROGRESS_LOG="$(mktemp -t homework-install-log)"
(
  pip install --upgrade pip --quiet
  python -c "import playwright" 2>/dev/null || pip install playwright --quiet
  python -m playwright install chromium
  touch ".venv/.pw-ready"
) > "$PROGRESS_LOG" 2>&1 &
INSTALL_PID=$!

SPIN='|/-\'
START_TS=$(date +%s)
i=0
while kill -0 "$INSTALL_PID" 2>/dev/null; do
  i=$(( (i + 1) % 4 ))
  ELAPSED=$(( $(date +%s) - START_TS ))
  printf "\r  [%s] Downloading and preparing... (%ds)   " "${SPIN:$i:1}" "$ELAPSED"
  sleep 0.2
done
wait "$INSTALL_PID" && INSTALL_STATUS=0 || INSTALL_STATUS=$?
printf "\r  Python environment ready.                          \n"

if [ "$INSTALL_STATUS" -ne 0 ]; then
  printf '\n\033[31mERROR:\033[0m Setup failed — full log below:\n\n' >&2
  cat "$PROGRESS_LOG" >&2
  exit 1
fi
rm -f "$PROGRESS_LOG"

# ------------------------------------------------------- first-run classes
# A fresh install (or the obfuscated release build) ships with an EMPTY
# course list — nothing to scrape until you tell it your classes.
NEEDS_SETUP=$(python - <<'PY'
import json, sys
try:
    with open("Scripts/lib/vcs_schedule.json", encoding="utf-8") as f:
        cfg = json.load(f)
    print("yes" if not cfg.get("courses") else "no")
except Exception:
    print("no")
PY
)
if [ "$NEEDS_SETUP" = "yes" ]; then
  say "Let's set up your classes"
  if [ -t 0 ]; then
    python "$TARGET/Scripts/lib/setup_wizard.py"
  else
    info "No terminal input available here — run 'setup' (or Scripts/setup.sh) before using 'hw'."
  fi
fi

# ------------------------------------------------------- license key
say "License key"
info "hw, hwai, and ai need a license key to run. Get one, then activate it with:"
info "  setup --license"

# --------------------------------------------------- weekday 6 AM auto-run
say "Weekday 6:00 AM auto-run"
"$TARGET/Scripts/automation/install_daily.sh" > /dev/null 2>&1 \
  && info "Installed — homework will be fetched automatically every weekday morning." \
  || info "Couldn't install it automatically — run later with: ~/.homework/Scripts/automation/install_daily.sh"
info "Turn it off any time with: ~/.homework/Scripts/automation/install_daily.sh uninstall"

# ---------------------------------------------------------------- done
say "Done!"
cat <<EOF
  1. Close this Terminal window and open a new one (loads the shortcuts),
     or run:  source ~/.zshrc
  2. Type:   hw
     First run opens a browser so you can log in to Learn@VCS once.
  3. Classes / schedule wrong or need changing? Run:  setup
     (or edit ~/.homework/Scripts/lib/vcs_schedule.json directly)
EOF
