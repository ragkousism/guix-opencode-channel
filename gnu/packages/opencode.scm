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
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages adns)
  #:use-module (gnu packages base)
  #:use-module (gnu packages backup)
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
            bun-build-system-smoke
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

(define (local-directory-or-empty path name)
  (if (file-exists? path)
      (local-file path
                  name
                  #:recursive? #t)
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

(define %bun-offline-seed-directory
  (path-or-default "BUN_OFFLINE_SEED_DIR" "/var/tmp/bun-offline-seed"))

(define %opencode-source-directory
  (path-or-default "OPENCODE_SOURCE_DIR" "/home/manolis/repos/opencode"))

(define %opencode-models-dev-api-json
  (path-or-default "OPENCODE_MODELS_DEV_API_JSON" "/tmp/models-dev-api.json"))

(define offline-seed
  (if (file-exists? %bun-offline-seed-directory)
      (local-file %bun-offline-seed-directory
                  "bun-offline-seed"
                  #:recursive? #t)
      (computed-file "bun-offline-seed"
                     #~(begin
                         (mkdir #$output)))))

(define webkit-prebuilt-stage0
  (origin
    (method url-fetch)
    (uri
     "https://github.com/oven-sh/WebKit/releases/download/autobuild-64d04ec1a65d91326c5f2298b9c7d05b56125252/bun-webkit-linux-amd64.tar.gz")
    (sha256
     (base32
      "01r1lbz1bl54wfs4wj8if7zzlx2603s75188yxzizq29iyvd0iky"))))

(define webkit-prebuilt-1.3.8
  (origin
    (method url-fetch)
    (uri
     "https://github.com/oven-sh/WebKit/releases/download/autobuild-9a2cc42ae1bf693a0fd0ceb9b1d7d965d9cfd3ea/bun-webkit-linux-amd64.tar.gz")
    (sha256
     (base32
      "1h0ajrpn3ybchggri5ypgd17mk5d4s1a6bbpn1cy14i940922y03"))))

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

(define node-v24.3.0-headers-source
  (origin
    (method url-fetch)
    (uri "https://nodejs.org/dist/v24.3.0/node-v24.3.0-headers.tar.gz")
    (sha256
     (base32
      "01yx2n8qxf09xp8f70f5wbgxx17plwxsdhgqcznb0pfdfzs9nph4"))))

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
        (base32 hash))))
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
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Keep source unpack size reasonable in tmpfs-backed builds.
           (delete-file-recursively "packages/bun-uws/fuzzing/seed-corpus")
           #t))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      ;; Temporary, for diagnosing the JS-execution hang: keep .symtab so
      ;; the spinning stack can be symbolized.
      #:strip-binaries? #f
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
              (invoke "tar" "xf" (assoc-ref inputs "webkit-prebuilt"))
              (setenv "JSC_BASE_DIR" (string-append (getcwd) "/bun-webkit"))
              ;; Bun's release tarball lacks the mimalloc submodule headers.
              ;; Rehydrate them from Guix's mimalloc package.  The headers
              ;; live under a version-specific subdirectory (e.g.
              ;; "include/mimalloc-3.3"), so locate it by content rather
              ;; than hard-coding a version that will drift.
              (copy-recursively
               (dirname (car (find-files (assoc-ref inputs "mimalloc")
                                         "^mimalloc\\.h$")))
               "src/deps/mimalloc/include")
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
                ;; Avoid forcing non-PIC static libatomic at final link.
                (("-l:libatomic\\.a")
                 "-latomic")
                ;; Link command places libs before most objects; keep needed
                ;; shared libs from being discarded in that ordering.
                (("-Wl,--as-needed")
                 "")
                ;; Ensure local compatibility shims participate in final link.
                (("src/deps/libmimalloc\\.o")
                 "src/deps/libmimalloc.o src/deps/guix-link-compat.o"))

              ;; Bun 1.0.x expects older JavaScriptCore/WTF APIs.  Adapt a few
              ;; generated headers/helpers to the newer WebKit snapshot used
              ;; in this bootstrap stage.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("const char\\*\\*")
                    "ASCIILiteral*")))
               (find-files "src/bun.js/bindings" "\\.(h|cpp)$"))
              (for-each
               (lambda (file)
                 (substitute* file
                   (("\\*reason = \"([^\"]*)\";" _ reason)
                    (string-append "*reason = WTF::ASCIILiteral::fromLiteralUnsafe(\""
                                   reason "\");"))))
               (find-files "src/bun.js/bindings" "\\.(h|cpp)$"))

              ;; WebKit now exposes text buffers through spans instead of raw
              ;; characters8/characters16 pointers.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("->characters8\\(\\)")
                    "->span8().data()")
                   (("->characters16\\(\\)")
                    "->span16().data()")
                   (("\\.characters8\\(\\)")
                    ".span8().data()")
                   (("\\.characters16\\(\\)")
                    ".span16().data()")))
               (find-files "src/bun.js/bindings" "\\.(h|cpp|gperf)$"))

              ;; WebKit removed uncheckedAppend in favor of append.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("uncheckedAppend")
                    "append")))
               (find-files "src/bun.js/bindings" "\\.(h|cpp)$"))

              (substitute* "src/bun.js/bindings/ZigGeneratedClasses.h"
                (("\\*reason = \"has pending activity\";")
                 "*reason = WTF::ASCIILiteral::fromLiteralUnsafe(\"has pending activity\");"))

              (substitute* "src/js/out/WebCoreJSBuiltins.h"
                (("JSC::makeSource\\(StringImpl::createWithoutCopying\\(s_##name, length\\), \\{ \\}\\)")
                 "JSC::makeSource(StringImpl::createWithoutCopying({reinterpret_cast<const LChar*>(s_##name), static_cast<size_t>(length)}), { }, JSC::SourceTaintedOrigin::Untainted)")
                (("JSC::createBuiltinExecutable\\(m_vm, m_##name##Source, executableName, s_##name##ImplementationVisibility, s_##name##ConstructorKind, s_##name##ConstructAbility\\)")
                 "JSC::createBuiltinExecutable(m_vm, m_##name##Source, executableName, s_##name##ImplementationVisibility, s_##name##ConstructorKind, s_##name##ConstructAbility, JSC::InlineAttribute::None)"))

              (substitute* "src/bun.js/bindings/helpers.h"
                (("JSC::Identifier::fromString\\(global->vm\\(\\), untag\\(str\\.ptr\\), str\\.len\\)")
                 "JSC::Identifier::fromString(global->vm(), { untag(str.ptr), str.len })")
                (("WTF::String::fromUTF8\\(untag\\(str\\.ptr\\), str\\.len\\)")
                 "WTF::String::fromUTF8({ reinterpret_cast<const char*>(untag(str.ptr)), str.len })")
                (("WTF::String::fromUTF8\\(&untag\\(str\\.ptr\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::String::fromUTF8({ reinterpret_cast<const char*>(&untag(str.ptr)[ptr.off]), ptr.len })")
                (("WTF::ExternalStringImpl::create\\(untag\\(str\\.ptr\\), str\\.len, untagVoid\\(str\\.ptr\\), free_global_string\\)")
                 "WTF::ExternalStringImpl::create({ untag(str.ptr), str.len }, untagVoid(str.ptr), free_global_string)")
                (("WTF::ExternalStringImpl::create\\([[:space:]]*reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len, untagVoid\\(str\\.ptr\\), free_global_string\\)")
                 "WTF::ExternalStringImpl::create({ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len }, untagVoid(str.ptr), free_global_string)")
                (("WTF::StringImpl::createWithoutCopying\\(untag\\(str\\.ptr\\), str\\.len\\)")
                 "WTF::StringImpl::createWithoutCopying({ untag(str.ptr), str.len })")
                (("WTF::StringImpl::createWithoutCopying\\(reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len\\)")
                 "WTF::StringImpl::createWithoutCopying({ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len })")
                (("WTF::StringImpl::createWithoutCopying\\([[:space:]]*reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len\\)")
                 "WTF::StringImpl::createWithoutCopying({ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len })")
                (("WTF::StringImpl::createWithoutCopying\\(&untag\\(str\\.ptr\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::StringImpl::createWithoutCopying({ &untag(str.ptr)[ptr.off], ptr.len })")
                (("WTF::StringImpl::createWithoutCopying\\(&reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::StringImpl::createWithoutCopying({ &reinterpret_cast<const UChar*>(untag(str.ptr))[ptr.off], ptr.len })")
                (("WTF::StringImpl::createWithoutCopying\\([[:space:]]*&reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::StringImpl::createWithoutCopying({ &reinterpret_cast<const UChar*>(untag(str.ptr))[ptr.off], ptr.len })")
                (("WTF::StringImpl::create\\(&untag\\(str\\.ptr\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::StringImpl::create({ &untag(str.ptr)[ptr.off], ptr.len })")
                (("WTF::StringImpl::create\\(&reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::StringImpl::create({ &reinterpret_cast<const UChar*>(untag(str.ptr))[ptr.off], ptr.len })")
                (("WTF::StringImpl::create\\([[:space:]]*&reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\)\\[ptr\\.off\\], ptr\\.len\\)")
                 "WTF::StringImpl::create({ &reinterpret_cast<const UChar*>(untag(str.ptr))[ptr.off], ptr.len })")
                (("reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len, untagVoid\\(str\\.ptr\\), free_global_string\\)\\)")
                 "{ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len }, untagVoid(str.ptr), free_global_string))")
                (("reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len\\)\\)")
                 "{ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len }))")
                (("&reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\)\\[ptr\\.off\\], ptr\\.len\\)\\)")
                 "{ &reinterpret_cast<const UChar*>(untag(str.ptr))[ptr.off], ptr.len }))")
                (("reinterpret_cast<const LChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len\\)\\)")
                 "{ reinterpret_cast<const LChar*>(untag(str.ptr)), str.len }))")
                (("str->is8Bit\\(\\) \\? str->characters8\\(\\) : taggedUTF16Ptr\\(str->characters16\\(\\)\\)")
                 "str->is8Bit() ? str->span8().data() : taggedUTF16Ptr(str->span16().data())")
                (("str\\.is8Bit\\(\\) \\? str\\.characters8\\(\\) : taggedUTF16Ptr\\(str\\.characters16\\(\\)\\)")
                 "str.is8Bit() ? str.span8().data() : taggedUTF16Ptr(str.span16().data())")
                (("WTF::StringView\\(untag\\(str\\.ptr\\), str\\.len\\)")
                 "isTaggedUTF16Ptr(str.ptr) ? WTF::StringView({ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len }) : WTF::StringView({ untag(str.ptr), str.len })")
                (("AtomStringImpl::add\\(reinterpret_cast<const UChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len\\)")
                 "AtomStringImpl::add({ reinterpret_cast<const UChar*>(untag(str.ptr)), str.len })")
                (("AtomStringImpl::add\\([[:space:]]*reinterpret_cast<const LChar\\*>\\(untag\\(str\\.ptr\\)\\), str\\.len[[:space:]]*\\)")
                 "AtomStringImpl::add({ reinterpret_cast<const LChar*>(untag(str.ptr)), str.len })"))

              (substitute* "src/bun.js/bindings/BunDebugger.cpp"
                (("WTF::LockHolder")
                 "WTF::Locker"))
              (substitute* "src/bun.js/bindings/JSCTaskScheduler.cpp"
                (("LockHolder holder")
                 "WTF::Locker holder"))
              (substitute* "src/bun.js/bindings/BunInspector.cpp"
                (("WTF::String::fromUTF8\\(message\\.data\\(\\), message\\.length\\(\\)\\)")
                 "WTF::String::fromUTF8({ message.data(), message.length() })"))
              (substitute* "src/bun.js/bindings/IDLTypes.h"
                (("std::isnan\\(value\\)")
                 "value.isNaN()"))
              (substitute* "src/bun.js/bindings/BunObject.cpp"
                (("resolvedString\\.characters16\\(\\)")
                 "resolvedString.span16().data()")
                (("resolvedString\\.characters8\\(\\)")
                 "resolvedString.span8().data()"))
              (substitute* "src/bun.js/bindings/JSBuffer.cpp"
                (("view\\.characters8\\(\\)")
                 "view.span8().data()")
                (("view\\.characters16\\(\\)")
                 "view.span16().data()"))
              (substitute* "src/bun.js/bindings/JSStringDecoder.cpp"
                (("WTF::String\\(u\"\\\\uFFFD\", 1\\)")
                 "WTF::String({ u\"\\uFFFD\", 1 })"))
              (substitute* "src/bun.js/bindings/Process.cpp"
                (("WTF::String\\(Bun__githubURL, strlen\\(Bun__githubURL\\)\\)")
                 "WTF::String({ Bun__githubURL, strlen(Bun__githubURL) })"))
              (substitute* "src/bun.js/modules/BunJSCModule.h"
                (("WTF::String timeZoneString\\(buffer\\.data\\(\\), buffer\\.size\\(\\)\\);")
                 "WTF::String timeZoneString({ buffer.data(), buffer.size() });"))
              (substitute* "src/bun.js/bindings/ZigGlobalObject.cpp"
                (("#include \"JavaScriptCore/JSModuleNamespaceObject.h\"")
                 "#include \"JavaScriptCore/JSModuleNamespaceObject.h\"\n#include \"JavaScriptCore/JSModuleNamespaceObjectInlines.h\"")
                (("WTF::String::fromUTF8\\(raw\\.str, raw\\.len\\)")
                 "WTF::String::fromUTF8({ raw.str, raw.len })")
                (("frame\\.computeLineAndColumn\\(thisLine, thisColumn\\);")
                 "auto lineColumn = frame.computeLineAndColumn();\n            thisLine = lineColumn.line;\n            thisColumn = lineColumn.column;")
                (("WEBCORE_GENERATED_CONSTRUCTOR_GETTER\\(JSMessageChannel\\);\n")
                 "")
                (("WEBCORE_GENERATED_CONSTRUCTOR_SETTER\\(JSMessageChannel\\);\n")
                 "")
                (("PUT_WEBCORE_GENERATED_CONSTRUCTOR\\([^)]*JSMessageChannel[^)]*\\);")
                 "")
                (("WTF::StringImpl::copyCharacters\\(ptr, encodedString\\.span16\\(\\)\\.data\\(\\), length\\);")
                 "WTF::StringImpl::copyCharacters(ptr, encodedString.span16());"))
              (substitute* "src/bun.js/bindings/napi.cpp"
                (("WTF::StringImpl::createWithoutCopying\\(utf8name, utf8Len\\)")
                 "WTF::StringImpl::createWithoutCopying({ utf8name, utf8Len })")
                (("charactersAreAllASCII\\(reinterpret_cast<const LChar\\*>\\(utf8name\\), utf8Len\\)")
                 "charactersAreAllASCII(std::span<const LChar> { reinterpret_cast<const LChar*>(utf8name), utf8Len })")
                (("charactersAreAllASCII\\(\\{ reinterpret_cast<const LChar\\*>\\(utf8name\\), utf8Len \\}\\)")
                 "charactersAreAllASCII(std::span<const LChar> { reinterpret_cast<const LChar*>(utf8name), utf8Len })")
                (("JSC::makeSource\\(sourceCodeBuilder\\.toString\\(\\), JSC::SourceOrigin\\(\\), keyString,")
                 "JSC::makeSource(sourceCodeBuilder.toString(), JSC::SourceOrigin(), JSC::SourceTaintedOrigin::Untainted, keyString,")
                (("WTF::String::fromUTF8\\(property\\.utf8name, len\\)")
                 "WTF::String::fromUTF8({ property.utf8name, len })")
                (("WTF::String::fromUTF8\\(utf8name, strlen\\(utf8name\\)\\)")
                 "WTF::String::fromUTF8({ utf8name, strlen(utf8name) })")
                (("WTF::String::fromUTF8\\(utf8name, length == NAPI_AUTO_LENGTH \\? strlen\\(utf8name\\) : length\\)")
                 "WTF::String::fromUTF8({ utf8name, length == NAPI_AUTO_LENGTH ? strlen(utf8name) : length })")
                (("WTF::String::fromUTF8\\(utf8description, length == NAPI_AUTO_LENGTH \\? strlen\\(utf8description\\) : length\\)")
                 "WTF::String::fromUTF8({ utf8description, length == NAPI_AUTO_LENGTH ? strlen(utf8description) : length })")
                (("WTF::String::fromUTF8\\(utf8name, length\\)")
                 "WTF::String::fromUTF8({ utf8name, length })"))
              (substitute* "src/bun.js/bindings/bindings.cpp"
                (("WTF::StringImpl::createWithoutCopying\\(range_error_name, 10\\)")
                 "WTF::StringImpl::createWithoutCopying({ range_error_name, 10 })")
                (("WTF::StringImpl::createWithoutCopying\\(range_error_name, 9\\)")
                 "WTF::StringImpl::createWithoutCopying({ range_error_name, 9 })")
                (("StringImpl::createWithoutCopying\\(arg1, arg2\\)")
                 "StringImpl::createWithoutCopying({ arg1, arg2 })")
                (("WTF::String::fromUTF8\\(arg1, arg2\\)")
                 "WTF::String::fromUTF8({ arg1, arg2 })")
                (("WTF::String::fromUTF8\\(originUrlPtr, originURLLen\\)")
                 "WTF::String::fromUTF8({ originUrlPtr, originURLLen })")
                (("WTF::String::fromUTF8\\(referrerUrlPtr, referrerUrlLen\\)")
                 "WTF::String::fromUTF8({ referrerUrlPtr, referrerUrlLen })")
                (("WTF::String::fromUTF8\\(arg0->ptr, arg0->len\\)")
                 "WTF::String::fromUTF8({ arg0->ptr, arg0->len })")
                (("WTF::StringView\\(ptr, strlen\\(ptr\\)\\)")
                 "WTF::StringView({ ptr, strlen(ptr) })")
                (("StringImpl::copyCharacters\\(&buf\\[i\\], name\\.span16\\(\\)\\.data\\(\\), name\\.length\\(\\)\\);")
                 "StringImpl::copyCharacters(&buf[i], name.span16());")
                (("StringImpl::copyCharacters\\(&buf\\[i\\], value\\.span16\\(\\)\\.data\\(\\), value\\.length\\(\\)\\);")
                 "StringImpl::copyCharacters(&buf[i], value.span16());")
                (("StringView\\(reinterpret_cast<const char\\*>\\(header\\.name\\.ptr\\), header\\.name\\.len\\)")
                 "StringView({ reinterpret_cast<const char*>(header.name.ptr), header.name.len })")
                (("StringView\\(reinterpret_cast<const LChar\\*>\\(header\\.first\\.data\\(\\)\\), header\\.first\\.length\\(\\)\\)")
                 "StringView({ reinterpret_cast<const LChar*>(header.first.data()), header.first.length() })")
                (("src, JSC::SourceOrigin \\{ origin \\}, origin\\.fileSystemPath\\(\\),")
                 "src, JSC::SourceOrigin { origin }, JSC::SourceTaintedOrigin::Untainted, origin.fileSystemPath(),")
                (("WTF::AtomStringImpl::lookUp\\(reinterpret_cast<const UChar\\*>\\(untag\\(arg0->ptr\\)\\), arg0->len\\)")
                 "WTF::AtomStringImpl::lookUp({ reinterpret_cast<const UChar*>(untag(arg0->ptr)), arg0->len })")
                (("WTF::AtomStringImpl::lookUp\\(untag\\(arg0->ptr\\), arg0->len\\)")
                 "WTF::AtomStringImpl::lookUp({ untag(arg0->ptr), arg0->len })")
                (("ExternalStringImpl::create\\(reinterpret_cast<const UChar\\*>\\(arg0\\), len, reinterpret_cast<void\\*>\\(const_cast<uint16_t\\*>\\(arg0\\)\\), free_global_string\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const UChar*>(arg0), len }, reinterpret_cast<void*>(const_cast<uint16_t*>(arg0)), free_global_string)")
                (("ExternalStringImpl::create\\(reinterpret_cast<const UChar\\*>\\(Zig::untag\\(str\\.ptr\\)\\), str\\.len, Zig::untagVoid\\(str\\.ptr\\), free_global_string\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const UChar*>(Zig::untag(str.ptr)), str.len }, Zig::untagVoid(str.ptr), free_global_string)")
                (("ExternalStringImpl::create\\(Zig::untag\\(str\\.ptr\\), str\\.len, Zig::untagVoid\\(str\\.ptr\\), free_global_string\\)")
                 "ExternalStringImpl::create({ Zig::untag(str.ptr), str.len }, Zig::untagVoid(str.ptr), free_global_string)")
                (("ExternalStringImpl::create\\(reinterpret_cast<const UChar\\*>\\(Zig::untag\\(str\\.ptr\\)\\), str\\.len, arg2, ArgFn3\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const UChar*>(Zig::untag(str.ptr)), str.len }, arg2, ArgFn3)")
                (("ExternalStringImpl::create\\(reinterpret_cast<const LChar\\*>\\(Zig::untag\\(str\\.ptr\\)\\), str\\.len, arg2, ArgFn3\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const LChar*>(Zig::untag(str.ptr)), str.len }, arg2, ArgFn3)")
                (("ExternalStringImpl::create\\(reinterpret_cast<const UChar\\*>\\(Zig::untag\\(str\\.ptr\\)\\), str\\.len, nullptr, ArgFn2\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const UChar*>(Zig::untag(str.ptr)), str.len }, nullptr, ArgFn2)")
                (("ExternalStringImpl::create\\(reinterpret_cast<const LChar\\*>\\(Zig::untag\\(str\\.ptr\\)\\), str\\.len, nullptr, ArgFn2\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const LChar*>(Zig::untag(str.ptr)), str.len }, nullptr, ArgFn2)")
                (("m_codeBlock->unlinkedCodeBlock\\(\\)->expressionRangeForBytecodeIndex\\(")
                 "auto expressionInfo = m_codeBlock->expressionInfoForBytecodeIndex(bytecodeOffset);")
                (("bytecodeOffset, divotPoint, startOffset, endOffset, line, unusedColumn\\);")
                 "startOffset = expressionInfo.startOffset;\n    endOffset = expressionInfo.endOffset;\n    divotPoint = expressionInfo.divot;\n    auto lineColumn = m_codeBlock->lineColumnForBytecodeIndex(bytecodeOffset);\n    line = lineColumn.line;\n    unusedColumn = lineColumn.column;"))
              (substitute* "src/bun.js/bindings/sqlite/JSSQLStatement.cpp"
                (("WTF::String::fromUTF8\\(name, len\\)")
                 "WTF::String::fromUTF8({ name, len })")
                (("WTF::String::fromUTF8\\(text, len\\)")
                 "WTF::String::fromUTF8({ text, len })")
                (("WTF::String::fromUTF8\\(string, length\\)")
                 "WTF::String::fromUTF8({ string, length })"))
              (substitute* "src/bun.js/bindings/ErrorStackTrace.cpp"
                (("visitor->isWasmFrame\\(\\)")
                 "visitor->codeType() == JSC::StackVisitor::Frame::Wasm")
                (("m_codeBlock->unlinkedCodeBlock\\(\\)->expressionRangeForBytecodeIndex\\(bytecodeIndex, divotPoint, startOffset, endOffset, line, unusedColumn\\);")
                 "auto expressionInfo = m_codeBlock->expressionInfoForBytecodeIndex(bytecodeIndex);\n    startOffset = expressionInfo.startOffset;\n    endOffset = expressionInfo.endOffset;\n    divotPoint = expressionInfo.divot;\n    auto lineColumn = m_codeBlock->lineColumnForBytecodeIndex(bytecodeIndex);\n    line = lineColumn.line;\n    unusedColumn = lineColumn.column;"))
              (substitute* "src/bun.js/bindings/InternalModuleRegistry.cpp"
                (("JSC::makeSource\\(SOURCE, origin, moduleName\\)")
                 "JSC::makeSource(SOURCE, origin, JSC::SourceTaintedOrigin::Untainted, moduleName)")
                (("ConstructAbility::CannotConstruct\\)")
                 "ConstructAbility::CannotConstruct, JSC::InlineAttribute::None)"))
              ;; Newer libc++/libstdc++ combinations can exceed constexpr
              ;; evaluation limits on these very large generated literals.
              (substitute* "src/js/out/InternalModuleRegistryConstants.h"
                (("static constexpr ASCIILiteral")
                 "static const ASCIILiteral"))
              (substitute* "src/bun.js/bindings/BunString.cpp"
                (("startsWith\\(bytes, length\\)")
                 "startsWith({ bytes, length })")
                (("createWithoutCopying\\(bytes, length\\)")
                 "createWithoutCopying({ bytes, length })")
                (("fromUTF8ReplacingInvalidSequences\\(reinterpret_cast<const LChar\\*>\\(bytes\\), length\\)")
                 "fromUTF8ReplacingInvalidSequences({ reinterpret_cast<const LChar*>(bytes), length })")
                (("StringImpl::create\\(bytes, length\\)")
                 "StringImpl::create({ bytes, length })")
                (("ExternalStringImpl::create\\(reinterpret_cast<const LChar\\*>\\(bytes\\), length, ctx, callback\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const LChar*>(bytes), length }, ctx, callback)")
                (("ExternalStringImpl::create\\(reinterpret_cast<const UChar\\*>\\(bytes\\), length, ctx, callback\\)")
                 "ExternalStringImpl::create({ reinterpret_cast<const UChar*>(bytes), length }, ctx, callback)"))
              (substitute* "src/bun.js/bindings/workaround-missing-symbols.cpp"
                (("#include <errno.h>")
                 "#include <errno.h>\n#include <cstdlib>"))
              (substitute* "src/bun.js/bindings/wtf-bindings.cpp"
                (("WTF::parseDouble\\(string, length, \\*position\\)")
                 "WTF::parseDouble(WTF::StringView({ string, length }), *position)")
                (("WTF::StringImpl::copyCharacters\\(destination, source, length\\);")
                 "WTF::StringImpl::copyCharacters(destination, { source, length });"))
              (substitute* "src/bun.js/bindings/ZigSourceProvider.h"
                ((": Base\\(sourceOrigin, WTFMove\\(sourceURL\\), String\\(\\), startPosition, sourceType\\)")
                 ": Base(sourceOrigin, WTFMove(sourceURL), String(), JSC::SourceTaintedOrigin::Untainted, startPosition, sourceType)"))
              (substitute* "src/bun.js/bindings/NodeVMScript.cpp"
                (("options\\.filename, TextPosition\\(options\\.lineOffset, options\\.columnOffset\\)")
                 "options.filename, JSC::SourceTaintedOrigin::Untainted, TextPosition(options.lineOffset, options.columnOffset)"))
              (substitute* "src/bun.js/bindings/Path.cpp"
                (("uncheckedAppend")
                 "append"))
              (substitute* "src/bun.js/bindings/Serialization.cpp"
                (("Vector<uint8_t> vector\\(bytes, size\\);")
                 "Vector<uint8_t> vector({ bytes, size });"))
              (substitute* "src/bun.js/bindings/ZigGeneratedClasses.cpp"
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(Blob__estimatedSize\\(instance->wrapped\\(\\)\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(instance, Blob__estimatedSize(instance->wrapped()));")
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(Blob__estimatedSize\\(ptr\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(instance, Blob__estimatedSize(ptr));")
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(Request__estimatedSize\\(instance->wrapped\\(\\)\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(instance, Request__estimatedSize(instance->wrapped()));")
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(Request__estimatedSize\\(ptr\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(instance, Request__estimatedSize(ptr));")
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(Response__estimatedSize\\(instance->wrapped\\(\\)\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(instance, Response__estimatedSize(instance->wrapped()));")
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(Response__estimatedSize\\(ptr\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(instance, Response__estimatedSize(ptr));"))
              (substitute* (list "src/bun.js/bindings/webcore/HTTPHeaderNames.gperf"
                                 "src/bun.js/bindings/webcore/HTTPHeaderNames.cpp")
                (("return StringView \\{ reinterpret_cast<const LChar\\*>\\(name\\.name\\), static_cast<unsigned>\\(name\\.length\\) \\};")
                 "return StringView(std::span<const LChar> { reinterpret_cast<const LChar*>(name.name), static_cast<unsigned>(name.length) });"))
              (substitute* "src/bun.js/bindings/webcore/JSAbortSignalCustom.cpp"
                (("\\*reason = \"EventTarget firing event listeners\";")
                 "*reason = WTF::ASCIILiteral::fromLiteralUnsafe(\"EventTarget firing event listeners\");"))
              (substitute* "src/bun.js/bindings/webcore/JSBroadcastChannel.cpp"
                (("\\*reason = \"ActiveDOMObject with pending activity\";")
                 "*reason = WTF::ASCIILiteral::fromLiteralUnsafe(\"ActiveDOMObject with pending activity\");"))
              (substitute* "src/bun.js/bindings/webcore/JSFetchHeaders.cpp"
                (("globalObject\\(\\)->vm\\(\\)\\.heap\\.reportExtraMemoryAllocated\\(m_memoryCost\\);")
                 "globalObject()->vm().heap.reportExtraMemoryAllocated(this, m_memoryCost);"))
              (substitute* "src/bun.js/bindings/webcore/JSMessageEvent.cpp"
                (("vm\\.heap\\.reportExtraMemoryAllocated\\(wrapped\\(\\)\\.memoryCost\\(\\)\\);")
                 "vm.heap.reportExtraMemoryAllocated(this, wrapped().memoryCost());"))
              (substitute* "src/bun.js/bindings/webcore/WebSocket.cpp"
                (("builder\\.append\\(\"\\\\+\"\\);")
                 "builder.append(\"\\\\\\\\\"_s);")
                (("builder\\.append\\(separator\\);")
                 "builder.append(WTF::ASCIILiteral::fromLiteralUnsafe(separator));")
                (("didReceiveBinaryData\\(\"message\"_s, \\{ bytes, len \\}\\);")
                 "didReceiveBinaryData(\"message\"_s, Vector<uint8_t>(std::span<const uint8_t> { bytes, len }));")
                (("didReceiveBinaryData\\(\"ping\"_s, \\{ bytes, len \\}\\);")
                 "didReceiveBinaryData(\"ping\"_s, Vector<uint8_t>(std::span<const uint8_t> { bytes, len }));")
                (("didReceiveBinaryData\\(\"pong\"_s, \\{ bytes, len \\}\\);")
                 "didReceiveBinaryData(\"pong\"_s, Vector<uint8_t>(std::span<const uint8_t> { bytes, len }));"))
              (substitute* "src/bun.js/bindings/webcore/HTTPHeaderMap.cpp"
                (("findHTTPHeaderName\\(StringView\\(nameCharacters, length\\), headerName\\)")
                 "findHTTPHeaderName(StringView({ nameCharacters, length }), headerName)")
                (("setUncommonHeader\\(String\\(nameCharacters, length\\), value\\);")
                 "setUncommonHeader(String({ nameCharacters, length }), value);"))
              (substitute* "src/bun.js/bindings/webcore/HTTPParsers.cpp"
                (("return String\\(p, length\\);")
                 "return String::fromUTF8({ reinterpret_cast<const char*>(p), length });")
                (("StringView\\(p, length\\)")
                 "StringView({ reinterpret_cast<const char*>(p), length })")
                (("parseDateFromNullTerminatedCharacters\\(value\\.utf8\\(\\)\\.data\\(\\)\\)")
                 "WTF::parseDate(value.span8())")
                (("nameStr = StringView\\(namePtr, nameSize\\);")
                 "nameStr = StringView({ reinterpret_cast<const char*>(namePtr), nameSize });")
                (("String::fromUTF8\\(value\\.data\\(\\), value\\.size\\(\\)\\)")
                 "String::fromUTF8({ reinterpret_cast<const char*>(value.data()), value.size() })")
                (("body\\.append\\(data, length\\);")
                 "body.append(std::span<const uint8_t> { data, length });")
                (("body\\.append\\(\\{ data, length \\}\\);")
                 "body.append(std::span<const uint8_t> { data, length });"))
              (substitute* "src/bun.js/bindings/webcore/SharedBuffer.cpp"
                (("combinedData\\.append\\(segment\\.segment->data\\(\\), segment\\.segment->size\\(\\)\\);")
                 "combinedData.append(std::span<const uint8_t> { segment.segment->data(), segment.segment->size() });")
                (("combinedData\\.append\\(element->segment->data\\(\\) \\+ offsetInSegment, element->segment->size\\(\\) - offsetInSegment\\);")
                 "combinedData.append(std::span<const uint8_t> { element->segment->data() + offsetInSegment, element->segment->size() - offsetInSegment });")
                (("combinedData\\.append\\(element->segment->data\\(\\), canCopy\\);")
                 "combinedData.append(std::span<const uint8_t> { element->segment->data(), canCopy });")
                (("DataSegment::create\\(Vector \\{ data, length \\}\\)")
                 "DataSegment::create(Vector<uint8_t>(std::span<const uint8_t> { data, length }))")
                (("data\\.append\\(currentSegment->segment->data\\(\\) \\+ offsetInSegment, availableInSegment\\);")
                 "data.append(std::span<const uint8_t> { currentSegment->segment->data() + offsetInSegment, availableInSegment });")
                (("data\\.append\\(currentSegment->segment->data\\(\\), lengthInSegment\\);")
                 "data.append(std::span<const uint8_t> { currentSegment->segment->data(), lengthInSegment });")
                (("if \\(!WTF::Unicode::convertLatin1ToUTF8\\(&d, d \\+ length, &p, p \\+ buffer\\.size\\(\\)\\)\\)")
                 "if (([&] { auto conversionResult = WTF::Unicode::convert(std::span<const LChar> { d, length }, std::span<char8_t> { reinterpret_cast<char8_t*>(p), buffer.size() }); p = reinterpret_cast<char*>(conversionResult.buffer.data() + conversionResult.buffer.size()); return conversionResult.code != WTF::Unicode::ConversionResultCode::Success; })())")
                (("if \\(WTF::Unicode::convertUTF16ToUTF8\\(&d, d \\+ length, &p, p \\+ buffer\\.size\\(\\)\\) != WTF::Unicode::ConversionResult::Success\\)")
                 "if (([&] { auto conversionResult = WTF::Unicode::convert(std::span<const char16_t> { reinterpret_cast<const char16_t*>(d), length }, std::span<char8_t> { reinterpret_cast<char8_t*>(p), buffer.size() }); p = reinterpret_cast<char*>(conversionResult.buffer.data() + conversionResult.buffer.size()); return conversionResult.code != WTF::Unicode::ConversionResultCode::Success; })())"))
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
                 "String jwkString = String::fromUTF8({ reinterpret_cast<const char*>(bytes.data()), bytes.size() });"))
              (substitute* "src/bun.js/bindings/webcore/SerializedScriptValue.cpp"
                (("buffer\\.append\\(reinterpret_cast<uint8_t\\*>\\(&value\\), sizeof\\(value\\)\\);")
                 "buffer.append(std::span<const uint8_t> { reinterpret_cast<uint8_t*>(&value), sizeof(value) });")
                (("buffer\\.append\\(reinterpret_cast<const uint8_t\\*>\\(values\\), length \\* sizeof\\(T\\)\\);")
                 "buffer.append(std::span<const uint8_t> { reinterpret_cast<const uint8_t*>(values), length * sizeof(T) });")
                (("buffer\\.append\\(values, length\\);")
                 "buffer.append(std::span<const uint8_t> { values, length });")
                (("str = String \\{ ptr, length \\};")
                 "str = String({ reinterpret_cast<const LChar*>(ptr), length });")
                (("str = String\\(reinterpret_cast<const UChar\\*>\\(ptr\\), length\\);")
                 "str = String({ reinterpret_cast<const UChar*>(ptr), length });")
                (("str = Identifier::fromString\\(vm, reinterpret_cast<const LChar\\*>\\(ptr\\), length\\);")
                 "str = Identifier::fromString(vm, { reinterpret_cast<const LChar*>(ptr), length });")
                (("str = Identifier::fromString\\(vm, reinterpret_cast<const UChar\\*>\\(ptr\\), length\\);")
                 "str = Identifier::fromString(vm, { reinterpret_cast<const UChar*>(ptr), length });")
                (("result\\.append\\(m_ptr, size\\);")
                 "result.append(std::span<const uint8_t> { m_ptr, size });")
                (("ErrorInstance::create\\(m_lexicalGlobalObject, WTFMove\\(message\\), toErrorType\\(serializedErrorType\\), line, column, WTFMove\\(sourceURL\\), WTFMove\\(stackString\\)\\)")
                 "ErrorInstance::create(m_lexicalGlobalObject, WTFMove(message), toErrorType(serializedErrorType), JSC::LineColumn { line, column }, WTFMove(sourceURL), WTFMove(stackString))"))
              (substitute* "src/bun.js/bindings/webcore/JSDOMConvertSequences.h"
                (("uncheckedAppend")
                 "append"))))
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
                ;; this tarball.  Build/link required dep objects explicitly.
                ;; The release tarball also flattens picohttpparser and omits
                ;; mimalloc sources, so provide those expected build inputs.
                (let* ((mimalloc-lib (string-append (assoc-ref inputs "mimalloc")
                                                    "/lib"))
                       (mimalloc-objects (find-files mimalloc-lib
                                                     "^mimalloc\\.o$")))
                  (unless (pair? mimalloc-objects)
                    (error "mimalloc.o not found in mimalloc input"
                           mimalloc-lib))
                  (mkdir-p "src/deps/picohttpparser")
                  (when (file-exists? "src/deps/picohttpparser/picohttpparser.c")
                    (delete-file "src/deps/picohttpparser/picohttpparser.c"))
                  (copy-file "src/deps/picohttpparser.c"
                             "src/deps/picohttpparser/picohttpparser.c")
                  (copy-file (car mimalloc-objects)
                             "src/deps/libmimalloc.o"))

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

                (invoke "make" "sqlite")
                (invoke "make" "picohttp")
                (invoke "make" "uws")
                (let ((cpus (or (getenv "NIX_BUILD_CORES") "1")))
                  ;; Temporary, for diagnosing the JS-execution hang: the
                  ;; `release-only' target strips the binary itself, which
                  ;; defeats #:strip-binaries? #f.  A command-line variable
                  ;; overrides the Makefile's own STRIP assignment.
                  (invoke "make" "release-only"
                          (string-append "CPUS=" cpus)
                          "STRIP=true")))))
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
     `(("webkit-prebuilt" ,webkit-prebuilt-stage0)
       ("cmake-minimal" ,cmake-minimal)
       ("ninja" ,ninja)
       ("pkg-config" ,pkg-config)
       ("mimalloc" ,mimalloc-3.1)
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
     (list glibc))
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
         "1byw1rbvsizm079isfxp3hz6s5x76hpskdpfn9xkhh73admkj54p"))))
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
          (add-before 'build 'prepare-offline-tree
            (lambda* (#:key inputs #:allow-other-keys)
              (invoke "cp" "-a"
                      (string-append (assoc-ref inputs "offline-seed") "/.")
                      ".")
              (invoke "chmod" "-R" "u+w" ".")

              ;; Preserve offline seed content but mark it newer than CMake
              ;; sources so download rules are considered up to date.
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
                    (display "#!/bin/sh\nexec " port)
                    (display esbuild port)
                    (display " \"$@\"\n" port)))
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
                        "    ('bun-fallback-decoder', 'Skipping fallback-decoder target; using preseeded output'),\n"
                        "    ('bun-runtime-js', 'Skipping runtime.out.js target; using preseeded output'),\n"
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
            (lambda _
              (let* ((cache (string-append (getcwd) "/build/release/cache"))
                     (webkit (string-append cache "/webkit-9a2cc42ae1bf693a"))
                     (extracted (string-append cache "/bun-webkit")))
                (mkdir-p cache)
                (invoke "tar" "xf" #$webkit-prebuilt-1.3.8 "-C" cache)
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
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "HOME" (getcwd))
              (setenv "BUN_DEBUG_QUIET_LOGS" "1")
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; Run build-time codegen with the source-built stage0 Bun, so
              ;; that no prebuilt Bun binary takes part in the build.
              (setenv "PATH"
                      (string-append (assoc-ref inputs "bun-stage0")
                                     "/bin:"
                                     (getenv "PATH")))
              ;; Use full local parallelism for CMake/Ninja.
              (setenv "CMAKE_BUILD_PARALLEL_LEVEL" "16")
              ;; Guix kills builds that stay silent for too long; emit periodic
              ;; keepalive lines while CMake/Ninja compile.
              (invoke "bash" "-lc"
                      "set -euo pipefail\n(while true; do echo \"[guix-heartbeat] bun-from-source build still running\"; sleep 60; done) &\nhb_pid=$!\ntrap 'kill \"$hb_pid\" 2>/dev/null || true' EXIT\npython3 - <<'PY'\nimport glob\nimport json\nimport re\nfrom pathlib import Path\n\nroot = Path('.').resolve()\n\ndef expand_braces(pattern):\n    start = pattern.find('{')\n    if start == -1:\n        return [pattern]\n    depth = 0\n    end = -1\n    for i, ch in enumerate(pattern[start:], start):\n        if ch == '{':\n            depth += 1\n        elif ch == '}':\n            depth -= 1\n            if depth == 0:\n                end = i\n                break\n    if end == -1:\n        return [pattern]\n    inside = pattern[start + 1:end]\n    parts = []\n    buf = ''\n    depth = 0\n    for ch in inside:\n        if ch == ',' and depth == 0:\n            parts.append(buf)\n            buf = ''\n        else:\n            if ch == '{':\n                depth += 1\n            elif ch == '}':\n                depth -= 1\n            buf += ch\n    parts.append(buf)\n    out = []\n    prefix = pattern[:start]\n    suffix = pattern[end + 1:]\n    for part in parts:\n        for rest in expand_braces(suffix):\n            out.extend(expand_braces(prefix + part + rest))\n    return out\n\ndef to_zig_namespace(name):\n    result = re.sub(r'([^A-Z_])([A-Z])', r'\\1_\\2', name)\n    result = re.sub(r'([A-Z])([A-Z][a-z])', r'\\1_\\2', result)\n    result = result.lower()\n    if result == name:\n        return result + '_namespace'\n    return result\n\nitems = json.loads((root / 'cmake' / 'Sources.json').read_text())\nfor item in items:\n    excludes = set(item.get('exclude', []))\n    excludes.update({\n        'src/bun.js/bindings/GeneratedBindings.zig',\n        'src/bun.js/bindings/GeneratedJS2Native.zig',\n    })\n    rels = []\n    for pat in item['paths']:\n        for expanded in expand_braces(pat):\n            for match in glob.glob(expanded, recursive=True):\n                path = Path(match)\n                if not path.is_file():\n                    continue\n                rel = path.as_posix()\n                if rel in excludes:\n                    continue\n                rels.append(rel)\n    rels = sorted(set(rels))\n    out = root / 'cmake' / 'sources' / item['output']\n    out.parent.mkdir(parents=True, exist_ok=True)\n    out.write_text(('\\n'.join(rels) + '\\n') if rels else '')\n\n# Precompute bindgenv2 outputs so CMake does not invoke bun-stage0 for\n# --command=list-outputs (it can hang there).\nbindgen_sources = root / 'cmake' / 'sources' / 'BindgenV2Sources.txt'\ncodegen_path = root / 'build' / 'release' / 'codegen'\ncodegen_path.mkdir(parents=True, exist_ok=True)\nbindgen_outputs = [f\"{codegen_path.as_posix()}/bindgen_generated.zig\"]\nseen = set()\nif bindgen_sources.exists():\n    for rel in bindgen_sources.read_text().splitlines():\n        rel = rel.strip()\n        if not rel:\n            continue\n        src = root / rel\n        if not src.is_file():\n            continue\n        text = src.read_text()\n        for name, kind in re.findall(\n            r'export\\s+const\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*b\\.(dictionary|enumeration|union)\\s*\\(',\n            text,\n        ):\n            key = (name, kind)\n            if key in seen:\n                continue\n            seen.add(key)\n            if kind in {'dictionary', 'enumeration'}:\n                bindgen_outputs.append(\n                    f\"{codegen_path.as_posix()}/Generated{name}.cpp\"\n                )\n            bindgen_outputs.append(\n                f\"{codegen_path.as_posix()}/bindgen_generated/{to_zig_namespace(name)}.zig\"\n            )\n\n(codegen_path / 'bindgenv2-outputs.txt').write_text(';'.join(bindgen_outputs))\nPY\nmkdir -p build/release/codegen/bun-error build/release/codegen/node-fallbacks\ncp -f packages/bun-error/bun-error.css build/release/codegen/bun-error/bun-error.css\ncat > build/release/codegen/bun-error/index.js <<'EOF'\nexport default {};\nEOF\nfor f in src/node-fallbacks/*.js; do\n  [ -f \"$f\" ] || continue\n  cp -f \"$f\" build/release/codegen/node-fallbacks/\ndone\ncat > build/release/codegen/node-fallbacks/react-refresh.js <<'EOF'\nmodule.exports = {};\nEOF\ncat > build/release/codegen/fallback-decoder.js <<'EOF'\nexport default {};\nEOF\ncat > build/release/codegen/runtime.out.js <<'EOF'\nexport default {};\nEOF\nBUN_EXE=\"$(command -v bun)\"\necho \"[guix-heartbeat] using bun executable: ${BUN_EXE}\"\n\"${BUN_EXE}\" --version\nrm -f build/release/CMakeCache.txt\ncmake -S . -B build/release -GNinja -DCMAKE_BUILD_TYPE=Release -DCACHE_STRATEGY=auto -DBUN_EXECUTABLE=\"${BUN_EXE}\"\nif [ -f build/release/.env ]; then set -a; . build/release/.env; set +a; fi\ncmake --build build/release --parallel 16")))
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
     `(("offline-seed" ,offline-seed)
       ("bun-stage0" ,bun-stage0)
       ("lezer-common" ,lezer-common-source)
       ("lezer-cpp" ,lezer-cpp-source)
       ("lezer-highlight" ,lezer-highlight-source)
       ("lezer-lr" ,lezer-lr-source)
       ("node-headers" ,node-v24.3.0-headers-source)
       ("cmake-minimal" ,cmake-minimal)
       ("ninja" ,ninja)
       ("pkg-config" ,pkg-config)
       ("clang" ,clang-19)
       ("lld" ,lld-19)
       ("llvm" ,llvm-19)
       ("zig" ,zig-0.14)
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
          (delete 'patch-generated-file-shebangs)
          (add-after 'unpack 'restore-node-modules
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((cache (assoc-ref inputs "node-modules"))
                     (root-modules (string-append cache "/node_modules"))
                     (desktop-modules
                      (string-append cache "/packages/desktop/node_modules"))
                     (opencode-modules
                      (string-append cache "/packages/opencode/node_modules")))
                ;; Keep the large workspace cache out of /tmp by symlinking the
                ;; root node_modules tree from the immutable store.
                (when (file-exists? "node_modules")
                  (delete-file-recursively "node_modules"))
                (symlink root-modules "node_modules")
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
              (restore-input-symlink-tree
               inputs
               '(("packages/app/node_modules" . "app-node-modules")
                 ("packages/enterprise/node_modules" . "enterprise-node-modules")
                 ("packages/function/node_modules" . "function-node-modules")
                 ("packages/plugin/node_modules" . "plugin-node-modules")
                 ("packages/script/node_modules" . "script-node-modules")
                 ("packages/slack/node_modules" . "slack-node-modules")
                 ("packages/ui/node_modules" . "ui-node-modules")
                 ("packages/util/node_modules" . "util-node-modules")
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
