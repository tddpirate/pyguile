#!/usr/bin/guile -s
!#
; python-import tests.
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

(plan 5)

; Run python-import under catch harness.
(define catch-test-import
  (lambda (arg)
    (catch #t
	   (lambda () (python-import arg))
	   (lambda (key . args) (object->string (list key args))))))

(like 1 "good python-import"
	   "^\\(python-eval <module 'math' from '[^']*'> #t\\)$"
	   (object->string (catch-test-import "math")))

(like 2 "nonexistent module"
	   "^\\(misc-error \\(\"python-import\" \"Python exception during module ~A import: ~A\" \\(\"mathalternate\" \"<class exceptions.ImportError at 0x[0-9a-f]{8}>\"\\) #f\\)\\)$"
	   (catch-test-import "mathalternate"))

(is-ok 3 "bad argument datatype"
	   "(wrong-type-arg (\"python-import\" \"Wrong type argument in position ~A: ~S\" (1 2.7818) #f))"
	   (catch-test-import 2.7818))

(is-ok 4 "python-import with symbol"
	   "(wrong-type-arg (\"python-import\" \"Wrong type argument in position ~A: ~S\" (1 os.path) #f))"
	   (catch-test-import 'os.path))

(is-ok 5 "python-import with keyword"
	   "(wrong-type-arg (\"python-import\" \"Wrong type argument in position ~A: ~S\" (1 #:re) #f))"
	   (catch-test-import #:re))


; End of 09_import.t
