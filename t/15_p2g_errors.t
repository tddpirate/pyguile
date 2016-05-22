#!/usr/bin/guile -s
!#
; p2g conversion error handling tests.
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

(plan 20)

; Run python-eval under catch harness.
(define catch-test-eval
  (lambda (txt template)
    (catch #t
	   (lambda () (python-eval txt template))
	   (lambda (key . args) (object->string (list key args))))))

(is-ok 1 "template with bad CAR"
       "(misc-error (\"p2g_apply\" \"bad template CAR item ~S\" (42) #f))"
       (catch-test-eval "-42" (cons 42 "None")))

(is-ok 2 "p2g_leaf template with bad CDR"
       "(wrong-type-arg (\"p2g_leaf\" \"Wrong type argument in position ~A: ~S\" (2 \"foofoo\") #f))"
       (catch-test-eval "-42" (cons p2g_leaf "foofoo")))

(is-ok 3 "no p2g_leaf template matches the data"
       "#<undefined>"
       (object->string (catch-test-eval "'a-42'" (list p2g_leaf p2g_Int2num p2g_Long2bignum))))

(is-ok 4 "too short string for keyword"
       "#<undefined>"
       (object->string (catch-test-eval "''" p2g_String2keyword)))

(is-ok 5 "too long string for char"
       "#<undefined>"
       (object->string (catch-test-eval "'lg'" p2g_1String2char)))

(is-ok 6 "too short string for char"
       "#<undefined>"
       (object->string (catch-test-eval "''''''" p2g_1String2char)))

(is-ok 7 "2-tuple to pair, bad template"
       "(misc-error (\"p2g_2Tuple2pair\" \"bad template item ~S\" (12.3) #f))"
       (catch-test-eval "(12.0,34)" (cons p2g_2Tuple2pair 12.3)))

(is-ok 8 "2-tuple to pair, wrong tuple length - too long" "#<undefined>"
       (object->string (python-eval "(1,2,3)" (cons p2g_2Tuple2pair (cons p2g_Int2num p2g_Int2num)))))

(is-ok 9 "2-tuple to pair, wrong tuple length - too short" "#<undefined>"
       (object->string (python-eval "(1,)" (cons p2g_2Tuple2pair (cons p2g_Int2num p2g_Int2num)))))

(is-ok 10 "2-tuple to pair, wrong 2nd item datatype" "#<undefined>"
       (object->string (python-eval "(1,'zuzu')" (cons p2g_2Tuple2pair (cons p2g_Int2num p2g_Int2num)))))

(is-ok 11 "2-list to pair, bad template"
       "(misc-error (\"p2g_2List2pair\" \"bad template item ~S\" (12.3) #f))"
       (catch-test-eval "[12.0,34]" (cons p2g_2List2pair 12.3)))

(is-ok 12 "2-list to pair, wrong tuple length - too long" "#<undefined>"
       (object->string (python-eval "[1,2,3]" (cons p2g_2List2pair (cons p2g_Int2num p2g_Int2num)))))

(is-ok 13 "2-list to pair, wrong tuple length - too short" "#<undefined>"
       (object->string (python-eval "[1]" (cons p2g_2List2pair (cons p2g_Int2num p2g_Int2num)))))

(is-ok 14 "2-list to pair, wrong 1st item datatype" "#<undefined>"
       (object->string (python-eval "['xyxy',11]" (cons p2g_2List2pair (cons p2g_Int2num p2g_Int2num)))))

(is-ok 15 "2-list to pair, wrong 2nd item datatype" "#<undefined>"
       (object->string (python-eval "[1,'zuzu']" (cons p2g_2List2pair (cons p2g_Int2num p2g_Int2num)))))


; template not a proper list

(is-ok 16 "Tuple to list, template improper list"
       "(wrong-type-arg (\"p2g_Tuple2list\" \"Wrong type argument in position ~A: ~S\" (2 ('p2g_Int2num 'p2g_Float2real . 'p2g_Float2real)) #f))"
       (catch-test-eval
	"(11,12.0,13,34.5,38,780.25)"
	(cons p2g_Tuple2list (cons p2g_Int2num (cons p2g_Float2real p2g_Float2real)))))

(is-ok 17 "List to list, template improper list"
       "(wrong-type-arg (\"p2g_List2list\" \"Wrong type argument in position ~A: ~S\" (2 ('p2g_Int2num 'p2g_Float2real . 'p2g_Float2real)) #f))"
       (catch-test-eval
	"[11,12.0,13,34.5,38,780.25]"
	(cons p2g_List2list (cons p2g_Int2num (cons p2g_Float2real p2g_Float2real)))))

; p2g_Dict2alist - bad templates

(is-ok 18 "Dict to alist, template is not pair"
       "(misc-error (\"p2g_Dict2alist\" \"bad template ~S\" ('p2g_Int2num) #f))"
       (catch-test-eval
	"{1 : 2, 3 : 4}"
	(cons p2g_Dict2alist p2g_Int2num)))

(is-ok 19 "Dict to alist, bad template CAR"
       "(misc-error (\"p2g_apply\" \"bad template item ~S\" (12) #f))"
       (catch-test-eval
	"{1 : 2, 3 : 4}"
	(cons p2g_Dict2alist (cons 12 p2g_Int2num))))

(is-ok 20 "Dict to alist, bad template CDR"
       "(misc-error (\"p2g_apply\" \"bad template item ~S\" (\"cde\") #f))"
       (catch-test-eval
	"{1 : 2, 3 : 4}"
	(cons p2g_Dict2alist (cons p2g_Int2num "cde"))))

; End of 15_p2g_errors.t
