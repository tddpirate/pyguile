#!/usr/bin/guile -s
!#
; Additional Pyguile tests - python-apply tests.
; Tests added to complete code coverage.
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

(plan 18)

(python-eval "import sys;sys.path = ['']+sys.path\n")
(python-eval "from t.scripts.t4apply import return_args")
(python-eval "def myfunc():\n  return('this was myfunc')\n")

(define myfunc-smob (python-eval "myfunc" #t))

(is-ok 1 "string funcname" "positional: ('xyzzy',)      keywords: {}"
       (python-apply "return_args" '(xyzzy) '()))

(is-ok 2 "symbol funcname" "positional: ()      keywords: {'arg': 7}"
       (python-apply #:return_args '() '((#:arg . 7))))

(is-ok 3 "pysmob func" "this was myfunc"
       (python-apply myfunc-smob '() '()))

(is-ok 4 "list consisting of pysmob func" "this was myfunc"
       (python-apply (list myfunc-smob) '() '()))


; python-apply funcname tests

(is-ok 5 "funcname not in list and is illegal"
       '(wrong-type-arg ("python-apply" "Wrong type argument in position ~A: ~S" (1 42) #f))
       (catch #t
	      (lambda () (python-apply 42 '("a") '((#:arg1 . "b"))))
	      (lambda (key . args) (list key args))))

(is-ok 6 "funcname in list and is illegal"
      ;like 6: "^\\(misc-error \\(\"python-apply\" \"Python exception: ~A\" \\(\"<class exceptions.TypeError at 0x[0-9a-f]{8}>\"\\) #f\\)\\)$"
      "(misc-error (\"python-apply\" \"function denoted by ~S is not callable\" ((45)) #f))"
       (catch #t
	      (lambda () (python-apply '(45) '("a") '((#:arg1 . "b"))))
	      (lambda (key . args) (object->string (list key args)))))

(is-ok 7 "non-imported module"
	   "(misc-error (\"python-apply\" \"could not dereference ~Ath level attribute in ~S\" (1 (\"math\" sin)) #f))"
       (catch #t
	      (lambda () (python-apply '("math" sin) '(3.14159) '()))
	      (lambda (key . args) (object->string (list key args)))))

(define t2conv (python-import "t.scripts.t2conv"))

; Run python-apply under catch harness.
(define catch-test
  (lambda (func posargs kwargs)
    (catch #t
	   (lambda () (python-apply func posargs kwargs))
	   (lambda (key . args) (object->string (list key args))))))

(is-ok 8 "finding attribute in module by string"
       -5
       (catch-test '("t.scripts.t2conv" "return_Int_5") '() '()))

(is-ok 9 "nonexistent attribute in module by string"
       "(misc-error (\"python-apply\" \"could not dereference ~Ath level attribute in ~S\" (1 (\"t.scripts.t2conv\" \"return_jnt_5\")) #f))"
       (catch-test '("t.scripts.t2conv" "return_jnt_5") '() '()))

(is-ok 10 "finding attribute in module by symbol"
       -5
       (catch-test '("t.scripts.t2conv" return_Int_5) '() '()))

(is-ok 11 "nonexistent attribute in module by symbol"
       "(misc-error (\"python-apply\" \"could not dereference ~Ath level attribute in ~S\" (1 (\"t.scripts.t2conv\" return_jnt_5)) #f))"
       (catch-test '("t.scripts.t2conv" return_jnt_5) '() '()))

(is-ok 12 "finding attribute in module by pysmob"
       -5
       (catch-test (list t2conv "return_Int_5") '() '()))

(is-ok 13 "nonexistent attribute in module by pysmob"
       "(misc-error (\"python-apply\" \"could not dereference ~Ath level attribute in ~S\" (1 ((python-eval <module 't.scripts.t2conv' from 't/scripts/t2conv.pyc'> #t) \"return_jnt_5\")) #f))"
       (catch-test (list t2conv "return_jnt_5") '() '()))

; Python function raises uncaught exception during its work.

(define t7except (python-import "t.scripts.t7except"))

(like 14 "exception inside Python code"
	   "^\\(misc-error \\(\"python-apply\" \"Python exception: ~A\" \\(\"<class t.scripts.t7except.myexception at 0x[0-9a-f]{8}>\"\\) #f\\)\\)$"
	   (catch-test (list t7except 'raiser) '(script7) '()))

(is-ok 15 "kw argument is datum rather than list"
	   "(wrong-type-arg (\"guileassoc2pythondict\" \"Wrong type argument in position ~A: ~S\" (1 \"shut up\") #f))"
	   (catch-test '("__builtin__" repr) '((3 4 5)) "shut up"))

(is-ok 16 "kw argument is pair rather than list"
	   "(wrong-type-arg (\"guileassoc2pythondict\" \"Wrong type argument in position ~A: ~S\" (1 (\"shut\" . \"up\")) #f))"
	   (catch-test '("__builtin__" repr) '((3 4 5)) '("shut" . "up")))

(is-ok 17 "no proc specified"
	   "(wrong-type-arg (\"python-apply\" \"Wrong type argument in position ~A: ~S\" (1 ()) #f))"
	   (catch-test '() '() '()))

(is-ok 18 "nonexistent module"
	   "(misc-error (\"python-apply\" \"could not dereference ~Ath level attribute in ~S\" (1 (\"no.such.module\" repr)) #f))"
	   (catch-test '("no.such.module" repr) '((3 4 5)) '("shut" . "up")))

; End of 07_apply.t
