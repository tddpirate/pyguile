#!/usr/bin/guile -s
!#
; Basic p2g template tests
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

(plan 57)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; p2g_None2SCM_EOL

(is-ok 1 "default None" '()
	    (python-eval "None" #t))

(is-ok 2 "default None 2" '()
	    (python-eval "None" python2guile))

(is-ok 3 "default None 3" '()
	    (python-eval "None" p2g_None2SCM_EOL))

(is-ok 4 "default None 4" '()
	    (python-eval "None" (cons p2g_None2SCM_EOL '())))

(is-ok 5 "None becomes 'None'" "None"
	    (python-eval "None" (cons p2g_None2SCM_EOL "None")))

(is-ok 6 "non-None" "#<undefined>"
	    (object->string (python-eval "True" p2g_None2SCM_EOL)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; p2g_Bool2SCM_BOOL

(is-ok 7 "p2g_Bool2SCM_BOOL True" #t
       (python-eval "True" p2g_Bool2SCM_BOOL))

(is-ok 8 "p2g_Bool2SCM_BOOL False" #f
       (python-eval "False" p2g_Bool2SCM_BOOL))

(is-ok 9 "p2g_Bool2SCM_BOOL Other" "#<undefined>"
       (object->string (python-eval "2239" p2g_Bool2SCM_BOOL)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; p2g_Int2num, p2g_Long2bignum

(is-ok 10 "p2g_Int2num ok" 12
       (python-eval "12" p2g_Int2num))

(is-ok 11 "p2g_Int2num bad" "#<undefined>"
       (object->string (python-eval "None" p2g_Int2num)))

(is-ok 12 "p2g_Int2num long" "#<undefined>"
       (object->string (python-eval "1000200030004" p2g_Int2num)))

(is-ok 13 "p2g_Long2bignum ok" 12
       (python-eval "12L" p2g_Long2bignum))

(is-ok 14 "p2g_Long2bignum bad" "#<undefined>"
       (object->string (python-eval "'q'" p2g_Long2bignum)))

(is-ok 15 "p2g_Long2bignum long" "1000200030004"
       (object->string (python-eval "1000200030004" p2g_Long2bignum)))

; p2g_leaf

(is-ok 16 "p2g_Int2num+p2g_Long2bignum" "5000600070008"
       (object->string (python-eval "5000600070008" (list p2g_leaf p2g_Int2num p2g_Long2bignum))))

(is-ok 17 "p2g_Int2num+p2g_Long2bignum/cons" "5100600070008"
       (object->string (python-eval "5100600070008" (cons p2g_leaf p2g_Long2bignum))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; float and complex

(is-ok 18 "p2g_Float2real" 2.718
       (python-eval "2.7+0.018" p2g_Float2real))

(is-ok 19 "p2g_Complex2complex" 1.5+3.6i
       (python-eval "1.5+3.6j" p2g_Complex2complex))

; Tuple2list of numbers

(is-ok 20 "Numbers in tuple" '(1023 -445 4.75 -8.1e5 2e7+3.125i)
       (python-eval "(1023,-445,4.75,-8.1e5,(2e7+3.125j))"
		    (list p2g_apply p2g_Tuple2list (list p2g_leaf p2g_Int2num p2g_Long2bignum p2g_Float2real p2g_Complex2complex))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Strings

(is-ok 21 "String" "a message"
       (python-eval "'''a message'''" p2g_String2string))

(is-ok 22 "Sumbol" 'a-message
       (python-eval "'''a-message'''" p2g_String2symbol))

(is-ok 23 "Keyword" #:another-message
       (python-eval "'''another-message'''" p2g_String2keyword))

; string to char

(is-ok 24 "single char" #\space
       (python-eval "' '" p2g_1String2char))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 2-tuple/2-list to pairs

(is-ok 25 "2-tuple to pair" '(12.0 . 34)
       (python-eval "(12.0,34)" (cons p2g_2Tuple2pair (cons p2g_Float2real p2g_Int2num))))

(is-ok 26 "2-tuple to pair, wrong template" "#<undefined>"
       (object->string (python-eval "(12.0,34)" (cons p2g_2Tuple2pair (cons p2g_Int2num p2g_Float2real)))))

(is-ok 27 "2-tuple to pair, wrong template due another reason" "#<undefined>"
       (object->string (python-eval "[12.0,34]" (cons p2g_2Tuple2pair (cons p2g_Int2num p2g_Float2real)))))

(is-ok 28 "2-list to pair" '("ab" . "cd")
       (python-eval "['ab','cd']" (cons p2g_2List2pair (cons p2g_String2string p2g_String2string))))

(is-ok 29 "2-tuple (or 2-list) to pair" '("ef" . 3)
       (python-eval "('ef',3)"
		    (cons p2g_leaf
			  (list
			   (cons p2g_2Tuple2pair (cons p2g_String2string p2g_Int2num))
			   (cons p2g_2List2pair (cons p2g_String2string p2g_Int2num))))))


(is-ok 30 "(2-tuple or) 2-list to pair" '("ef" . 3)
       (python-eval "['ef',3]"
		    (cons p2g_leaf
			  (list
			   (cons p2g_2Tuple2pair (cons p2g_String2string p2g_Int2num))
			   (cons p2g_2List2pair (cons p2g_String2string p2g_Int2num))))))

(is-ok 31 "2-list to pair, wrong template" "#<undefined>"
       (object->string (python-eval "[12.0,34]" (cons p2g_2List2pair (cons p2g_Int2num p2g_Float2real)))))

(is-ok 32 "2-list to pair, wrong template due another reason" "#<undefined>"
       (object->string (python-eval "(12.0,34)" (cons p2g_2List2pair (cons p2g_Int2num p2g_Float2real)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Aggregates - N-Tuples/N-Lists to lists

; from Tuples
(is-ok 33 "tuple to list, mixed datatypes" "(11 12.0 13 34.5 38 780.25)"
       (object->string (python-eval "(11,12.0,13,34.5,38,780.25)" (cons p2g_Tuple2list (list p2g_Int2num p2g_Float2real)))))

(is-ok 34 "tuple to list, wrong data type" "#<undefined>"
       (object->string (python-eval "[11,12.0,13,34.5,38,780.25]" (cons p2g_Tuple2list (list p2g_Int2num p2g_Float2real)))))

(is-ok 35 "tuple to list, P2G_SMOB" "(11 12 13 34 38 780)"
       (object->string (python-eval "(11,12,13,34,38,780)" (cons p2g_Tuple2list p2g_Int2num))))

(is-ok 36 "tuple to list, P2G_SMOB, one bad value" "#<undefined>"
       (object->string (python-eval "(11,12,'a13',34,38,780)" (cons p2g_Tuple2list p2g_Int2num))))

; from Lists
(is-ok 37 "List to list, mixed datatypes" "(11 12.0 13 34.5 38 780.25)"
       (object->string (python-eval "[11,12.0,13,34.5,38,780.25]" (cons p2g_List2list (list p2g_Int2num p2g_Float2real)))))

(is-ok 38 "List to list, wrong data type" "#<undefined>"
       (object->string (python-eval "(11,12.0,13,34.5,38,780.25)" (cons p2g_List2list (list p2g_Int2num p2g_Float2real)))))

(is-ok 39 "List to list, P2G_SMOB" "(11 12 13 34 38 780)"
       (object->string (python-eval "[11,12,13,34,38,780]" (cons p2g_List2list p2g_Int2num))))

(is-ok 40 "List to list, P2G_SMOB, one bad value" "#<undefined>"
       (object->string (python-eval "[11,12,'a13',34,38,780]" (cons p2g_List2list p2g_Int2num))))

; p2g_Dict2alist

(define alist-properly-included?
  (lambda (included includor)
    (if (null? included) #t
	(let ((key (caar included))
	      (value (cdar included))
	      (rest (cdr included)))
	  (let ((includor-ref (assoc key includor)))
	    (cond ((not includor-ref) #f)
		  ((not (equal? (cdr includor-ref) value)) #f)
		  (else (alist-properly-included? rest includor))))))))

(define alist-equal?
  (lambda (alista alistb)
    (and (alist-properly-included? alista alistb)
	 (alist-properly-included? alistb alista))))

; Quick tests of alist-properly-included?
(ok 41 "should pass 1"
    (alist-equal? '((1 . 2)("3" . "4"))
		  '(("3" . "4")(1 . 2))))

(ok 42 "should pass 2"
    (alist-equal? '((1 . 2)("3" . "4"))
		  '((1 . 2)("3" . "4"))))

(ok 43 "should fail 1"
    (not (alist-equal? '((1 . 2)("3" . "4"))
		       '((11 . 2)("3" . "4")))))

(ok 44 "should fail 2"
    (not (alist-equal? '((1 . 2)("3" . "4"))
		  '((1 . 21)("3" . "4")))))

(ok 45 "should fail 3"
    (not (alist-equal? '((1 . 2)("3" . "4"))
		       '((1 . 2)("3a" . "4")))))

(ok 46 "should fail 4"
    (not (alist-equal? '((1 . 2)("3" . "4"))
		       '((1 . 2)("3" . "4b")))))

(ok 47 "should fail 1a"
    (not (alist-equal? '(("3" . "4")(1 . 2))
		       '((11 . 2)("3" . "4")))))

(ok 48 "should fail 2a"
    (not (alist-equal? '(("3" . "4")(1 . 2))
		       '((1 . 21)("3" . "4")))))

(ok 49 "should fail 3a"
    (not (alist-equal? '(("3" . "4")(1 . 2))
		       '((1 . 2)("3a" . "4")))))

(ok 50 "should fail 4a"
    (not (alist-equal? '(("3" . "4")(1 . 2))
		       '((1 . 2)("3" . "4b")))))

(ok 51 "should fail 5"
    (not (alist-equal? '(("3" . "4")(1 . 2)(5 . 6))
		       '((1 . 2)("3" . "4")))))

(ok 52 "should fail 5a"
    (not (alist-equal? '(("3" . "4")(1 . 2)(5 . 6))
		       '((1 . 2)("3" . "4")(7 . 8)(5 . 6)))))


; Proper p2g_Dict2alist tests


(ok 53 "Default p2g_Dict2alist"
    (alist-equal? '((1 . 2) ("3" . "4"))
		  (python-eval "{1 : 2, '3' : '4'}" #t)))

(ok 54 "Explicit p2g_Dict2alist template"
    (alist-equal? '((#\b . 42) (gg . 3))
		  (python-eval "{'b' : None, 'gg' : 3}"
			       (cons p2g_Dict2alist
				     (cons
				      (cons p2g_leaf (list p2g_1String2char p2g_String2symbol))
				      (cons p2g_leaf (list (cons p2g_None2SCM_EOL 42) p2g_Int2num)))))))

(ok 55 "P2G_SMOBP based p2g_Dict2alist template"
    (alist-equal? '(("key1" . val1) ("key2" . myval2) ("k3" . yourval3))
		  (python-eval "{'key1' : 'val1', 'key2' : 'myval2', 'k3' : 'yourval3'}"
			       (cons p2g_Dict2alist
				     (cons p2g_String2string p2g_String2symbol)))))

(is-ok 56 "p2g_Dict2alist key conversion failure" "#<undefined>"
       (object->string (python-eval "{'b' : None, 1.2 : 3}"
				    (cons p2g_Dict2alist
					  (cons
					   (cons p2g_leaf (list p2g_1String2char p2g_String2symbol))
					   (cons p2g_leaf (list (cons p2g_None2SCM_EOL 42) p2g_Int2num)))))))

(is-ok 57 "p2g_Dict2alist value conversion failure" "#<undefined>"
       (object->string (python-eval "{'b' : 'None', 'gg' : 3}"
				    (cons p2g_Dict2alist
					  (cons
					   (cons p2g_leaf (list p2g_1String2char p2g_String2symbol))
					   (cons p2g_leaf (list (cons p2g_None2SCM_EOL 42) p2g_Int2num)))))))

; End of 14_p2g_templated.t
