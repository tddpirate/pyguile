#!/usr/bin/guile -s
!#
; Pyguile hash tests - keyword arguments to functions and general Dicts.
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

(python-eval "import sys;sys.path = ['']+sys.path\n")
(python-eval "from t.scripts.t4apply import return_args\n")

(define check-kw-conversion
  (lambda (keywords kwtemplate)
    (python-apply '("__main__" "return_args") '() keywords
		  (list g2p_list2Tuple guile2python)
		  kwtemplate)))

(define catch-test-kw-conversion
  (lambda (keywords kwtemplate)
    (catch #t
	   (lambda () (check-kw-conversion keywords kwtemplate))
	   (lambda (key . args2) (object->string (list key args2))))))

(plan 20)

(is-ok 1 "validate test"
	    "positional: ()      keywords: {'a': 'argument A'}"
	    (catch-test-kw-conversion '((#:a . "argument A"))
				      (make-hash-table 2)))

(is-ok 2 "no kw template"
	    "positional: ()      keywords: {'bob': 'buba'}"
	    (python-apply '("__main__" "return_args")
			  '()
			  '((#:bob . "buba"))))

(is-ok 3 "no kw template 2"
	    "positional: ()      keywords: {'n': None}"
	    (python-apply '("__main__" "return_args")
			  '()
			  '((#:n . ()))
			  (list g2p_list2Tuple guile2python)))

(is-ok 4 "not a list of pairs"
	    "(wrong-type-arg (\"guileassoc2pythondict\" \"Wrong type argument in position ~A: ~S\" (1 not-a-list) #f))"
	    (catch-test-kw-conversion 'not-a-list
				      (make-hash-table 2)))

(is-ok 5 "not a list of pairs 2"
	    "(wrong-type-arg (\"guileassoc2pythondict\" \"Wrong type argument in position ~A: ~S\" (1 not-list-either) #f))"
	    (catch-test-kw-conversion '(not-list-either)
				      (make-hash-table 2)))

(is-ok 6 "bad key"
	    "(wrong-type-arg (\"guileassoc2pythondict\" \"Wrong type argument in position ~A: ~S\" (1 bad-key) #f))"
	    (catch-test-kw-conversion '((bad-key . 'val))
				      (make-hash-table 2)))

; Our own hash table for keywords

(define kwhash (make-hash-table 7))
(hashq-set! kwhash #:inpstr (list g2p_apply g2p_string2String))
(hashq-set! kwhash #:inpkw (list g2p_apply g2p_keyword2String))
(hashq-set! kwhash #:mynum (list g2p_apply g2p_num2Int))

(is-ok 7 "our own conversions"
	    "positional: ()      keywords: {'inpkw': 'must-be-kw', 'mynum': -3, 'inpstr': 'must be string', 'unverified': ['a', 'b', 'c']}"
	    (catch-test-kw-conversion '((#:unverified . (a b c)) (#:inpstr . "must be string") (#:inpkw . #:must-be-kw) (#:mynum . -3))
				      kwhash))

(is-ok 8 "bad conversion"
	    "(misc-error (\"python-apply\" \"keyword arguments conversion failure (~S)\" (((#:unverified . -3) (#:inpstr . 7) (#:inpkw . #:must-be-kw) (#:mynum . -3))) #f))"
	    (catch-test-kw-conversion '((#:unverified . -3) (#:inpstr . 7) (#:inpkw . #:must-be-kw) (#:mynum . -3))
				      kwhash))

; Passing a Dict argument to Python function

(define catch-python-apply
  (lambda (args keywords argtemplate)
    (catch #t
	   (lambda () (python-apply '("__main__" "return_args") args keywords argtemplate))
	   (lambda (key . args2) (object->string (list key args2))))))

(is-ok 9 "basic Dict"
	    "positional: ({1: 2},)      keywords: {}"
	    (catch-python-apply '(((1 . 2))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python))))))

(is-ok 10 "more complicated Dict"
	    "positional: ({1: 2, '3': 4.0},)      keywords: {}"
	    (catch-python-apply '(((1 . 2) ("3" . 4.0))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python)) (cons (list g2p_apply g2p_string2String) (list g2p_apply g2p_real2Float))))))

(is-ok 11 "bad conversion"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((((1 . 2) (\"3\" four-dot-zero)))) #f))"
	    (catch-python-apply '(((1 . 2) ("3" . (four-dot-zero)))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python)) (cons (list g2p_apply g2p_string2String) (list g2p_apply g2p_real2Float))))))

(is-ok 12 "no alist template"
	    "positional: ([[1, 3, 1, 4], ['2', '6', '2', '8']],)      keywords: {}"
	    (python-apply '("__main__" "return_args")
			  '(((1 . (3 1 4)) ("2" . ("6" "2" "8"))))
			  '()))

(is-ok 13 "default template 2"
	    "positional: ({1: [3, 1, 4], '2': ['6', '2', '8']},)      keywords: {}"
	    (python-apply '("__main__" "return_args")
			  '(((1 . (3 1 4)) ("2" . ("6" "2" "8"))))
			  '()
			  (list g2p_list2Tuple (list g2p_apply g2p_alist2Dict))))

(is-ok 14 "Dict template with non-list argument"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((\"not-a-list\")) #f))"
	    (catch-python-apply '("not-a-list") '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python))))))

(is-ok 15 "basic Dict with non-list template"
	    "(wrong-type-arg (\"g2p_alist2Dict\" \"Wrong type argument in position ~A: ~S\" (2 'guile2python) #f))"
	    (catch-python-apply '(((1 . 2))) '()
				(list g2p_list2Tuple (list g2p_apply g2p_alist2Dict guile2python))))

(is-ok 16 "Dict with malformed template"
	    "(wrong-type-arg (\"g2p_alist2Dict\" \"Wrong type argument in position ~A: ~S\" (2 \"notapair\") #f))"
	    (catch-python-apply '(((1 . 2) ("3" . 4.0))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python)) "notapair"))))

(is-ok 17 "malformed alist"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((((1 . 2) conjugate (\"3\" . 4.0)))) #f))"
	    (catch-python-apply '(((1 . 2) conjugate ("3" . 4.0))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python)) (cons (list g2p_apply g2p_string2String) (list g2p_apply g2p_real2Float))))))

(is-ok 18 "Dict with keys matching template"
	    "positional: ({1: '2', '3': 4.0},)      keywords: {}"
	    (catch-python-apply '(((1 . "2") ("3" . 4.0))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply g2p_num2Int) (list g2p_apply g2p_string2String)) (cons (list g2p_apply g2p_string2String) (list g2p_apply g2p_real2Float))))))

(is-ok 19 "Dict with keys not matching template"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((((1.5 . 2) (\"3\" . 4.0)))) #f))"
	    (catch-python-apply '(((1.5 . 2) ("3" . 4.0))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply g2p_num2Int) (list g2p_apply g2p_string2String)) (cons (list g2p_apply g2p_string2String) (list g2p_apply g2p_real2Float))))))

(is-ok 20 "alist with duplicate key"
	    "(misc-error (\"g2p_alist2Dict\" \"duplicate key (~S)\" (1) #f))"
	    (catch-python-apply '(((1 . 2) ("3" . 4.0) (1 . a55))) '()
				(list g2p_list2Tuple (list g2p_alist2Dict (cons (list g2p_apply guile2python) (list g2p_apply guile2python)) (cons (list g2p_apply guile2python) (list g2p_apply guile2python))))))

; End of 13_hashes.t
