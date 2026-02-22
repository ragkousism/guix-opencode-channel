# guix-opencode-channel

Experimental channel for packaging Bun and opencode in Guix with a
source-build bootstrap chain.

## Quick commands

```bash
guix build -L /home/manolis/repos/guix-opencode-channel bun-stage0 --dry-run
guix build -L /home/manolis/repos/guix-opencode-channel bun-from-source --dry-run
guix build -L /home/manolis/repos/guix-opencode-channel opencode --dry-run
guix build -L /home/manolis/repos/guix-opencode-channel bun-build-system-smoke --dry-run
```

## Main module

- `gnu/packages/opencode.scm`
- exports: `bun-stage0`, `bun-from-source`, `bun-build-system-smoke`, `opencode`

## Bun Build System Modules

- `guix/build-system/bun.scm`
- `guix/build/bun-build-system.scm`

## Local path overrides

- `BUN_OFFLINE_SEED_DIR` (default `/var/tmp/bun-offline-seed`)
- `OPENCODE_SOURCE_DIR` (default `/home/manolis/repos/opencode`)
- `OPENCODE_MODELS_DEV_API_JSON` (default `/tmp/models-dev-api.json`)

## Session log

Detailed status, blockers, and continuation steps are tracked in:

- `doc/bun-opencode-packaging-plan.md`
