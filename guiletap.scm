; Define functions for running Guile-written tests under the TAP protocol.
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
;;;
;;; To invoke it:
;;; (use-modules (guiletap))
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-module (guiletap))
(export plan)
(export ok)
(export bail-out)
(export diag)
(export is-ok)
(export like)
(export diagprint)

(use-modules (ice-9 format))
(use-modules (ice-9 regex))

; n is the number of tests.
(define plan
  (lambda (n) (display (format "1..~d~%" n))))

; n -        test number
; testdesc - test descriptor
; res -      result which is #f at failure, other at success.
(define ok
  (lambda (n testdesc res)
    (if (not res)(display "not "))
    (display (format "ok ~d - ~a~%" n testdesc))))

; testdesc - test descriptor
(define bail-out
  (lambda (testdesc)
    (display (format "Bail out! - ~a~%" testdesc))))

; diagmsg - diagnostic message
(define diag
  (lambda (diagmsg)
    (display (format "# ~a~%" diagmsg))))

; n -        test number
; testdesc - test descriptor
; expres -   expected test result
; actres -   actual test result
; Does not print expected+actual results even when they differ.
(define is-ok-silent
  (lambda (n testdesc expres actres)
    (ok n testdesc (equal? expres actres))))

; Has the same arguments as is-ok and like, but
; instead of performing comparisons, it just prints
; the information.
(define diagprint
  (lambda (n testdesc exp actres)
    (display (format "# Test ~d - ~a:~%" n testdesc))
    (display (format "# Exp: ~a~%# Act: ~a~%" exp actres))))

; Match the actual result to a POSIX extended regular expression
; (which is supported by Guile, by default).
; n -        test number
; testdesc - test descriptor
; exppatt -  pattern to match expected test result
; actres -   actual test result
(define like
  (lambda (n testdesc exppatt actres)
    (ok n testdesc (string-match exppatt actres))
    (if (not (string-match exppatt actres))
	(diagprint n testdesc exppatt actres))))

; Same as is-ok-silent except that it prints expected and
; actual results if they differ.
(define is-ok
  (lambda (n testdesc expres actres)
    (is-ok-silent n testdesc expres actres)
    (if (not (equal? expres actres))
	(diagprint n testdesc expres actres))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; !!! TODO:
; !!! To be implemented also:
; plan-no-plan
; plan-skip-all [REASON]
;
; is RESULT EXPECTED [NAME]
; isnt RESULT EXPECTED [NAME]
; unlike RESULT PATTERN [NAME]
; pass [NAME]
; fail [NAME]
;
; skip CONDITION [REASON] [NB_TESTS=1]
; Specify TODO mode by setting $TODO:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of guiletap.scm
