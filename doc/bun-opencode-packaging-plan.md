# Bun + opencode Guix Packaging Plan

Last updated: 2026-02-12
Owner: Manolis/Codex session
Status: in progress

## Objective
Package `opencode` for Guix, with Bun built from source and a clear bootstrap path (no prebuilt Bun executable in the final chain).

## Scope (current)
- Target system: `x86_64-linux`
- Working repo: `/home/manolis/repos/guix-opencode-channel`
- Main package module: `gnu/packages/opencode.scm`

## Current package chain
- `bun-stage0` (Bun 1.1.16, source tarball)
- `bun-from-source` (Bun 1.3.8, uses `bun-stage0` as builder/runtime bootstrap)
- `opencode` (uses `bun-from-source`)

## Milestones

| ID | Milestone | Status | Notes |
|---|---|---|---|
| M1 | Channel bootstrap + remote repo | DONE | `main` pushed to `ragkousism/guix-opencode-channel` |
| M2 | Move local prototypes into channel module | DONE | `gnu/packages/opencode.scm` has Bun + opencode package defs |
| M3 | Remove prebuilt Bun bootstrap executable | DONE | Replaced `bun-bootstrap` flow with source `bun-stage0` |
| M4 | Resolve Bun stage0 build blockers | IN PROGRESS | Current blockers are missing generated headers |
| M5 | Build `bun-stage0` successfully | TODO | Needed before building higher Bun stages |
| M6 | Rebuild Bun 1.3.8 via stage0 | TODO | `bun-from-source` already wired to `bun-stage0` |
| M7 | Rebuild opencode with source-built Bun chain | TODO | Package definition exists; full build pending stage0 |
| M8 | Upstream-grade hardening (offline, reproducibility, no prebuilts) | TODO | Includes eventual source-built WebKit strategy |

## What changed in this session

### 1) Added source-based stage0 package
File: `gnu/packages/opencode.scm`
- Added `bun-stage0` (version `1.1.16`) from source tarball:
  - URL: `https://github.com/oven-sh/bun/archive/refs/tags/bun-v1.1.16.tar.gz`
  - hash: `1ddacbx5nlr2qqvwhzpcv7jsk15agfd16bc2hl82slqc4z5x8ych`
- Added matching WebKit artifact input for this Bun version:
  - URL: `https://github.com/oven-sh/WebKit/releases/download/autobuild-64d04ec1a65d91326c5f2298b9c7d05b56125252/bun-webkit-linux-amd64.tar.gz`
  - hash: `01r1lbz1bl54wfs4wj8if7zzlx2603s75188yxzizq29iyvd0iky`
- Uses older Makefile flow (`make release-only`) with patched flags to reduce build pressure.

### 2) Switched Bun 1.3.8 to stage0 bootstrap
File: `gnu/packages/opencode.scm`
- `bun-from-source` now depends on `bun-stage0` (not `bun-bootstrap`).
- Kept current Bun 1.3.8 WebKit artifact input:
  - `autobuild-9a2cc42ae1bf693a...`

### 3) Verified package graph resolution
Commands run:
- `guix build -L /home/manolis/repos/guix-opencode-channel bun-stage0 --dry-run`
- `guix build -L /home/manolis/repos/guix-opencode-channel bun-from-source --dry-run`
- `guix build -L /home/manolis/repos/guix-opencode-channel opencode --dry-run`

Result:
- All three packages resolve and produce derivations.
- `bun-from-source` and `opencode` now correctly depend on `bun-stage0`.

## Current blocker details (M4)

### Blocker A: missing generated `SyntheticModuleType.h`
- Error seen during `bun-stage0` build:
  - `fatal error: 'SyntheticModuleType.h' file not found`
- Cause:
  - Bun release tarballs do not include some generated codegen headers.
- Mitigation attempted:
  - Added a build phase to generate `src/bun.js/bindings/SyntheticModuleType.h` before compilation.
- Outcome:
  - This specific header issue is resolved.

### Blocker B: missing generated `ZigGeneratedClasses+DOMClientIsoSubspaces.h`
- Next error after fixing Blocker A:
  - `fatal error: 'ZigGeneratedClasses+DOMClientIsoSubspaces.h' file not found`
- Cause:
  - Additional generated class headers are also absent from source tarball.
  - Upstream generation typically uses codegen scripts (`generate-classes.ts`) normally run with Bun tooling.
- Current state:
  - `bun-stage0` still fails in `build` phase due to this missing generated header family.

## Next actions (ordered)

1. Add a deterministic pre-build codegen step for missing ZigGeneratedClasses headers
- Generate at least:
  - `ZigGeneratedClasses+DOMClientIsoSubspaces.h`
  - `ZigGeneratedClasses+DOMIsoSubspaces.h`
  - `ZigGeneratedClasses+lazyStructureHeader.h`
  - `ZigGeneratedClasses+lazyStructureImpl.h`
- First attempt: transpile/execute `src/codegen/generate-classes.ts` via `esbuild` + `node` in the stage0 build.

2. Re-run stage0 build and collect next blocker
- Command:
  - `guix build -L /home/manolis/repos/guix-opencode-channel bun-stage0 --keep-failed`

3. When `bun-stage0` builds, validate runtime
- Commands:
  - `guix shell -L /home/manolis/repos/guix-opencode-channel bun-stage0 -- bun --version`
  - `guix shell -L /home/manolis/repos/guix-opencode-channel bun-stage0 -- bun -e 'console.log("ok")'`

4. Build Bun 1.3.8 and then opencode using full chain
- Commands:
  - `guix build -L /home/manolis/repos/guix-opencode-channel bun-from-source`
  - `guix build -L /home/manolis/repos/guix-opencode-channel opencode`

## Risks and technical notes
- WebKit is still consumed as upstream prebuilt artifact in current stage0 prototype.
  - This removes prebuilt Bun executable from the chain, but is not yet a full “everything from source” closure.
- Bun source tarballs omit generated artifacts required by older Makefile-based builds.
  - We need explicit codegen handling in Guix phases.
- Build logs are very noisy due source repacking and Makefile verbosity.
  - Use `--keep-failed` and short iterative edits.

## Handoff checklist for next session
- Open: `gnu/packages/opencode.scm`
- Focus: `bun-stage0` phases, especially pre-build codegen generation
- Re-run:
  - `guix build -L /home/manolis/repos/guix-opencode-channel bun-stage0 --keep-failed`
- Update this file after each blocker fix.
