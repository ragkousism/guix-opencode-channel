# Bun + opencode Guix Packaging Plan

Last updated: 2026-08-05
Owner: Manolis / Claude session
Status: bun-stage0 builds and links (mimalloc ABI fix applied); bun-stage0 binary still hangs on JS execution. Stage 1 of the fix plan was implemented and DID NOT fix it — the runtime-blob hypothesis is falsified. See "Known blocker" and "Stage 1 result" below.

## Objective
Package `opencode` in Guix with a fully source-built Bun chain.

## Known blocker (2026-08-05): bun-stage0 hangs on JS execution

### Status of this session's work
- Fixed a real version-drift bug: `prepare-webkit` copied mimalloc headers
  from a hard-coded `mimalloc-3.1` path; current Guix ships `mimalloc-3.3.2`.
  Fixed to locate the header by content (`find-files ... "^mimalloc\\.h$"`)
  instead of a hard-coded version string.
- Found and fixed a real ABI hazard: Bun 1.0.0 vendors an old mimalloc fork
  (`Jarred-Sumner/mimalloc` a.k.a. now `oven-sh/mimalloc`, commit `7968d42`,
  `MI_MALLOC_VERSION 210`). Current Guix `mimalloc` (3.3.2) replaced the
  classic `mi_heap_get_default()` (`mi_heap_t*`) with a distinct
  `mi_theap_get_default()` (`mi_theap_t*` — a different type, not just a
  rename; see `mimalloc_arena.zig` around `getThreadlocalDefault()`, whose
  return value later flows into `mi_heap_malloc`/`mi_heap_destroy`). Rather
  than rewrite Bun's Zig allocator code against an unverified ABI, pinned a
  local `mimalloc-3.1` package variant (inherits Guix's `mimalloc`, source
  overridden to `v3.1.6`, which still has the classic API). This is a plain
  `package/inherit` override — see `mimalloc-3.1` definition just above
  `bun-stage0` in `gnu/packages/opencode.scm`, and the
  `("mimalloc" ,mimalloc-3.1)` native-input in `bun-stage0`.
- Result: `bun-stage0` now builds and links successfully.
  `bun --version` → `1.0.0`, exit 0.

### The new blocker
`bun run <any-script.js>`, including a trivial `console.log(...)`, does not
execute — it spins indefinitely. Confirmed via `/proc/<pid>/status`: state
`R` (running), ~99% CPU. This is a CPU-bound loop, not a crash or blocked
I/O wait.

### Root cause: corrected diagnosis
The `prepare-webkit` phase (`gnu/packages/opencode.scm`, search for
`"runtime.out.js"`) writes literal no-op placeholder files —
`(display "(()=>{})();\n" port)` — for `src/runtime.out.js`,
`src/runtime.out.refresh.js`, `src/runtime.node.out.js`,
`src/runtime.bun.out.js`, and `src/fallback.out.js`, instead of Bun's real
generated JS runtime bootstrap. The working hypothesis (strong, not yet
proven end-to-end) is that Bun's native code spins waiting on JS-side
runtime initialization state that a no-op stub never establishes.

**This session's log previously attributed the missing runtime files to a
missing `peechy` npm dependency unavailable offline. That appears to be a
misattribution.** Checked directly against Bun v1.0.0's own `Makefile`:

```makefile
.PHONY: fallback_decoder
fallback_decoder:
	@$(ESBUILD) --target=esnext --bundle src/fallback.ts --format=iife --platform=browser --minify > src/fallback.out.js

.PHONY: runtime_js
runtime_js:
	@NODE_ENV=production $(ESBUILD) --define:process.env.NODE_ENV="production" --target=esnext --bundle src/runtime/index.ts --format=iife --platform=browser --global-name=BUN_RUNTIME --minify --external:/bun:* > src/runtime.out.js; cat src/runtime.footer.js >> src/runtime.out.js
	@NODE_ENV=production $(ESBUILD) ... --bundle src/runtime/index-with-refresh.ts ... > src/runtime.out.refresh.js; cat src/runtime.footer.with-refresh.js >> src/runtime.out.refresh.js
	@NODE_ENV=production $(ESBUILD) ... --bundle src/runtime/index-without-hmr.ts --platform=node ... > src/runtime.node.pre.out.js; cat src/runtime.node.pre.out.js src/runtime.footer.node.js > src/runtime.node.out.js
	@NODE_ENV=production $(ESBUILD) ... --bundle src/runtime/index-without-hmr.ts --platform=node ... > src/runtime.bun.pre.out.js; cat src/runtime.bun.pre.out.js src/runtime.footer.bun.js > src/runtime.bun.out.js
```

CORRECTION (2026-08-05, verification pass): the paragraph that previously
stood here claimed peechy is entirely unrelated to these targets. That is
only *half* right. Verified against the extracted tarball:

- `src/api/schema.js` IS committed to the release tarball, so
  peechy-the-CLI (codegen) is indeed not needed.
- BUT `src/fallback.ts` and `src/runtime/hmr.ts` both do
  `import { ByteBuffer } from "peechy"` — the peechy *runtime library*.
  Import graph of the five bundle entrypoints:
  - `runtime.node.out.js`, `runtime.bun.out.js` ← `index-without-hmr.ts`
    → only `../runtime.js` + `./regenerator`. **No peechy — bundleable
    offline with zero new inputs.**
  - `runtime.out.js` ← `index.ts` → re-exports `./hmr` → **needs peechy**.
  - `runtime.out.refresh.js` ← `index-with-refresh.ts` → `./hmr` +
    `../react-refresh` → **needs peechy (and react-refresh)**.
  - `fallback.out.js` ← `fallback.ts` → **needs peechy directly**.

So the February log's peechy claim was partially correct after all — for
three of the five blobs. peechy is MIT-licensed
(github.com/jarred-sumner/peechy); its ByteBuffer runtime is small and can
be vendored as an ordinary `origin` input if those three blobs turn out to
matter.

All bundle inputs verified present in the release tarball:
`src/runtime/index.ts`, `index-without-hmr.ts`, `index-with-refresh.ts`,
`src/fallback.ts`, and all four `src/runtime.footer*.js` files.

`esbuild` is already a native-input in `bun-stage0` (used a few lines above
the placeholder loop, to build `packages/bun-error/dist/index.js` — the
exact same pattern needed here).

Caveat on the hypothesis itself: it is NOT yet proven that the runtime
stubs cause the hang. A plain `console.log` script does not obviously
require injected BUN_RUNTIME helpers; the spin could also originate in the
internal-module bootstrap (`src/js/out/*`, `InternalModuleRegistry`) that
the prepare phase also touches. The staged fix below doubles as the
falsification test.

### Suggested next step (not yet implemented — untested)
Stage 1 (zero new inputs): replace the placeholders for
`runtime.node.out.js` and `runtime.bun.out.js` only, with real
`invoke esbuild ...` bundles of `src/runtime/index-without-hmr.ts`
(platform=node, `--external:/bun:*`), concatenating the matching
`src/runtime.footer.{node,bun}.js` as the Makefile does. Rebuild, smoke
test. If the hang clears, the HMR/browser blobs can stay stubbed for
stage0's bootstrap purposes.

Stage 2 (only if stage 1 is insufficient): vendor peechy source as an
`origin` input, expose it to esbuild (alias/NODE_PATH), and bundle the
remaining three blobs (`runtime.out.js`, `runtime.out.refresh.js`,
`fallback.out.js`) for real too. `react-refresh` would also be needed for
the refresh variant — check whether stage0 can keep that one stubbed.

Smoke test after each stage:

```bash
guix build -c16 -L /home/manolis/repos/guix-opencode-channel bun-stage0
guix shell -L /home/manolis/repos/guix-opencode-channel bun-stage0 -- bun run <(echo 'console.log("hello")')
```

Expect instant "hello" output, not a hang. If it still hangs, check
`node-fallbacks` next (a sibling `vendor-without-npm` prerequisite,
currently populated by direct-copying `src/node-fallbacks/*.js` to
`src/node-fallbacks/out/*.js` around line 763 of the same file — this looks
plausible but has not been runtime-verified either).

Also note: `bun-from-source` (the later, CMake-based Bun 1.3.8 package,
further down in the same file) has its *own*, separate placeholder
mechanism for the same class of files (`runtime.out.js` as literal
`export default {};`, in the big Python/shell codegen block). If fixing
`bun-stage0`'s runtime.js unblocks it, the same class of issue likely still
needs revisiting there — check whether `bun-from-source`'s own build
actually exercises the JS runtime at any point (it uses `bun-stage0`/
`bun-bootstrap-binary` for codegen scripts), since it may hit the identical
hang.

### Stage 1 result (2026-08-05): hypothesis FALSIFIED

Stage 1 was implemented and built.  It did **not** fix the hang.

What was done (committed; see the `bun-stage0: Bundle node/bun runtime
blobs from source` commit):

- `gnu/packages/opencode.scm` (`bun-stage0`, `build` phase): replaced the
  no-op placeholders for `src/runtime.node.out.js` and
  `src/runtime.bun.out.js` with a real esbuild bundle of
  `src/runtime/index-without-hmr.ts`, concatenated with
  `src/runtime.footer.{node,bun}.js`, mirroring Bun's `runtime_js` target.
  The other three blobs remain placeholders.
- Verified upstream runs the *byte-identical* esbuild command for both
  outputs (only the footer differs), so one bundle feeds both.
- Dropped upstream's `--define:process.env.NODE_ENV=...`: `NODE_ENV` does
  not appear anywhere in this entry point's source graph, and the emitted
  bundle contains zero references to it.  (Note for anyone re-adding it:
  in upstream's Makefile the shell strips the quotes, so esbuild receives
  a bare identifier rather than a JSON string — that would inject an
  undefined global.  It is inert here only because nothing reads it.)

Proof the change actually took effect (i.e. this is a real falsification,
not a silently-skipped edit): the build log contains esbuild's output
`src/runtime.node.pre.out.js  10.1kb`, versus the previous 12-byte stub.

Result: `guix build` succeeds →
`/gnu/store/mvjhlrrapxpqw7qbr7yf3mghjb68j50a-bun-stage0-1.0.0`.
`bun --version` → `1.0.0` (exit 0).
`bun run hello.js` → still spins, killed by `timeout 20` (exit 124).

### Narrowed scope of the hang (new evidence)

Only *JS execution* hangs.  Everything around it works:

| command | result |
|---|---|
| `bun --version` | `1.0.0`, exit 0 |
| `bun --help` | exit 0 |
| `bun build hello.js` | exit 0 — bundler/transpiler path is fine |
| `bun run /nonexistent.js` | prompt `error: missing script`, exit 1 — file resolution and error paths are fine |
| `bun run hello.js` | hangs forever, ~99% CPU |

So the spin is after argument parsing and file resolution, in the
VM-startup / module-load / execute path — and it is CPU-bound, not
blocked on I/O.

Stack sample (via `timeout -s ABRT` + `coredumpctl info`, since
`ptrace_scope=1` blocks attaching):

```
Stack trace of thread <main>:
#0  0x...  n/a (bun + 0x29e1490)
#1  0x...  n/a (bun + 0x3fa2470)
...
#10 0x...  n/a (bun + 0x423d49b)
#11 __libc_start_call_main (libc.so.6)
```

Main thread is 11 frames deep from `main`, entirely inside bun's own code,
not in a syscall.  (The only other thread sits in a normal
`pthread_cond_timedwait`.)  Symbols are unavailable: the binary is
stripped, `.symtab` is gone and `.dynsym` has only the 147 exported
`BUN_1.0` symbols, so these offsets cannot be resolved as-is.

### RESOLVED (2026-08-05): stack symbolized — root cause identified

The stack was symbolized (see "How to symbolize" below).  The hang is:

```
#0  WTF::AtomStringImpl::addLiteral(std::span<const unsigned char>)
#1  WebCore::BunBuiltinNames::BunBuiltinNames(JSC::VM&)
#2  WebCore::JSVMClientData::JSVMClientData(JSC::VM&)
#3  WebCore::JSVMClientData::create(JSC::VM*, void*)
#4  Zig__GlobalObject__create
#5  ...shimmer...cppFn
#6  src.bun.js.javascript.VirtualMachine.init
#7  src.bun_js.Run.boot
#8  src.cli.run_command.RunCommand.exec
#9  src.cli.Command.start
#10 src.main.main
```

This is JS **VM/global-object construction** — it happens before any user
JavaScript is loaded or run.  That explains every observation at once:
`--version`, `--help` and `bun build` never construct a JS global object,
so they work; `bun run` constructs one, so it hangs.  It also definitively
clears the runtime blobs (embedded JS, consumed much later) — consistent
with Stage 1 having no effect.

The loop is in WTF's atom-string table while interning Bun's builtin
identifier names (`BunBuiltinNames`, ~250 `macro(...)` names in
`src/js/builtins/BunBuiltinNames.h`, interned via WebKit's
`INITIALIZE_BUILTIN_NAMES`).

**Root cause: the recipe links Bun 1.0.0 against the wrong WebKit.**
`bun-stage0` uses

    .../WebKit/releases/download/autobuild-64d04ec1a65d91326c5f2298b9c7d05b56125252/bun-webkit-linux-amd64.tar.gz

but Bun 1.0.0's own CI (`.github/workflows/bun-linux-build.yml` in the
release tarball, `webkit_url:`) pins

    .../WebKit/releases/download/2023-aug3-5/bun-webkit-linux-amd64-lto.tar.gz

The recipe's own comment admits the mismatch ("Bun 1.0.x expects older
JavaScriptCore/WTF APIs.  Adapt a few generated headers/helpers to the
newer WebKit snapshot used in this bootstrap stage").  The ~60
`substitute*` calls exist purely to bridge that gap.  They made the code
*compile* against the newer WTF, but compiling is not conforming: the
runtime behaviour of the atom-string path differs, and it now spins.

### Suggested next step: use the WebKit that Bun 1.0.0 expects

Swap `webkit-prebuilt-stage0` to the `2023-aug3-5`
`bun-webkit-linux-amd64-lto.tar.gz` release.  Verified downloadable and
hashed on 2026-08-05, so this is ready to paste in:

```scheme
(define webkit-prebuilt-stage0
  (origin
    (method url-fetch)
    (uri "https://github.com/oven-sh/WebKit/releases/download/2023-aug3-5/\
bun-webkit-linux-amd64-lto.tar.gz")
    (sha256
     (base32
      "15xcmxagps6ifl6wmw9fav4yfn9bf4mfwzssnqs2k7qh9zyl8h04"))))
```

Note the tarball's top-level directory name may differ from the current
one; the `prepare-webkit` phase untars it and sets `JSC_BASE_DIR` to
`$(pwd)/bun-webkit`, so check the extracted layout and adjust if needed.
A non-LTO `bun-webkit-linux-amd64.tar.gz` also exists at the same tag if
the LTO build causes trouble.

Expect this to *also* let most of the ~60
compatibility substitutions be deleted, since they only exist to bridge to
the newer snapshot.  Note Guix's `substitute*` does not error when a
pattern fails to match, so stale substitutions will silently become
no-ops — they should be removed deliberately, not left to rot, and any
that still match must be re-checked against the older headers.

Caveats worth stating plainly:

- This does not fix the upstream-policy problem: it is still a prebuilt
  binary blob, which is why this whole chain stays channel-only.
- It is a large change with a ~40 min build per iteration.
- It is a strong hypothesis, not a certainty; the falsification test is
  the same smoke test (`bun run hello.js` must print promptly).

### How to symbolize (for future debugging)

`#:strip-binaries? #f` alone is **not** enough: Bun's own Makefile strips
the binary during the build.  On Linux the `release-only` target runs
`bun-link-lld-release-dsym`, which does
`-$(STRIP) -s $(BUN_RELEASE_BIN) --wildcard -K _napi\*`.

Override it with a make command-line variable (command-line assignments
beat the Makefile's own `STRIP=`):

```scheme
(invoke "make" "release-only" (string-append "CPUS=" cpus) "STRIP=true")
```

Do **not** try to patch this with `substitute*` on `^STRIP=.*llvm-strip.*$`:
a trailing `$` in a `substitute*` pattern eats the newline, welding the
next line on (`STRIP=trueendif`) and unbalancing the Makefile's
conditionals.

Then, because `ptrace_scope=1` blocks attaching:

```bash
ulimit -c unlimited
timeout -s ABRT 8 <bun> run hello.js
coredumpctl info <bun>          # or: coredumpctl gdb <bun>
```

A ready-made script lives in the session scratchpad as `symbolize.sh`.

### Superseded: earlier "symbolize the stack" plan

1. Add `#:strip-binaries? #f` to `bun-stage0`'s arguments (and ideally
   keep debug info: the Makefile's `-g` is already in `BUN_LLD_FLAGS`).
2. Rebuild, reproduce the hang, re-dump with
   `ulimit -c unlimited; timeout -s ABRT 6 <bun> run hello.js`, then
   `coredumpctl info` (or `coredumpctl gdb` → `bt`).
3. The resolved frames should say whether this is, e.g., the internal
   module registry, a JSC bootstrap loop, or one of the `-Wl,--wrap=`
   libc wrappers from `workaround-missing-symbols.cpp` (a plausible
   suspect given Bun 1.0.0 predates glibc 2.41 and the link line wraps
   `stat`/`fstat`/`pow`/`exp`/... — a mismatch there can loop).

Only after that should Stage 2 (vendoring `peechy` to un-stub the
remaining three blobs) be considered; on current evidence those blobs are
not implicated in plain-script execution.

## Scope
- Target system: `x86_64-linux`
- Working repo: `/home/manolis/repos/guix-opencode-channel`
- Main file under active development: `gnu/packages/opencode.scm`

## Current package chain (channel)
- `bun-stage0` (Bun `1.0.0`, source tarball)
- `bun-from-source` (Bun `1.3.8`, bootstrapped from `bun-stage0`)
- `opencode` (built with `bun-from-source`)
- `bun-build-system-smoke` (minimal package validating new `bun-build-system`)
- `opencode` schema generation currently runs with `bun-schema-generator`
  (`bun-bootstrap-binary-1.3.8`) because current `bun-from-source` runtime
  does not export `bun:wrap.__using`

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
| M8 | Replace schema fallback with generated schema in package build | DONE | now generated via `bun-schema-generator`; latest success: `/gnu/store/bd6krmn4a6x5wa9n754df3r0i3cnbs0i-opencode-1.1.58` |
| M9 | Scaffold reusable `bun-build-system` + smoke package | DONE | added `guix/build-system/bun.scm`, `guix/build/bun-build-system.scm`, and `bun-build-system-smoke` |

## Historical build/debug notes (2026-02-21)

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
- This section reflects the late 2026-02-21 state before the 2026-02-22
  schema-generation and `bun-build-system` updates.
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
- RESOLVED (2026-02-22): `SyntaxError: Export named '__using' not found in module 'bun:wrap'` during `script/schema.ts`.
  - packaging now runs schema generation with `bun-schema-generator`
    (`bun-bootstrap-binary-1.3.8`) and installs the real generated schema.
- `Object is not a constructor (evaluating 'new _lruCache({ max: 64 })')` while compiling TUI entrypoint.
  - traced to `@babel/helper-compilation-targets` assuming `require("lru-cache")` returns a constructor.
  - fixed by patching helper to use `(_lruCache.LRUCache || _lruCache)` and localizing writable `@babel` tree in build.
- `Cannot find module '@opencode-ai/script'` from `packages/opencode/script/build.ts`.
  - addressed by recreating `@opencode-ai/*` workspace symlinks in `restore-node-modules`.
- `Cannot find module '@babel/types'` from `@babel/core/lib/transformation/file/file.js`.
  - addressed by linking full hoisted `@babel` tree.
- `Cannot find module '@babel/helper-plugin-utils'` from `@babel/preset-typescript/lib/index.js`.
  - addressed by exposing hoisted Babel deps and revising restore strategy.

## Session updates (2026-02-22)

### Completed milestones since previous checkpoint
- Added reusable Bun build-system modules:
  - `guix/build-system/bun.scm`
  - `guix/build/bun-build-system.scm`
- Added and validated smoke package:
  - `bun-build-system-smoke`
- Replaced `opencode` schema fallback with full schema generation in build:
  - build now invokes `bun-schema-generator` for `script/schema.ts`
  - removed minimal JSON fallback write path
- latest successful `opencode` output after this change:
  - `/gnu/store/bd6krmn4a6x5wa9n754df3r0i3cnbs0i-opencode-1.1.58`
- installed schema is full/generated (not fallback):
  - `/gnu/store/bd6krmn4a6x5wa9n754df3r0i3cnbs0i-opencode-1.1.58/share/opencode/schema.json`
  - size observed: `259307` bytes

### Key packaging changes merged in `gnu/packages/opencode.scm`
- `opencode`:
  - added native input:
    - `("bun-schema-generator" ,bun-bootstrap-binary-1.3.8)`
  - changed build phase schema step from tolerant fallback to required generation:
    - now invokes `${bun-schema-generator}/bin/bun --bun ./script/schema.ts schema.json`
  - removed `call-with-output-file` minimal fallback JSON path
- module exports:
  - added `bun-build-system-smoke` export in channel package module

### Validation run summary
- `guix build -L . opencode` succeeded with generated schema path.
- `guix shell -L . opencode -- opencode --help` succeeded.
- `guix build -L . bun-build-system-smoke` succeeded.

## Next actions (ordered)
1. Re-run detached `opencode` build without `--keep-failed` for a clean archival log of the updated schema path:

```bash
setsid bash -lc 'cd /home/manolis/repos/guix-opencode-channel && guix build -c16 -L . opencode > /tmp/opencode-setsid.log 2>&1; echo $? > /tmp/opencode-exit-code' </dev/null &
```

2. Keep smoke-testing package output:

```bash
guix shell -L /home/manolis/repos/guix-opencode-channel opencode -- opencode --help
```

3. Advance `bun-build-system` Phase 2:
   - harden deterministic/offline install behavior and lockfile handling.
4. Advance `bun-build-system` Phase 3:
   - move at least one `opencode` workspace-restore step into reusable Bun phase helpers.
5. Optional quality follow-up:
   - remove `bun-schema-generator` once `bun-from-source` runtime supports
     schema generation (`bun:wrap.__using`) directly.

## Risks / notes
- Build logs are large and include many unpack lines; grep/tail filtering is required for fast triage.
- Detached launch is required; interactive-session termination can stop foreground `guix build`.
- `--keep-failed` is useful for inspection but can fill `/tmp`; clean stale `/tmp/guix-build-opencode-*` trees periodically.
- `opencode` schema generation now depends on `bun-schema-generator`
  (`bun-bootstrap-binary-1.3.8`) for `bun:wrap.__using`.
- This keeps schema quality high but is still a temporary non-source-built
  component in the `opencode` packaging path.

## Handoff checklist
- Open `gnu/packages/opencode.scm`.
- Re-run detached `opencode` build from channel root (prefer without `--keep-failed`) and capture `/tmp/opencode-setsid.log`.
- Verify generated schema is installed (not fallback), e.g. check size/content under:
  - `/gnu/store/...-opencode-1.1.58/share/opencode/schema.json`
- Continue Phase 2/3 `bun-build-system` work by extracting one `restore-node-modules` step into generic helpers.
- If improving source purity, remove `bun-schema-generator` once Bun `__using` is available in `bun-from-source`.
- Update this document with any post-success cleanup and verification logs.

## RESOLVED (2026-08-13): hang fixed, and the blobs are going away

### The hang

Confirmed and fixed.  The recipe linked Bun 1.0.0 against a WebKit years
newer than it targets, bridged by ~250 `substitute*` calls.  Those made it
compile without making it conform; the binary spun in
`WTF::AtomStringImpl::addLiteral` while building the JS global object, so
anything that had to execute JavaScript hung while `--version`, `--help` and
`bun build` worked.  Building the JavaScriptCore Bun 1.0.0 expects, and
deleting the adaptation layer, fixes it: `bun run hello.js` prints in ~12ms.

Two of the removed substitutions were *not* WebKit-related and had to be kept
(a `<cstdlib>` include and a constexpr-limit workaround).  Guix's
`substitute*` does not fail when a pattern misses, so the rest were removed
deliberately rather than left to rot.

### No more prebuilt binaries in the stage0 chain

`bun-stage0`'s closure now contains only Bun's source tarball, a WebKit git
checkout, and Guix's own icu4c.

- The prebuilt Bun release is gone; stage0 bootstraps the next stage itself.
  It only ever existed because stage0 could not run JavaScript.
- `bun-webkit` is built from source (`make-bun-webkit`), as a static JSCOnly
  port configured like the fork's own Dockerfile.  GitHub refuses to generate
  archives for that repo (~12GB), but a `--depth 1` fetch of the pinned commit
  is ~1.2GiB, which `git-fetch` does by default.
- The prebuilt tarball bundled the *build host's* Debian ICU 67 archives.
  That, and nothing else, is why ICU 67 headers had to be fetched to match
  `u_strlen_67`.  With ICU coming from Guix the pin is gone.

Revisions come from the prebuilt tarball's `package.json`, or from the
`autobuild-<sha>` release tag, which encodes the commit.

| revision   | for       | toolchain | note                        |
|------------|-----------|-----------|-----------------------------|
| `48c1316`  | Bun 1.0.0 | gcc       | built, runs JS              |
| `9e3b60e4` | Bun 1.2.0 | gcc       | built                       |
| `9a2cc42`  | Bun 1.3.8 | clang     | `USE_BUN_EVENT_LOOP=ON`     |

`RunLoopBun.cpp` only compiles with clang, so revisions enabling Bun's run
loop must use it -- matching upstream's toolchain, since deviating from
upstream's pairing is what caused the hang in the first place.

Bun consumes only `include/` and `lib/`, so WebKit's own build helpers under
`bin/` are deliberately not installed (they would fail `validate-runpath`).

### Remaining: the bootstrap ladder

`bun-from-source` (1.3.8) does not yet build, because Bun 1.0.0 cannot run
Bun 1.3.8's code generators.  Four differences, in the order they appear:
`Bun.Glob` and `Bun.stringWidth` do not exist in 1.0.0; `--keep-names` is
unsupported and mis-parses into a misleading "specify --outdir" error even
though `--outdir` was passed; and `Bun.write` does not create parent
directories.  Past all four it hits a genuine segfault in 1.0.0's parser
(`DotDefine` lookup under `Bun.Transpiler.scan`), which cannot be shimmed.

An intermediate rung avoids this.  Under stage0, Bun 1.1.0 and 1.2.0
code generation both run to completion needing only the `Bun.write` shim --
no `Bun.Glob`, no `--keep-names`, no segfault.  So the ladder is
1.0.0 -> 1.2.0 -> 1.3.8.  opencode pins `bun@1.3.8` in its `packageManager`
field, so the ladder does have to reach 1.3.8.

Next step: parameterise `bun-from-source` over version, WebKit and bootstrap
Bun (as `make-bun-webkit` is), then build the 1.2.0 and 1.3.8 rungs.

### Still outstanding

- `#:strip-binaries? #f` and `STRIP=true` in `bun-stage0` remain from
  debugging the hang and should be reverted now that it is fixed.
- `webkit-prebuilt-1.3.8` is still referenced by `bun-from-source`;
  `bun-webkit-for-1.3.8` is built and ready to replace it.

## Session updates (2026-08-13, later): stage0 drives the 1.3.8 codegen

With the mimalloc ABI mismatch fixed, the 1.3.8 code generators stopped
crashing and started failing for ordinary reasons instead: places where Bun
1.0.0 genuinely lacks something 1.3.8 assumes.  Each was reproduced against a
`--keep-failed` tree before being turned into a substitution.

### Fixed in this pass

- **bindgen "This function definition needs to be exported".**
  `import.meta.require()` of an ES module returns `{}` in 1.0.0, so bindgen saw
  no exports for `src/bake/DevServer.bind.ts` and rejected its one function.
  Dynamic `import()` does report the exports, but it cannot simply replace the
  `require()`: `TypeImpl` derives each type's owning file by walking the stack
  for the first frame outside `src/codegen`, and in a pure ES module graph
  `bindgen-lib.ts` is evaluated *before* the importing `.bind.ts` body, so no
  such frame exists and `snapshotCallerLocation` throws.  Keeping the
  `require()` for its side effects and reading exports from `await import()`
  satisfies both.  Output: 27 KB `GeneratedBindings.cpp`, 21 KB
  `GeneratedBindings.zig`.

- **`create-hash-table.ts` ReadableStream TypeError.**  It read `proc.stdout`
  only after `await proc.exited`.  In 1.0.0 that trips a controller assertion
  when the stream is *empty*, which is the case for `ZigGeneratedClasses`: no
  `.classes.ts` defines `own` properties, so `create_hash_table` gets no
  `@begin/@end` block and prints nothing.  (The resulting 58-byte `.lut.h` is
  correct, not a truncation.)  Starting the read before awaiting the exit fixes
  it, and leaves the non-empty cases byte-identical.

- **Bake runtime CSS.**  `bun build overlay.css --minify` fails on 1.0.0, which
  predates CSS entry points.  The value only has to be a JavaScript string
  literal for the `OVERLAY_CSS` define, so the stylesheet is embedded
  unminified.

- **Bake runtime `ModuleNotFound` (the subtle one).**  The generator bundles a
  second time from a `.runtime-*.generated.ts` file it has just written, and
  1.0.0's resolver caches its listing of `src/bake`.  The three runtimes are
  bundled concurrently, and each `map` callback created its file and then
  started a bundle, so the first bundle to scan `src/bake` froze the listing
  before the last file existed -- which is why the failure always landed on
  `error`, the last of the three.  Creating all three before any bundle starts,
  and deleting them only after all three settle, holds the directory still for
  the whole concurrent phase.

  Worth recording as a measurement lesson: pre-creating inside the callback
  took the standalone failure rate from 5/5 to 1/20, and a later variant ran
  60/60 clean standalone but still failed under the real build, where ninja
  runs 16 jobs concurrently.  Standalone trials were not a valid proxy for
  build-time concurrency here.

### lolhtml is now vendored

`cargo build` in `vendor/lolhtml/c-api` ran with an empty `CARGO_HOME` under
`CARGO_NET_OFFLINE`, failing with `no matching package named 'libc'`.  The
dependency tree resolves to **44 crates** (not the ~98 estimated earlier).
They are pinned as `url-fetch` origins from crates.io in
`%lolhtml-vendored-crates` and unpacked into a cargo *directory source* by the
`vendor-lolhtml-crates` phase, each with a `.cargo-checksum.json` whose empty
`files` map tells cargo not to re-verify contents the store already
authenticated.

### Where the build now stops

`bun-from-source` reaches **[51/628]** and the last known blocker is lolhtml
itself, which the vendoring above is intended to clear.

### Still outstanding

- The 16 local-path inputs (opencode source defaulting to
  `/home/manolis/repos/opencode`, plus 11 `node_modules` directories) silently
  become empty elsewhere.  This is the real upstreaming blocker.
- Re-test whether `SIMDUTF_IMPLEMENTATION_ICELAKE=0` is still needed; it was
  added while chasing what turned out to be heap corruption.

## Session updates (2026-08-13, evening)

### `bun-from-source` is complete

Both remaining stubbed codegen targets now build for real, and the recipe no
longer preseeds any of their output:

- `bun-runtime-js` -> `runtime.out.js` (2.8 KB).  This was the `__using`
  blocker: opencode's sources use explicit resource management, and the stub
  (`export default {}`) made `bun build` fail with *Export named '__using' not
  found in module 'bun:wrap'*.
- `bun-fallback-decoder` -> `fallback-decoder.js` (8.6 KB).

Both had been stubbed for the same non-reason: the esbuild wrapper written by
`prepare-offline-tree` carried a `#!/bin/sh` shebang, and there is no
`/bin/sh` in the build container.  The kernel reports that as *"cannot execute:
required file not found"*, which reads like a missing esbuild.  Using
`(which "bash")` fixed both targets at once.

`fallback-decoder.js` additionally needs peechy's `ByteBuffer`.  The npm
package ships only esbuild output, so `peechy-source` takes the TypeScript
sources from git instead, and `src/fallback.ts` is pointed at the `peechy/bb`
entry point that the rest of the tree already uses -- the package root also
re-exports the schema compilers, whose `change-case` dependency is not
vendored.

Four CMake targets remain skipped, and unlike the two above these genuinely do
need npm dependencies: `bun-error` (preact), `bun-node-fallbacks` and
`bun-node-fallbacks-react-refresh` (~125 browserify-shim packages), and
`bun-node-headers` (preseeded from a source origin, which is the correct Guix
treatment for a download step).  None of them are prebuilt binaries, and none
are reachable from opencode, which compiles with `--target=bun`.

### `libopentui`

opencode's TUI is rendered by `@opentui/core`, which `dlopen`s a Zig library
that npm ships prebuilt as `@opentui/core-linux-x64`.  The new `libopentui`
package builds it from source with `zig-0.15`; its single Zig dependency
(`uucode`) is a plain checkout, which `zig fetch` hashes to exactly the package
hash upstream pinned.  The result exports the same 229 symbols as the npm
binary and has an empty closure.

Substituting it into the build needed more than overwriting the file.  Bun
resolves modules to their realpath, so leaving `index.ts` as a symlink into the
store made its `import("./libopentui.so")` resolve back to the *store's*
prebuilt copy -- the substitution appeared to succeed and changed nothing.  The
`use-source-built-opentui` phase therefore materialises each parent directory
as a real directory of symlinks and copies the leaf package outright.

That failure was invisible from the build log, so `verify-source-built-opentui`
now greps the compiled binary for a Zig debug-info string that only the
unstripped npm library carries.  Independent confirmation: the binary shrank by
3,479,510 bytes, against a 3,479,288-byte difference between the two libraries.

### Remaining prebuilt binaries

Nine prebuilt blobs are still embedded verbatim in the compiled binary
(measured by searching the 110 MB output for each candidate's bytes):

| bytes | file |
| --- | --- |
| 1413849 | `@opentui/core/assets/typescript/tree-sitter-typescript.wasm` |
| 1380769 | `tree-sitter-bash/tree-sitter-bash.wasm` |
| 691726 | `@opentui/core/assets/zig/tree-sitter-zig.wasm` |
| 610024 | `bun-pty/rust-pty/target/release/librust_pty.so` |
| 514960 | `@parcel/watcher-linux-x64-glibc/watcher.node` |
| 426020 | `@opentui/core/assets/markdown_inline/tree-sitter-markdown_inline.wasm` |
| 421534 | `@opentui/core/assets/markdown/tree-sitter-markdown.wasm` |
| 411770 | `@opentui/core/assets/javascript/tree-sitter-javascript.wasm` |
| 205488 | `web-tree-sitter/tree-sitter.wasm` |

Six are tree-sitter WebAssembly (five grammars plus the `web-tree-sitter`
runtime); Guix already packages the corresponding grammars natively, so what is
missing is the wasm build.  The other two are `librust_pty.so` (Rust) and
`watcher.node` (a C++ N-API addon).

Note that the 51 distinct native/wasm blobs in the `node_modules` input are all
build *inputs* regardless of use; only these nine reach the output.

## Session updates (2026-08-13, night): eight of nine blobs replaced

Starting from the nine prebuilt binaries embedded in the compiled opencode
binary, eight are now built from source.  Each was verified functionally, not
just structurally, before being wired in.

### `librust-pty`

`bun-pty` publishes `librust_pty.so` inside its npm package with no Rust
sources at all -- `rust-pty/` contains only `target/`.  The sources live only
upstream.  The new `librust-pty` package builds them from the v0.4.8 tag with
the 43 crates of `rust-pty/Cargo.lock` vendored as crates.io origins, verified
against the lockfile checksums (0 mismatches).  Same eight exported functions
as the npm binary, and correctly linked against Guix's glibc, which the npm
build is not.

### `tree-sitter-wasm-grammars`

Upstream builds these with emscripten, which Guix does not package, so this
looked blocked.  It is not: inspecting the published modules shows they are
plain wasm **side modules** -- position-independent code with a `dylink.0`
section, importing memory, an indirect function table and eleven libc
functions from `env`.  `wasm-ld --shared` emits exactly that format, so clang
and lld suffice:

```
clang --target=wasm32-wasi -nostdinc -isystem <clang>/lib/clang/19/include \
      -isystem <wasi-libc>/share/wasi-sysroot/include/wasm32-wasi \
      -fPIC -fvisibility=hidden -Os -std=c11 -c parser.c
wasm-ld --shared --allow-undefined --no-entry --strip-all \
        --export=tree_sitter_<lang> --export-if-defined=__wasm_call_ctors
```

Two details matter.  Guix's clang searches the host glibc headers ahead of any
`--sysroot`, so `-nostdinc` plus explicit `-isystem` flags are required.  And
grammars without static constructors have no `__wasm_call_ctors`, so the export
must be conditional.

The six grammars (bash, javascript, typescript, markdown, markdown_inline, zig)
come from the commits behind the release artifacts that `@opentui/core`'s
`parsers-config.ts` and opencode's `tree-sitter-bash` dependency pin.  Each was
checked by parsing a sample exercising real grammar features and diffing the
resulting s-expression against the npm module's: **all six are identical**.

### `parcel-watcher-node`

`@parcel/watcher`'s addon, published prebuilt as
`@parcel/watcher-linux-x64-glibc`.  Built directly with `g++` from the source
list and defines in `binding.gyp`'s `linux` condition -- node-gyp is not needed
to apply them -- against header-only `node-addon-api` 7.1.1 and Node's headers.
Since Node-API is a stable ABI that Bun implements, the result loads under Bun.
Verified by subscribing to a directory and observing the same
create/update/delete event sequence as the prebuilt.

Only the glibc variant is substituted; the musl package stays prebuilt but is
never reached on a Guix system.

### Verification

`verify-source-built-libraries` runs after the build and searches the compiled
binary for each artefact's bytes: every prebuilt one must be absent and every
source-built one present.  This is the only reliable signal, because a missed
substitution is otherwise invisible -- Bun resolves modules to their realpath,
so a package reached through a symlink loads its assets from the store copy and
the replacement silently does nothing.  An independent scan of the finished
binary against all 51 native/wasm blobs in the `node_modules` input confirms
the count went 9 -> 8 -> 2 -> 1 as each package landed.

### The one that remains

`web-tree-sitter/tree-sitter.wasm` (205 KB) is the tree-sitter *runtime*, not a
grammar, and unlike the grammars it genuinely needs emscripten: it imports
`wasi_snapshot_preview1.{fd_write,fd_seek,fd_close,clock_time_get}` plus
`env.emscripten_resize_heap` and `env._abort_js`, and its 153 exports are
consumed by emscripten-generated JS glue (`tree-sitter.js`) that is published
alongside it.  Reproducing it means either packaging emscripten for Guix, or
rebuilding the runtime against wasi-libc and matching the glue's expected
export set by hand.  Neither is a small job, and the second risks subtle
breakage in memory growth and stack handling.

## Session updates (2026-08-13, late): zero prebuilt binaries

All nine prebuilt blobs are gone.  An independent scan of the finished 110 MB
binary against all 51 distinct native/wasm blobs in the `node_modules` input
finds **none** of them embedded, and the in-build check confirms all ten
source-built artefacts are present.

The last one, `web-tree-sitter/tree-sitter.wasm`, needed emscripten, so
emscripten is now packaged.

### `clang-for-emscripten`

Guix configures clang with `-DC_INCLUDE_DIRS=<glibc>/include`, baked in at
build time.  Clang searches it for *every* target, ahead of any `--sysroot`, so
compiling for `wasm32-unknown-emscripten` picks up host glibc headers and fails
on `gnu/stubs-32.h`.  Emscripten drives clang itself and has no flag to undo
this.

A wrapper injecting `-Xclang -nostdsysteminc` plus explicit `-isystem` flags
got surprisingly far -- musl, dlmalloc and compiler-rt all built -- but each
step needed another patch (`-Qunused-arguments` for assembly inputs, then C++
header ordering, then `getentropy` from a header-order inversion against
emscripten's `include/compat`).  That is the shape of a fix that eventually
produces a bad artefact rather than an error, so it was abandoned in favour of
a clang that simply never had the path baked in: `clang-for-emscripten`
inherits `clang-20` and filters that one configure flag out.  Its include
search list is the resource directory alone, which is what emscripten expects.

### `emscripten`

Version 4.0.4, the release tree-sitter pins in `cli/loader/emscripten-version`.
It drives Guix's `clang-for-emscripten`, `lld-20`, `llvm-20`, `binaryen` and
`node`; nothing is downloaded through emsdk.  Four things were needed:

- `bootstrap.py`'s three actions are `npm ci`, entry-point generation and
  submodule checkout.  Only the entry points matter here, so the build runs
  that script directly and writes the other two stamps.  The default
  `bootstrap` phase had to be deleted too -- it found the repository's
  `bootstrap` script and ran `npm ci`.
- The generated launchers carry `#!/bin/sh`, and emcc shells out to them to
  compile its own system libraries.  There is no `/bin/sh` in the build
  container.  This is the same trap that had two of Bun's codegen targets
  stubbed for months.
- Emscripten populates its cache with `shutil.copytree`, which preserves
  permissions.  Store files are read-only, so a copied directory comes out
  unwritable and the next file into it fails -- inside `copytree`, so a
  post-copy `chmod` never runs.  It now copies contents only and sets modes
  itself.
- `-O3` runs `tools/acorn-optimizer.mjs`, which imports acorn.  npm ships only
  rollup output, so acorn 8.15.0 is built from its sources with esbuild into
  the package's own `node_modules`.

A note for anyone editing this file: `substitute*` reads each line with its
newline attached, so a pattern anchored with `$` silently matches nothing.
Both patches here are unanchored for that reason.

### `web-tree-sitter-wasm`

Built with `xtask/src/build_wasm.rs`'s flags verbatim, so the module matches
the emscripten-generated glue already published in the npm package -- only the
`.wasm` is replaced, not the JavaScript.  Two deviations, both forced by Guix
having binaryen 125 where emscripten 4.0.4 expects 121:

- `-gsource-map` is dropped; binaryen 125 rejects the map emscripten emits
  ("sourcesContent is not an array").  Nothing loads it at runtime.
- wasm-opt 125 strips 23 libc exports (`malloc`, `free`, `memcpy`,
  `iswalpha`, ...) that 121 keeps.  Grammars are side modules that import
  exactly those from `env`, so without them every grammar fails to link with
  a bare *"resolved is not a function"*.  They are now named explicitly in
  `EXPORTED_FUNCTIONS`; the list is precisely the set the published module
  exports beyond `exports.txt`.

Verified by loading each of the six source-built grammars into the
source-built runtime under the published glue and diffing the parse trees
against the fully-prebuilt stack: identical for all six.

### Result

| artefact | replaces |
| --- | --- |
| `libopentui.so` | `@opentui/core-linux-x64` |
| `librust_pty.so` | `bun-pty`'s bundled binary |
| `watcher.node` | `@parcel/watcher-linux-x64-glibc` |
| `tree-sitter.wasm` | `web-tree-sitter` |
| six `tree-sitter-*.wasm` | `tree-sitter-bash`, `@opentui/core/assets` |

opencode's runtime closure is 30 items and contains no prebuilt binary; the
build-time closure is 2640.  The binary runs, and the opentui-rendered startup
banner confirms the Zig library loads.

### Still outstanding

These are packaging concerns, not source-provenance ones:

- The 16 local-path inputs (opencode source defaulting to
  `/home/manolis/repos/opencode`, plus 11 `node_modules` directories) silently
  become empty elsewhere.  This remains the real upstreaming blocker.
- The npm dependency tree is still consumed as a prebuilt `node_modules`
  directory.  Nothing binary survives into the output, but the JavaScript is
  npm's build output rather than built from source here.
- The musl variants of `@parcel/watcher` remain prebuilt; they are never
  reached on a Guix system.
- Four Bun CMake targets stay skipped (`bun-error`, `bun-node-fallbacks`,
  `bun-node-fallbacks-react-refresh`, `bun-node-headers`).  None are prebuilt
  binaries and none are reachable from opencode.

## Session updates (2026-08-13, later still): the inputs, not just the output

The previous section's claim -- zero prebuilt binaries -- was measured on the
compiled binary.  That was the wrong denominator.  Nothing prebuilt reached the
*output*, but plenty still entered the *build*:

- The `node_modules` inputs carried **235 compiled artefacts**: 108 `.wasm`,
  68 `.node`, 12 `.so`, plus binaries published with no extension at all --
  `workerd` (117 MB, three copies), `pagefind_extended` (69 MB, three copies),
  `tsgo` (20 MB, three copies), `libvips-cpp.so.42`.  Around 900 MB in total.
- Source checkouts carried **357 more**, mostly WebKit's test fixtures.

### Filtering the node_modules inputs

`local-directory-or-empty` now passes a `#:select?` predicate that drops
compiled artefacts, matching on extension and, for the extension-less ones, on
magic number (ELF, WebAssembly, PE, Mach-O, `ar`).  All eleven `node_modules`
inputs now contain zero compiled artefacts, and the built binary is
byte-for-byte the same size as before, with the same ten source-built artefacts
embedded.

Two details worth keeping:

- `.lib` and `.a` are *not* in the extension list.  They matched
  `bottleneck/.babelrc.lib`, a JSON babel config; static archives are caught by
  their `!<ar` magic instead.  Checking the removals against their actual
  content is what surfaced this -- the extension list alone looked right.
- The magic check only reads files that are executable or at least 64 KB.
  Reading all 428k files in the tree turned every `guix build` evaluation into
  a ten-minute affair; with the narrowing it is back to twenty seconds.

Because the prebuilt files are no longer present to overwrite, the substitution
phase installs rather than replaces, and the post-build check now verifies only
that each source-built artefact is present -- a prebuilt one can no longer be
embedded, since it is not in the derivation at all.

### Cleaning the source checkouts

- **zig-for-bun** shipped `stage1/zig1.wasm`, the WebAssembly build of Zig's
  own stage 1 compiler.  Guix's `zig-source` deletes it in a snippet;
  inheriting `zig-0.15` while overriding the origin dropped that.  The build
  never used it -- `prepare-source` overwrites `stage1` with the zig1 that
  Guix bootstrapped -- but it had no business being there.
- **opentui** vendors the same prebuilt tree-sitter grammars this file now
  builds from source; only `packages/core/src/zig` is used here.
- **parcel-watcher** vendors watchman's Windows binaries for its test suite.
- **bun-webkit** carries ~180 compiled fixtures per revision under `JSTests`,
  `LayoutTests`, `PerformanceTests`, `WebDriverTests` and `Websites`, plus a
  prebuilt Android profiler in Skia and archive-tool test data in BoringSSL.
  A JSCOnly build reads none of them.  The snippet deletes the binaries rather
  than the directories, so nothing the build might reference disappears, and
  it matches on magic rather than extension -- several have no extension
  (`perfhost`, a musl test binary) or carry one after it
  (`emu_bench_bg.wasm.release`).

An aside that cost time: `/tmp` here is a 30 GB tmpfs, and twenty-one
`--keep-failed` build directories had filled 12 GB of it, so the WebKit
checkout failed with "No space left on device" while the store still had
100 GB free.

## Result: no compiled artefact enters the build

Measured against opencode's full build closure -- 1569 derivations, 12 unpacked
source trees, 11 `node_modules` inputs -- **zero** compiled artefacts are
present, detected by magic number (ELF, WebAssembly, PE, Mach-O, `ar`) rather
than by filename.  Ten native artefacts are built from source and verified
present in the compiled binary after every build.

The last round removed two remaining pockets:

- `Tools/TestWebKitAPI` in WebKit's tree held two macOS app-extension
  binaries.  The directory list now covers all of `Tools`; since the snippet
  deletes files by content and not by directory, build scripts there are
  untouched.
- emscripten's `test/` held three small WebAssembly fixtures.

### How the audit was got wrong twice, and what settled it

Both wrong answers came from measuring something adjacent to the question.

The first audit matched on file *extension*.  That reported `COPYING.LIB` and
`.babelrc.lib` as binaries, and it counted `JSTests/wasm/v8/incrementer.wasm`
-- a JavaScript file starting with `//@ requireOptions` -- as WebAssembly.  The
filter built on that list would have deleted three babel configs.  Matching on
magic number fixed both directions.

The second audit walked derivation files with a regular expression and
collected every store path that looked like a fixed-output.  That picked up
stale checkouts still sitting in the store from earlier builds, and reported
364 artefacts for a closure that contained none of them.  Two things settled
it: the build log names the checkouts it actually unpacked, and `guix gc
--delete` removed all six stale trees without complaint, which it will not do
for anything a live closure needs.  Re-running the audit afterwards gave zero.

Worth remembering: a store path being present on disk says nothing about
whether the build used it, and `guix gc --requisites` on a `.drv` lists
derivations, whose hashes differ from the outputs they produce -- grepping the
one for the other proves nothing.

### What "from source" does and does not mean here

It means: every compiled artefact in the build is compiled during the build,
from source, by this channel or by Guix.  Bun, its WebKit fork, its Zig fork,
emscripten's toolchain, the tree-sitter runtime and grammars, opentui's Zig
library, bun-pty's Rust library and the parcel-watcher addon are all built
here.

It does not mean the JavaScript is built from source.  opencode's npm
dependency tree is still consumed as a `node_modules` directory produced by
`bun install`; what ships in those packages is npm's build output.  Nothing
binary survives into the derivation, but the JavaScript is taken on trust.
That, and the 16 local-path inputs, are what stand between this and something
upstreamable.

## Session updates: the archives

The previous section's audit scanned unpacked source *directories*.  Of the 700
source inputs in opencode's closure, only 12 are directories -- the other 111
(the rest are patches and JSON) are **archives**, and nothing had looked inside
them.  They held **2828 compiled files**:

| count | archive | what |
| --- | --- | --- |
| 1404 | `crate-winapi-x86_64-pc-windows-gnu-0.4.0` | mingw import libraries |
| 1376 | `crate-winapi-i686-pc-windows-gnu-0.4.0` | mingw import libraries |
| 20 | `bun-v1.3.8` | test fixtures, `libtcc1.a.macos-aarch64` |
| 11 | `bun-vendor-mimalloc` | Windows DLLs, `minject.exe` |
| 7 | `bun-vendor-boringssl` | `util/ar` test data |
| 6 | `bun-stage0-mimalloc` | Windows DLLs, injectors |
| 4 | `bun-v1.0.0` | fuzzing corpus, `libtcc1.a.macos-aarch64`, wasm fixtures |

The two winapi crates are pulled in by `rust-pty`'s lockfile for Windows
targets that are never built here; Guix's own `rust-winapi-*-pc-windows-gnu`
packages delete the same files.

`%strip-compiled-artefacts` is now a shared origin snippet -- matching on magic
number, so a `.wasm` that is really JavaScript survives -- applied to every
crates.io source, every vendored C/C++ source, both Bun tarballs and the
stage 0 mimalloc fork.  Guix repacks the results as `.tar.zst`; the build's
`tar xf` handles that, since zstd is already on PATH.

### Where the count now stands

- Sources that builds unpack: **0** compiled artefacts, across 310 items
  (12 checkouts plus the repacked archives) -- with one exception below.
- `node_modules` inputs: **0**, across 11 items.
- The compiled binary: **0** of the 51 prebuilt blobs, and all ten
  source-built artefacts present.

The exception is `llvm-project-20.1.8-checkout`, which carries 941 binaries,
all under `llvm/test`, `lld/test` and `lldb/test`: sancov inputs, llvm-cov
format samples, object-file fixtures.  That is Guix's own LLVM source, shared
by `llvm-20`, `lld-20`, `clang-20` and this channel's `clang-for-emscripten`.
Stripping it means overriding the source on all four and rebuilding LLVM, lld
and clang from scratch -- hours of work whose only effect is to *diverge* the
toolchain from the binaries Guix builds and publishes.  Left alone
deliberately; it is upstream test data that nothing compiles, links or ships.

Raw upstream downloads still contain their 2828 files, necessarily: an origin
snippet cannot filter a tarball it has not fetched.  What changed is that no
build unpacks them any more.

## The LLVM question, and where the real boundary is

The one source tree still holding compiled files is Guix's LLVM checkout: 941
in 20.1.8, 934 in 19.1.7, every one under `llvm/test`, `lld/test` or
`lldb/test`.  I built the machinery to strip them -- `without-test-binaries`
applied to llvm, lld and clang, rewired through `clang-for-emscripten` and
Bun's toolchain -- and then checked whether anything reads them:

```
$ grep -rl test-linux_x86_64 llvm/test/tools/sancov/
llvm/test/tools/sancov/symbolize_noskip_dead_files.test
llvm/test/tools/sancov/ignorelist.test
llvm/test/tools/sancov/merge.test

RUN: sancov -merge %p/Inputs/test-linux_x86_64.0.symcov | FileCheck ...
```

They are lit test inputs, and `llvm-19` and `llvm-20` both build with
`#:tests? #t`.  Deleting them means also passing `#:tests? #f`, giving up the
compiler's own test suite to remove data files that are never compiled, linked
or shipped.  That is a worse position than the one it fixes, so the change was
reverted; the derivation hashes back to the artefact already verified.

### What actually remains

Checking which packages were compiled here rather than fetched:

| package | origin |
| --- | --- |
| `gcc-14.3.0` | substitute |
| `glibc-2.41` | substitute |
| `llvm-19.1.7`, `clang-19.1.7`, `lld-19.1.7` | substitute |
| `llvm-20.1.8` | substitute |
| `lld-20.1.8`, `clang-20.1.8`, `clang-for-emscripten` | built here |

So the compiler that builds Bun, WebKit and everything else arrived as a
prebuilt binary from Guix's build farm.  Every snippet in this file addresses
files that no build reads; this is a real binary that every build runs.

That is not a defect in the packaging, and it is not something a snippet can
reach.  Guix's substitutes are reproducible builds of the same derivations --
`guix challenge` verifies them against independent builders -- so the software
is from source in the sense that matters, just not compiled locally.  Building
it locally is one flag, `--no-substitutes`, and days of CPU: GCC, glibc, LLVM
twice over, then WebKit twice and Bun.  Below that sits Guix's bootstrap seed,
which only the Full Source Bootstrap removes.

The honest summary: within what this channel controls, no compiled artefact
enters the build.  Beyond it lies Guix's toolchain, where "from source" is
Guix's guarantee rather than this channel's.

## The bottom of the stack

Two checks finish the question.

**Is the substituted toolchain what it claims to be?**  `guix challenge`
against ci.guix.gnu.org and bordeaux.guix.gnu.org: `gcc`, `glibc`, `llvm@19`,
`clang@19`, `lld@19` and `llvm@20` are **6/6 byte-identical** -- two
independent builders produce the same output from the same sources.  Across a
wider set of 22 items, 20 are identical; the two that differ are
`binutils`'s `share/doc/gprofng/examples.tar.gz` and `python`'s bundled
`pip-...whl`, both archives whose embedded timestamps make the container
non-reproducible.  No executable code differs.  A `--no-substitutes` rebuild
would spend days producing bytes two other machines have already shown to be
identical.

**What is underneath?**  The closure bootstraps through Guix's full source
bootstrap: a 24-package `mesboot` chain -- mes-boot 0.25.1, tcc, gcc-mesboot0
2.95.3, glibc-mesboot0 2.2.5, gcc-mesboot1 4.6.4, gcc-mesboot 4.9.4 -- so gcc
and glibc are themselves built from source rather than seeded from a prebuilt
compiler.

What remains is `guile-bootstrap-2.0`, 14 MB.  That is the interpreter Guix
uses to *run* derivations; no build can happen without it, and no packaging
change reaches it.  It is Guix's binary seed, shared by every package in the
distribution.

### Final position

| layer | status |
| --- | --- |
| opencode's native artefacts | ten built from source, verified in the binary |
| this channel's sources and archives | 0 compiled artefacts |
| `node_modules` inputs | 0 compiled artefacts |
| Guix toolchain binaries | substituted, reproducible (verified) |
| gcc, glibc | built from source via the mesboot chain |
| `guile-bootstrap` | 14 MB binary seed, irreducible |

Every prebuilt binary that packaging can remove has been removed.  The one
that is left is the seed Guix itself stands on.

## The JavaScript side, measured

The native side is finished; the npm tree is not, so here is its actual shape.
1812 unique packages, 6168 instances across bun's isolated layout:

| shape | count |
| --- | --- |
| plain `.js` at the package root -- no build step, already source | 2752 |
| ships `src/` alongside its output -- rebuildable in place | 511 |
| ships only `dist/`, `lib/` or `build/` -- prebuilt JavaScript | 2905 |

So a little under half the tree is already source or trivially rebuildable.
The remaining ~2905 would each need their upstream repository plus their own
build toolchain, and those toolchains -- typescript, rollup, babel, esbuild --
are themselves npm packages distributed as built output.  That makes it a
bootstrapping problem rather than a packaging one, and it is the same wall the
wider Guix node ecosystem runs into; it cannot be closed inside this channel.

Together with the 16 local-path inputs, this is what stands between the
current state and something upstreamable.

## LLVM, revisited -- and closed

The earlier conclusion ("cannot strip LLVM without disabling its test suite")
was too broad.  Only `llvm` itself builds with `#:tests? #t`; `clang-20` and
`lld-20` both have tests off, and those two are exactly the packages compiled
locally here.  Their sources can be stripped with nothing lost.

`without-test-binaries` now applies to `clang-for-emscripten` and a
`lld-20-from-source`.  The stripped checkout has 150273 files and **0**
compiled artefacts, down from 941.

The unstripped `llvm-project` checkouts belong to `llvm-19` and `llvm-20`,
which arrive as substitutes and therefore never unpack their sources.  `guix
gc --delete` removed both without complaint -- 1.57 GiB -- and opencode still
resolves to the same output with nothing to rebuild, which is the proof that
no build reads them.

Final audit: **112 sources that builds unpack, 0 compiled artefacts.**

Also checked and clean, having never been scanned before: opencode's own source
checkout, 3782 files, 0.

The picture is now complete.  Every prebuilt binary that any packaging change
can reach has been removed.  What is left is `guile-bootstrap` (14 MB), the
interpreter Guix runs derivations with, and the npm JavaScript described above.

## Runtime verification

Byte-level checks prove the right artefacts are embedded; they do not prove the
binary uses them.  What has been exercised on the finished binary:

- `libopentui.so` -- the startup banner renders with truecolor escapes, which
  only happens if the Zig library loaded and ran.
- The runtime as a whole -- `opencode serve` starts and answers `/doc` with the
  OpenAPI schema and `/config` with the resolved configuration.
- The six grammars and the tree-sitter runtime -- verified compositionally:
  the exact bytes embedded in the binary were loaded under the published glue
  and produced parse trees identical to the npm stack for all six languages.
- `librust_pty.so` and `watcher.node` -- verified compositionally: same
  exported symbols, and the watcher produced the same create/update/delete
  event sequence as the prebuilt addon.

The tree-sitter and pty paths are reached only from a live agent session, so
they are verified through their components rather than end to end.

## The JavaScript side, scoped properly

The earlier figure -- 2905 packages shipping only built output -- described the
whole install tree, and was the wrong denominator.  opencode compiles with
`bun build --compile`, which bundles only what it imports, so what matters is
the set that actually reaches the binary.  Counting the `node_modules/<pkg>`
references embedded in the compiled output gives **253 packages**:

| shape | count |
| --- | --- |
| plain `.js` at the package root -- already source | 103 |
| ships `src/` -- rebuildable in place | 17 |
| ships only built output -- prebuilt JavaScript | **110** |
| not found in the tree (builtins, aliases, noise) | 23 |

So the real remaining gap is 110 packages, not 2905, and just under half of
what ships is already source.

Those 110 come from **80 upstream repositories**, and the distribution is
lopsided:

| packages | repository |
| --- | --- |
| 20 | github.com/vercel/ai |
| 5 | github.com/actions/toolkit |
| 3 | github.com/solidjs-community/solid-primitives |
| 3 | github.com/googleapis/google-cloud-node-core |
| 2 each | bombshell-dev/clack, gitlab-org/editor-extensions, TooTallNate/proxy-agents |
| 1 each | 73 others |

A single monorepo, vercel/ai, accounts for a fifth of the gap.  This is a
bounded packaging effort rather than the open-ended bootstrapping problem the
earlier figure suggested -- though the bootstrapping character remains, since
these packages are built with TypeScript, rollup and friends, which are
themselves distributed as built output.

## Building npm packages from source: proof of concept

`@ai-sdk/provider` is one of the 110, and vercel/ai is the largest group at 20.
Two things make it tractable:

- The monorepo tags releases per package, and one commit is consistent: at
  `ai@5.0.124`, `packages/provider` is exactly the 2.0.1 that is installed.
- Its build is `tsup`, whose config here is four lines -- entry `src/index.ts`,
  formats cjs and esm, sourcemaps, and `dts`.  tsup is esbuild plus a
  declaration generator, and declarations are types only: `bun build --compile`
  never reads them.

So the build reduces to two esbuild invocations, using the esbuild Guix already
builds from source -- the same substitution that replaced rollup for acorn in
the emscripten package:

```
esbuild src/index.ts --bundle --platform=node --format=cjs --sourcemap -o dist/index.js
esbuild src/index.ts --bundle --platform=node --format=esm --sourcemap -o dist/index.mjs
```

The result exports exactly the same 18 names as the published build, with no
difference in either direction.  Same names is necessary rather than
sufficient, but the input is the same source at the same tag.

What full integration needs beyond this: dependency ordering within the
monorepo, `--external` for the packages that depend on each other rather than
bundling them, generated `package.json` files, and a substitution phase like
the one used for the native artefacts.  Not done yet.

## First npm packages built from source

`vercel-ai-from-source` builds the `ai` and `@ai-sdk/*` packages from the
monorepo at the `ai@5.0.124` tag -- 46 packages, of which 20 are the ones
opencode bundles.  The build is a small Node driver that reads each
`package.json`, keeps its dependencies and peer dependencies external as tsup
does, and runs esbuild twice per package.  Node and esbuild are the only tools
involved, both already built from source by Guix.

Validation before integration: all 24 relevant packages were swapped into a
copy of the real `node_modules` tree and imported under Bun.  All 24 exported
identical name sets to the published builds, with no difference in either
direction.

Integration took two attempts, and the first one failed silently in a way worth
recording.

**Attempt one produced a byte-identical binary.**  The phase walked
`node_modules/.bun/*/node_modules` and reported "replaced 274 files", but
opencode's own build resolves against `packages/opencode/node_modules`, which
it never visited.  The log looked like success; only comparing the output
against the previous build showed nothing had changed.  That is the third time
in this project a substitution has reported success while changing nothing --
`cmp` against the previous artefact is the check that catches it.

**A worse bug was one line below.**  Bun's layout keeps several versions of the
same package side by side: `@ai-sdk/anthropic` appears at 2.0.0, 2.0.56 and
2.0.58.  The build produces one version, so overwriting every copy would
silently mix releases.  The phase now reads each copy's `package.json` version
and replaces only exact matches -- on the current tree, 264 files replaced and
30 copies correctly left alone.

The binary changed as a result (110018937 bytes, against 110123235), still
runs, and `/config/providers` still returns the full provider catalogue, which
is served through the SDK that was rebuilt.

20 of the 110 prebuilt-JavaScript packages are now built from source.

## Two recipes cover the npm packages

The 90 remaining prebuilt-JavaScript packages split by how they are built.
Reading the published manifests: 11 `tsc`, 6 `tsup`, 4 `rollup`, 3 `unbuild`,
3 `pkgroll`, 16 other, and 47 with no build script at all -- npm trims the
manifest, so the real one is upstream.  Both shapes reduce to esbuild:

**Bundled** (tsup, pkgroll, unbuild, rollup) -- one bundle per format, with
dependencies external:

```
esbuild src/index.ts --bundle --platform=node --format=cjs -o dist/index.js
esbuild src/index.ts --bundle --platform=node --format=esm -o dist/index.mjs
```

Proven and integrated: the 20 vercel/ai packages.

**Per-file** (tsc) -- no bundling, one output per input, preserving layout:

```
esbuild src/*.ts --outdir=lib --format=cjs --platform=node
```

Proven on `@actions/core` 1.11.1: 28 exports, identical to the published
build, verified by swapping into a real node_modules tree and importing under
Bun.

### What the remaining work actually is

Not uniform.  Each package needs its upstream repository, the commit for its
exact version, its entry point, and its externals.  `actions/toolkit`
illustrates the friction: it does not tag most releases, so `@actions/core`
1.11.1 had to be found by walking `git log` over `packages/core/package.json`
looking for the version bump -- the same technique peechy needed.

So: 90 packages across roughly 79 repositories, two known recipes, and
per-repository detective work for the commit and layout.  Mechanical, but not
automatic.

## A provenance limit worth stating

Working through `@actions/*` surfaced something that applies to the whole npm
tranche.  Four of the five packages opencode uses have a commit on the main
branch where the version matches:

| package | version | commit |
| --- | --- | --- |
| `@actions/core` | 1.11.1 | d14afd7973c037fa9f72882decd1eb3befa36135 |
| `@actions/exec` | 1.1.1 | af45ad8eaa9ccbb742e6c2967385a85becf6527a |
| `@actions/http-client` | 2.2.3 | d1aa255c7fc5c25f2faebbb54d35bd98d9894150 |
| `@actions/io` | 1.1.3 | 457303960f03375db6f033e214b9f90d79c3fe5c |

`@actions/github` 6.0.1 has none.  The main branch's history for that file
stops at 6.0.0; 6.0.1 exists only on unmerged branches, among them
`joshmgross/github-6.0.1-release-notes`.  And none of the five records a
`gitHead` in its published manifest, so npm carries no pointer back to a
commit either.

That is a limit on what "from source" can mean for npm packages, distinct from
the toolchain question.  For a Guix origin one still has to *pick* a commit,
and for `@actions/github` 6.0.1 any pick is a plausible guess rather than the
source the published artefact was built from.  Nothing verifies the choice:
there is no tag, no `gitHead`, and npm publishes no build attestation for these.

Where a version does correspond to a commit, building from source is honest.
Where it does not, the best available claim is "built from the upstream sources
for that version", which is weaker than what the native artefacts in this
channel can claim -- those are pinned to exact commits with hashes.

## Second tranche: @actions/*

Four of the five landed -- `core` 1.11.1, `exec` 1.1.1, `http-client` 2.2.3,
`io` 1.1.3, each from the commit where its version was set.  `@actions/github`
6.0.1 is left prebuilt for the reason above: no commit can honestly be claimed
as its source, and guessing one would make the from-source claim weaker than
it looks.

Their layout differs from the bundled packages -- per-file `lib/*.js` rather
than `dist/index.{js,mjs}` -- so the substitution phase was generalised: a
built package is now a directory tree, and every file in it is copied to the
same relative path inside the target, whatever the shape.  `vercel-ai-from-source`
emits into `dist/` to match, and both are driven by the same code.

The version guard carried over and still matters: 323 files replaced, 30
copies deliberately left alone because they sit at versions other than the one
built.

The binary changed again (109993911, from 110018937), runs, and still serves
`/config/providers`.

**24 of 110** prebuilt-JavaScript packages now built from source.

## Third tranche, and a correction to the count

`agent-base` 7.1.4 and `https-proxy-agent` 7.0.6 were built from source
(one commit covers both) and substituted.  The binary came out byte-identical
to the previous one, and chasing that produced a correction worth recording.

`@clack/core` and `@clack/prompts` were dropped from the tranche first: unbuild
inlines `wrap-ansi`, one of their devDependencies, into the published bundle,
so building them from source needs wrap-ansi's sources as well, and its
dependencies after that.  That is the bootstrapping character showing up in a
concrete package rather than in the abstract.

**The count of 110 was measured wrong.**  It came from `node_modules/<pkg>`
strings embedded in the binary, and those appear for packages whose code is
never bundled -- sourcemap paths and dynamic-require metadata mention them.
`"https-proxy-agent"` occurs 12 times in the binary; `"Creating a proxied
socket"`, an actual string from its code, occurs zero times.  Re-measuring by
looking for string literals drawn from each package's own JavaScript:

| | count |
| --- | --- |
| referenced by name | 110 |
| code demonstrably shipped | 53 |
| referenced but code absent | 2 |
| no distinctive literal, undecided | 55 |

So the real target is somewhere between 53 and 108, not 110, and two of the
packages this tranche built are among the ones that never ship.  Their
substitution is correct and harmless -- it simply cannot change the output.

The lesson repeats one from earlier in this file: a name appearing in a binary
is not evidence that its code is there.  The check that settles it is whether
replacing the package changes the compiled artefact, and for these two it
provably cannot: building a minimal program against each version gives
different minified output (4262 against 3917 bytes), so a real substitution
would have shown up.

## How many packages actually ship: an honest range

Two attempts to pin the number disagree, and the disagreement is the useful
result.

Requiring a distinctive literal (24-60 characters) from each package's own
JavaScript to appear in the binary: **53 shipped, 2 absent, 55 undecided** --
the undecided ones simply have no literal that long.

Lowering the bar to 12 characters, keeping only strings containing a space or
a slash or longer than 20: **93 shipped, 1 absent, 16 undecided**.  But that
admits strings like `application/json`, which occur in many packages and in the
binary regardless, so some of those 93 are false positives.

The true figure is somewhere between the two, and this method cannot narrow it
further.  What would settle it is bun's module graph for the real build.
Reproducing that outside the derivation got as far as resolving every import --
workspace links, hoisted dependencies, the wasm assets this channel strips and
substitutes -- before running into opencode's JSX configuration, which its own
`script/build.ts` sets up.  Finishing that is the way to an exact answer.

One conclusion is solid regardless: `https-proxy-agent`'s code is not in the
binary.  Its distinctive string `Creating a proxied socket` appears zero times,
while its *name* appears twelve times as a path.  A name in a binary is not
evidence its code is there.

## Correction: the module graph, and a claim that was wrong

Reproducing opencode's bundle finally worked, and it overturns the previous
two sections.

`Bun.build` with the same options the real build uses -- `conditions:
["browser"]`, `target: "bun"`, the `@opentui/solid` plugin, the same defines --
and `sourcemap: "external"` produces a map whose `sources` array *is* the
module graph.  Getting there needed the workspace links, the hoisted
dependencies, the wasm assets this channel strips and substitutes, and the same
`lru-cache` interop patch the recipe applies to
`@babel/helper-compilation-targets`.

**1621 modules, 221 npm packages contributing code.**  Against the shapes:

| | count |
| --- | --- |
| already built from source here | 24 |
| plain `.js`, already source | 97 |
| ship `src/`, rebuildable in place | 16 |
| **prebuilt-only, still to do** | **84** |

**The earlier claim that `https-proxy-agent`'s code is not in the binary was
wrong.**  It is module number one of the packages I checked, and it is in the
graph.  The error was mine and worth naming precisely: the package's shipped
JavaScript contains no double-quoted literals, my extraction returned nothing,
and I then searched the binary for `Creating a proxied socket` -- a string I
had invented as "a plausible debug string" rather than taken from the package.
It is not in the package at all.  Its real literals are single-quoted:
`Creating new HttpsProxyAgent instance: %o` occurs twice in the binary.

So the counts of 53 and 93, and the range built on them, were both measuring
noise.  The number is 84, and it comes from the bundler rather than from
guessing at strings.

Why substituting `agent-base` and `https-proxy-agent` left the binary
byte-identical is therefore still unexplained, and remains the open question.

### Unresolved: why two packages made no difference

Four attempts to explain why substituting `agent-base` and `https-proxy-agent`
left the binary byte-identical, none conclusive:

1. Swapped the workspace copy in a reproduced tree -- bundle unchanged, but the
   sourcemap showed the bundler had resolved `.bun/node_modules/agent-base`
   in the *store*, so the wrong copy was swapped.
2. Materialised `.bun/node_modules` locally and swapped there -- still resolved
   to the store.
3. Repointed the workspace symlinks at the local tree, confirming the resolved
   file was the 5653-byte source build rather than npm's 7324 -- the sourcemap
   *still* named the store path.

The reproduction keeps reaching store copies through `.bun/<holder>/node_modules`
directories that the real recipe materialises but this scratch tree does not,
so it cannot settle the question.  What is known:

- Both packages are in the module graph, so their code does reach the binary.
- The substitution machinery works: for the vercel/ai and `@actions/*`
  packages the binary demonstrably changed, verified with `cmp`.
- For these two it did not, and the reason is still unknown.

The honest reading is that these two are unverified rather than done.  They are
not counted among the 24.

### Resolved: the hoisted directory was never visited

A probe printed from inside the phase settled it:

```
probe packages/opencode/node_modules/agent-base/dist/index.js -> 5653 bytes
probe node_modules/.bun/node_modules/agent-base/dist/index.js -> 7324 bytes
```

The workspace copy was the source build; the hoisted one was still npm's.

The loop iterated the entries of `node_modules/.bun` treating each as a
*holder* and looking inside `<holder>/node_modules`.  But `.bun/node_modules`
is itself an entry, and it is not a holder -- it is the shared directory that
holds packages directly.  So the phase looked for
`.bun/node_modules/node_modules`, found nothing, and skipped it.  Every
transitive dependency resolves through that directory, which is why replacing
only the workspace copies changed nothing for a package like `agent-base` that
opencode never imports directly.

Visiting it explicitly, and excluding it from the holder loop, takes the count
from 339 replaced files to **408**, and the binary changes: 109994295 bytes
against 109993911.  It still runs and still serves `/config/providers`.

This also means the earlier tranches were only partly applied.  `vercel/ai` and
`@actions/*` changed the binary because opencode imports them directly, so the
workspace copies were the ones that mattered; their transitive uses were still
coming from npm's builds until now.

Two lessons, both already visible earlier in this file and both ignored:
counting replaced files says nothing about whether the right files were
replaced, and a phase reporting success is not evidence.  What settled it was
printing the state of the tree the build actually reads.

## Fourth tranche, and a pattern in what resists

`@agentclientprotocol/sdk` 0.14.1 built from source and substituted; the
binary changed (111101497 bytes, from 109994295) and still serves.  The
builder gained comma-separated `<format>:<output>` pairs so a package can emit
CommonJS and ESM side by side, as tsup and pkgroll do.

Three packages were attempted and deferred, all for the same reason, which is
now clearly the dominant obstacle:

| package | inlines |
| --- | --- |
| `@clack/core`, `@clack/prompts` | `wrap-ansi` |
| `@openrouter/ai-sdk-provider` | `@ai-sdk/provider`, `@ai-sdk/provider-utils` |

Each declares those as **devDependencies**, and its bundler inlines them into
the published artefact.  Reproducing that from source means supplying those
packages' sources too -- and theirs in turn.  `@standard-community/standard-json`
is deferred for a different reason: pkgroll emits hash-named code-split chunks
(`arktype-aI7TBD0R.js`), which cannot be reproduced without matching the
bundler exactly.

So the remaining 81 are not uniform.  A package that only bundles its own
source is a few lines of data; one that inlines devDependencies drags in a
subtree, and one with content-hashed chunks needs the original bundler.  That
distinction, rather than the count, is what determines how far this can go.

## The count, once more -- and this time it adds up

Classifying a package as "prebuilt" because it ships `lib/` was wrong for a
third of the remainder.  Plenty of npm packages have no build step at all:
`jws`, `tunnel`, `json-bigint`, `cross-spawn` and friends ship hand-written
JavaScript under `lib/`, which is their source.  Checking for a build script
*and* for signs the JavaScript was generated -- a `sourceMappingURL` comment,
or lines over 600 characters -- separates them.

Of the 221 packages contributing code to the binary:

| | count |
| --- | --- |
| plain `.js` at the package root, already source | 97 |
| `lib/` of hand-written JavaScript, already source | 27 |
| ships `src/`, rebuildable in place | 16 |
| built from source by this channel | 27 |
| **genuinely built output, still to do** | **54** |

That totals 221.  Earlier figures -- 2905, 110, 84, 81 -- were each measuring
something slightly different and none of them were this.  The progression is
not flattering, and the cause was the same every time: classifying by file
layout instead of by what the package actually is.

Of the 54, the ones that only bundle their own source are a few lines of data
each.  The ones that inline devDependencies need those sources supplied first,
and the ones emitting content-hashed chunks need their original bundler.

## Fifth tranche

`ai-gateway-provider` 2.3.1 and `opentui-spinner` 0.0.6 built from source and
substituted; the binary changed and still serves.  Both bundle only their own
sources, so each is six lines of data.

Finding them was automated: for a batch of candidates, clone, walk `git log`
over the manifest holding that package name until the version matches, then
attempt an esbuild build with the declared dependencies external.  Of the
first batch, two built cleanly, two had no commit carrying the published
version within the first eighty touching the manifest, and one --
`@mixmark-io/domino` -- turned out to have no `src/` at all: its `lib/` is
hand-written JavaScript, one more package the classifier had wrongly called
built output.

**29 packages** now built from source.

## Sixth tranche: twelve at once, and a near miss

Discovery was automated across every remaining candidate: clone, walk `git log`
over the manifest carrying that package name until the version matches, then
attempt an esbuild build with declared dependencies external.  Across 43
candidates:

| verdict | count |
| --- | --- |
| builds cleanly | 21 |
| no TypeScript source -- already source | 13 |
| no commit carries the published version | 5 |
| needs devDependency sources | 4 |

Thirteen more "already source" packages, which is the fifth time the
classifier has over-counted; the discovery script settles it per package
instead of by layout.

Twelve of the buildable ones were added in one batch: `hono`, `hono-openapi`,
`@hono/standard-validator`, three `@solid-primitives/*`, both
`@standard-community/*`, `@vercel/oidc`, `bonjour-service`, `quansync`,
`zod-to-json-schema`.  531 files replaced, the binary changed (111085205 from
111099837) and still serves both `/config/providers` and `/doc`.

**The near miss is worth recording.**  The output mode was first derived from
the file layout -- `dist/index.js` was assumed to be CommonJS.  Checking each
file's actual contents for `export` against `module.exports` showed **eight of
twelve were ESM**, including all of `hono`, `@solid-primitives/*` and
`@standard-community/*`.  Building those as CommonJS would have produced a
binary that linked and ran until the first import of them.  Deriving the format
by reading the file, rather than by guessing from its extension, is the only
version of this that is safe.

**41 packages** now built from source.

## Seventh tranche: inlined devDependencies, and a define that broke the binary

`@openrouter/ai-sdk-provider` 1.5.4 is the first of the packages whose bundler
inlines devDependencies rather than leaving them external.  The spec grew a
final field for it: tokens prefixed `+` are aliased to this channel's own build
of that package, the rest become extra externals.  So what gets inlined into
`@openrouter/ai-sdk-provider` is this channel's `@ai-sdk/provider` and
`@ai-sdk/provider-utils`, not npm's -- which is the point.

That took three passes.  The aliases resolved but the inlined packages brought
their own imports (`eventsource-parser/stream`, `@standard-schema/spec`, `zod`)
which then had to be externalised, hence the two-kind field.

**Then the binary built cleanly and crashed on startup:**

```
ReferenceError: __PACKAGE_VERSION__ is not defined
      at node_modules/@openrouter/ai-sdk-provider/dist/index.mjs:4597:16
```

Upstream's tsup config substitutes `__PACKAGE_VERSION__` at build time.  Left
undefined it survived into the output as a free variable and threw the moment
the provider was loaded.  esbuild now receives
`--define:__PACKAGE_VERSION__="<version>"`.

This one is worth dwelling on.  The build succeeded, the substitution
"worked", and `cmp` said the binary had changed -- every signal this file has
been relying on said success.  Only running the binary caught it.  Byte
comparison proves a substitution took effect; it says nothing about whether the
result is correct, and reproducing a package means honouring its bundler's
defines, not just its entry point and format.

Verified after the fix: the server lists seven providers and `openrouter` is
among them, which is the code that was rebuilt.

**42 packages** now built from source.

## The audit the crash prompted, and what it found

After `__PACKAGE_VERSION__` crashed the binary, the same class of defect was
looked for across everything built here: scan each output for identifiers that
a bundler config would normally substitute.

It was already shipping.  `ai/dist/index.mjs` -- from the very first tranche,
declared verified at the time -- carried **140 occurrences** of
`__PACKAGE_VERSION__`, and the binary in the store carried 36.  npm's build of
the same file has none, because tsup substitutes it.  Any code path touching
one would have thrown `ReferenceError`; none of `--version`, `/config/providers`
or `/doc` happens to touch them, which is why nine rounds of "verified" missed
it.

The vercel/ai builder now passes the define too, written as
`--define:__PACKAGE_VERSION__=${JSON.stringify(meta.version)}` -- the obvious
spelling with literal quotes terminates the surrounding Scheme string, which
cost a build to discover.  The rebuilt `ai/dist/index.mjs` inlines `"5.0.124"`
and the binary now contains zero unresolved defines.

The rest of the scan was clean: `__PURE__` is an annotation inside a comment,
and the `process.env.*` hits are genuine runtime environment reads.

The lesson generalises past this one identifier.  Everything this file has been
using as verification -- the build succeeding, the phase's replaced-file count,
`cmp` against the previous artefact, a smoke test of two endpoints -- reports
success for a package that is broken on a path nobody exercised.  Reproducing a
package means reproducing its bundler's *configuration*, and the only cheap
check for that is scanning the output for what should have been substituted.

## The check is now part of the build

Scanning for unsubstituted identifiers is no longer something to remember; the
vercel/ai builder does it after every build and throws if anything survives:

```js
for (const m of readFileSync(p, 'utf8').matchAll(/\b__[A-Z][A-Z0-9_]*__\b/g))
  if (m[0] !== '__PURE__') leaked.push(`${p}: ${m[0]}`);
if (leaked.length) throw new Error('unsubstituted build-time identifiers: ' + ...);
```

`__PURE__` is exempt: it appears inside `/* @__PURE__ */` annotations.
esbuild's own helpers (`__toESM`, `__commonJS`, `__defProp`) contain lowercase
letters and do not match the pattern.

The check was verified against a known-bad artefact rather than assumed to
work: run over the previous build of this package it reports 140 leaked
identifiers, over the current one it reports 0.  A check that has only ever
passed is not evidence of anything.

Writing it cost three builds, all on escaping: the JS lives inside a Scheme
string, so `\.` and `\b` must be written `\\.` and `\\b`, and a `\n` intended
for JavaScript became a real newline that split a string literal across two
lines.  The error message now uses `join('; ')` and no escapes at all.

## The check now guards all three builders

`actions-toolkit-from-source` and `npm-packages-from-source` scan their output
too.  Both are Scheme builders, so the check is written in Scheme rather than
JavaScript, and it reads line at a time with `(ice-9 rdelim)`: the obvious
`get-string-all` needs `(ice-9 textual-ports)`, which pulls in
`(ice-9 custom-ports)`, which this builder's Guile does not have.

Both report zero, as does vercel/ai.  All three artefacts were checked with the
same standalone scanner used on the known-bad build, so "zero" means the
scanner ran and found nothing rather than the check being inert.

Getting there cost four failed builds, every one an editing mistake rather than
a packaging one: a module list edited on the first match in the file instead of
the intended package, a paren count that left the check outside the builder's
gexp, and the module that does not exist here.  Worth noting because none of
them were about the problem being solved.

## Eighth tranche: dual cjs/esm layouts

Six more: `diff`, `gaxios`, `gcp-metadata`, `google-logging-utils`, `isexe`,
`signal-exit`.  All six had been skipped because their output does not fit a
single shape -- they ship CommonJS and ESM in sibling trees
(`libcjs`/`libesm`, `build/cjs/src`/`build/esm/src`, `dist/cjs`/`dist/mjs`).

The builder now takes a comma-separated list where each part is either
`transpile:<dir>[:<format>]` (one output per input, as tsc emits) or
`<format>:<file>` (a bundle), so a package can mix them:

```
gaxios      transpile:build/cjs/src:cjs,transpile:build/esm/src:esm
diff        esm:libesm/index.js,cjs:libcjs/index.js
isexe       transpile:dist/cjs:cjs,transpile:dist/mjs:esm
```

705 files replaced, the binary changed, no unsubstituted identifiers, still
serves.

Getting the builder to that shape took several failed evaluations from
patching parentheses in a deeply nested gexp.  The fix was to stop patching and
rewrite the whole package definition in one piece, then confirm the output was
byte-identical to the previous build before adding anything new -- so the
refactor and the new packages could not be confused for each other.

**48 packages** now built from source.

## Ninth tranche, and a gap in the discovery method

`@modelcontextprotocol/sdk` 1.25.2 built from source: 954 files replaced, the
binary changed, still serves.

Finding it exposed a flaw in the discovery script.  It looked for the version
only by walking `git log` over the manifest, and reported NO_COMMIT for five
packages.  All five are in fact tagged:

| package | tag |
| --- | --- |
| `@modelcontextprotocol/sdk` | v1.25.2 |
| `remeda` | v2.26.0 |
| `ret` | v0.5.0 |
| `solid-js` | v1.9.10 |
| `vscode-jsonrpc` | release/jsonrpc/8.2.1 |

Checking tags first would have found them immediately.  The manifest walk is
the fallback, not the primary method -- backwards from how it was written.

Only the MCP SDK was added from that list.  Its ESM tree is rebuilt but its
CommonJS tree is not: several sources use top-level await, which esbuild cannot
emit as CommonJS.  Bun resolves the `import` condition, so the tree opencode
loads is the one built here, but the package is only half from source and is
counted that way.  `remeda` publishes a file per exported function, `ret` ships
hand-written `lib/`, and `solid-js` has a multi-step build that does not reduce
to esbuild.

**49 packages** built from source.

## @opentui/core: attempted, not landed

Worth recording because the approach was different and the failure is
instructive.

`@opentui/core` is bundled by bun itself -- `index.js` re-exports from
`index-h3dbfsf6.js`, a content-hash-named chunk that esbuild cannot reproduce.
But this channel builds bun from source, so upstream's own build script can be
run instead of approximated: `bun scripts/build.ts --lib`, which imports only
node builtins and needs no npm dependencies.

It gets as far as reporting every step succeeded:

```
Building library...
Post-processing bundled files to fix duplicate exports...
Note: skipping TypeScript declarations (types only)
  Copied tree-sitter assets (*.wasm, *.scm) to dist/assets/
Library built at: .../packages/core/dist
```

and `dist/` contains `assets/`, `LICENSE`, `package.json`, `README.md` -- and
no JavaScript at all.  The script does not check the exit status of its own
bundling step, so a failure there is reported as a successful build.  Only the
declaration step was patched (it needs `tsc`, and declarations are types
only); whatever stopped the bundler is unexamined.

Not landed.  `@opentui/core` remains npm's build, while the Zig library it
loads is built from source.  Given that the TUI depends entirely on this
package, a substitution that cannot be verified is worse than none.

## Tenth tranche: the GitLab pair

`@gitlab/gitlab-ai-provider` 3.5.0 and `@gitlab/opencode-gitlab-auth` 1.3.2.
Both had been skipped for a dull reason: the discovery sweep only considered
repositories whose URL contained `github.com`, so these were never examined.
Both are tagged, both build with esbuild, and each took one entry.

`npm-from-source-origin` now reads a repository given as `host/owner/name`
literally and treats a bare `owner/name` as GitHub, which most of them are.

Their formats went opposite ways -- `gitlab-ai-provider` ships CommonJS in
`dist/index.js` and ESM in `dist/index.mjs`, while `opencode-gitlab-auth`
ships ESM per-file in `dist/` -- so each was read out of the built file rather
than assumed, as with the eight that were nearly built in the wrong format.

972 files replaced, the binary changed, no unsubstituted identifiers, seven
providers still served.

**51 packages** built from source.

## @opentui/core, diagnosed

The earlier attempt was abandoned with "whatever stopped the bundler is
unexamined".  It is examined now, and there were two problems stacked.

The script calls `spawnSync("bun", ...)` and never checks the status, so with
`bun` absent from `PATH` it printed "Library built at: ..." over an empty
directory.  Putting bun on `PATH` gets the standalone parser worker built.

The main bundle then fails honestly:

```
error: Could not resolve: "yoga-layout"   at src/index.ts:18:23
error: Could not resolve: "jimp"          at src/3d/TextureUtils.ts:2:22
```

Neither is in the script's external list, so both are bundled in.  Building
`@opentui/core` from source therefore needs `yoga-layout` and `jimp` present --
the same dependency-subtree problem as clack, but with runtime dependencies
and larger ones, `yoga-layout` being a WebAssembly build of a C++ layout
engine.

Supplying them from the installed tree would work and would produce an
`@opentui/core` built from opentui's own sources with npm's `yoga-layout` and
`jimp` inlined -- better than the status quo, but partial in the same way the
MCP SDK is.  Not done, for a specific reason: opencode's entire terminal UI
runs through this package, and there is no way to exercise a TUI from this
harness, so a substitution here cannot be verified beyond "the binary still
starts".  The native library it loads is built from source; its JavaScript is
not.

## Eleventh tranche

`pkce-challenge` 5.0.1.  One `src/index.ts` produces three outputs; the two
node ones are rebuilt (`dist/index.node.js` as ESM, `dist/index.node.cjs` as
CommonJS) and the browser variant is left as published, since opencode
resolves the `node` condition and this builder always targets node.

980 files replaced, the binary changed.

**52 packages** built from source.

## @clack/*: tried, reverted

A promising-looking shortcut that does not work, recorded so it is not tried
again.

unbuild inlines `wrap-ansi` and `is-unicode-supported` into clack's published
bundle.  Both are hand-written JavaScript with no build step, so the idea was
to leave them external here and let opencode's own bundler inline them from the
tree -- same sources, same result, no extra machinery.  Both clack packages
build that way, and the substitution applied cleanly.

opencode then fails to bundle:

```
error: Could not resolve: "is-unicode-supported"
    at packages/opencode/node_modules/@clack/prompts/dist/index.mjs:9:32
```

Bun's isolated layout exposes a package's *dependencies*, not its
devDependencies, so opencode's bundler cannot resolve them either.  Marking
them external does not remove the problem, it relocates it from a build that
would have failed here to one that fails later.

Reverted; the artefact is byte-identical to the one before the attempt.  Doing
this properly means supplying those two packages' sources and aliasing to them,
which the alias field currently only supports for vercel/ai.

## @clack/core and @clack/prompts, via arbitrary-source aliasing

The earlier attempt marked clack's inlined devDependencies external and
failed: bun's isolated layout exposes a package's dependencies but not its
devDependencies, so opencode's own bundler could not resolve them either.
Marking them external relocated the failure rather than removing it.

The fix was to extend the alias mechanism.  It previously had exactly one
form, `+name`, meaning "alias to vercel/ai's build".  It now also takes
`^name`, meaning "alias to a source fetched purely so it can be inlined",
drawn from a new `%npm-alias-sources` list.

Two facts made this larger than it first looked.

`is-unicode-supported` is installed nowhere in opencode's tree -- it existed
only on the publisher's machine -- so its source had to be fetched outright.

`wrap-ansi` is worse than absent: clack pins `^8.1.0` and the copy in the
tree is 9.0.2.  Had the external route worked, it would have silently
bundled a different major version.  Pinning 8.1.0 then drags in that
version's own runtime closure -- string-width 5, strip-ansi 7, ansi-styles
6, ansi-regex 6, eastasianwidth 0.2, emoji-regex 9.2.2.  No recursion was
needed to satisfy it: `--alias` is global to a bun build, so listing the
closure alongside wrap-ansi resolves wrap-ansi's own imports too.

eastasianwidth carries no tags; 0.2.0 is the version in package.json at
af9ddb8, found by walking the history of that file.  `^0.2.0` excludes the
current 0.3.0.

One honest caveat.  Every package in that closure is single-file and
hand-written except emoji-regex, whose `index.js` upstream commits as babel
output with Unicode sequences injected by `script/inject-sequences.js`.
Rebuilding it would pull in babel, regexgen and @unicode/unicode-13.0.0.
This takes the file as upstream's version control carries it rather than as
npm ships it -- better provenance, but not a rebuild.

Verified: the binary differs from the previous artefact, and `auth list`
renders through clack's box drawing, so the from-source build is what runs.
The "multiple instances of Solid" warning was checked against the previous
binary and pre-dates this change.

That brings the count to 54 packages built from source.

## ret and vscode-jsonrpc, and a correction to the transpile mode

Both are zero-dependency TypeScript compiled per-file by tsc, so both fit
the existing transpile mode -- with two adjustments.

The transpile mode had the source directory hardcoded to `src/`.  ret keeps
its TypeScript in `lib/`, so the mode now probes for `src/` and falls back to
`lib/`.  ret's own package.json says version 0.0.0-development because
releases are cut by semantic-release; the v0.5.0 tag is the published
version.

vscode-jsonrpc is one package of the vscode-languageserver-node monorepo,
tagged release/jsonrpc/8.2.1.  esbuild takes the common ancestor of its
inputs as the output root, so src/{common,node,browser} land as
lib/{common,node,browser} and ./lib/node/main.js resolves.  The result
matches upstream's layout file for file.

The second adjustment came from reading the warnings rather than the exit
status.  The build succeeded but esbuild emitted warnings, all of them from
files that upstream does not ship: vscode-jsonrpc's src/node/test calls
`assert` as a function through a namespace import, and agentclientprotocol's
src/examples uses import.meta under CommonJS.  These are excluded by each
package's own tsconfig, which esbuild never reads.  The transpile mode now
skips test, tests, __tests__ and examples directories and .test.ts/.spec.ts
files, which both matches upstream and removes the warnings.  It also stops
shipping example code that requires modules absent at run time.

One warning was left standing after being checked: ret's lib/index.ts ends
with `module.exports = tokenizer`, which esbuild flags because the file also
uses ESM syntax.  It is benign here -- the assignment is emitted after
esbuild's own CommonJS wiring, so the callable export wins, exactly as tsc's
output does.  Confirmed by running both builds side by side: same export
shape (function/object/function) and identical tokenizer output for a test
pattern.

Verified: the binary differs from the previous artefact, --version, serve
with 7 providers, and auth list all work.  56 packages from source.

## remeda

Listed earlier as blocked because its dist has one file per exported
function.  That was the wrong reason to skip it.  The exports map has a
single "." entry pointing at dist/index.js and dist/index.cjs; the
per-function files exist for bundlers wanting finer tree-shaking and are not
reachable by name.  Bundling src/index.ts into both formats is all opencode
ever resolves.

type-fest is declared a dependency but contributes only types, and esbuild
erases imports used solely in type positions, so nothing needs marking
external.  As with ret, package.json in the repository carries a stale
version (2.0.0) because releases are cut by semantic-release; v2.26.0 is the
tag matching the installed copy.

Verified beyond the usual smoke test, because a missing export here would
break opencode at import time rather than at first call: both builds were
imported side by side and their export sets diffed -- 159 names, identical --
then pipe/map/sum, chunk and groupBy were run against both for identical
results.  `opencode models` was added to the smoke test since it exercises
this code path.

57 packages from source.

## Exhaustive prebuilt-binary audit of the whole build closure

Rather than assume the earlier result still held, the current artefact was
audited from scratch.  Every fixed-output derivation in opencode's build
closure -- 746 downloads and checkouts -- was scanned by magic number, ELF,
wasm, ar, Mach-O and PE, reading inside every tar and zip rather than
trusting file names.  3781 files matched.  They fall into five groups.

**winapi crates (2780 files), already handled.**  rust-pty's cargo closure
pulls winapi-x86_64/i686-pc-windows-gnu, which ship prebuilt Windows import
libraries.  The strip snippet removes all of them; the twelve `.a` files
that survive in the repack are plain text linker scripts (`INPUT( ... )`),
which is the correct outcome.  Confirmed on the repacked tar.zst, not on the
download.

**llvm-project checkout (946 files), accepted.**  Every one is under
`test/`, `unittest/` or an `Inputs/` directory -- zero outside.  These are
upstream's binary test fixtures.  They are never compiled, linked or
installed.  Stripping them would mean forking LLVM away from Guix proper and
rebuilding it for no change in output.

**bun and its vendored deps (48 files), already handled.**  These are the
pre-snippet originals.  A snippet cannot remove a file without the unstripped
download existing first as the input to the stripping step, so their presence
in the closure is structural.  The repacks are what the build consumes.

**actions/toolkit and vercel (6 files): real, and fixed.**  All four
actions/toolkit checkouts carry
`packages/tool-cache/scripts/externals/7zdec.exe`, a prebuilt Windows
executable, and the vercel monorepo carries two WebAssembly test fixtures.
Only a few packages of each monorepo are built, but the whole tree is the
input, and neither origin had a strip snippet.  The snippet is now applied by
all three checkout constructors -- `npm-from-source-origin`,
`actions-toolkit-source` and `npm-alias-source` -- so it also covers anything
added later.  All 44 consumed checkouts were re-scanned afterwards: zero
hits, and both files are gone.

**Guix's bootstrap seeds, irreducible.**  `bash`, `mkdir`, `tar` and `xz` as
statically linked i386 ELF, plus guile-2.0.9.tar.xz.  This is Guix's own seed
and is the same for every package in the distribution.

### Verdict

Every prebuilt binary that packaging can reach is gone.  What remains is
upstream test data that is never built, the unstripped inputs that stripping
itself consumes, and Guix's bootstrap seed.

### Two corrections to how this was being verified

The `cmp` check used to prove each new package "landed" was pointed at
`libexec/opencode/opencode`.  That path does not exist -- the binary is at
`bin/opencode` -- so `cmp` was comparing two absent files and its failure was
being reported as "DIFFERS (landed)".  The conclusions were right, but not
for the stated reason.  Re-checked properly by size across the chain:
111179083, 111285600 (clack), 111348114 (ret, vscode-jsonrpc), 111358869
(remeda), 111358884 (strip snippets).  Each change did land.  The same wrong
path silently emptied a `strings` check, which is why an earlier pass
reported no embedded store paths.

### A defect this uncovered

Chasing why stripping unused files changed the binary by 15 bytes led to the
cause: esbuild records each module's absolute path in its `__esm` annotations,
so store paths are embedded in the compiled binary as text.  Guix scans
output for store hashes, so those become *runtime references*.  The package
therefore retains bun-stage0, gcc, the grammar checkouts, the npm source
checkouts and both node_modules trees, for a closure of 4.6 GiB.  None of it
is needed to run.  The fix is the `materialize` treatment already used
elsewhere -- copy rather than symlink, so the bundler sees paths inside the
build directory -- but it is a separate piece of work.

## Cutting the runtime closure from 4.6 GiB to 853 MiB

esbuild records each module's absolute path in the `__esm` annotation it
emits, and bun resolves every module to its realpath.  The root node_modules
tree was symlinked from the store to keep the build directory small, so those
annotations named store paths, they survived into the compiled binary as
plain text, and Guix -- which scans output for store hashes -- registered the
whole 2.6 GiB cache as a *runtime* reference.  packages/util/node_modules
leaked the same way.  Copying both into the build directory instead took the
closure from 4628 MiB to 853 MiB.

The other workspace node_modules inputs are left symlinked deliberately:
they belong to packages the CLI does not bundle, and none of them appears in
the reference set.

### A latent bug this exposed

With the copy in place the build failed on `Could not resolve "./types"` from
google-logging-utils.  The substitution phase replaced a file only `(when
(file-exists? to)`, so it could overwrite what upstream shipped but never add
anything.  tsc drops a module whose exports are all types while esbuild keeps
it, so our build emits `types.js` where upstream's has none -- the require
between the two modules is real either way, and the file was being silently
discarded, leaving a dangling import.  The phase now creates the file when it
is missing.  This was always wrong; the symlinked layout merely hid it.

### The same leak in the npm builder

esbuild was also being run directly on store checkouts, which put their paths
in the built packages and from there into opencode.  Package sources and
alias sources are now copied into the build directory first.  The copy for a
package has to happen while the `let*` bindings are evaluated rather than in
the body, because `externals` shells out to node against that manifest before
the body runs.

### What still leaks, and why

gcc, glibc, icu4c and bun-stage0 remain, from strings inside the bun runtime
that opencode embeds -- assertion messages carrying __FILE__ and recorded
toolchain paths.  glibc and icu4c are genuine runtime dependencies anyway.
The two tree-sitter grammar checkouts remain via scanner.c paths in the wasm
debug info.  Fixing those means changing the bun and grammar builds, not
opencode's.

## @opentui/core

Previously set aside as needing yoga-layout and jimp inlined.  That was
half right.  The published bundle does inline jimp, yoga-layout, marked,
diff and bun-ffi-structs -- it imports nothing but node builtins -- but all
five are ordinary dependencies rather than devDependencies, and each is
installed in opencode's tree exactly once, so they can stay external and be
resolved there.  The clack problem does not arise.

The actual obstacle was different: esbuild cannot build this package at all.
opentui loads its grammars with `import x from "./....wasm" with { type:
"file" }`, and esbuild answers `Importing with a type attribute of "file" is
not supported`.  So the builder gained a bun bundling mode, which is what
upstream builds this package with.  A mode part spelled `bun:<dir>:<entry>`
runs bun instead of esbuild and translates the externals to bun's spelling.

The origin snippet strips the prebuilt grammars the repository vendors, so
the ones built by tree-sitter-wasm-grammars are copied into
src/lib/tree-sitter/assets/<language>/ first -- beside the module that loads
them, not at the top of src/, which is where the relative import points.
bun emits them as content-hashed assets next to the output.

Only two of the four entry points are built.  ./3d and ./testing import
three and planck, neither declared anywhere in opentui's manifest, and
opencode uses neither, so they stay as published.  parser.worker.ts imports
web-tree-sitter, a devDependency, but that one is hoisted into opencode's
tree and resolves as an external.

### Verifying it, and two checks that proved nothing

The TUI was finally driven rather than argued about: run under a pty it
renders the banner, the prompt, the model selector and the status bar, which
exercises yoga layout and the box drawing.

Two attempts at byte-level evidence failed and are recorded so they are not
repeated.  Searching the binary for bun's content-hashed asset names does
not discriminate, because the grammar bytes are identical either way -- they
come from tree-sitter-wasm-grammars in both cases -- so bun derives the same
hash.  Searching for bun's `// build/@opentui/core/src/...` module comments
also fails, because opencode's own `bun build --compile` re-minifies and
strips them.

What does show it is the substitution count: 1052 files replaced before,
1117 after, and 1117 - 1052 = 65 = the 13 files of this build times the five
copies of the package in the tree.

58 packages from source.

## solid-js

The last of the packages set aside as a "multi-step build".  It needed its
own package rather than an entry in the generic list, because its rollup
configuration turns fifteen inputs into thirty bundles and what separates
them is not a build flag but a textual substitution.

rollup-plugin-replace rewrites the *string literal* "_SOLID_DEV_", with
empty delimiters, inside `export const IS_DEV = "_SOLID_DEV_" as string |
boolean'.  Left alone that literal is a non-empty string and therefore
truthy, so a bundle built without the substitution would silently run in
development mode for ever -- and it would pass the unsubstituted-identifier
check already in the tree, which looks for the __NAME__ form and not this
one.  esbuild's --define rewrites identifiers, not literals, so the source is
copied once per variant and patched in place.  Ours reads `IS_DEV = false'
and `IS_DEV = true' exactly as upstream's does, and the build fails if the
literal survives into a patched variant.

Three of the four export conditions rollup builds are left as published.
web, html and h compile against dom-expressions and lit-dom-expressions;
opencode drives a terminal through @opentui/solid's universal renderer and
resolves none of them.  universal does need dom-expressions, fetched at
0.40.3, the version pinned in solid's monorepo root.

That is also where `rxcore' finally made sense.  It appears in solid's rollup
config as a rename-import target but nothing in solid imports it -- it is
dom-expressions that does, and rollup points it at solid's own web/src/core.
The alias has to resolve into the same variant copy, or a single bundle would
mix the development flag.

Verified by diffing export sets against the published bundles: 54, 54, 53, 8
and 1 names for solid, dev, server, store and universal, all identical, and
the TUI renders unchanged under a pty.  The substitution count went 1117 to
1917, which is the 16 files of this build times the fifty copies of solid-js
in the tree.

One self-inflicted mistake worth recording: dom-expressions was first aliased
straight at its store path, which put a /gnu/store reference back into the
output -- the very leak the previous section removed.  It is copied into the
build directory like everything else now.

## One package per dependency

The three aggregate builders each produced a single derivation holding many
npm packages: npm-packages-from-source held 34, actions-toolkit-from-source
4, vercel-ai-from-source every package in the vercel/ai monorepo.  That is
convenient and wrong.  Guix expects one derivation per package so each can be
built, substituted, inspected and pinned on its own, and no upstream
submission would be accepted in the aggregate shape.

Each is now its own package -- 62 of them, plus solid-js-from-source:

  node-agent-base, node-hono, node-remeda, node-clack-core, ...   (34)
  node-actions-core, node-actions-exec, ...                        (4)
  node-ai, node-ai-sdk-provider, node-ai-sdk-anthropic, ...       (24)

The build logic stays in one procedure per family -- npm-source-package,
actions-toolkit-package, vercel-ai-package -- so it is written once rather
than 62 times, but the definitions themselves are ordinary `define-public'
forms and `guix build node-ret' works on its own.  opencode takes them as
individual inputs and lists each as a substitution root.

%vercel-ai-packages names the 24 the monorepo publishes that opencode
actually resolves; it carries roughly twice as many that nothing here
reaches.

### A package was dropped, and the build did not notice

The definitions were generated from the existing spec list with a regular
expression anchored to the start of a line.  The first entry of
%npm-from-source-packages shares its line with the opening `'((', so it
matched 34 of the entries and missed agent-base.  All 33 generated packages
built, and so did opencode.

What caught it was the substitution count: 1907 files replaced where the
aggregate had replaced 1917.  Ten is two files times the five copies of
agent-base in the tree.  After restoring it the count is 1917 again, with the
same 41 copies skipped at other versions, which is what makes the refactor
verifiably equivalent rather than merely green.

Worth keeping: for this work the count is a far better regression test than
the exit status, and it has now caught two distinct faults -- this one and the
earlier substitution phase that could overwrite files but never add them.

### Two gexp traps

vercel-ai-package first carried two `(source ...)` fields, because the
original package set `(source #f)` on a line the edit did not touch; guix
reports that only as a "duplicate field initializer" warning and builds the
wrong thing.

The vercel builder writes a JavaScript program out as a Scheme string and
runs it.  `#$directory' inside that string is not interpolated -- gexps do
not substitute into string literals -- so the script received the characters
verbatim and reported "no packages were built".  The directory is passed
through the environment instead.

## The grammar checkouts leave the reference set

Two of the eight remaining references were the bash and markdown grammar
checkouts, held there by a single string each: clang records the path of
every translation unit in the module it emits, and the grammars were being
compiled straight out of the store.  Compiling from a copy removes it; all
six grammars now scan clean.

The first attempt copied only the source subdirectory and broke twice.
grammar-markdown serves two grammars, markdown and markdown_inline, so the
destination collided; and typescript's scanner.c includes
../../common/scanner.h, a header outside its own subdirectory.  The whole
checkout is copied once per input instead.

References are down from eight to six and the closure from 853.7 to 838.3
MiB.  The substitution count is unchanged at 1917, which is the point: this
changed how the grammars are compiled, not what opencode ends up running.

What remains is gcc, glibc, icu4c and bun-stage0, all of them strings inside
the bun runtime that opencode embeds rather than anything opencode does.
glibc and icu4c are genuine runtime dependencies in any case.

## gcc leaves the closure: 838.3 MiB to 576.4 MiB

gcc was 336 MiB total, 261.7 MiB of it its own, nearly a third of opencode's
closure -- held there by eight strings.  libstdc++'s assertion macros bake
__FILE__ into the message, so the path of every standard header an assertion
can fire in (optional, span, bits/stl_tree.h and five more) is a literal in
bun's binary, and Guix scans output for store hashes.

Three attempts failed before one worked, and each failure is worth keeping.

-ffile-prefix-map=/gnu/store=/store, appended to bun's CompilerFlags.cmake,
**built cleanly and changed nothing**: afterwards the binary still held eight
unmapped paths and zero mapped ones.  The flag never reached whichever
translation units carry them.  This one is the reason to measure rather than
assume -- nothing about the build said it had not worked.

A regexp scan over the binary found zero matches and stopped on its own
guard.  Guile's make-regexp goes through POSIX regex, which works on
NUL-terminated C strings: on a 100 MiB binary it stops at the first NUL byte.
Guile's own string procedures carry a length and search the whole file, so
the scan uses string-contains and explicit position tests instead.

The third attempt was an editing mistake that left the module unbalanced, so
it would not load at all.  Paren balance and `guix build --dry-run` are now
checked before spending a build.

What works is a post-install rewrite: blank the 32 hash characters in place,
same length, so nothing in the file moves.  Only paths under a gcc include
directory match, which leaves the RUNPATH -- icu4c and glibc, the only
references bun genuinely needs -- untouched.  The strings still read
/gnu/store/eeee...-gcc-14.3.0/include/c++/optional, so an assertion still
names the right header; it simply no longer carries a hash for the scanner.
The phase errors out if it matches nothing or if the file changes size.

Turning off bun's ENABLE_ASSERTIONS would have deleted the strings at the
source.  That was not done: it removes real runtime checks, which is too much
to trade for closure size.

Verified: blanked 8, gcc absent from bun's references and from opencode's,
closure 576.4 MiB, bun runs, opencode runs, TUI renders, and the substitution
count is unchanged at 1917 with 41 copies skipped.

The five that remain are bun-stage0, gcc-14.3.0-lib, glibc twice and icu4c.
All but bun-stage0 are genuine: they are in RUNPATH with libicui18n, libicuuc
and libc as NEEDED.
