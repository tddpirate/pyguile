#!/usr/bin/guile -s
!#
; Tests of PyGuile verbosity messages - for full source code coverage
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
;(use-modules (srfi srfi-6))  ; string ports
(use-modules (srfi srfi-13))  ; string-concatenate
(use-modules (ice-9 regex))   ; regexp-substitute

;(define get-output
;  (lambda (thunk)
;    (let ((my-output-port open-output-string))
;      (call-with-output-string (thunk))
;      (get-output-string my-output-port))))

(define thunk-invoke-python-repr
  (lambda (arg . template)
    (lambda ()
      (if (null? template)
	  (python-apply '("__builtin__" "repr") arg '())
	  (python-apply '("__builtin__" "repr") arg '() (car template))))))

(plan 6)

(pyguile-verbosity-set! 1)

(define successful-verbose-builtin-repr-conversion-report
  (string-concatenate
   '("# g2p_string2String: successful conversion of \"__builtin__\" into a Python String value\n"
     "# g2p_string2String: successful conversion of \"repr\" into a Python String value\n")))

(define expres1
  (string-concatenate
   (list
    successful-verbose-builtin-repr-conversion-report
    "# g2p_bool2Bool: successful conversion of #t into a Python Bool value\n"
    "# p2g_String2string: successful conversion of \"'True'\" into SCM\n")))
(is-ok 1 "Verbosity with a single value"
       expres1
       (with-output-to-string
	 (thunk-invoke-python-repr '(#t))))

(define expres2
  (string-concatenate
   (list
    successful-verbose-builtin-repr-conversion-report
    "# g2p_null2PyNone: successful conversion of () into Python None\n"
    "# g2p_bool2Bool: successful conversion of #t into a Python Bool value\n"
    "# g2p_bool2Bool: successful conversion of #f into a Python Bool value\n"
    "# g2p_num2Int: successful conversion of 1 into a Python Int value\n"
    "# g2p_num2Int: successful conversion of -5 into a Python Int value\n"
    "# g2p_symbol2String: successful conversion of quote into a Python String value\n"
    "# g2p_symbol2String: successful conversion of symba into a Python String value\n"
    "# g2p_complex2Complex: successful conversion of 1.0-1.0i into a Python Complex value\n"
    "# g2p_real2Float: successful conversion of 3.125 into a Python Float value\n"
    "# p2g_String2string: successful conversion of \"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\" into SCM\n")))
(is-ok 2 "Verbosity when successful"
       expres2
       (with-output-to-string
	 (thunk-invoke-python-repr '((() #t #f 1 -5 #\P 'symba 1-1i 3.125)))))

(define expres3
  (string-concatenate
   (list
    successful-verbose-builtin-repr-conversion-report
    "# g2p_null2Tuple0: successful conversion of () into Python ()\n"
    "# g2p_null2List0: successful conversion of () into Python []\n"
    "# g2p_null2DictEmpty: successful conversion of () into Python {}\n"
    "# p2g_String2string: successful conversion of \"'((), [], {})'\" into SCM\n")))
(is-ok 3 "g2p* verbosity coverage"
       expres3
       (with-output-to-string
	 (thunk-invoke-python-repr
	  '((() () ()))
	  (list g2p_list2Tuple (list g2p_list2Tuple g2p_null2Tuple0 g2p_null2List0 g2p_null2DictEmpty)))))

(define expres4
  (string-concatenate
   (list
    successful-verbose-builtin-repr-conversion-report
    "# g2p_num2Int: successful conversion of 1000000 into a Python Int value\n"
    "# g2p_bignum2Long: successful conversion of 1000000000000 into a Python Long value\n"
    "# p2g_String2string: successful conversion of \"'[1000000, 1000000000000L]'\" into SCM\n")))
(is-ok 4 "g2p* verbosity coverage - bignums,list2Tuple,list2List"
       expres4
       (with-output-to-string
	 (thunk-invoke-python-repr
	  '((1000000 1000000000000))
	  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_bignum2Long g2p_num2Int))))))

(define expres5
  (string-concatenate
   (list
    successful-verbose-builtin-repr-conversion-report
    "# g2p_symbol2String: successful conversion of p1at into a Python String value\n"
    "# g2p_string2String: successful conversion of \"p1bt\" into a Python String value\n"
    "# g2p_keyword2String: successful conversion of #:p2al into a Python String value\n"
    "# g2p_symbol2String: successful conversion of p2bl into a Python String value\n"
    "# p2g_String2string: successful conversion of \"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\" into SCM\n")))
(is-ok 5 "g2p* verbosity coverage - pair2Tuple,pair2List"
       expres5
       (with-output-to-string
	 (thunk-invoke-python-repr
	  '(((p1at . "p1bt")  (#:p2al . p2bl)))
	  (list g2p_list2Tuple (list g2p_list2Tuple (cons g2p_pair2Tuple (cons guile2python guile2python)) (cons g2p_pair2List (cons guile2python guile2python)))))))

(define substitute-hex-addresses-for-gggggggg
  (lambda (strarg)
    (regexp-substitute/global #f
			      "0x[0-9a-f]{8}"
			      strarg
			      'pre "0xgggggggg" 'post)))

(define expres6
  (string-concatenate
   (list
    successful-verbose-builtin-repr-conversion-report
    "# g2p_opaque2Object: the Python object inside opaque pysmob (python-eval <function func at 0xgggggggg> #t) is unwrapped\n"
    "# g2p_num2Int: successful conversion of 1 into a Python Int value\n"
    "# g2p_string2String: successful conversion of \"one\" into a Python String value\n"
    "# g2p_num2Int: successful conversion of 2 into a Python Int value\n"
    "# g2p_string2String: successful conversion of \"two\" into a Python String value\n"
    "# g2p_num2Int: successful conversion of 3 into a Python Int value\n"
    "# g2p_string2String: successful conversion of \"three\" into a Python String value\n"
    "# p2g_String2string: successful conversion of \"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\" into SCM\n")))
(python-eval "def func(a):\n  print a\n" #f)
(define opaqueobj (python-eval "func" #t))
(define run-test-opaque
  (lambda ()
    (with-output-to-string
      (thunk-invoke-python-repr
       (list (list opaqueobj '((1 . "one")(2 . "two")(3 . "three"))))
       (list g2p_list2Tuple (list g2p_list2List g2p_opaque2Object (cons g2p_alist2Dict (list (cons g2p_num2Int g2p_string2String)))))))))
(is-ok 6 "g2p* verbosity coverage - opaque2Object,g2p_alist2Dict"
       expres6
       (substitute-hex-addresses-for-gggggggg
	(run-test-opaque)))

; End of 17_verbose.t
