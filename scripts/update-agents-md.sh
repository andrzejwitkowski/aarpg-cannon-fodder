#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_FILE="$ROOT_DIR/AGENTS.md"
SOURCE_URL="https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/CLAUDE.md"

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT INT TERM

curl -fsSL "$SOURCE_URL" -o "$TMP_FILE"

{
  printf '%s\n' '<!-- Synced from multica-ai/andrej-karpathy-skills: CLAUDE.md -->'
  printf '%s\n\n' '<!-- Run ./scripts/update-agents-md.sh to refresh this file. -->'
  cat "$TMP_FILE"
} > "$OUTPUT_FILE"
