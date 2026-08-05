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

(define-module (guix build bun-build-system)
  #:use-module ((guix build gnu-build-system) #:prefix gnu:)
  #:use-module (guix build utils)
  #:use-module (json)
  #:use-module (ice-9 match)
  #:export (%standard-phases
            restore-input-symlink-tree
            bun-build))

(define* (assoc-ref* alist key #:optional default)
  "Like assoc-ref, but return DEFAULT instead of #f if no value exists."
  (match (assoc key alist)
    (#f default)
    ((_ . value) value)))

(define (package-metadata)
  (and (file-exists? "package.json")
       (call-with-input-file "package.json" json->scm)))

(define (script-defined? package-meta script)
  (and package-meta
       (let ((scripts (assoc-ref* package-meta "scripts" '())))
         (and (list? scripts)
              (assoc-ref scripts script)))))

(define (set-home . _)
  (with-directory-excursion ".."
    (let loop ((i 0))
      (let ((dir (string-append "bun-home-" (number->string i))))
        (if (directory-exists? dir)
            (loop (1+ i))
            (begin
              (mkdir dir)
              (setenv "HOME" (string-append (getcwd) "/" dir))
              (format #t "set HOME to ~s~%" (getenv "HOME")))))))
  #t)

(define (lockfile-present?)
  (or (file-exists? "bun.lock")
      (file-exists? "bun.lockb")))

(define (lockfile-mode->flags lockfile-mode)
  (cond
   ((equal? lockfile-mode "auto")
    (if (lockfile-present?)
        '("--frozen-lockfile")
        '()))
   ((equal? lockfile-mode "frozen")
    '("--frozen-lockfile"))
   ((equal? lockfile-mode "update")
    '())
   (else
    (error "invalid lockfile-mode, expected one of auto/frozen/update"
           lockfile-mode))))

(define* (configure #:key inputs
                    (offline? #t)
                    (lockfile-mode "auto")
                    (bun-install-flags '())
                    (install-scripts? #f)
                    #:allow-other-keys)
  (if (file-exists? "package.json")
      (let ((bun (string-append (assoc-ref inputs "bun") "/bin/bun")))
        (apply invoke bun "install"
               (append (lockfile-mode->flags lockfile-mode)
                       (if offline? '("--offline") '())
                       ;; Skip lifecycle scripts by default since they often
                       ;; pull prebuilt binaries from remote sources.
                       (if install-scripts?
                           '()
                           '("--ignore-scripts"))
                       bun-install-flags)))
      (format #t "no package.json found; skipping bun install~%"))
  #t)

(define* (build #:key inputs (bun-flags '()) #:allow-other-keys)
  (let ((package-meta (package-metadata)))
    (if (script-defined? package-meta "build")
        (let ((bun (string-append (assoc-ref inputs "bun") "/bin/bun")))
          (apply invoke bun "run" "build" bun-flags))
        (format #t "there is no build script to run~%")))
  #t)

(define* (check #:key tests? inputs test-target (bun-flags '())
                #:allow-other-keys)
  (if tests?
      (let ((package-meta (package-metadata)))
        (if (script-defined? package-meta test-target)
            (let ((bun (string-append (assoc-ref inputs "bun") "/bin/bun")))
              (apply invoke bun "run" test-target bun-flags))
            (format #t "there is no test script ~s to run~%" test-target)))
      (format #t "test suite not run~%"))
  #t)

(define* (install #:key outputs #:allow-other-keys)
  "Install built artifacts under OUT."
  (let ((out (assoc-ref outputs "out")))
    (mkdir-p out)
    (if (file-exists? "dist")
        (invoke "cp" "-a" "dist/." out)
        (let ((share (string-append out "/share/bun-source")))
          (copy-recursively "." share))))
  #t)

(define* (restore-input-symlink-tree inputs mappings #:key (strict? #t))
  "Restore symlinked paths from INPUTS according to MAPPINGS, a list of
pairs (TARGET . INPUT-NAME)."
  (for-each
   (lambda (mapping)
     (let* ((target (car mapping))
            (input-name (cdr mapping))
            (source (assoc-ref inputs input-name)))
       (cond
        (source
         ;; Use rm(1) so an existing symlink to a directory is removed without
         ;; traversing into the linked tree.
         (when (or (file-exists? target)
                   (false-if-exception (lstat target)))
           (invoke "rm" "-rf" target))
         (mkdir-p (dirname target))
         (symlink source target))
        (strict?
         (error "missing input for restore-input-symlink-tree" input-name))
        (else
         (format #t "missing input ~s; skipping restore of ~s~%"
                 input-name target)))))
   mappings)
  #t)

(define %standard-phases
  (modify-phases gnu:%standard-phases
    (add-after 'unpack 'set-home set-home)
    (replace 'configure configure)
    (replace 'build build)
    (replace 'check check)
    (replace 'install install)))

(define* (bun-build #:key inputs (phases %standard-phases)
                    #:allow-other-keys #:rest args)
  (apply gnu:gnu-build #:inputs inputs #:phases phases args))
