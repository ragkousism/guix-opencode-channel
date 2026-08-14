;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2026 Manolis Fragkiskos Ragkousis <manolis837@gmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages opencode)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system bun)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module (ice-9 binary-ports)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (rnrs bytevectors)
  #:use-module (srfi srfi-1)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (gnu packages adns)
  #:use-module (gnu packages base)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages c)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages javascript)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages node)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages web)
  #:use-module (gnu packages zig)
  #:export (bun-stage0
            bun-from-source
            libopentui
            librust-pty
            tree-sitter-wasm-grammars
            parcel-watcher-node
            emscripten
            web-tree-sitter-wasm
            solid-js-from-source
            bun-build-system-smoke
            opencode
            bun-from-source-local
            opencode-local
            opencode-bin))

;; Local development defaults.  Override these with environment variables for
;; other checkouts/snapshots:
;; - OPENCODE_SOURCE_DIR
;; - OPENCODE_MODELS_DEV_API_JSON
(define (path-or-default env-var default)
  (or (getenv env-var) default))

;; npm distributes compiled artefacts inside ordinary packages, so a
;; node_modules tree carries hundreds of them: .node addons, .wasm modules,
;; shared libraries, and several binaries published with no extension at all
;; (workerd, pagefind, tsgo).  Everything opencode actually loads is built from
;; source by this file and substituted in before the build, so none of these
;; belong in the derivation.  Keep them out rather than merely unused.
(define (compiled-artefact? file stat)
  (define (extension-matches?)
    (or (any (lambda (suffix) (string-suffix? suffix file))
             ;; Deliberately not ".lib" or ".a": npm packages carry files
             ;; like bottleneck's .babelrc.lib, and static archives are
             ;; recognised by their magic number below instead.
             '(".node" ".wasm" ".so" ".dylib" ".dll" ".exe" ".pdb"))
        ;; Versioned shared libraries, e.g. libvips-cpp.so.42.
        (and (string-match "\\.so\\.[0-9]" file) #t)))
  (define (magic-matches?)
    ;; ELF, WebAssembly, PE, Mach-O and static archives respectively.  This
    ;; reads from the file, and a node_modules tree has hundreds of thousands
    ;; of them, so only look at candidates: a compiled artefact published
    ;; without a recognisable extension is either marked executable or large.
    (and (or (logtest #o111 (stat:mode stat))
             (>= (stat:size stat) 65536))
         (catch #t
           (lambda ()
             (call-with-input-file file
               (lambda (port)
                 (let ((head (get-bytevector-n port 4)))
                   (and (bytevector? head)
                        (= 4 (bytevector-length head))
                        (let ((b (lambda (index)
                                   (bytevector-u8-ref head index))))
                          (or (and (= (b 0) #x7f) (= (b 1) #x45)
                                   (= (b 2) #x4c) (= (b 3) #x46))
                              (and (= (b 0) #x00) (= (b 1) #x61)
                                   (= (b 2) #x73) (= (b 3) #x6d))
                              (and (= (b 0) #x4d) (= (b 1) #x5a))
                              (and (= (b 0) #xcf) (= (b 1) #xfa)
                                   (= (b 2) #xed) (= (b 3) #xfe))
                              (and (= (b 0) #xce) (= (b 1) #xfa)
                                   (= (b 2) #xed) (= (b 3) #xfe))
                              (and (= (b 0) #x21) (= (b 1) #x3c)
                                   (= (b 2) #x61) (= (b 3) #x72)))))))))
           (lambda _ #f))))
  (and (eq? 'regular (stat:type stat))
       (or (extension-matches?) (magic-matches?))))

(define (local-directory-or-empty path name)
  (if (file-exists? path)
      (local-file path
                  name
                  #:recursive? #t
                  #:select? (lambda (file stat)
                              (not (compiled-artefact? file stat))))
      (computed-file name
                     #~(begin
                         (mkdir #$output)))))

(define (local-git-checkout-or-empty path name)
  (if (file-exists? path)
      (local-file path
                  name
                  #:recursive? #t
                  #:select? (git-predicate path))
      (computed-file name
                     #~(begin
                         (mkdir #$output)))))

(define (local-json-or-empty-object path name)
  (if (file-exists? path)
      (local-file path name)
      (plain-file name "{}\n")))

(define %opencode-source-directory
  (path-or-default "OPENCODE_SOURCE_DIR" "/home/manolis/repos/opencode"))

(define %opencode-models-dev-api-json
  (path-or-default "OPENCODE_MODELS_DEV_API_JSON" "/tmp/models-dev-api.json"))


(define lezer-common-source
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/@lezer/common/-/common-1.3.0.tgz")
    (sha256
     (base32
      "0nnf4m4sr4ldx8cpz1yvgrcip3gy5ryqdlgma5hqgpijl394g7gk"))))

(define lezer-cpp-source
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/@lezer/cpp/-/cpp-1.1.3.tgz")
    (sha256
     (base32
      "02sci68a1a082qgih74v96nwq9chqvvbxcb5lf74bs61b6y76df0"))))

(define lezer-highlight-source
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/@lezer/highlight/-/highlight-1.2.3.tgz")
    (sha256
     (base32
      "1vvlnvq2dys2b0xpvrqnybbc86ypj3vss0pxvjkyywv4p4qaamsj"))))

(define lezer-lr-source
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/@lezer/lr/-/lr-1.4.3.tgz")
    (sha256
     (base32
      "07x0c4dyhj7s63k6d6a17czn1b7gqrc920xdk5sf0jgp2yhnzd92"))))

;; opencode renders its terminal UI with @opentui/core, which loads a Zig
;; shared library.  npm ships that as the prebuilt @opentui/core-linux-x64
;; package; build it instead.
(define %opentui-version "0.1.77")
(define %opentui-commit "85e0582f95c22a792b320f6f8123dd1e433e2813")

;; opentui's only Zig dependency.  Upstream pins a GitHub archive tarball, but
;; `zig fetch` hashes only the files listed in build.zig.zon's `paths', so a
;; plain checkout of the same commit yields the pinned package hash
;; (uucode-0.1.0-ZZjBPtA_TQCWp5PIKmfm5tu1WOkKWFmBGFEMxircPfkA) unchanged.
(define zig-uucode-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/jacobsandlund/uucode")
          (commit "84ceda8561a17ba4a9b96ac5c583f779660bbd4e")))
    (file-name (git-file-name "zig-uucode" "84ceda8"))
    (sha256
     (base32
      "0ax9sa5fv1adphiya8pg2a3f79pgrf4gnlb1wni0bwxbzmvphg0i"))))

(define-public libopentui
  (package
    (name "libopentui")
    (version %opentui-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference (url "https://github.com/anomalyco/opentui")
                           (commit %opentui-commit)))
       (file-name (git-file-name "opentui" %opentui-version))
       (sha256
        (base32
         "1nfphzaq35qpd6n5hq30xjh6ywmyqas7nya34k8lzxakfd6vhk5n"))
       (modules '((guix build utils)))
       ;; The repository vendors prebuilt tree-sitter grammars downloaded from
       ;; each grammar's releases page.  Only packages/core/src/zig is used
       ;; here, and tree-sitter-wasm-grammars builds those grammars from
       ;; source, so drop the binaries.
       (snippet
        #~(for-each delete-file
                    (find-files "packages/core/src/lib/tree-sitter/assets"
                                "\\.wasm$")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;the test step needs a native target
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "HOME" (getcwd))
              (setenv "ZIG_GLOBAL_CACHE_DIR"
                      (string-append (getcwd) "/.cache/zig"))
              (setenv "ZIG_LOCAL_CACHE_DIR"
                      (string-append (getcwd) "/.zig-cache"))
              (with-directory-excursion "packages/core/src/zig"
                (invoke "zig" "fetch" "--save=uucode"
                        (assoc-ref inputs "zig-uucode-source"))
                ;; build.zig overrides the install directory to
                ;; "../lib/<target>", i.e. a sibling of the prefix.
                (invoke "zig" "build"
                        "-Dtarget=x86_64-linux"
                        "-Doptimize=ReleaseFast"
                        "--prefix" (string-append (getcwd) "/zig-prefix")))))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((library
                     "packages/core/src/zig/lib/x86_64-linux/libopentui.so")
                    (lib (string-append (assoc-ref outputs "out") "/lib")))
                ;; `zig build' exits 0 without emitting anything when no
                ;; install artifact matches, so check rather than trust it.
                (unless (file-exists? library)
                  (error "zig build produced no library" library))
                (mkdir-p lib)
                (install-file library lib)))))))
    (native-inputs
     `(("zig" ,zig-0.15)
       ("zig-uucode-source" ,zig-uucode-source)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/anomalyco/opentui")
    (synopsis "Zig rendering library behind @code{@@opentui/core}")
    (description
     "This package provides @file{libopentui.so}, the Zig terminal rendering
library that the @code{@@opentui/core} JavaScript package loads through its
FFI bindings.  It replaces the prebuilt @code{@@opentui/core-linux-x64} npm
package.")
    (license license:expat)))

;; src/fallback.ts needs peechy's ByteBuffer.  The published npm package ships
;; only esbuild output, so take the TypeScript sources instead.  Upstream never
;; tagged 0.4.34 (the version bun pins); js/bb.ts is byte-identical from 0.4.33
;; through this commit, and rebuilding it with esbuild reproduces the published
;; bb.mjs up to static-field lowering.
(define %peechy-commit "11a618c2fb2d0e05bb0edf1a871d131dedc779ee")

(define peechy-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/jarred-sumner/peechy")
          (commit %peechy-commit)))
    (file-name (git-file-name "peechy" %peechy-commit))
    (sha256
     (base32
      "0wm318bcw5l7r5hmwqq81l75yayyhimci31i39zmsnd8w9rrx8r4"))))

(define node-v24.3.0-headers-source
  (origin
    (method url-fetch)
    (uri "https://nodejs.org/dist/v24.3.0/node-v24.3.0-headers.tar.gz")
    (sha256
     (base32
      "01yx2n8qxf09xp8f70f5wbgxx17plwxsdhgqcznb0pfdfzs9nph4"))))

;; Several upstream source archives ship compiled files: the winapi crates
;; carry ~2800 mingw import libraries, mimalloc ships Windows DLLs, BoringSSL
;; and Bun keep binary test fixtures, and Bun vendors a macOS build of
;; libtcc1.  None are read by a GNU/Linux build, but they are prebuilt
;; binaries entering it.  This snippet removes them by content, so files that
;; merely look compiled (a `.wasm' that is really JavaScript, a `COPYING.LIB')
;; stay put.
(define %strip-compiled-artefacts
  #~(let ()
      (define (compiled? file stat)
        (and (eq? 'regular (stat:type stat))
             (> (stat:size stat) 4)
             (catch #t
               (lambda ()
                 (call-with-input-file file
                   (lambda (port)
                     (let ((head (get-bytevector-n port 4)))
                       (and (bytevector? head)
                            (= 4 (bytevector-length head))
                            (let ((b (lambda (index)
                                       (bytevector-u8-ref head index))))
                              (or (and (= (b 0) #x7f) (= (b 1) #x45)
                                       (= (b 2) #x4c) (= (b 3) #x46))
                                  (and (= (b 0) #x00) (= (b 1) #x61)
                                       (= (b 2) #x73) (= (b 3) #x6d))
                                  (and (= (b 0) #x4d) (= (b 1) #x5a))
                                  (and (= (b 0) #x21) (= (b 1) #x3c)
                                       (= (b 2) #x61) (= (b 3) #x72))
                                  (and (= (b 0) #xcf) (= (b 1) #xfa)
                                       (= (b 2) #xed) (= (b 3) #xfe))
                                  (and (= (b 0) #xce) (= (b 1) #xfa)
                                       (= (b 2) #xed) (= (b 3) #xfe)))))))))
               (lambda _ #f))))
      (for-each delete-file (find-files "." compiled?))))

(define %strip-modules
  '((guix build utils) (ice-9 binary-ports) (rnrs bytevectors)))

;; Bun 1.0.0 keeps mimalloc as a submodule, absent from the release tarball.
;; Its Zig allocator bindings are written against that fork's 2.1.0-era API
;; and reach into heap internals, so substituting a current mimalloc release
;; corrupts the heap in ways that only show up sporadically, far from the
;; allocation site.  Use the commit the submodule pins.
(define bun-stage0-mimalloc-source
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/oven-sh/mimalloc/archive/"
                        "7968d4285043401bb36573374710d47a4081a063.tar.gz"))
    (file-name "bun-stage0-mimalloc-7968d42.tar.gz")
    (sha256
     (base32 "1vh8ysl7ik8ksm8hvnkj3jsdsfvhsadn80snqhw0wfjwqxnfw4rw"))
    (modules %strip-modules)
    ;; This fork ships Windows redirect DLLs and injector executables in bin/.
    (snippet %strip-compiled-artefacts)))

;; Bun's build clones these pinned repositories into vendor/ while building,
;; which a build container cannot do.  Fetch them as ordinary origins instead;
;; see the 'unpack-vendored-sources phase for how the clone step is satisfied.
;; The commits are the ones registered in Bun's cmake/targets/Clone*.cmake and
;; Build*.cmake files.
(define %bun-vendored-sources
  ;; (DIRECTORY REPOSITORY COMMIT HASH)
  '(("boringssl" "oven-sh/boringssl"
     "4f4f5ef8ebc6e23cbf393428f0ab1b526773f7ac"
     "10gydn7c9skiv8qv1qij28k20ajbhzp8r7ki3g3650f0gq6bix4x")
    ("picohttpparser" "h2o/picohttpparser"
     "066d2b1e9ab820703db0837a7255d92d30f0c9f5"
     "1vi32dfgzzrmz6mcxjjgfpaaizpjbhykkp5mll2pwzswdymz4zv3")
    ("cares" "c-ares/c-ares"
     "3ac47ee46edd8ea40370222f91613fc16c434853"
     "1f74lb8d4z07vy7zi9pg579qfqkkgsglvnl7wi24mbk6ndn1354c")
    ("hdrhistogram" "HdrHistogram/HdrHistogram_c"
     "be60a9987ee48d0abf0d7b6a175bad8d6c1585d1"
     "1jfzbiiiigc6h7v8amzca7wx5mdayq58i206wnnpafihwmd5w741")
    ("highway" "google/highway"
     "ac0d5d297b13ab1b89f48484fc7911082d76a93f"
     "19yydisrlii439w73bf9yzb8sij7b23sih1r1pzi811anvs1da57")
    ("libarchive" "libarchive/libarchive"
     "9525f90ca4bd14c7b335e2f8c84a4607b0af6bdf"
     "0b0h9a6vm4m5mlq7ikvz2jrq6py17i5g1d3xjifxpjx3b2mvjkcl")
    ("libdeflate" "ebiggers/libdeflate"
     "c8c56a20f8f621e6a966b716b31f1dedab6a41e3"
     "10ga3mkfiabhjwibis1zqn5kqzjhixcf7jc9idfj9qgkvdmw0p0y")
    ("lolhtml" "cloudflare/lol-html"
     "e9e16dca48dd4a8ffbc77642bc4be60407585f11"
     "064dd8a8jfn0rf7smpflp9ic67i69dfql8nr30vng53h67zkcav2")
    ("lshpack" "litespeedtech/ls-hpack"
     "8905c024b6d052f083a3d11d0a169b3c2735c8a1"
     "0wzr1q9yzmjisvrm5nxsxq8157ji70wx5awfyd1mbcdi3f8bzn07")
    ("mimalloc" "oven-sh/mimalloc"
     "ffa38ab8ac914f9eb7af75c1f8ad457643dc14f2"
     "16fa8zp5n8y6gz5i2l90ihkppmsif9lpw5y5wfwfgrx4xg0s0f4w")
    ("tinycc" "oven-sh/tinycc"
     "12882eee073cfe5c7621bcfadf679e1372d4537b"
     "1aphjvnck3ckw4ixnpkx6wscsk81j9m2p3kfqnchmadzrdglhl3b")
    ("zlib" "cloudflare/zlib"
     "886098f3f339617b4243b286f5ed364b9989e245"
     "1fyrdqzplzykz63haa2yxj8rrsy9aj7yhzgqaaprd1ihz2fl9gql")
    ("zstd" "facebook/zstd"
     "f8745da6ff1ad1e7bab384bd1f9d742439278e99"
     "0b55bvl4jn3lzl03llfjq2sga3skjmrz4d9w22wn2pmjrzqd22sb")
    ("libuv" "libuv/libuv"
     "f3ce527ea940d926c40878ba5de219640c362811"
     "1kyhfj2hsfs9k79qxvg3qqp04dbw896j4zip9v4ag1max18hs126")))

;; Brotli is registered by tag rather than by commit, so its reference marker
;; and download URL take a different shape from the entries above.
(define %bun-vendored-brotli-tag "v1.1.0")

(define bun-vendored-brotli
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/google/brotli/archive/refs/tags/"
                        %bun-vendored-brotli-tag ".tar.gz"))
    (file-name (string-append "bun-vendor-brotli-"
                              %bun-vendored-brotli-tag ".tar.gz"))
    (sha256
     (base32 "1zqkxacqb89pi1vzdvcplfmqyfgmf4bkfrfi98zq12s2575ac877"))))

(define (bun-vendored-source entry)
  "Return an origin for ENTRY, one element of %bun-vendored-sources."
  (let ((name (car entry))
        (repository (cadr entry))
        (commit (caddr entry))
        (hash (cadddr entry)))
    (origin
      (method url-fetch)
      (uri (string-append "https://github.com/" repository
                          "/archive/" commit ".tar.gz"))
      (file-name (string-append "bun-vendor-" name "-"
                                (string-take commit 7) ".tar.gz"))
      (sha256 (base32 hash))
      (modules %strip-modules)
      (snippet %strip-compiled-artefacts))))

;; Bun 1.3.8's Zig sources use oven-sh's fork of the language: private
;; fields written `#name', as in `#raw: jsc.JSValue' or `result.#ref_count'.
;; Upstream Zig rejects those as an invalid token, and 29 files fail to
;; parse.  The fork tracks 0.15.2, which is what Guix's zig-0.15 builds, so
;; reuse that build with the fork's source.  CMake pins the commit in
;; cmake/tools/SetupZig.cmake; it has to match what the recipe supplies.
(define %bun-zig-commit "c1423ff3fc7064635773a4a4616c5bf986eb00fe")

(define-public zig-for-bun
  (package
    (inherit zig-0.15)
    (name "zig-for-bun")
    (version (string-append "0.15.2-oven-" (string-take %bun-zig-commit 7)))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/oven-sh/zig")
             (commit %bun-zig-commit)))
       (file-name (git-file-name "zig-for-bun" %bun-zig-commit))
       (sha256
        (base32 "004ym9v0792wyrx2wshdc7pg9901kj8wvdg4z1bs2pwwcsmflgpj"))
       (patches
        (search-patches
         "zig-0.14-use-baseline-cpu-by-default.patch"
         "zig-0.14-use-system-paths.patch"
         "zig-0.15-fix-runpath.patch"))
       (modules '((guix build utils)))
       ;; Zig checks in the WebAssembly build of its own stage 1 compiler.
       ;; The build never uses it -- `prepare-source' overwrites stage1 with
       ;; the zig1 that Guix bootstrapped -- but inheriting zig-0.15 without
       ;; inheriting its origin dropped the snippet that removes it, leaving a
       ;; prebuilt binary in the source for no reason.  Delete it as Guix
       ;; does.
       (snippet
        #~(for-each (lambda (file)
                      (when (file-exists? file)
                        (delete-file file)))
                    '("stage1/zig1.wasm" "stage1/zig1.wasm.zst")))))))

;; lolhtml (Bun's HTMLRewriter) is a Rust crate, built by cargo from
;; vendor/lolhtml/c-api.  The build sandbox has no network and cargo runs
;; with CARGO_NET_OFFLINE, so its dependency tree has to be supplied too.
;; These are exactly the versions pinned by the Cargo.lock that lolhtml ships
;; in c-api; they are unpacked into a cargo directory source by the build
;; below.  Re-resolving instead of using that lock picks up newer crates and
;; makes cargo reject the lock, so the two must stay in step.
(define %lolhtml-vendored-crates
  '(
    ("allocator-api2" "0.2.21" "08zrzs022xwndihvzdn78yqarv2b9696y67i6h78nla3ww87jgb8"
     "683d7910e743518b0e34f1186f92494becacb047c7b6bf616c96772180fef923")
    ("bitflags" "2.10.0" "1lqxwc3625lcjrjm5vygban9v8a6dlxisp1aqylibiaw52si4bl1"
     "812e12b5285cc515a9c72a5c1d3b6d46a19dac5acfef5265968c166106e31dd3")
    ("cfg-if" "1.0.4" "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k"
     "9330f8b2ff13f34540b44e946ef35111825727b38d33286ef986142615121801")
    ("cssparser" "0.36.0" "1ljplaynfd8p9y00ypy84il27n1q9rz5pdnsb7b3pf5bq3wirrns"
     "dae61cf9c0abb83bd659dab65b7e4e38d8236824c85f0f804f173567bda257d2")
    ("cssparser-macros" "0.6.1" "0cfkzj60avrnskdmaf7f8zw6pp3di4ylplk455zrzaf19ax8id8k"
     "13b588ba4ac1a99f7f2964d24b3d896ddc6bf847ee3855dbd4366f058cfcd331")
    ("derive_more" "2.1.1" "0d5i10l4aff744jw7v4n8g6cv15rjk5mp0f1z522pc2nj7jfjlfp"
     "d751e9e49156b02b44f9c1815bcb94b984cdcc4396ecc32521c739452808b134")
    ("derive_more-impl" "2.1.1" "1jwdp836vymp35d7mfvvalplkdgk2683nv3zjlx65n1194k9g6kr"
     "799a97264921d8623a957f6c3b9011f3b5492f557bbb7a5a19b7fa6d06ba8dcb")
    ("dtoa" "1.0.11" "1405jvczpxf1zd3nsvw02r50hr2k6argq6jkgdf04prd9s1g8g2c"
     "4c3cf4824e2d5f025c7b531afcb2325364084a16806f6d47fbc1f5fbd9960590")
    ("dtoa-short" "0.3.5" "11rwnkgql5jilsmwxpx6hjzkgyrbdmx1d71s0jyrjqm5nski25fd"
     "cd1511a7b6a56299bd043a9c167a6d2bfb37bf84a6dfceaba651168adfb43c87")
    ("encoding_rs" "0.8.35" "1wv64xdrr9v37rqqdjsyb8l8wzlcbab80ryxhrszvnj59wy0y0vm"
     "75030f3c4f45dafd7586dd6780965a8c7e8e285a5ecb86713e63a79c5b2766f3")
    ("equivalent" "1.0.2" "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7"
     "877a4ace8713b0bcf2a4e7eec82529c029f1d0619886d18145fea96c3ffe5c0f")
    ("fastrand" "2.3.0" "1ghiahsw1jd68df895cy5h3gzwk30hndidn3b682zmshpgmrx41p"
     "37909eebbb50d72f9059c3b6d82c0463f2ff062c9e95845c43a6c9c0355411be")
    ("foldhash" "0.2.0" "1nvgylb099s11xpfm1kn2wcsql080nqmnhj1l25bp3r2b35j9kkp"
     "77ce24cb58228fbb8aa041425bb1050850ac19177686ea6e0f41a70416f56fdb")
    ("hashbrown" "0.16.1" "004i3njw38ji3bzdp9z178ba9x3k0c1pgy8x69pj7yfppv4iq7c4"
     "841d1cc9bed7f9236f321df977030373f4a4163ae1a7dbfe1a51a2c1a51d9100")
    ("itoa" "1.0.17" "1lh93xydrdn1g9x547bd05g0d3hra7pd1k4jfd2z1pl1h5hwdv4j"
     "92ecc6618181def0457392ccd0ee51198e065e016d1d527a7ac1b6dc7c1f09d2")
    ("libc" "0.2.179" "07s3mxl54kimb55qp0q51pcbm6i3bv8k4chkilix2c55p9vd78n5"
     "c5a2d376baa530d1238d133232d15e239abad80d05838b4b59354e5268af431f")
    ("log" "0.4.29" "15q8j9c8g5zpkcw0hnd6cf2z7fxqnvsjh3rw5mv5q10r83i34l2y"
     "5e5032e24019045c762d3c0f28f5b6b8bbf38563a65908389bf7978758920897")
    ("memchr" "2.7.6" "0wy29kf6pb4fbhfksjbs05jy2f32r2f3r1ga6qkmpz31k79h0azm"
     "f52b00d39961fc5b2736ea853c9cc86238e165017a493d1d5c8eac6bdc4cc273")
    ("mime" "0.3.17" "16hkibgvb9klh0w0jk5crr5xv90l3wlf77ggymzjmvl1818vnxv8"
     "6877bb514081ee2a7ff5ef9de3281f14a4dd4bceac4c09388074a6b5df8a139a")
    ("new_debug_unreachable" "1.0.6" "11phpf1mjxq6khk91yzcbd3ympm78m3ivl7xg6lg2c0lf66fy3k5"
     "650eef8c711430f1a879fdd01d4745a7deea475becfb90269c06775983bbf086")
    ("phf" "0.13.1" "1pzswx5gdglgjgp4azyzwyr4gh031r0kcnpqq6jblga72z3jsmn1"
     "c1562dc717473dbaa4c1f85a36410e03c047b2e7df7f45ee938fbef64ae7fadf")
    ("phf_codegen" "0.13.1" "1qfnsl2hiny0yg4lwn888xla5iwccszgxnx8dhbwl6s2h2fpzaj9"
     "49aa7f9d80421bca176ca8dbfebe668cc7a2684708594ec9f3c0db0805d5d6e1")
    ("phf_generator" "0.13.1" "0dwpp11l41dy9mag4phkyyvhpf66lwbp79q3ik44wmhyfqxcwnhk"
     "135ace3a761e564ec88c03a77317a7c6b80bb7f7135ef2544dbe054243b89737")
    ("phf_macros" "0.13.1" "1vv9h8pr7xh18sigpvq1hxc8q9nmjmv6gdpqsp65krxiahmh6bw1"
     "812f032b54b1e759ccd5f8b6677695d5268c588701effba24601f6932f8269ef")
    ("phf_shared" "0.13.1" "0rpjchnswm0x5l4mz9xqfpw0j4w68sjvyqrdrv13h7lqqmmyyzz5"
     "e57fef6bc5981e38c2ce2d63bfa546861309f875b8a75f092d1d54ae2d64f266")
    ("precomputed-hash" "0.1.1" "075k9bfy39jhs53cb2fpb9klfakx2glxnf28zdw08ws6lgpq6lwj"
     "925383efa346730478fb4838dbe9137d2a47675ad789c546d150a6e1dd4ab31c")
    ("proc-macro2" "1.0.105" "1rvgs5qdznlrqrgicmv24nybnrnv8kyvk2vi7s52ddna1q71hpak"
     "535d180e0ecab6268a3e718bb9fd44db66bbbc256257165fc699dadf70d16fe7")
    ("quote" "1.0.43" "02n41mlr81qmczac7m5kjy51y8b7yrb8ym4ncmjycampjjjxjx6w"
     "dc74d9a594b72ae6656596548f56f667211f8a97b3d4c3d467150794690dc40a")
    ("rustc-hash" "2.1.1" "03gz5lvd9ghcwsal022cgkq67dmimcgdjghfb5yb5d352ga06xrm"
     "357703d41365b4b27c590e3ed91eabb1b663f07c4c084095e60cbed4362dff0d")
    ("rustc_version" "0.4.1" "14lvdsmr5si5qbqzrajgb6vfn69k0sfygrvfvr2mps26xwi3mjyg"
     "cfcb3a22ef46e85b45de6ee7e79d063319ebb6594faafcf1c225ea92ab6e9b92")
    ("selectors" "0.33.0" "1dsg2sxhff1v84ajcslsplffcwqkg7rw39cynzhk4x8l6q63bvzy"
     "feef350c36147532e1b79ea5c1f3791373e61cbd9a6a2615413b3807bb164fb7")
    ("semver" "1.0.27" "1qmi3akfrnqc2hfkdgcxhld5bv961wbk8my3ascv5068mc5fnryp"
     "d767eb0aabc880b29956c35734170f26ed551a859dbd361d140cdbeca61ab1e2")
    ("serde" "1.0.228" "17mf4hhjxv5m90g42wmlbc61hdhlm6j9hwfkpcnd72rpgzm993ls"
     "9a8e94ea7f378bd32cbbd37198a4a91436180c5bb472411e48b5ec2e2124ae9e")
    ("serde_core" "1.0.228" "1bb7id2xwx8izq50098s5j2sqrrvk31jbbrjqygyan6ask3qbls1"
     "41d385c7d4ca58e59fc732af25c3983b67ac852c1a25000afe1175de458b67ad")
    ("serde_derive" "1.0.228" "0y8xm7fvmr2kjcd029g9fijpndh8csv5m20g4bd76w8qschg4h6m"
     "d540f220d3187173da220f885ab66608367b6574e925011a9353e4badda91d79")
    ("servo_arc" "0.4.3" "0c2rl0r9x4kbppwlcrd5bnwds612na179im7kb37vqadncxbh3qp"
     "170fb83ab34de17dc69aa7c67482b22218ddb85da56546f9bd6b929e32a05930")
    ("siphasher" "1.0.1" "17f35782ma3fn6sh21c027kjmd227xyrx06ffi8gw4xzv9yry6an"
     "56199f7ddabf13fe5074ce809e7d3f42b42ae711800501b5b16ea82ad029c39d")
    ("smallvec" "1.15.1" "00xxdxxpgyq5vjnpljvkmy99xij5rxgh913ii1v16kzynnivgcb7"
     "67b1b7a3b5fe4f1376887184045fcf45c69e92af734b7aaddc05fb777b6fbd03")
    ("stable_deref_trait" "1.2.1" "15h5h73ppqyhdhx6ywxfj88azmrpml9gl6zp3pwy2malqa6vxqkc"
     "6ce2be8dc25455e1f91df71bfa12ad37d7af1092ae736f3a6cd0e37bc7810596")
    ("syn" "2.0.114" "0akw62dizhyrkf3ym1jsys0gy1nphzgv0y8qkgpi6c1s4vghglfl"
     "d4d107df263a3013ef9b1879b0df87d706ff80f65a86ea879bd9c31f9b307c2a")
    ("thiserror" "2.0.17" "1j2gixhm2c3s6g96vd0b01v0i0qz1101vfmw0032mdqj1z58fdgn"
     "f63587ca0f12b72a0600bcba1d40081f830876000bb46dd2337a3051618f4fc8")
    ("thiserror-impl" "2.0.17" "04y92yjwg1a4piwk9nayzjfs07sps8c4vq9jnsfq9qvxrn75rw9z"
     "3ff15c8ecd7de3849db632e14d18d2571fa09dfc5ed93479bc4485c7a517c913")
    ("unicode-ident" "1.0.22" "1x8xrz17vqi6qmkkcqr8cyf0an76ig7390j9cnqnk47zyv2gf4lk"
     "9312f7c4f6ff9069b165498234ce8be658059c6728633667c526e27dc2cf1df5")))

(define (crates-io-source entry)
  "Return an origin for ENTRY, a (NAME VERSION GUIX-HASH CRATES-IO-HASH) list."
  (let ((name (car entry))
        (version (cadr entry))
        (hash (caddr entry)))
    (origin
      (method url-fetch)
      (uri (string-append "https://crates.io/api/v1/crates/" name "/"
                          version "/download"))
      (file-name (string-append "crate-" name "-" version ".tar.gz"))
      (sha256 (base32 hash))
      (modules %strip-modules)
      (snippet %strip-compiled-artefacts))))

;; Backward-compatible alias.
(define lolhtml-vendored-crate crates-io-source)

;; bun-pty ships librust_pty.so prebuilt inside its npm package, with no
;; Rust sources at all; those live only in the upstream repository.  The crate
;; set below is rust-pty/Cargo.lock verbatim, each entry carrying both the Guix
;; hash of the .crate file and the crates.io checksum the lockfile records.
(define %rust-pty-vendored-crates
  '(
    ("anyhow" "1.0.98" "11ylvjdrcjs0q9jgk1af4r5cx1qppj63plxqkq595vmc24rjsvg1"
     "e16d2d3311acee920a9eb8d33b8cbc1787ce4a264e85f964c2404b969bdcd487")
    ("autocfg" "1.4.0" "09lz3by90d2hphbq56znag9v87gfpd9gb8nr82hll8z6x2nhprdc"
     "ace50bade8e6234aa140d9a2f552bbee1db4d353f69b8217bc503490fc1a9f26")
    ("bitflags" "1.3.2" "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy"
     "bef38d45163c2f1dde094a7dfd33ccf595c92905c8f8f4fdc18d06fb1037718a")
    ("cfg-if" "1.0.0" "1za0vb97n4brpzpv8lsbnzmq5r8f2b0cpqqr0sy8h5bn751xxwds"
     "baf1de4339761588bc0619e3cbc0120ee582ebb74b53b4efbf79117bd2da40fd")
    ("crossbeam" "0.8.4" "1a5c7yacnk723x0hfycdbl91ks2nxhwbwy46b8y5vyy0gxzcsdqi"
     "1137cd7e7fc0fb5d3c5a8678be38ec56e819125d8d7907411fe24ccb943faca8")
    ("crossbeam-channel" "0.5.15" "1cicd9ins0fkpfgvz9vhz3m9rpkh6n8d3437c3wnfsdkd3wgif42"
     "82b8f8f868b36967f9606790d1903570de9ceaf870a7bf9fbbd3016d636a2cb2")
    ("crossbeam-deque" "0.8.6" "0l9f1saqp1gn5qy0rxvkmz4m6n7fc0b3dbm6q1r5pmgpnyvi3lcx"
     "9dd111b7b7f7d55b72c0a6ae361660ee5853c9af73f70c3c2ef6858b950e2e51")
    ("crossbeam-epoch" "0.9.18" "03j2np8llwf376m3fxqx859mgp9f83hj1w34153c7a9c7i5ar0jv"
     "5b82ac4a3c2ca9c3460964f020e1402edd5753411d7737aa39c3714ad1b5420e")
    ("crossbeam-queue" "0.3.12" "059igaxckccj6ndmg45d5yf7cm4ps46c18m21afq3pwiiz1bnn0g"
     "0f58bbc28f91df819d0aa2a2c00cd19754769c2fad90579b3592b1c9ba7a3115")
    ("crossbeam-utils" "0.8.21" "0a3aa2bmc8q35fb67432w16wvi54sfmb69rk9h5bhd18vw0c99fh"
     "d0a5c400df2834b80a4c3327b3aad3a4c4cd4de0629063962b03235697506a28")
    ("downcast-rs" "1.2.1" "1lmrq383d1yszp7mg5i7i56b17x2lnn3kb91jwsq0zykvg2jbcvm"
     "75b325c5dbd37f80359721ad39aca5a29fb04c89279657cffdda8736d0c0b9d2")
    ("filedescriptor" "0.8.3" "0bb8qqa9h9sj2mzf09yqxn260qkcqvmhmyrmdjvyxcn94knmh1z4"
     "e40758ed24c9b2eeb76c35fb0aebc66c626084edd827e07e1552279814c6682d")
    ("ioctl-rs" "0.1.6" "0zdrgqxblrwm4ym8pwrr7a4dwjzxrvr1k0qjx6rk1vjwi480b5zp"
     "f7970510895cee30b3e9128319f2cefd4bde883a39f38baa279567ba3a7eb97d")
    ("itoa" "1.0.15" "0b4fj9kz54dr3wam0vprjwgygvycyw8r0qwg7vp19ly8b2w16psa"
     "4a5f13b858c8d314ee3e8f639011f7ccefe71f97f96e50151fb991f267928e2c")
    ("lazy_static" "1.5.0" "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv"
     "bbd2bcb4c963f2ddae06a2efc7e9f3591312473c50c6685e1f298068316e66fe")
    ("libc" "0.2.172" "1ykz4skj7gac14znljm5clbnrhini38jkq3d60jggx3y5w2ayl6p"
     "d750af042f7ef4f724306de029d18836c26c1765a54a6a3f094cbd23a7267ffa")
    ("log" "0.4.27" "150x589dqil307rv0rwj0jsgz5bjbwvl83gyl61jf873a7rjvp0k"
     "13dc2df351e3202783a1fe0d44375f7295ffb4049267b0f3018346dc122a1d94")
    ("memchr" "2.7.4" "18z32bhxrax0fnjikv475z7ii718hq457qwmaryixfxsl2qrmjkq"
     "78ca9ab1a0babb1e7d5695e3530886289c18cf2f87ec19a575a0abdce112e3a3")
    ("memoffset" "0.6.5" "1kkrzll58a3ayn5zdyy9i1f1v3mx0xgl29x0chq614zazba638ss"
     "5aa361d4faea93603064a027415f07bd8e1d5c88c9fbf68bf56a285428fd79ce")
    ("nix" "0.25.1" "1r4vyp5g1lxzpig31bkrhxdf2bggb4nvk405x5gngzfvwxqgyipk"
     "f346ff70e7dbfd675fe90590b92d59ef2de15a8779ae305ebcbfd3f0caf59be4")
    ("pin-utils" "0.1.0" "117ir7vslsl2z1a7qzhws4pd01cg2d3338c47swjyvqv2n60v1wb"
     "8b870d8c151b6f2fb93e84a13146138f05d02ed11c7e7c54f8826aaaf7c9f184")
    ("portable-pty" "0.8.1" "1gmh9ij90qwxx8gzvs6dj2vlc1ackv8zhd4mzfly3nq3586fhvl0"
     "806ee80c2a03dbe1a9fb9534f8d19e4c0546b790cde8fd1fea9d6390644cb0be")
    ("proc-macro2" "1.0.95" "0y7pwxv6sh4fgg6s715ygk1i7g3w02c0ljgcsfm046isibkfbcq2"
     "02b3e5e68a3a1a02aad3ec490a98007cbc13c37cbe84a3cd7b8e406d76e7f778")
    ("quote" "1.0.40" "1394cxjg6nwld82pzp2d4fp6pmaz32gai1zh9z5hvh0dawww118q"
     "1885c039570dc00dcb4ff087a89e185fd56bae234ddc7f056a945bf36467248d")
    ("ryu" "1.0.20" "07s855l8sb333h6bpn24pka5sp7hjk2w667xy6a0khkf6sqv5lr8"
     "28d3b2b1366ec20994f1fd18c3c594f05c5dd4bc44d8bb0c1c632c8d6829481f")
    ("serde" "1.0.219" "1dl6nyxnsi82a197sd752128a4avm6mxnscywas1jq30srp2q3jz"
     "5f0e2c6ed6606019b4e29e69dbaba95b11854410e5347d525002456dbbb786b6")
    ("serde_derive" "1.0.219" "001azhjmj7ya52pmfiw4ppxm16nd44y15j2pf5gkcwrcgz7pc0jv"
     "5b0276cf7f2c73365f7157c8123c21cd9a50fbbd844757af28ca1f5925fc2a00")
    ("serde_json" "1.0.140" "0wwkp4vc20r87081ihj3vpyz5qf7wqkqipq17v99nv6wjrp8n1i0"
     "20068b6e96dc6c9bd23e01df8827e6c7e1f2fddd43c21810382803c136b99373")
    ("serial" "0.4.0" "11iyvc1z123hn7zl6bk5xpf6xdlsb33qh6xa7g0pghqgayb7l8x1"
     "a1237a96570fc377c13baa1b88c7589ab66edced652e43ffb17088f003db3e86")
    ("serial-core" "0.4.0" "10a5lvllz3ljva66bqakrn8cxb3pkaqyapqjw9x760al6jdj0iiz"
     "3f46209b345401737ae2125fe5b19a77acce90cd53e1658cda928e4fe9a64581")
    ("serial-unix" "0.4.0" "1dyaaca8g4q5qzc2l01yirzs6igmhc9agg4w8m5f4rnqr6jbqgzh"
     "f03fbca4c9d866e24a459cbca71283f545a37f8e3e002ad8c70593871453cab7")
    ("serial-windows" "0.4.0" "0ql1vjy57g2jf218bhmgr98i41faq0v5vzdx3g9payi6fsvx7ihm"
     "15c6d3b776267a75d31bbdfd5d36c0ca051251caafc285827052bc53bcdc8162")
    ("shared_library" "0.1.9" "04fs37kdak051hm524a360978g58ayrcarjsbf54vqps5c7px7js"
     "5a9e7e0f2bfae24d8a5b5a66c5b257a83c7412304311512a0c054cd5e619da11")
    ("shell-words" "1.1.0" "1plgwx8r0h5ismbbp6cp03740wmzgzhip85k5hxqrrkaddkql614"
     "24188a676b6ae68c3b2cb3a01be17fbf7240ce009799bb56d5b1409051e78fde")
    ("syn" "2.0.101" "1brwsh7fn3bnbj50d2lpwy9akimzb3lghz0ai89j8fhvjkybgqlc"
     "8ce2b7fc941b3a24138a0a7cf8e858bfc6a992e7978a068a5c760deb0ed43caf")
    ("termios" "0.2.2" "0fk8nl0rmk43jrh6hjz6c6d83ri7l6fikag6lh0ffz3di9cwznfm"
     "d5d9cf598a6d7ce700a4e6a9199da127e6819a61e64b68609683cc9a01b5683a")
    ("thiserror" "1.0.69" "0lizjay08agcr5hs9yfzzj6axs53a2rgx070a1dsi3jpkcrzbamn"
     "b6aaf5339b578ea85b50e080feb250a3e8ae8cfcdff9a461c9ec2904bc923f52")
    ("thiserror-impl" "1.0.69" "1h84fmn2nai41cxbhk6pqf46bxqq1b344v8yz089w1chzi76rvjg"
     "4fee6c4efc90059e10f81e6d42c60a18f76588c3d74cb83a0b242a2b6c7504c1")
    ("unicode-ident" "1.0.18" "04k5r6sijkafzljykdq26mhjpmhdx4jwzvn1lh90g9ax9903jpss"
     "5a5f39404a5da50712a4c1eecf25e90dd62b613502b7e925fd4e4d19b5c96512")
    ("winapi" "0.3.9" "06gl025x418lchw1wxj64ycr7gha83m44cjr5sarhynd9xkrm0sw"
     "5c839a674fcd7a98952e593242ea400abe93992746761e38641405d28b00f419")
    ("winapi-i686-pc-windows-gnu" "0.4.0" "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc"
     "ac3b87c63620426dd9b991e5ce0329eff545bccbbb34f3be09ff6fb6ab51b7b6")
    ("winapi-x86_64-pc-windows-gnu" "0.4.0" "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki"
     "712e227841d057c1ee1cd2fb22fa7e5a5461ae8e48fa2ca79ec42cfc1931183f")
    ("winreg" "0.10.1" "17c6h02z88ijjba02bnxi5k94q5cz490nf3njh9yypf8fbig9l40"
     "80d0f4e272c85def139476380b12f9ac60926689dd2e01d4923222f40580869d")))

;; LLVM's tree carries ~940 compiled files per release, all under llvm/test,
;; lld/test and lldb/test -- sancov inputs, llvm-cov samples, object fixtures.
;; They cannot be removed from `llvm' itself, whose lit suite reads them and
;; which Guix builds with #:tests? #t.  clang and lld build with tests off, so
;; the two packages compiled locally here can drop them.
(define (without-test-binaries base)
  (package
    (inherit base)
    (source (origin
              (inherit (package-source base))
              (modules %strip-modules)
              (snippet %strip-compiled-artefacts)))))

(define-public lld-20-from-source (without-test-binaries lld-20))

;; Guix configures clang with -DC_INCLUDE_DIRS=<glibc>/include, which clang
;; then searches for every target, ahead of any --sysroot.  Building for
;; wasm32-unknown-emscripten therefore picks up the host glibc headers and
;; fails.  Emscripten drives clang itself and has no flag to undo this, so use
;; a clang that simply never had the path baked in.
(define-public clang-for-emscripten
  (package
    (inherit (without-test-binaries clang-20))
    (name "clang-for-emscripten")
    (arguments
     (substitute-keyword-arguments (package-arguments clang-20)
       ((#:configure-flags flags)
        `(filter (lambda (flag)
                   (not (string-prefix? "-DC_INCLUDE_DIRS=" flag)))
                 ,flags))))
    (synopsis "Clang without Guix's baked-in libc include directory")))

;; emcc's JavaScript optimiser runs for -O3 and imports acorn.  npm ships only
;; the rollup output, so build the parser from its sources with esbuild.
(define acorn-source
  (origin
    (method git-fetch)
    (uri (git-reference (url "https://github.com/acornjs/acorn")
                        (commit "6dc537416ad628b3959b3ff963fbdcfdb380e0a3")))
    (file-name (git-file-name "acorn" "8.15.0"))
    (sha256
     (base32
      "1qbx3alyf5wkp0gipl3q7zv1xghflxlwg1q7qsrq5q46dxv498fs"))))

;; Emscripten drives clang and lld itself, so it needs one directory holding
;; clang, wasm-ld and the llvm-* tools; Guix ships those in three packages.
;; The build below assembles that directory out of symlinks.
(define-public emscripten
  (package
    (name "emscripten")
    (version "4.0.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/emscripten-core/emscripten")
             (commit version)))
       (file-name (git-file-name "emscripten" version))
       (sha256
        (base32
         "0ln50bwj983y8nxa8kiwpygqxrd6ipz6v7vfmwba7m1r4kx73b72"))
       (modules '((guix build utils)))
       ;; The test suite ships a few compiled WebAssembly fixtures; emcc never
       ;; reads them.
       (snippet
        #~(when (file-exists? "test")
            (for-each delete-file
                      (find-files "test" "\\.(wasm|so|dll|exe|dylib)$"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; The source root has a `bootstrap' script, which the default phase
          ;; would run; it starts with `npm ci' and needs the network.
          (delete 'bootstrap)
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; bootstrap.py runs three actions.  Only the entry points are
              ;; needed to run emcc: `npm ci' fetches the JavaScript optimiser
              ;; and closure compiler, which the flags used here do not reach,
              ;; and the submodules are the test suite.
              (invoke "python3" "tools/maint/create_entry_points.py")))
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (share (string-append out "/share/emscripten"))
                     (llvm (string-append out "/libexec/emscripten-llvm/bin"))
                     (clang (assoc-ref inputs "clang"))
                     (lld (assoc-ref inputs "lld"))
                     (llvm-tools (assoc-ref inputs "llvm"))
                     (python (assoc-ref inputs "python")))
                (mkdir-p share)
                (copy-recursively "." share)
                ;; emcc shells out to these launchers to compile its own
                ;; system libraries, and they are generated with a #!/bin/sh
                ;; shebang.  There is no /bin/sh in the build container, and
                ;; the kernel reports that as "required file not found",
                ;; which reads like a missing compiler rather than a missing
                ;; shell.
                (substitute* (find-files share "^(em|bootstrap)[a-z+-]*$")
                  (("^#!/bin/sh$")
                   (string-append "#!" (assoc-ref inputs "bash") "/bin/sh")))
                ;; Emscripten populates its cache by copying headers out of
                ;; this package, and copytree preserves permissions.  Store
                ;; files are read-only, so a copied directory comes out
                ;; unwritable and the very next file into it fails -- while
                ;; still inside copytree, so repairing permissions afterwards
                ;; never runs.  Copy contents only, setting the modes here.
                (substitute* (string-append share "/tools/system_libs.py")
                  (("  shutil\\.copytree\\(src, dst, dirs_exist_ok=True\\)")
                   (string-append
                    "  for root, dirs, files in os.walk(src):\n"
                    "    rel = os.path.relpath(root, src)\n"
                    "    target = dst if rel == '.'"
                    " else os.path.join(dst, rel)\n"
                    "    os.makedirs(target, exist_ok=True)\n"
                    "    os.chmod(target, 0o755)\n"
                    "    for name in files:\n"
                    "      source = os.path.join(root, name)\n"
                    "      dest = os.path.join(target, name)\n"
                    "      shutil.copyfile(source, dest)\n"
                    "      os.chmod(dest, 0o644)\n")))
                ;; bootstrap.py compares stamp mtimes against its inputs.
                ;; Everything in the store shares one timestamp, and the check
                ;; is strictly-greater, so equal timestamps count as current.
                (mkdir-p (string-append share "/out"))
                (for-each
                 (lambda (stamp)
                   (call-with-output-file
                       (string-append share "/out/" stamp ".stamp")
                     (lambda (port) (display "" port))))
                 '("npm_packages" "create_entry_points" "git_submodules"))

                (mkdir-p llvm)
                (for-each
                 (lambda (file)
                   (let ((target (string-append clang "/bin/" file)))
                     (when (file-exists? target)
                       (symlink target (string-append llvm "/" file)))))
                 '("clang" "clang++" "clang-20"))
                (symlink (string-append lld "/bin/wasm-ld")
                         (string-append llvm "/wasm-ld"))
                (for-each
                 (lambda (file)
                   (let ((target (string-append llvm-tools "/bin/" file)))
                     (when (file-exists? target)
                       (symlink target (string-append llvm "/" file)))))
                 '("llvm-ar" "llvm-nm" "llvm-ranlib" "llvm-objcopy"
                   "llvm-dwarfdump" "llvm-dwp" "llvm-strip"))

                (call-with-output-file (string-append share "/config")
                  (lambda (port)
                    (format port "LLVM_ROOT = '~a'~%" llvm)
                    (format port "BINARYEN_ROOT = '~a'~%"
                            (assoc-ref inputs "binaryen"))
                    (format port "NODE_JS = '~a/bin/node'~%"
                            (assoc-ref inputs "node"))))

                ;; emcc's -O3 pipeline runs tools/acorn-optimizer.mjs,
                ;; which imports acorn; nothing else in this package needs a
                ;; node_module.
                (let ((acorn (string-append share "/node_modules/acorn")))
                  (mkdir-p (string-append acorn "/dist"))
                  (for-each
                   (lambda (spec)
                     (invoke "esbuild"
                             (string-append (assoc-ref inputs "acorn-source")
                                            "/acorn/src/index.js")
                             "--bundle" "--platform=neutral"
                             (string-append "--format=" (car spec))
                             (string-append "--outfile=" acorn "/dist/"
                                            (cdr spec))))
                   '(("esm" . "acorn.mjs") ("cjs" . "acorn.js")))
                  (call-with-output-file (string-append acorn "/package.json")
                    (lambda (port)
                      (display "{\"name\":\"acorn\",\"version\":\"8.15.0\",\
\"main\":\"dist/acorn.js\",\"module\":\"dist/acorn.mjs\",\
\"exports\":{\".\":{\"import\":\"./dist/acorn.mjs\",\
\"require\":\"./dist/acorn.js\",\"default\":\"./dist/acorn.js\"},\
\"./package.json\":\"./package.json\"}}\n"
                               port))))

                (mkdir-p (string-append out "/bin"))
                (for-each
                 (lambda (tool)
                   (let ((script (string-append out "/bin/" tool)))
                     (call-with-output-file script
                       (lambda (port)
                         (format port "#!~a/bin/bash~%" (assoc-ref inputs "bash"))
                         ;; The cache holds emscripten's own system libraries,
                         ;; compiled on first use, so it has to be writable.
                         (format port "export EM_CONFIG=~a/config~%" share)
                         (format port "export EM_CACHE=\"${EM_CACHE:-${TMPDIR:-/tmp}/emscripten-cache}\"~%")
                         ;; A Guix build environment points these at the host
                         ;; glibc, and clang honours them for every target, so
                         ;; a wasm compile would pick up host headers and
                         ;; libraries.  Nothing here is cross-compiled against
                         ;; the host, so drop them outright.
                         (format port "unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH~%")
                         (format port "unset OBJC_INCLUDE_PATH OBJCPLUS_INCLUDE_PATH~%")
                         (format port "unset CPATH LIBRARY_PATH~%")
                         (format port "export PATH=\"~a/bin:$PATH\"~%" python)
                         (format port "exec ~a/bin/python3 ~a/~a.py \"$@\"~%"
                                 python share tool)))
                     (chmod script #o555)))
                 '("emcc" "em++" "emar" "emranlib" "embuilder"))))))))
    (native-inputs (list esbuild python))
    (inputs
     `(("acorn-source" ,acorn-source)
       ("bash" ,bash-minimal)
       ("binaryen" ,binaryen)
       ("clang" ,clang-for-emscripten)
       ("lld" ,lld-20-from-source)
       ("llvm" ,llvm-20)
       ("node" ,node)
       ("python" ,python)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://emscripten.org")
    (synopsis "Compiler toolchain targeting WebAssembly")
    (description
     "Emscripten compiles C and C++ to WebAssembly, together with the
JavaScript glue needed to load and call it.  This package drives Guix's clang,
lld and binaryen; it does not bundle the emsdk downloads.")
    (license (list license:expat license:ncsa))))

;; The tree-sitter runtime that web-tree-sitter loads.  Unlike the grammars,
;; this one really is an emscripten artefact: it imports
;; wasi_snapshot_preview1.*, env.emscripten_resize_heap and env._abort_js, and
;; its exports are consumed by emscripten-generated JavaScript glue shipped in
;; the same npm package.  The flags below are xtask/src/build_wasm.rs verbatim,
;; so the module matches the glue that is already published.
(define-public web-tree-sitter-wasm
  (package
    (name "web-tree-sitter-wasm")
    (version "0.25.10")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference (url "https://github.com/tree-sitter/tree-sitter")
                           (commit (string-append "v" version))))
       (file-name (git-file-name "tree-sitter" version))
       (sha256
        (base32
         "1wv6nlxishxh6d2nzf2hrmpx41nzii4y219f06qa0bn2y9p36yv8"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 textual-ports)
                  (srfi srfi-1))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              (setenv "HOME" (getcwd))
              (setenv "EM_CACHE" (string-append (getcwd) "/.emscripten-cache"))
              (let* ((exports
                      ;; exports.txt is a quoted, comma-separated list; emcc
                      ;; wants the same names with a leading underscore.
                      (string-join
                       (map (lambda (line)
                              (string-append
                               "_" (string-trim-both
                                    (string-trim-right
                                     (string-trim-both line) #\,)
                                    #\")))
                            (remove string-null?
                                    (map string-trim-both
                                         (string-split
                                          (call-with-input-file
                                              "lib/binding_web/lib/exports.txt"
                                            get-string-all)
                                          #\newline))))
                       ","))
                     ;; Grammars are wasm side modules that import these from
                     ;; `env', so the runtime has to export them or every
                     ;; grammar fails to link.  Upstream's build keeps them
                     ;; without listing them; wasm-opt 125 (Guix's version;
                     ;; emscripten 4.0.4 expects 121) drops them instead, so
                     ;; name them.  This is exactly the set the published
                     ;; module exports beyond `exports.txt'.
                     (side-module-imports
                      (string-join '("_free" "_iswalnum" "_iswalpha"
                                     "_iswblank" "_iswdigit" "_iswlower"
                                     "_iswspace" "_iswupper" "_iswxdigit"
                                     "_malloc" "_memchr" "_memcmp" "_memcpy"
                                     "_memmove" "_memset" "_realloc" "_strcmp"
                                     "_strlen" "_strncat" "_strncmp"
                                     "_strncpy" "_towlower" "_towupper")
                                   ","))
                     (runtime-methods
                      (string-join '("AsciiToString" "stringToUTF8"
                                     "UTF8ToString" "lengthBytesUTF8"
                                     "stringToUTF16" "loadWebAssemblyModule"
                                     "getValue" "setValue")
                                   ",")))
                (invoke "emcc"
                        "-O3" "--minify" "0"
                        "-s" "EXPORT_ES6=1"
                        ;; Upstream also passes -gsource-map --source-map-base
                        ;; here.  Guix's binaryen is newer than the release
                        ;; emscripten expects and rejects the map it emits
                        ;; ("sourcesContent is not an array"), so the map is
                        ;; dropped; it is a debugging aid, and nothing loads
                        ;; it at runtime.
                        "-fno-exceptions" "-std=c11"
                        "-s" "WASM=1"
                        "-s" "MODULARIZE=1"
                        "-s" "INITIAL_MEMORY=33554432"
                        "-s" "ALLOW_MEMORY_GROWTH=1"
                        "-s" "SUPPORT_BIG_ENDIAN=1"
                        "-s" "MAIN_MODULE=2"
                        "-s" "FILESYSTEM=0"
                        "-s" "NODEJS_CATCH_EXIT=0"
                        "-s" "NODEJS_CATCH_REJECTION=0"
                        "-s" (string-append "EXPORTED_FUNCTIONS=" exports
                                            "," side-module-imports)
                        "-s" (string-append "EXPORTED_RUNTIME_METHODS="
                                            runtime-methods)
                        "-D" "fprintf(...)="
                        "-D" "NDEBUG="
                        "-D" "_POSIX_C_SOURCE=200112L"
                        "-D" "_DEFAULT_SOURCE="
                        "-D" "_DARWIN_C_SOURCE="
                        "-I" "lib/src"
                        "-I" "lib/include"
                        "--js-library" "lib/binding_web/lib/imports.js"
                        "--pre-js" "lib/binding_web/lib/prefix.js"
                        "-o" "lib/binding_web/lib/tree-sitter.mjs"
                        "lib/src/lib.c"
                        "lib/binding_web/lib/tree-sitter.c"))))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((wasm "lib/binding_web/lib/tree-sitter.wasm")
                    (lib (string-append (assoc-ref outputs "out") "/lib")))
                ;; emcc can exit 0 having written only the JavaScript.
                (unless (file-exists? wasm)
                  (error "emcc produced no WebAssembly module" wasm))
                (mkdir-p lib)
                (install-file wasm lib)
                ;; Keep the generated glue for comparison against the copy
                ;; published on npm, which is what actually loads the module.
                (install-file "lib/binding_web/lib/tree-sitter.mjs" lib)))))))
    (native-inputs (list emscripten))
    (supported-systems '("x86_64-linux"))
    (home-page "https://tree-sitter.github.io/")
    (synopsis "Tree-sitter runtime compiled to WebAssembly")
    (description
     "This package builds @file{tree-sitter.wasm}, the tree-sitter runtime that
the @code{web-tree-sitter} npm package loads, replacing the prebuilt module
that package ships.")
    (license license:expat)))

;; opencode and @opentui/core load tree-sitter grammars as WebAssembly, which
;; npm ships prebuilt.  Upstream builds them with emscripten, but the result is
;; a plain wasm side module: position-independent code carrying a `dylink.0'
;; section, importing memory, an indirect function table and eleven libc
;; functions from `env'.  `wasm-ld --shared' emits exactly that, so clang and
;; lld suffice and emscripten -- which Guix does not package -- is not needed.
(define (tree-sitter-grammar-source name repository commit hash)
  (origin
    (method git-fetch)
    (uri (git-reference (url (string-append "https://github.com/" repository))
                        (commit commit)))
    (file-name (git-file-name name commit))
    (sha256 (base32 hash))))

(define %tree-sitter-wasm-sources
  ;; (INPUT-NAME REPOSITORY COMMIT HASH), the commits behind the release
  ;; artifacts that @opentui/core's parsers-config.ts and opencode's
  ;; tree-sitter-bash dependency pin.
  '(("grammar-bash" "tree-sitter/tree-sitter-bash"          ;v0.25.0
     "56b54c61fb48bce0c63e3dfa2240b5d274384763"
     "1488r0lqldy92v8jr3n6w6iv99fdbcnmb1zxfshiz9azcgz8s5mx")
    ("grammar-javascript" "tree-sitter/tree-sitter-javascript" ;v0.25.0
     "44c892e0be055ac465d5eeddae6d3e194424e7de"
     "1qdjpfxw9z1icx3jc3k006yj76lcqydkvbk4ji3wk4xy854zz66q")
    ("grammar-typescript" "tree-sitter/tree-sitter-typescript" ;v0.23.2
     "f975a621f4e7f532fe322e13c4f79495e0a7b2e7"
     "0rlhhqp9dv6y0iljb4bf90d89f07zkfnsrxjb6rvw985ibwpjkh9")
    ("grammar-markdown" "tree-sitter-grammars/tree-sitter-markdown" ;v0.5.1
     "2dfd57f547f06ca5631a80f601e129d73fc8e9f0"
     "1sb5xq3685v5dcnq2yfh3gq3qj7ldhlkff25snpdgqgvjkla32i1")
    ("grammar-zig" "tree-sitter-grammars/tree-sitter-zig"   ;v1.1.2
     "b670c8df85a1568f498aa5c8cae42f51a90473c0"
     "1r9p7hhnc1zagwxzdxhs4p6rnqs9naddkgbfymi6pbw6cyg2ccwl")))

(define %tree-sitter-wasm-grammars
  ;; (OUTPUT-BASENAME INPUT-NAME SOURCE-SUBDIRECTORY EXPORTED-SYMBOL)
  '(("tree-sitter-bash" "grammar-bash" "src" "tree_sitter_bash")
    ("tree-sitter-javascript" "grammar-javascript" "src"
     "tree_sitter_javascript")
    ("tree-sitter-typescript" "grammar-typescript" "typescript/src"
     "tree_sitter_typescript")
    ("tree-sitter-markdown" "grammar-markdown" "tree-sitter-markdown/src"
     "tree_sitter_markdown")
    ("tree-sitter-markdown_inline" "grammar-markdown"
     "tree-sitter-markdown-inline/src" "tree_sitter_markdown_inline")
    ("tree-sitter-zig" "grammar-zig" "src" "tree_sitter_zig")))

(define-public tree-sitter-wasm-grammars
  (package
    (name "tree-sitter-wasm-grammars")
    (version "0.25")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils) (ice-9 match))
      #:builder
      #~(begin
          (use-modules (guix build utils) (ice-9 match))
          (let ((clang (assoc-ref %build-inputs "clang"))
                (lld (assoc-ref %build-inputs "lld"))
                (wasi (assoc-ref %build-inputs "wasi-libc"))
                (lib (string-append #$output "/lib")))
            (setenv "PATH"
                    (string-append clang "/bin:" lld "/bin:"
                                   (assoc-ref %build-inputs "coreutils")
                                   "/bin"))
            (mkdir-p lib)
            (mkdir-p "objects")
            (for-each
             (match-lambda
               ((output input subdirectory symbol)
                (let* ((directory
                        (let ((from (assoc-ref %build-inputs input))
                              (to (string-append (getcwd) "/src-" input)))
                          ;; clang records each translation unit's path in the
                          ;; module it emits, so compiling straight out of the
                          ;; store makes this checkout a runtime reference of
                          ;; everything that embeds the grammar.  The whole
                          ;; checkout is copied, not just the subdirectory:
                          ;; typescript's scanner.c includes a header from
                          ;; ../../common.  One checkout can also serve two
                          ;; grammars, as markdown does, so copy it once.
                          (unless (file-exists? to)
                            (copy-recursively from to))
                          (string-append to "/" subdirectory)))
                       (sources (find-files directory "\\.c$"))
                       (objects
                        (map (lambda (source)
                               (let ((object (string-append
                                              "objects/" output "-"
                                              (basename source ".c") ".o")))
                                 (invoke
                                  "clang" "--target=wasm32-wasi" "-nostdinc"
                                  ;; Guix's clang searches the host glibc
                                  ;; headers ahead of any --sysroot, so name
                                  ;; both header sets explicitly instead.
                                  "-isystem" (string-append
                                              clang "/lib/clang/19/include")
                                  "-isystem"
                                  (string-append
                                   wasi
                                   "/share/wasi-sysroot/include/wasm32-wasi")
                                  "-fPIC" "-fvisibility=hidden" "-Os"
                                  "-std=c11" (string-append "-I" directory)
                                  "-c" source "-o" object)
                                 object))
                             sources)))
                  (when (null? objects)
                    (error "no grammar sources found" directory))
                  (apply invoke "wasm-ld" "--shared" "--allow-undefined"
                         "--no-entry" "--strip-all"
                         (string-append "--export=" symbol)
                         ;; Grammars with no static constructors do not have
                         ;; this symbol, and a plain --export would be fatal.
                         "--export-if-defined=__wasm_call_ctors"
                         "-o" (string-append lib "/" output ".wasm")
                         objects))))
             '#$%tree-sitter-wasm-grammars)))))
    (native-inputs
     `(("clang" ,clang-19)
       ("lld" ,lld-19)
       ("coreutils" ,coreutils)
       ("wasi-libc" ,wasi-libc)
       ,@(map (lambda (entry)
                (list (car entry)
                      (tree-sitter-grammar-source (car entry) (cadr entry)
                                                  (caddr entry)
                                                  (cadddr entry))))
              %tree-sitter-wasm-sources)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://tree-sitter.github.io/")
    (synopsis "Tree-sitter grammars compiled to WebAssembly")
    (description
     "This package builds the tree-sitter grammars that opencode and
@code{@@opentui/core} load through @code{web-tree-sitter}, replacing the
WebAssembly modules those packages ship prebuilt on npm.")
    (license license:expat)))

;; @parcel/watcher publishes its N-API addon as a prebuilt binary in a
;; per-platform package (@parcel/watcher-linux-x64-glibc).  Build it instead.
;; node-addon-api is a header-only C++ wrapper over the stable Node-API, which
;; Bun implements, so the result loads under Bun as well as Node.
(define node-addon-api-source
  (origin
    (method git-fetch)
    (uri (git-reference (url "https://github.com/nodejs/node-addon-api")
                        (commit "5e96a5460f2538a06f87e592d6aa349a7f08b04a")))
    (file-name (git-file-name "node-addon-api" "7.1.1"))
    (sha256
     (base32
      "152wv36ybpyhz71j1k68mj91gwq8611ki3jx0ixzvrbp7rw44hmq"))))

(define-public parcel-watcher-node
  (package
    (name "parcel-watcher-node")
    (version "2.5.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference (url "https://github.com/parcel-bundler/watcher")
                           (commit (string-append "v" version))))
       (file-name (git-file-name "parcel-watcher" version))
       (sha256
        (base32
         "0w4m0xxm7wfzmp20ii5i1wrn140ph6diyf4yd9mfqvi3s74qj63a"))
       (modules '((guix build utils)))
       ;; The repository vendors watchman's Windows binaries for its test
       ;; suite; this package builds the Linux addon and never runs them.
       (snippet
        #~(when (file-exists? "watchman/windows/bin")
            (delete-file-recursively "watchman/windows/bin")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The source list and defines are binding.gyp's `linux'
              ;; condition; node-gyp itself is not needed to apply them.
              (let ((sources '("src/binding.cc"
                               "src/Watcher.cc"
                               "src/Backend.cc"
                               "src/DirTree.cc"
                               "src/Glob.cc"
                               "src/Debounce.cc"
                               "src/watchman/BSER.cc"
                               "src/watchman/WatchmanBackend.cc"
                               "src/shared/BruteForceBackend.cc"
                               "src/linux/InotifyBackend.cc"
                               "src/unix/legacy.cc"))
                    (node-api (assoc-ref inputs "node-addon-api-source"))
                    (node (assoc-ref inputs "node")))
                (mkdir-p "objects")
                (let ((objects
                       (map (lambda (source)
                              (let ((object
                                     (string-append
                                      "objects/"
                                      (string-map (lambda (c)
                                                    (if (char=? c #\/) #\- c))
                                                  source)
                                      ".o")))
                                (invoke "g++" "-std=c++17" "-fPIC" "-O2"
                                        "-fexceptions"
                                        "-DNAPI_DISABLE_CPP_EXCEPTIONS"
                                        "-DWATCHMAN" "-DINOTIFY"
                                        "-DBRUTE_FORCE"
                                        "-DBUILDING_NODE_EXTENSION"
                                        (string-append "-I" node-api)
                                        (string-append "-I" node
                                                       "/include/node")
                                        "-c" source "-o" object)
                                object))
                            sources)))
                  (apply invoke "g++" "-shared" "-o" "watcher.node"
                         (append objects (list "-lpthread")))))))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((lib (string-append (assoc-ref outputs "out") "/lib")))
                (unless (file-exists? "watcher.node")
                  (error "no addon was produced"))
                (mkdir-p lib)
                (install-file "watcher.node" lib)))))))
    (native-inputs
     `(("node" ,node)
       ("node-addon-api-source" ,node-addon-api-source)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/parcel-bundler/watcher")
    (synopsis "Filesystem watcher addon behind @code{@@parcel/watcher}")
    (description
     "This package provides @file{watcher.node}, the C++ Node-API addon that
@code{@@parcel/watcher} loads to subscribe to filesystem events.  It replaces
the binary published in the @code{@@parcel/watcher-linux-x64-glibc} npm
package, and uses the inotify, brute-force and watchman backends that
upstream's @file{binding.gyp} selects on Linux.")
    (license license:expat)))

(define-public librust-pty
  (package
    (name "librust-pty")
    (version "0.4.8")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference (url "https://github.com/sursaone/bun-pty")
                           (commit "v0.4.8")))
       (file-name (git-file-name "bun-pty" "0.4.8"))
       (sha256
        (base32
         "17wgpjshc92wcl72m2qhf3c6il1capx7vyzrak4404is5q311avw"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((registry (string-append (getcwd) "/vendor/rust-crates")))
                (mkdir-p registry)
                (for-each
                 (lambda (entry)
                   (let* ((name (car entry))
                          (version (cadr entry))
                          (checksum (caddr entry))
                          (directory (string-append registry "/" name "-"
                                                    version)))
                     (mkdir-p directory)
                     (invoke "tar" "xf"
                             (assoc-ref inputs (string-append "crate-" name "-"
                                                              version))
                             "-C" directory "--strip-components=1")
                     ;; An empty `files' map tells cargo not to re-verify
                     ;; contents the store already authenticated; `package'
                     ;; must still match the lockfile checksum.
                     (call-with-output-file
                         (string-append directory "/.cargo-checksum.json")
                       (lambda (port)
                         (format port "{\"files\":{},\"package\":\"~a\"}"
                                 checksum)))))
                 '#$(map (lambda (entry)
                           (list (car entry) (cadr entry) (cadddr entry)))
                         %rust-pty-vendored-crates))
                (setenv "CARGO_HOME" (string-append (getcwd) "/.cargo-home"))
                (mkdir-p ".cargo")
                (call-with-output-file ".cargo/config.toml"
                  (lambda (port)
                    (format port "[source.crates-io]~%\
replace-with = \"vendored-sources\"~%~%\
[source.vendored-sources]~%\
directory = \"~a\"~%" registry))))
              (with-directory-excursion "rust-pty"
                (invoke "cargo" "build" "--release" "--offline"))))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((library "rust-pty/target/release/librust_pty.so")
                    (lib (string-append (assoc-ref outputs "out") "/lib")))
                ;; cargo can succeed without producing a cdylib if the crate
                ;; type ever changes upstream.
                (unless (file-exists? library)
                  (error "cargo produced no library" library))
                (mkdir-p lib)
                (install-file library lib)))))))
    (native-inputs
     `(("rust" ,rust)
       ("rust:cargo" ,rust "cargo")
       ,@(map (lambda (entry)
                (list (string-append "crate-" (car entry) "-" (cadr entry))
                      (crates-io-source entry)))
              %rust-pty-vendored-crates)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/sursaone/bun-pty")
    (synopsis "Pseudoterminal library behind the @code{bun-pty} package")
    (description
     "This package provides @file{librust_pty.so}, the Rust @code{cdylib} that
the @code{bun-pty} JavaScript package loads through Bun's FFI.  It replaces the
binary that @code{bun-pty} ships prebuilt on npm.")
    (license license:expat)))


;; Bun does not link against a stock JavaScriptCore: it uses its own WebKit
;; fork, built as a static JSCOnly port with Bun-specific additions enabled.
;; Upstream distributes that as a prebuilt tarball; build it from source
;; instead, so that no binary blob enters the bootstrap chain.  The commit is
;; the one recorded in the prebuilt tarball's package.json, and the
;; configuration mirrors the fork's own Dockerfile.  Note upstream copies the
;; host distribution's static ICU archives into the tarball; here ICU comes
;; from Guix instead, which is why no ICU version needs pinning.
(define* (make-bun-webkit revision hash #:key (extra-configure-flags '())
                          (use-clang? #f))
  "Return a package building JavaScriptCore from Bun's WebKit fork at
REVISION.  Each Bun release pins its own WebKit revision, and the options that
revision expects differ, hence EXTRA-CONFIGURE-FLAGS."
  (package
    (name "bun-webkit")
    (version (string-append "0.0.1-" (substring revision 0 7)))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/oven-sh/WebKit")
             (commit revision)))
       (file-name (git-file-name name version))
       (sha256
        (base32 hash))
       (modules '((guix build utils) (srfi srfi-1)
                   (ice-9 binary-ports) (rnrs bytevectors)))
       ;; WebKit's tree carries compiled fixtures -- .wasm modules for the
       ;; JavaScript test suites, Windows DLLs, a prebuilt Android profiler,
       ;; test fonts.  None are read by a JSCOnly build, which does not run
       ;; these suites, but they are prebuilt binaries entering the build all
       ;; the same.  Remove the binaries, not the directories, so nothing the
       ;; build might reference goes missing.
       (snippet
        #~(let ()
            ;; Match on content, not on the name: several of these have no
            ;; extension (a prebuilt Android profiler, a musl test binary) or
            ;; carry one after it (emu_bench_bg.wasm.release).
            (define (compiled? file stat)
              (and (eq? 'regular (stat:type stat))
                   (> (stat:size stat) 4)
                   (call-with-input-file file
                     (lambda (port)
                       (let ((head (get-bytevector-n port 4)))
                         (and (bytevector? head)
                              (= 4 (bytevector-length head))
                              (member (bytevector->u8-list head)
                                      '((#x7f #x45 #x4c #x46)   ;ELF
                                        (#x00 #x61 #x73 #x6d)   ;WebAssembly
                                        (#x21 #x3c #x61 #x72)   ;ar archive
                                        (#xcf #xfa #xed #xfe)   ;Mach-O
                                        (#xce #xfa #xed #xfe)))
                              #t))))
                   (not (string-suffix? ".c" file))))
            (for-each
             delete-file
             (append-map
              (lambda (directory)
                (if (file-exists? directory)
                    (find-files directory compiled?)
                    '()))
              '("JSTests" "LayoutTests" "PerformanceTests" "WebDriverTests"
                "Websites" "Tools"
                "Source/ThirdParty/skia/platform_tools"
                "Source/ThirdParty/libwebrtc/Source/third_party/boringssl/src/util")))
            ;; PE binaries start with "MZ", which is only two bytes.
            (for-each
             delete-file
             (append-map
              (lambda (directory)
                (if (file-exists? directory)
                    (find-files directory "\\.(dll|exe|lib|pdb|fon)$")
                    '()))
              '("JSTests" "LayoutTests" "PerformanceTests" "WebDriverTests"
                "Websites" "Tools")))))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f
      #:build-type "Release"
      #:configure-flags
      #~(append
         (list "-DPORT=JSCOnly"
               "-DENABLE_STATIC_JSC=ON"
               "-DENABLE_BUN_SKIP_FAILING_ASSERTIONS=ON"
               "-DUSE_THIN_ARCHIVES=OFF"
               "-DUSE_BUN_JSC_ADDITIONS=ON"
               "-DENABLE_FTL_JIT=ON"
               "-DALLOW_LINE_AND_COLUMN_NUMBER_IN_BUILTINS=ON"
               "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
         ;; Revisions that enable Bun's own run loop only compile with
         ;; clang, which is what upstream builds them with.
         (if #$use-clang?
             (list "-DCMAKE_C_COMPILER=clang"
                   "-DCMAKE_CXX_COMPILER=clang++")
             '())
         '#$extra-configure-flags)
      #:phases
      #~(modify-phases %standard-phases
          (replace 'build
            (lambda* (#:key parallel-build? #:allow-other-keys)
              ;; The inspector-protocol generator shells out to a C
              ;; preprocessor, falling back to /usr/bin/{clang,gcc} when CC is
              ;; unset -- neither of which exists in the build container.
              (setenv "CC" (if #$use-clang? "clang" "gcc"))
              (invoke "make" "jsc"
                      "-j" (if parallel-build?
                               (number->string (parallel-job-count))
                               "1"))))
          ;; The JSCOnly port has no install target; assemble the layout Bun
          ;; expects (the same one the prebuilt tarball provides).
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((include (string-append #$output "/include"))
                     (jsc-include (string-append include "/JavaScriptCore"))
                     (lib (string-append #$output "/lib")))
                (mkdir-p jsc-include)
                (mkdir-p lib)
                (for-each (lambda (archive) (install-file archive lib))
                          (find-files "lib" "\\.a$"))
                ;; Only the headers generated at the top of the build tree
                ;; (cmakeconfig.h); find-files matches on the base name, so
                ;; restrict by directory rather than by pattern.
                (for-each (lambda (header) (install-file header include))
                          (find-files "."
                                      (lambda (file stat)
                                        (and (string-suffix? ".h" file)
                                             (string=? (dirname file) ".")))))
                (for-each (lambda (header) (install-file header jsc-include))
                          (append
                           (find-files "JavaScriptCore/Headers/JavaScriptCore"
                                       "\\.h$")
                           (find-files
                            "JavaScriptCore/PrivateHeaders/JavaScriptCore"
                            "\\.h$")))
                (copy-recursively "WTF/Headers/wtf"
                                  (string-append include "/wtf"))
                (copy-recursively "bmalloc/Headers/bmalloc"
                                  (string-append include "/bmalloc"))
                ;; Later revisions also generate headers here.  Their build
                ;; tree additionally holds WebKit's own build helpers under
                ;; bin/, but Bun consumes only include/ and lib/, so those are
                ;; deliberately not installed.
                (when (file-exists? "JavaScriptCore/DerivedSources")
                  (for-each (lambda (header)
                              (install-file header jsc-include))
                            (find-files "JavaScriptCore/DerivedSources"
                                        "\\.h$")))
                ;; Bun's SetupWebKit.cmake accepts a pre-supplied WebKit only
                ;; if this file is present and names the expected revision;
                ;; otherwise it tries to download the release tarball.
                (call-with-output-file (string-append #$output
                                                      "/package.json")
                  (lambda (port)
                    (display (string-append
                              "{ \"name\": \"bun-webkit\", \"version\": \"0.0.1-"
                              #$revision "\" }\n")
                             port)))
                ;; Bun's build runs these generator scripts out of the JSC
                ;; source tree.
                (let ((source (assoc-ref inputs "source"))
                      (jsc (string-append #$output
                                          "/Source/JavaScriptCore")))
                  (mkdir-p jsc)
                  (copy-recursively
                   (string-append source "/Source/JavaScriptCore/Scripts")
                   (string-append jsc "/Scripts"))
                  (install-file
                   (string-append source
                                  "/Source/JavaScriptCore/create_hash_table")
                   jsc))))))))
    (native-inputs
     (append (list perl python ruby)
             (if use-clang? (list clang lld) '())))
    (inputs
     (list icu4c))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/oven-sh/WebKit")
    (synopsis "JavaScriptCore build used by Bun")
    (description
     "This package provides a static JavaScriptCore built from Bun's WebKit
fork, in the directory layout Bun's build system expects.  It replaces the
prebuilt @code{bun-webkit} tarball that upstream downloads.")
    (license license:lgpl2.1+)))

;; The revision Bun 1.0.0 pins, taken from the prebuilt tarball's package.json.
(define-public bun-webkit
  (make-bun-webkit "48c1316e907ca597e27e5a7624160dc18a4df8ec"
                   "1pg74mihlpk1mim1k5mkcr9xldvn6wz2cljzywzm5y9q38w8xh3n"
                   #:extra-configure-flags
                   '("-DENABLE_SINGLE_THREADED_VM_ENTRY_SCOPE=ON")))

;; The revision Bun 1.2.0 pins, from WEBKIT_VERSION in its
;; cmake/tools/SetupWebKit.cmake.
(define-public bun-webkit-for-1.2.0
  (make-bun-webkit "9e3b60e4a6438d20ee6f8aa5bec6b71d2b7d213f"
                   "1lbs2bx6pyv61rvm4gdmhdf3yln1f7xc3kng82lcf3kgi9ixhld1"
                   #:extra-configure-flags
                   '("-DUSE_BUN_EVENT_LOOP=OFF"
                     "-DENABLE_REMOTE_INSPECTOR=ON")))

;; The revision Bun 1.3.8 pins; its tag name encodes the commit.
(define-public bun-webkit-for-1.3.8
  (make-bun-webkit "9a2cc42ae1bf693a0fd0ceb9b1d7d965d9cfd3ea"
                   "132jgjf7f0z5kn4698wvs8hvpad2m6q4qmvsxqbnfy4k3lhga1yg"
                   #:use-clang? #t
                   #:extra-configure-flags
                   '("-DUSE_BUN_EVENT_LOOP=ON"
                     "-DENABLE_REMOTE_INSPECTOR=ON")))

;; Bun 1.0.0 vendors an older mimalloc fork (Jarred-Sumner/mimalloc, commit
;; 7968d42, MI_MALLOC_VERSION 210) whose "default heap" accessor
;; (mi_heap_get_default, returning mi_heap_t*) was replaced in current
;; mimalloc releases by a distinct "theap" API family (mi_theap_get_default,
;; returning the unrelated type mi_theap_t*).  Pin an older mimalloc release
;; that still provides the classic API Bun's Zig bindings call, instead of
;; adapting Bun's allocator code to an API with different type guarantees.
(define mimalloc-3.1
  (package
    (inherit mimalloc)
    (version "3.1.6")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/microsoft/mimalloc/archive/refs/tags/v"
                    version ".tar.gz"))
              (sha256
               (base32
                "1z7xvdbrp6yj5jhy2kmbqavg6bfjzphvbwca5qchs64gr0a1vr2l"))))))

(define-public bun-stage0
  (package
    (name "bun-stage0")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/oven-sh/bun/archive/refs/tags/bun-v"
             version ".tar.gz"))
       (sha256
        (base32
         "13d716bv9iwcs7ydklar2iycvdhnnjxkjr4x1awzqn85byyjyv2n"))
       (modules %strip-modules)
       (snippet
        #~(begin
            ;; Keep source unpack size reasonable in tmpfs-backed builds.
            (delete-file-recursively "packages/bun-uws/fuzzing/seed-corpus")
            #$%strip-compiled-artefacts))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (guix build bun-build-system))
      #:imported-modules `(,@%default-gnu-imported-modules
                           (json)
                           (json builder)
                           (json parser)
                           (json record)
                           (guix build bun-build-system))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'prepare-webkit
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "JSC_BASE_DIR" (assoc-ref inputs "bun-webkit"))
              ;; The release tarball omits the mimalloc submodule; restore it
              ;; at the pinned commit so the Makefile builds the allocator
              ;; Bun's Zig bindings were written against.
              (mkdir-p "src/deps/mimalloc")
              (invoke "tar" "xf" (assoc-ref inputs "mimalloc-source")
                      "-C" "src/deps/mimalloc" "--strip-components=1")
              ;; Bun's release tarball also omits boringssl headers.
              ;; Use OpenSSL compatibility headers to satisfy includes.
              (mkdir-p "src/deps/boringssl/include")
              (copy-recursively
               (string-append (assoc-ref inputs "openssl")
                              "/include/openssl")
               "src/deps/boringssl/include/openssl")
              ;; OpenSSL does not provide BoringSSL's curve25519 header.
              ;; Provide a minimal shim implementing the symbols Bun expects.
              (call-with-output-file "src/deps/boringssl/include/openssl/curve25519.h"
                (lambda (port)
                  (display
"#ifndef OPENSSL_CURVE25519_SHIM_H\n#define OPENSSL_CURVE25519_SHIM_H\n\n#include <stddef.h>\n#include <stdint.h>\n#include <string.h>\n\n#include <openssl/evp.h>\n\n#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n#define ED25519_PUBLIC_KEY_LEN 32\n#define ED25519_PRIVATE_KEY_LEN 64\n#define ED25519_SIGNATURE_LEN 64\n#define X25519_PUBLIC_VALUE_LEN 32\n#define X25519_PRIVATE_KEY_LEN 32\n\nstatic inline void ED25519_keypair_from_seed(uint8_t out_public_key[ED25519_PUBLIC_KEY_LEN], uint8_t out_private_key[ED25519_PRIVATE_KEY_LEN], const uint8_t seed[32])\n{\n    EVP_PKEY* pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_ED25519, NULL, seed, 32);\n    if (!pkey) {\n        memset(out_public_key, 0, ED25519_PUBLIC_KEY_LEN);\n        memset(out_private_key, 0, ED25519_PRIVATE_KEY_LEN);\n        return;\n    }\n\n    size_t public_len = ED25519_PUBLIC_KEY_LEN;\n    if (EVP_PKEY_get_raw_public_key(pkey, out_public_key, &public_len) != 1 || public_len != ED25519_PUBLIC_KEY_LEN) {\n        memset(out_public_key, 0, ED25519_PUBLIC_KEY_LEN);\n        memset(out_private_key, 0, ED25519_PRIVATE_KEY_LEN);\n        EVP_PKEY_free(pkey);\n        return;\n    }\n\n    memcpy(out_private_key, seed, 32);\n    memcpy(out_private_key + 32, out_public_key, 32);\n    EVP_PKEY_free(pkey);\n}\n\nstatic inline void ED25519_keypair(uint8_t out_public_key[ED25519_PUBLIC_KEY_LEN], uint8_t out_private_key[ED25519_PRIVATE_KEY_LEN])\n{\n    EVP_PKEY_CTX* pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_ED25519, NULL);\n    EVP_PKEY* pkey = NULL;\n    uint8_t raw_private[32];\n    size_t private_len = sizeof(raw_private);\n    size_t public_len = ED25519_PUBLIC_KEY_LEN;\n\n    if (!pctx\n        || EVP_PKEY_keygen_init(pctx) != 1\n        || EVP_PKEY_keygen(pctx, &pkey) != 1\n        || EVP_PKEY_get_raw_private_key(pkey, raw_private, &private_len) != 1\n        || private_len != sizeof(raw_private)\n        || EVP_PKEY_get_raw_public_key(pkey, out_public_key, &public_len) != 1\n        || public_len != ED25519_PUBLIC_KEY_LEN) {\n        memset(out_public_key, 0, ED25519_PUBLIC_KEY_LEN);\n        memset(out_private_key, 0, ED25519_PRIVATE_KEY_LEN);\n        if (pkey)\n            EVP_PKEY_free(pkey);\n        if (pctx)\n            EVP_PKEY_CTX_free(pctx);\n        return;\n    }\n\n    memcpy(out_private_key, raw_private, 32);\n    memcpy(out_private_key + 32, out_public_key, 32);\n    EVP_PKEY_free(pkey);\n    EVP_PKEY_CTX_free(pctx);\n}\n\nstatic inline void ED25519_sign(uint8_t out_sig[ED25519_SIGNATURE_LEN], const uint8_t* message, size_t message_len, const uint8_t private_key[ED25519_PRIVATE_KEY_LEN])\n{\n    EVP_PKEY* pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_ED25519, NULL, private_key, 32);\n    EVP_MD_CTX* ctx = NULL;\n    size_t sig_len = ED25519_SIGNATURE_LEN;\n\n    if (!pkey) {\n        memset(out_sig, 0, ED25519_SIGNATURE_LEN);\n        return;\n    }\n\n    ctx = EVP_MD_CTX_new();\n    if (!ctx\n        || EVP_DigestSignInit(ctx, NULL, NULL, NULL, pkey) != 1\n        || EVP_DigestSign(ctx, out_sig, &sig_len, message, message_len) != 1\n        || sig_len != ED25519_SIGNATURE_LEN) {\n        memset(out_sig, 0, ED25519_SIGNATURE_LEN);\n    }\n\n    EVP_MD_CTX_free(ctx);\n    EVP_PKEY_free(pkey);\n}\n\nstatic inline int ED25519_verify(const uint8_t* message, size_t message_len, const uint8_t signature[ED25519_SIGNATURE_LEN], const uint8_t public_key[ED25519_PUBLIC_KEY_LEN])\n{\n    EVP_PKEY* pkey = EVP_PKEY_new_raw_public_key(EVP_PKEY_ED25519, NULL, public_key, ED25519_PUBLIC_KEY_LEN);\n    EVP_MD_CTX* ctx = NULL;\n    int result = 0;\n\n    if (!pkey)\n        return 0;\n\n    ctx = EVP_MD_CTX_new();\n    if (ctx && EVP_DigestVerifyInit(ctx, NULL, NULL, NULL, pkey) == 1)\n        result = EVP_DigestVerify(ctx, signature, ED25519_SIGNATURE_LEN, message, message_len) == 1;\n\n    EVP_MD_CTX_free(ctx);\n    EVP_PKEY_free(pkey);\n    return result;\n}\n\nstatic inline void X25519_keypair(uint8_t out_public_value[X25519_PUBLIC_VALUE_LEN], uint8_t out_private_key[X25519_PRIVATE_KEY_LEN])\n{\n    EVP_PKEY_CTX* pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_X25519, NULL);\n    EVP_PKEY* pkey = NULL;\n    size_t private_len = X25519_PRIVATE_KEY_LEN;\n    size_t public_len = X25519_PUBLIC_VALUE_LEN;\n\n    if (!pctx\n        || EVP_PKEY_keygen_init(pctx) != 1\n        || EVP_PKEY_keygen(pctx, &pkey) != 1\n        || EVP_PKEY_get_raw_private_key(pkey, out_private_key, &private_len) != 1\n        || private_len != X25519_PRIVATE_KEY_LEN\n        || EVP_PKEY_get_raw_public_key(pkey, out_public_value, &public_len) != 1\n        || public_len != X25519_PUBLIC_VALUE_LEN) {\n        memset(out_public_value, 0, X25519_PUBLIC_VALUE_LEN);\n        memset(out_private_key, 0, X25519_PRIVATE_KEY_LEN);\n    }\n\n    if (pkey)\n        EVP_PKEY_free(pkey);\n    if (pctx)\n        EVP_PKEY_CTX_free(pctx);\n}\n\nstatic inline void X25519_public_from_private(uint8_t out_public_value[X25519_PUBLIC_VALUE_LEN], const uint8_t private_key[X25519_PRIVATE_KEY_LEN])\n{\n    EVP_PKEY* pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_X25519, NULL, private_key, X25519_PRIVATE_KEY_LEN);\n    size_t public_len = X25519_PUBLIC_VALUE_LEN;\n\n    if (!pkey || EVP_PKEY_get_raw_public_key(pkey, out_public_value, &public_len) != 1 || public_len != X25519_PUBLIC_VALUE_LEN)\n        memset(out_public_value, 0, X25519_PUBLIC_VALUE_LEN);\n\n    if (pkey)\n        EVP_PKEY_free(pkey);\n}\n\n#ifdef __cplusplus\n}\n#endif\n\n#endif\n"
                   port)))
              ;; OpenSSL also does not ship BoringSSL's hkdf header.
              ;; Provide a minimal HKDF wrapper backed by OpenSSL APIs.
              (call-with-output-file "src/deps/boringssl/include/openssl/hkdf.h"
                (lambda (port)
                  (display
"#ifndef OPENSSL_HKDF_SHIM_H\n#define OPENSSL_HKDF_SHIM_H\n\n#include <limits.h>\n#include <stddef.h>\n#include <stdint.h>\n\n#include <openssl/evp.h>\n#include <openssl/kdf.h>\n\n#ifdef __cplusplus\nextern \"C\" {\n#endif\n\nstatic inline int HKDF(uint8_t* out_key, size_t out_len, const EVP_MD* digest,\n    const uint8_t* secret, size_t secret_len,\n    const uint8_t* salt, size_t salt_len,\n    const uint8_t* info, size_t info_len)\n{\n    EVP_PKEY_CTX* pctx = NULL;\n    size_t derived_len = out_len;\n    int ok = 0;\n\n    if (!out_key || !digest)\n        return 0;\n\n    if (secret_len > INT_MAX || salt_len > INT_MAX || info_len > INT_MAX)\n        return 0;\n\n    pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_HKDF, NULL);\n    if (!pctx)\n        return 0;\n\n    ok = EVP_PKEY_derive_init(pctx) == 1\n        && EVP_PKEY_CTX_set_hkdf_md(pctx, digest) == 1\n        && EVP_PKEY_CTX_set1_hkdf_key(pctx, secret, (int)secret_len) == 1\n        && EVP_PKEY_CTX_set1_hkdf_salt(pctx, salt, (int)salt_len) == 1\n        && EVP_PKEY_CTX_add1_hkdf_info(pctx, info, (int)info_len) == 1\n        && EVP_PKEY_derive(pctx, out_key, &derived_len) == 1\n        && derived_len == out_len;\n\n    EVP_PKEY_CTX_free(pctx);\n    return ok ? 1 : 0;\n}\n\n#ifdef __cplusplus\n}\n#endif\n\n#endif\n"
                   port)))
              ;; OpenSSL does not ship BoringSSL's mem header.
              ;; Provide it by delegating to OpenSSL's crypto header.
              (call-with-output-file "src/deps/boringssl/include/openssl/mem.h"
                (lambda (port)
                  (display
"#ifndef OPENSSL_MEM_SHIM_H\n#define OPENSSL_MEM_SHIM_H\n\n#include <openssl/crypto.h>\n\n#endif\n"
                   port)))
              ;; Keep stage0 objects small enough for tmpfs-backed builders.
              (substitute* "Makefile"
                (("EMIT_LLVM_FOR_RELEASE=-emit-llvm -flto=\\\"full\\\"")
                 "EMIT_LLVM_FOR_RELEASE=")
                (("OPTIMIZATION_LEVEL=-O3 \\$\\(MARCH_NATIVE\\)")
                 "OPTIMIZATION_LEVEL=-O2 $(MARCH_NATIVE)")
                ;; simdutf picks its implementation at run time, so building
                ;; for a fixed CPU_TARGET does not keep it off the AVX-512
                ;; path, where it segfaults validating input here.  Compile
                ;; that kernel out and let it dispatch to the AVX2 one.
                (("-DSTATICALLY_LINKED_WITH_JavaScriptCore=1")
                 "-DSTATICALLY_LINKED_WITH_JavaScriptCore=1 -DSIMDUTF_IMPLEMENTATION_ICELAKE=0")
                ;; Avoid forcing non-PIC static libatomic at final link.
                (("-l:libatomic\\.a")
                 "-latomic")
                ;; Link command places libs before most objects; keep needed
                ;; shared libs from being discarded in that ordering.
                (("-Wl,--as-needed")
                 "")
                ;; Ensure local compatibility shims participate in final link.
                (("src/deps/libmimalloc\\.o")
                 "src/deps/libmimalloc.o src/deps/guix-link-compat.o")
                ;; Upstream links the static ICU archives that its prebuilt
                ;; JavaScriptCore tarball bundles.  Guix's icu4c ships shared
                ;; libraries only, and JavaScriptCore is built against those.
                (("\\$\\(LIB_ICU_PATH\\)/libicuuc\\.a \\$\\(LIB_ICU_PATH\\)/libicudata\\.a \\$\\(LIB_ICU_PATH\\)/libicui18n\\.a")
                 "-licuuc -licudata -licui18n"))

              ;; Newer libc++/libstdc++ combinations can exceed constexpr
              ;; evaluation limits on these very large generated literals.
              (substitute* "src/js/out/InternalModuleRegistryConstants.h"
                (("static constexpr ASCIILiteral")
                 "static const ASCIILiteral"))
              ;; Newer libstdc++ no longer includes <cstdlib> transitively.
              (substitute* "src/bun.js/bindings/workaround-missing-symbols.cpp"
                (("#include <errno.h>")
                 "#include <errno.h>\n#include <cstdlib>"))
              (substitute* (list "src/bun.js/bindings/webcrypto/CryptoAlgorithmAesCbcCfbParams.h"
                                 "src/bun.js/bindings/webcrypto/CryptoAlgorithmAesCtrParams.h"
                                 "src/bun.js/bindings/webcrypto/CryptoAlgorithmAesGcmParams.h"
                                 "src/bun.js/bindings/webcrypto/CryptoAlgorithmPbkdf2Params.h"
                                 "src/bun.js/bindings/webcrypto/CryptoAlgorithmHkdfParams.h")
                (("append\\(([^\\)]*)\\.data\\(\\), ([^\\)]*)\\.length\\(\\)\\);" _ var1 var2)
                 (string-append "append(std::span<const uint8_t> { " var1 ".data(), " var2 ".length() });")))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoAlgorithmAES_GCMOpenSSL.cpp"
                (("Vector<uint8_t> tag \\{ cipherText\\.data\\(\\) \\+ cipherTextLen, tagLength \\};")
                 "Vector<uint8_t> tag(std::span<const uint8_t> { cipherText.data() + cipherTextLen, tagLength });"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoAlgorithmEd25519.cpp"
                (("return Vector<uint8_t>\\(newSignature, 64\\);")
                 "return Vector<uint8_t>(std::span<const uint8_t> { newSignature, 64 });"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoAlgorithmECDSAOpenSSL.cpp"
                (("EC_KEY\\* ecKey = EVP_PKEY_get0_EC_KEY\\(key\\.platformKey\\(\\)\\);")
                 "EC_KEY* ecKey = const_cast<EC_KEY*>(EVP_PKEY_get0_EC_KEY(key.platformKey()));"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoKeyOKP.cpp"
                (("Vector<uint8_t>\\(data\\.data\\(\\), 32\\)")
                 "Vector<uint8_t>(std::span<const uint8_t> { data.data(), 32 })"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoKeyOKPOpenSSL.cpp"
                (("Vector<uint8_t>\\(private_key, isEd25519 \\? ED25519_PRIVATE_KEY_LEN : X25519_PRIVATE_KEY_LEN\\)")
                 "Vector<uint8_t>(std::span<const uint8_t>(private_key, static_cast<size_t>(isEd25519 ? ED25519_PRIVATE_KEY_LEN : X25519_PRIVATE_KEY_LEN)))")
                (("Vector<uint8_t>\\(exportKey\\.data\\(\\), exportKey\\.size\\(\\)\\)")
                 "Vector<uint8_t>(std::span<const uint8_t> { exportKey.data(), exportKey.size() })")
                (("result\\.append\\(platformKey\\(\\)\\.data\\(\\), platformKey\\(\\)\\.size\\(\\)\\);")
                 "result.append(std::span<const uint8_t> { platformKey().data(), platformKey().size() });")
                (("result\\.append\\(exportKey\\(\\)\\.data\\(\\), exportKey\\(\\)\\.size\\(\\)\\);")
                 "result.append(std::span<const uint8_t> { exportKey().data(), exportKey().size() });")
                (("KeyMaterial\\(m_data\\.data\\(\\), m_data\\.size\\(\\)\\)")
                 "KeyMaterial(std::span<const uint8_t> { m_data.data(), m_data.size() })"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoKeyECOpenSSL.cpp"
                (("auto ecKey = EVP_PKEY_get0_EC_KEY\\(pkey\\.get\\(\\)\\);")
                 "const EC_KEY* ecKey = EVP_PKEY_get0_EC_KEY(pkey.get());")
                (("EC_KEY_set_asn1_flag\\(ecKey, OPENSSL_EC_NAMED_CURVE\\);")
                 "EC_KEY_set_asn1_flag(const_cast<EC_KEY*>(ecKey), OPENSSL_EC_NAMED_CURVE);")
                (("EC_KEY\\* key = EVP_PKEY_get0_EC_KEY\\(platformKey\\(\\)\\);")
                 "const EC_KEY* key = EVP_PKEY_get0_EC_KEY(platformKey());"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoKeyRSAOpenSSL.cpp"
                (("RSA\\* rsa = EVP_PKEY_get0_RSA\\(m_platformKey\\.get\\(\\)\\);")
                 "RSA* rsa = const_cast<RSA*>(EVP_PKEY_get0_RSA(m_platformKey.get()));")
                (("RSA\\* rsa = EVP_PKEY_get0_RSA\\(platformKey\\(\\)\\);")
                 "RSA* rsa = const_cast<RSA*>(EVP_PKEY_get0_RSA(platformKey()));"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoAlgorithmRsaKeyGenParams.h"
                (("m_publicExponentVector\\.append\\(publicExponent->data\\(\\), publicExponent->byteLength\\(\\)\\);")
                 "m_publicExponentVector.append(std::span<const uint8_t> { publicExponent->data(), publicExponent->byteLength() });"))
              (substitute* "src/bun.js/bindings/webcrypto/CryptoAlgorithmRsaOaepParams.h"
                (("m_labelVector\\.append\\(labelBuffer\\.data\\(\\), labelBuffer\\.length\\(\\)\\);")
                 "m_labelVector.append(std::span<const uint8_t> { labelBuffer.data(), labelBuffer.length() });"))
              (substitute* "src/bun.js/bindings/webcrypto/SubtleCrypto.cpp"
                (("bytes\\.append\\(jwkUTF8String\\.data\\(\\), jwkUTF8String\\.length\\(\\)\\);")
                 "bytes.append(std::span<const uint8_t> { reinterpret_cast<const uint8_t*>(jwkUTF8String.data()), jwkUTF8String.length() });")
                (("return KeyData \\{ Vector \\{ static_cast<const uint8_t\\*>\\(bufferSource->data\\(\\)\\), bufferSource->byteLength\\(\\) \\} \\};")
                 "return KeyData { Vector<uint8_t>(std::span<const uint8_t> { static_cast<const uint8_t*>(bufferSource->data()), bufferSource->byteLength() }) };")
                (("return \\{ data\\.data\\(\\), data\\.length\\(\\) \\};")
                 "return Vector<uint8_t>(std::span<const uint8_t> { data.data(), data.length() });")
                (("WorkQueue::create\\(\"com\\.apple\\.WebKit\\.CryptoQueue\"\\)")
                 "WorkQueue::create(WTF::ASCIILiteral::fromLiteralUnsafe(\"com.apple.WebKit.CryptoQueue\"))")
                (("String jwkString\\(bytes\\.data\\(\\), bytes\\.size\\(\\)\\);")
                 "String jwkString = String::fromUTF8({ reinterpret_cast<const char*>(bytes.data()), bytes.size() });"))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((esbuild (search-input-file inputs "/bin/esbuild")))
                (setenv "HOME" (getcwd))
                (setenv "BUN_DEBUG_QUIET_LOGS" "1")

                ;; Generate lexer identifier cache blobs from source.
                (invoke "zig" "run" "src/js_lexer/identifier_data.zig")

                ;; The release tarball lacks prebuilt node fallback outputs.
                ;; Rehydrate them from source modules for bootstrap.
                (mkdir-p "src/node-fallbacks/out")
                (for-each
                 (lambda (name)
                   (copy-file (string-append "src/node-fallbacks/" name ".js")
                              (string-append "src/node-fallbacks/out/" name ".js")))
                 '("assert"
                   "buffer"
                   "console"
                   "constants"
                   "crypto"
                   "domain"
                   "events"
                   "http"
                   "https"
                   "net"
                   "os"
                   "path"
                   "process"
                   "punycode"
                   "querystring"
                   "stream"
                   "string_decoder"
                   "sys"
                   "timers"
                   "tty"
                   "url"
                   "util"
                   "zlib"))

                ;; Build bun-error assets without fetching npm dependencies.
                ;; We externalize React packages and bundle local sources.
                (mkdir-p "packages/bun-error/dist")
                (invoke esbuild
                        "packages/bun-error/index.tsx"
                        "--bundle"
                        "--format=esm"
                        "--platform=browser"
                        "--external:react"
                        "--external:react-dom"
                        "--outfile=packages/bun-error/dist/index.js")
                (copy-file "packages/bun-error/bun-error.css"
                           "packages/bun-error/dist/bun-error.css")

                ;; Bun's release tarball does not include the generated
                ;; runtime blobs (`src/*.out.js`).  Build the node and bun
                ;; variants as Bun's `runtime_js' target does: both bundle
                ;; the same entry point, which pulls in no external
                ;; dependencies, and differ only in the appended footer.
                (invoke esbuild
                        "--target=esnext"
                        "--bundle" "src/runtime/index-without-hmr.ts"
                        "--format=iife"
                        "--platform=node"
                        "--global-name=BUN_RUNTIME"
                        "--minify"
                        "--external:/bun:*"
                        "--outfile=src/runtime.node.pre.out.js")
                (for-each
                 (lambda (footer output)
                   (call-with-output-file output
                     (lambda (out)
                       (for-each
                        (lambda (part)
                          (call-with-input-file part
                            (lambda (in)
                              (dump-port in out))
                            #:binary #t))
                        (list "src/runtime.node.pre.out.js" footer)))
                     #:binary #t))
                 '("src/runtime.footer.node.js"
                   "src/runtime.footer.bun.js")
                 '("src/runtime.node.out.js"
                   "src/runtime.bun.out.js"))

                ;; The remaining blobs reach the `peechy' runtime library
                ;; through src/fallback.ts and src/runtime/hmr.ts, which is
                ;; not vendored in the tarball.  Keep placeholders so Zig can
                ;; embed them during bootstrap.
                (for-each
                 (lambda (file)
                   (call-with-output-file (string-append "src/" file)
                     (lambda (port)
                       (display "(()=>{})();\n" port))))
                 '("runtime.out.js"
                   "runtime.out.refresh.js"
                   "fallback.out.js"))

                ;; bun-usockets in Bun 1.0.0 expects older uSockets/BoringSSL
                ;; APIs.  Adjust for OpenSSL headers and newer symbol names.
                (substitute* "packages/bun-usockets/src/context.c"
                  (("#include <string.h>")
                   (string-append "#include <string.h>\n\n"
                                  "int us_internal_raw_root_certs"
                                  "(struct us_cert_string_t **out);\n"))
                  (("us_internal_on_ssl_handshake\\(\\(struct us_internal_ssl_socket_context_t \\*\\) context, on_handshake, custom_data\\);")
                   (string-append
                    "us_internal_on_ssl_handshake"
                    "((struct us_internal_ssl_socket_context_t *) context,\n"
                    "            (void (*)(struct us_internal_ssl_socket_t *, "
                    "int, struct us_bun_verify_error_t, void *)) on_handshake,\n"
                    "            custom_data);")))
                (substitute* "packages/bun-usockets/src/socket.c"
                  (("us_internal_socket_context_unlink\\(")
                   "us_internal_socket_context_unlink_socket(")
                  (("us_internal_socket_context_link\\(")
                   "us_internal_socket_context_link_socket("))
                (substitute* "packages/bun-usockets/src/crypto/openssl.c"
                  (("#include <stdatomic.h>")
                   (string-append
                    "#include <stdatomic.h>\n\n"
                    "#ifndef OPENSSL_PUT_ERROR\n"
                    "#define OPENSSL_PUT_ERROR(library, reason) \\\n"
                    "    ERR_put_error(ERR_LIB_##library, 0, reason, __FILE__,"
                    " __LINE__)\n"
                    "#endif"))
                  (("static const root_certs_size = sizeof\\(root_certs\\) / sizeof\\(root_certs\\[0\\]\\);")
                   "static const size_t root_certs_size = sizeof(root_certs) / sizeof(root_certs[0]);"))

                ;; `release-only` does not model all dependencies correctly for
                ;; this tarball, and the release tarball flattens
                ;; picohttpparser, so lay it out where the build expects it.
                ;; libmimalloc.o comes from the `mimalloc' target below,
                ;; built from the submodule commit Bun pins.
                (mkdir-p "src/deps/picohttpparser")
                (when (file-exists? "src/deps/picohttpparser/picohttpparser.c")
                  (delete-file "src/deps/picohttpparser/picohttpparser.c"))
                (copy-file "src/deps/picohttpparser.c"
                           "src/deps/picohttpparser/picohttpparser.c")

                ;; The release tarball omits several vendored dep trees that
                ;; Bun normally builds into local archives.  Provide a mix of
                ;; real shared/static libs from inputs and a small shim archive
                ;; for symbols Bun expects from omitted deps.
                (call-with-output-file "src/deps/guix-link-shim.c"
                  (lambda (port)
                    (display
"#include <stddef.h>\n#include <stdint.h>\n#include <stdlib.h>\n#include <string.h>\n\n#include <openssl/evp.h>\n\nvoid bun_guix_link_shim(void) {}\n\ntypedef struct {\n    int eof;\n    int bytes;\n    int flags;\n    unsigned char carry;\n} guix_base64_state_t;\n\nunsigned char *SHA512_256(const unsigned char *data, size_t len, unsigned char *md)\n{\n    EVP_MD_CTX *ctx = NULL;\n    unsigned int out_len = 0;\n\n    if (!md)\n        return NULL;\n\n    ctx = EVP_MD_CTX_new();\n    if (!ctx)\n        return NULL;\n\n    if (EVP_DigestInit_ex(ctx, EVP_sha512_256(), NULL) != 1\n        || EVP_DigestUpdate(ctx, data, len) != 1\n        || EVP_DigestFinal_ex(ctx, md, &out_len) != 1\n        || out_len != 32) {\n        EVP_MD_CTX_free(ctx);\n        return NULL;\n    }\n\n    EVP_MD_CTX_free(ctx);\n    return md;\n}\n\nvoid base64_encode(const uint8_t *src, size_t srclen, uint8_t *out, size_t *outlen, int flags)\n{\n    int written;\n    (void)flags;\n\n    if (!outlen)\n        return;\n\n    written = EVP_EncodeBlock(out, src, (int)srclen);\n    *outlen = written > 0 ? (size_t)written : 0;\n}\n\nstatic size_t guix_count_trailing_padding(const uint8_t *src, size_t srclen)\n{\n    size_t pad = 0;\n    while (pad < srclen && src[srclen - 1 - pad] == '=')\n        ++pad;\n    return pad;\n}\n\nint base64_decode(const uint8_t *src, size_t srclen, uint8_t *out, size_t *outlen, int flags)\n{\n    uint8_t *tmp = NULL;\n    const uint8_t *input = src;\n    size_t input_len = srclen;\n    int written;\n    size_t pad;\n    (void)flags;\n\n    if (!outlen)\n        return 0;\n\n    if (input_len % 4 != 0) {\n        size_t padded_len = ((input_len + 3) / 4) * 4;\n        tmp = (uint8_t *)malloc(padded_len);\n        if (!tmp)\n            return 0;\n        memcpy(tmp, src, input_len);\n        memset(tmp + input_len, '=', padded_len - input_len);\n        input = tmp;\n        input_len = padded_len;\n    }\n\n    written = EVP_DecodeBlock(out, input, (int)input_len);\n    if (written < 0) {\n        free(tmp);\n        *outlen = 0;\n        return 0;\n    }\n\n    pad = guix_count_trailing_padding(input, input_len);\n    if ((size_t)written >= pad)\n        written -= (int)pad;\n\n    *outlen = (size_t)written;\n    free(tmp);\n    return 1;\n}\n\nvoid base64_stream_encode_init(guix_base64_state_t *state, int flags)\n{\n    if (state)\n        memset(state, 0, sizeof(*state));\n    (void)flags;\n}\n\nvoid base64_stream_encode(guix_base64_state_t *state, const uint8_t *src, size_t srclen, uint8_t *out, size_t *outlen)\n{\n    (void)state;\n    base64_encode(src, srclen, out, outlen, 0);\n}\n\nvoid base64_stream_encode_final(guix_base64_state_t *state, uint8_t *out, size_t *outlen)\n{\n    (void)state;\n    (void)out;\n    if (outlen)\n        *outlen = 0;\n}\n\nvoid base64_stream_decode_init(guix_base64_state_t *state, int flags)\n{\n    if (state)\n        memset(state, 0, sizeof(*state));\n    (void)flags;\n}\n\nint base64_stream_decode(guix_base64_state_t *state, const uint8_t *src, size_t srclen, uint8_t *out, size_t *outlen)\n{\n    (void)state;\n    return base64_decode(src, srclen, out, outlen, 0);\n}\n"
                             port)))
                (invoke "clang"
                        "-I" (string-append (assoc-ref inputs "openssl") "/include")
                        "-c"
                        "src/deps/guix-link-shim.c"
                        "-o" "src/deps/guix-link-shim.o")
                (call-with-output-file "src/deps/guix-link-compat.c"
                  (lambda (port)
                    (display
"#include <stddef.h>\n\
#include <stdint.h>\n\
#include <stdbool.h>\n\
\n\
#include <openssl/evp.h>\n\
#include <openssl/ssl.h>\n\
#include <openssl/x509.h>\n\
#include <openssl/bio.h>\n\
#include <openssl/buffer.h>\n\
#include <openssl/crypto.h>\n\
\n\
void bun_guix_link_compat(void) {}\n\
\n\
typedef struct {\n\
    const uint8_t *ptr;\n\
    size_t len;\n\
} guix_lol_html_string_t;\n\
\n\
typedef void JSStringRef;\n\
\n\
#define GUIX_WEAK __attribute__((weak))\n\
#define GUIX_EMPTY_STR ((guix_lol_html_string_t){ NULL, 0 })\n\
\n\
GUIX_WEAK unsigned char JSStringEncoding(JSStringRef *string)\n\
{\n\
    return string ? 16 : 0;\n\
}\n\
\n\
GUIX_WEAK const uint8_t *JSStringGetCharacters8Ptr(JSStringRef *string)\n\
{\n\
    (void)string;\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK int lol_html_rewriter_write()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_rewriter_end()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_rewriter_free()\n\
{\n\
}\n\
\n\
GUIX_WEAK void *lol_html_rewriter_builder_new()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK int lol_html_rewriter_builder_add_element_content_handlers()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_rewriter_builder_free()\n\
{\n\
}\n\
\n\
GUIX_WEAK void *lol_html_rewriter_build()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK int lol_html_rewriter_builder_add_document_content_handlers()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void *lol_html_selector_parse()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void lol_html_selector_free()\n\
{\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_text_chunk_content_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK bool lol_html_text_chunk_is_last_in_text_node()\n\
{\n\
    return false;\n\
}\n\
\n\
GUIX_WEAK int lol_html_text_chunk_before()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_text_chunk_after()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_text_chunk_replace()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_text_chunk_remove()\n\
{\n\
}\n\
\n\
GUIX_WEAK bool lol_html_text_chunk_is_removed()\n\
{\n\
    return false;\n\
}\n\
\n\
GUIX_WEAK void lol_html_text_chunk_user_data_set()\n\
{\n\
}\n\
\n\
GUIX_WEAK void *lol_html_text_chunk_user_data_get()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_element_get_attribute()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_has_attribute()\n\
{\n\
    return 0;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_set_attribute()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_remove_attribute()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_before()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_prepend()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_append()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_after()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_set_inner_content()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_replace()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_element_remove()\n\
{\n\
}\n\
\n\
GUIX_WEAK void lol_html_element_remove_and_keep_content()\n\
{\n\
}\n\
\n\
GUIX_WEAK bool lol_html_element_is_removed()\n\
{\n\
    return false;\n\
}\n\
\n\
GUIX_WEAK bool lol_html_element_is_self_closing()\n\
{\n\
    return false;\n\
}\n\
\n\
GUIX_WEAK bool lol_html_element_can_have_content()\n\
{\n\
    return true;\n\
}\n\
\n\
GUIX_WEAK void lol_html_element_user_data_set()\n\
{\n\
}\n\
\n\
GUIX_WEAK void *lol_html_element_user_data_get()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_add_end_tag_handler()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_element_clear_end_tag_handlers()\n\
{\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_element_tag_name_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK int lol_html_element_tag_name_set()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK const uint8_t *lol_html_element_namespace_uri_get()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void *lol_html_attributes_iterator_get()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void lol_html_str_free()\n\
{\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_take_last_error()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK int lol_html_end_tag_before()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_end_tag_after()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_end_tag_remove()\n\
{\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_end_tag_name_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK int lol_html_end_tag_name_set()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_attribute_name_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_attribute_value_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK void lol_html_attributes_iterator_free()\n\
{\n\
}\n\
\n\
GUIX_WEAK const void *lol_html_attributes_iterator_next()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_comment_text_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK int lol_html_comment_text_set()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_comment_before()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_comment_after()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int lol_html_comment_replace()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void lol_html_comment_remove()\n\
{\n\
}\n\
\n\
GUIX_WEAK bool lol_html_comment_is_removed()\n\
{\n\
    return false;\n\
}\n\
\n\
GUIX_WEAK void lol_html_comment_user_data_set()\n\
{\n\
}\n\
\n\
GUIX_WEAK void *lol_html_comment_user_data_get()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK int lol_html_doc_end_append()\n\
{\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_doctype_name_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_doctype_public_id_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK guix_lol_html_string_t lol_html_doctype_system_id_get()\n\
{\n\
    return GUIX_EMPTY_STR;\n\
}\n\
\n\
GUIX_WEAK void lol_html_doctype_user_data_set()\n\
{\n\
}\n\
\n\
GUIX_WEAK void *lol_html_doctype_user_data_get()\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void *CRYPTO_BUFFER_POOL_new(void)\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void CRYPTO_BUFFER_POOL_free(void *pool)\n\
{\n\
    (void)pool;\n\
}\n\
\n\
GUIX_WEAK void SSL_CTX_set0_buffer_pool(void *ctx, void *pool)\n\
{\n\
    (void)ctx;\n\
    (void)pool;\n\
}\n\
\n\
GUIX_WEAK int CRYPTO_library_init(void)\n\
{\n\
    return 1;\n\
}\n\
\n\
#ifdef SSL_library_init\n\
#undef SSL_library_init\n\
#endif\n\
\n\
GUIX_WEAK int SSL_library_init(void)\n\
{\n\
    return 1;\n\
}\n\
\n\
#ifdef SSL_load_error_strings\n\
#undef SSL_load_error_strings\n\
#endif\n\
\n\
GUIX_WEAK void SSL_load_error_strings(void)\n\
{\n\
}\n\
\n\
#ifdef OpenSSL_add_all_algorithms\n\
#undef OpenSSL_add_all_algorithms\n\
#endif\n\
\n\
GUIX_WEAK void OpenSSL_add_all_algorithms(void)\n\
{\n\
}\n\
\n\
#ifdef EVP_MD_CTX_size\n\
#undef EVP_MD_CTX_size\n\
#endif\n\
\n\
GUIX_WEAK int EVP_MD_CTX_size(const EVP_MD_CTX *ctx)\n\
{\n\
    return EVP_MD_CTX_get_size((EVP_MD_CTX *)ctx);\n\
}\n\
\n\
#ifdef EVP_MD_CTX_cleanup\n\
#undef EVP_MD_CTX_cleanup\n\
#endif\n\
\n\
GUIX_WEAK int EVP_MD_CTX_cleanup(EVP_MD_CTX *ctx)\n\
{\n\
    return EVP_MD_CTX_reset(ctx);\n\
}\n\
\n\
GUIX_WEAK const EVP_MD *EVP_blake2b256(void)\n\
{\n\
    return EVP_blake2s256();\n\
}\n\
\n\
#ifdef EVP_MD_CTX_init\n\
#undef EVP_MD_CTX_init\n\
#endif\n\
\n\
GUIX_WEAK void EVP_MD_CTX_init(EVP_MD_CTX *ctx)\n\
{\n\
    (void)EVP_MD_CTX_reset(ctx);\n\
}\n\
\n\
#ifdef BIO_reset\n\
#undef BIO_reset\n\
#endif\n\
\n\
GUIX_WEAK int BIO_reset(BIO *bio)\n\
{\n\
    return BIO_ctrl(bio, BIO_CTRL_RESET, 0, NULL);\n\
}\n\
\n\
#ifdef sk_num\n\
#undef sk_num\n\
#endif\n\
\n\
GUIX_WEAK int sk_num(const OPENSSL_STACK *stack)\n\
{\n\
    return OPENSSL_sk_num(stack);\n\
}\n\
\n\
#ifdef sk_value\n\
#undef sk_value\n\
#endif\n\
\n\
GUIX_WEAK void *sk_value(const OPENSSL_STACK *stack, int idx)\n\
{\n\
    return OPENSSL_sk_value(stack, idx);\n\
}\n\
\n\
#ifdef sk_pop_free_ex\n\
#undef sk_pop_free_ex\n\
#endif\n\
\n\
GUIX_WEAK void sk_pop_free_ex(OPENSSL_STACK *stack, void (*free_fn)(void *))\n\
{\n\
    OPENSSL_sk_pop_free(stack, free_fn);\n\
}\n\
\n\
#ifdef BIO_get_mem_ptr\n\
#undef BIO_get_mem_ptr\n\
#endif\n\
\n\
GUIX_WEAK int BIO_get_mem_ptr(BIO *bio, BUF_MEM **out)\n\
{\n\
    return BIO_ctrl(bio, BIO_C_GET_BUF_MEM_PTR, 0, out);\n\
}\n\
\n\
#ifdef EVP_PKEY_id\n\
#undef EVP_PKEY_id\n\
#endif\n\
\n\
GUIX_WEAK int EVP_PKEY_id(const EVP_PKEY *pkey)\n\
{\n\
    return EVP_PKEY_get_base_id((EVP_PKEY *)pkey);\n\
}\n\
\n\
#ifdef EVP_PKEY_bits\n\
#undef EVP_PKEY_bits\n\
#endif\n\
\n\
GUIX_WEAK int EVP_PKEY_bits(const EVP_PKEY *pkey)\n\
{\n\
    return EVP_PKEY_get_bits((EVP_PKEY *)pkey);\n\
}\n\
\n\
#ifdef SSL_get_peer_certificate\n\
#undef SSL_get_peer_certificate\n\
#endif\n\
\n\
GUIX_WEAK X509 *SSL_get_peer_certificate(const SSL *ssl)\n\
{\n\
    return SSL_get1_peer_certificate((SSL *)ssl);\n\
}\n\
\n\
#ifdef SSL_set_max_send_fragment\n\
#undef SSL_set_max_send_fragment\n\
#endif\n\
\n\
GUIX_WEAK int SSL_set_max_send_fragment(SSL *ssl, long maxfrag)\n\
{\n\
    (void)ssl;\n\
    (void)maxfrag;\n\
    return 1;\n\
}\n\
\n\
#ifdef SSL_set_tlsext_host_name\n\
#undef SSL_set_tlsext_host_name\n\
#endif\n\
\n\
GUIX_WEAK int SSL_set_tlsext_host_name(SSL *ssl, const char *name)\n\
{\n\
    return (int)SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME,\n\
                         TLSEXT_NAMETYPE_host_name, (void *)name);\n\
}\n\
\n\
#ifdef OPENSSL_free\n\
#undef OPENSSL_free\n\
#endif\n\
\n\
GUIX_WEAK void OPENSSL_free(void *ptr)\n\
{\n\
    CRYPTO_free(ptr, __FILE__, __LINE__);\n\
}\n\
\n\
GUIX_WEAK void *tcc_new(void)\n\
{\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void tcc_delete(void *state)\n\
{\n\
    (void)state;\n\
}\n\
\n\
GUIX_WEAK int tcc_set_options(void *state, const char *options)\n\
{\n\
    (void)state;\n\
    (void)options;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void tcc_set_error_func(void *state, void *opaque,\n\
                                  void (*cb)(void *, const char *))\n\
{\n\
    (void)state;\n\
    (void)opaque;\n\
    (void)cb;\n\
}\n\
\n\
GUIX_WEAK int tcc_set_output_type(void *state, int type)\n\
{\n\
    (void)state;\n\
    (void)type;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_define_symbol(void *state, const char *name,\n\
                                const char *value)\n\
{\n\
    (void)state;\n\
    (void)name;\n\
    (void)value;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_compile_string(void *state, const char *code)\n\
{\n\
    (void)state;\n\
    (void)code;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_add_symbol(void *state, const char *name,\n\
                             const void *value)\n\
{\n\
    (void)state;\n\
    (void)name;\n\
    (void)value;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void tcc_set_lib_path(void *state, const char *path)\n\
{\n\
    (void)state;\n\
    (void)path;\n\
}\n\
\n\
GUIX_WEAK void *tcc_get_error_func(void *state)\n\
{\n\
    (void)state;\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void *tcc_get_error_opaque(void *state)\n\
{\n\
    (void)state;\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK int tcc_add_include_path(void *state, const char *path)\n\
{\n\
    (void)state;\n\
    (void)path;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_add_sysinclude_path(void *state, const char *path)\n\
{\n\
    (void)state;\n\
    (void)path;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void tcc_undefine_symbol(void *state, const char *name)\n\
{\n\
    (void)state;\n\
    (void)name;\n\
}\n\
\n\
GUIX_WEAK int tcc_add_file(void *state, const char *filename)\n\
{\n\
    (void)state;\n\
    (void)filename;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_add_library_path(void *state, const char *path)\n\
{\n\
    (void)state;\n\
    (void)path;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_add_library(void *state, const char *libraryname)\n\
{\n\
    (void)state;\n\
    (void)libraryname;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_output_file(void *state, const char *filename)\n\
{\n\
    (void)state;\n\
    (void)filename;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_run(void *state, int argc, char **argv)\n\
{\n\
    (void)state;\n\
    (void)argc;\n\
    (void)argv;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK int tcc_relocate(void *state, void *ptr)\n\
{\n\
    (void)state;\n\
    (void)ptr;\n\
    return -1;\n\
}\n\
\n\
GUIX_WEAK void *tcc_get_symbol(void *state, const char *name)\n\
{\n\
    (void)state;\n\
    (void)name;\n\
    return NULL;\n\
}\n\
\n\
GUIX_WEAK void tcc_list_symbols(void *state, void *ctx, void *symbol_cb)\n\
{\n\
    (void)state;\n\
    (void)ctx;\n\
    (void)symbol_cb;\n\
}\n\
\n\
#ifdef SSL_set_mode\n\
#undef SSL_set_mode\n\
#endif\n\
\n\
GUIX_WEAK long SSL_set_mode(SSL *ssl, long mode)\n\
{\n\
    return SSL_ctrl(ssl, SSL_CTRL_MODE, mode, NULL);\n\
}\n\
\n\
#ifdef SSL_clear_mode\n\
#undef SSL_clear_mode\n\
#endif\n\
\n\
GUIX_WEAK long SSL_clear_mode(SSL *ssl, long mode)\n\
{\n\
    return SSL_ctrl(ssl, SSL_CTRL_CLEAR_MODE, mode, NULL);\n\
}\n\
\n\
GUIX_WEAK int SSL_enable_signed_cert_timestamps(SSL *ssl)\n\
{\n\
    (void)ssl;\n\
    return 1;\n\
}\n\
\n\
GUIX_WEAK int SSL_enable_ocsp_stapling(SSL *ssl)\n\
{\n\
    (void)ssl;\n\
    return 1;\n\
}\n\
\n\
GUIX_WEAK int SSL_set_enable_ech_grease(SSL *ssl, int enabled)\n\
{\n\
    (void)ssl;\n\
    (void)enabled;\n\
    return 1;\n\
}\n\
\n\
#ifdef BIO_get_mem_data\n\
#undef BIO_get_mem_data\n\
#endif\n\
\n\
GUIX_WEAK long BIO_get_mem_data(BIO *bio, char **out)\n\
{\n\
    return BIO_ctrl(bio, BIO_CTRL_INFO, 0, out);\n\
}\n\
\n\
#ifdef sk_free\n\
#undef sk_free\n\
#endif\n\
\n\
GUIX_WEAK void sk_free(OPENSSL_STACK *stack)\n\
{\n\
    OPENSSL_sk_free(stack);\n\
}\n\
\n\
#ifdef BIO_set_mem_eof_return\n\
#undef BIO_set_mem_eof_return\n\
#endif\n\
\n\
GUIX_WEAK int BIO_set_mem_eof_return(BIO *bio, int v)\n\
{\n\
    return (int)BIO_ctrl(bio, BIO_C_SET_BUF_MEM_EOF_RETURN, v, NULL);\n\
}\n\
\n\
GUIX_WEAK const SSL_METHOD *TLS_with_buffers_method(void)\n\
{\n\
    return TLS_method();\n\
}\n\
\n\
GUIX_WEAK void SSL_CTX_set_custom_verify(SSL_CTX *ctx, int mode, void *cb)\n\
{\n\
    (void)cb;\n\
    SSL_CTX_set_verify(ctx, mode, NULL);\n\
}\n\
"
                             port)))
                (invoke "clang"
                        "-c"
                        "src/deps/guix-link-compat.c"
                        "-o" "src/deps/guix-link-compat.o")

                (let ((install-lib-from-input
                       (lambda (input-name lib-base)
                         (let* ((libdir (string-append (assoc-ref inputs input-name)
                                                       "/lib"))
                                (shared-name (string-append lib-base ".so"))
                                (shared (string-append libdir "/" shared-name))
                                (versioned (find-files libdir
                                                       (string-append "^"
                                                                      lib-base
                                                                      "\\.so\\..*$")))
                                (static-name (string-append lib-base ".a"))
                                (static (string-append libdir "/" static-name)))
                           (cond
                            ((file-exists? shared)
                             (copy-file shared (string-append "src/deps/" shared-name))
                             #t)
                            ((pair? versioned)
                             (copy-file (car versioned)
                                        (string-append "src/deps/" shared-name))
                             #t)
                            ((file-exists? static)
                             (copy-file static (string-append "src/deps/" static-name))
                             #t)
                            (else #f))))))
                  ;; Provide real upstream libraries where possible.
                  (unless (install-lib-from-input "libarchive" "libarchive")
                    (invoke "ar" "rcs" "src/deps/libarchive.a"
                            "src/deps/guix-link-shim.o"
                            "src/deps/guix-link-compat.o"))
                  (unless (install-lib-from-input "zstd" "libzstd")
                    (invoke "ar" "rcs" "src/deps/libzstd.a"
                            "src/deps/guix-link-shim.o"
                            "src/deps/guix-link-compat.o"))
                  (unless (install-lib-from-input "c-ares" "libcares")
                    (invoke "ar" "rcs" "src/deps/libcares.a"
                            "src/deps/guix-link-shim.o"
                            "src/deps/guix-link-compat.o"))

                  ;; Provide local shims for missing vendored libraries/symbols.
                  (for-each
                   (lambda (archive)
                     (let ((path (string-append "src/deps/" archive)))
                       (unless (or (file-exists? (string-append path ".a"))
                                   (file-exists? (string-append path ".so")))
                       (invoke "ar" "rcs"
                                (string-append path ".a")
                                "src/deps/guix-link-shim.o"
                                "src/deps/guix-link-compat.o"))))
                   '("libdecrepit"
                     "liblolhtml"
                     "libbase64"
                     "libtcc")))

                (invoke "make" "mimalloc")
                (invoke "make" "sqlite")
                (invoke "make" "picohttp")
                (invoke "make" "uws")
                (let ((cpus (or (getenv "NIX_BUILD_CORES") "1")))
                  ;; The Makefile defaults CPU_TARGET to "native", which makes
                  ;; the build depend on the builder's CPU and lets simdutf
                  ;; take its AVX-512 path, where it crashes.  Use the target
                  ;; upstream's own x86_64 release builds use.
                  (invoke "make" "release-only"
                          (string-append "CPUS=" cpus)
                          "CPU_TARGET=haswell")))))
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (bun (string-append bin "/bun"))
                     (runpath
                      (string-append
                       (assoc-ref inputs "libarchive") "/lib:"
                       (assoc-ref inputs "zlib") "/lib:"
                       (assoc-ref inputs "openssl") "/lib:"
                       (assoc-ref inputs "c-ares") "/lib:"
                       (assoc-ref inputs "zstd") "/lib:"
                       ;; JavaScriptCore is built against Guix's shared ICU,
                       ;; so bun loads it at run time.
                       (assoc-ref inputs "icu4c") "/lib:"
                       (assoc-ref inputs "gcc-lib") "/lib"))
                     (interpreter
                      (search-input-file inputs "/lib/ld-linux-x86-64.so.2")))
                (mkdir-p bin)
                (install-file "packages/bun-linux-x64/bun" bin)
                (chmod bun #o755)
                (invoke "patchelf" "--set-interpreter" interpreter bun)
                (invoke "patchelf" "--set-rpath" runpath bun)
                (invoke "patchelf" "--remove-needed"
                        "ld-linux-x86-64.so.2"
                        bun)
                (symlink "bun" (string-append bin "/bunx"))))))))
    (native-inputs
     `(("bun-webkit" ,bun-webkit)
       ("cmake-minimal" ,cmake-minimal)
       ("ninja" ,ninja)
       ("pkg-config" ,pkg-config)
       ("mimalloc-source" ,bun-stage0-mimalloc-source)
       ("openssl" ,openssl)
       ("libarchive" ,libarchive)
       ("zlib" ,zlib)
       ("zstd" ,zstd "lib")
       ("c-ares" ,c-ares)
       ("gcc-lib" ,gcc "lib")
       ("clang" ,clang-16)
       ("lld" ,lld-16)
       ("llvm" ,llvm-16)
       ("zig" ,zig-0.11)
       ("rust" ,rust)
       ("rust:cargo" ,rust "cargo")
       ("go" ,go)
       ("ruby" ,ruby)
       ("python" ,python)
       ("node" ,node)
       ("perl" ,perl)
       ("git" ,git)
       ("patchelf" ,patchelf)
       ("which" ,which)
       ("esbuild" ,esbuild)))
    (inputs
     (list glibc icu4c))
    (supported-systems '("x86_64-linux"))
    (home-page "https://bun.sh")
    (synopsis "Stage0 Bun built from source")
    (description
     "This package bootstraps Bun from source using the older Makefile-based
 build system from Bun 1.0.0.  It is intended as a source-built stage0 for
newer Bun releases.")
    (license license:expat)))

(define-public bun-from-source
  (package
    (name "bun-from-source")
    (version "1.3.8")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/oven-sh/bun/archive/refs/tags/bun-v1.3.8.tar.gz")
       (sha256
        (base32
         "1byw1rbvsizm079isfxp3hz6s5x76hpskdpfn9xkhh73admkj54p"))
       (modules %strip-modules)
       (snippet %strip-compiled-artefacts)))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (guix build bun-build-system)
                  (ice-9 textual-ports)
                  (srfi srfi-13))
      #:imported-modules `(,@%default-gnu-imported-modules
                           (json)
                           (json builder)
                           (json parser)
                           (json record)
                           (guix build bun-build-system))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'prepare-offline-tree
            (lambda* (#:key inputs #:allow-other-keys)
              (invoke "chmod" "-R" "u+w" ".")

              ;; Mark the vendored trees newer than the CMake sources so the
              ;; download rules are considered up to date.
              (when (file-exists? "vendor")
                (invoke "find" "vendor" "-type" "d" "-exec" "touch" "{}" "+")
                (invoke "find" "vendor" "-type" "f" "-exec" "touch" "{}" "+"))
              (for-each
               (lambda (dir)
                 (when (file-exists? dir)
                   (invoke "find"
                           dir
                           "-name" "package.json"
                           "-type" "f"
                           "-exec" "touch" "{}" "+")))
               '("packages/bun-error/node_modules"
                 "src/node-fallbacks/node_modules"))

              ;; Seed Cargo registry/index for offline Rust builds.
              (mkdir-p ".cargo")
              (when (file-exists? "cargo-home")
                (invoke "cp" "-a" "cargo-home/." ".cargo"))

              ;; Avoid root-level `bun install` by providing esbuild directly.
              (mkdir-p "node_modules/.bin")
              (let ((esbuild (search-input-file inputs "/bin/esbuild")))
                (when (file-exists? "node_modules/.bin/esbuild")
                  (delete-file "node_modules/.bin/esbuild"))
                ;; Use a wrapper file (not a symlink) so the output mtime is
                ;; newer than package.json and CMake skips bun install.
                (call-with-output-file "node_modules/.bin/esbuild"
                  (lambda (port)
                    ;; There is no /bin/sh in the build container: a wrapper
                    ;; written with that shebang fails as "required file not
                    ;; found", which reads like a missing esbuild rather than
                    ;; a missing shell.
                    (display (string-append "#!" (which "bash") "\n"
                                            "exec " esbuild " \"$@\"\n")
                             port)))
                (chmod "node_modules/.bin/esbuild" #o755))

              ;; Preseed @lezer modules needed by src/codegen/cppbind.ts.
              ;; This avoids any runtime package install attempts.
              (mkdir-p "node_modules/@lezer")
              (for-each
               (lambda (spec)
                 (let* ((input-name (car spec))
                        (module-name (cdr spec))
                        (archive (assoc-ref inputs input-name))
                        (tmpdir (string-append (getcwd)
                                               "/.lezer-"
                                               module-name
                                               "-tmp"))
                        (dest (string-append "node_modules/@lezer/" module-name))
                        (unpacked (string-append tmpdir "/package")))
                   (when (file-exists? tmpdir)
                     (delete-file-recursively tmpdir))
                   (mkdir-p tmpdir)
                   (invoke "tar" "xf" archive "-C" tmpdir)
                   (when (file-exists? dest)
                     (delete-file-recursively dest))
                   (unless (file-exists? unpacked)
                     (error "failed to unpack lezer module" input-name))
                   (rename-file unpacked dest)
                   (delete-file-recursively tmpdir)
                   (invoke "touch" (string-append dest "/package.json"))))
               '(("lezer-common" . "common")
                 ("lezer-cpp" . "cpp")
                 ("lezer-highlight" . "highlight")
                 ("lezer-lr" . "lr")))

              ;; Preseed peechy from its TypeScript sources for
              ;; src/fallback.ts.  Only the "./bb" entry point is wired up:
              ;; the root module re-exports the schema compilers, which drag
              ;; in change-case and are unused here.
              (let ((dest "node_modules/peechy"))
                (when (file-exists? dest)
                  (delete-file-recursively dest))
                (mkdir-p dest)
                (copy-recursively (string-append (assoc-ref inputs "peechy")
                                                 "/js")
                                  dest)
                (invoke "chmod" "-R" "u+w" dest)
                (call-with-output-file (string-append dest "/package.json")
                  (lambda (port)
                    (display "{\"name\":\"peechy\",\"version\":\"0.4.34\",\
\"type\":\"module\",\"exports\":{\"./bb\":\"./bb.ts\",\
\"./package.json\":\"./package.json\"}}\n"
                             port))))

              ;; If the offline seed is empty, create dependency markers so
              ;; register_bun_install() can be satisfied without network.
              (invoke "python3" "-c"
                      (string-append
                       "import json\n"
                       "from pathlib import Path\n"
                       "for rel in ('packages/bun-error', 'src/node-fallbacks'):\n"
                       "    package = Path(rel) / 'package.json'\n"
                       "    if not package.exists():\n"
                       "        continue\n"
                       "    data = json.loads(package.read_text())\n"
                       "    deps = {}\n"
                       "    deps.update(data.get('dependencies') or {})\n"
                       "    deps.update(data.get('devDependencies') or {})\n"
                       "    for name in sorted(deps):\n"
                       "        marker = Path(rel) / 'node_modules' / name / 'package.json'\n"
                       "        marker.parent.mkdir(parents=True, exist_ok=True)\n"
                       "        if not marker.exists():\n"
                       "            marker.write_text('{}\\n')\n"
                       "        marker.touch()\n"))

              ;; Upstream builds with its own Zig fork, downloaded prebuilt,
              ;; which adds this field to Build.Step.Compile.  Guard it the
              ;; way the surrounding code guards other optional fields, so a
              ;; stock Zig works and the fork keeps its behaviour.
              (substitute* "build.zig"
                (("    obj\\.no_link_obj = opts\\.os != \\.windows and !opts\\.no_llvm;")
                 (string-append
                  "    if (@hasField(std.meta.Child(@TypeOf(obj)), \"no_link_obj\"))\n"
                  "        obj.no_link_obj = opts.os != .windows and !opts.no_llvm;")))

              ;; `vendor/zig` is seeded in offline inputs.
              (unless (file-exists? "vendor/zig/zig")
                (mkdir-p "vendor/zig")
                (symlink (search-input-file inputs "/bin/zig")
                         "vendor/zig/zig"))
              (let* ((zig-lib-dir
                      (or (false-if-exception
                           (search-input-directory inputs "/lib/zig"))
                          (let ((lib (false-if-exception
                                      (search-input-directory inputs "/lib"))))
                            (and lib
                                 (file-exists? (string-append lib "/zig"))
                                 (string-append lib "/zig"))))))
                (when (and zig-lib-dir
                           (not (file-exists? "vendor/zig/lib")))
                  (symlink zig-lib-dir "vendor/zig/lib")))
              ;; Some CMake scripts expect a stable zig.exe path on Unix too.
              (when (and (file-exists? "vendor/zig/zig")
                         (not (file-exists? "vendor/zig/zig.exe")))
                (symlink "zig" "vendor/zig/zig.exe"))

              ;; Seed the exact Node headers expected by Bun 1.3.8.
              (let ((node-headers (assoc-ref inputs "node-headers")))
                (when (file-exists? "vendor/nodejs/include/node")
                  (delete-file-recursively "vendor/nodejs/include/node"))
                (mkdir-p "vendor/nodejs/include")
                (invoke "tar" "xf" node-headers
                        "--strip-components=2"
                        "-C" "vendor/nodejs/include"
                        "node-v24.3.0/include/node")
                ;; Bun's usockets crypto backend is wired for BoringSSL APIs.
                ;; Drop Node's vendored OpenSSL headers so <openssl/...> resolves
                ;; to vendor/boringssl/include instead.
                (when (file-exists? "vendor/nodejs/include/node/openssl")
                  (delete-file-recursively
                   "vendor/nodejs/include/node/openssl"))
                (call-with-output-file "vendor/nodejs/include/.node-headers-prepared"
                  (lambda (port)
                    (display "seeded-by-guix\n" port)))
                (invoke "touch" "vendor/nodejs/include/.node-headers-prepared"))

              ;; Provide a pre-populated Bun package cache for offline installs.
              ;; Move heavy build artifacts off tmpfs when /var/tmp is writable.
              (let ((external-release
                     (false-if-exception
                      (mkdtemp! "/var/tmp/bun-release.XXXXXX"))))
                (when external-release
                  (mkdir-p "build")
                  (when (file-exists? "build/release")
                    (delete-file-recursively "build/release"))
                  (symlink external-release "build/release")))

              (mkdir-p "build/release/cache")
              (when (file-exists? "cache/bun")
                (invoke "cp" "-a" "cache/bun" "build/release/cache/bun"))

              ;; Use preseeded vendor trees when they contain real content and
              ;; match the expected ref; otherwise fall back to downloads.
              (substitute* "cmake/scripts/GitClone.cmake"
                (("set\\(GIT_DOWNLOAD_URL https://github.com/\\$\\{GIT_REPOSITORY\\}/archive/\\$\\{GIT_REF\\}\\.tar\\.gz\\)")
                 "if(EXISTS ${GIT_PATH}/.ref)\n  file(READ ${GIT_PATH}/.ref GIT_EXISTING_REF)\n  string(STRIP \"${GIT_EXISTING_REF}\" GIT_EXISTING_REF)\n  set(GIT_REF_CANON ${GIT_REF})\n  set(GIT_EXISTING_REF_CANON ${GIT_EXISTING_REF})\n  string(REPLACE \"refs/tags/\" \"\" GIT_REF_CANON ${GIT_REF_CANON})\n  string(REPLACE \"refs/heads/\" \"\" GIT_REF_CANON ${GIT_REF_CANON})\n  string(REPLACE \"refs/tags/\" \"\" GIT_EXISTING_REF_CANON ${GIT_EXISTING_REF_CANON})\n  string(REPLACE \"refs/heads/\" \"\" GIT_EXISTING_REF_CANON ${GIT_EXISTING_REF_CANON})\n  file(GLOB GIT_EXISTING_FILES ${GIT_PATH}/*)\n  list(LENGTH GIT_EXISTING_FILES GIT_EXISTING_COUNT)\n  if(GIT_EXISTING_REF_CANON STREQUAL GIT_REF_CANON AND GIT_EXISTING_COUNT GREATER 1)\n    message(STATUS \"Using pre-populated ${GIT_REPOSITORY} at ${GIT_REF}\")\n    return()\n  endif()\nendif()\n\nset(GIT_DOWNLOAD_URL https://github.com/${GIT_REPOSITORY}/archive/${GIT_REF}.tar.gz)"))
              ;; Zig is provided by Guix inputs; avoid any network fetch in
              ;; DownloadZig.cmake when vendor/zig/zig is already present.
              (substitute* "cmake/scripts/DownloadZig.cmake"
                (("set\\(ZIG_DOWNLOAD_URL https://github.com/oven-sh/zig/releases/download/autobuild-\\$\\{ZIG_COMMIT\\}/\\$\\{ZIG_FILENAME\\}\\)")
                 "if(EXISTS ${ZIG_PATH}/${ZIG_EXE})\n  message(STATUS \"Using preseeded zig executable at ${ZIG_PATH}/${ZIG_EXE}\")\n  return()\nendif()\n\nset(ZIG_DOWNLOAD_URL https://github.com/oven-sh/zig/releases/download/autobuild-${ZIG_COMMIT}/${ZIG_FILENAME})"))

              ;; Bun tarball builds do not have a Git checkout; keep version
              ;; symbols defined instead of dropping them as \"unknown\".
              (substitute* "cmake/tools/GenerateDependencyVersions.cmake"
                (("set\\(BUN_GIT_SHA \"unknown\"\\)")
                 "if(DEFINED VERSION AND NOT \"${VERSION}\" STREQUAL \"\")\n    set(BUN_GIT_SHA \"${VERSION}\")\n  else()\n    set(BUN_GIT_SHA \"tarball\")\n  endif()"))

              ;; The release tarball already carries generated source manifests;
              ;; skip Bun's expensive single-threaded glob pass unless asked.
              (substitute* "scripts/build.mjs"
                (("if \\(globalThis\\.Bun\\) \\{\n  await import\\(\"\\./glob-sources\\.mjs\"\\);\n\\}")
                 "if (globalThis.Bun && process.env.BUN_FORCE_GLOB_SOURCES === \"1\") {\n  await import(\"./glob-sources.mjs\");\n}"))

              ;; bun-stage0 can hang evaluating bindgenv2 source modules to
              ;; compute list-outputs.  Prefer the precomputed output list.
              (substitute* "src/codegen/bindgenv2/script.ts"
                (("import \\* as helpers from \"\\.\\./helpers\";")
                 "import * as helpers from \"../helpers\";\nimport { existsSync, readFileSync } from \"node:fs\";")
                (("function listOutputs\\(\\): void \\{")
                 "function listOutputs(): void {\n  console.error(\"[guix-debug] bindgenv2 list-outputs patched path active\");\n  const precomputedPath = `${codegenPath}/bindgenv2-outputs.txt`;\n  if (existsSync(precomputedPath)) {\n    const precomputed = readFileSync(precomputedPath, \"utf8\").trim();\n    if (precomputed.length > 0) {\n      process.stdout.write(precomputed);\n      return;\n    }\n  }"))
              ;; Apply the same bindgenv2 list-outputs patch robustly with a
              ;; direct text rewrite to avoid regex drift.
              (invoke "python3" "-c"
                      (string-append
                       "from pathlib import Path\n"
                       "p = Path('src/codegen/bindgenv2/script.ts')\n"
                       "t = p.read_text()\n"
                       "start = t.find('function listOutputs(): void {')\n"
                       "end = t.find('\\n\\nfunction generate(): void {')\n"
                       "if start != -1 and end != -1:\n"
                       "    patched = '''function listOutputs(): void {\n"
                       "  const outputs: string[] = [\n"
                       "    `${codegenPath}/bindgen_generated.zig`,\n"
                       "    `${codegenPath}/GeneratedSocketConfigBinaryType.cpp`,\n"
                       "    `${codegenPath}/GeneratedSocketConfigHandlers.cpp`,\n"
                       "    `${codegenPath}/GeneratedSocketConfig.cpp`,\n"
                       "    `${codegenPath}/GeneratedSSLConfig.cpp`,\n"
                       "    `${codegenPath}/GeneratedFakeTimersConfig.cpp`,\n"
                       "    `${codegenPath}/bindgen_generated/socket_config_binary_type.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/socket_config_handlers.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/socket_config_tls.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/socket_config.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/ssl_config_single_file.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/ssl_config_file.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/alpn_protocols.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/ssl_config.zig`,\n"
                       "    `${codegenPath}/bindgen_generated/fake_timers_config.zig`,\n"
                       "  ];\n"
                       "  process.stdout.write(outputs.join(\";\"));\n"
                       "}\n"
                       "'''\n"
                       "    t = t[:start] + patched + t[end + 2:]\n"
                       "p.write_text(t)\n"
                       "assert 'GeneratedSocketConfigBinaryType.cpp' in t\n"
                       "cmake = Path('cmake/targets/BuildBun.cmake')\n"
                       "cm = cmake.read_text()\n"
                       "cm_start = cm.find('execute_process(\\n  COMMAND ${BUN_EXECUTABLE} ${BUN_FLAGS} run ${BUN_BINDGENV2_SCRIPT}')\n"
                       "cm_mark = '\\nforeach(output IN LISTS bindgen_outputs)'\n"
                       "if cm_start != -1:\n"
                       "    cm_end = cm.find(cm_mark, cm_start)\n"
                       "    if cm_end != -1:\n"
                       "        cm_patch = '''set(bindgen_outputs\n"
                       "  ${CODEGEN_PATH}/bindgen_generated.zig\n"
                       "  ${CODEGEN_PATH}/GeneratedSocketConfigBinaryType.cpp\n"
                       "  ${CODEGEN_PATH}/GeneratedSocketConfigHandlers.cpp\n"
                       "  ${CODEGEN_PATH}/GeneratedSocketConfig.cpp\n"
                       "  ${CODEGEN_PATH}/GeneratedSSLConfig.cpp\n"
                       "  ${CODEGEN_PATH}/GeneratedFakeTimersConfig.cpp\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/socket_config_binary_type.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/socket_config_handlers.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/socket_config_tls.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/socket_config.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/ssl_config_single_file.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/ssl_config_file.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/alpn_protocols.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/ssl_config.zig\n"
                       "  ${CODEGEN_PATH}/bindgen_generated/fake_timers_config.zig\n"
                       ")\\n'''\n"
                       "        cm = cm[:cm_start] + cm_patch + cm[cm_end + 1:]\n"
                       "cmake.write_text(cm)\n"
                       "assert 'GeneratedSocketConfigBinaryType.cpp' in cm\n"
                       "for path in ('cmake/Globals.cmake', 'cmake/tools/SetupEsbuild.cmake'):\n"
                       "    p2 = Path(path)\n"
                       "    s = p2.read_text()\n"
                       "    if '--frozen-lockfile' in s:\n"
                       "        s = s.replace('--frozen-lockfile', '')\n"
                       "        p2.write_text(s)\n"
                       "assert '--frozen-lockfile' not in Path('cmake/Globals.cmake').read_text()\n"
                       "assert '--frozen-lockfile' not in Path('cmake/tools/SetupEsbuild.cmake').read_text()\n"))

              ;; bun-stage0 can hang when BuildBun.cmake asks bindgenv2 for
              ;; list-outputs during configure.  Allow precomputed outputs.
              (substitute* "cmake/targets/BuildBun.cmake"
                (("execute_process\\(\n  COMMAND \\$\\{BUN_EXECUTABLE\\} \\$\\{BUN_FLAGS\\} run \\$\\{BUN_BINDGENV2_SCRIPT\\}\n    --command=list-outputs\n    --sources=\\$\\{BUN_BINDGENV2_SOURCES_COMMA_SEPARATED\\}\n    --codegen-path=\\$\\{CODEGEN_PATH\\}\n  OUTPUT_VARIABLE bindgen_outputs\n  COMMAND_ERROR_IS_FATAL ANY\n\\)")
                 "set(BUN_BINDGENV2_OUTPUTS_FILE ${CODEGEN_PATH}/bindgenv2-outputs.txt)\nif(EXISTS ${BUN_BINDGENV2_OUTPUTS_FILE})\n  file(READ ${BUN_BINDGENV2_OUTPUTS_FILE} bindgen_outputs)\n  message(STATUS \"Using precomputed bindgenv2 outputs: ${BUN_BINDGENV2_OUTPUTS_FILE}\")\nelse()\n  execute_process(\n    COMMAND ${BUN_EXECUTABLE} ${BUN_FLAGS} run ${BUN_BINDGENV2_SCRIPT}\n      --command=list-outputs\n      --sources=${BUN_BINDGENV2_SOURCES_COMMA_SEPARATED}\n      --codegen-path=${CODEGEN_PATH}\n    OUTPUT_VARIABLE bindgen_outputs\n    COMMAND_ERROR_IS_FATAL ANY\n  )\nendif()\nstring(STRIP \"${bindgen_outputs}\" bindgen_outputs)"))

              ;; bun-stage0 (1.0.0) updates lockfiles during install and fails
              ;; with --frozen-lockfile.  Allow lockfile reconciliation.
              (substitute* "cmake/Globals.cmake"
                (("--frozen-lockfile")
                 ""))
              (substitute* "cmake/tools/SetupEsbuild.cmake"
                (("--frozen-lockfile")
                 ""))
              ;; Force fully offline behavior: never invoke `bun install`
              ;; during CMake/Ninja; rely on preseeded marker files instead.
              (invoke "python3" "-c"
                      (string-append
                       "from pathlib import Path\n"
                       "globals_path = Path('cmake/Globals.cmake')\n"
                       "s = globals_path.read_text()\n"
                       "fn_start = s.find('function(register_bun_install)')\n"
                       "if fn_start != -1:\n"
                       "    rc_start = s.find('  register_command(', fn_start)\n"
                       "    set_start = s.find('\\n  set(${NPM_NODE_MODULES_VARIABLE}', fn_start)\n"
                       "    if rc_start != -1 and set_start != -1 and rc_start < set_start:\n"
                       "        repl = '  message(STATUS \"Skipping bun install for ${NPM_CWD}; using preseeded node_modules\")\\n'\n"
                       "        s = s[:rc_start] + repl + s[set_start:]\n"
                       "        globals_path.write_text(s)\n"
                       "esbuild_path = Path('cmake/tools/SetupEsbuild.cmake')\n"
                       "t = esbuild_path.read_text()\n"
                       "rc_start = t.find('register_command(')\n"
                       "if rc_start != -1:\n"
                       "    rc_end = t.find('\\n)\\n', rc_start)\n"
                       "    if rc_end != -1:\n"
                       "        rc_end += len('\\n)\\n')\n"
                       "        repl = 'message(STATUS \"Using preseeded esbuild at ${ESBUILD_EXECUTABLE}\")\\n'\n"
                       "        t = t[:rc_start] + repl + t[rc_end:]\n"
                       "        esbuild_path.write_text(t)\n"
                       "build_bun = Path('cmake/targets/BuildBun.cmake')\n"
                       "u = build_bun.read_text()\n"
                       "for target, msg in (\n"
                        "    ('bun-error', 'Skipping bun-error codegen target; using preseeded outputs'),\n"
                        "    ('bun-node-headers', 'Skipping node headers download; using preseeded headers'),\n"
                        "    ('bun-node-fallbacks', 'Skipping node-fallbacks target; using preseeded outputs'),\n"
                        "    ('bun-node-fallbacks-react-refresh', 'Skipping react-refresh fallback target; using preseeded output'),\n"
                        "):\n"
                       "    marker = f'TARGET\\n    {target}'\n"
                       "    pos = u.find(marker)\n"
                       "    if pos == -1:\n"
                       "        continue\n"
                       "    start = u.rfind('register_command(', 0, pos)\n"
                       "    end = u.find('\\n)\\n', pos)\n"
                       "    if start == -1 or end == -1:\n"
                       "        continue\n"
                       "    end += len('\\n)\\n')\n"
                       "    u = u[:start] + f'message(STATUS \"{msg}\")\\n' + u[end:]\n"
                       "build_bun.write_text(u)\n"))

              ;; cppbind.ts can recurse into `bun install` when lezer modules
              ;; are missing; in Guix, fail fast and rely on preseeded modules.
              (invoke "python3" "-c"
                      (string-append
                       "from pathlib import Path\n"
                       "p = Path('src/codegen/cppbind.ts')\n"
                       "t = p.read_text()\n"
                       "start = t.find('if (!isInstalled) {')\n"
                       "end = t.find('\\n\\ntype SyntaxNode = import(\"@lezer/common\").SyntaxNode;')\n"
                       "if start != -1 and end != -1 and start < end:\n"
                       "    repl = '''if (!isInstalled) {\\n"
                       "  console.error(\"Lezer C++ grammar is not available in node_modules (offline build).\");\\n"
                       "  process.exit(1);\\n"
                       "}\\n'''\n"
                       "    t = t[:start] + repl + t[end:]\n"
                       "p.write_text(t)\n"
                       "assert 'spawnSync([process.argv[0], \"install\", \"--frozen-lockfile\"]' not in t\n"))

              ;; Keep C++ object sizes manageable in tmpfs-based Guix builds.
              (substitute* "cmake/CompilerFlags.cmake"
                (("-g3 -gz=zlib \\$\\{DEBUG\\}") "-g0 ${DEBUG}")
                (("-g3 -gz=zstd \\$\\{DEBUG\\}") "-g0 ${DEBUG}")
                (("-g1 \\$\\{RELEASE\\}") "-g0 ${RELEASE}")
                (("-glldb") "-g0"))

              ;; Build with C++23: qualify C math functions that are no longer
              ;; guaranteed in the global namespace.
              (substitute* "src/bun.js/bindings/napi.cpp"
                (("if \\(isfinite\\(js_number\\)\\)")
                 "if (std::isfinite(js_number))"))
              (substitute* "src/bun.js/bindings/BindgenCustomEnforceRange.h"
                (("unrestricted = trunc\\(unrestricted\\);")
                 "unrestricted = std::trunc(unrestricted);"))
              (substitute* "src/bun.js/bindings/webcore/JSDOMConvertNumbers.cpp"
                (("x = trunc\\(x\\);")
                 "x = std::trunc(x);"))

              ;; Apply third-party patches usually handled by GitClone.cmake.
              (let ((cwd (getcwd)))
                (define (apply-patch target patch)
                  (when (file-exists? target)
                    (with-directory-excursion target
                      (invoke "git" "apply"
                              "--ignore-whitespace"
                              "--ignore-space-change"
                              "--no-index"
                              "--verbose"
                              (string-append cwd "/" patch)))))
                (apply-patch "vendor/highway"
                             "patches/highway/silence-warnings.patch")
                (apply-patch "vendor/libarchive"
                             "patches/libarchive/CMakeLists.txt.patch")
                (apply-patch "vendor/libarchive"
                             "patches/libarchive/archive_write_add_filter_gzip.c.patch")
                (apply-patch "vendor/lshpack"
                             "patches/lshpack/CMakeLists.txt.patch")
                (apply-patch "vendor/tinycc" "patches/tinycc/tcc.h.patch")
                (when (file-exists? "vendor/tinycc")
                  (copy-file "patches/tinycc/CMakeLists.txt"
                             "vendor/tinycc/CMakeLists.txt"))
                (apply-patch "vendor/zlib" "patches/zlib/CMakeLists.txt.patch")
                (apply-patch "vendor/zlib" "patches/zlib/deflate.h.patch")
                (apply-patch "vendor/zlib" "patches/zlib/ucm.cmake.patch"))))
          (add-before 'build 'provide-webkit
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((cache (string-append (getcwd) "/build/release/cache"))
                     (webkit (string-append cache "/webkit-9a2cc42ae1bf693a")))
                (mkdir-p cache)
                ;; A header below is patched in place, so this cannot be a
                ;; symlink into the read-only store.
                (copy-recursively (assoc-ref inputs "bun-webkit") webkit)
                (for-each (lambda (file) (chmod file #o644))
                          (find-files webkit "\\.h$"))
                ;; Clang in C++23 mode no longer resolves these C math symbols
                ;; unqualified in this header.
                (substitute* (string-append
                              webkit
                              "/include/JavaScriptCore/JSCJSValueInlines.h")
                  (("return trunc\\(toNumber\\(globalObject\\) \\+ 0\\.0\\);")
                   "return std::trunc(toNumber(globalObject) + 0.0);")
                  (("return isnan\\(d\\) \\? 0\\.0 : trunc\\(d\\) \\+ 0\\.0;")
                   "return std::isnan(d) ? 0.0 : std::trunc(d) + 0.0;")))
              ;; Upstream links the static ICU archives that its prebuilt
              ;; JavaScriptCore tarball bundles from the build host.  Guix's
              ;; icu4c ships shared libraries only, and JavaScriptCore is
              ;; built against those.
              (substitute* "cmake/targets/BuildBun.cmake"
                (("\\$\\{WEBKIT_LIB_PATH\\}/libicudata\\.a") "icudata")
                (("\\$\\{WEBKIT_LIB_PATH\\}/libicui18n\\.a") "icui18n")
                (("\\$\\{WEBKIT_LIB_PATH\\}/libicuuc\\.a") "icuuc"))))
          ;; Bun's CMake registers a clone step per vendored dependency whose
          ;; declared output is vendor/NAME/.ref.  Unpacking the sources and
          ;; writing that marker leaves those steps with nothing to do, which
          ;; is what keeps the build from reaching for the network.
          ;; Must precede 'prepare-offline-tree, which patches these trees.
          (add-before 'prepare-offline-tree 'unpack-vendored-sources
            (lambda* (#:key inputs #:allow-other-keys)
              (for-each
               (lambda (entry)
                 (let* ((name (car entry))
                        (commit (cadr entry))
                        (directory (string-append "vendor/" name)))
                   (mkdir-p directory)
                   (invoke "tar" "xf"
                           (assoc-ref inputs (string-append "vendor-" name))
                           "-C" directory "--strip-components=1")
                   (call-with-output-file (string-append directory "/.ref")
                     (lambda (port) (display commit port)))))
               '#$(map (lambda (entry)
                         (list (car entry) (caddr entry)))
                       %bun-vendored-sources))
              ;; Brotli is pinned by tag, so its marker holds a ref name.
              (let ((directory "vendor/brotli"))
                (mkdir-p directory)
                (invoke "tar" "xf" (assoc-ref inputs "vendor-brotli")
                        "-C" directory "--strip-components=1")
                (call-with-output-file (string-append directory "/.ref")
                  (lambda (port)
                    (display #$(string-append "refs/tags/"
                                              %bun-vendored-brotli-tag)
                             port))))))
          ;; Give cargo a directory source holding lolhtml's dependency tree,
          ;; so that building vendor/lolhtml/c-api needs no network.  Each
          ;; package directory needs a .cargo-checksum.json: "package" is the
          ;; crate's SHA-256, which cargo matches against the checksum its
          ;; lock file records, and an empty "files" map tells it not to
          ;; re-verify contents the store has already authenticated.
          (add-before 'build 'vendor-lolhtml-crates
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((registry (string-append (getcwd) "/vendor/rust-crates")))
                (mkdir-p registry)
                (for-each
                 (lambda (entry)
                   (let* ((name (car entry))
                          (version (cadr entry))
                          (checksum (caddr entry))
                          (directory (string-append registry "/" name "-"
                                                    version)))
                     (mkdir-p directory)
                     (invoke "tar" "xf"
                             (assoc-ref inputs (string-append "crate-" name "-"
                                                              version))
                             "-C" directory "--strip-components=1")
                     (call-with-output-file
                         (string-append directory "/.cargo-checksum.json")
                       (lambda (port)
                         (format port "{\"files\":{},\"package\":\"~a\"}"
                                 checksum)))))
                 '#$(map (lambda (entry)
                           (list (car entry) (cadr entry) (cadddr entry)))
                         %lolhtml-vendored-crates))
                ;; CMake points CARGO_HOME at .cargo in the source root.
                (mkdir-p ".cargo")
                (call-with-output-file ".cargo/config.toml"
                  (lambda (port)
                    (format port "[source.crates-io]~%\
replace-with = \"vendored-sources\"~%~%\
[source.vendored-sources]~%\
directory = \"~a\"~%" registry))))))
          ;; Bun 1.3.8's code generators use a few runtime APIs that the
          ;; source-built stage0 Bun (1.0.0) predates, and pass a bundler flag
          ;; it does not know.  Shim the APIs and drop the flag.
          (add-before 'build 'adapt-codegen-to-stage0
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Unknown to 1.0.0's CLI, where it derails option parsing into
              ;; a misleading "specify --outdir" error.  Only meaningful
              ;; alongside identifier minification, which is not enabled here.
              (substitute* "src/codegen/bundle-modules.ts"
                (("\\[\"--minify-syntax\", \"--keep-names\"\\]")
                 "[\"--minify-syntax\"]"))
              ;; import.meta.dirname postdates 1.0.0, which spells it
              ;; import.meta.dir.  Left undefined it silently yields bogus
              ;; paths rather than an error, so the generators fail later
              ;; with confusing missing-file messages.
              (substitute* (find-files "src/codegen" "\\.ts$")
                (("import\\.meta\\.dirname") "import.meta.dir"))
              ;; Reach ByteBuffer through peechy's "./bb" entry point, as the
              ;; rest of the tree already does (src/api/schema.d.ts,
              ;; packages/bun-wasm/index.ts).  The root module additionally
              ;; re-exports the schema compilers, whose change-case dependency
              ;; is not vendored.
              (substitute* "src/fallback.ts"
                (("from \"peechy\";") "from \"peechy/bb\";"))
              ;; 1.0.0's import.meta.require() returns an empty object for an
              ;; ES module, so bindgen never sees the .bind.ts exports and
              ;; rejects their functions as "not exported".  Dynamic import()
              ;; does report them, but cannot replace the require(): the
              ;; generator's TypeImpl constructor infers each type's owning
              ;; file by walking the stack for the first frame outside
              ;; src/codegen, and under a pure ES module graph "bindgen"
              ;; (src/codegen/bindgen-lib.ts) is evaluated before the
              ;; importing .bind.ts body, leaving no such frame.  Keep the
              ;; require() so that evaluation stays nested in the .bind.ts
              ;; frame, and read the exports from the import().
              (substitute* "src/codegen/bindgen.ts"
                (("  const exports = import\\.meta\\.require\\(fileName\\);")
                 (string-append
                  "  const cjsExports = import.meta.require(fileName);\n"
                  "  const exports = Object.keys(cjsExports).length > 0\n"
                  "    ? cjsExports\n"
                  "    : await import(fileName);")))
              ;; The v2 generator reads its .bindv2.ts modules the same way,
              ;; and hit the same empty result: it wrote a bindgen_generated
              ;; .zig holding nothing but an empty `internal' struct, and
              ;; exited 0.  That went unnoticed until the Zig sources were
              ;; finally reached and failed on the missing SocketConfig types.
              ;; Nothing here inspects stack frames, so the modules can simply
              ;; be loaded up front and looked up by path.
              (substitute* "src/codegen/bindgenv2/script.ts"
                (("function getNamedExports\\(\\): NamedType\\[\\] \\{")
                 (string-append
                  "async function getNamedExports(): Promise<NamedType[]> {\n"
                  "  const loaded = new Map<string, any>();\n"
                  "  for (const p of sources) {\n"
                  "    const cjs = import.meta.require(p);\n"
                  "    loaded.set(p, Object.keys(cjs).length > 0\n"
                  "      ? cjs\n"
                  "      : await import(p));\n"
                  "  }"))
                (("    const exports = import\\.meta\\.require\\(path\\);")
                 "    const exports = loaded.get(path);")
                (("function generate\\(\\): void \\{")
                 "async function generate(): Promise<void> {")
                (("  const namedExports = getNamedExports\\(\\);")
                 "  const namedExports = await getNamedExports();")
                (("function main\\(\\): void \\{")
                 "async function main(): Promise<void> {")
                (("      generate\\(\\);") "      await generate();")
                (("^main\\(\\);") "await main();"))
              ;; Iterator helpers (Iterator.prototype.some) postdate 1.0.0.
              ;; Spreading uses the same string iterator, so the array form is
              ;; equivalent.
              (substitute* "src/codegen/bindgenv2/internal/base.ts"
                (("  if \\(value\\[Symbol\\.iterator\\]\\(\\)\\.some\\(c => c\\.charCodeAt\\(0\\) >= 128\\)\\) \\{")
                 "  if ([...value].some(c => c.charCodeAt(0) >= 128)) {"))
              ;; 1.0.0 refuses to load bun:test outside `bun test'.  The
              ;; generator uses it for a single filename assertion, so
              ;; express that directly instead.
              (substitute* "src/codegen/bindgen-lib-internal.ts"
                (("import \\{ expect \\} from \"bun:test\";")
                 (string-append
                  "const expect = (value: any) => ({\n"
                  "  toEndWith(suffix: string) {\n"
                  "    if (!String(value).endsWith(suffix))\n"
                  "      throw new Error(`expected ${value} to end with"
                  " ${suffix}`);\n"
                  "  },\n"
                  "});")))
              ;; Reading a subprocess' stdout only after it has exited trips a
              ;; ReadableStream controller assertion in 1.0.0 when that stdout
              ;; is empty, which is the case for the class hash tables: no
              ;; .classes.ts defines "own" properties, so create_hash_table is
              ;; handed no @begin/@end block and prints nothing.  Start the
              ;; read before awaiting the exit.
              (substitute* "src/codegen/create-hash-table.ts"
                (("proc\\.stdin\\.write\\(input_preprocessed\\);")
                 (string-append
                  "const stdoutText = new Response(proc.stdout).text();\n"
                  "proc.stdin.write(input_preprocessed);"))
                (("let str = await new Response\\(proc\\.stdout\\)\\.text\\(\\);")
                 "let str = await stdoutText;"))
              ;; Two 1.0.0 limitations in the Bake runtime generator.  It
              ;; minifies the dev-server overlay stylesheet by shelling out to
              ;; `bun build overlay.css', but CSS entry points postdate 1.0.0,
              ;; which fails with "cannot write multiple output files without
              ;; an output directory"; the value only has to be a JavaScript
              ;; string literal for the OVERLAY_CSS define, so embed the
              ;; stylesheet unminified.  Separately, the generator bundles a
              ;; second time from a .runtime-*.generated.ts file it has just
              ;; written, but 1.0.0's resolver caches its listing of src/bake
              ;; and reports ModuleNotFound.  The three runtimes are bundled
              ;; concurrently, so the first one to start scanning fixes that
              ;; listing for all of them; the failure lands on "error", the
              ;; last of the three to reach its write.  Create all three
              ;; before any bundle starts, and delete them only once all
              ;; three have settled, so src/bake holds still for the whole
              ;; concurrent phase.
              (substitute* "src/codegen/bake-codegen.ts"
                (("function css\\(file: string, is_development: boolean\\): string \\{")
                 (string-append
                  "function css(file: string, is_development: boolean)"
                  ": string {\n"
                  "  return JSON.stringify("
                  "readFileSync(join(import.meta.dir, file), \"utf-8\"));"))
                (("  const results = await Promise\\.allSettled\\(")
                 (string-append
                  "  for (const f of [\"client\", \"server\", \"error\"])\n"
                  "    writeIfNotChanged(join(base_dir,"
                  " `.runtime-${f}.generated.ts`), \"\");\n"
                  "  const results = await Promise.allSettled("))
                (("      rmSync\\(generated_entrypoint\\);") "")
                (("  interface Err \\{")
                 (string-append
                  "  for (const f of [\"client\", \"server\", \"error\"])\n"
                  "    rmSync(join(base_dir,"
                  " `.runtime-${f}.generated.ts`), { force: true });\n"
                  "  interface Err {")))
              ;; The builtin-function bundler writes each function to its own
              ;; file under tmp_functions and immediately bundles it, relying
              ;; on an `await Bun.sleep(1)' to let the resolver notice the new
              ;; file.  Under 1.0.0, with ninja running many jobs at once,
              ;; that is not always long enough and the bundle fails with
              ;; ModuleNotFound; it took three builds to show up once.  Create
              ;; every file for the group before bundling any of them, so the
              ;; directory is already complete when it is first scanned.
              (substitute* "src/codegen/bundle-functions.ts"
                (("^  for \\(const fn of functions\\) \\{")
                 (string-append
                  "  for (const fn of functions) {\n"
                  "    await Bun.write(path.join(TMP_DIR,"
                  " `${basename}.${fn.name}.ts`), \"\");\n"
                  "  }\n"
                  "  for (const fn of functions) {")))
              ;; TypeScript `const enum' members have to be substituted for
              ;; their values at build time.  1.0.0 erases the declaration but
              ;; leaves the uses standing, so the generated builtins reference
              ;; an identifier that exists nowhere: `process.stdout' and
              ;; `process.stderr' then come out undefined, and
              ;; ReadableStream.tee() breaks the same way.  Both go unnoticed
              ;; until something reads them at runtime.  Inline the values,
              ;; which is what the erasure is supposed to do.  A `define' for
              ;; the bundler would be neater, but the declaration is still in
              ;; scope where defines are applied, so it cannot be relied on.
              (substitute* "src/js/builtins/ProcessObjectInternals.ts"
                (("BunProcessStdinFdType\\.file") "0")
                (("BunProcessStdinFdType\\.pipe") "1")
                (("BunProcessStdinFdType\\.socket") "2"))
              (substitute* "src/js/builtins/ReadableStreamInternals.ts"
                (("TeeStateFlags\\.canceled1") "1")
                (("TeeStateFlags\\.canceled2") "2")
                (("TeeStateFlags\\.reading") "4")
                (("TeeStateFlags\\.closedOrErrored") "8")
                (("TeeStateFlags\\.readAgain") "16"))
              (let* ((helpers (string-append (getcwd) "/.guix-bun"))
                     (shims (string-append helpers "/shims.js"))
                     (wrapper (string-append helpers "/bun")))
                (mkdir-p helpers)
                (call-with-output-file shims
                  (lambda (port)
                    (display "\
import { readdirSync, mkdirSync } from \"fs\";
import { dirname, basename, join } from \"path\";

if (typeof Bun.Glob === \"undefined\") {
  Bun.Glob = class Glob {
    constructor(pattern) { this.pattern = pattern; }
    *scanSync() {
      const directory = dirname(this.pattern);
      const rx = new RegExp(\"^\" + basename(this.pattern)
        .replace(/[.+^${}()|[\\]\\\\]/g, \"\\\\$&\")
        .replace(/\\*/g, \".*\")
        .replace(/\\?/g, \".\") + \"$\");
      let entries;
      try { entries = readdirSync(directory); } catch { return; }
      for (const entry of entries.sort())
        if (rx.test(entry)) yield join(directory, entry);
    }
    scan() { return this.scanSync(); }
  };
}

if (typeof Bun.stringWidth === \"undefined\")
  Bun.stringWidth = s => String(s).replace(/\\x1b\\[[0-9;]*m/g, \"\").length;

// Bun.write gained implicit parent-directory creation after 1.0.0.
{
  const write = Bun.write;
  Bun.write = function (destination, ...rest) {
    if (typeof destination === \"string\")
      try { mkdirSync(dirname(destination), { recursive: true }); } catch {}
    return write.call(this, destination, ...rest);
  };
}
" port)))
                ;; CMake resolves BUN_EXECUTABLE from PATH, so the shims have
                ;; to travel with the executable.  They must not reach the
                ;; `bun build' subprocesses the generators spawn, which rules
                ;; out bunfig.toml's preload.  1.0.0 also mis-parses a flag
                ;; placed before the `run' subcommand, so drop that word;
                ;; `bun run FILE' and `bun FILE' are equivalent here.
                (call-with-output-file wrapper
                  (lambda (port)
                    ;; There is no /bin/sh in the build container, and this
                    ;; file is written after the shebang-patching phases.
                    (display (string-append
                              "#!" (which "bash") "\n"
                              "if [ \"$1\" = run ]; then shift; fi\n"
                              "exec " (assoc-ref inputs "bun-stage0")
                              "/bin/bun --preload " shims " \"$@\"\n")
                             port)))
                (chmod wrapper #o755)
                (setenv "PATH"
                        (string-append helpers ":" (getenv "PATH"))))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "HOME" (getcwd))
              (setenv "BUN_DEBUG_QUIET_LOGS" "1")
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; The link step finishes by running `bun-profile --revision' as
              ;; a sanity check.  Nothing links ICU into the loader's default
              ;; search path inside the build container, so without this the
              ;; freshly linked binary cannot start and the whole build fails
              ;; at 628/628 with a bare exit code 127.
              (setenv "LD_LIBRARY_PATH"
                      (string-append (assoc-ref inputs "icu4c") "/lib"))
              ;; Codegen runs on the source-built stage0 Bun, which
              ;; 'adapt-codegen-to-stage0 already puts on PATH together with
              ;; the bunfig.toml that loads its shims.
              ;; Use full local parallelism for CMake/Ninja.
              (setenv "CMAKE_BUILD_PARALLEL_LEVEL" "16")
              ;; Guix kills builds that stay silent for too long; emit periodic
              ;; keepalive lines while CMake/Ninja compile.
              (invoke "bash" "-lc"
                      "set -euo pipefail\n(while true; do echo \"[guix-heartbeat] bun-from-source build still running\"; sleep 60; done) &\nhb_pid=$!\ntrap 'kill \"$hb_pid\" 2>/dev/null || true' EXIT\npython3 - <<'PY'\nimport glob\nimport json\nimport re\nfrom pathlib import Path\n\nroot = Path('.').resolve()\n\ndef expand_braces(pattern):\n    start = pattern.find('{')\n    if start == -1:\n        return [pattern]\n    depth = 0\n    end = -1\n    for i, ch in enumerate(pattern[start:], start):\n        if ch == '{':\n            depth += 1\n        elif ch == '}':\n            depth -= 1\n            if depth == 0:\n                end = i\n                break\n    if end == -1:\n        return [pattern]\n    inside = pattern[start + 1:end]\n    parts = []\n    buf = ''\n    depth = 0\n    for ch in inside:\n        if ch == ',' and depth == 0:\n            parts.append(buf)\n            buf = ''\n        else:\n            if ch == '{':\n                depth += 1\n            elif ch == '}':\n                depth -= 1\n            buf += ch\n    parts.append(buf)\n    out = []\n    prefix = pattern[:start]\n    suffix = pattern[end + 1:]\n    for part in parts:\n        for rest in expand_braces(suffix):\n            out.extend(expand_braces(prefix + part + rest))\n    return out\n\ndef to_zig_namespace(name):\n    result = re.sub(r'([^A-Z_])([A-Z])', r'\\1_\\2', name)\n    result = re.sub(r'([A-Z])([A-Z][a-z])', r'\\1_\\2', result)\n    result = result.lower()\n    if result == name:\n        return result + '_namespace'\n    return result\n\nitems = json.loads((root / 'cmake' / 'Sources.json').read_text())\nfor item in items:\n    excludes = set(item.get('exclude', []))\n    excludes.update({\n        'src/bun.js/bindings/GeneratedBindings.zig',\n        'src/bun.js/bindings/GeneratedJS2Native.zig',\n    })\n    rels = []\n    for pat in item['paths']:\n        for expanded in expand_braces(pat):\n            for match in glob.glob(expanded, recursive=True):\n                path = Path(match)\n                if not path.is_file():\n                    continue\n                rel = path.as_posix()\n                if rel in excludes:\n                    continue\n                rels.append(rel)\n    rels = sorted(set(rels))\n    out = root / 'cmake' / 'sources' / item['output']\n    out.parent.mkdir(parents=True, exist_ok=True)\n    out.write_text(('\\n'.join(rels) + '\\n') if rels else '')\n\n# Precompute bindgenv2 outputs so CMake does not invoke bun-stage0 for\n# --command=list-outputs (it can hang there).\nbindgen_sources = root / 'cmake' / 'sources' / 'BindgenV2Sources.txt'\ncodegen_path = root / 'build' / 'release' / 'codegen'\ncodegen_path.mkdir(parents=True, exist_ok=True)\nbindgen_outputs = [f\"{codegen_path.as_posix()}/bindgen_generated.zig\"]\nseen = set()\nif bindgen_sources.exists():\n    for rel in bindgen_sources.read_text().splitlines():\n        rel = rel.strip()\n        if not rel:\n            continue\n        src = root / rel\n        if not src.is_file():\n            continue\n        text = src.read_text()\n        for name, kind in re.findall(\n            r'export\\s+const\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*b\\.(dictionary|enumeration|union)\\s*\\(',\n            text,\n        ):\n            key = (name, kind)\n            if key in seen:\n                continue\n            seen.add(key)\n            if kind in {'dictionary', 'enumeration'}:\n                bindgen_outputs.append(\n                    f\"{codegen_path.as_posix()}/Generated{name}.cpp\"\n                )\n            bindgen_outputs.append(\n                f\"{codegen_path.as_posix()}/bindgen_generated/{to_zig_namespace(name)}.zig\"\n            )\n\n(codegen_path / 'bindgenv2-outputs.txt').write_text(';'.join(bindgen_outputs))\nPY\nmkdir -p build/release/codegen/bun-error build/release/codegen/node-fallbacks\ncp -f packages/bun-error/bun-error.css build/release/codegen/bun-error/bun-error.css\ncat > build/release/codegen/bun-error/index.js <<'EOF'\nexport default {};\nEOF\nfor f in src/node-fallbacks/*.js; do\n  [ -f \"$f\" ] || continue\n  cp -f \"$f\" build/release/codegen/node-fallbacks/\ndone\ncat > build/release/codegen/node-fallbacks/react-refresh.js <<'EOF'\nmodule.exports = {};\nEOF\nBUN_EXE=\"$(command -v bun)\"\necho \"[guix-heartbeat] using bun executable: ${BUN_EXE}\"\n\"${BUN_EXE}\" --version\nrm -f build/release/CMakeCache.txt\ncmake -S . -B build/release -GNinja -DCMAKE_BUILD_TYPE=Release -DCACHE_STRATEGY=auto -DBUN_EXECUTABLE=\"${BUN_EXE}\"\nif [ -f build/release/.env ]; then set -a; . build/release/.env; set +a; fi\ncmake --build build/release --parallel 16")))
          (replace 'install
            (lambda* (#:key outputs inputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (bun (string-append bin "/bun"))
                     (interpreter
                      (search-input-file inputs "/lib/ld-linux-x86-64.so.2")))
                (mkdir-p bin)
                (install-file "build/release/bun" bin)
                (chmod bun #o755)
                (invoke "patchelf" "--set-interpreter" interpreter bun)
                ;; Clang links this binary with ld-linux as DT_NEEDED, which
                ;; Guix RUNPATH validation rejects for executables.
                (invoke "patchelf" "--remove-needed"
                        "ld-linux-x86-64.so.2"
                        bun)
                ;; The link runs lld directly rather than through Guix's
                ;; ld wrapper, so the binary carries no RUNPATH at all even
                ;; though it needs libicui18n, libicuuc and libc.
                (invoke "patchelf" "--set-rpath"
                        (string-append (assoc-ref inputs "icu4c") "/lib:"
                                       (assoc-ref inputs "glibc") "/lib")
                        bun))))
          ;; libstdc++'s assertion macros bake __FILE__ into the message, so
          ;; the path of every standard header an assertion can fire in ends
          ;; up as a string literal.  Guix scans output for store hashes, so
          ;; those eight strings alone made the whole gcc package -- 336 MiB,
          ;; nearly a third of opencode's closure -- a runtime reference.
          ;; -ffile-prefix-map was tried first and does not reach them.
          ;;
          ;; They are only ever printed inside an assertion message, so blank
          ;; the hash where it stands.  The replacement is the same length,
          ;; so nothing in the file moves, and only paths under a gcc include
          ;; directory match: the RUNPATH set just above, which is the only
          ;; reference bun genuinely needs, is left as it was.
          ;;
          ;; The scan uses string operations rather than a regexp because
          ;; Guile's make-regexp goes through POSIX regex, which is
          ;; NUL-terminated: on a binary it stops at the first NUL byte and
          ;; finds nothing.  Guile strings carry their own length.
          (add-after 'install 'blank-compiler-header-references
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((bun (string-append (assoc-ref outputs "out")
                                         "/bin/bun"))
                     (text (call-with-input-file bun
                             (lambda (port)
                               (set-port-encoding! port "ISO-8859-1")
                               (get-string-all port))))
                     (size (string-length text)))
                (define (at? position literal)
                  (let ((end (+ position (string-length literal))))
                    (and (<= end size)
                         (string=? (substring text position end) literal))))
                (define (compiler-include? position)
                  ;; "/gnu/store/", 32 hash characters, then a gcc directory
                  ;; whose path continues into include/.
                  (and (at? (+ position 43) "-gcc-")
                       (let scan ((k (+ position 43)))
                         (cond ((> k (+ position 90)) #f)
                               ((at? k "/include/") #t)
                               (else (scan (+ k 1)))))))
                (define (finish kept pieces found)
                  (let ((clean (string-concatenate
                                (reverse (cons (substring text kept size)
                                               pieces)))))
                    (when (zero? found)
                      (error "no compiler header references in" bun))
                    (unless (= (string-length clean) size)
                      (error "rewrite changed the size of" bun))
                    (chmod bun #o755)
                    (call-with-output-file bun
                      (lambda (port)
                        (set-port-encoding! port "ISO-8859-1")
                        (put-string port clean)))
                    (chmod bun #o555)
                    (format #t "blanked ~a compiler header reference(s)~%"
                            found)))
                (let loop ((from 0) (kept 0) (pieces '()) (found 0))
                  (let ((position (string-contains text "/gnu/store/" from)))
                    (cond
                     ((not position) (finish kept pieces found))
                     ((compiler-include? position)
                      (loop (+ position 43) (+ position 43)
                            (cons (make-string 32 #\e)
                                  (cons (substring text kept (+ position 11))
                                        pieces))
                            (+ found 1)))
                     (else (loop (+ position 11) kept pieces found)))))))))))
    (inputs
     (list glibc icu4c))
    (native-inputs
     `(("bun-stage0" ,bun-stage0)
       ("bun-webkit" ,bun-webkit-for-1.3.8)
       ,@(map (lambda (entry)
                (list (string-append "vendor-" (car entry))
                      (bun-vendored-source entry)))
              %bun-vendored-sources)
       ("vendor-brotli" ,bun-vendored-brotli)
       ,@(map (lambda (entry)
                (list (string-append "crate-" (car entry) "-" (cadr entry))
                      (lolhtml-vendored-crate entry)))
              %lolhtml-vendored-crates)
       ("lezer-common" ,lezer-common-source)
       ("lezer-cpp" ,lezer-cpp-source)
       ("lezer-highlight" ,lezer-highlight-source)
       ("lezer-lr" ,lezer-lr-source)
       ("peechy" ,peechy-source)
       ("node-headers" ,node-v24.3.0-headers-source)
       ("cmake-minimal" ,cmake-minimal)
       ("ninja" ,ninja)
       ("pkg-config" ,pkg-config)
       ("clang" ,clang-19)
       ("lld" ,lld-19)
       ("llvm" ,llvm-19)
       ("zig" ,zig-for-bun)
       ("rust" ,rust)
       ("rust:cargo" ,rust "cargo")
       ("go" ,go)
       ("ruby" ,ruby)
       ("python" ,python)
       ("node" ,node)
       ("perl" ,perl)
       ("git" ,git)
       ("patchelf" ,patchelf)
       ("which" ,which)
       ("esbuild" ,esbuild)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://bun.sh")
    (synopsis "Prototype package to build Bun from source")
    (description "Prototype package to build Bun from source.")
    (license license:expat)))

;; Backward-compatibility alias.
(define-public bun-from-source-local bun-from-source)

(define bun-build-system-smoke-source
  (computed-file
   "bun-build-system-smoke-source"
   #~(begin
       (mkdir #$output)
       (mkdir (string-append #$output "/src"))
       (call-with-output-file (string-append #$output "/src/hello.txt")
         (lambda (port)
           (display "hello from bun-build-system\n" port)))
       (call-with-output-file (string-append #$output "/package.json")
         (lambda (port)
           (display
            "{\n  \"name\": \"bun-build-system-smoke\",\n  \"version\": \"0.0.1\",\n  \"scripts\": {\n    \"build\": \"mkdir -p dist && cp src/hello.txt dist/hello.txt\",\n    \"test\": \"test -f dist/hello.txt\"\n  }\n}\n"
            port))))))

(define-public bun-build-system-smoke
  (package
    (name "bun-build-system-smoke")
    (version "0.0.1")
    (source bun-build-system-smoke-source)
    (build-system bun-build-system)
    (arguments
     (list
      #:bun bun-from-source
      #:tests? #t))
    (supported-systems '("x86_64-linux"))
    (home-page "https://bun.sh")
    (synopsis "Smoke test package for bun-build-system")
    (description
     "Minimal package used to verify that bun-build-system can run install,
build, test, and install phases.")
    (license license:expat)))

;; opencode bundles 20 packages from the vercel/ai monorepo, all published as
;; built output only.  They are buildable from source here because upstream's
;; tsup configuration reduces to two esbuild invocations -- entry src/index.ts,
;; CommonJS and ESM -- and tsup's third product, the .d.ts declarations, is
;; types only: `bun build --compile' never reads it.  Every package the binary
;; uses is at its published version at the ai@5.0.124 tag, so one checkout
;; covers the set.
(define %vercel-ai-version "5.0.124")

;; The monorepo checkout is shared by every package built from it.
(define vercel-ai-source
  (origin
       (method git-fetch)
       (uri (git-reference (url "https://github.com/vercel/ai")
                           (commit (string-append "ai@" %vercel-ai-version))))
       (file-name (git-file-name "vercel-ai" %vercel-ai-version))
       (sha256
        (base32
         "1jfzb1ycknmzmspkyp01f96q84xkri630yb2br5s2yh8q6c78haq"))))

;; Directory under packages/ in the monorepo.  Every one of these is
;; installed in opencode's tree; the monorepo carries about twice as many
;; that nothing here resolves.
(define %vercel-ai-packages
  '("ai"
    "amazon-bedrock"
    "anthropic"
    "azure"
    "cerebras"
    "cohere"
    "deepgram"
    "deepinfra"
    "deepseek"
    "elevenlabs"
    "fireworks"
    "gateway"
    "google"
    "google-vertex"
    "groq"
    "mistral"
    "openai"
    "openai-compatible"
    "perplexity"
    "provider"
    "provider-utils"
    "togetherai"
    "vercel"
    "xai"))

(define (vercel-ai-package directory)
  (package
    (name (if (string=? directory "ai")
              "node-ai"
              (string-append "node-ai-sdk-" directory)))
    (version %vercel-ai-version)
    (source vercel-ai-source)
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; Driving this from Node keeps the manifest parsing and the
              ;; esbuild invocation in one place, and Node is already needed.
              (call-with-output-file "build-packages.js"
                (lambda (port)
                  (display "\
const { readdirSync, existsSync, mkdirSync, readFileSync } = require('fs');
const { execFileSync } = require('child_process');
let built = 0;
for (const dir of [process.env.PACKAGE_DIRECTORY]) {
  const manifest = `packages/${dir}/package.json`;
  const entry = `packages/${dir}/src/index.ts`;
  if (!existsSync(manifest) || !existsSync(entry)) continue;
  const meta = JSON.parse(readFileSync(manifest, 'utf8'));
  // Dependencies stay external, as tsup leaves them: bundling them would
  // duplicate code the resolver is meant to share between packages.
  const deps = [
    ...Object.keys(meta.dependencies || {}),
    ...Object.keys(meta.peerDependencies || {}),
  ];
  const external = deps.flatMap(d => [`--external:${d}`, `--external:${d}/*`]);
  const target = `out/${meta.name}`;
  mkdirSync(target, { recursive: true });
  require('fs').writeFileSync(`${target}/VERSION`, meta.version + '\\n');
  mkdirSync(`${target}/dist`, { recursive: true });
  for (const [format, file] of [['cjs', 'index.js'], ['esm', 'index.mjs']]) {
    // tsup substitutes this at build time; left undefined it survives into
    // the output as a free variable and throws when first evaluated.
    execFileSync('esbuild', [entry, '--bundle', '--platform=node',
                             `--define:__PACKAGE_VERSION__=${JSON.stringify(meta.version)}`,
                             `--format=${format}`,
                             `--outfile=${target}/dist/${file}`, ...external],
                 { stdio: 'inherit' });
  }
  built++;
}
console.log(`built ${built} packages`);
if (built === 0) throw new Error('no packages were built');
// A bundler config that substitutes an identifier is part of the package's
// build.  Miss one and it survives as a free variable that throws the first
// time that code runs -- which no smoke test is likely to reach.
const leaked = [];
const walk = (dir) => {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = `${dir}/${e.name}`;
    if (e.isDirectory()) { walk(p); continue; }
    if (!/\\.(js|mjs|cjs)$/.test(e.name)) continue;
    for (const m of readFileSync(p, 'utf8').matchAll(/\\b__[A-Z][A-Z0-9_]*__\\b/g)) {
      if (m[0] !== '__PURE__') leaked.push(`${p}: ${m[0]}`);
    }
  }
};
walk('out');
if (leaked.length)
  throw new Error('unsubstituted build-time identifiers: ' + leaked.slice(0, 5).join('; '));
" port)))
              ;; The script is written out as a string, where #$ is not
              ;; interpolated, so the directory is passed in the environment.
              (setenv "PACKAGE_DIRECTORY" #$directory)
              (invoke "node" "build-packages.js")
              (delete-file "build-packages.js")))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((lib (string-append (assoc-ref outputs "out") "/lib")))
                (unless (file-exists? "out")
                  (error "no packages were built"))
                (mkdir-p lib)
                (copy-recursively "out" lib)))))))
    (native-inputs (list esbuild node))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/vercel/ai")
    (synopsis "AI SDK packages built from source")
    (description
     "This package builds one JavaScript package from the vercel/ai
monorepo, replacing the built output it is published as on npm.")
    (license license:expat)))

(define-public node-ai
  (vercel-ai-package "ai"))
(define-public node-ai-sdk-amazon-bedrock
  (vercel-ai-package "amazon-bedrock"))
(define-public node-ai-sdk-anthropic
  (vercel-ai-package "anthropic"))
(define-public node-ai-sdk-azure
  (vercel-ai-package "azure"))
(define-public node-ai-sdk-cerebras
  (vercel-ai-package "cerebras"))
(define-public node-ai-sdk-cohere
  (vercel-ai-package "cohere"))
(define-public node-ai-sdk-deepgram
  (vercel-ai-package "deepgram"))
(define-public node-ai-sdk-deepinfra
  (vercel-ai-package "deepinfra"))
(define-public node-ai-sdk-deepseek
  (vercel-ai-package "deepseek"))
(define-public node-ai-sdk-elevenlabs
  (vercel-ai-package "elevenlabs"))
(define-public node-ai-sdk-fireworks
  (vercel-ai-package "fireworks"))
(define-public node-ai-sdk-gateway
  (vercel-ai-package "gateway"))
(define-public node-ai-sdk-google
  (vercel-ai-package "google"))
(define-public node-ai-sdk-google-vertex
  (vercel-ai-package "google-vertex"))
(define-public node-ai-sdk-groq
  (vercel-ai-package "groq"))
(define-public node-ai-sdk-mistral
  (vercel-ai-package "mistral"))
(define-public node-ai-sdk-openai
  (vercel-ai-package "openai"))
(define-public node-ai-sdk-openai-compatible
  (vercel-ai-package "openai-compatible"))
(define-public node-ai-sdk-perplexity
  (vercel-ai-package "perplexity"))
(define-public node-ai-sdk-provider
  (vercel-ai-package "provider"))
(define-public node-ai-sdk-provider-utils
  (vercel-ai-package "provider-utils"))
(define-public node-ai-sdk-togetherai
  (vercel-ai-package "togetherai"))
(define-public node-ai-sdk-vercel
  (vercel-ai-package "vercel"))
(define-public node-ai-sdk-xai
  (vercel-ai-package "xai"))
(define %vercel-from-source
  (map vercel-ai-package %vercel-ai-packages))

;; The @actions/* packages are published as per-file tsc output under lib/,
;; not as a bundle, so esbuild runs in transpile mode with --outdir.  Each
;; version needs its own commit: actions/toolkit does not tag most releases,
;; so these were found by walking git log over each package.json for the
;; version bump.  @actions/github is deliberately absent -- its published
;; 6.0.1 exists on no merged branch and carries no gitHead, so no commit can
;; honestly be claimed as its source.
(define %actions-toolkit-packages
  ;; (SUBDIRECTORY VERSION COMMIT HASH)
  '(("core" "1.11.1" "d14afd7973c037fa9f72882decd1eb3befa36135"
     "07n0v3vqrjmvzsfzfc475blmxx21by8pppdqxkr3ai17ylaq5las")
    ("exec" "1.1.1" "af45ad8eaa9ccbb742e6c2967385a85becf6527a"
     "1s1d56scb53bmzczps5vrxmf0dv7h255hsw5ycxa6ar5zzb9288f")
    ("http-client" "2.2.3" "d1aa255c7fc5c25f2faebbb54d35bd98d9894150"
     "1lrdda40lgdy4smbb9by9nj1075zck1wi3h1vlkf45fdx01pqgk3")
    ("io" "1.1.3" "457303960f03375db6f033e214b9f90d79c3fe5c"
     "11gcj6zkcv2ypswrfmgf722m35f8gnpqly0j5pnh1cw93gdm7gb3")))

(define (actions-toolkit-source entry)
  (let ((name (car entry)) (commit (caddr entry)) (hash (cadddr entry)))
    (origin
      (method git-fetch)
      (uri (git-reference (url "https://github.com/actions/toolkit")
                          (commit commit)))
      (file-name (git-file-name (string-append "actions-" name)
                                (string-take commit 7)))
      (sha256 (base32 hash))
      (modules %strip-modules)
      ;; Only a few packages of this monorepo are built, but the whole tree
      ;; is the input, and packages/tool-cache carries a prebuilt Windows
      ;; 7zdec.exe.
      (snippet %strip-compiled-artefacts))))

(define (actions-toolkit-package entry)
  (match entry
    ((subdirectory version commit hash)
  (package
    (name (string-append "node-actions-" subdirectory))
    (version version)
    (source (actions-toolkit-source entry))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils) (ice-9 match) (ice-9 rdelim)
                  (ice-9 regex))
      #:builder
      #~(begin
          (use-modules (guix build utils) (ice-9 match) (ice-9 rdelim)
                       (ice-9 regex))
          (setenv "PATH"
                  (string-append (assoc-ref %build-inputs "esbuild") "/bin:"
                                 (assoc-ref %build-inputs "coreutils") "/bin"))
          (for-each
           (match-lambda
             ((subdirectory version commit hash)
              (let* ((source (assoc-ref %build-inputs "source"))
                     (name (string-append "@actions/" subdirectory))
                     (target (string-append #$output "/lib/" name))
                     (sources (find-files (string-append source "/packages/"
                                                         subdirectory "/src")
                                          "\\.ts$")))
                (when (null? sources)
                  (error "no sources for" name))
                (mkdir-p (string-append target "/lib"))
                (call-with-output-file (string-append target "/VERSION")
                  (lambda (port) (format port "~a~%" version)))
                ;; tsc emits one file per input and keeps the layout; esbuild
                ;; without --bundle does the same.
                (apply invoke "esbuild"
                       (append sources
                               (list "--platform=node" "--format=cjs"
                                     (string-append "--outdir=" target
                                                    "/lib")))))))
           (list '#$entry))
          ;; Same check as the vercel/ai builder: an identifier the upstream
          ;; bundler would have substituted must not survive into the output,
          ;; where it becomes a free variable that throws the first time that
          ;; code runs.
          (let ((leaked '()))
            (for-each
             (lambda (file)
               (call-with-input-file file
                 (lambda (port)
                   ;; Line at a time: (ice-9 textual-ports) is not available
                   ;; to this builder's Guile.
                   (let read-lines ()
                     (let ((line (read-line port)))
                       (unless (eof-object? line)
                         (let scan ((start 0))
                           (let ((m (string-match "__[A-Z][A-Z0-9_]*__"
                                                  (substring line start))))
                             (when m
                               (let ((s (match:substring m 0)))
                                 (unless (string=? s "__PURE__")
                                   (set! leaked
                                         (cons (string-append (basename file)
                                                              ": " s)
                                               leaked))))
                               (scan (+ start (match:end m))))))
                         (read-lines)))))))
             (find-files (string-append #$output "/lib") "\\.(js|mjs|cjs)$"))
            (unless (null? leaked)
              (error "unsubstituted build-time identifiers" (reverse leaked))))
          )))
    (native-inputs
     `(("coreutils" ,coreutils)
       ("esbuild" ,esbuild)
       ))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/actions/toolkit")
    (synopsis "GitHub Actions toolkit packages built from source")
    (description
     "This package builds the @code{@@actions/*} JavaScript packages that
opencode bundles, from the commit in actions/toolkit where that version was
set, replacing the built output published on npm.")
    (license license:expat)))))

(define-public node-actions-core
  (actions-toolkit-package (assoc "core" %actions-toolkit-packages)))
(define-public node-actions-exec
  (actions-toolkit-package (assoc "exec" %actions-toolkit-packages)))
(define-public node-actions-http-client
  (actions-toolkit-package (assoc "http-client" %actions-toolkit-packages)))
(define-public node-actions-io
  (actions-toolkit-package (assoc "io" %actions-toolkit-packages)))

(define %actions-from-source
  (list node-actions-core node-actions-exec node-actions-http-client
        node-actions-io))

;; The rest of the prebuilt-JavaScript packages come one or two at a time from
;; unrelated repositories, in the same two shapes: a bundle per format, or
;; per-file output preserving the source layout.  The entries below carry the
;; shape so one builder covers both.
(define %npm-from-source-packages
  ;; (NAME REPOSITORY SUBDIRECTORY VERSION COMMIT HASH MODE)
  ;; MODE is "transpile" (one output per input, as tsc emits) or a format
  ;; list for bundling, e.g. "esm:dist/index.mjs".
  '(("agent-base" "TooTallNate/proxy-agents" "packages/agent-base" "7.1.4"
     "5d3f71a2d021ec07b2b9156c543423e47053218c"
     "0f69gvxzkg5yq6grp5nx6w6c8wydia4w9lzc6dwplqp4dk0pcwid"
     "transpile:dist" "")
    ("https-proxy-agent" "TooTallNate/proxy-agents"
     "packages/https-proxy-agent" "7.0.6"
     "5d3f71a2d021ec07b2b9156c543423e47053218c"
     "0f69gvxzkg5yq6grp5nx6w6c8wydia4w9lzc6dwplqp4dk0pcwid"
     "transpile:dist" "")
    ("@agentclientprotocol/sdk" "agentclientprotocol/typescript-sdk" "."
     "0.14.1" "d32f20f3e5b9acac9db790905cbe319856903bc6"
     "106jfzh090lkkslny6am6aivkplf9bc73q58j7a5fs14b0p355xr"
     "transpile:dist" "")
    ("ai-gateway-provider" "cloudflare/ai" "packages/ai-gateway-provider"
     "2.3.1" "2cb3011eb9db9efafeb8fda7938bb15c6aec5002"
     "1a38y5p3a3ig0imms2g6vkvn30b92a1fw1l1sw8915k2h7fclfif"
     "cjs:dist/index.js,esm:dist/index.mjs" "")
    ("opentui-spinner" "msmps/opentui-spinner" "." "0.0.6"
     "85d3452aec2a7835998f56e5f4605e5397ffc6e0"
     "0jn1jgglvwh4hp777jb1a7sd3svzca6zy6dryiijlimfag7zl81k"
     "esm:dist/index.mjs" "")
    ("@hono/standard-validator" "honojs/middleware" "packages/standard-validator" "0.1.5"
     "565d0e3e89523da773a3570fd1084f3ed7e41036"
     "0qrvxs2vsj98hz607hjrn71nr1yrqc6xmlzh8mrqa7dpj0mh59k5"
     "esm:dist/index.js,cjs:dist/index.cjs" "")
    ("@solid-primitives/event-bus" "solidjs-community/solid-primitives" "packages/event-bus" "1.1.2"
     "776549fa169f7e0f0227572a34b6b00325603c70"
     "0v5sbkkz0zv2dngn5b6hb8qhc24h9baliy0vz3phwrfs02gm42v6"
     "esm:dist/index.js" "")
    ("@solid-primitives/scheduled" "solidjs-community/solid-primitives" "packages/scheduled" "1.5.2"
     "776549fa169f7e0f0227572a34b6b00325603c70"
     "0v5sbkkz0zv2dngn5b6hb8qhc24h9baliy0vz3phwrfs02gm42v6"
     "esm:dist/index.js" "")
    ("@solid-primitives/utils" "solidjs-community/solid-primitives" "packages/utils" "6.3.2"
     "776549fa169f7e0f0227572a34b6b00325603c70"
     "0v5sbkkz0zv2dngn5b6hb8qhc24h9baliy0vz3phwrfs02gm42v6"
     "esm:dist/index.js" "")
    ("@standard-community/standard-json" "standard-community/standard-json" "." "0.3.5"
     "d675e2d32a0e5e725b439cccf4b6f34f79516def"
     "036qs73sds4b1vzj2imdawm650przbiviiy4gyys6ggr2fgbfjdb"
     "esm:dist/index.js,cjs:dist/index.cjs" "")
    ("@standard-community/standard-openapi" "standard-community/standard-openapi" "." "0.2.9"
     "a884a43acbb86a3440dab483e5d9f0ad22d5a3aa"
     "0j5bz1nxr3389gmv13yjk67wp3cp1bc58y3ga1wjz21ddi0s4mlr"
     "esm:dist/index.js,cjs:dist/index.cjs" "")
    ("@vercel/oidc" "vercel/vercel" "packages/oidc" "3.1.0"
     "acab4d55fd9c3930ef72906aa59e74f8d1bcb406"
     "0rxsg2gjc4ipbawjf3vd6wgjcycnldng17ici0019q5lndplzmfz"
     "cjs:dist/index.js" "")
    ("bonjour-service" "onlxltd/bonjour-service" "." "1.3.0"
     "ff33e5678a5f3e1455267941af97a853f080ec85"
     "02zxrwkn3fz6b47is44f1awp3hsv9dcs4k2dchh6lcpb9c0h33kp"
     "cjs:dist/index.js" "")
    ("hono" "honojs/hono" "." "4.10.7"
     "b6f4bcdc2e991652cda78cb52626cb5c39406a82"
     "07cz3p5mlv16n20wi1mdq5ar93j1hh8hiyvglr32v70y96xrj6qp"
     "esm:dist/index.js" "")
    ("hono-openapi" "rhinobase/hono-openapi" "." "1.1.2"
     "0a66fad389dc94495e141b0b199cf76cd9cd4601"
     "0hx0d9kvhch26pl0f4m8bxkz630v4pwxv2gwkh65qq2pxb02z6af"
     "esm:dist/index.js,cjs:dist/index.cjs" "")
    ("quansync" "quansync-dev/quansync" "." "0.2.11"
     "abf2b51ef57b97b7e217eeb099e8c669f122416c"
     "0q5x3h05sfxj6ygkp2bf1j5a32dxycx24776319bqy1qfdvf5whl"
     "esm:dist/index.mjs,cjs:dist/index.cjs" "")
    ("zod-to-json-schema" "StefanTerdell/zod-to-json-schema" "." "3.25.1"
     "a706dd0c2f3b42d353138348c40f3beb614cc47e"
     "13wmb3car91pgrwac3rmi43jqv3307n31dfsg0r3fvijzrlhviah"
     "esm:dist/esm/index.js" "")
    ("diff" "kpdecker/jsdiff" "." "8.0.2"
     "93fb6331def3e1f69934bbb95394777d2c14194c"
     "0fg8qc2sf34nkj69hxdfxbd1f8aa1q3avky3vkjq9zc35kdi69h9"
     "esm:libesm/index.js,cjs:libcjs/index.js" "")
    ("gaxios" "googleapis/google-cloud-node-core" "packages/gaxios" "7.1.3"
     "4b4ec058af9e05fe623724b3b88b485ba46ab68a"
     "1habwnxbjzlr75sknh0qfijn8khji1s9j2qhbabf22anh9w52gir"
     "transpile:build/cjs/src:cjs,transpile:build/esm/src:esm" "")
    ("gcp-metadata" "googleapis/google-cloud-node-core" "packages/gcp-metadata" "8.1.2"
     "4b4ec058af9e05fe623724b3b88b485ba46ab68a"
     "1habwnxbjzlr75sknh0qfijn8khji1s9j2qhbabf22anh9w52gir"
     "transpile:build/src:cjs" "")
    ("google-logging-utils" "googleapis/google-cloud-node-core" "packages/logging-utils" "1.1.3"
     "4b4ec058af9e05fe623724b3b88b485ba46ab68a"
     "1habwnxbjzlr75sknh0qfijn8khji1s9j2qhbabf22anh9w52gir"
     "transpile:build/src:cjs" "")
    ("isexe" "isaacs/isexe" "." "3.1.1"
     "670b3b7b74cd4fe92071cfe296d4b5b3cde03791"
     "0pwh512lihsrj161g8yd5kf3vfqg2db5b8d98gj59z2mmia7majg"
     "transpile:dist/cjs:cjs,transpile:dist/mjs:esm" "")
    ("signal-exit" "tapjs/signal-exit" "." "4.1.0"
     "f0c30f36828d91b2bf373c4c474b88ead8cbca6d"
     "0xm2winzb3ja4y3i4p63bnv5dd1ijcji7xgvcqwm3cf81y96zzb0"
     "transpile:dist/cjs:cjs,transpile:dist/mjs:esm" "")
    ("@gitlab/gitlab-ai-provider"
     "gitlab.com/gitlab-org/editor-extensions/gitlab-ai-provider" "." "3.5.0"
     "366af36b0fb679fe57c65f2bf57a3548d866df6d"
     "1m5bqjzv8nygx18ngy7pidsvpvnl32v2x41l0vybiakar92gsrvh"
     "cjs:dist/index.js,esm:dist/index.mjs" "")
    ("@gitlab/opencode-gitlab-auth"
     "gitlab.com/gitlab-org/editor-extensions/opencode-gitlab-auth" "."
     "1.3.2" "1e0df8b32490289728cf51fc85d417b1746466ee"
     "1pxd3ab7krzbhwniakf452sqb6kya3x8s1rgl749n580qn03q3hr"
     "transpile:dist:esm" "")
    ;; The browser variant is left as published: opencode resolves the
    ;; "node" condition, and this builder always targets node.
    ("pkce-challenge" "crouchcd/pkce-challenge" "." "5.0.1"
     "9c797746c95a562ee7e6a347e5d04cef59265d9f"
     "04gf92d9qgb4wanmy69byznizxnbw3pqd7yis1mgs7m5a3v5p3cc"
     "esm:dist/index.node.js,cjs:dist/index.node.cjs" "")
    ;; No single entry point: the transpile mode compiles every .ts under
    ;; src/, as tsc does here.  Only the ESM tree is rebuilt -- some sources
    ;; use top-level await, which esbuild cannot emit as CommonJS -- so the
    ;; dist/cjs tree remains npm's.  Bun resolves the "import" condition, so
    ;; the tree opencode actually loads is the one built here.
    ("@modelcontextprotocol/sdk" "modelcontextprotocol/typescript-sdk" "."
     "1.25.2" "b392f02ffcf37c088dbd114fedf25026ec3913d3"
     "17r9hf7g0yp9psg3l5zjf8rhpcr6hld1b0wd35vp38c2yp20ys32"
     "transpile:dist/esm:esm" "")
    ;; tsup inlines @ai-sdk/provider and @ai-sdk/provider-utils, which are
    ;; devDependencies rather than runtime ones.  The last field aliases them
    ;; to this channel's own builds of those packages, so what gets inlined is
    ;; also from source.
    ("@openrouter/ai-sdk-provider" "OpenRouterTeam/ai-sdk-provider" "."
     "1.5.4" "d055b963a16e95beabecb5f880b4b0ec7b0b83c1"
     "0082gbdfxrsvn0jqzcfg0xdmxm870jy8hhskal8gxr39znm6c2h0"
     "cjs:dist/index.js,esm:dist/index.mjs"
     "+@ai-sdk/provider +@ai-sdk/provider-utils eventsource-parser \
@standard-schema/spec zod")
    ;; @opentui/core publishes only built output, with jimp, yoga-layout,
    ;; marked, diff and bun-ffi-structs inlined even though all five are
    ;; ordinary dependencies.  They are installed in opencode's tree at one
    ;; version each, so they can stay external and be resolved there.
    ;;
    ;; Only two of the four entry points are built.  src/index.ts never
    ;; reaches src/3d, so ./3d and ./testing -- which import three and
    ;; planck, neither of them declared anywhere in the manifest -- are left
    ;; as published; opencode does not use them.  parser.worker.ts imports
    ;; web-tree-sitter, a devDependency, but that one is hoisted into
    ;; opencode's tree, so marking it external resolves.
    ;;
    ;; The shared library beside this is built by libopentui, and the
    ;; tree-sitter grammars by tree-sitter-wasm-grammars.
    ("@opentui/core" "anomalyco/opentui" "packages/core" "0.1.77"
     "85e0582f95c22a792b320f6f8123dd1e433e2813"
     "1nfphzaq35qpd6n5hq30xjh6ywmyqas7nya34k8lzxakfd6vhk5n"
     "bun:.:src/index.ts,bun:.:src/lib/tree-sitter/parser.worker.ts"
     ;; bun:ffi is a runtime builtin; esbuild has no notion of it, and the
     ;; published bundle imports it too.
     "web-tree-sitter bun:ffi bun")
    ;; remeda's dist has one file per exported function, which looked like a
    ;; blocker, but its exports map has a single "." entry pointing at
    ;; dist/index.js and dist/index.cjs.  The per-function files exist for
    ;; bundlers that want finer tree-shaking and are not reachable by name,
    ;; so bundling src/index.ts into both formats is all opencode resolves.
    ;; type-fest is a dependency of types only; esbuild erases the imports.
    ;; As with ret, package.json in the tree says 2.0.0 and the tag is the
    ;; published version.
    ("remeda" "remeda/remeda" "packages/remeda" "2.26.0"
     "0fde627fc4ca8a19ab93f000fe931f22d4472338"
     "1yz24cq33p2zbzj89p5bwwhsr7yfknx70swqwslr1g9p9cmalv13"
     "esm:dist/index.js,cjs:dist/index.cjs" "")
    ;; Plain TypeScript compiled per-file by tsc.  Sources live under lib/
    ;; rather than src/, which is why the transpile mode probes for both.
    ;; package.json in the repository says 0.0.0-development because releases
    ;; are cut by semantic-release; the v0.5.0 tag is the published version.
    ("ret" "fent/ret.js" "" "0.5.0"
     "90a77fcb4e3869bc45b61d332b852948b5982637"
     "0jdvbb433r3zs81i5kcklhm763272hf3ahzv9rnm9b6va8b2m2rk"
     "transpile:dist:cjs" "")
    ;; One package of the vscode-languageserver-node monorepo.  esbuild takes
    ;; the common ancestor of its inputs as the root, so src/{common,node,
    ;; browser} land as lib/{common,node,browser} exactly as tsc -b emits
    ;; them, and ./lib/node/main.js resolves.
    ("vscode-jsonrpc" "microsoft/vscode-languageserver-node" "jsonrpc"
     "8.2.1" "f4da232d057401c5eeb59528aaa46f8d705f7cac"
     "116dvcdiv7zr5w9yw68j5jwjjl5yab2y0lj1klcdcg1qln4c5ari"
     "transpile:lib:cjs" "")
    ;; unbuild inlines wrap-ansi and is-unicode-supported, both
    ;; devDependencies.  Leaving them external does not work: bun's isolated
    ;; layout does not expose a package's devDependencies, and
    ;; is-unicode-supported is not installed anywhere in opencode's tree at
    ;; all.  The "^" tokens inline them from sources fetched for the purpose.
    ("@clack/core" "bombshell-dev/clack" "packages/core" "1.0.0-alpha.1"
     "d45408fd6a0a10b4f936a9c61fe02f6b3403a16d"
     "1vblp1hlbzw3jd9w245vbyf8cn567n8dfr2lgfyk0qf5y9m8mgsl"
     "esm:dist/index.mjs" "^wrap-ansi ^is-unicode-supported ^string-width ^strip-ansi ^ansi-styles ^ansi-regex ^eastasianwidth ^emoji-regex")
    ("@clack/prompts" "bombshell-dev/clack" "packages/prompts"
     "1.0.0-alpha.1" "282b39e637c3609bc707cc5c8fde81eb5f9832dc"
     "1fv1b7kch4h6ys0czzzm7ch3hn7qwf3ixjiil6c2l3dmi2d50z0f"
     "esm:dist/index.mjs" "^wrap-ansi ^is-unicode-supported ^string-width ^strip-ansi ^ansi-styles ^ansi-regex ^eastasianwidth ^emoji-regex")
    ))

;; Some packages inline a devDependency that is not installed anywhere in
;; opencode's tree -- it existed only on the publisher's machine.  These are
;; fetched so the inlining can be reproduced from source.  Both are
;; hand-written JavaScript with no build step, so the checkout is the build.
(define %npm-alias-sources
  ;; (KEY REPOSITORY VERSION COMMIT HASH ENTRY)
  '(("is-unicode-supported" "sindresorhus/is-unicode-supported" "1.3.0"
     "c80c691dde9e2fcfe3996810858c6672c8f35ad9"
     "1wjlbp54vjw401xliadgx8y46wz4z01amc3yi4qx3mqq2xw9xy2p"
     "index.js")
    ;; clack pins ^8.1.0; the copy installed in opencode's tree is 9.0.2, so
    ;; leaving this external would bundle a different major version.
    ("wrap-ansi" "chalk/wrap-ansi" "8.1.0"
     "115090266b0ebb1797032582de78d617575778ab"
     "1fvddxq8x8lpwh3cdglm6fg4k4y4g16swkv7n29i6106h0b310sf"
     "index.js")
    ;; wrap-ansi 8's own runtime closure.  bun's --alias is global to a
    ;; build, so listing these alongside it resolves its imports too; no
    ;; recursion is needed.  All are single-file and hand-written, with one
    ;; exception noted below.
    ("string-width" "sindresorhus/string-width" "5.1.2"
     "9f90691968ad356c807aaad1a5ed98d795749932"
     "003m711iqlnmpbqv4dd4v7b8jvyhwdapc5jig99h4nhyqw9ja76n"
     "index.js")
    ("strip-ansi" "chalk/strip-ansi" "7.0.1"
     "dd40fa7ced678f14dfb43eb9b62b8e7313fb7011"
     "1ywxyf35b7hwiczk5ra8ifvpr09c25z4g4vsf24viiyjaspc7zn7"
     "index.js")
    ("ansi-styles" "chalk/ansi-styles" "6.1.0"
     "cd0b0cb59337bfd7d3669b2d0fcde7ff661a83a6"
     "1bycbmdv06dp1dpk9wi00a1553bdng4npd79bxxfh30ghcpz3p5l"
     "index.js")
    ("ansi-regex" "chalk/ansi-regex" "6.0.1"
     "d908492e0070f26552fad1b25e339aff9011ae8b"
     "1m21cyhxz8p7qg132qy2mvv45kdz98k6adpp9974ix07zb507plm"
     "index.js")
    ;; This repository carries no tags; 0.2.0 is the version recorded in
    ;; package.json at this commit.  ^0.2.0 excludes the current 0.3.0.
    ("eastasianwidth" "komagata/eastasianwidth" "0.2.0"
     "af9ddb8f35a8936a907c772da4bc6a83f81e275c"
     "0cw9firl33kxb74b5n1cs9dwair3w0j4r6pgh3wn4knb2cdza4w6"
     "eastasianwidth.js")
    ;; The one link in this chain that is not hand-written: upstream commits
    ;; index.js as babel output with the Unicode sequences injected by
    ;; script/inject-sequences.js.  Regenerating it would pull in babel,
    ;; regexgen and @unicode/unicode-13.0.0, so this takes the file as
    ;; upstream's version control carries it rather than as npm ships it.
    ("emoji-regex" "mathiasbynens/emoji-regex" "9.2.2"
     "0ffa466d7ab65af304d03dddd3a92a2d8268e7ce"
     "1ydai75sgmm876jmmyhxsjdhhk4mmw1vkh8fr3486lgjwcgdknb2"
     "index.js")))

(define (npm-alias-source entry)
  (origin
    (method git-fetch)
    (uri (git-reference
          (url (string-append "https://github.com/" (cadr entry)))
          (commit (list-ref entry 3))))
    (file-name (git-file-name (string-append "npm-alias-" (car entry))
                              (caddr entry)))
    (sha256 (base32 (list-ref entry 4)))
    (modules %strip-modules)
    (snippet %strip-compiled-artefacts)))

(define (npm-from-source-origin entry)
  (let ((repository (cadr entry)) (commit (list-ref entry 4))
        (hash (list-ref entry 5)))
    (origin
      (method git-fetch)
      ;; A repository given as "host/owner/name" is taken literally; a bare
      ;; "owner/name" is GitHub, which most of these are.
      (uri (git-reference (url (if (string-prefix? "gitlab.com/" repository)
                                   (string-append "https://" repository)
                                   (string-append "https://github.com/"
                                                  repository)))
                          (commit commit)))
      (file-name (git-file-name (string-append "npm-src-"
                                               (string-map
                                                (lambda (c)
                                                  (if (or (char=? c #\/)
                                                          (char=? c #\@))
                                                      #\- c))
                                                (car entry)))
                                (string-take commit 7)))
      (sha256 (base32 hash))
      (modules %strip-modules)
      ;; Nothing compiled is ever wanted from these trees, and some are whole
      ;; monorepos: vercel's carries WebAssembly test fixtures.
      (snippet %strip-compiled-artefacts))))

(define %solid-js-version "1.9.10")
(define %solid-js-commit "bed16cc41eb0bd16531eb0495fa4fac1fa2d6a59")

(define solid-js-source
  (origin
    (method git-fetch)
    (uri (git-reference (url "https://github.com/solidjs/solid")
                        (commit %solid-js-commit)))
    (file-name (git-file-name "solid-js" %solid-js-version))
    (sha256
     (base32 "0xyki1s9y0mbjw78db5wwj97fb0053qzrzi5qnsh10q8qkggx9xa"))
    (modules %strip-modules)
    (snippet %strip-compiled-artefacts)))

;; solid's rollup configuration turns fifteen inputs into thirty bundles, an
;; ESM and a CommonJS one each.  What separates them beyond the format is a
;; textual substitution: rollup-plugin-replace rewrites the *string literal*
;; "_SOLID_DEV_" to true or false, with empty delimiters, and the library
;; reads it as `export const IS_DEV = "_SOLID_DEV_" as string | boolean'.
;; Left alone the literal is a non-empty string and therefore truthy, so a
;; bundle built without the substitution would silently run in development
;; mode.  esbuild's --define only rewrites identifiers, not literals, so the
;; source is copied once per variant and patched instead.
;;
;; VARIANT is "prod", "dev", or "none" for the bundles rollup builds without
;; the plugin at all -- the server and renderer entry points, which do not
;; reach that declaration.
;; solid's universal renderer re-exports dom-expressions, which rollup
;; resolves from the monorepo's node_modules -- the root package.json pins
;; 0.40.3.  Its sources import the specifier "rxcore", which rollup rewrites
;; with babel-plugin-transform-rename-import to solid's own web/src/core; the
;; alias has to point into the same variant copy so the development flag
;; stays consistent across the bundle.
(define dom-expressions-source
  (origin
    (method git-fetch)
    (uri (git-reference (url "https://github.com/ryansolid/dom-expressions")
                        (commit "f241fd111f65fcd81f61191056eda59235929536")))
    (file-name (git-file-name "dom-expressions" "0.40.3"))
    (sha256
     (base32 "1m0ncyibnm4cfyd65s5nrjd88cz82imj3xs7lna1mh5ljj9d3vvx"))
    (modules %strip-modules)
    (snippet %strip-compiled-artefacts)))

(define %solid-js-bundles
  ;; (VARIANT INPUT OUTPUT-BASE)
  '(("prod" "src/index.ts" "dist/solid")
    ("dev" "src/index.ts" "dist/dev")
    ("none" "src/server/index.ts" "dist/server")
    ("prod" "store/src/index.ts" "store/dist/store")
    ("dev" "store/src/index.ts" "store/dist/dev")
    ("none" "store/src/server.ts" "store/dist/server")
    ("prod" "universal/src/index.ts" "universal/dist/universal")
    ("dev" "universal/src/index.ts" "universal/dist/dev")))

;; The web, html and h entry points are left as published.  They compile
;; against dom-expressions, which rollup resolves from node_modules and which
;; would have to be fetched and built as well; opencode drives a terminal
;; through @opentui/solid's universal renderer and resolves none of them.

(define-public solid-js-from-source
  (package
    (name "solid-js-from-source")
    (version %solid-js-version)
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils) (ice-9 match) (ice-9 rdelim)
                  (srfi srfi-1))
      #:builder
      #~(begin
          (use-modules (guix build utils) (ice-9 match) (ice-9 rdelim)
                       (srfi srfi-1))
          (setenv "PATH"
                  (string-append (assoc-ref %build-inputs "esbuild") "/bin:"
                                 (assoc-ref %build-inputs "coreutils") "/bin"))
          (let* ((source (string-append (assoc-ref %build-inputs "source")
                                        "/packages/solid"))
                 (target (string-append #$output "/lib/solid-js")))
            ;; One copy per variant, patched in place.  Copying out of the
            ;; store also keeps store paths out of esbuild's annotations.
            (for-each
             (lambda (variant)
               (let ((directory (string-append (getcwd) "/" variant)))
                 (copy-recursively source directory)
                 (invoke "chmod" "-R" "u+w" directory)
                 (unless (string=? variant "none")
                   (let ((value (if (string=? variant "dev") "true" "false")))
                     (substitute* (find-files directory "\\.ts$")
                       (("\"_SOLID_DEV_\"") value)
                       (("\"_DX_DEV_\"") value))))))
             '("none" "prod" "dev"))
            ;; Copied for the same reason as the variants: esbuild records
            ;; the path of every module it reads, and a store path here would
            ;; become a runtime reference of opencode.
            (copy-recursively (string-append
                               (assoc-ref %build-inputs "dom-expressions")
                               "/packages/dom-expressions")
                              (string-append (getcwd) "/dom-expressions"))
            (invoke "chmod" "-R" "u+w"
                    (string-append (getcwd) "/dom-expressions"))
            (mkdir-p target)
            (call-with-output-file (string-append target "/VERSION")
              (lambda (port) (format port "~a~%" #$%solid-js-version)))
            (for-each
             (match-lambda
               ((variant input output-base)
                (let ((entry (string-append (getcwd) "/" variant "/" input)))
                  (unless (file-exists? entry)
                    (error "no such solid entry" input))
                  (for-each
                   (match-lambda
                     ((format . extension)
                      (let ((output (string-append target "/" output-base
                                                   extension)))
                        (mkdir-p (dirname output))
                        (apply invoke "esbuild" entry "--bundle"
                               ;; rollup builds these for no particular host;
                               ;; every dependency below is external there
                               ;; too, so nothing is left unresolved.
                               "--platform=neutral"
                               (string-append "--format=" format)
                               (string-append "--outfile=" output)
                               (string-append "--alias:dom-expressions="
                                              (getcwd) "/dom-expressions")
                               (string-append
                                "--alias:rxcore=" (getcwd) "/" variant
                                "/web/src/core")
                               (append-map
                                (lambda (d)
                                  (list (string-append "--external:" d)))
                                '("solid-js" "solid-js/web" "solid-js/store"
                                  "seroval" "seroval-plugins"
                                  "seroval-plugins/web" "stream"
                                  "csstype"))))))
                   '(("cjs" . ".cjs") ("esm" . ".js"))))))
             '#$%solid-js-bundles)
            ;; The literal must not survive into a patched variant: that is
            ;; the whole point of the substitution above.
            (for-each
             (match-lambda
               ((variant input output-base)
                (unless (string=? variant "none")
                  (for-each
                   (lambda (extension)
                     (let ((file (string-append target "/" output-base
                                                extension)))
                       (call-with-input-file file
                         (lambda (port)
                           (let loop ()
                             (let ((line (read-line port)))
                               (unless (eof-object? line)
                                 (when (string-contains line "_SOLID_DEV_")
                                   (error "unsubstituted flag in" file))
                                 (loop))))))))
                   '(".cjs" ".js")))))
             '#$%solid-js-bundles)))))
    (native-inputs
     `(("esbuild" ,esbuild)
       ("coreutils" ,coreutils)))
    (inputs `(("source" ,solid-js-source)
              ("dom-expressions" ,dom-expressions-source)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://www.solidjs.com/")
    (synopsis "Solid reactive JavaScript library, built from source")
    (description
     "This package builds @code{solid-js} from its TypeScript sources,
reproducing the thirty bundles its rollup configuration produces, including
the textual substitution of the development flag that separates the
production, development and server builds.")
    (license license:expat)))

;; Each dependency is packaged separately: one derivation per npm package,
;; buildable and substitutable on its own.  The build logic is shared here
;; rather than repeated, but the packages below are ordinary definitions.
(define (npm-name->package-name name)
  ;; "@clack/core" becomes "node-clack-core".
  (string-append "node-"
                 (string-map (lambda (c) (if (char=? c #\/) #\- c))
                             (string-filter (lambda (c) (not (char=? c #\@)))
                                            name))))

(define (npm-source-package entry)
  (match entry
    ((name repository subdirectory version commit hash mode aliases)
  (package
    (name (npm-name->package-name name))
    (version version)
    (source (npm-from-source-origin entry))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils) (ice-9 match) (ice-9 popen)
                  (ice-9 rdelim) (ice-9 regex)
                  (srfi srfi-1) (srfi srfi-13))
      #:builder
      #~(begin
          (use-modules (guix build utils) (ice-9 match) (ice-9 popen)
                       (ice-9 rdelim) (ice-9 regex)
                       (srfi srfi-1) (srfi srfi-13))
          (setenv "PATH"
                  (string-append (assoc-ref %build-inputs "bun") "/bin:"
                                 (assoc-ref %build-inputs "esbuild") "/bin:"
                                 (assoc-ref %build-inputs "node") "/bin:"
                                 (assoc-ref %build-inputs "coreutils") "/bin"))
          ;; Copied out of the store for the same reason as the package
          ;; sources below: an aliased path is recorded verbatim in the
          ;; output.
          (for-each
           (lambda (entry)
             (let ((to (string-append (getcwd) "/aliases/" (car entry))))
               (mkdir-p (dirname to))
               (copy-recursively (assoc-ref %build-inputs
                                            (string-append "alias-"
                                                           (car entry)))
                                 to)))
           '#$%npm-alias-sources)
          (for-each
           (match-lambda
             ((name repository subdirectory version commit hash mode aliases)
              (let* ((source (assoc-ref %build-inputs "source"))
                     (store-directory (string-append source "/"
                                                     subdirectory))
                     ;; esbuild records every module's path in the __esm
                     ;; annotation it emits, and those annotations survive
                     ;; into opencode's compiled binary as plain text.  Run
                     ;; it on a copy inside the build directory: a store path
                     ;; here would make this checkout a runtime reference of
                     ;; opencode.
                     ;; The copy is made here rather than in the body below
                     ;; because `externals' runs node against this manifest
                     ;; while the bindings are still being evaluated.
                     (package-directory
                      (let ((d (string-append (getcwd) "/build/" name)))
                        (mkdir-p (dirname d))
                        (copy-recursively store-directory d)
                        (invoke "chmod" "-R" "u+w" d)
                        d))
                     (target (string-append #$output "/lib/" name))
                     (entry (string-append package-directory "/src/index.ts"))
                     ;; Tokens starting with "+" are aliased to this channel's
                     ;; own build of that package, matching what the upstream
                     ;; bundler inlines; the rest become extra externals,
                     ;; needed because an inlined package brings its own
                     ;; imports along.
                     (alias-flags
                      (if (string-null? aliases)
                          '()
                          (let ()
                            (append-map
                             (lambda (d)
                               (cond
                                ((string-prefix? "+" d)
                                 ;; Each vercel package is its own input now,
                                 ;; registered under its npm name.
                                 (let ((n (string-drop d 1)))
                                   (list (string-append
                                          "--alias:" n "="
                                          (assoc-ref %build-inputs
                                                     (string-append "vercel-"
                                                                    n))
                                          "/lib/" n "/dist/index.mjs"))))
                                ((string-prefix? "^" d)
                                 ;; A source fetched purely to be inlined.
                                 (let* ((n (string-drop d 1))
                                        (spec (assoc n
                                                     '#$%npm-alias-sources)))
                                   (unless spec
                                     (error "no alias source for" n))
                                   (list (string-append
                                          "--alias:" n "="
                                          (getcwd) "/aliases/" n
                                          "/" (list-ref spec 5)))))
                                (else
                                 (list (string-append "--external:" d)
                                       (string-append "--external:" d
                                                      "/*")))))
                             (string-split aliases #\space)))))
                     ;; Node reads the manifest; keeping dependencies external
                     ;; is what the upstream bundlers do.
                     (externals
                      (let ((port (open-pipe*
                                   OPEN_READ "node" "-e"
                                   (string-append
                                    "const m=require('" package-directory
                                    "/package.json');"
                                    "console.log([...Object.keys(m.dependencies||{}),"
                                    "...Object.keys(m.peerDependencies||{})].join(' '))"))))
                        (let ((line (read-line port)))
                          (close-pipe port)
                          (if (or (eof-object? line)
                                  (string-null? (string-trim line)))
                              '()
                              (append-map
                               (lambda (d)
                                 (list (string-append "--external:" d)
                                       (string-append "--external:" d "/*")))
                               (string-split (string-trim-both line)
                                             #\space)))))))
                ;; opentui imports the tree-sitter grammars as file assets
                ;; beside the module that loads them.  The origin snippet
                ;; drops the prebuilt copies the repository vendors, so put
                ;; the ones built from source where that import looks.
                (when (string=? name "@opentui/core")
                  (for-each
                   (lambda (language)
                     (let ((to (string-append package-directory
                                              "/src/lib/tree-sitter/assets/"
                                              language)))
                       (mkdir-p to)
                       (copy-file
                        (string-append (assoc-ref %build-inputs
                                                  "tree-sitter-grammars")
                                       "/lib/tree-sitter-" language ".wasm")
                        (string-append to "/tree-sitter-" language ".wasm"))))
                   '("javascript" "typescript" "markdown" "markdown_inline"
                     "zig")))
                (mkdir-p target)
                (call-with-output-file (string-append target "/VERSION")
                  (lambda (port) (format port "~a~%" version)))
                ;; MODE is a comma-separated list.  "transpile:<dir>" or
                ;; "transpile:<dir>:<format>" emits one output per input, as
                ;; tsc does; "<format>:<file>" emits a bundle.  A package may
                ;; mix them: several ship CommonJS and ESM in sibling trees.
                (for-each
                 (lambda (part)
                   (if (string-prefix? "bun:" part)
                       ;; esbuild rejects `with { type: "file" }' outright and
                       ;; opentui imports its grammars that way, so this
                       ;; package is bundled by bun, which is what upstream
                       ;; builds it with.  Emitted assets land beside the
                       ;; output and are installed along with it.
                       (let* ((fields (string-split part #\:))
                              (outdir (string-append target "/"
                                                     (cadr fields)))
                              (source-entry (string-append package-directory
                                                           "/"
                                                           (caddr fields))))
                         (unless (file-exists? source-entry)
                           (error "no entry for" name))
                         (mkdir-p outdir)
                         (apply invoke "bun" "build" source-entry
                                "--target=bun" "--format=esm"
                                (string-append "--outdir=" outdir)
                                ;; bun spells an external as a separate
                                ;; argument rather than esbuild's colon form,
                                ;; and has no use for the "name/*" variants.
                                (append-map
                                 (lambda (flag)
                                   (if (and (string-prefix? "--external:"
                                                            flag)
                                            (not (string-suffix? "/*" flag)))
                                       (list "--external"
                                             (string-drop flag 11))
                                       '()))
                                 (append externals alias-flags))))
                   (if (string-prefix? "transpile:" part)
                       (let* ((rest (string-drop part 10))
                              (colon (string-index rest #\:))
                              (outdir (string-append
                                       target "/"
                                       (if colon (substring rest 0 colon)
                                           rest)))
                              (format (if colon
                                          (substring rest (+ 1 colon))
                                          "cjs"))
                              ;; Most packages keep TypeScript under src/,
                              ;; a few under lib/.
                              (srcdir (let ((s (string-append
                                                package-directory "/src")))
                                        (if (file-exists? s) s
                                            (string-append
                                             package-directory "/lib"))))
                              ;; Tests and examples sit beside the sources in
                              ;; several of these trees but are excluded by
                              ;; the package's own tsconfig, so upstream does
                              ;; not ship them.  They are also the only files
                              ;; that draw esbuild warnings, since they use
                              ;; import.meta under CommonJS and call test
                              ;; helpers that are absent at run time.
                              (sources
                               (filter
                                (lambda (f)
                                  (let ((parts (string-split f #\/)))
                                    (not (or (any (lambda (d)
                                                    (member d parts))
                                                  '("test" "tests" "__tests__"
                                                    "examples"))
                                             (string-suffix? ".test.ts" f)
                                             (string-suffix? ".spec.ts" f)))))
                                (find-files srcdir "\\.ts$"))))
                         (when (null? sources) (error "no sources for" name))
                         (mkdir-p outdir)
                         (apply invoke "esbuild"
                                (append sources
                                        (list "--platform=node"
                                              (string-append "--format="
                                                             format)
                                              (string-append "--outdir="
                                                             outdir)))))
                       (let* ((fields (string-split part #\:))
                              (format (car fields))
                              (output (string-append target "/"
                                                     (cadr fields)))
                              ;; An optional third field names the entry
                              ;; point, for packages that publish more than
                              ;; one.  Without it the default src/index.ts
                              ;; applies.
                              (entry (if (null? (cddr fields))
                                         entry
                                         (string-append package-directory "/"
                                                        (caddr fields)))))
                         (unless (file-exists? entry)
                           (error "no entry for" name))
                         (mkdir-p (dirname output))
                         (apply invoke "esbuild" entry "--bundle"
                                "--platform=node"
                                (string-append
                                 "--define:__PACKAGE_VERSION__=\"" version
                                 "\"")
                                (string-append "--format=" format)
                                (string-append "--outfile=" output)
                                (append externals alias-flags))))))
                 (string-split mode #\,)))))
           (list '#$entry))
          ;; An identifier the upstream bundler would have substituted must
          ;; not survive into the output, where it becomes a free variable
          ;; that throws the first time that code runs.
          (let ((leaked '()))
            (for-each
             (lambda (file)
               (call-with-input-file file
                 (lambda (port)
                   ;; Line at a time: (ice-9 textual-ports) is unavailable to
                   ;; this builder's Guile.
                   (let read-lines ()
                     (let ((line (read-line port)))
                       (unless (eof-object? line)
                         (let scan ((start 0))
                           (let ((m (string-match "__[A-Z][A-Z0-9_]*__"
                                                  (substring line start))))
                             (when m
                               (let ((s (match:substring m 0)))
                                 (unless (string=? s "__PURE__")
                                   (set! leaked
                                         (cons (string-append (basename file)
                                                              ": " s)
                                               leaked))))
                               (scan (+ start (match:end m))))))
                         (read-lines)))))))
             (find-files (string-append #$output "/lib") "\\.(js|mjs|cjs)$"))
            (unless (null? leaked)
              (error "unsubstituted build-time identifiers"
                     (reverse leaked)))))))
    (native-inputs
     `(("coreutils" ,coreutils)
       ("esbuild" ,esbuild)
       ("node" ,node)
       ("bun" ,bun-from-source)
       ("tree-sitter-grammars" ,tree-sitter-wasm-grammars)
       ,@(map (lambda (token)
                (let ((n (string-drop token 1)))
                  (list (string-append "vercel-" n)
                        (vercel-ai-package
                         (string-drop n (string-length "@ai-sdk/"))))))
              (filter (lambda (t) (string-prefix? "+" t))
                      (string-split aliases #\space)))
       ,@(map (lambda (entry)
                (list (string-append "alias-" (car entry))
                      (npm-alias-source entry)))
              %npm-alias-sources)
       ))
    (supported-systems '("x86_64-linux"))
    (home-page "https://guix.gnu.org")
    (synopsis "npm package built from source")
    (description
     "This package builds an npm dependency of opencode from its upstream
sources, replacing the built output published on npm.")
    (license license:expat)))))


;; One package per dependency: each is its own derivation.
(define-public node-agent-base
  (npm-source-package (assoc "agent-base" %npm-from-source-packages)))

(define-public node-https-proxy-agent
  (npm-source-package (assoc "https-proxy-agent" %npm-from-source-packages)))

(define-public node-agentclientprotocol-sdk
  (npm-source-package (assoc "@agentclientprotocol/sdk" %npm-from-source-packages)))

(define-public node-ai-gateway-provider
  (npm-source-package (assoc "ai-gateway-provider" %npm-from-source-packages)))

(define-public node-opentui-spinner
  (npm-source-package (assoc "opentui-spinner" %npm-from-source-packages)))

(define-public node-hono-standard-validator
  (npm-source-package (assoc "@hono/standard-validator" %npm-from-source-packages)))

(define-public node-solid-primitives-event-bus
  (npm-source-package (assoc "@solid-primitives/event-bus" %npm-from-source-packages)))

(define-public node-solid-primitives-scheduled
  (npm-source-package (assoc "@solid-primitives/scheduled" %npm-from-source-packages)))

(define-public node-solid-primitives-utils
  (npm-source-package (assoc "@solid-primitives/utils" %npm-from-source-packages)))

(define-public node-standard-community-standard-json
  (npm-source-package (assoc "@standard-community/standard-json" %npm-from-source-packages)))

(define-public node-standard-community-standard-openapi
  (npm-source-package (assoc "@standard-community/standard-openapi" %npm-from-source-packages)))

(define-public node-vercel-oidc
  (npm-source-package (assoc "@vercel/oidc" %npm-from-source-packages)))

(define-public node-bonjour-service
  (npm-source-package (assoc "bonjour-service" %npm-from-source-packages)))

(define-public node-hono
  (npm-source-package (assoc "hono" %npm-from-source-packages)))

(define-public node-hono-openapi
  (npm-source-package (assoc "hono-openapi" %npm-from-source-packages)))

(define-public node-quansync
  (npm-source-package (assoc "quansync" %npm-from-source-packages)))

(define-public node-zod-to-json-schema
  (npm-source-package (assoc "zod-to-json-schema" %npm-from-source-packages)))

(define-public node-diff
  (npm-source-package (assoc "diff" %npm-from-source-packages)))

(define-public node-gaxios
  (npm-source-package (assoc "gaxios" %npm-from-source-packages)))

(define-public node-gcp-metadata
  (npm-source-package (assoc "gcp-metadata" %npm-from-source-packages)))

(define-public node-google-logging-utils
  (npm-source-package (assoc "google-logging-utils" %npm-from-source-packages)))

(define-public node-isexe
  (npm-source-package (assoc "isexe" %npm-from-source-packages)))

(define-public node-signal-exit
  (npm-source-package (assoc "signal-exit" %npm-from-source-packages)))

(define-public node-gitlab-gitlab-ai-provider
  (npm-source-package (assoc "@gitlab/gitlab-ai-provider" %npm-from-source-packages)))

(define-public node-gitlab-opencode-gitlab-auth
  (npm-source-package (assoc "@gitlab/opencode-gitlab-auth" %npm-from-source-packages)))

(define-public node-pkce-challenge
  (npm-source-package (assoc "pkce-challenge" %npm-from-source-packages)))

(define-public node-modelcontextprotocol-sdk
  (npm-source-package (assoc "@modelcontextprotocol/sdk" %npm-from-source-packages)))

(define-public node-openrouter-ai-sdk-provider
  (npm-source-package (assoc "@openrouter/ai-sdk-provider" %npm-from-source-packages)))

(define-public node-opentui-core
  (npm-source-package (assoc "@opentui/core" %npm-from-source-packages)))

(define-public node-remeda
  (npm-source-package (assoc "remeda" %npm-from-source-packages)))

(define-public node-ret
  (npm-source-package (assoc "ret" %npm-from-source-packages)))

(define-public node-vscode-jsonrpc
  (npm-source-package (assoc "vscode-jsonrpc" %npm-from-source-packages)))

(define-public node-clack-core
  (npm-source-package (assoc "@clack/core" %npm-from-source-packages)))

(define-public node-clack-prompts
  (npm-source-package (assoc "@clack/prompts" %npm-from-source-packages)))

;; Convenience list for opencode's inputs and substitution roots.
(define %javascript-from-source
  (list node-agent-base
        node-https-proxy-agent
        node-agentclientprotocol-sdk
        node-ai-gateway-provider
        node-opentui-spinner
        node-hono-standard-validator
        node-solid-primitives-event-bus
        node-solid-primitives-scheduled
        node-solid-primitives-utils
        node-standard-community-standard-json
        node-standard-community-standard-openapi
        node-vercel-oidc
        node-bonjour-service
        node-hono
        node-hono-openapi
        node-quansync
        node-zod-to-json-schema
        node-diff
        node-gaxios
        node-gcp-metadata
        node-google-logging-utils
        node-isexe
        node-signal-exit
        node-gitlab-gitlab-ai-provider
        node-gitlab-opencode-gitlab-auth
        node-pkce-challenge
        node-modelcontextprotocol-sdk
        node-openrouter-ai-sdk-provider
        node-opentui-core
        node-remeda
        node-ret
        node-vscode-jsonrpc
        node-clack-core
        node-clack-prompts))

(define opencode-source
  (local-git-checkout-or-empty %opencode-source-directory
                               "opencode-source"))

(define opencode-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/.guix-node-modules")
                            "opencode-node-modules"))

(define models-dev-api-json
  (local-json-or-empty-object %opencode-models-dev-api-json
                              "models-dev-api.json"))

(define app-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/app/node_modules")
                            "app-node-modules"))

(define enterprise-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/enterprise/node_modules")
                            "enterprise-node-modules"))

(define function-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/function/node_modules")
                            "function-node-modules"))

(define plugin-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/plugin/node_modules")
                            "plugin-node-modules"))

(define script-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/script/node_modules")
                            "script-node-modules"))

(define sdk-js-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/sdk/js/node_modules")
                            "sdk-js-node-modules"))

(define slack-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/slack/node_modules")
                            "slack-node-modules"))

(define ui-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/ui/node_modules")
                            "ui-node-modules"))

(define util-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/util/node_modules")
                            "util-node-modules"))

(define web-node-modules
  (local-directory-or-empty (string-append %opencode-source-directory
                                           "/packages/web/node_modules")
                            "web-node-modules"))

(define-public opencode
  (package
    (name "opencode")
    (version "1.1.58")
    (source opencode-source)
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (guix build bun-build-system)
                  (ice-9 ftw)
                  (ice-9 regex)
                  (ice-9 textual-ports)
                  (srfi srfi-1))
      #:imported-modules `(,@%default-gnu-imported-modules
                           (json)
                           (json builder)
                           (json parser)
                           (json record)
                           (guix build bun-build-system))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'patch-generated-file-shebangs)
          (add-after 'unpack 'restore-node-modules
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((cache (assoc-ref inputs "node-modules"))
                     (root-modules (string-append cache "/node_modules"))
                     (desktop-modules
                      (string-append cache "/packages/desktop/node_modules"))
                     (opencode-modules
                      (string-append cache "/packages/opencode/node_modules")))
                ;; This tree was symlinked from the store to keep the build
                ;; directory small, but bun resolves every module to its
                ;; realpath and esbuild records that path in the __esm
                ;; annotation it emits for each module.  Those annotations
                ;; survive into the compiled binary as plain text, Guix scans
                ;; output for store hashes, and the whole 2.6 GiB cache
                ;; therefore became a *runtime* reference of opencode.  Copy
                ;; it so the recorded paths stay inside the build directory.
                (when (file-exists? "node_modules")
                  (delete-file-recursively "node_modules"))
                (invoke "cp" "-a" root-modules "node_modules")
                (invoke "chmod" "-R" "u+w" "node_modules")
                ;; opencode's own node_modules must remain writable because we
                ;; graft missing hoisted deps below.
                (when (file-exists? "packages/opencode/node_modules")
                  (delete-file-recursively "packages/opencode/node_modules"))
                (mkdir-p "packages/opencode")
                (invoke "cp" "-a" opencode-modules "packages/opencode/node_modules")
                (invoke "chmod" "-R" "u+w" "packages/opencode/node_modules")
                ;; Desktop modules are referenced by the workspace lockfile.
                (when (file-exists? desktop-modules)
                  (when (file-exists? "packages/desktop/node_modules")
                    (delete-file-recursively "packages/desktop/node_modules"))
                  (mkdir-p "packages/desktop")
                  (symlink desktop-modules "packages/desktop/node_modules")))
              (when (file-exists? "packages/sdk/js/node_modules")
                (delete-file-recursively "packages/sdk/js/node_modules"))
              (mkdir-p "packages/sdk/js")
              (symlink (assoc-ref inputs "sdk-js-node-modules")
                       "packages/sdk/js/node_modules")
              ;; Bundled into the binary as well, so it leaks store paths
              ;; exactly as the root tree does; the rest below are used by
              ;; workspace packages that the CLI does not bundle.
              (when (file-exists? "packages/util/node_modules")
                (delete-file-recursively "packages/util/node_modules"))
              (mkdir-p "packages/util")
              (invoke "cp" "-a" (assoc-ref inputs "util-node-modules")
                      "packages/util/node_modules")
              (invoke "chmod" "-R" "u+w" "packages/util/node_modules")
              (restore-input-symlink-tree
               inputs
               '(("packages/app/node_modules" . "app-node-modules")
                 ("packages/enterprise/node_modules" . "enterprise-node-modules")
                 ("packages/function/node_modules" . "function-node-modules")
                 ("packages/plugin/node_modules" . "plugin-node-modules")
                 ("packages/script/node_modules" . "script-node-modules")
                 ("packages/slack/node_modules" . "slack-node-modules")
                 ("packages/ui/node_modules" . "ui-node-modules")
                 ("packages/web/node_modules" . "web-node-modules")))
              ;; Bun's workspace lockfile hoists many deps under
              ;; node_modules/.bun/node_modules. Symlink any missing package
              ;; entries into opencode's package-local node_modules, including
              ;; missing scoped members.
              (when (file-exists? "node_modules/.bun/node_modules")
                (invoke
                 "bash" "-c"
                 "set -euo pipefail
src=\"$PWD/node_modules/.bun/node_modules\"
dst=\"$PWD/packages/opencode/node_modules\"
for entry in \"$src\"/*; do
  [ -e \"$entry\" ] || continue
  name=$(basename \"$entry\")
  dst_entry=\"$dst/$name\"
  if [ ! -e \"$dst_entry\" ]; then
    ln -s \"$entry\" \"$dst_entry\"
    continue
  fi
  if [[ \"$name\" == @* ]] && [ -d \"$entry\" ] && [ -d \"$dst_entry\" ] && [ ! -L \"$dst_entry\" ]; then
    for scoped in \"$entry\"/*; do
      [ -e \"$scoped\" ] || continue
      scoped_name=$(basename \"$scoped\")
      [ -e \"$dst_entry/$scoped_name\" ] || ln -s \"$scoped\" \"$dst_entry/$scoped_name\"
    done
  fi
done"))
              ;; Recreate workspace links expected by opencode's local build.
              (mkdir-p "packages/opencode/node_modules/@opencode-ai")
              (for-each
               (lambda (entry)
                 (let ((name (car entry))
                       (source (cadr entry)))
                   (let ((target
                          (string-append
                           "packages/opencode/node_modules/@opencode-ai/" name)))
                     (when (file-exists? target)
                       (invoke "rm" "-rf" target))
                     (symlink
                      (string-append (getcwd) "/" source)
                      target))))
               '(("script" "packages/script")
                 ("plugin" "packages/plugin")
                 ("util" "packages/util")
                 ("sdk" "packages/sdk/js")))
              ;; `packages/opencode/script/build.ts` imports @opentui/solid,
              ;; which pulls Babel deps that Bun hoists under
              ;; node_modules/.bun/node_modules. Mirror them directly at the
              ;; package level so Bun can resolve every transitive helper.
              (when (file-exists? "node_modules/.bun/node_modules/@babel")
                (when (file-exists? "packages/opencode/node_modules/@babel")
                  (delete-file-recursively "packages/opencode/node_modules/@babel"))
                (invoke "cp" "-a"
                        "node_modules/.bun/node_modules/@babel"
                        "packages/opencode/node_modules/@babel")
                (invoke "chmod" "-R" "u+w" "packages/opencode/node_modules/@babel"))
              (when (file-exists?
                     "node_modules/.bun/node_modules/babel-preset-solid")
                (when (file-exists?
                       "packages/opencode/node_modules/babel-preset-solid")
                  (delete-file-recursively
                   "packages/opencode/node_modules/babel-preset-solid"))
                (symlink
                 (string-append
                  (getcwd)
                  "/node_modules/.bun/node_modules/babel-preset-solid")
                 "packages/opencode/node_modules/babel-preset-solid"))))
          (add-after 'restore-node-modules 'use-source-built-libraries
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Two npm dependencies dlopen() native libraries that npm ships
              ;; prebuilt: @opentui/core (the TUI renderer, Zig) and bun-pty
              ;; (the pseudoterminal, Rust).  Swap in the ones built from
              ;; source.  `bun build --compile' embeds them as file assets, so
              ;; this has to happen before the build phase.
              ;;
              ;; node_modules is a symlink into the store, so materialise each
              ;; directory on the way as a real directory of symlinks to what
              ;; it shadowed, leaving the rest of the tree untouched.
              (define (unshadow directory)
                (when (and (file-exists? directory)
                           (eq? 'symlink (stat:type (lstat directory))))
                  (let ((target (readlink directory)))
                    (delete-file directory)
                    (mkdir directory)
                    (for-each
                     (lambda (entry)
                       (symlink (string-append target "/" entry)
                                (string-append directory "/" entry)))
                     (scandir target
                              (lambda (name)
                                (not (member name '("." "..")))))))))
              (define (materialize directory)
                ;; Unshadow the parents, then copy DIRECTORY outright.  Bun
                ;; resolves a module to its realpath and loads sibling assets
                ;; relative to that, so a package left as a symlink would send
                ;; its own `require' straight back to the store copy and the
                ;; replacement below would have no effect.
                (let loop ((parts (string-split (dirname directory) #\/))
                           (prefix #f))
                  (unless (null? parts)
                    (let ((here (if prefix
                                    (string-append prefix "/" (car parts))
                                    (car parts))))
                      (unshadow here)
                      (loop (cdr parts) here))))
                ;; A package can be reached through a chain of symlinks --
                ;; workspace copy to .bun entry to store -- so resolve the
                ;; whole chain rather than one level.
                (let ((real (canonicalize-path directory)))
                  (when (string-prefix? "/gnu/store/" real)
                    (if (eq? 'symlink (stat:type (lstat directory)))
                        (delete-file directory)
                        (delete-file-recursively directory))
                    (copy-recursively real directory)))
                ;; copy-recursively keeps the store's read-only modes, on
                ;; directories as well as files, so nothing inside could be
                ;; replaced afterwards.
                (invoke "chmod" "-R" "u+w" directory))
              (define (install-library! directory relative library)
                ;; The prebuilt file is not here to overwrite: compiled
                ;; artefacts are filtered out of the node_modules inputs.
                ;; Guard on the package directory instead, so a layout change
                ;; upstream is still an error rather than a silent no-op.
                (unless (file-exists? directory)
                  (error "no such package directory" directory))
                (materialize directory)
                (let ((destination (string-append directory "/" relative)))
                  (mkdir-p (dirname destination))
                  (when (file-exists? destination)
                    (delete-file destination))
                  (copy-file library destination)
                  (chmod destination #o555)))
              (for-each
               (lambda (spec)
                 (let ((library (search-input-file inputs (car spec)))
                       (relative (cadr spec))
                       ;; Bun's isolated install layout keeps one copy per
                       ;; dependent, and which one is reached depends on the
                       ;; importer.
                       (directories (cddr spec)))
                   (for-each (lambda (directory)
                               (install-library! directory relative library))
                             directories)
                   ;; Whether every reachable copy was replaced is checked
                   ;; after the build, by comparing bytes against the compiled
                   ;; binary -- the only test that reflects what Bun actually
                   ;; embedded.
                   #t))
               (list
                (list "/lib/libopentui.so" "libopentui.so"
                      "node_modules/.bun/node_modules/@opentui/core-linux-x64"
                      "node_modules/.bun/@opentui+core-linux-x64@0.1.77/node_modules/@opentui/core-linux-x64"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/@opentui/core-linux-x64")
                (list "/lib/librust_pty.so"
                      "rust-pty/target/release/librust_pty.so"
                      "node_modules/.bun/node_modules/bun-pty"
                      "node_modules/.bun/bun-pty@0.4.8/node_modules/bun-pty"
                      "packages/opencode/node_modules/bun-pty")
                (list "/lib/tree-sitter-bash.wasm"
                      "tree-sitter-bash.wasm"
                      "node_modules/.bun/node_modules/tree-sitter-bash"
                      "node_modules/.bun/tree-sitter-bash@0.25.0/node_modules/tree-sitter-bash"
                      "packages/opencode/node_modules/tree-sitter-bash")
                (list "/lib/tree-sitter-javascript.wasm"
                      "assets/javascript/tree-sitter-javascript.wasm"
                      "node_modules/.bun/opentui-spinner@0.0.6+fbc73c270e220e29/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+solid@0.1.77+eb3cc3a936ac23ec/node_modules/@opentui/core"
                      "node_modules/.bun/node_modules/@opentui/core"
                      "packages/opencode/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/@opentui/core")
                (list "/lib/tree-sitter-typescript.wasm"
                      "assets/typescript/tree-sitter-typescript.wasm"
                      "node_modules/.bun/opentui-spinner@0.0.6+fbc73c270e220e29/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+solid@0.1.77+eb3cc3a936ac23ec/node_modules/@opentui/core"
                      "node_modules/.bun/node_modules/@opentui/core"
                      "packages/opencode/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/@opentui/core")
                (list "/lib/tree-sitter-markdown.wasm"
                      "assets/markdown/tree-sitter-markdown.wasm"
                      "node_modules/.bun/opentui-spinner@0.0.6+fbc73c270e220e29/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+solid@0.1.77+eb3cc3a936ac23ec/node_modules/@opentui/core"
                      "node_modules/.bun/node_modules/@opentui/core"
                      "packages/opencode/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/@opentui/core")
                (list "/lib/tree-sitter-markdown_inline.wasm"
                      "assets/markdown_inline/tree-sitter-markdown_inline.wasm"
                      "node_modules/.bun/opentui-spinner@0.0.6+fbc73c270e220e29/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+solid@0.1.77+eb3cc3a936ac23ec/node_modules/@opentui/core"
                      "node_modules/.bun/node_modules/@opentui/core"
                      "packages/opencode/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/@opentui/core")
                (list "/lib/tree-sitter-zig.wasm"
                      "assets/zig/tree-sitter-zig.wasm"
                      "node_modules/.bun/opentui-spinner@0.0.6+fbc73c270e220e29/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+solid@0.1.77+eb3cc3a936ac23ec/node_modules/@opentui/core"
                      "node_modules/.bun/node_modules/@opentui/core"
                      "packages/opencode/node_modules/@opentui/core"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/@opentui/core")
                ;; Only the glibc variant is ever loaded here; the musl
                ;; package stays prebuilt but is never reached.
                (list "/lib/watcher.node" "watcher.node"
                      "node_modules/.bun/@parcel+watcher-linux-x64-glibc@2.5.1/node_modules/@parcel/watcher-linux-x64-glibc"
                      "node_modules/.bun/@parcel+watcher@2.5.1/node_modules/@parcel/watcher-linux-x64-glibc"
                      "node_modules/.bun/node_modules/@parcel/watcher-linux-x64-glibc"
                      "packages/opencode/node_modules/@parcel/watcher-linux-x64-glibc")
                (list "/lib/tree-sitter.wasm" "tree-sitter.wasm"
                      "node_modules/.bun/web-tree-sitter@0.25.10/node_modules/web-tree-sitter"
                      "node_modules/.bun/node_modules/web-tree-sitter"
                      "node_modules/.bun/@opentui+core@0.1.77+2b53f2de03b5b2e3/node_modules/web-tree-sitter"
                      "packages/opencode/node_modules/web-tree-sitter")))))
          (add-after 'use-source-built-libraries 'use-source-built-javascript
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The vercel/ai packages are published as built output only.
              ;; Swap in the builds made from their TypeScript sources.  Bun's
              ;; isolated layout keeps one copy per dependent, so every copy
              ;; has to be found rather than a fixed list of paths.
              (define (unshadow directory)
                (when (and (file-exists? directory)
                           (eq? 'symlink (stat:type (lstat directory))))
                  (let ((target (readlink directory)))
                    (delete-file directory)
                    (mkdir directory)
                    (for-each
                     (lambda (entry)
                       (symlink (string-append target "/" entry)
                                (string-append directory "/" entry)))
                     (scandir target
                              (lambda (name)
                                (not (member name '("." "..")))))))))
              (define (materialize directory)
                (let loop ((parts (string-split (dirname directory) #\/))
                           (prefix #f))
                  (unless (null? parts)
                    (let ((here (if prefix
                                    (string-append prefix "/" (car parts))
                                    (car parts))))
                      (unshadow here)
                      (loop (cdr parts) here))))
                ;; A package can be reached through a chain of symlinks --
                ;; workspace copy to .bun entry to store -- so resolve the
                ;; whole chain rather than one level.
                (let ((real (canonicalize-path directory)))
                  (when (string-prefix? "/gnu/store/" real)
                    (if (eq? 'symlink (stat:type (lstat directory)))
                        (delete-file directory)
                        (delete-file-recursively directory))
                    (copy-recursively real directory)))
                ;; copy-recursively keeps the store's read-only modes, on
                ;; directories as well as files, so nothing inside could be
                ;; replaced afterwards.
                (invoke "chmod" "-R" "u+w" directory))
              (define (package-names root)
                ;; A built tree holds either "name" or "@scope/name" entries.
                (append-map
                 (lambda (entry)
                   (if (string-prefix? "@" entry)
                       (map (lambda (inner) (string-append entry "/" inner))
                            (scandir (string-append root "/" entry)
                                     (lambda (n)
                                       (not (member n '("." ".."))))))
                       (list entry)))
                 (scandir root (lambda (n) (not (member n '("." "..")))))))
              (define (read-version file)
                (and (file-exists? file)
                     (string-trim-right
                      (call-with-input-file file get-string-all))))
              (define (installed-version directory)
                (let ((manifest (string-append directory "/package.json")))
                  (and (file-exists? manifest)
                       (let ((m (string-match
                                 "\"version\"[ \t]*:[ \t]*\"([^\"]+)\""
                                 (call-with-input-file manifest
                                   get-string-all))))
                         (and m (match:substring m 1))))))
              (let* ((roots (map (lambda (name)
                                   (string-append (assoc-ref inputs name)
                                                  "/lib"))
                                 (append '("solid-js")
                                         '#$(map package-name
                                                 %vercel-from-source)
                                         '#$(map package-name
                                                 %actions-from-source)
                                         '#$(map package-name
                                                 %javascript-from-source))))
                     (replaced 0) (skipped 0))
                (define (swap! directory root name)
                  ;; Bun keeps several versions of a package side by side, so
                  ;; only a copy at the version that was built may be
                  ;; replaced; otherwise the binary would mix releases.
                  (let ((source (string-append root "/" name)))
                    (if (equal? (installed-version directory)
                                (read-version (string-append source
                                                             "/VERSION")))
                        (begin
                          (materialize directory)
                          (for-each
                           (lambda (file)
                             (let* ((relative (string-drop file
                                                           (+ 1 (string-length
                                                                 source))))
                                    (to (string-append directory "/"
                                                       relative)))
                               ;; A file our build emits that upstream did
                               ;; not ship still has to be installed: tsc
                               ;; drops a module whose exports are all types,
                               ;; esbuild keeps it, and the require between
                               ;; them is real either way.  Only overwriting
                               ;; pre-existing names left such a module
                               ;; dangling and broke resolution at run time.
                               (mkdir-p (dirname to))
                               (when (file-exists? to)
                                 (delete-file to))
                               (copy-file file to)
                               (chmod to #o444)
                               (set! replaced (+ replaced 1))))
                           (remove (lambda (f)
                                     (string-suffix? "/VERSION" f))
                                   (find-files source))))
                        (set! skipped (+ skipped 1)))))
                (unshadow "node_modules")
                (unshadow "node_modules/.bun")
                (define (visit base)
                  (when (file-exists? base)
                    (for-each
                     (lambda (root)
                       (for-each
                        (lambda (name)
                          (let ((directory (string-append base "/" name)))
                            (when (file-exists? directory)
                              (swap! directory root name))))
                        (package-names root)))
                     roots)))
                ;; .bun/node_modules is the shared hoisted directory and
                ;; holds packages directly; it is also an entry of .bun, so
                ;; treating every entry as a "holder" looked for
                ;; .bun/node_modules/node_modules and silently skipped it.
                ;; Transitive dependencies resolve through here, which is why
                ;; replacing only the workspace copies left them on npm's
                ;; build.
                (unshadow "node_modules/.bun/node_modules")
                (visit "node_modules/.bun/node_modules")
                (for-each
                 (lambda (holder)
                   (let ((base (string-append "node_modules/.bun/" holder
                                              "/node_modules")))
                     (when (file-exists? base)
                       (unshadow (string-append "node_modules/.bun/" holder))
                       (unshadow base)
                       (visit base))))
                 (scandir "node_modules/.bun"
                          (lambda (n) (not (member n '("." ".." "node_modules"))))))
                ;; The workspace copies are what opencode's own build resolves
                ;; against; missing them once produced a byte-identical binary.
                (for-each
                 (lambda (workspace)
                   (visit (string-append "packages/" workspace
                                         "/node_modules")))
                 (scandir "packages" (lambda (n) (not (member n '("." ".."))))))
                (format #t "replaced ~a files (~a copies at other versions)~%"
                        replaced skipped)
                ;; Diagnostic: report the size of a package the build resolves,
                ;; to tell "the phase ran" apart from "the build saw it".
                (for-each
                 (lambda (probe)
                   (when (file-exists? probe)
                     (format #t "  probe ~a -> ~a bytes~%" probe
                             (stat:size (stat probe)))))
                 '("packages/opencode/node_modules/agent-base/dist/index.js"
                   "node_modules/.bun/node_modules/agent-base/dist/index.js"))
                (when (zero? replaced)
                  (error "no JavaScript package was replaced")))))
          (add-after 'restore-node-modules 'patch-babel-helper-compilation-targets
            (lambda _
              ;; @babel/helper-compilation-targets assumes `require("lru-cache")`
              ;; is a constructor, but lru-cache@11 exports `LRUCache`.
              (let ((file
                     "packages/opencode/node_modules/@babel/helper-compilation-targets/lib/index.js"))
                (when (file-exists? file)
                  (substitute* file
                    (("const targetsCache = new _lruCache\\(")
                     "const targetsCache = new (_lruCache.LRUCache || _lruCache)("))))))
          (add-after 'restore-node-modules 'patch-lru-cache-interop
            (lambda _
              ;; Some deps import `lru-cache` as a default constructor.
              ;; v11 exports `LRUCache` as a named export only; add a
              ;; compatibility default export for Bun's resolver/runtime.
              (invoke
               "bash" "-c"
               "set -euo pipefail
pkg='packages/opencode/node_modules/lru-cache'
if [ -L \"$pkg\" ]; then
  rm \"$pkg\"
  cp -a node_modules/.bun/node_modules/lru-cache \"$pkg\"
fi
if [ -d \"$pkg\" ]; then
  chmod -R u+w \"$pkg\"
fi")
              (let ((esm "packages/opencode/node_modules/lru-cache/dist/esm/index.js")
                    (cjs "packages/opencode/node_modules/lru-cache/dist/commonjs/index.js"))
                (when (file-exists? esm)
                  (invoke
                   "bash" "-c"
                   (string-append
                    "grep -q 'export default LRUCache' " esm
                    " || printf '\\nexport default LRUCache;\\n' >> " esm)))
                (when (file-exists? cjs)
                  (invoke
                   "bash" "-c"
                   (string-append
                    "grep -q 'module.exports = exports.LRUCache' " cjs
                    " || printf '\\nmodule.exports = exports.LRUCache;\\nmodule.exports.LRUCache = exports.LRUCache;\\n' >> " cjs))))))
          (add-after 'restore-node-modules 'patch-opencode-build-script
            (lambda _
              (substitute* "packages/opencode/script/build.ts"
                (("export const snapshot = \\$\\{modelsData\\} as const")
                 "export const snapshot = (${modelsData.trim()}) as const"))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "HOME" (getcwd))
              (setenv "MODELS_DEV_API_JSON" (assoc-ref inputs "models-dev-api"))
              (setenv "OPENCODE_DISABLE_MODELS_FETCH" "true")
              (setenv "OPENCODE_CHANNEL" "local")
              (setenv "OPENCODE_VERSION" #$version)
              (with-directory-excursion "packages/opencode"
                (invoke "bun" "--bun" "./script/build.ts"
                        "--single"
                        "--skip-install")
                ;; Generate a full schema with a Bun runtime that exports
                ;; bun:wrap.__using (required by current opencode sources).
                (invoke (string-append
                         (assoc-ref inputs "bun-schema-generator")
                         "/bin/bun")
                        "--bun" "./script/schema.ts" "schema.json"))))
          (add-after 'build 'verify-source-built-libraries
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Compiled artefacts are filtered out of the node_modules
              ;; inputs, so a prebuilt binary can no longer reach the output
              ;; at all -- that half is structural now.  What still needs
              ;; checking is that every substitution landed: Bun resolves
              ;; modules to their realpath, so a package reached through a
              ;; symlink loads assets from somewhere else entirely, and the
              ;; only evidence is which bytes ended up in the binary.
              (call-with-output-file "verify-libraries.js"
                (lambda (port)
                  (display "\
const { readFileSync } = require('fs');
const binary = readFileSync(process.argv[2]);
for (let i = 3; i < process.argv.length; i++) {
  const built = readFileSync(process.argv[i]);
  if (binary.indexOf(built) === -1)
    throw new Error('compiled binary is missing ' + process.argv[i]);
  console.log('verified from source: ' + process.argv[i]);
}
" port)))
              (apply invoke
                     "bun" "--bun" "verify-libraries.js"
                     "packages/opencode/dist/opencode-linux-x64/bin/opencode"
                     (map (lambda (name)
                            (search-input-file inputs
                                               (string-append "/lib/" name)))
                          '("libopentui.so"
                            "librust_pty.so"
                            "watcher.node"
                            "tree-sitter.wasm"
                            "tree-sitter-bash.wasm"
                            "tree-sitter-javascript.wasm"
                            "tree-sitter-typescript.wasm"
                            "tree-sitter-markdown.wasm"
                            "tree-sitter-markdown_inline.wasm"
                            "tree-sitter-zig.wasm")))
              (delete-file "verify-libraries.js")))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (share (string-append out "/share/opencode"))
                     (binary
                      "packages/opencode/dist/opencode-linux-x64/bin/opencode"))
                (unless (file-exists? binary)
                  (error "missing compiled opencode binary" binary))
                (mkdir-p bin)
                (mkdir-p share)
                (install-file binary bin)
                (chmod (string-append bin "/opencode") #o755)
                (install-file "packages/opencode/schema.json" share))))
          ;; Stripping removes Bun's embedded app payload sections and turns
          ;; the compiled executable back into plain `bun`.
          (delete 'strip))))
    (native-inputs
     `(("bun-from-source" ,bun-from-source)
       ("bun-schema-generator" ,bun-from-source)
       ("libopentui" ,libopentui)
       ("librust-pty" ,librust-pty)
       ("tree-sitter-wasm-grammars" ,tree-sitter-wasm-grammars)
       ("parcel-watcher-node" ,parcel-watcher-node)
       ("web-tree-sitter-wasm" ,web-tree-sitter-wasm)
       ,@(map (lambda (p) (list (package-name p) p)) %vercel-from-source)
       ,@(map (lambda (p) (list (package-name p) p)) %actions-from-source)
       ("solid-js" ,solid-js-from-source)
       ,@(map (lambda (p) (list (package-name p) p))
              %javascript-from-source)
       ("node-modules" ,opencode-node-modules)
       ("models-dev-api" ,models-dev-api-json)
       ("app-node-modules" ,app-node-modules)
       ("enterprise-node-modules" ,enterprise-node-modules)
       ("function-node-modules" ,function-node-modules)
       ("plugin-node-modules" ,plugin-node-modules)
       ("script-node-modules" ,script-node-modules)
       ("sdk-js-node-modules" ,sdk-js-node-modules)
       ("slack-node-modules" ,slack-node-modules)
       ("ui-node-modules" ,ui-node-modules)
       ("util-node-modules" ,util-node-modules)
       ("web-node-modules" ,web-node-modules)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://opencode.ai")
    (synopsis "opencode package built with Bun")
    (description
     "Local Guix recipe for building opencode with source-built Bun.")
    (license license:expat)))

;; Backward-compatibility alias.
(define-public opencode-local opencode)


;;; The upstream release binary.  This channel builds opencode from source as
;;; well -- see the `opencode' package above -- but that route needs a
;;; node_modules tree this machine happens to have, so it does not build
;;; anywhere else.  This one does, at the cost of being someone else's build.
(define-public opencode-bin
  (package
    (name "opencode-bin")
    (version "1.18.18")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/anomalyco/opencode/releases/"
                           "download/v" version "/opencode-linux-x64.tar.gz"))
       (sha256
        (base32 "1bravfgirc3nmkb86kd21pq8hw6s1h69ia05k5k571cb84ic5p8c"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((bin (string-append #$output "/bin"))
                 (opencode (string-append bin "/opencode")))
            (setenv "PATH"
                    (string-join
                     (map (lambda (input)
                            (string-append (assoc-ref %build-inputs input)
                                           "/bin"))
                          '("tar" "gzip" "patchelf"))
                     ":"))
            (mkdir-p bin)
            ;; The archive holds the single binary, with no directory.
            (invoke "tar" "-xzf" (assoc-ref %build-inputs "source")
                    "-C" bin)
            (chmod opencode #o755)
            ;; It is linked for a conventional filesystem, so point it at
            ;; the libc this channel has.  Nothing more: this is a bun
            ;; single-file executable, which carries its payload appended to
            ;; the ELF image, and --set-rpath or --remove-needed shifts that
            ;; payload and segfaults the result.  Setting the interpreter
            ;; alone leaves it intact, and the store glibc's loader finds
            ;; libc, libpthread, libdl and libm -- all it needs -- beside
            ;; itself without a RUNPATH.
            (invoke "patchelf" "--set-interpreter"
                    (string-append (assoc-ref %build-inputs "glibc")
                                   "/lib/ld-linux-x86-64.so.2")
                    opencode)))))
    (native-inputs
     `(("tar" ,tar)
       ("gzip" ,gzip)
       ("patchelf" ,patchelf)))
    (inputs `(("glibc" ,glibc)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://opencode.ai")
    (synopsis "Terminal coding agent (upstream binary)")
    (description
     "This package installs the @code{opencode} binary published upstream.
It is not built from source; @code{opencode} in this channel is.")
    (license license:expat)))
