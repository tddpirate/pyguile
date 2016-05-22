// guiletopy header file
// Functions for conversion from Guile SCMs into PyObjects.

#ifndef GUILETOPY_H
#define GUILETOPY_H

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
// The format of stemplate for SCM->PyObject conversions
////////////////////////////////////////////////////////////////////////
//
// The following cases are to be considered:
// -----------------------------------------
// All g2p* functions have a template argument.
// However, those which are genuine leaf conversion functions
// ignore it.
//
// 1. "Leaf" data item (such as a number or a string):
//    We want to try few g2p* functions until one succeeds.
//    The template in this case consists of 'g2p_leaf followed by
//    a list of one or more g2p* symbols.
//    It is possible for the template corresponding to a "leaf"
//    data item to consist of a single g2p* function.  In this case,
//    the function is directly applied to the data item.
// 2. Data item which is pair:
//    The template consists of list of g2p_pair2Tuple or g2p_pair2List,
//    and pair of two templates for processing the CAR and CDR of the
//    data item.  Example:
//    (list g2p_pair2Tuple
//        ((list g2p_leaf g2p_real2Float) . (list g2p_leaf g2p_num2Int)))
// 3. Data item which is a list:
//    The template data structure is a list of g2p_list2List or
//    g2p_list2Tuple followed by a list of one or more templates, which
//    are used to convert the list members.
//    It is possible for the data list to have more items than the
//    corresponding template list.  In this case, the template list
//    items are cyclically processed.
//    This way it is possible to use a single template to convert all
//    list items, if they are to be converted in the same way.
// 4. Data item which is an alist:
//    The data structure is TBD.
//    (need to consider handling of keys)
//
////////////////////////////////////////////////////////////////////////
// SCM -> PyObject
////////////////////////////////////////////////////////////////////////

// Basic conversion of a SCM object according to template.
extern PyObject *g2p_apply(SCM sobj,SCM stemplate);

// Convert a SCM object into a Python object.
// If cannot convert, abort.
extern PyObject *guile2python(SCM sobj,SCM stemplate);

// Treat the SCM object as an association list and convert it into
// Python hash, whose keys are strings corresponding to the
// association list's keys (which must be either strings or symbols).
//
// Checks:
// 1. Validity of keys.
// 2. No duplicate keys.
PyObject *guileassoc2pythondict(SCM sobj,SCM stemplate);

// Convert from Guile list into Python tuple.
// Need separate function because the default behavior is to convert
// it into Python list.
extern PyObject *g2p_list2Tuple(SCM sobj,SCM stemplate);

////////////////////////////////////////////////////////////////////////
// Extra initialization after registration of all g2p_* and p2g_*
// functions.

extern void init_default_guiletopy_templates(void);

////////////////////////////////////////////////////////////////////////

#endif /* GUILETOPY_H */

////////////////////////////////////////////////////////////////////////
// End of guiletopy.h
