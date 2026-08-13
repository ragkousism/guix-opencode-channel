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
