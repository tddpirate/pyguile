// pysmob header file
//
////////////////////////////////////////////////////////////////////////

#ifndef PYSMOB_H
#define PYSMOB_H

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
// Declares the Guile SMOB type, which encapsulates Python objects.
// While those SMOBs can be used to encapsulate any PyObject* object,
// they are typically used to encapsulate only class instances.

#include <Python.h>   // Must be first header file
#include <libguile.h>

// Return nonzero if sobj is of type pysmob.
int IS_PYSMOBP(SCM sobj);

void init_pysmob_type(void);
// Naming convention: don't start names with "py", but use them
// if they are not the first characters of a name.

SCM wrap_pyobject(PyObject *pobj);
// Create a pysmob corresponding to a PyObject.

PyObject *unwrap_pysmob(SCM sobj);
// Provide reference to PyObject embedded in a pysmob.
// No ownership transfer is implied.

#endif /* PYSMOB_H */
////////////////////////////////////////////////////////////////////////
// End of pysmob.h
