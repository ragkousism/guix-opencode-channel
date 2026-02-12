# Guix Opencode Channel (local)

Local channel for iterative Bun/opencode packaging work.

## Use with -L

```bash
guix build -L /home/manolis/repos/guix-opencode-channel \
  -e '(@@ (gnu packages opencode) opencode)'
```

## Optional path overrides

- `BUN_OFFLINE_SEED_DIR` (default `/var/tmp/bun-offline-seed`)
- `OPENCODE_SOURCE_DIR` (default `/home/manolis/repos/opencode`)
- `OPENCODE_MODELS_DEV_API_JSON` (default `/tmp/models-dev-api.json`)
