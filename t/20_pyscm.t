#!/usr/bin/guile -s
!#
; PySCM related tests.
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
(load "scripts/test_auxiliary_functions.scm")

(plan 7)

(define guilefunc0
  (lambda (dummy1 dummy2) 2.73))
(define pyfunc0code
  (string-concatenate
   '("def pyfunc0(func):\n"
     "  return(4.1 + func())\n")))
(python-eval pyfunc0code)
(define pyfunc0-smob (python-eval "pyfunc0" #t))


(is-ok 1 "show argumentless guile procedure and Python function"
       "#<procedure guilefunc0 (dummy1 dummy2)>\n(python-eval <function pyfunc0 at 0xgggggggg> #t)\n"
       (substitute-hex-addresses-for-gggggggg
	(cdr
	 (capture-result-output-catch
	  (lambda ()
	    (display guilefunc0)
	    (newline)
	    (display pyfunc0-smob)
	    (newline))))))

(is-ok 2 "pysmob func, using argumentless guile procedure"
       6.83
       (python-apply pyfunc0-smob (list guilefunc0) '()
		     (list g2p_list2Tuple (cons g2p_procedure2PySCMObject pyscm-default-template))))

(define expres3_cdr
  (string-concatenate
   (list
    "# guile2python: entry: seeking to convert sobj=(python-eval <function pyfunc0 at 0xgggggggg> #t); unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not null\n"
    "# g2p_list2List: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a string value\n"
    "# g2p_symbol2String: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a symbol value\n"
    "# g2p_keyword2String: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a keyword value\n"
    "# g2p_procedure2PySCMObject: unsuccessful conversion: (python-eval <function pyfunc0 at 0xgggggggg> #t) is not a procedure\n"
    "# g2p_opaque2Object: the Python object inside opaque pysmob (python-eval <function pyfunc0 at 0xgggggggg> #t) is unwrapped\n"
    "# python_apply: decoded pfunc \"<function pyfunc0 at 0xgggggggg>\"\n"
    "# python_apply: decoded function actually to be invoked: \"<function pyfunc0 at 0xgggggggg>\"\n"
    "# Entered g2p_apply: sobj=(#<procedure guilefunc0 (dummy1 dummy2)>)  stemplate=('g2p_list2Tuple ('g2p_procedure2PySCMObject . #('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=#<procedure guilefunc0 (dummy1 dummy2)>  CAR(stemp)=('g2p_procedure2PySCMObject . #('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f))\n"
    "# Entered g2p_apply: sobj=#<procedure guilefunc0 (dummy1 dummy2)>  stemplate=('g2p_procedure2PySCMObject . #('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f))\n"
    "# wrap_scm: was called to wrap #<procedure guilefunc0 (dummy1 dummy2)>\n"
    "# g2p_procedure2PySCMObject: successful conversion: #<procedure guilefunc0 (dummy1 dummy2)> has been wrapped\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# python_apply: decoded positional arguments \"(<pyscm.PySCM object at 0xgggggggg>,)\"\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# python_apply: decoded keyword arguments \"{}\"\n"
    "# pyscm_PySCM_call: calling #<procedure guilefunc0 (dummy1 dummy2)> with args=\"()\" and keywords=\"(null PyObject)\"; stemplate=#('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f)\n"
    "# p2g_apply: pobj=\"()\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"()\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: failed to convert pobj=\"()\"  using stemplate=#<unspecified>\n"
    "# Entered g2p_apply: sobj=2.73  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=2.73; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: 2.73 is not null\n"
    "# g2p_list2List: unsuccessful conversion: 2.73 is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: 2.73 is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: 2.73 is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: 2.73 is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: 2.73 is not a bignum value\n"
    "# g2p_real2Float: successful conversion of 2.73 into a Python Float value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# p2g_apply: pobj=\"6.8300000000000001\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"6.8300000000000001\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"6.8300000000000001\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"6.8300000000000001\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"6.8300000000000001\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"6.8300000000000001\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: successful conversion of \"6.8300000000000001\" into SCM\n"
    "# python_apply: decoded results:\n"
    "#     Python: \"6.8300000000000001\"\n"
    "#     Scheme: 6.83\n")))
(define saved-verbosity (pyguile-verbosity-set! (+ 3 64 128 256)))
(define gggggggg-transform-cdr  ; perform substitute-hex-addresses-for-gggggggg only on cdr of the argument
  (lambda (arg)
    (cons (car arg)
	  (substitute-hex-addresses-for-gggggggg (cdr arg)))))
(is-ok 3 "pysmob func, using argumentless guile procedure"
       (cons 6.83 expres3_cdr)
       (gggggggg-transform-cdr
	(capture-result-output-catch
	 python-apply pyfunc0-smob (list guilefunc0) '()
	 (list g2p_list2Tuple (cons g2p_procedure2PySCMObject pyscm-default-template)))))
(pyguile-verbosity-set! saved-verbosity)

(define guilefunc
  (lambda (arg dummy) (+ 3.5 (car arg))))
(define pyfunccode
  (string-concatenate
   '("def pyfunc(argu,func):\n"
     "  return(4.2 + func(argu))\n")))
(python-eval pyfunccode)
(define pyfunc-smob (python-eval "pyfunc" #t))

(is-ok 4 "show guile procedure with argument and Python function"
       "#<procedure guilefunc (arg dummy)>\n(python-eval <function pyfunc at 0xgggggggg> #t)\n"
       (substitute-hex-addresses-for-gggggggg
	(cdr
	 (capture-result-output-catch
	  (lambda ()
	    (display guilefunc)
	    (newline)
	    (display pyfunc-smob)
	    (newline))))))


(is-ok 5 "pysmob func, using guile procedure with argument"
       67.7
       (python-apply pyfunc-smob (list 60.0 guilefunc) '()
		     (list g2p_list2Tuple g2p_real2Float (cons g2p_procedure2PySCMObject pyscm-default-template))))

(define expres6_cdr
  (string-concatenate
   (list
    "# guile2python: entry: seeking to convert sobj=(python-eval <function pyfunc at 0xgggggggg> #t); unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not null\n"
    "# g2p_list2List: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a bignum value\n"
    "# g2p_real2Float: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a real value\n"
    "# g2p_complex2Complex: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a complex value\n"
    "# g2p_string2String: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a string value\n"
    "# g2p_symbol2String: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a symbol value\n"
    "# g2p_keyword2String: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a keyword value\n"
    "# g2p_procedure2PySCMObject: unsuccessful conversion: (python-eval <function pyfunc at 0xgggggggg> #t) is not a procedure\n"
    "# g2p_opaque2Object: the Python object inside opaque pysmob (python-eval <function pyfunc at 0xgggggggg> #t) is unwrapped\n"
    "# python_apply: decoded pfunc \"<function pyfunc at 0xgggggggg>\"\n"
    "# python_apply: decoded function actually to be invoked: \"<function pyfunc at 0xgggggggg>\"\n"
    "# Entered g2p_apply: sobj=(60.0 #<procedure guilefunc (arg dummy)>)  stemplate=('g2p_list2Tuple 'g2p_real2Float ('g2p_procedure2PySCMObject . #('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f)))\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=60.0  CAR(stemp)='g2p_real2Float\n"
    "# Entered g2p_apply: sobj=60.0  stemplate='g2p_real2Float\n"
    "# g2p_real2Float: successful conversion of 60.0 into a Python Float value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple - processing item CAR(sobj)=#<procedure guilefunc (arg dummy)>  CAR(stemp)=('g2p_procedure2PySCMObject . #('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f))\n"
    "# Entered g2p_apply: sobj=#<procedure guilefunc (arg dummy)>  stemplate=('g2p_procedure2PySCMObject . #('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f))\n"
    "# wrap_scm: was called to wrap #<procedure guilefunc (arg dummy)>\n"
    "# g2p_procedure2PySCMObject: successful conversion: #<procedure guilefunc (arg dummy)> has been wrapped\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# g2p_list2Tuple: successful conversion of list () by template\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# python_apply: decoded positional arguments \"(60.0, <pyscm.PySCM object at 0xgggggggg>)\"\n"
    "# guileassoc2pythondict: entry: seeking to convert sobj=() using stemplate=#<undefined>\n"
    "# guileassoc2pythondict: successful conversion of ()\n"
    "# python_apply: decoded keyword arguments \"{}\"\n"
    "# pyscm_PySCM_call: calling #<procedure guilefunc (arg dummy)> with args=\"(60.0,)\" and keywords=\"(null PyObject)\"; stemplate=#('python2guile 'python2guile 'guile2python #<procedure apply (fun . args)> #f)\n"
    "# p2g_apply: pobj=\"(60.0,)\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"(60.0,)\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: failed to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_Complex2complex: failed to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_String2string: failed to convert pobj=\"(60.0,)\"  using stemplate=#<unspecified>\n"
    "# p2g_apply: pobj=\"60.0\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"60.0\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"60.0\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"60.0\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"60.0\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"60.0\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: successful conversion of \"60.0\" into SCM\n"
    "# p2g_Tuple2list: 1. converted item pobj=0[\"60.0\"], stemplate='python2guile\n"
    "# Entered g2p_apply: sobj=63.5  stemplate='guile2python\n"
    "# guile2python: entry: seeking to convert sobj=63.5; unused stemplate=#<unspecified>\n"
    "# g2p_null2PyNone: unsuccessful conversion: 63.5 is not null\n"
    "# g2p_list2List: unsuccessful conversion: 63.5 is not a list\n"
    "# g2p_pair2Tuple: unsuccessful conversion: 63.5 is not a pair\n"
    "# g2p_bool2Bool: unsuccessful conversion: 63.5 is not a bool value\n"
    "# g2p_num2Int: unsuccessful conversion: 63.5 is not a num value\n"
    "# g2p_bignum2Long: unsuccessful conversion: 63.5 is not a bignum value\n"
    "# g2p_real2Float: successful conversion of 63.5 into a Python Float value\n"
    "# Leaving g2p_apply: with non-null result\n"
    "# p2g_apply: pobj=\"67.700000000000003\"  smob-stemplate='python2guile\n"
    "# python2guile: trying to convert pobj=\"67.700000000000003\"  using stemplate=#<unspecified>\n"
    "# p2g_None2SCM_EOL: pobj=\"67.700000000000003\" stemplate=#<unspecified>\n"
    "# p2g_Bool2SCM_BOOL: failed to convert pobj=\"67.700000000000003\"  using stemplate=#<unspecified>\n"
    "# p2g_Int2num: failed to convert pobj=\"67.700000000000003\"  using stemplate=#<unspecified>\n"
    "# p2g_Long2bignum: failed to convert pobj=\"67.700000000000003\"  using stemplate=#<unspecified>\n"
    "# p2g_Float2real: successful conversion of \"67.700000000000003\" into SCM\n"
    "# python_apply: decoded results:\n"
    "#     Python: \"67.700000000000003\"\n"
    "#     Scheme: 67.7\n")))
(set! saved-verbosity (pyguile-verbosity-set! (+ 3 64 128 256)))
(is-ok 6 "pysmob func, using guile procedure with argument"
       (cons 67.7 expres6_cdr)
       (gggggggg-transform-cdr
	(capture-result-output-catch
	 python-apply pyfunc-smob (list 60.0 guilefunc) '()
	 (list g2p_list2Tuple g2p_real2Float (cons g2p_procedure2PySCMObject pyscm-default-template)))))
(pyguile-verbosity-set! saved-verbosity)

(python-eval "def holdval(val):\n  global heldval\n  heldval=val\n")
(python-apply '("__main__" "holdval") (list guilefunc0) '())
(like 7 "obtain python representation of a procedure value"
      "^#<procedure guilefunc0 \\([-a-zA-Z0-9_]+ [-a-zA-Z0-9_]+\\)>$"
      (object->string (python-eval "heldval" #t)))

; End of 20_pyscm.t
