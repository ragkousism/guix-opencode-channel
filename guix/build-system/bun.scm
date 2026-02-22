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

(define-module (guix build-system bun)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix monads)
  #:use-module (guix search-paths)
  #:use-module (guix build-system)
  #:use-module (guix build-system gnu)
  #:export (%bun-build-system-modules
            bun-build
            bun-build-system))

(define %bun-build-system-modules
  ;; Build-side modules imported by default.
  `((guix build bun-build-system)
    (json)
    (json builder)
    (json parser)
    (json record)
    ,@%default-gnu-imported-modules))

(define (default-bun)
  "Return the default Bun package, resolved lazily."
  (@* (gnu packages opencode) bun-from-source))

(define* (lower name
                #:key source inputs native-inputs outputs system target
                (bun (default-bun))
                #:allow-other-keys
                #:rest arguments)
  "Return a bag for NAME."
  (define private-keywords
    '(#:target #:bun #:inputs #:native-inputs))

  (and (not target)                    ;XXX: no cross-compilation
       (bag
         (name name)
         (system system)
         (host-inputs `(,@(if source
                              `(("source" ,source))
                              '())
                        ,@inputs
                        ;; Keep the standard inputs of 'gnu-build-system'.
                        ,@(standard-packages)))
         (build-inputs `(("bun" ,bun)
                         ,@native-inputs))
         (outputs outputs)
         (build bun-build)
         (arguments (strip-keyword-arguments private-keywords arguments)))))

(define* (bun-build name inputs
                    #:key
                    source
                    (bun-flags ''())
                    (bun-install-flags ''())
                    (offline? #t)
                    (lockfile-mode "auto")
                    (test-target "test")
                    (tests? #t)
                    (phases '%standard-phases)
                    (outputs '("out"))
                    (search-paths '())
                    (system (%current-system))
                    (guile #f)
                    (imported-modules %bun-build-system-modules)
                    (modules '((guix build bun-build-system)
                               (guix build utils))))
  "Build SOURCE using BUN and INPUTS."
  (define builder
    (with-imported-modules imported-modules
      #~(begin
          (use-modules #$@(sexp->gexp modules))
          (bun-build #:name #$name
                     #:source #+source
                     #:system #$system
                     #:bun-flags #$bun-flags
                     #:bun-install-flags #$bun-install-flags
                     #:offline? #$offline?
                     #:lockfile-mode #$lockfile-mode
                     #:test-target #$test-target
                     #:tests? #$tests?
                     #:phases #$phases
                     #:outputs #$(outputs->gexp outputs)
                     #:search-paths '#$(sexp->gexp
                                        (map search-path-specification->sexp
                                             search-paths))
                     #:inputs #$(input-tuples->gexp inputs)))))

  (mlet %store-monad ((guile (package->derivation (or guile (default-guile))
                                                  system #:graft? #f)))
    (gexp->derivation name builder
                      #:system system
                      #:guile-for-build guile)))

(define bun-build-system
  (build-system
    (name 'bun)
    (description "The Bun build system")
    (lower lower)))
