#!/usr/bin/guile -s
!#
; Additional PyGuile tests - transferring data from Python to Guile.
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

(plan 8)

(is-ok 1 "Float 1.5" 1.5
       (python-eval "1.5" #t))

(is-ok 2 "Float 10000000.5" 10000000.5
       (python-eval "10000000 + 0.5" #t))

(is-ok 3 "Float 1e+20" 1e20
       (python-eval "1e11*1e9" #t))

(is-ok 4 "Complex" '(1.0+1.0i 2.0-3.0i -3.0-4.0i -4.0+5.0i)
       (python-eval "[1+1j,2-3j,-3-4j,-4+5j]" #t))

(is-ok 5 "bigint" 123456789101112131415
       (python-eval "15 + 100*1234567891011121314" #t))

(is-ok 6 "list" '("ab" "cd")
       (python-eval "['ab','cd']" #t))

(is-ok 7 "tuple" '("ab" "cd")
       (python-eval "('ab','cd')" #t))

; !!! Need to sort to ensure consistent test results.
(is-ok 8 "dict" '((6 . (78 90)) (3 . "4.5") (1 . 2.2))
       (python-eval "{1 : 2.2, 3 : '4.5', 6 : (78,90)}" #t))

; End of 10_python2guile.t
