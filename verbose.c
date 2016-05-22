// verbosity control implementation
//
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
//
// Implements verbosity control for PyGuile C code.

#include "verbose.h"

static int pyguile_verbosity_control = 0;

////////////////////////////////////////////////////////////////////////
// SCM side
////////////////////////////////////////////////////////////////////////

SCM
pyguile_verbosity_set(SCM snewsetting)
{
  if (SCM_INUMP(snewsetting)) {
    SCM sprev_value = scm_long2num(pyguile_verbosity_control);
    pyguile_verbosity_control = (int)scm_num2long(snewsetting,0,"pyguile-verbosity-set!");
    return(sprev_value);
  }
  else {
    scm_wrong_type_arg("pyguile-verbosity-set!",SCM_ARG1,snewsetting);
  }
}

////////////////////////////////////////////////////////////////////////
// C side
////////////////////////////////////////////////////////////////////////

int
pyguile_verbosity_test(int mask)
{
  return(pyguile_verbosity_control & mask);
}

////////////////////////////////////////////////////////////////////////
// Verbosity auxiliary functions
////////////////////////////////////////////////////////////////////////

// Create a SCM string whose contents are the Python-generated repr()
// of a PyObject.
// If PyObject==NULL, return "(null PyObject)".
SCM
verbosity_repr(PyObject *pobj)
{
  if (NULL == pobj) {
    return(scm_makfrom0str("(null PyObject)"));
  }
  PyObject *pstr = PyObject_Repr(pobj);
  if (NULL == pstr) {
    PyObject *pexception = PyErr_Occurred();  // NOT COVERED BY TESTS
    if (pexception) {  // NOT COVERED BY TESTS
      PyErr_Clear();  // NOT COVERED BY TESTS
      scm_misc_error("verbosity_repr","cannot get repr of pobj",  // NOT COVERED BY TESTS
		     SCM_UNDEFINED);
    }
    else {
      scm_misc_error("verbosity_repr","unknown error during repr of pobj",  // NOT COVERED BY TESTS
		     SCM_UNDEFINED);
    }
  }
  SCM sstr = scm_makfrom0str(PyString_AsString(pstr));
  Py_DECREF(pstr);
  return(sstr);
}

////////////////////////////////////////////////////////////////////////
// End of verbose.c
