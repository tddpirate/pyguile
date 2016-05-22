// verbose header file
// Functions for verbosity control of PyGuile functions.
////////////////////////////////////////////////////////////////////////

#ifndef VERBOSE_H
#define VERBOSE_H

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
// Verbosity control
////////////////////////////////////////////////////////////////////////

// Function to be invoked from Scheme code.
// The previous setting is returned to the caller.
extern SCM pyguile_verbosity_set(SCM newsetting);

// Function for accessing the verbosity control from C data.
// The return value is 0 if the caller is not to print the
// requested information.
extern int pyguile_verbosity_test(int mask);

// Auxiliary function, for use in several verbosity messages.
extern SCM verbosity_repr(PyObject *pobj);

// Bitmap settings for the aforementioned mask argument.
#define PYGUILE_VERBOSE_NONE             0
#define PYGUILE_VERBOSE_G2P2G_SUCCESSFUL 1
#define PYGUILE_VERBOSE_G2P2G_ALWAYS     2  // You should use   3 =   1+2
#define PYGUILE_VERBOSE_GC               4
#define PYGUILE_VERBOSE_GC_DETAILED      8  // You should use  12 =   4+8
#define PYGUILE_VERBOSE_NEW_PYSMOB      16
#define PYGUILE_VERBOSE_UNWRAP_PYSMOB   32  // You should use  48 =  16+32
#define PYGUILE_VERBOSE_PYTHON_APPLY    64
#define PYGUILE_VERBOSE_PYSCM          128
#define PYGUILE_VERBOSE_GC_PYSCM       256

////////////////////////////////////////////////////////////////////////

#endif /* VERBOSE_H */

////////////////////////////////////////////////////////////////////////
// End of verbose.h
