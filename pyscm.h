// pyscm header file
// Python data type for wrapping Guile SCM objects
////////////////////////////////////////////////////////////////////////

#ifndef PYSCM_H
#define PYSCM_H

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
// pyscm.PySCM
////////////////////////////////////////////////////////////////////////

PyObject *wrap_scm(SCM sobj,SCM stemplate);

// Return 0 if pobj is not of this type and/or does not wrap a SCM.
// Otherwise, return a nonzero value.
int PySCMObject_Check(PyObject *pobj);

// Unwrap a pyscm_PySCMObject instance and get from it the original
// SCM object.  If the object is not a pyscm_PySCMObject or does not
// wrap a SCM object, raise an error.
SCM unwrap_pyscm_object(PyObject *pobj);

void initpyscm(void);

////////////////////////////////////////////////////////////////////////

#endif /* PYSCM_H */

////////////////////////////////////////////////////////////////////////
// End of pyscm.h
