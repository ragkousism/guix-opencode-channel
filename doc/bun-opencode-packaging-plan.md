# Bun + opencode Guix Packaging Plan

Last updated: 2026-02-12
Owner: current Codex session
Status: in progress

## Objective
Build and package `opencode` from source in Guix, with `bun` also built from source (no runtime dependency on prebuilt upstream binaries).

## Non-goals
- Porting opencode to Node/Deno.
- Publishing to channels in this session.
- Multi-platform support in first iteration (target: `x86_64-linux`).

## Constraints
- opencode currently depends on `bun@1.3.8` (from `package.json`).
- opencode build and runtime use Bun-specific APIs.
- Guix builds should be offline during normal derivation builds.
- Any bootstrap exception must be explicit, temporary, and documented.

## Strategy Summary
1. Bring up a temporary `bun-bootstrap` package to run Bun build tooling.
2. Build `bun-from-source` with Guix-managed, pinned inputs and patched offline build flow.
3. Rebuild/validate bun reproducibly.
4. Switch opencode package to use `bun-from-source`.
5. Validate complete source build chain.

## Milestones

| ID | Milestone | Deliverable | Status |
|---|---|---|---|
| M1 | Tracking + design baseline | This document + explicit work breakdown | DONE |
| M2 | Bun build graph inventory | List of all fetch points and replacement plan | DONE |
| M3 | Bootstrap package | `bun-bootstrap` package expression builds in Guix | DONE |
| M4 | Bun source package | `bun-from-source` builds from source with pinned inputs | DONE (prototype) |
| M5 | Bun reproducibility | `--check --rounds=2` + smoke validation | TODO |
| M6 | opencode integration | `opencode` package builds using `bun-from-source` | DONE (prototype) |
| M7 | Handoff-ready state | Risk log, known gaps, continuation commands | IN PROGRESS |

## Detailed Work Plan

### M2 - Bun Build Graph Inventory
- Record all Bun build-time network fetchers and where they are triggered:
  - Zig compiler fetch (`SetupZig.cmake` / `DownloadZig.cmake`).
  - WebKit artifact fetch (`SetupWebKit.cmake`) or local WebKit build path.
  - Node headers tarball fetch (`BuildBun.cmake`).
  - Dependency git clones (`register_repository` + `GitClone.cmake`).
  - JS tool install via `bun install` (`SetupEsbuild.cmake`, `register_bun_install`).
- For each fetch point, define exact Guix replacement:
  - patch site,
  - input source/origin,
  - integrity pin/hash.

#### M2 Findings (current)

##### Toolchain assumptions in upstream Bun
- Requires an existing Bun executable at configure/build time (`cmake/tools/SetupBun.cmake`).
- Uses LLVM/Clang 21.1.x (`cmake/tools/SetupLLVM.cmake`).
- Uses Zig bootstrap commit `c1423ff3fc7064635773a4a4616c5bf986eb00fe` (`cmake/tools/SetupZig.cmake`).
- Default Node headers version is `24.3.0` (`cmake/Options.cmake`).

##### Network fetch points and Guix replacement plan

| Fetch point | Upstream location | Current behavior | Guix replacement |
|---|---|---|---|
| Zig compiler download | `cmake/tools/SetupZig.cmake`, `cmake/scripts/DownloadZig.cmake` | Downloads Zig bootstrap zip from `oven-sh/zig` release | Use Guix `zig` package as explicit input; patch to bypass downloader |
| WebKit artifact download | `cmake/tools/SetupWebKit.cmake` | Downloads prebuilt WebKit tarball from `oven-sh/WebKit` releases | Use `WEBKIT_LOCAL=ON` path with source checkout as input (or explicit temporary exception) |
| Node headers download | `cmake/targets/BuildBun.cmake` (`bun-node-headers`) | Downloads `node-v${NODEJS_VERSION}-headers.tar.gz` | Provide headers as pinned Guix source input and patch command path |
| Third-party git repos | `cmake/Globals.cmake` + `cmake/scripts/GitClone.cmake` + `register_repository(...)` in `cmake/targets/Build*.cmake` | Downloads tarballs from GitHub during build | Patch clone helper to resolve from pre-fetched Guix inputs by repo name |
| JS dependency install | `cmake/tools/SetupEsbuild.cmake`, `register_bun_install` in `cmake/Globals.cmake` | Runs `bun install --frozen-lockfile` in multiple dirs | Inject fixed-output `node_modules` snapshots; avoid network installs in derivation |

##### Known repository pins in upstream Bun CMake
- `oven-sh/boringssl` @ `4f4f5ef8ebc6e23cbf393428f0ab1b526773f7ac`
- `google/brotli` @ tag `v1.1.0`
- `h2o/picohttpparser` @ `066d2b1e9ab820703db0837a7255d92d30f0c9f5`
- `c-ares/c-ares` @ `3ac47ee46edd8ea40370222f91613fc16c434853`
- `HdrHistogram/HdrHistogram_c` @ `be60a9987ee48d0abf0d7b6a175bad8d6c1585d1`
- `google/highway` @ `ac0d5d297b13ab1b89f48484fc7911082d76a93f`
- `libarchive/libarchive` @ `9525f90ca4bd14c7b335e2f8c84a4607b0af6bdf`
- `ebiggers/libdeflate` @ `c8c56a20f8f621e6a966b716b31f1dedab6a41e3`
- `libuv/libuv` @ `f3ce527ea940d926c40878ba5de219640c362811`
- `cloudflare/lol-html` @ `e9e16dca48dd4a8ffbc77642bc4be60407585f11`
- `litespeedtech/ls-hpack` @ `8905c024b6d052f083a3d11d0a169b3c2735c8a1`
- `oven-sh/mimalloc` @ `1beadf9651a7bfdec6b5367c380ecc3fe1c40d1a`
- `oven-sh/tinycc` @ `12882eee073cfe5c7621bcfadf679e1372d4537b`
- `cloudflare/zlib` @ `886098f3f339617b4243b286f5ed364b9989e245`
- `facebook/zstd` @ `f8745da6ff1ad1e7bab384bd1f9d742439278e99`

##### Decision gate
- D1: strict interpretation of \"build Bun from source\" likely requires source-built WebKit/JSC as well, not downloaded prebuilt WebKit artifacts.
- Proposed direction: start with `WEBKIT_LOCAL=ON` and source input strategy, accepting that this is the highest-risk part of the effort.

### M3 - Bootstrap Bun
- Add `bun-bootstrap` package (temporary).
- Keep surface area minimal (only what is needed to execute Bun build scripts).
- Mark clearly as bootstrap-only in comments/doc.

#### M3 Outcome
- Added `bun-bootstrap` to `gnu/packages/javascript.scm`.
- Package fetches Bun release zip `bun-v1.3.8` and patches ELF interpreter with `patchelf`.
- Scope is currently `x86_64-linux` only.
- Build validated with:
  - `guix build -L /home/manolis/repos/guix -e '(@@ (gnu packages javascript) bun-bootstrap)'`
  - `guix shell -L /home/manolis/repos/guix -e '(@@ (gnu packages javascript) bun-bootstrap)' -- bun --version`
- Result: Bun bootstrap package works and reports `1.3.8`.

### M4 - Bun From Source
- Add `bun-from-source` package.
- Replace runtime fetches with provided inputs.
- Patch CMake scripts to avoid direct downloads during build.
- Vendor/pin all dependency sources (repos + node headers + JS deps snapshot).
- Ensure resulting `bun` binary runs and reports expected version.

#### M4 Outcome (prototype package validated)
- A local prototype package (`/tmp/bun-local.scm`) was used to exercise Bun source build wiring end-to-end.
- Resolved early blockers:
  - `SetupRust.cmake` could not find `cargo` (fixed by adding Rust `cargo` output to native inputs).
  - Offline `SetupWebKit.cmake` download failure (fixed by pre-seeding Bun's expected WebKit artifact into `build/release/cache/webkit-9a2cc42ae1bf693a`).
  - Offline fetch paths (`GitClone.cmake`, `DownloadUrl.cmake`) were patched to short-circuit when pre-populated content exists.
  - Tarball (no `.git`) caused missing dependency version constants (fixed by patching `cmake/tools/GenerateDependencyVersions.cmake` fallback for `BUN_GIT_SHA`).
- Zig/toolchain findings:
  - Upstream Guix Zig was insufficient for Bun 1.3.8 source build in this configuration.
  - Using Bun/Oven Zig bootstrap (`vendor/zig`) unblocked Zig compilation.
- Major build-capacity finding:
  - Default Bun C/C++ flags emitted heavy debug data, triggering `IO failure on output stream: No space left on device` in `/tmp` during large C++ object builds.
  - Prototype mitigation: patch `cmake/CompilerFlags.cmake` to use `-g0` and run with `CMAKE_BUILD_PARALLEL_LEVEL=1`.
  - Result: build progressed through full native compile, linked `bun-profile`, and executed the produced binary (`1.3.8-canary.1+000000000`) during build.
- Runpath blocker (resolved):
  - Guix `validate-runpath` initially failed because Bun binary was linked with `ld-linux-x86-64.so.2` as `DT_NEEDED`.
  - Fixed in install phase using `patchelf --set-interpreter` and `patchelf --remove-needed ld-linux-x86-64.so.2`.
  - Full build now succeeds:
    - `guix build -L /home/manolis/repos/guix -L /tmp -e '(@@ (bun-local) bun-from-source-proto)'`
  - Smoke tests succeeded:
    - `guix shell -L /home/manolis/repos/guix -L /tmp -e '(@@ (bun-local) bun-from-source-proto)' -- bun --version` -> `1.3.8`
    - `guix shell -L /home/manolis/repos/guix -L /tmp -e '(@@ (bun-local) bun-from-source-proto)' -- bun -e 'console.log("ok")'` -> `ok`

### M5 - Reproducibility and Validation
- Build `bun-from-source` at least twice.
- Run `guix build --check --rounds=2`.
- Smoke checks:
  - `bun --version`
  - `bun -e 'console.log("ok")'`

### M6 - opencode Integration
- Replace opencode package native input from `bun-bootstrap` to `bun-from-source`.
- Keep build offline (`MODELS_DEV_API_JSON`, `--skip-install`).
- Ensure node_modules restore strategy is deterministic and collision-free.

#### M6 Outcome (prototype package validated)
- Local package prototype: `/tmp/opencode-local.scm`.
- Build succeeded with:
  - `guix build -L /home/manolis/repos/guix -L /tmp -e '(@@ (opencode-local) opencode-local)'`
- Runtime checks on resulting binary succeeded:
  - `.../bin/opencode --help` shows opencode CLI help.
  - `.../bin/opencode --version` reports `1.1.58`.
- Important caveat:
  - Guix default `strip` phase must be disabled for this package.
  - Stripping removes Bun embedded payload sections and changes behavior back to plain Bun.

### M7 - Handoff
- Update this file with:
  - what is complete,
  - exact blockers,
  - exact next commands/files.

#### M7 Progress (in-repo module port + validation)
- Added local module file:
  - `gnu/packages/opencode-local.scm`
- This module now contains both:
  - `bun-from-source-local` (ported from `/tmp/bun-local.scm`)
  - `opencode-local` (ported from `/tmp/opencode-local.scm`)
- Path handling is now environment-overridable for future sessions:
  - `BUN_OFFLINE_SEED_DIR`
  - `OPENCODE_SOURCE_DIR`
  - `OPENCODE_MODELS_DEV_API_JSON`
- In-repo builds validated with:
  - `guix build -L /home/manolis/repos/guix -e '(@@ (gnu packages opencode-local) bun-from-source-local)'`
  - `guix build -L /home/manolis/repos/guix -e '(@@ (gnu packages opencode-local) opencode-local)'`
- Latest successful outputs:
  - Bun: `/gnu/store/yj5xgkz92wpgx7l5xqb3bc6vmc3kfypa-bun-from-source-local-1.3.8`
  - opencode: `/gnu/store/hnn0cwxf5mvlh2m7b100nn0hb9pcsrqr-opencode-local-1.1.58`
- Smoke checks from in-repo module succeeded:
  - `guix shell -L /home/manolis/repos/guix -e '(@@ (gnu packages opencode-local) bun-from-source-local)' -- bun --version` -> `1.3.8`
  - `guix shell -L /home/manolis/repos/guix -e '(@@ (gnu packages opencode-local) bun-from-source-local)' -- bun -e 'console.log("ok")'` -> `ok`
  - `guix shell -L /home/manolis/repos/guix -e '(@@ (gnu packages opencode-local) opencode-local)' -- opencode --version` -> `1.1.58`

## Risk Register
- R1: Bun build system expects live network fetches by default.  
  Mitigation: patch fetch paths to local/pinned Guix inputs.
- R2: WebKit dependency complexity for source builds.  
  Mitigation: first target Bun's supported non-local path with pinned artifacts if unavoidable, then incrementally move to fuller source closure if required.
- R3: JS dependency closure size and determinism.  
  Mitigation: fixed-output, hash-pinned dependency snapshot.
- R4: Bootstrap trust gap.  
  Mitigation: isolate bootstrap package and rebuild Bun from source afterward.

## Progress Log
- 2026-02-11: Created initial plan and milestone structure (M1 complete).
- 2026-02-11: Completed M2 inventory with concrete fetch points, upstream pins, and initial replacement strategy.
- 2026-02-11: Implemented `bun-bootstrap` in `gnu/packages/javascript.scm` and validated build/runtime (M3 complete).
- 2026-02-11: Started M4 source-build bring-up via local prototype; confirmed WebKit fetch/local-source blockers and cargo requirement.
- 2026-02-11: Switched prototype Zig strategy to Bun/Oven Zig bootstrap in `vendor/zig`; source build progressed far beyond initial Zig parser failures.
- 2026-02-11: Fixed tarball/no-git version macro issue by patching `GenerateDependencyVersions.cmake`.
- 2026-02-11: Identified `/tmp` capacity failure mode from Bun debug-heavy C/C++ flags; patched `CompilerFlags.cmake` to `-g0` and reduced build parallelism.
- 2026-02-11: Reached successful compile/link/test stage in Bun build; remaining failure is Guix `validate-runpath` for `DT_NEEDED ld-linux-x86-64.so.2`.
- 2026-02-12: Fixed Bun runpath/install issues with `patchelf`; confirmed successful Bun source build and smoke tests (`--version`, `-e`).
- 2026-02-12: Built opencode locally against source-built Bun, restored all required workspace `node_modules`, and validated runtime CLI.
- 2026-02-12: Identified and fixed opencode packaging trap: deleting `strip` phase is required to preserve Bun-embedded executable payload.
- 2026-02-12: Ported Bun/opencode package prototypes into `gnu/packages/opencode-local.scm` with path override environment variables.
- 2026-02-12: Rebuilt both packages from in-repo module and revalidated Bun + opencode smoke checks.

## Continuation Notes (for next session)
- Primary tracking file: `doc/bun-opencode-packaging-plan.md`
- Start at M5/M7 and update statuses in both this file and Codex plan tool.
- Do not remove bootstrap notes until `bun-from-source` is validated and opencode uses it.
- Current durable code changes are in:
  - `gnu/packages/javascript.scm` (added `bun-bootstrap`)
  - `gnu/packages/opencode-local.scm` (local Bun + opencode packaging module)
- Current throwaway prototypes (not committed) are:
  - `/tmp/bun-local.scm`
  - `/tmp/opencode-local.scm`
- Current local recipe prerequisites:
  - `BUN_OFFLINE_SEED_DIR` (default `/var/tmp/bun-offline-seed`)
  - `OPENCODE_SOURCE_DIR` (default `/home/manolis/repos/opencode`)
  - `OPENCODE_MODELS_DEV_API_JSON` (default `/tmp/models-dev-api.json`)
  - restored node_modules snapshots under `OPENCODE_SOURCE_DIR`:
    - `.guix-node-modules`
    - `packages/{app,enterprise,function,plugin,script,slack,ui,util,web}/node_modules`
- Immediate next actions:
  - Run Bun reproducibility check from in-repo module:
    - `guix build --check --rounds=2 -L /home/manolis/repos/guix -e '(@@ (gnu packages opencode-local) bun-from-source-local)'`
  - Reduce opencode shebang-patching noise by narrowing source tree traversal or deleting more unused patch phases safely.
  - Decide whether to keep `gnu/packages/opencode-local.scm` as a local-dev module or upstream candidate, then remove absolute-path assumptions accordingly.
