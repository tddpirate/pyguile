#!/usr/bin/guile -s
!#
; Basic g2p template tests
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

(plan 36)

(is-ok 1 "real" "1.0"
	    (python-apply '("__builtin__" "repr") '(1.0) '() (list g2p_list2Tuple g2p_real2Float)))

(is-ok 2 "int" "3"
	    (python-apply '("__builtin__" "repr") '(3) '() (list g2p_list2Tuple g2p_num2Int)))

(is-ok 3 "mixed int-real" "[4, 5.0, 6, 7.0, 8]"
	    (python-apply '("__builtin__" "repr") '((4 5 6 7 8)) '()
			  (list g2p_list2Tuple (list g2p_list2List g2p_num2Int g2p_real2Float))))

(is-ok 4 "mixed int-real(tuple)" "(4, 5.0, 6, 7.0, 8)"
	    (python-apply '("__builtin__" "repr") '((4 5 6 7 8)) '()
			  (list g2p_list2Tuple (list g2p_list2Tuple g2p_num2Int g2p_real2Float))))

(is-ok 5 "list2Tuple" "(4.0, 5.0, 6.0, 7.0, 8.0)"
	    (python-apply '("__builtin__" "repr") '((4 5 6 7 8)) '()
			  (list g2p_list2Tuple (cons g2p_list2Tuple g2p_real2Float))))

(is-ok 6 "bool vs. int -> List" "[True, 5, 6, 7, False]"
	    (python-apply '("__builtin__" "repr") '((#t 5 6 7 #f)) '()
			  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_num2Int g2p_bool2Bool)))))

(is-ok 7 "pair2tuple" "('a', 5)"
	    (python-apply '("__builtin__" "repr") '(("a" . 5)) '()
			  (list g2p_list2Tuple (cons g2p_pair2Tuple (cons g2p_string2String g2p_num2Int)))))

(is-ok 8 "pair2list" "['c', 55]"
	    (python-apply '("__builtin__" "repr") '(("c" . 55)) '()
			  (list g2p_list2Tuple (cons g2p_pair2List (cons g2p_string2String g2p_num2Int)))))

; Run python-apply under catch harness.
(define catch-test-apply
  (lambda (func args kws . targ)
    (catch #t
	   (lambda () (python-apply func args kws (car targ)))
	   (lambda (key . args2) (object->string (list key args2))))))

(is-ok 9 "bad template in g2p_apply"
	    "(misc-error (\"g2p_apply\" \"bad template item ~S\" (\"pooh\") #f))"
	    (catch-test-apply '("__builtin__" "repr") '() '() "pooh"))

(is-ok 10 "bad template 2 in g2p_apply"
	    "(misc-error (\"g2p_apply\" \"bad template CAR item ~S\" (\"pooh\") #f))"
	    (catch-test-apply '("__builtin__" "repr") '() '() '("pooh" . "bar")))

(is-ok 11 "g2p_leaf in pair" "'pair'"
	    (python-apply '("__builtin__" "repr") '("pair") '() (list g2p_list2Tuple (cons g2p_leaf g2p_string2String))))

(is-ok 12 "g2p_leaf missing conversion datatype"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((#t 5 \"rude\" 7 #f))) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((#t 5 "rude" 7 #f)) '()
			      (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_num2Int g2p_bool2Bool)))))

; Exercise various g2p_* functions not otherwise covered.

(is-ok 13 "null" "None"
	    (python-apply '("__builtin__" "repr") '(()) '()
			  (list g2p_list2Tuple (list g2p_null2PyNone))))

(is-ok 14 "Other nulls" "[(), [], {}]"
	    (python-apply '("__builtin__" "repr") '((() () ())) '()
			  (list g2p_list2Tuple (list g2p_list2List g2p_null2Tuple0 g2p_null2List0 g2p_null2DictEmpty))))

(is-ok 15 "g2p_copmlex"
	    "[1, 2, 3.5, (4+6j)]"
	    (python-apply '("__builtin__" "repr") '((1 2 3.5 4+6i)) '()
			  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_num2Int g2p_real2Float g2p_complex2Complex)))))

(is-ok 16 "bignums"
	    "[1000000, 100000000, 10000000000L, 1000000000000L]"
	    (python-apply '("__builtin__" "repr") '((1000000 100000000 10000000000 1000000000000)) '()
			  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_bignum2Long g2p_num2Int)))))

; Exercise g2p_pair2Tuple with bad templates and data

(is-ok 17 "bad template for g2p_pair2Tuple"
	    "(misc-error (\"g2p_pair2Tuple\" \"bad template ~S\" (\"pooh\") #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2Tuple "pooh"))))

(is-ok 18 "validate datatype tests for g2p_pair2Tuple"
	    "(1, 2)"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2Tuple (cons g2p_num2Int g2p_num2Int)))))

(is-ok 19 "bad CAR datatype for g2p_pair2Tuple"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((1 . 2))) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2Tuple (cons g2p_bool2Bool g2p_num2Int)))))

(is-ok 20 "bad CDR datatype for g2p_pair2Tuple"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((1 . 2))) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2Tuple (cons g2p_num2Int g2p_bool2Bool)))))

; Exercise g2p_pair2List with bad templates and data

(is-ok 21 "bad template for g2p_pair2List"
	    "(misc-error (\"g2p_pair2List\" \"bad template ~S\" (\"pooh\") #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2List "pooh"))))

(is-ok 22 "validate datatype tests for g2p_pair2List"
	    "[1, 2]"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2List (cons g2p_num2Int g2p_num2Int)))))

(is-ok 23 "bad CAR datatype for g2p_pair2List"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((1 . 2))) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2List (cons g2p_bool2Bool g2p_num2Int)))))

(is-ok 24 "bad CDR datatype for g2p_pair2List"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((1 . 2))) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 . 2)) '()
			      (list g2p_list2Tuple (cons g2p_pair2List (cons g2p_num2Int g2p_bool2Bool)))))

; Exercise g2p_list2Tuple and g2p_list2List with bad arguments

(is-ok 25 "bad argument to g2p_list2Tuple"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((\"not a list\")) #f))"
	    (catch-test-apply '("__builtin__" "repr") '("not a list") '()
			      (list g2p_list2Tuple (list g2p_list2Tuple g2p_string2String))))

(is-ok 26 "bad argument to g2p_list2List"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((\"not a list\")) #f))"
	    (catch-test-apply '("__builtin__" "repr") '("not a list") '()
			      (list g2p_list2Tuple (list g2p_list2List g2p_string2String))))


(is-ok 27 "no bad argument datatype to g2p_list2Tuple (test validation)"
	    "(1, 2, 3, 4, 5)"
	    (catch-test-apply '("__builtin__" "repr") '((1 2 3 4 5)) '()
			      (list g2p_list2Tuple (list g2p_list2Tuple g2p_num2Int))))

(is-ok 28 "bad argument datatype to g2p_list2Tuple"
       "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((1 2 3 #f 4 5))) #f))"
       (catch-test-apply '("__builtin__" "repr") '((1 2 3 #f 4 5)) '()
			 (list g2p_list2Tuple (list g2p_list2Tuple g2p_num2Int))))


(is-ok 29 "bad argument datatype to g2p_list2List"
	    "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((6 7 #t 8 9 10))) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((6 7 #t 8 9 10)) '()
			      (list g2p_list2Tuple (list g2p_list2List g2p_num2Int))))

(is-ok 30 "bad template (not list) to g2p_list2Tuple"
	    "(wrong-type-arg (\"g2p_list2Tuple\" \"Wrong type argument in position ~A: ~S\" (2 #<unspecified>) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((1 2 3 #f 4 5)) '()
			      (list g2p_list2Tuple g2p_list2Tuple "fadiha")))


(is-ok 31 "bad template (not list) to g2p_list2List"
	    "(wrong-type-arg (\"g2p_list2List\" \"Wrong type argument in position ~A: ~S\" (2 #<unspecified>) #f))"
	    (catch-test-apply '("__builtin__" "repr") '((6 7 #t 8 9 10)) '()
			      (list g2p_list2Tuple g2p_list2List "fadiha")))

; g2p_char2String

(is-ok 32 "g2p_char2String"
       "['a', 5, 6, 7, ' ', 'Q']"
       (python-apply '("__builtin__" "repr") '((#\a 5 6 7 #\space #\Q)) '()
		     (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_char2String g2p_num2Int g2p_bool2Bool)))))

; g2p_symbol2String

(is-ok 33 "g2p_symbol2String"
       "['one', 'two', 'three', 'four', 'five', 'six']"
       (python-apply '("__builtin__" "repr") '(("one" two #:three "four" five #:six)) '()
		     (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_string2String g2p_symbol2String g2p_keyword2String)))))

(python-eval "class opaq(object):\n  def __init__(self,v):\n    self.v=v\n  def __repr__(self):    return('*** opaque %s ***' % str(self.v))\n" #f)
(define opaq1 (python-eval "opaq('o p a q 1')" #t))
(define opaq2 (python-eval "opaq(['o p a q',2])" #t))

(is-ok 34 "opaque data"
       "[*** opaque o p a q 1 ***, 3, *** opaque ['o p a q', 2] ***]"
       (python-apply '("__builtin__" "repr") (list (list opaq1 3 opaq2)) '()
		     (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_opaque2Object g2p_num2Int)))))

; Additional tests: g2p_list2Tuple and g2p_list2List getting data with
; item inappropriate to the single G2P_SMOB template argument.

(is-ok 35 "list2Tuple"
       "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((4 \"Gorilla!\" 6 7 8))) #f))"
       (catch-test-apply '("__builtin__" "repr") '((4 "Gorilla!" 6 7 8)) '()
			 (list g2p_list2Tuple (cons g2p_list2Tuple g2p_real2Float))))

(is-ok 36 "list2Tuple"
       "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" (((4 \"Chimpanzee!\" 6 7 8))) #f))"
       (catch-test-apply '("__builtin__" "repr") '((4 "Chimpanzee!" 6 7 8)) '()
			 (list g2p_list2Tuple (cons g2p_list2List g2p_real2Float))))


; End of 12_g2p_templated.t
