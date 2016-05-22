#!/usr/bin/guile -s
!#
; Basic tests of the PyGuile verbosity control
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

(plan 4)

(pyguile-verbosity-set! 43)
(is-ok 1 "Verbosity value should be 43"
       43
       (pyguile-verbosity-set! 10))

(is-ok 2 "Verbosity value should be 10"
       10
       (pyguile-verbosity-set! 0))

(is-ok 3 "Verbosity value should be 0"
       0
       (pyguile-verbosity-set! 0))

(is-ok 4 "Trying to set verbosity value to a non-number"
       "(wrong-type-arg (\"pyguile-verbosity-set!\" \"Wrong type argument in position ~A: ~S\" (1 \"NAN\") #f))"
       (catch #t
	      (lambda () (pyguile-verbosity-set! "NAN"))
	      (lambda (key . args) (object->string (list key args)))))

; End of 16_verbose.t
