# Bun + opencode Guix Packaging Plan

Last updated: 2026-02-21
Owner: Manolis / Codex session
Status: Completed initial source-build chain (follow-up cleanup pending for schema generation path)

## Objective
Package `opencode` in Guix with a fully source-built Bun chain.

## Scope
- Target system: `x86_64-linux`
- Working repo: `/home/manolis/repos/guix-opencode-channel`
- Main file under active development: `gnu/packages/opencode.scm`

## Current package chain (channel)
- `bun-stage0` (Bun `1.0.0`, source tarball)
- `bun-from-source` (Bun `1.3.8`, bootstrapped from `bun-stage0`)
- `opencode` (built with `bun-from-source`)

## Milestones

| ID | Milestone | Status | Notes |
|---|---|---|---|
| M1 | Channel skeleton + remote repo | DONE | `ragkousism/guix-opencode-channel` |
| M2 | Move prototype packages to channel module | DONE | `gnu/packages/opencode.scm` |
| M3 | Replace Bun prebuilt bootstrap executable | DONE | `bun-stage0` introduced |
| M4 | Make `bun-stage0` compile on current WebKit headers | DONE | Compatibility patch set merged in package recipe |
| M5 | Build `bun-stage0` successfully | DONE | stage0 build now succeeds |
| M6 | Build `bun-from-source` (`1.3.8`) from stage0 | DONE | latest success: `/gnu/store/84y963hsyb5gi1finyhjx7787hafw28h-bun-from-source-1.3.8` |
| M7 | Build `opencode` from source-built Bun chain | DONE | latest success: `/gnu/store/2wnbn0jx6m0wifb73sxzmwndfss3pxnk-opencode-1.1.58` |

## What was done in this session

### Stage0 recipe work (`gnu/packages/opencode.scm`)
Expanded `bun-stage0` compatibility substitutions for modern WebKit/JSC APIs.

Key additions in this round:
- `bindings.cpp` fixes:
  - `StringImpl::copyCharacters` span API
  - `StringView` ctor span migration
  - `JSC::makeSource` tainted-origin argument
  - `AtomStringImpl::lookUp` span API
  - `ExternalStringImpl::create` span API
  - bytecode expression-range API migration (`expressionInfoForBytecodeIndex`)
- `napi.cpp` fixes:
  - `generateSourceCode` `makeSource` signature update
  - `charactersAreAllASCII` call updated to explicit `std::span<const LChar>`
- `workaround-missing-symbols.cpp`:
  - add missing `<cstdlib>` include for `abort`
- `wtf-bindings.cpp`:
  - `parseDouble` and `copyCharacters` span API
- `webcore/HTTPHeaderNames.{gperf,cpp}`:
  - `StringView` construction updated to explicit span
- `webcore/HTTPParsers.cpp`:
  - `parseDateFromNullTerminatedCharacters` -> `WTF::parseDate(value.span8())`
  - `String`/`StringView`/`fromUTF8` pointer+len calls moved to span forms
  - `Vector<uint8_t>::append` updated to explicit span
- `webcore/JSAbortSignalCustom.cpp` and `webcore/JSBroadcastChannel.cpp`:
  - `*reason = "..."` adapted to `WTF::ASCIILiteral::fromLiteralUnsafe(...)`
- `webcore/JSFetchHeaders.cpp`, `webcore/JSMessageEvent.cpp`:
  - `reportExtraMemoryAllocated` now passes owning JSCell (`this`)
- `webcore/SerializedScriptValue.cpp` (latest patch batch, needs validation run):
  - `Vector<uint8_t>::append` pointer+len -> span
  - `String` and `Identifier::fromString` pointer+len -> span
  - `ErrorInstance::create` now uses `JSC::LineColumn { line, column }`
- `webcore/WebSocket.cpp` (newly fixed in this session):
  - `StringBuilder::append(const char*)` removals:
    - `builder.append("\\\\")` -> `builder.append("\\\\"_s)`
    - `builder.append(separator)` -> `builder.append(WTF::ASCIILiteral::fromLiteralUnsafe(separator))`
  - `didReceiveBinaryData(..., { bytes, len })` migrated to:
    - `Vector<uint8_t>(std::span<const uint8_t> { bytes, len })`
- `webcrypto/CryptoAlgorithmAES_GCMOpenSSL.cpp`:
  - `Vector<uint8_t> tag { ptr, len }` migrated to:
    - `Vector<uint8_t>(std::span<const uint8_t> { ptr, len })`
- `webcrypto/CryptoAlgorithmEd25519.cpp`:
  - `return Vector<uint8_t>(newSignature, 64);` migrated to:
    - `return Vector<uint8_t>(std::span<const uint8_t> { newSignature, 64 });`
- `webcrypto/SubtleCrypto.cpp` (proactive fixes in same API family):
  - `KeyData { Vector { ptr, len } }` migrated to explicit span-based vector construction
  - `return { data.data(), data.length() }` migrated to explicit span-based `Vector<uint8_t>` construction
- OpenSSL 3 const-correctness fixes:
  - `webcrypto/CryptoAlgorithmECDSAOpenSSL.cpp`:
    - `EVP_PKEY_get0_EC_KEY(...)` result now wrapped via `const_cast<EC_KEY*>` at assignment site (needed because `ECDSA_do_sign` / `ECDSA_do_verify` still expect non-const `EC_KEY*`)
  - `webcrypto/CryptoKeyECOpenSSL.cpp`:
    - `EVP_PKEY_get0_EC_KEY(...)` bindings changed to `const EC_KEY*`
    - `EC_KEY_set_asn1_flag` call updated with `const_cast<EC_KEY*>` for explicit mutation path
  - `webcrypto/CryptoKeyRSAOpenSSL.cpp` (proactive):
    - `EVP_PKEY_get0_RSA(...)` assignments changed to `const_cast<RSA*>` to absorb OpenSSL 3 const-return changes while preserving existing helper signatures
- BoringSSL compatibility shim:
  - `src/deps/boringssl/include/openssl/curve25519.h` is now generated during build prep
  - provides the subset Bun uses:
    - `ED25519_keypair`, `ED25519_keypair_from_seed`, `ED25519_sign`, `ED25519_verify`
    - `X25519_keypair`, `X25519_public_from_private`
    - related length constants
  - implementation uses OpenSSL EVP raw-key/sign/verify APIs
- Additional BoringSSL compatibility shim:
  - `src/deps/boringssl/include/openssl/hkdf.h` is now generated during build prep
  - provides `HKDF(...)` using OpenSSL HKDF APIs (`EVP_PKEY_HKDF`)
- Additional BoringSSL compatibility shim:
  - `src/deps/boringssl/include/openssl/mem.h` is now generated during build prep
  - delegates to OpenSSL's `openssl/crypto.h` for `OPENSSL_malloc` / `OPENSSL_free`
- Build-loop tuning:
  - switched stage0 make invocation from `CPUS=1` to `CPUS=2` to speed iterative compile/fix cycles
  - then increased to `CPUS=8` to push more of the compile within session time limits
- Global helper substitution:
  - convert `*reason = "..."` patterns in `src/bun.js/bindings/*.{h,cpp}` to `ASCIILiteral`.

### Build-loop notes
Build command used repeatedly:

```bash
guix build -L /home/manolis/repos/guix-opencode-channel bun-stage0
```

For low-noise triage:

```bash
guix build -L /home/manolis/repos/guix-opencode-channel bun-stage0 \
  2>&1 | rg --line-buffered -n "error:|fatal error|build of .* failed|failed with exit code|^make:"
```

### Infra issue hit and fixed
- `/tmp` (tmpfs) filled to 100% because of accumulated `--keep-failed` trees.
- Cleaned stale stage0 build dirs with:

```bash
sudo find /tmp -maxdepth 1 -name 'guix-build-bun-stage0-*' -print0 \
  | sudo xargs -0 -I{} find '{}' -depth -delete
```

- After cleanup: `/tmp` back to ~5% usage.

## Current status
- `bun-stage0` now compiles far past the earlier `bindings.cpp`/`napi.cpp`/`webcore` blockers.
- New blocker was observed in:
  - `src/bun.js/bindings/webcore/WebSocket.cpp`
    - deleted `StringBuilder::append(const char*)`
    - `Vector<uint8_t> { bytes, len }` constructor mismatch
- After fixing `WebSocket.cpp`, the next blocker appeared in:
  - `src/bun.js/bindings/webcrypto/CryptoAlgorithmAES_GCMOpenSSL.cpp`
    - `Vector<uint8_t> tag { ptr, len }` constructor mismatch
- A corresponding patch was added.
- Then added proactive follow-up substitutions for similar `Vector` pointer+length constructions in `SubtleCrypto.cpp`.
- Build was restarted after these updates.
- Next failure occurred in `CryptoAlgorithmECDSAOpenSSL.cpp` after initial const migration:
  - `ECDSA_do_sign` / `ECDSA_do_verify` require non-const `EC_KEY*`.
- Updated patch to assign `ecKey` via `const_cast<EC_KEY*>(EVP_PKEY_get0_EC_KEY(...))` in that file, then restarted validation.
- Next failure then occurred due missing header:
  - `fatal error: 'openssl/curve25519.h' file not found`
- Added generated shim header in the `prepare-webkit` phase and restarted validation.
- Next failure then occurred in:
  - `src/bun.js/bindings/webcrypto/CryptoAlgorithmEd25519.cpp`
    - `Vector<uint8_t>(newSignature, 64)` constructor mismatch
- Added a span-based constructor patch and restarted validation.
- Next failure then occurred in:
  - `src/bun.js/bindings/webcrypto/CryptoAlgorithmHKDFOpenSSL.cpp`
    - `fatal error: 'openssl/hkdf.h' file not found`
- Added a generated `openssl/hkdf.h` shim (backed by OpenSSL HKDF APIs) and restarted validation.
- Next failure then occurred in:
  - `src/bun.js/bindings/webcrypto/CryptoAlgorithmRSA_OAEPOpenSSL.cpp`
    - `fatal error: 'openssl/mem.h' file not found`
- Added a generated `openssl/mem.h` shim (delegating to OpenSSL `crypto.h`) and restarted validation.
- Next failure then occurred in:
  - `src/bun.js/bindings/webcrypto/CryptoKeyOKP.cpp`
    - `Vector<uint8_t>(data.data(), 32)` constructor mismatch
- Added a span-based constructor patch and restarted validation.
- Added proactive follow-up substitutions in:
  - `src/bun.js/bindings/webcrypto/CryptoKeyOKPOpenSSL.cpp`
    - `Vector<uint8_t>(private_key, ...)` -> span-based constructor
    - `Vector<uint8_t>(exportKey.data(), exportKey.size())` -> span-based constructor
- Further `CryptoKeyOKPOpenSSL.cpp` API updates:
  - `result.append(platformKey().data(), platformKey().size())` -> span-based append
  - `result.append(exportKey().data(), exportKey().size())` -> span-based append
  - `KeyMaterial(m_data.data(), m_data.size())` -> span-based constructor
- Follow-up fix in `CryptoKeyOKPOpenSSL.cpp`:
  - span length for private key needed explicit cast:
    - `static_cast<size_t>(isEd25519 ? ED25519_PRIVATE_KEY_LEN : X25519_PRIVATE_KEY_LEN)`
  - addresses `-Wc++11-narrowing` on the span initializer list.
- Refinement:
  - switched to the `std::span<const uint8_t>(ptr, len)` constructor form
    to avoid brace-initializer narrowing in this call site.
- Next failure occurred in:
  - `src/bun.js/bindings/webcrypto/SubtleCrypto.cpp`
    - `WorkQueue::create("com.apple.WebKit.CryptoQueue")` no longer converts
      implicitly to `ASCIILiteral`.
    - `String jwkString(bytes.data(), bytes.size())` constructor no longer
      exists with pointer+length arguments.
- Added substitutions for `SubtleCrypto.cpp`:
  - `WorkQueue::create(...)` now uses
    `WTF::ASCIILiteral::fromLiteralUnsafe(...)`.
  - `String jwkString(...)` now uses
    `String::fromUTF8({ reinterpret_cast<const char*>(bytes.data()), bytes.size() })`.
- Build restarted after these fixes.
- Next failure occurred after C++ compilation completed:
  - `zig build obj` panicked in `build.zig`:
    - `Runtime file was not read successfully. Please run make setup`
  - missing generated files:
    - `src/runtime.out.js`
    - `src/fallback.out.js`
- Added build-phase generation step before `release-only`:
  - initial attempt used `make runtime_js fallback_decoder`
  - this failed in the isolated build because the `peechy` npm dependency is
    not present in the release tarball and cannot be fetched during Guix build.
- Switched strategy:
  - create minimal placeholder files in `src/` for:
    - `runtime.out.js`
    - `runtime.out.refresh.js`
    - `runtime.node.out.js`
    - `runtime.bun.out.js`
    - `fallback.out.js`
  - this unblocks Zig `@embedFile` and `updateRuntime()` checks for stage0.
- Next failure after a long detached run:
  - missing generated assets required by Zig `@embedFile`:
    - `src/js_lexer/id_start_bitset.meta.blob`
    - `src/js_lexer/id_continue_bitset.meta.blob`
    - `src/node-fallbacks/out/assert.js` (and sibling `out/*.js`)
    - `packages/bun-error/dist/bun-error.css`
    - `packages/bun-error/dist/index.js`
- Added source-built/prepared generation steps in the `build` phase:
  - run `zig run src/js_lexer/identifier_data.zig` to generate identifier
    cache blobs from upstream Unicode tables (no prebuilt blobs).
  - populate `src/node-fallbacks/out/*.js` from `src/node-fallbacks/*.js`
    source files.
  - generate `packages/bun-error/dist/index.js` with `esbuild` from
    `packages/bun-error/index.tsx` (externalizing `react` and `react-dom`),
    and install `packages/bun-error/dist/bun-error.css` from source CSS.

## Session updates (2026-02-21)

### Completed milestones since previous checkpoint
- `bun-stage0` now completes.
- `bun-from-source` now completes.
- latest successful `bun-from-source` output:
  - `/gnu/store/84y963hsyb5gi1finyhjx7787hafw28h-bun-from-source-1.3.8`

### Key packaging changes merged in `gnu/packages/opencode.scm`
- `bun-from-source`:
  - added `node-v24.3.0` headers tarball as a native input.
  - extract Node headers during `prepare-offline-tree`.
  - removed `vendor/nodejs/include/node/openssl` to force resolution to Bun's vendored BoringSSL headers.
- `opencode`:
  - added `models-dev-api` input and export `MODELS_DEV_API_JSON`.
  - set `OPENCODE_DISABLE_MODELS_FETCH=true` to avoid network fetch in build.
  - rewired `restore-node-modules` to keep large root `node_modules` in store (symlink) and avoid huge tmpfs copies.
  - copied only `packages/opencode/node_modules` locally and made it writable for targeted grafting.
  - restored package module trees from inputs via symlink:
    - `app`, `enterprise`, `function`, `plugin`, `script`, `slack`, `ui`, `util`, `web`
  - restored `packages/sdk/js/node_modules` from input for workspace SDK package.
  - recreated expected workspace links under `packages/opencode/node_modules/@opencode-ai`:
    - `script`, `plugin`, `util`, `sdk`
  - mirrored hoisted Babel deps used by build scripts:
    - `@babel` and `babel-preset-solid` from `node_modules/.bun/node_modules`.

### opencode blocker progression (latest first)
- `SyntaxError: Export named '__using' not found in module 'bun:wrap'` during `script/schema.ts`.
  - treated as non-fatal for packaging: run schema generation opportunistically and fallback to a minimal `schema.json` when Bun lacks `__using`.
- `Object is not a constructor (evaluating 'new _lruCache({ max: 64 })')` while compiling TUI entrypoint.
  - traced to `@babel/helper-compilation-targets` assuming `require("lru-cache")` returns a constructor.
  - fixed by patching helper to use `(_lruCache.LRUCache || _lruCache)` and localizing writable `@babel` tree in build.
- `Cannot find module '@opencode-ai/script'` from `packages/opencode/script/build.ts`.
  - addressed by recreating `@opencode-ai/*` workspace symlinks in `restore-node-modules`.
- `Cannot find module '@babel/types'` from `@babel/core/lib/transformation/file/file.js`.
  - addressed by linking full hoisted `@babel` tree.
- `Cannot find module '@babel/helper-plugin-utils'` from `@babel/preset-typescript/lib/index.js`.
  - addressed by exposing hoisted Babel deps and revising restore strategy.

## Next actions (ordered)
1. Re-run detached `opencode` build without `--keep-failed` for a clean confirmation:

```bash
setsid bash -lc 'cd /home/manolis/repos/guix-opencode-channel && guix build -c16 -L . opencode > /tmp/opencode-setsid.log 2>&1; echo $? > /tmp/opencode-exit-code' </dev/null &
```

2. Keep smoke-testing package output:

```bash
guix shell -L /home/manolis/repos/guix-opencode-channel opencode -- opencode --help
```

3. Optional quality follow-up:
   - replace temporary minimal `schema.json` fallback with true generated schema once Bun `__using` support in this chain is resolved.

## Risks / notes
- Build logs are large and include many unpack lines; grep/tail filtering is required for fast triage.
- Detached launch is required; interactive-session termination can stop foreground `guix build`.
- `--keep-failed` is useful for inspection but can fill `/tmp`; clean stale `/tmp/guix-build-opencode-*` trees periodically.
- Current package build succeeds even when `script/schema.ts` fails on Bun `__using`; schema is currently a minimal compatibility fallback.

## Handoff checklist
- Open `gnu/packages/opencode.scm`.
- Re-run detached `opencode` build from channel root (prefer without `--keep-failed`).
- If improving quality, remove the schema fallback once Bun supports the required `__using` path.
- Update this document with any post-success cleanup and verification logs.
