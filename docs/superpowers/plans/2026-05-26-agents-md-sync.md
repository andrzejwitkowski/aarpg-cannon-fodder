# AGENTS.md Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local `AGENTS.md` seeded from the upstream Karpathy-style `CLAUDE.md`, plus a simple script to refresh it later.

**Architecture:** Keep the repository-level instructions in a committed `AGENTS.md` so local tooling can read them directly. Use one small shell script to regenerate that file from the upstream raw GitHub URL, and document the refresh command in `README.md`.

**Tech Stack:** Markdown, POSIX shell, `curl`

---

### Task 1: Add the sync script

**Files:**
- Create: `scripts/update-agents-md.sh`

- [ ] **Step 1: Write the script**

```sh
#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_FILE="$ROOT_DIR/AGENTS.md"
SOURCE_URL="https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/CLAUDE.md"

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT INT TERM

curl -fsSL "$SOURCE_URL" -o "$TMP_FILE"

{
  printf '%s\n\n' '<!-- Synced from multica-ai/andrej-karpathy-skills: CLAUDE.md -->'
  cat "$TMP_FILE"
} > "$OUTPUT_FILE"
```

- [ ] **Step 2: Make the script executable**

Run: `chmod +x scripts/update-agents-md.sh`
Expected: command succeeds with no output

- [ ] **Step 3: Run the script**

Run: `./scripts/update-agents-md.sh`
Expected: command succeeds with no output and creates `AGENTS.md`

### Task 2: Document local usage

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the README content with a minimal usage note**

```md
# aarpg-cannon-fodder

This repo uses a local `AGENTS.md` generated from the upstream `CLAUDE.md` in `multica-ai/andrej-karpathy-skills`.

Refresh it anytime with:

```sh
./scripts/update-agents-md.sh
```
```

- [ ] **Step 2: Verify the README change**

Run: `git diff -- README.md`
Expected: diff shows the new `AGENTS.md` refresh instructions

### Task 3: Verify generated instructions

**Files:**
- Verify: `AGENTS.md`

- [ ] **Step 1: Confirm the generated header exists**

Run: `grep -n "Synced from multica-ai/andrej-karpathy-skills" AGENTS.md`
Expected: one matching line near the top of the file

- [ ] **Step 2: Confirm the upstream guideline title exists**

Run: `grep -n "# CLAUDE.md" AGENTS.md`
Expected: one matching line after the sync header

- [ ] **Step 3: Confirm the four principles are present**

Run: `grep -n "## 1. Think Before Coding\|## 2. Simplicity First\|## 3. Surgical Changes\|## 4. Goal-Driven Execution" AGENTS.md`
Expected: four matching lines
