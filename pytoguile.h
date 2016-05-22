// pytoguile header file
// Functions for conversion from PyObjects into Guile SCMs.
////////////////////////////////////////////////////////////////////////

#ifndef PYTOGUILE_H
#define PYTOGUILE_H

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
// PyObject -> SCM
////////////////////////////////////////////////////////////////////////

// Basic conversion of a PyObject into a SCM object according
// to template.
extern SCM p2g_apply(PyObject *pobj,SCM stemplate);

// Convert a Python object into a SCM object.
// If cannot convert, abort.
extern SCM python2guile(PyObject *pobj,SCM stemplate);

////////////////////////////////////////////////////////////////////////

#endif /* PYTOGUILE_H */

////////////////////////////////////////////////////////////////////////
// End of pytoguile.h
