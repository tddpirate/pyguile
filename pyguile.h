// pyguile header file
#ifndef PYGUILE_H
#define PYGUILE_H

////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2008 Omer Zak.
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this library, in a file named COPYING; if not, write to the
// Free Software Foundation, Inc., 59 Temple Place, Suite 330,
// Boston, MA  02111-1307  USA
//
// For licensing issues, contact <w1@zak.co.il>.
//
////////////////////////////////////////////////////////////////////////

#include <Python.h>   // Must be first header file
#include <libguile.h>

////////////////////////////////////////////////////////////////////////
// Functions exported by the library to Guile
////////////////////////////////////////////////////////////////////////


// Import Python module whose name is given in the SCM.
// The returned value is a pysmob pointing at the module PyObject.
//
// NOTE:  support for representing nested module names (like "os.path")
//        by a list like ("os" "path") will be implemented by means
//        of Scheme level macros.
// NOTE:  we support only strings - not symbols or keywords - due to
//        potential existence of dots.
extern SCM python_import(SCM smodulename);

////////////////////////////////////////////////////////////////////////
// Final pyguile interface functions
////////////////////////////////////////////////////////////////////////

// Evaluate a string, which is a Python script.
// sobj - the string to be evaluated.
// smode - #f or unspecified - if the caller does not expect a return value.
//               The string is evaluated under Py_file_input.
//         #t if the caller expects a return value and wants to
//               convert it using the default template (python2guile).
//               The string is evaluated under Py_eval_input.
//         Any other value - is caller-supplied template for
//               converting the return value.
//   PyRun_String() 2nd argument value is
//     smode ? Py_eval_input : Py_file_input
//   This is an optional argument, defaulting to #f.
//
// Typical use:
// import sys; sys.path = ['']+sys.path
// in order to be able to load modules from home directory.
extern SCM python_eval(SCM sobj,SCM smode);


// The Python call is func(*args,**kwargs)
extern SCM python_apply(SCM sfunc, SCM sarg, SCM skw,
			SCM sargtemplate, SCM skwtemplate,
			SCM srestemplate);
// sfunc can either be a function object or a list of strings, the first
// of which names a module and the others select attributes of the
// module's attributes.
// sarg is a list of values, which are to serve as positional
// arguments for the function.
// skw is a list of pairs, each pair consisting of keyword (a string)
// and a value.
// sargtemplate - specifies how to convert sarg - optional argument.
// skwtemplate - specifies how to convert skw - optional argument.
// srestemplate - specifies how to convert the result back into
//     SCM - optional argument.

#endif /* PYGUILE_H */

////////////////////////////////////////////////////////////////////////
// End of pyguile.h
