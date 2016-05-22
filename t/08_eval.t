#!/usr/bin/guile -s
!#
; python-eval tests.
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

(plan 7)

(is-ok 1 "regular python-eval"
       42
       (python-eval "7*3*2" #t))


; Run python-eval under catch harness.
(define catch-test-eval
  (lambda (txt retval)
    (catch #t
	   (lambda () (python-eval txt retval))
	   (lambda (key . args) (object->string (list key args))))))

(is-ok 2 "trying to run python-eval on non-string"
       "(wrong-type-arg (\"python-eval\" \"Wrong type argument in position ~A: ~S\" (1 -42) #f))"
       (catch-test-eval -42 #t))

(is-ok 3 "trying to run python-eval with non-boolean/non-P2G_SMOB argument"
       "(misc-error (\"p2g_apply\" \"bad template item ~S\" (42) #f))"
       (catch-test-eval "7*3*2" 42))

(like 4 "Raising exception inside python-eval f"
	   "\\(misc-error \\(\"python-eval\" \"Python exception: ~A\" \\(\"<class exceptions.ImportError at 0x[0-9a-f]{8}>\"\\) #f\\)\\)"
	   (catch-test-eval "import t7except\nraiser('xyzzy')\n" #f))

(python-eval "import sys;sys.path = ['']+sys.path\n")
(python-eval "from t.scripts.t7except import raiser")
(like 5 "Raising exception inside python-eval t"
	   "^\\(misc-error \\(\"python-eval\" \"Python exception: ~A\" \\(\"<class t.scripts.t7except.myexception at 0x[0-9a-f]{8}>\"\\) #f\\)\\)$"
	   (catch-test-eval "1+raiser('foo fee dom')" #t))

(like 6 "code does not return requested result"
      "^\\(misc-error \\(\"python-eval\" \"Python exception: ~A\" \\(\"<class exceptions.SyntaxError at 0x[0-9a-f]{8}>\"\\) #f\\)\\)$"
      (catch-test-eval "print '# no value was returned'\n" #t))

(is-ok 7 "code returns unsolicited result"
       "#<unspecified>"
       (object->string (python-eval "99+101" #f)))

; End of 08_eval.t
