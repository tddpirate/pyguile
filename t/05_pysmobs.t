#!/usr/bin/guile -s
!#
; PyGuile tests - exercise pysmob handling.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Copyright (C) 2008 Omer Zak.
; This library is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; Lesser General Public License for more details.
;
; You should have received a copy of the GNU Lesser General Public License
; along with this library, in a file named COPYING; if not, write to the
; Free Software Foundation, Inc., 59 Temple Place, Suite 330,
; Boston, MA  02111-1307  USA
;
; For licensing issues, contact <w1@zak.co.il>.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(use-modules (guiletap))
(use-modules (pyguile))

(plan 12)
(python-eval "import sys;sys.path = ['']+sys.path\n")
(define t5smobs (python-import "t.scripts.t5smobs"))

(is-ok 1 "Creation and repr" "opaq('abc')"
       (python-apply '("__builtin__" "repr")
		     (list (python-apply '("t.scripts.t5smobs" "opaq")
					 '("abc") '()))
		     '()))

(is-ok 2 "Creation and object->string" "(python-eval opaq('abcd') #t)"
       (object->string
	(python-apply '("t.scripts.t5smobs" "opaq")
		      '("abcd")
		      '())))

(define objt (python-apply '("t.scripts.t5smobs" "opaq")
			   '(37)
			   '()))
(is-ok 3 "Created opaq with numeric value" "(python-eval opaq(37) #t)"
       (object->string objt))

(python-apply (list objt "transform") '() '())
(is-ok 4 "After transforming opaq with numeric value"
       "(python-eval opaq(74) #t)"
       (object->string objt))

(define objl (python-apply '("t.scripts.t5smobs" "opaq")
			   '(("el1" "el2"))
			   '()))
(is-ok 5 "opaq with list value"
       "(python-eval opaq(['el1', 'el2']) #t)"
       (object->string objl))

(python-apply (list objl "transform") '() '())
(is-ok 6 "opaq with list value"
       "(python-eval opaq(['el1', 'el2', 'el1', 'el2']) #t)"
       (object->string objl))

(define equalities3?
  (lambda (obj1 obj2)
    (list (eq? obj1 obj2) (eqv? obj1 obj2) (equal? obj1 obj2))))

(is-ok 7 "verify equalities3?"
       '(#f #f #t)
       (equalities3? '("a" "b") '("a" "b")))

(define nd1 (python-apply (list t5smobs 'noisydelete) '("nd1a") '()))
(define nd2 (python-apply (list t5smobs 'noisydelete) '("nd2b") '()))
(define nd1same nd1)
(define nd1equal (python-apply (list t5smobs 'noisydelete) '("nd1a") '()))

(is-ok 8 "two different pysmobs"
       '(#f #f #f)
       (equalities3? nd1 nd2))

(is-ok 9 "two identical pysmobs"
       '(#t #t #t)
       (equalities3? nd1 nd1same))

(is-ok 10 "two equal pysmobs"
       '(#f #f #t)
       (equalities3? nd1 nd1equal))

(define nd-me (python-apply (list t5smobs 'noisydelete) '("me") '()))
(define nd-41 (python-apply (list t5smobs 'noisydelete) '(41) '()))
(define nd-42 (python-apply (list t5smobs 'noisydelete) '(42) '()))

(is-ok 11 "'me'!=41 to validate t5smobs.noisydelete.__cmp__ test"
       '(#f #f #f)
       (equalities3? nd-me nd-41))

(is-ok 12 "'me'==42 to prove t5smobs.noisydelete.__cmp__ is being executed"
       '(#f #f #t)
       (equalities3? nd-me nd-42))


; The following tests do not work as expected and I do not have yet
; a way to capture outputs.
; !!! Check strports.h (object->string, scm_object_to_string).

; Garbage collection behavior of pysmobs.
(define noisydel (python-apply (list t5smobs 'noisydelete) '("BOO!") '()))
(diagprint 1001 "verify noisydel object"
       "'BOO!'"
       (python-apply '("__builtin__" repr) (list noisydel) '()))
(display "# Forcing garbage collection...")
(gc)
(display "Done")(newline)
(diagprint 1002 "verify noisydel object after gc"
       "'BOO!'"
       (python-apply '("__builtin__" repr) (list noisydel) '()))
(set! noisydel "losing reference")
(display "# Forcing another garbage collection...")
(gc)
(display "Done - should show deletion of noisydel")
(newline)
(display "# ")(display noisydel)(newline)
(python-eval "import gc\ngc.collect()\n")
; End of 05_pysmobs.t
