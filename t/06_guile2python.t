#!/usr/bin/guile -s
!#
; Additional Pyguile tests - transferring data from Guile to Python.
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

(plan 13)

(is-ok 1 "Float 1.5" "1.5"
       (python-apply '("__builtin__" repr) '(1.5) '()))
(is-ok 2 "Float 1000000000.5" "1000000000.5"
       (python-apply '("__builtin__" repr) '(1000000000.5) '()))
(is-ok 3 "Float 1e+20" "1e+20"
       (python-apply '("__builtin__" repr) '(100000000000000000000.5) '()))

(is-ok 4 "Complex" "[(1+1j), (2-3j), (-3-4j), (-4+5j)]"
       (python-apply '("__builtin__" repr) '((1+1i 2-3i -3-4i -4+5i)) '()))

;(if (equal? (effective-version) "1.6")
;    (is-ok 5 "Dash-only keyword" "''"
;		(python-apply '("__builtin__" repr) '(#:) '()))
;    (ok 5 "Dash-only keyword not supported in Guile 1.8" #t))
(ok 5 "Dash-only keyword not supported in Guile 1.8" #t)

;(if (equal? (effective-version) "1.6")
;    (is-ok 6 "String, symbol and keywords (version 1.6.x)"
;		"['abc', 'def', 'ghi', 'gh', 'g', '']"
;		(python-apply '("__builtin__" repr)
;			      '(("abc" def #:ghi #:gh #:g #:))
;			      '()))
;    (is-ok 6 "String, symbol and keywords (version 1.8.x)"
;		"['abc', 'def', 'ghi', 'gh', 'g']"
;		(python-apply '("__builtin__" repr)
;			      '(("abc" def #:ghi #:gh #:g))
;			      '())))
(is-ok 6 "String, symbol and keywords (version 1.8 compatible)"
	    "['abc', 'def', 'ghi', 'gh', 'g']"
	    (python-apply '("__builtin__" repr)
			  '(("abc" def #:ghi #:gh #:g))
			  '()))

; Illegal positional keyword arguments handling

(is-ok 7 "Positional argument list is not legal list"
	   '(misc-error ("python-apply" "positional arguments conversion failure (~S)" (42) #f))
	   (catch #t
		  (lambda () (python-apply '("__builtin__" repr)
					   42
					   '()))
		  (lambda (key . args) (list key args))))


; Illegal keyword arguments handling

(python-eval "import sys;sys.path = ['']+sys.path\n")
(python-import "t.scripts.t4apply")

(is-ok 8 "good alist" "positional: ('a',)      keywords: {'arg1': 'b'}"
       (catch #t
	      (lambda () (python-apply '("t.scripts.t4apply" return_args)
				       '("a")
				       '((#:arg1 . "b"))))
	      (lambda (key . args) (list key args))))

(is-ok 9 "bad alist - not list"
       '(wrong-type-arg ("guileassoc2pythondict"
			 "Wrong type argument in position ~A: ~S"
			 (1 "b")
			 #f))
       (catch #t
	      (lambda () (python-apply '("t.scripts.t4apply" return_args)
				       '("a")
				       '("b")))
	      (lambda (key . args) (list key args))))

(is-ok 10 "bad alist - item not pair"
       '(wrong-type-arg ("guileassoc2pythondict"
			 "Wrong type argument in position ~A: ~S"
			 (2 "c")
			 #f))
       (catch #t
	      (lambda () (python-apply '("t.scripts.t4apply" return_args)
				       '("a")
				       '((#:b . 3) "c" (#:d . 5))))
	      (lambda (key . args) (list key args))))

(is-ok 11 "bad alist - key not string"
       '(wrong-type-arg ("guileassoc2pythondict"
			 "Wrong type argument in position ~A: ~S"
			 (2 4)
			 #f))
       (catch #t
	      (lambda () (python-apply '("t.scripts.t4apply" return_args)
				       '("a")
				       '((#:b . 3) (4 . "c") ("d" . 5))))
	      (lambda (key . args) (list key args))))


(is-ok 12 "bad alist - duplicate key"
       '(misc-error ("guileassoc2pythondict"
		     "duplicate key (~S)"
		     (#:b)
		     #f))
       (catch #t
	      (lambda () (python-apply '("t.scripts.t4apply" return_args)
				       '("a")
				       '((#:b . 3) (#:c . 4) (#:b . 5))))
	      (lambda (key . args) (list key args))))

(like 13 "bad alist - inconvertible data"
      "^\\(wrong-type-arg \\(\"guile2python\" \"Wrong type argument in position ~A: ~S\" \\(1 #<input: [^>]*>\\) #f\\)\\)$"
      (catch #t
	     (lambda () (python-apply '("t.scripts.t4apply" return_args)
				      '("a")
				      `((#:b . 3)
					(#:c . 4)
					(#:d . ,(current-input-port)))))
	     (lambda (key . args) (object->string (list key args)))))

; End of 06_guile2python.t
