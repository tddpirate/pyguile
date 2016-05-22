#!/usr/bin/guile -s
!#
; Basic g2p2g_smob tests
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

(plan 6)

(is-ok 1 "g2p_null2PyNone" "'g2p_null2PyNone"
	    (with-output-to-string (lambda () (display g2p_null2PyNone))))

(is-ok 2 "guile2python" "'guile2python"
       (with-output-to-string (lambda () (display guile2python))))

(is-ok 3 "guileassoc2pythondict" "'guileassoc2pythondict"
       (with-output-to-string (lambda () (display guileassoc2pythondict))))

(is-ok 4 "p2g_None2SCM_EOL" "'p2g_None2SCM_EOL"
       (with-output-to-string (lambda () (display p2g_None2SCM_EOL))))

(is-ok 5 "p2g_Dict2alist" "'p2g_Dict2alist"
       (with-output-to-string (lambda () (display p2g_Dict2alist))))

(is-ok 6 "python2guile" "'python2guile"
       (with-output-to-string (lambda () (display python2guile))))

; End of 11_g2p2g.t
