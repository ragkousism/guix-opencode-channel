# Guix Upstreaming Plan (Local)

Last updated: 2026-03-06
Scope: local working notes for splitting the channel work into reviewable Guix
patches.

## Original Prompt (Working)

- Add Bun support to Guix in upstream-reviewable steps.
- Keep the build-system path reproducible and offline-first.
- Avoid proprietary code, remotely pulled binaries, and opaque provenance.

## Current Upstream State (`../guix`)

`master` is ahead of `origin/master` by 3 Bun build-system commits:

1. `ebfed3d0d7` `guix: Add bun build system skeleton.`
2. `78e2e3b3e1` `guix: bun-build-system: Add offline install options.`
3. `cb080a7b91` `guix: bun-build-system: Add workspace symlink restore helper.`

Interpretation:

- Track A steps 1-3 are implemented locally in `../guix`.
- Next work should focus on hardening + reviewer-facing polish before posting.

## Goals

- Upstream the work in small, standalone patches.
- Keep patch provenance auditable.
- Optimize for reviewer clarity and maintainability.

## Non-Negotiable Gates

1. No proprietary code in the patch series.
2. No binary blobs or prebuilt artifacts committed in patches.
3. No generated files unless Guix already expects them upstream.
4. Every embedded shim/compat snippet has explicit provenance in the commit
   message (self-authored vs adapted from upstream OSS).
5. Each patch must build/evaluate on its own (or clearly be an RFC-only patch).

## Reviewer-Facing Style Rules

1. One concern per patch.
2. Tight commit messages (`guix:` / `gnu:` scope prefixes, exact rationale).
3. No vague "cleanup" commits.
4. No channel-only docs in Guix patch series.
5. Include validation evidence for each patch (commands + outcomes).

## Upstream Tracks

### Track A: Generic Bun Build System (first)

1. `guix: add bun build system skeleton` (DONE locally)
2. `guix: bun-build-system add deterministic install policy` (DONE locally)
3. `guix: bun-build-system add workspace symlink restore helper` (DONE locally)
4. `guix: bun-build-system harden install script behavior` (NEXT)
5. `doc: document bun-build-system` (Guix manual style)
6. `gnu: convert/add tiny Bun package` (real package preferred)

### Track B: Bun Bootstrap Chain (second)

1. `gnu: add bun-stage0`
2. `gnu: bun-stage0 compatibility fixes` (split by subsystem/theme)
3. `gnu: add bun-from-source`
4. `gnu: bun-from-source offline/reproducibility fixes`
5. Follow-up cleanup/style fixes

### Track C: opencode (last)

1. `gnu: add opencode package skeleton`
2. `gnu: opencode reuse bun-build-system helpers`
3. `gnu: opencode schema generation integration`
4. `gnu: opencode source-purity follow-up` (after Bun runtime supports
   `bun:wrap.__using`)

## Current Temporaries / Known Blockers

- `opencode` schema generation currently uses `bun-schema-generator`
  (`bun-bootstrap-binary-1.3.8`) because current `bun-from-source` runtime does
  not export `bun:wrap.__using`.
- This is a build/runtime purity concern, not a proprietary-code-in-patch
  concern, but it must remain isolated and explicitly temporary.
- For generic Bun upstreaming, this blocker is out-of-scope until Track A is
  accepted.

## Provenance Checklist (Per Patch)

Before sending:

1. `git show --name-status --stat <commit>`
2. `git diff --numstat <base>..<commit>` (no binary markers)
3. `git diff --name-only <base>..<commit> | xargs file` (text-only patch files)
4. Review commit message for provenance notes on embedded code/shims.
5. Confirm no local-path references, private repos, or generated artifacts.

## Validation Checklist (Per Patch)

1. `guix build -L . <target> --dry-run`
2. Run the minimal real build needed to prove the patch.
3. Capture exact result path or exact failure.
4. Record any warnings that reviewers are likely to ask about.

## Continuation Plan (2026-03-06)

### Step 1 (Next): Hardening commit in `../guix`

Objective: strengthen guarantees around no remotely pulled binaries during
dependency installation.

Planned patch title:

`guix: bun-build-system: Disable lifecycle scripts by default.`

Planned changes:

1. Add an explicit knob (for example `install-scripts?`) defaulting to `#f`.
2. Pass Bun install flags that skip lifecycle scripts by default.
3. Keep `offline?` default `#t` and `lockfile-mode` behavior as-is.
4. Document in commit message why this is required for upstream policy defense.

Validation for this patch:

1. Build/eval smoke target using the local Bun demo package.
2. Confirm the install phase command line includes offline and no-scripts mode.
3. Record exact command outcomes in commit message notes.

### Step 2: Build-system docs patch

Objective: reviewer-ready documentation for new build-system API.

Planned outputs:

1. Guix manual-style section for `bun-build-system`.
2. Keyword argument docs (`bun`, `bun-flags`, `bun-install-flags`, `offline?`,
   `lockfile-mode`, workspace helper usage).
3. Short, realistic package example.

### Step 3: Tiny real package patch

Objective: prove real use in `gnu/packages/*` with minimal policy risk.

Constraints:

1. No binary blobs.
2. No network fetch during build.
3. Clear, maintainable package recipe with deterministic dependency handling.

### Step 4: Post-Track-A follow-on

1. Rebase/split channel Bun bootstrap work into Track B (`bun-stage0`,
   `bun-from-source`) after Track A reviewer feedback is integrated.
2. Keep `opencode` as Track C only after generic pieces are accepted and stable.

## Patch Order to Send (Target)

1. `guix: add bun build system skeleton` (already local)
2. `guix: bun-build-system add offline install options` (already local)
3. `guix: bun-build-system add workspace symlink restore helper` (already local)
4. `guix: bun-build-system disable lifecycle scripts by default` (next)
5. `doc: document bun-build-system`
6. `gnu: add/convert tiny Bun package`
