#!/usr/bin/guile -s
!#
; Pyguile tests - transferring data from Python to Guile
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

(plan 10)
(python-eval "import sys;sys.path = ['']+sys.path\n")
(python-eval "from t.scripts.t2conv import *\n")

;(if (python-import "t.scripts.t2conv") (ok 1 "Imported t2conv" #t)
;    (bail-out "Could not import t2conv"))

(is-ok 1 "None" 0 (length (python-eval "return_None()" #t)))
(is-ok 2 "True" #t (python-eval "return_True()" #t))
(is-ok 3 "False" #f (python-eval "return_False()" #t))
(is-ok 4 "1" 1 (python-eval "return_Int1()" #t))
(is-ok 5 "-5" -5 (python-eval "return_Int_5()" #t))
(is-ok 6 "2^65" 36893488147419103232 (python-eval "return_BigInt()" #t))
(is-ok 7 "-2^65" -36893488147419103232 (python-eval "return_BigInt_neg()" #t))
(is-ok 8 "string 1" "abcdefghi" (python-eval "return_String1()" #t))
(is-ok 9 "string 2" "01abCD%^" (python-eval "return_String2()" #t))
(is-ok 10 "string 3"
       (string-append "bef" (list->string (list (integer->char 0) (integer->char 163))) "ore")
       (python-eval "return_String_Zero()" #t))

; End of 02_pyguile.t
