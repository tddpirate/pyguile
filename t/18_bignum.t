#!/usr/bin/guile -s
!#
; Miscellaneous tests of PyGuile data handling
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

(python-eval "def func(val):\n  global longint\n  longint=val\n" #f)

(plan 3)

(python-apply "func" '("abc") '())
; The following won't work because Guile's and Python's stdout are
; separately controlled.
;;(is-ok 1 "should yield 'abc'"
;;       "abc\n"
;;       (with-output-to-string
;;	 (lambda ()
;;	   (python-eval "print longint\n" #f))))
(is-ok 1 "should yield 'abc'"
       "abc"
       (python-eval "longint" #t))

(python-apply "func" '(3773) '())
(is-ok 2 "should yield 3773"
       3773
       (python-eval "longint" #t))

(python-apply "func" '(36893488147419103232) '())
(is-ok 3 "should yield the bignum"
       36893488147419103232
       (python-eval "longint" #t))

; End of 18_bignum.t
