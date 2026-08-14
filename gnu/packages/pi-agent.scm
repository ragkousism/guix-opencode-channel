;;; Pi Agent, a terminal coding agent written in Rust, and the pieces Guix
;;; does not carry yet.

(define-module (gnu packages pi-agent)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages rust))

;; Guix keeps this private: every Rust is built by the one before it, and the
;; helper that expresses that link is not exported.  Reaching for it is the
;; only way a channel can extend the chain.
(define rust-bootstrapped-package
  (@@ (gnu packages rust) rust-bootstrapped-package))

;; Pi declares rust-version = "1.95" and its locked sysinfo needs the same, so
;; the chain has to go one further than the 1.94 Guix carries.  The nightly
;; that pi's rust-toolchain.toml pins is not needed: there is no #![feature]
;; anywhere in its sources, and the pin exists to keep clippy's lint set from
;; drifting, which is a concern for its CI rather than for a build.
(define-public rust-1.95
  (let ((base-rust
         (rust-bootstrapped-package
          rust-1.94 "1.95.0"
          "05d53hj717ildhvm3rln7821r08nzbbfk72nqcvpb5j67sl856za")))
    (package
      (inherit base-rust)
      (source
       (origin
         (inherit (package-source base-rust))
         ;; The 1.94 clippy race patch is deliberately not carried over: it
         ;; touches a test this build does not run.
         (patches '())
         (snippet
          '(begin
             ;; Bundled C libraries, taken from the 1.95 tarball rather than
             ;; assumed: the list matches 1.94's but for curl-sys 0.4.83.
             (for-each delete-file-recursively
                       '("src/llvm-project"
                         "vendor/curl-sys-0.4.79+curl-8.12.0/curl"
                         "vendor/curl-sys-0.4.83+curl-8.15.0/curl"
                         "vendor/curl-sys-0.4.84+curl-8.17.0/curl"
                         "vendor/jemalloc-sys-0.5.3+5.3.0-patched/jemalloc"
                         "vendor/jemalloc-sys-0.5.4+5.3.0-patched/jemalloc"
                         "vendor/libffi-sys-4.1.0/libffi"
                         "vendor/libz-sys-1.1.21/src/zlib"
                         "vendor/libz-sys-1.1.23/src/zlib"
                         "vendor/libmimalloc-sys-0.1.44/c_src/mimalloc"
                         "vendor/openssl-src-111.28.2+1.1.1w/openssl"
                         "vendor/openssl-src-300.5.0+3.5.0/openssl"
                         "vendor/openssl-src-300.5.4+3.5.4/openssl"
                         "vendor/tikv-jemalloc-sys-0.5.4+5.3.0-patched/jemalloc"
                         "vendor/tikv-jemalloc-sys-0.6.1+5.3.0-1-\
ge13ca993e8ccb9ba9847cc330696e02839f328f7/jemalloc"))
             ;; Prebuilt objects and the bundled Windows libraries.
             (for-each delete-file
                       (find-files "vendor" "\\.(a|dll|exe|lib)$"))
             ;; Use the packaged nghttp2.
             (for-each
              (lambda (ver)
                (let ((vendored-dir
                       (format #f "vendor/libnghttp2-sys-~a/nghttp2" ver))
                      (build-rs
                       (format #f "vendor/libnghttp2-sys-~a/build.rs" ver)))
                  (delete-file-recursively vendored-dir)
                  (delete-file build-rs)
                  (call-with-output-file build-rs
                    (lambda (port)
                      (format port "fn main() {~@
                         println!(\"cargo:rustc-link-lib=nghttp2\");~@
                         }~%")))))
              '("0.1.11+1.64.0"))
             ;; Adjust vendored dependency to explicitly use rustix with libc
             ;; backend.
             (substitute* '("vendor/tempfile-3.14.0/Cargo.toml"
                            "vendor/tempfile-3.16.0/Cargo.toml"
                            "vendor/tempfile-3.19.1/Cargo.toml"
                            "vendor/tempfile-3.20.0/Cargo.toml"
                            "vendor/tempfile-3.21.0/Cargo.toml"
                            "vendor/tempfile-3.23.0/Cargo.toml"
                            "vendor/tempfile-3.24.0/Cargo.toml")
               (("features = \\[\"fs\"" all)
                (string-append all ", \"use-libc\""))))))))))
