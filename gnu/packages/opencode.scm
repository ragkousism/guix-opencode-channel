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
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages javascript)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages node)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages web)
  #:use-module (gnu packages zig)
  #:export (bun-bootstrap
            bun-from-source
            opencode
            bun-from-source-local
            opencode-local))

;; Local development defaults.  Override these with environment variables for
;; other checkouts/snapshots:
;; - BUN_OFFLINE_SEED_DIR
;; - OPENCODE_SOURCE_DIR
;; - OPENCODE_MODELS_DEV_API_JSON
(define (path-or-default env-var default)
  (or (getenv env-var) default))

(define %bun-offline-seed-directory
  (path-or-default "BUN_OFFLINE_SEED_DIR" "/var/tmp/bun-offline-seed"))

(define %opencode-source-directory
  (path-or-default "OPENCODE_SOURCE_DIR" "/home/manolis/repos/opencode"))

(define %opencode-models-dev-api-json
  (path-or-default "OPENCODE_MODELS_DEV_API_JSON" "/tmp/models-dev-api.json"))

(define offline-seed
  (local-file %bun-offline-seed-directory
              "bun-offline-seed"
              #:recursive? #t))

(define webkit-prebuilt
  (origin
    (method url-fetch)
    (uri
     "https://github.com/oven-sh/WebKit/releases/download/autobuild-9a2cc42ae1bf693a0fd0ceb9b1d7d965d9cfd3ea/bun-webkit-linux-amd64.tar.gz")
    (sha256
     (base32
      "1h0ajrpn3ybchggri5ypgd17mk5d4s1a6bbpn1cy14i940922y03"))))

(define-public bun-bootstrap
  (package
    (name "bun-bootstrap")
    (version "1.3.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/oven-sh/bun/releases/download/bun-v"
             version "/bun-linux-x64.zip"))
       (sha256
        (base32
         "1wd34srfq5jywkga220hvzvcpvas4acd9alq8ak7dni20xzv28h3"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:validate-runpath? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (invoke "unzip" source)))
          (delete 'configure)
          (delete 'build)
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (bun (string-append bin "/bun"))
                     (interpreter
                      (search-input-file inputs "/lib/ld-linux-x86-64.so.2")))
                (mkdir-p bin)
                (install-file "bun-linux-x64/bun" bin)
                (chmod bun #o755)
                (invoke "patchelf" "--set-interpreter" interpreter bun)
                (symlink "bun" (string-append bin "/bunx"))))))))
    (native-inputs
     (list unzip patchelf))
    (inputs
     (list glibc))
    (supported-systems '("x86_64-linux"))
    (home-page "https://bun.sh")
    (synopsis "Temporary bootstrap Bun binary")
    (description
     "This package provides a temporary bootstrap Bun binary for building a
fully source-built Bun package.")
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
         "1byw1rbvsizm079isfxp3hz6s5x76hpskdpfn9xkhh73admkj54p"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'prepare-offline-tree
            (lambda* (#:key inputs #:allow-other-keys)
              (invoke "cp" "-a"
                      (string-append (assoc-ref inputs "offline-seed") "/.")
                      ".")
              (invoke "chmod" "-R" "u+w" ".")

              ;; Preserve offline seed content but mark it newer than CMake
              ;; sources so download rules are considered up to date.
              (invoke "find" "vendor" "-type" "d" "-exec" "touch" "{}" "+")
              (invoke "find" "vendor" "-type" "f" "-exec" "touch" "{}" "+")
              (invoke "find"
                      "packages/bun-error/node_modules"
                      "src/node-fallbacks/node_modules"
                      "-name" "package.json"
                      "-type" "f"
                      "-exec" "touch" "{}" "+")

              ;; Seed Cargo registry/index for offline Rust builds.
              (mkdir-p ".cargo")
              (invoke "cp" "-a" "cargo-home/." ".cargo")

              ;; Avoid root-level `bun install` by providing esbuild directly.
              (mkdir-p "node_modules/.bin")
              (let ((esbuild (search-input-file inputs "/bin/esbuild")))
                (when (file-exists? "node_modules/.bin/esbuild")
                  (delete-file "node_modules/.bin/esbuild"))
                (symlink esbuild "node_modules/.bin/esbuild"))

              ;; `vendor/zig` is seeded in offline inputs.
              (unless (file-exists? "vendor/zig/zig")
                (error "missing pre-seeded vendor/zig toolchain"))

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
              (invoke "cp" "-a" "cache/bun" "build/release/cache/bun")

              ;; Prevent network fetches when a repository is already
              ;; pre-populated.
              (substitute* "cmake/scripts/GitClone.cmake"
                (("set\\(GIT_DOWNLOAD_URL https://github.com/\\$\\{GIT_REPOSITORY\\}/archive/\\$\\{GIT_REF\\}\\.tar\\.gz\\)")
                 "if(EXISTS ${GIT_PATH}/.ref)\n  file(READ ${GIT_PATH}/.ref GIT_EXISTING_REF)\n  string(STRIP \"${GIT_EXISTING_REF}\" GIT_EXISTING_REF)\n  if(GIT_EXISTING_REF STREQUAL GIT_REF)\n    message(STATUS \"Using pre-populated ${GIT_REPOSITORY} at ${GIT_REF}\")\n    return()\n  endif()\nendif()\n\nset(GIT_DOWNLOAD_URL https://github.com/${GIT_REPOSITORY}/archive/${GIT_REF}.tar.gz)"))

              (substitute* "cmake/scripts/DownloadUrl.cmake"
                (("if\\(CMAKE_SYSTEM_NAME STREQUAL \\\"Windows\\\"\\)")
                 "if(EXISTS ${DOWNLOAD_PATH})\n  message(STATUS \\\"Using pre-populated download path: ${DOWNLOAD_PATH}\\\")\n  return()\nendif()\n\nif(CMAKE_SYSTEM_NAME STREQUAL \\\"Windows\\\")"))

              ;; Bun tarball builds do not have a Git checkout; keep version
              ;; symbols defined instead of dropping them as \"unknown\".
              (substitute* "cmake/tools/GenerateDependencyVersions.cmake"
                (("set\\(BUN_GIT_SHA \"unknown\"\\)")
                 "if(DEFINED VERSION AND NOT \"${VERSION}\" STREQUAL \"\")\n    set(BUN_GIT_SHA \"${VERSION}\")\n  else()\n    set(BUN_GIT_SHA \"tarball\")\n  endif()"))

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
                  (with-directory-excursion target
                    (invoke "git" "apply"
                            "--ignore-whitespace"
                            "--ignore-space-change"
                            "--no-index"
                            "--verbose"
                            (string-append cwd "/" patch))))
                (apply-patch "vendor/highway"
                             "patches/highway/silence-warnings.patch")
                (apply-patch "vendor/libarchive"
                             "patches/libarchive/CMakeLists.txt.patch")
                (apply-patch "vendor/libarchive"
                             "patches/libarchive/archive_write_add_filter_gzip.c.patch")
                (apply-patch "vendor/lshpack"
                             "patches/lshpack/CMakeLists.txt.patch")
                (apply-patch "vendor/tinycc" "patches/tinycc/tcc.h.patch")
                (copy-file "patches/tinycc/CMakeLists.txt"
                           "vendor/tinycc/CMakeLists.txt")
                (apply-patch "vendor/zlib" "patches/zlib/CMakeLists.txt.patch")
                (apply-patch "vendor/zlib" "patches/zlib/deflate.h.patch")
                (apply-patch "vendor/zlib" "patches/zlib/ucm.cmake.patch"))))
          (add-before 'build 'provide-webkit
            (lambda _
              (let* ((cache (string-append (getcwd) "/build/release/cache"))
                     (webkit (string-append cache "/webkit-9a2cc42ae1bf693a"))
                     (extracted (string-append cache "/bun-webkit")))
                (mkdir-p cache)
                (invoke "tar" "xf" #$webkit-prebuilt "-C" cache)
                (when (file-exists? webkit)
                  (delete-file-recursively webkit))
                (rename-file extracted webkit)
                ;; Clang in C++23 mode no longer resolves these C math symbols
                ;; unqualified in this prebuilt header.
                (substitute* (string-append
                              webkit
                              "/include/JavaScriptCore/JSCJSValueInlines.h")
                  (("return trunc\\(toNumber\\(globalObject\\) \\+ 0\\.0\\);")
                   "return std::trunc(toNumber(globalObject) + 0.0);")
                  (("return isnan\\(d\\) \\? 0\\.0 : trunc\\(d\\) \\+ 0\\.0;")
                   "return std::isnan(d) ? 0.0 : std::trunc(d) + 0.0;")))))
          (replace 'build
            (lambda _
              (setenv "HOME" (getcwd))
              (setenv "BUN_DEBUG_QUIET_LOGS" "1")
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; Clang crashes were observed under heavy parallelism in
              ;; tmpfs-limited builds; force serialized CMake/Ninja execution.
              (setenv "CMAKE_BUILD_PARALLEL_LEVEL" "1")
              (invoke "bun" "./scripts/build.mjs"
                      "-GNinja"
                      "-DCMAKE_BUILD_TYPE=Release"
                      "-B" "build/release")))
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
                        bun)))))))
    (inputs
     (list glibc))
    (native-inputs
     (list (list "offline-seed" offline-seed)
           (list "bun-bootstrap" bun-bootstrap)
           (list "cmake" cmake)
           (list "ninja" ninja)
           (list "pkg-config" pkg-config)
           (list "clang" clang-19)
           (list "lld" lld-19)
           (list "llvm" llvm-19)
           (list "zig" zig-0.14)
           (list "rust" rust)
           (list "cargo" rust "cargo")
           (list "go" go)
           (list "ruby" ruby)
           (list "python" python)
           (list "node" node)
           (list "perl" perl)
           (list "git" git)
           (list "patchelf" patchelf)
           (list "which" which)
           (list "esbuild" esbuild)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://bun.sh")
    (synopsis "Prototype package to build Bun from source")
    (description "Prototype package to build Bun from source.")
    (license license:expat)))

;; Backward-compatibility alias.
(define-public bun-from-source-local bun-from-source)

(define opencode-source
  (local-file %opencode-source-directory
              "opencode-source"
              #:recursive? #t
              #:select? (git-predicate %opencode-source-directory)))

(define opencode-node-modules
  (local-file (string-append %opencode-source-directory "/.guix-node-modules")
              "opencode-node-modules"
              #:recursive? #t))

(define models-dev-api-json
  (local-file %opencode-models-dev-api-json
              "models-dev-api.json"))

(define app-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/app/node_modules")
              "app-node-modules"
              #:recursive? #t))

(define enterprise-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/enterprise/node_modules")
              "enterprise-node-modules"
              #:recursive? #t))

(define function-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/function/node_modules")
              "function-node-modules"
              #:recursive? #t))

(define plugin-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/plugin/node_modules")
              "plugin-node-modules"
              #:recursive? #t))

(define script-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/script/node_modules")
              "script-node-modules"
              #:recursive? #t))

(define slack-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/slack/node_modules")
              "slack-node-modules"
              #:recursive? #t))

(define ui-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/ui/node_modules")
              "ui-node-modules"
              #:recursive? #t))

(define util-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/util/node_modules")
              "util-node-modules"
              #:recursive? #t))

(define web-node-modules
  (local-file (string-append %opencode-source-directory
                             "/packages/web/node_modules")
              "web-node-modules"
              #:recursive? #t))

(define-public opencode
  (package
    (name "opencode")
    (version "1.1.58")
    (source opencode-source)
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'patch-generated-file-shebangs)
          (add-after 'unpack 'restore-node-modules
            (lambda* (#:key inputs #:allow-other-keys)
              (invoke "cp" "-a"
                      (string-append (assoc-ref inputs "node-modules") "/.")
                      ".")
              (for-each
               (lambda (name)
                 (invoke "cp" "-a"
                         (assoc-ref inputs (string-append name "-node-modules"))
                         (string-append "packages/" name "/node_modules")))
               '("app" "enterprise" "function" "plugin" "script"
                 "slack" "ui" "util" "web"))
              (invoke "chmod" "-R" "u+w" ".")))
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
                (invoke "bun" "--bun" "./script/schema.ts" "schema.json"))))
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
     (list (list "bun" bun-from-source)
           (list "node-modules" opencode-node-modules)
           (list "models-dev-api" models-dev-api-json)
           (list "app-node-modules" app-node-modules)
           (list "enterprise-node-modules" enterprise-node-modules)
           (list "function-node-modules" function-node-modules)
           (list "plugin-node-modules" plugin-node-modules)
           (list "script-node-modules" script-node-modules)
           (list "slack-node-modules" slack-node-modules)
           (list "ui-node-modules" ui-node-modules)
           (list "util-node-modules" util-node-modules)
           (list "web-node-modules" web-node-modules)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://opencode.ai")
    (synopsis "opencode package built with Bun")
    (description
     "Local Guix recipe for building opencode with source-built Bun.")
    (license license:expat)))

;; Backward-compatibility alias.
(define-public opencode-local opencode)
