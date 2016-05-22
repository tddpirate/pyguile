#!/usr/bin/guile -s
!#
; Pyguile tests - exercise python-apply
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
(python-import "os.path")

(is-ok 1 "exists" #t
       (python-apply '("os.path" exists) '("t/04_python_apply.t") '()))
(is-ok 2 "does not exist" #f
       (python-apply '("os.path" exists) '("t/04_python_apply.tnone") '()))
(is-ok 3 "join 3 arguments" "Pyguile/t/04_python_apply.t"
       (python-apply '("os.path" "join") '("Pyguile" "t" "04_python_apply.t") '()))

(python-eval "import sys;sys.path = ['']+sys.path\n")
(python-import "t.scripts.t4apply")

(is-ok 4 "object path without arguments" "33y"
       (python-apply '("t.scripts.t4apply" mainobj "cl2func") '() '()))

(is-ok 5 "object path with positional argument as symbol" "33pos"
       (python-apply '("t.scripts.t4apply" mainobj "cl2func") '(pos) '()))

(is-ok 6 "object path with positional argument as string" "33:str"
       (python-apply '("t.scripts.t4apply" mainobj "cl2func") '(":str") '()))

(is-ok 7 "object path with kw+argument as symbols" "33symkw"
       (python-apply '("t.scripts.t4apply" mainobj "cl2func") '() '((#:argx . symkw ))))

(is-ok 8 "object path with kw+argument as strings" "33=strkw"
       (python-apply '("t.scripts.t4apply" mainobj "cl2func") '() '((#:argx . "=strkw" ))))

(is-ok 9 "object path with kw symbol, argument as string" "33<><>"
       (python-apply '("t.scripts.t4apply" mainobj "cl2func") '() '((#:argx . "<><>" ))))

(is-ok 10 "Return arguments" "positional: (True, 1, -3, 'mystr', 'symbolic')      keywords: {'kw4n': 65537, 'keyword1': 'symb1', 'kw3': 'trying3', 'KW_stri2': 'symb2'}"
       (python-apply '("t.scripts.t4apply" return_args)
		     '(#t 1 -3 "mystr" symbolic)
		     '((#:keyword1 . symb1) (#:KW_stri2 . symb2)
		       (#:kw3 . #:trying3 ) (#:kw4n . 65537))))

; End of 04_guile2python.t
