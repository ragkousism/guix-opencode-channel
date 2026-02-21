# Bun Build System Roadmap

## Goal

Introduce a reusable `bun-build-system` in Guix so Bun-based packages can be
packaged like `node-build-system`/`maven-build-system`, instead of embedding
custom Bun logic in each package definition.

## Scope

- Provide a first-class build system for Bun projects.
- Keep builds reproducible and offline.
- Support single-package projects first, then Bun workspaces.
- Keep `opencode` as the primary proving ground.

## Non-goals (initial phase)

- Full cross-compilation support.
- Solving every Bun workspace edge-case in v1.
- Replacing `node-build-system`.

## Proposed Architecture

### New modules

- `guix/build-system/bun.scm`
- `guix/build/bun-build-system.scm`

### Design approach

- Model `lower` and implicit input handling after
  `guix/build-system/node.scm`.
- Model build-side phase plumbing after
  `guix/build/node-build-system.scm`.
- Keep the implementation as a `gnu-build-system` extension.

### Initial API surface (draft)

- `bun-build-system`
- Parameters:
  - `bun` (default Bun package)
  - `bun-flags`
  - `bun-install-flags`
  - `test-target`
  - `tests?`
  - `phases`
- Optional offline parameters (v1.1+):
  - `offline-cache`
  - `lockfile-mode`
  - `workspace-root`

## Phase Plan

### Phase 0: Channel safety and cleanup (done)

- Remove channel-evaluation dependency on local host paths.
- Keep local developer overrides available through env vars.

Exit criteria:

- `guix pull` can evaluate the channel on machines that do not have
  `/home/manolis/repos/opencode`.

### Phase 1: Bun build-system skeleton

- Add `guix/build-system/bun.scm` with:
  - `%bun-build-system-modules`
  - `lower`
  - `bun-build`
  - `bun-build-system`
- Add `guix/build/bun-build-system.scm` with initial `%standard-phases`.

Exit criteria:

- A minimal Bun package builds through `bun-build-system`.

### Phase 2: Offline-first dependency workflow

- Implement deterministic install phase behavior.
- Prevent network access in build phases.
- Make lockfile behavior explicit and reproducible.

Exit criteria:

- Package builds succeed without network and without runtime fetching.

### Phase 3: Workspace support (opencode target)

- Add workspace-aware dependency restoration hooks.
- Add optional phase helpers for package-local grafting/symlink restoration.
- Reduce package-specific shell glue in `gnu/packages/opencode.scm`.

Exit criteria:

- `opencode` package uses mostly generic `bun-build-system` behavior.

### Phase 4: Upstream readiness

- Write build-system documentation in the Guix manual style.
- Split `opencode` hacks into justified patches or generic helpers.
- Minimize lint warnings and ensure code style matches upstream conventions.

Exit criteria:

- Patch series is reviewable upstream as:
  1. build-system introduction,
  2. package conversions,
  3. follow-up fixes.

## Review Risks and Mitigations

- Risk: Bun behavior changes quickly between releases.
  - Mitigation: pin Bun version for build-system bootstrapping and keep phase
    API minimal at first.
- Risk: workspace dependency layouts differ between projects.
  - Mitigation: expose extension points in phases and implement conservative
    defaults.
- Risk: large generated assets hurt reproducibility/CI time.
  - Mitigation: prefer source generation with deterministic inputs and avoid
    prebuilt blobs.

## Immediate Next Steps

1. Land the channel-safety fix.
2. Scaffold `bun-build-system` modules with no-op/default phases.
3. Add one tiny Bun package using the new build system as a smoke test.
4. Move one `opencode` preparation step into reusable Bun phase helpers.
