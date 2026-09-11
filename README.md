# Learn@VCS Homework Tools

## Folder structure
This zip mirrors exactly how it should sit on your Mac:

```
homework/
  Scripts/
    hw.sh ai.sh hwai.sh arrange.sh map.sh clean.sh clean_all.sh info.sh setup.sh
    lib/          <- the Python that does the actual work
    automation/   <- the scheduled-run setup (run_daily, install_daily, the plist)
  Info/                   <- ALL your lesson data lives here (created by "hw")
    Future/<A1 - Class>/   "<date> future.txt" + " AI.txt" files
    Past/<A1 - Class>/     "<date> past.txt" + " AI.txt" files
    Individual/<A1 - Class>/  single days you hand-picked via "Individual class"
  Debug/                 <- debug logs
  !START HERE.txt        <- one-glance overview across all classes ("map")
```

Class folders carry a sort prefix (`0 - All Classes`, `A1 - Biology - Ms.
Chamblin`, `B4 - AP Computer Science Principles - Mr. MacMillan`, …) so
Finder lists them in schedule order.

## Quick setup (one command)

Put this folder anywhere (Downloads is fine for now), open Terminal, type
`bash ` then drag the folder onto the window and add `/install.sh`, e.g.:

```
bash ~/Downloads/homework/install.sh
```

It copies the project to `~/.homework`, adds the shortcuts, builds the
Python environment, downloads the browser, and offers to save an AI key
and install the 6 AM auto-run. Then open a new Terminal and type `hw`.
Safe to re-run. The manual steps below do the same thing by hand.

## Setup on a new machine (e.g. after transferring into VS Code)

1. Put the `homework` folder directly in your home folder — you should end up
   with `~/.homework/Scripts/...`. (It must NOT live in `~/Downloads`,
   `~/Documents`, or `~/Desktop` — macOS blocks the scheduled run from those.)

2. Open Terminal and run:
   ```
   chmod +x ~/.homework/Scripts/*.sh ~/.homework/Scripts/automation/*.sh
   ```

3. Set up the shortcuts (one time):
   ```
   echo 'alias hw="~/.homework/Scripts/hw.sh"' >> ~/.zshrc
   echo 'alias ai="~/.homework/Scripts/ai.sh"' >> ~/.zshrc
   echo 'alias hwai="~/.homework/Scripts/hwai.sh"' >> ~/.zshrc
   echo 'alias clean="~/.homework/Scripts/clean.sh"' >> ~/.zshrc
   echo 'alias clean_all="~/.homework/Scripts/clean_all.sh"' >> ~/.zshrc
   echo 'alias arrange="~/.homework/Scripts/arrange.sh"' >> ~/.zshrc
   echo 'alias map="~/.homework/Scripts/map.sh"' >> ~/.zshrc
   echo 'alias info="~/.homework/Scripts/info.sh"' >> ~/.zshrc
   echo 'alias setup="~/.homework/Scripts/setup.sh"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. First run: type `hw` in Terminal. This will:
   - Set up a Python virtual environment in `~/.homework/.venv`
   - Install Playwright automatically
   - Open a browser window for you to log into Learn@VCS
   - Save your session so future runs (mostly) won't need you to log in again

## The commands

| Command | What it does |
|---|---|
| `hw`      | Runs the scraper. First menu: **1. Future days** · **2. Past days** (every lesson day from the past week, a separate file per day) · **3. Individual class** (pick one class → it lists that class's **5 previous and 5 upcoming lesson days**; you pick ONE, only that day is fetched, into `Info/Individual/<class>/`, and opened. `ai`/`hwai` then summarize it — homework + due dates included). Then it lists every class (grouped A Day / B Day). Files land in `Info/Future/<class>/` or `Info/Past/<class>/` as `<date> future.txt` / `<date> past.txt` (plus `<date> future AI.txt` once summarized). A single class writes a plain one-class file; "All" / "today's classes" writes the A Day / B Day period layout. A chapter spanning an A **and** B day (e.g. "September 8/9") is named `Sep 08-09 future.txt` and shows both days in its heading |
| `ai`      | Summarizes a saved file with AI. Uses Claude if `ANTHROPIC_API_KEY` is set, otherwise Google Gemini if `GEMINI_API_KEY` is set (see below). Skips work if the summary is already up to date — pass `--force` to redo |
| `hwai`    | Runs `hw`, then summarizes **every** date it just pulled — all at once, in parallel (reads `.last_run_dates.txt`) |
| `clean`   | Deletes lesson/AI files older than 3 days from every `Info/Future` and `Info/Past` class folder, then rebuilds the `Info/` view. `clean "Algebra I"` instead wipes that one class's files (loose name match; the empty browse-placeholder folder stays) |
| `clean_all` | **Deletes all data** — empties `Info/` and `Debug/`, removes the overview and run markers. Keeps `Scripts/`, the root `.sh` scripts, `README.md`, `dist/`, your login, and the empty `Info/` skeleton. Type "delete" to confirm, or `clean_all --yes` |
| `arrange` | Renames date files with a rank prefix so Finder sorts newest-first |
| `map`     | Writes `!START HERE.txt` — a **⚠️ UPCOMING TESTS & DEADLINES** board pulled from every AI summary (soonest first), then a per-class list of what's on disk |
| `info`    | Rebuilds the `Info/` folder (skeleton, migrates leftovers, drops stray empty folders) and opens it in Finder. (Shadows the rarely-used GNU `info` reader in your shell.) |
| `setup`   | Runs the Class Setup Wizard — add/redo your classes, teachers, course ids, and A/B-day schedule. Runs automatically on a fresh install; re-run any time |

### Environment toggles for `hw`
- `VCS_MODE=future|past|individual` — skip the first menu
- `VCS_COURSES=today|all|A|B` — skip the class menu (ignored for `individual`)
- `VCS_HEADLESS=0` — show the browser window (default is headless)
- `VCS_DAY_TYPE=A|B` — override the auto A/B-day guess on holidays/odd weeks
- `VCS_DAYS_BACK=N` — how many days back "Past days" looks (default 7)

## Automatic weekday-morning run (optional)
```
~/.homework/Scripts/automation/install_daily.sh
```
Schedules `hw` (today's classes) → `ai` → `arrange` → `map` every weekday at
6:00 AM so the summary is waiting when you wake up. Log:
`Debug/daily-run.log`. Remove with `install_daily.sh uninstall`.

This works because the project lives in `~/.homework` — a folder macOS lets
background jobs touch. If you ever move it into `~/Downloads`, `~/Documents`,
or `~/Desktop`, the 6 AM run will fail with "Operation not permitted" in
`Debug/launchd.err.log` (running the commands yourself from Terminal still
works). The fix is to move it back to `~/.homework`.

## Setting up the AI summary (optional)
1. Get a free key at https://aistudio.google.com/apikey (no credit card needed)
2. Run:
   ```
   echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshrc
   source ~/.zshrc
   ```

## Setting up your classes
First install (or any time `vcs_schedule.json` has no classes in it),
`install.sh` runs the **Class Setup Wizard** for you — it asks for each
class's name, teacher, Learn@VCS course id, and A/B day/period, plus the
A/B-day anchor date, and writes `Scripts/lib/vcs_schedule.json`. Run it
again any time with:
```
setup
```
(backs up the old file to `vcs_schedule.json.bak` first). To find a
course id: open the class in Learn@VCS and read the `?id=NNNN` in the
URL. You can also hand-edit `Scripts/lib/vcs_schedule.json` directly —
every command (`hw`, `ai`, `arrange`, `map`) reads whichever you did
last.

## Menu-bar app (optional)

`Scripts/app/homework_app.py` is a small macOS menu-bar app (📚 in the top
bar) that runs the same commands from a menu instead of the terminal:
*Get homework ▸ Today's / All / Past week*, *Summarize latest*, *Fetch +
summarize*, plus shortcuts to open the results folder / overview / last
log and a toggle for the 6 AM auto-run. It's a launcher only — it drives
the scripts at `~/.homework`, so run `install.sh` first.

Try it:
```
~/.homework/.venv/bin/pip install rumps
~/.homework/.venv/bin/python ~/.homework/Scripts/app/homework_app.py
```

Build a double-clickable app:
```
bash build_app.sh          # -> dist/Homework.app
```
Set `DEV_ID` (and `NOTARY_PROFILE`) env vars before running it to also
codesign + notarize and produce `dist/Homework.dmg`. See the comments at
the top of `build_app.sh`.

## Notes
- Your login session lives in `~/.vcshomework/` (browser profile + saved
  cookies) — outside the project so it survives a move or re-download.
- The Python virtualenv is `~/.homework/.venv` (created on first `hw`).
- The project is a git repo — `git log` shows the history, `git checkout .`
  undoes local changes.
- All the scripts are self-contained Python (standard library only, aside
  from Playwright for `hw`/`hwai`).
