#!/usr/bin/guile -s
!#
; Auxiliary functions, for use by test scripts
; Those functions are used by scripts from 20_* and on.
; Earlier scripts usually define their own versions of the
; functions.
;
; To use the functions, add
;   (load "scripts/test_auxliary_functions.scm")
; at the beginning of your test script, after any (use-modules ...)
; calls.
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
(use-modules (ice-9 regex))   ; regexp-substitute

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Functions from modules, unlikely to be generally useful
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; from 03_guile2python.t
(define invoke-python-func
  (lambda (module func arg)
    (python-apply (list module func) (list arg) '())))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Functions likely to be generally useful
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Miscellaneous data manipulation  ;
;             functions            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Returns a 3-element list of booleans.
(define equalities3?
  (lambda (obj1 obj2)
    (list (eq? obj1 obj2) (eqv? obj1 obj2) (equal? obj1 obj2))))

; Does one alist include another alist.
; Inclusion means that all keys of the included alist are in the
; including one, and the corresponding values are equal.
; The equality criteria used here is equal? (for both key and value).
(define alist-properly-included?
  (lambda (included includor)
    (if (null? included) #t
	(let ((key (caar included))
	      (value (cdar included))
	      (rest (cdr included)))
	  (let ((includor-ref (assoc key includor)))
	    (cond ((not includor-ref) #f)
		  ((not (equal? (cdr includor-ref) value)) #f)
		  (else (alist-properly-included? rest includor))))))))

; Are two alists equal?
(define alist-equal?
  (lambda (alista alistb)
    (and (alist-properly-included? alista alistb)
	 (alist-properly-included? alistb alista))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modify actual results for easier ;
; comparison to expected results   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Replace all hex addresses appearing in a string
; by a specific literal.
(define substitute-hex-addresses-for-gggggggg
  (lambda (strarg)
    (regexp-substitute/global #f
			      "0x[0-9a-f]{8}"
			      strarg
			      'pre "0xgggggggg" 'post)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Running inside catch harness     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Run a function, so that anything it writes to the current
; output port is captured, together with its return value.
; The return value to caller of capture-result-output is the
; pair of (return-value . output-string).

(define capture-result-output
  (lambda (func . args)
    (let ((stdoutstr #f)
	  (retval #f))
      (set! stdoutstr
	    (with-output-to-string
	      (lambda () (set! retval
			       (apply func args)))))
      (cons retval stdoutstr))))

; Run a function in an environment, in which any exceptions
; raised by it are caught; and anything it writes to the
; current output port is captured as well.
; The return value to caller of capture-result-output-catch
; is the pair of (return-value . output-string).
(define capture-result-output-catch
  (lambda (func . args)
    (let ((output-string #f)
	  (return-value  #f))
      (set! output-string
	    (with-output-to-string
	      (lambda () (set! return-value
			       (catch #t
				      (lambda () (apply func args))
				      (lambda (key . args2)
					(object->string (list key args2))))))))
      (cons return-value output-string))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Functions specific to PyGuile    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Run python-eval under catch harness.
; template can be #f when no return value is expected, or #t when
; the default template is to be used.
(define catch-python-eval
  (lambda (txt template)
    (catch #t
	   (lambda () (python-eval txt template))
	   (lambda (key . args) (object->string (list key args))))))

; Run python-import under catch harness.
(define catch-python-import
  (lambda (arg)
    (catch #t
	   (lambda () (python-import arg))
	   (lambda (key . args) (object->string (list key args))))))

; Run python-apply under catch harness.
; The positional argument list must be supplied.
; The keyword argument list and the templates are optional.
(define catch-python-apply
  (lambda (func posargs . kwargs-templates)
    (catch #t
	   (lambda () (apply python-apply func posargs kwargs-templates))
	   (lambda (key . args) (object->string (list key args))))))

; The following function is useful for checking how a SCM is
; actually converted into a PyObject using a template.
; The conversion is run under a catch harness.
(define catch-thunk-invoke-python-repr
  (lambda (arg . template)
    (catch #t
	   (lambda ()
	     (if (null? template)
		 (python-apply '("__builtin__" "repr") arg '())
		 (python-apply '("__builtin__" "repr") arg '() (car template))))
	   (lambda (key . args2) (object->string (list key args2))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; End of test_axuliary_functions.scm
