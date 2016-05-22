#!/usr/bin/guile -s
!#
; Tests of PyGuile verbosity messages - for full source code coverage
;
; Same tests as 17_verbose.t, except that the verbosity level was set
; to 3 (PYGUILE_VERBOSE_G2P2G_SUCCESSFUL+PYGUILE_VERBOSE_G2P2G_ALWAYS).
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
(use-modules (srfi srfi-13))  ; string-concatenate
(use-modules (ice-9 regex))   ; regexp-substitute

(define thunk-invoke-python-repr
  (lambda (arg . template)
    (lambda ()
      (if (null? template)
	  (python-apply '("__builtin__" "repr") arg '())
	  (python-apply '("__builtin__" "repr") arg '() (car template))))))

(plan 13)

(pyguile-verbosity-set! 3)

(define successful-verbose-3-report
  (string-concatenate
   '("# guile2python: entry: seeking to convert sobj=(\"__builtin__\" \"repr\"); unused stemplate=#<unspecified>\n"
     "# g2p_null2PyNone: unsuccessful conversion: (\"__builtin__\" \"repr\") is not null\n"
     "# DEBUG: g2p_list2List - processing item CAR(sobj)=\"__builtin__\"  CAR(stemp)='guile2python\n"
     "# Entered g2p_apply: sobj=\"__builtin__\"  stemplate='guile2python\n"
     "# guile2python: entry: seeking to convert sobj=\"__builtin__\"; unused stemplate=#<unspecified>\n"
     "# g2p_null2PyNone: unsuccessful conversion: \"__builtin__\" is not null\n"
     "# g2p_list2List: unsuccessful conversion: \"__builtin__\" is not a list\n"
     "# g2p_pair2Tuple: unsuccessful conversion: \"__builtin__\" is not a pair\n"
     "# g2p_bool2Bool: unsuccessful conversion: \"__builtin__\" is not a bool value\n"
     "# g2p_num2Int: unsuccessful conversion: \"__builtin__\" is not a num value\n"
     "# g2p_bignum2Long: unsuccessful conversion: \"__builtin__\" is not a bignum value\n"
     "# g2p_real2Float: unsuccessful conversion: \"__builtin__\" is not a real value\n"
     "# g2p_complex2Complex: unsuccessful conversion: \"__builtin__\" is not a complex value\n"
     "# g2p_string2String: successful conversion of \"__builtin__\" into a Python String value\n"
     "# Leaving g2p_apply: with non-null result\n"
     "# DEBUG: g2p_list2List - processing item CAR(sobj)=\"repr\"  CAR(stemp)='guile2python\n"
     "# Entered g2p_apply: sobj=\"repr\"  stemplate='guile2python\n"
     "# guile2python: entry: seeking to convert sobj=\"repr\"; unused stemplate=#<unspecified>\n"
     "# g2p_null2PyNone: unsuccessful conversion: \"repr\" is not null\n"
     "# g2p_list2List: unsuccessful conversion: \"repr\" is not a list\n"
     "# g2p_pair2Tuple: unsuccessful conversion: \"repr\" is not a pair\n"
     "# g2p_bool2Bool: unsuccessful conversion: \"repr\" is not a bool value\n"
     "# g2p_num2Int: unsuccessful conversion: \"repr\" is not a num value\n"
     "# g2p_bignum2Long: unsuccessful conversion: \"repr\" is not a bignum value\n"
     "# g2p_real2Float: unsuccessful conversion: \"repr\" is not a real value\n"
     "# g2p_complex2Complex: unsuccessful conversion: \"repr\" is not a complex value\n"
     "# g2p_string2String: successful conversion of \"repr\" into a Python String value\n"
     "# Leaving g2p_apply: with non-null result\n"
     "# g2p_list2List: successful conversion of list () by template\n")))

(define expres1
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=(#t)  stemplate=('g2p_list2Tuple 'guile2python)\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=#t  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=#t  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=#t; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: #t is not null\n"
    "# g2p_list2List: unsuccessful conversion: #t is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: #t is not a pair\n"
    "# g2p_bool2Bool: successful conversion of #t into a Python Bool value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"'True'\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"'True'\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"'True'\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"'True'\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"'True'\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"'True'\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"'True'\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"'True'\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"'True'\" into SCM\n")))
(is-ok 1 "Verbosity/3 with a single value"
       expres1
       (with-output-to-string
	 (thunk-invoke-python-repr '(#t))))

(define expres2
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=((() #t #f 1 -5 #\\P (quote symba) 1.0-1.0i 3.125))  stemplate=('g2p_list2Tuple 'guile2python)\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(() #t #f 1 -5 #\\P (quote symba) 1.0-1.0i 3.125)  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=(() #t #f 1 -5 #\\P (quote symba) 1.0-1.0i 3.125)  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=(() #t #f 1 -5 #\\P (quote symba) 1.0-1.0i 3.125); unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: (() #t #f 1 -5 #\\P (quote symba) 1.0-1.0i 3.125) is not null\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=()  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=()  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=(); unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: successful conversion of () into Python None\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=#t  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=#t  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=#t; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: #t is not null\n"
    "# g2p_list2List: unsuccessful conversion: #t is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: #t is not a pair\n"
    "# g2p_bool2Bool: successful conversion of #t into a Python Bool value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=#f  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=#f  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=#f; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: #f is not null\n"
    "# g2p_list2List: unsuccessful conversion: #f is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: #f is not a pair\n"
    "# g2p_bool2Bool: successful conversion of #f into a Python Bool value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=1  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=1  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=1; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: 1 is not null\n"
    "# g2p_list2List: unsuccessful conversion: 1 is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: 1 is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: 1 is not a bool value\n"
    "# g2p_num2Int: successful conversion of 1 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=-5  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=-5  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=-5; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: -5 is not null\n"
    "# g2p_list2List: unsuccessful conversion: -5 is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: -5 is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: -5 is not a bool value\n"
    "# g2p_num2Int: successful conversion of -5 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=#\\P  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=#\\P  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=#\\P; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: #\\P is not null\n"
    "# g2p_list2List: unsuccessful conversion: #\\P is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: #\\P is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: #\\P is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: #\\P is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: #\\P is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: #\\P is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: #\\P is not a complex value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=(quote symba)  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=(quote symba)  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=(quote symba); unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: (quote symba) is not null\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=quote  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=quote  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=quote; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: quote is not null\n"
    "# g2p_list2List: unsuccessful conversion: quote is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: quote is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: quote is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: quote is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: quote is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: quote is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: quote is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: quote is not a string value\n"
    "# g2p_symbol2String: successful conversion of quote into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=symba  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=symba  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=symba; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: symba is not null\n"
    "# g2p_list2List: unsuccessful conversion: symba is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: symba is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: symba is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: symba is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: symba is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: symba is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: symba is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: symba is not a string value\n"
    "# g2p_symbol2String: successful conversion of symba into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2List: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=1.0-1.0i  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=1.0-1.0i  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=1.0-1.0i; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: 1.0-1.0i is not null\n"
    "# g2p_list2List: unsuccessful conversion: 1.0-1.0i is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: 1.0-1.0i is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: 1.0-1.0i is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: 1.0-1.0i is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: 1.0-1.0i is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: 1.0-1.0i is not a real value\n"
    "# g2p_complex2Complex: successful conversion of 1.0-1.0i into a Python Complex value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=3.125  CAR(stemp)='guile2python\n"
    "# Entered g2p_apply: sobj=3.125  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=3.125; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: 3.125 is not null\n"
    "# g2p_list2List: unsuccessful conversion: 3.125 is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: 3.125 is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: 3.125 is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: 3.125 is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: 3.125 is not a bignum value\n"
    "# g2p_real2Float: successful conversion of 3.125 into a Python Float value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2List: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"\\\"[None, True, False, 1, -5, 'P', ['quote', 'symba'], (1-1j), 3.125]\\\"\" into SCM\n")))
(is-ok 2 "Verbosity/3 when successful"
       expres2
       (with-output-to-string
	 (thunk-invoke-python-repr '((() #t #f 1 -5 #\P 'symba 1-1i 3.125)))))

(define expres3
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=((() () ()))  stemplate=('g2p_list2Tuple ('g2p_list2Tuple 'g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(() () ())  CAR(stemp)=('g2p_list2Tuple 'g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty)\n"
    "# Entered g2p_apply: sobj=(() () ())  stemplate=('g2p_list2Tuple 'g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty)\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=()  CAR(stemp)='g2p_null2Tuple0\n"
    "# Entered g2p_apply: sobj=()  stemplate='g2p_null2Tuple0\n"
    "# g2p_null2Tuple0: successful conversion of () into Python ()\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=()  CAR(stemp)='g2p_null2List0\n"
    "# Entered g2p_apply: sobj=()  stemplate='g2p_null2List0\n"
    "# g2p_null2List0: successful conversion of () into Python []\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=()  CAR(stemp)='g2p_null2DictEmpty\n"
    "# Entered g2p_apply: sobj=()  stemplate='g2p_null2DictEmpty\n"
    "# g2p_null2DictEmpty: successful conversion of () into Python {}\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"'((), [], {})'\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"'((), [], {})'\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"'((), [], {})'\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"'((), [], {})'\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"'((), [], {})'\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"'((), [], {})'\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"'((), [], {})'\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"'((), [], {})'\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"'((), [], {})'\" into SCM\n")))
(is-ok 3 "g2p* verbosity/3 coverage"
       expres3
       (with-output-to-string
	 (thunk-invoke-python-repr
	  '((() () ()))
	  (list g2p_list2Tuple (list g2p_list2Tuple g2p_null2Tuple0 g2p_null2List0 g2p_null2DictEmpty)))))

(define expres4
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=((1000000 1000000000000))  stemplate=('g2p_list2Tuple ('g2p_list2List ('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(1000000 1000000000000)  CAR(stemp)=('g2p_list2List ('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int))\n"
    "# Entered g2p_apply: sobj=(1000000 1000000000000)  stemplate=('g2p_list2List ('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int))\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=1000000  CAR(stemp)=('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int)\n"
    "# Entered g2p_apply: sobj=1000000  stemplate=('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int)\n"
    "# Entered g2p_leaf: sobj=1000000  stemplate=('g2p_bignum2Long 'g2p_num2Int)\n"
    "# g2p_leaf: trying another stemplate 'g2p_bignum2Long on sobj\n"
    "# Entered g2p_apply: sobj=1000000  stemplate='g2p_bignum2Long\n"
    "# g2p_bignum2Long: unsuccessful conversion: 1000000 is not a bignum value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_num2Int on sobj\n"
    "# Entered g2p_apply: sobj=1000000  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: successful conversion of 1000000 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_leaf: successful conversion\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=1000000000000  CAR(stemp)=('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int)\n"
    "# Entered g2p_apply: sobj=1000000000000  stemplate=('g2p_leaf 'g2p_bignum2Long 'g2p_num2Int)\n"
    "# Entered g2p_leaf: sobj=1000000000000  stemplate=('g2p_bignum2Long 'g2p_num2Int)\n"
    "# g2p_leaf: trying another stemplate 'g2p_bignum2Long on sobj\n"
    "# Entered g2p_apply: sobj=1000000000000  stemplate='g2p_bignum2Long\n"
    "# g2p_bignum2Long: successful conversion of 1000000000000 into a Python Long value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_leaf: successful conversion\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2List: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"'[1000000, 1000000000000L]'\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"'[1000000, 1000000000000L]'\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"'[1000000, 1000000000000L]'\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"'[1000000, 1000000000000L]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"'[1000000, 1000000000000L]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"'[1000000, 1000000000000L]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"'[1000000, 1000000000000L]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"'[1000000, 1000000000000L]'\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"'[1000000, 1000000000000L]'\" into SCM\n")))
(is-ok 4 "g2p* verbosity/3 coverage - bignums,list2Tuple,list2List"
       expres4
       (with-output-to-string
	 (thunk-invoke-python-repr
	  '((1000000 1000000000000))
	  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_bignum2Long g2p_num2Int))))))

(define expres5
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=(((p1at . \"p1bt\") (#:p2al . p2bl)))  stemplate=('g2p_list2Tuple ('g2p_list2Tuple ('g2p_pair2Tuple 'guile2python . 'guile2python) ('g2p_pair2List 'guile2python . 'guile2python)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=((p1at . \"p1bt\") (#:p2al . p2bl))  CAR(stemp)=('g2p_list2Tuple ('g2p_pair2Tuple 'guile2python . 'guile2python) ('g2p_pair2List 'guile2python . 'guile2python))\n"
    "# Entered g2p_apply: sobj=((p1at . \"p1bt\") (#:p2al . p2bl))  stemplate=('g2p_list2Tuple ('g2p_pair2Tuple 'guile2python . 'guile2python) ('g2p_pair2List 'guile2python . 'guile2python))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(p1at . \"p1bt\")  CAR(stemp)=('g2p_pair2Tuple 'guile2python . 'guile2python)\n"
    "# Entered g2p_apply: sobj=(p1at . \"p1bt\")  stemplate=('g2p_pair2Tuple 'guile2python . 'guile2python)\n"
    "# Entered g2p_apply: sobj=p1at  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=p1at; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: p1at is not null\n"
    "# g2p_list2List: unsuccessful conversion: p1at is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: p1at is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: p1at is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: p1at is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: p1at is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: p1at is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: p1at is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: p1at is not a string value\n"
    "# g2p_symbol2String: successful conversion of p1at into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=\"p1bt\"  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=\"p1bt\"; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: \"p1bt\" is not null\n"
    "# g2p_list2List: unsuccessful conversion: \"p1bt\" is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: \"p1bt\" is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: \"p1bt\" is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: \"p1bt\" is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: \"p1bt\" is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: \"p1bt\" is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: \"p1bt\" is not a complex value\n"
    "# g2p_string2String: successful conversion of \"p1bt\" into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_pair2Tuple: successful conversion of (p1at . \"p1bt\") into a Python 2-Tuple\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(#:p2al . p2bl)  CAR(stemp)=('g2p_pair2List 'guile2python . 'guile2python)\n"
    "# Entered g2p_apply: sobj=(#:p2al . p2bl)  stemplate=('g2p_pair2List 'guile2python . 'guile2python)\n"
    "# Entered g2p_apply: sobj=#:p2al  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=#:p2al; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: #:p2al is not null\n"
    "# g2p_list2List: unsuccessful conversion: #:p2al is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: #:p2al is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: #:p2al is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: #:p2al is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: #:p2al is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: #:p2al is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: #:p2al is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: #:p2al is not a string value\n"
    "# g2p_symbol2String: unsuccessful conversion: #:p2al is not a symbol value\n"
    "# g2p_keyword2String: successful conversion of #:p2al into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=p2bl  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=p2bl; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: p2bl is not null\n"
    "# g2p_list2List: unsuccessful conversion: p2bl is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: p2bl is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: p2bl is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: p2bl is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: p2bl is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: p2bl is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: p2bl is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: p2bl is not a string value\n"
    "# g2p_symbol2String: successful conversion of p2bl into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_pair2List: successful conversion of (#:p2al . p2bl) into a Python 2-List\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"\\\"(('p1at', 'p1bt'), ['p2al', 'p2bl'])\\\"\" into SCM\n")))
(is-ok 5 "g2p* verbosity/3 coverage - pair2Tuple,pair2List"
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
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=(((python-eval <function func at 0xgggggggg> #t) ((1 . \"one\") (2 . \"two\") (3 . \"three\"))))  stemplate=('g2p_list2Tuple ('g2p_list2List 'g2p_opaque2Object ('g2p_alist2Dict ('g2p_num2Int . 'g2p_string2String))))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=((python-eval <function func at 0xgggggggg> #t) ((1 . \"one\") (2 . \"two\") (3 . \"three\")))  CAR(stemp)=('g2p_list2List 'g2p_opaque2Object ('g2p_alist2Dict ('g2p_num2Int . 'g2p_string2String)))\n"
    "# Entered g2p_apply: sobj=((python-eval <function func at 0xgggggggg> #t) ((1 . \"one\") (2 . \"two\") (3 . \"three\")))  stemplate=('g2p_list2List 'g2p_opaque2Object ('g2p_alist2Dict ('g2p_num2Int . 'g2p_string2String)))\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=(python-eval <function func at 0xgggggggg> #t)  CAR(stemp)='g2p_opaque2Object\n"
    "# Entered g2p_apply: sobj=(python-eval <function func at 0xgggggggg> #t)  stemplate='g2p_opaque2Object\n"
    "# g2p_opaque2Object: the Python object inside opaque pysmob (python-eval <function func at 0xgggggggg> #t) is unwrapped\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=((1 . \"one\") (2 . \"two\") (3 . \"three\"))  CAR(stemp)=('g2p_alist2Dict ('g2p_num2Int . 'g2p_string2String))\n"
    "# Entered g2p_apply: sobj=((1 . \"one\") (2 . \"two\") (3 . \"three\"))  stemplate=('g2p_alist2Dict ('g2p_num2Int . 'g2p_string2String))\n"
    "# g2p_alist2Dict sobj=((1 . \"one\") (2 . \"two\") (3 . \"three\"))  stemplate=(('g2p_num2Int . 'g2p_string2String))\n"
    "# Entered g2p_apply: sobj=1  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: successful conversion of 1 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=\"one\"  stemplate='g2p_string2String\n"
    "# g2p_string2String: successful conversion of \"one\" into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=2  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: successful conversion of 2 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=\"two\"  stemplate='g2p_string2String\n"
    "# g2p_string2String: successful conversion of \"two\" into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=3  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: successful conversion of 3 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# Entered g2p_apply: sobj=\"three\"  stemplate='g2p_string2String\n"
    "# g2p_string2String: successful conversion of \"three\" into a Python String value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_alist2Dict: successful conversion\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2List: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"\\\"[<function func at 0xgggggggg>, {1: 'one', 2: 'two', 3: 'three'}]\\\"\" into SCM\n")))
(python-eval "def func(a):\n  print a\n" #f)
(define opaqueobj (python-eval "func" #t))
(define run-test-opaque
  (lambda ()
    (with-output-to-string
      (thunk-invoke-python-repr
       (list (list opaqueobj '((1 . "one")(2 . "two")(3 . "three"))))
       (list g2p_list2Tuple (list g2p_list2List g2p_opaque2Object (cons g2p_alist2Dict (list (cons g2p_num2Int g2p_string2String)))))))))
(is-ok 6 "g2p* verbosity/3 coverage - opaque2Object,g2p_alist2Dict"
       expres6
       (substitute-hex-addresses-for-gggggggg
	(run-test-opaque)))

; Additional tests

(define expres7
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=((#t 5))  stemplate=('g2p_list2Tuple ('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(#t 5)  CAR(stemp)=('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool))\n"
    "# Entered g2p_apply: sobj=(#t 5)  stemplate=('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool))\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=#t  CAR(stemp)=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_apply: sobj=#t  stemplate=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_leaf: sobj=#t  stemplate=('g2p_num2Int 'g2p_bool2Bool)\n"
    "# g2p_leaf: trying another stemplate 'g2p_num2Int on sobj\n"
    "# Entered g2p_apply: sobj=#t  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: unsuccessful conversion: #t is not a num value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_bool2Bool on sobj\n"
    "# Entered g2p_apply: sobj=#t  stemplate='g2p_bool2Bool\n"
    "# g2p_bool2Bool: successful conversion of #t into a Python Bool value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_leaf: successful conversion\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=5  CAR(stemp)=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_apply: sobj=5  stemplate=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_leaf: sobj=5  stemplate=('g2p_num2Int 'g2p_bool2Bool)\n"
    "# g2p_leaf: trying another stemplate 'g2p_num2Int on sobj\n"
    "# Entered g2p_apply: sobj=5  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: successful conversion of 5 into a Python Int value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_leaf: successful conversion\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2List: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"'[True, 5]'\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"'[True, 5]'\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"'[True, 5]'\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"'[True, 5]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"'[True, 5]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"'[True, 5]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"'[True, 5]'\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"'[True, 5]'\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"'[True, 5]'\" into SCM\n")))
(is-ok 7 "g2p_leaf verbosity/3 coverage - all values recognized by leaf"
       expres7
       (with-output-to-string
	 (thunk-invoke-python-repr
	  '((#t 5 ))
	  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_num2Int g2p_bool2Bool))))))

; Run thunk-invoke-python-repr under catch harness.
(define catch-thunk-invoke-python-repr
  (lambda (arg . template)
    (lambda ()
      (catch
       #t
       (lambda ()
	 (if (null? template)
	     (python-apply '("__builtin__" "repr") arg '())
	     (python-apply '("__builtin__" "repr") arg '() (car template))))
       (lambda (key . args2) (object->string (list key args2)))))))

(define expres8
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=((3.1 5))  stemplate=('g2p_list2Tuple ('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(3.1 5)  CAR(stemp)=('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool))\n"
    "# Entered g2p_apply: sobj=(3.1 5)  stemplate=('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool))\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=3.1  CAR(stemp)=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_apply: sobj=3.1  stemplate=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_leaf: sobj=3.1  stemplate=('g2p_num2Int 'g2p_bool2Bool)\n"
    "# g2p_leaf: trying another stemplate 'g2p_num2Int on sobj\n"
    "# Entered g2p_apply: sobj=3.1  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: unsuccessful conversion: 3.1 is not a num value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_bool2Bool on sobj\n"
    "# Entered g2p_apply: sobj=3.1  stemplate='g2p_bool2Bool\n"
    "# g2p_bool2Bool: unsuccessful conversion: 3.1 is not a bool value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: unsuccessful conversion, no stemplate fit the sobj\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_list2List: unsuccessful conversion of element 0: 3.1 does not match personalized template\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_list2Tuple: unsuccessful conversion of element 0: (3.1 5) does not match personalized template\n"
    "# Leaving g2p_apply: with null result\n")))
(is-ok 8 "g2p_leaf verbosity/3 coverage - first value not recognized by leaf"
       expres8
       (with-output-to-string
	 (catch-thunk-invoke-python-repr
	  '((3.1 5))
	  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_num2Int g2p_bool2Bool))))))

(define expres9
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=((#t \"string\"))  stemplate=('g2p_list2Tuple ('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=(#t \"string\")  CAR(stemp)=('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool))\n"
    "# Entered g2p_apply: sobj=(#t \"string\")  stemplate=('g2p_list2List ('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool))\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=#t  CAR(stemp)=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_apply: sobj=#t  stemplate=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_leaf: sobj=#t  stemplate=('g2p_num2Int 'g2p_bool2Bool)\n"
    "# g2p_leaf: trying another stemplate 'g2p_num2Int on sobj\n"
    "# Entered g2p_apply: sobj=#t  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: unsuccessful conversion: #t is not a num value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_bool2Bool on sobj\n"
    "# Entered g2p_apply: sobj=#t  stemplate='g2p_bool2Bool\n"
    "# g2p_bool2Bool: successful conversion of #t into a Python Bool value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_leaf: successful conversion\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# DEBUG: g2p_list2List - processing item CAR(sobj)=\"string\"  CAR(stemp)=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate=('g2p_leaf 'g2p_num2Int 'g2p_bool2Bool)\n"
    "# Entered g2p_leaf: sobj=\"string\"  stemplate=('g2p_num2Int 'g2p_bool2Bool)\n"
    "# g2p_leaf: trying another stemplate 'g2p_num2Int on sobj\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate='g2p_num2Int\n"
    "# g2p_num2Int: unsuccessful conversion: \"string\" is not a num value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_bool2Bool on sobj\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate='g2p_bool2Bool\n"
    "# g2p_bool2Bool: unsuccessful conversion: \"string\" is not a bool value\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: unsuccessful conversion, no stemplate fit the sobj\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_list2List: unsuccessful conversion of element 1: \"string\" does not match personalized template\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_list2Tuple: unsuccessful conversion of element 0: (#t \"string\") does not match personalized template\n"
    "# Leaving g2p_apply: with null result\n")))
(is-ok 9 "g2p_leaf verbosity/3 coverage - last value not recognized by leaf"
       expres9
       (with-output-to-string
	 (catch-thunk-invoke-python-repr
	  '((#t "string"))
	  (list g2p_list2Tuple (list g2p_list2List (list g2p_leaf g2p_num2Int g2p_bool2Bool))))))

(define saved-verbosity (pyguile-verbosity-set! 0))

(define catch-test-apply
  (lambda (func args kws . targ)
    (catch #t
	   (lambda () (python-apply func args kws (car targ)))
	   (lambda (key . args2) (object->string (list key args2))))))

(is-ok 10 "g2p_null2* validate test - non-null values"
       "(misc-error (\"python-apply\" \"positional arguments conversion failure (~S)\" ((\"string\")) #f))"
       (catch-test-apply '("__builtin__" "repr") '("string") '()
			 (list g2p_list2Tuple (list g2p_leaf g2p_null2Tuple0 g2p_null2List0 g2p_null2DictEmpty))))

(pyguile-verbosity-set! saved-verbosity)

(define expres11
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=(\"string\")  stemplate=('g2p_list2Tuple ('g2p_leaf 'g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=\"string\"  CAR(stemp)=('g2p_leaf 'g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty)\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate=('g2p_leaf 'g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty)\n"
    "# Entered g2p_leaf: sobj=\"string\"  stemplate=('g2p_null2Tuple0 'g2p_null2List0 'g2p_null2DictEmpty)\n"
    "# g2p_leaf: trying another stemplate 'g2p_null2Tuple0 on sobj\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate='g2p_null2Tuple0\n"
    "# g2p_null2Tuple0: unsuccessful conversion: \"string\" is not null\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_null2List0 on sobj\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate='g2p_null2List0\n"
    "# g2p_null2List0: unsuccessful conversion: \"string\" is not null\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: trying another stemplate 'g2p_null2DictEmpty on sobj\n"
    "# Entered g2p_apply: sobj=\"string\"  stemplate='g2p_null2DictEmpty\n"
    "# g2p_null2DictEmpty: unsuccessful conversion: \"string\" is not null\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_leaf: unsuccessful conversion, no stemplate fit the sobj\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_list2Tuple: unsuccessful conversion of element 0: \"string\" does not match personalized template\n"
    "# Leaving g2p_apply: with null result\n")))
(is-ok 11 "g2p_null2* verbosity/3 coverage - non-null values"
       expres11
       (with-output-to-string
	 (catch-thunk-invoke-python-repr
	  '("string")
	  (list g2p_list2Tuple (list g2p_leaf g2p_null2Tuple0 g2p_null2List0 g2p_null2DictEmpty)))))


(define expres12
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=(())  stemplate=('g2p_list2Tuple ('g2p_leaf . 'g2p_null2Tuple0))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=()  CAR(stemp)=('g2p_leaf . 'g2p_null2Tuple0)\n"
    "# Entered g2p_apply: sobj=()  stemplate=('g2p_leaf . 'g2p_null2Tuple0)\n"
    "# Entered g2p_leaf: sobj=()  stemplate='g2p_null2Tuple0\n"
    "# g2p_null2Tuple0: successful conversion of () into Python ()\n"
    "# Leaving g2p_leaf, after G2P_SMOBP conversion, with non-null result\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# p2g_apply: pobj=\"'()'\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"'()'\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"'()'\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"'()'\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"'()'\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"'()'\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"'()'\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"'()'\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: successful conversion of \"'()'\" into SCM\n")))
(is-ok 12 "g2p_leaf verbosity/3 coverage - G2P_SMOB, successful"
       expres12
       (with-output-to-string
	 (catch-thunk-invoke-python-repr
	  '(())
	  (list g2p_list2Tuple (cons g2p_leaf g2p_null2Tuple0)))))

(define expres13
  (string-concatenate
   (list
    successful-verbose-3-report
    "# Entered g2p_apply: sobj=(#t)  stemplate=('g2p_list2Tuple ('g2p_leaf . 'g2p_null2Tuple0))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=#t  CAR(stemp)=('g2p_leaf . 'g2p_null2Tuple0)\n"
    "# Entered g2p_apply: sobj=#t  stemplate=('g2p_leaf . 'g2p_null2Tuple0)\n"
    "# Entered g2p_leaf: sobj=#t  stemplate='g2p_null2Tuple0\n"
    "# g2p_null2Tuple0: unsuccessful conversion: #t is not null\n"
    "# Leaving g2p_leaf, after G2P_SMOBP conversion, with null result\n"
    "# Leaving g2p_apply: with null result\n"
    "# g2p_list2Tuple: unsuccessful conversion of element 0: #t does not match personalized template\n"
    "# Leaving g2p_apply: with null result\n")))
(is-ok 13 "g2p_leaf verbosity/3 coverage - G2P_SMOB, failed"
       expres13
       (with-output-to-string
	 (catch-thunk-invoke-python-repr
	  '(#t)
	  (list g2p_list2Tuple (cons g2p_leaf g2p_null2Tuple0)))))

; End of 19_verbose_always.t
