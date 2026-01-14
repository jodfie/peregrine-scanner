# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

This repository is a Markdown-first research and tooling project for reverse engineering the Raven Document Scanner (Avision AN335W / InnoComm "Puzzle-B3"). It combines:
- A living research notebook in `docs/raven-research-notebook.md`
- A Warp-friendly APK extraction script `raven-extract.sh`
- A detailed APK extraction guide `raven-apk-extraction-warp-guide.md`
- AI/agent integration metadata under `.claude/`, `.taskmaster/`, and `.serena/`

There is currently no application source code (no Python/Go/TypeScript/etc.) and no automated test suite defined; most work is editing Markdown and Bash scripts and running Android reverse-engineering tooling.

## Key commands & workflows

### Raven APK extraction (primary script)

Core workflow is automated via `raven-extract.sh` at the repo root.

**Prerequisites (once per machine):**
- Homebrew installed
- Android platform tools (`adb`)
- Optionally: `jadx-gui`, `apktool`, and `dex2jar` for deeper analysis

You can install the basics with:

```bash
# Install Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Android platform tools
brew install --cask android-platform-tools

# Recommended analysis tools
brew install jadx apktool dex2jar
```

**Run the automated extraction script:**

```bash
chmod +x ./raven-extract.sh    # first time only
./raven-extract.sh
```

The script will:
- Ensure `adb` is available and start the ADB server
- Detect the connected Raven/scan device
- Discover candidate Raven/Avision/Innocomm packages on the device
- Let you select a package (if multiple are found)
- Pull all related APKs to `~/Desktop/raven-apk-<timestamp>/`
- Print next-step commands (JADX, APKTool, unzip) and write an `EXTRACTION_SUMMARY.txt`

**Common follow-up commands (run in the extraction directory created by the script):**

```bash
# Open extracted APK in JADX GUI
jadx-gui raven-base.apk

# Decompile with APKTool
apktool d raven-base.apk -o raven-decompiled

# Quick listing of APK contents
unzip -l raven-base.apk | head -30

# Extract native libraries
unzip raven-base.apk 'lib/*' -d native-libs
```

### Manual ADB / package discovery (from the guide)

When the automated script cannot locate the right package, the guide `raven-apk-extraction-warp-guide.md` documents a more manual flow. Key commands (typically run from anywhere):

```bash
# Start ADB and list devices
adb start-server
adb devices

# Search for likely Raven/scan packages
adb shell pm list packages -f | grep -i raven
adb shell pm list packages -f | grep -i scan
adb shell pm list packages -f | grep -i 'avision\|innocomm'

# Get APK path(s) for a known package
adb shell pm path com.raven.scanner

# Pull a specific APK path discovered above
adb pull /data/app/com.raven.scanner-XYZ/base.apk ./raven-base.apk
```

Use the guide for detailed troubleshooting (connection issues, package discovery, extraction failures, etc.) and for additional post-processing workflows (dex2jar, JD-GUI, network analysis, etc.).

### Task Master AI workflow (task management)

This repo is wired for Task Master AI–driven task management via `.taskmaster/` and `.claude/`:
- `.taskmaster/config.json` configures AI models and global Task Master settings (project name `"peregrine-scanner"`, logging, etc.).
- `.taskmaster/templates/example_prd.txt` is a template for authoring PRDs that can be parsed into structured tasks.
- `.taskmaster/CLAUDE.md` (referenced by the original `bootstrap.sh`) documents the Task Master workflow and its MCP integration.

If the Task Master CLI `task-master` is installed, the typical workflow (taken from `.taskmaster/CLAUDE.md`) is:

```bash
# One-time project setup
task-master init
cp .taskmaster/templates/example_prd.txt .taskmaster/docs/prd.txt   # create PRD (edit as needed)
task-master parse-prd .taskmaster/docs/prd.txt

# Optional: AI-driven analysis and expansion
task-master analyze-complexity --research
task-master expand --all --research

# Daily development loop
task-master list
task-master next
task-master show <id>
# ...implement work described by the task...
task-master set-status --id=<id> --status=done
```

Important Task Master concepts from `.taskmaster/CLAUDE.md`:
- Prefer using the Task Master MCP server (`task-master-ai`) when available; the CLI above is the fallback interface.
- Tasks are hierarchical (`1`, `1.1`, `1.1.1`, ...) with status values like `pending`, `in-progress`, `done`, `deferred`, `cancelled`, `blocked`.
- High-level operations include task creation (`add-task`), expansion into subtasks (`expand` / `expand --all`), dependency management (`add-dependency`, `validate-dependencies`, `fix-dependencies`), and regeneration of markdown task files (`generate`).

If you add actual code or more complex workflows to this repo, consider driving that work through Task Master tasks and keeping `.taskmaster` as the source of truth for project-level planning.

### Claude/Serena integration artifacts (for reference)

Even though Warp does not use Claude-specific configuration directly, the following files encode how other agents have been configured to work in this repo:
- `.claude/settings.json` – tool allow/deny lists and hooks. Notably, it:
  - Prefers MCP tools for code and documentation lookup.
  - Blocks direct Bash access to sensitive paths and heavy directories (e.g., `.git/`, `node_modules/`, `dist/`, `venv/`, large binary or log files) via `.claude/scripts/validate-bash.sh`.
- `.claude/skills/*` – process skills describing analysis, implementation, testing, documentation, and development guidelines. These are high-level and language-agnostic and can be treated as background context rather than strict rules.
- `.claude/TM_COMMANDS_GUIDE.md` – detailed mapping of Task Master features onto Claude slash commands under the `/project:tm/` namespace (mirroring the `task-master` CLI).
- `.serena/project.yml` – declares the project language as `markdown` and configures Serena to treat this repo as a documentation-focused project.

These artifacts are useful background when reasoning about how this repository is meant to be used (task-driven, AI-assisted research and documentation), but they do not introduce additional build/test commands beyond what is described here.

## Repository structure (high level)

Focus on these top-level areas when working in the repo:
- Root directory:
  - `raven-extract.sh` – main executable for automated APK extraction; tightly coupled with the instructions and troubleshooting sections in `raven-apk-extraction-warp-guide.md`.
  - `raven-apk-extraction-warp-guide.md` – comprehensive step-by-step reference and cookbook for APK extraction and analysis flows on macOS + Warp.
  - `README.md` – currently just a placeholder project title (`peregrine-scanner`).
  - `bootstrap.sh` – one-shot initializer for generating a `CLAUDE.md` file and committing it; it calls `claude` and self-deletes after use. Treat this as historical template scaffolding rather than something to re-run.
- `docs/`:
  - `raven-research-notebook.md` – the primary, structured research notebook capturing hardware, firmware, OS, software stack, network behaviour, and open questions about the Raven scanner.
  - `docs/wip/language-specific-skills/*` – design and implementation notes for generic language-specific skills; they come from a template and are not specific to this project’s current Markdown-only codebase.
- `.taskmaster/`:
  - `config.json` – Task Master AI configuration (models, logging and global settings) for this project.
  - `templates/example_prd.txt` – PRD template used as input to Task Master’s `parse-prd` command.
  - `CLAUDE.md` – Task Master + Claude integration doc; use it as reference for how tasks are expected to drive development.
- `.claude/` and `.serena/`:
  - Contain configuration and skills for agentic workflows in other tools; useful as design reference but not required for everyday manual use of this repo.

## Notes on tests, linting, and builds

- There is currently **no** language-specific build system (no `package.json`, `pyproject.toml`, `Makefile`, etc.) and **no automated tests** in this repository.
- If you introduce code in a particular language (e.g., Python utilities for processing APKs), you should also add the corresponding build/test/lint commands and update this `WARP.md` with:
  - How to install dependencies
  - How to run the full test suite
  - How to run a single test or focused subset
  - Any project-specific linting or formatting commands

Until then, the main "development" loop is:
1. Use `raven-extract.sh` and the documented ADB flows to acquire and decompile APKs.
2. Analyze the resulting artifacts with standard Android RE tools (JADX, APKTool, etc.).
3. Record findings and hypotheses in `docs/raven-research-notebook.md` and, where appropriate, extend or refine the instructions in `raven-apk-extraction-warp-guide.md`.
4. Optionally manage higher-level work items via Task Master (`.taskmaster`).