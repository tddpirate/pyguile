#!/usr/bin/guile -s
!#
; Pyguile tests - transferring data from Guile to Python.
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

(plan 14)

(define invoke-python-func
  (lambda (module func arg)
    (python-apply (list module func) (list arg) '())))

(is-ok 1 "None" "None" (invoke-python-func "__builtin__" "repr" (list)))
(is-ok 2 "True" "True" (invoke-python-func "__builtin__" "repr" #t))
(is-ok 3 "False" "False" (invoke-python-func "__builtin__" "repr" #f))
(is-ok 4 "int 1" "1" (invoke-python-func "__builtin__" "repr" 1))
(is-ok 5 "int -5" "-5" (invoke-python-func "__builtin__" "repr" -5))
(is-ok 6 "string 1" "'string 1'"
       (invoke-python-func "__builtin__" "repr" "string 1"))
(is-ok 7 "char P" "'P'" (invoke-python-func "__builtin__" "repr" #\P))
(is-ok 8 "symbol symba" "'symba'"
       (invoke-python-func "__builtin__" "repr" 'symba))
(is-ok 9 "complex 1-1i" "(1-1j)" (invoke-python-func "__builtin__" "repr" 1-1i))
(is-ok 10 "float 3.125" "3.125" (invoke-python-func "__builtin__" "repr" 3.125))
(define big10to7th 10000000)
(define big10to35th (* big10to7th big10to7th big10to7th big10to7th big10to7th))
(is-ok 11 "bignum 10^35" "100000000000000000000000000000000000L"
       (invoke-python-func "__builtin__" "repr" big10to35th))
(is-ok 12 "pair" "('mycar', 42)"
    (invoke-python-func "__builtin__" "repr" (cons "mycar" (* 21 2))))
(is-ok 13 "list 1" "['item1', 'item2', 'item3']"
    (invoke-python-func "__builtin__" "repr" '(item1 item2 "item3")))
(is-ok 14 "list 2" "['lambda', ['arg1', 'arg2'], ['display', 'textA'], ['newline'], ['display', 'arg1'], ['newline'], ['display', 'arg2']]"
    (invoke-python-func "__builtin__" "repr" '(lambda (arg1 arg2)(display "textA")(newline)(display arg1)(newline)(display arg2))))

; End of 03_guile2python.t
