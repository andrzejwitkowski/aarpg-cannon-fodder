## Goal

Use the upstream `CLAUDE.md` from `multica-ai/andrej-karpathy-skills` as this repo's local `AGENTS.md`, with a simple local update path.

## Scope

- Add a committed `AGENTS.md` at the repo root.
- Seed `AGENTS.md` from the upstream `CLAUDE.md` content.
- Add a small update script that re-downloads the upstream file into `AGENTS.md`.
- Add minimal usage documentation to `README.md`.

## Design

### `AGENTS.md`

Create `AGENTS.md` in the repo root. The file will contain:

- a short header noting that it is synced from the upstream repository
- the upstream guideline content copied verbatim below that header

This keeps the effective instructions in the location expected by local tooling while preserving a clear source of truth.

### Update script

Create `scripts/update-agents-md.sh`.

Behavior:

- download the raw upstream `CLAUDE.md`
- write a short generated header into local `AGENTS.md`
- append the downloaded content
- fail fast on download errors

The script should stay dependency-light and use standard shell tooling already available in this environment.

### Documentation

Add a brief note to `README.md` describing:

- why `AGENTS.md` exists
- how to refresh it using the update script

## Verification

1. Run the update script.
2. Confirm that `AGENTS.md` exists and contains the expected upstream title and principles.
3. Confirm that `README.md` points to the script path correctly.

## Non-goals

- automatic background syncing
- plugin installation or opencode config changes
- transforming the upstream content beyond a short local header
