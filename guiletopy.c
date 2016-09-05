// guiletopy functions
// Functions for conversion from Guile SCMs into PyObjects.
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
//#include <Python.h>     // included in guiletopy.h
//#include <libguile.h>   // included in guiletopy.h
#include "guiletopy.h"
#include "pysmob.h"
#include "g2p2g_smob.h"   // used in guiletopy.inc
#include "verbose.h"
#include "pyscm.h"

////////////////////////////////////////////////////////////////////////
//
// VERBOSITY HANDLING CONVENTIONS:
//
// PYGUILE_VERBOSE_G2P2G_SUCCESSFUL is tested whenever conversion in
// a primitive data type conversion function (g2p*) is successful.
// This condition is intended to capture all successful conversions
// of primitive values.
//
// PYGUILE_VERBOSE_G2P2G_ALWAYS is tested in all conversion failures
// and also when successfully converting aggregate data structures
// (such as Tuples, Lists and Dicts).  It is intended to provide
// detailed trace of operation of the conversion functions.
//
////////////////////////////////////////////////////////////////////////
// Convert data from Guile (SCM) representation into Python
// representation
////////////////////////////////////////////////////////////////////////

// The following functions convert each a single data type.
// They have to be efficient.
// The interface conventions are:
// 1. The function gets a single SCM argument, and upon
//    success - returns a single PyObject, which has already
//    been Py_INCREF()-ed.
// 2. The function is responsible for checking the data type of
//    and whether the value of its argument is in range.
//    If any of them fails, the function returns NULL.
//    NOTE: no error is raised with the NULL return (unlike the
//    usual convention in Python code).
// 3. If there is any error not associated with wrong data type
//    of its argument, the function throws a scm exception.
// 4. Naming convention:
//    g2p_{Guile datatype name}2{Python datatype name}
// The reason for (2),(3) above is that those functions are
// intended to be called one after one, until one of them
// succeeds in converting a data item.

//////////////////////// general template handling /////////////////////

// Apply a template to sobj.
// The template consists of pair of g2p* token and data structure
// which serves as the stemplate argument when the token's function
// is invoked.
// Alternatively, the template may consist of a single g2p* token.
// In that case, the corresponding function gets SCM_UNSPECIFIED
// as its stemplate argument.
// The invoked function is responsible for ensuring that the stemplate
// which it received is appropriate to sobj.  Inappropriateness
// means that NULL is returned, which allows g2p_leaf (see below)
// to backtrace and try another template.
PyObject *
g2p_apply(SCM sobj,SCM stemplate)
{
  PyObject *pobj;
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# Entered g2p_apply: sobj=~S  stemplate=~S\n"),scm_list_2(sobj,stemplate));
  }
  if (IS_G2P_SMOBP(stemplate)) {
    pobj = (get_g2p_function(stemplate))(sobj,SCM_UNSPECIFIED);
  }
  else if (!SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    if (IS_G2P_SMOBP(SCM_CAR(stemplate))) {
      pobj = (get_g2p_function(SCM_CAR(stemplate)))(sobj,SCM_CDR(stemplate));
    }
    else {
      scm_misc_error("g2p_apply","bad template CAR item ~S",
		     scm_list_1(SCM_CAR(stemplate)));
    }
  }
  else {
    scm_misc_error("g2p_apply","bad template item ~S",
		   scm_list_1(stemplate));
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),
		      scm_makfrom0str("# Leaving g2p_apply: with ~A result\n"),
		      scm_list_1(NULL == pobj ? scm_makfrom0str("null")
				              : scm_makfrom0str("non-null")));
  }
  return(pobj);  // is NULL if conversion failed, otherwise a new
  // reference to a PyObject (Py_INCREF has been invoked on it).
}

////////////////////////// leaf ////////////////////////////////////////

// Perform 'leaf' data conversion.
// Normally, stemplate is a list of templates, to be tried one by one
// until one of them succeeds.
PyObject *
g2p_leaf(SCM sobj,SCM stemplate)
{
  PyObject *pobj;
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# Entered g2p_leaf: sobj=~S  stemplate=~S\n"),scm_list_2(sobj,stemplate));
  }
  if (IS_G2P_SMOBP(stemplate)) {
    pobj = (get_g2p_function(stemplate))(sobj,SCM_UNSPECIFIED);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),
			scm_makfrom0str("# Leaving g2p_leaf, after G2P_SMOBP conversion, with ~A result\n"),
			scm_list_1(NULL == pobj ? scm_makfrom0str("null")
				                : scm_makfrom0str("non-null")));
    }
    return(pobj);  // Will be NULL if the conversion failed.
  }
  if (!SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    // Each template list item is examined.
    // If the template list item is itself a list, then its CAR is invoked
    // and gets its CDR as template, and the whole sobj (which is
    // expected to be a list, too) as the argument.
    // If the template list item is a G2P_SMOB, then it is invoked with
    // sobj.
    //
    // At any case, template list items are invoked one by one until
    // one of them succeeds.
    SCM slist;
    for (slist = stemplate; (!SCM_EQ_P(slist,SCM_EOL));
	 slist = SCM_CDR(slist)) {
      SCM scandidate = SCM_CAR(slist);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_leaf: trying another stemplate ~S on sobj\n"),scm_list_1(scandidate));
      }
      pobj = g2p_apply(sobj,scandidate);
      if (NULL != pobj) {
	if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	  scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_leaf: successful conversion\n"),SCM_EOL);
	}
	return(pobj);
      }
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_leaf: unsuccessful conversion, no stemplate fit the sobj\n"),SCM_EOL);
    }
    return(NULL);  // None of the templates in the list fit the sobj.
    // NULL return supports backtracking if the template is so designed.
  }
  scm_wrong_type_arg("g2p_leaf",SCM_ARG2,stemplate);  // Bad template
}

////////////////////////// null ////////////////////////////////////////

PyObject *
g2p_null2PyNone(SCM sobj,SCM stemplate)
{
  if (SCM_NULLP(sobj)) {  //(SCM_BOOL_F != scm_null_p(sobj))
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2PyNone: successful conversion of ~S into Python None\n"),scm_list_1(sobj));
    }
    Py_INCREF(Py_None);
    return(Py_None);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2PyNone: unsuccessful conversion: ~S is not null\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_null2Tuple0(SCM sobj,SCM stemplate)
{
  if (SCM_NULLP(sobj)) {  //(SCM_BOOL_F != scm_null_p(sobj))
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2Tuple0: successful conversion of ~S into Python ()\n"),scm_list_1(sobj));
    }
    PyObject *pres = PyTuple_New(0);
    if (NULL == pres) {
      scm_memory_error("g2p-null2Tuple0");  // NOT COVERED BY TESTS
    }
    return(pres);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2Tuple0: unsuccessful conversion: ~S is not null\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_null2List0(SCM sobj,SCM stemplate)
{
  if (SCM_NULLP(sobj)) {  //(SCM_BOOL_F != scm_null_p(sobj))
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2List0: successful conversion of ~S into Python []\n"),scm_list_1(sobj));
    }
    PyObject *pres = PyList_New(0);
    if (NULL == pres) {
      scm_memory_error("g2p-null2List0");  // NOT COVERED BY TESTS
    }
    return(pres);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2List0: unsuccessful conversion: ~S is not null\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_null2DictEmpty(SCM sobj,SCM stemplate)
{
  if (SCM_NULLP(sobj)) {  //(SCM_BOOL_F != scm_null_p(sobj))
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2DictEmpty: successful conversion of ~S into Python {}\n"),scm_list_1(sobj));
    }
    PyObject *pres = PyDict_New();
    if (NULL == pres) {
      scm_memory_error("g2p-null2DictEmpty");  // NOT COVERED BY TESTS
    }
    return(pres);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_null2DictEmpty: unsuccessful conversion: ~S is not null\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

// Python's None is different from Python's () or Python's []
// !!! Also, check for token such as '*none* or '*None* for
// !!! conversion into Python None instead of Python string.

///////////////////////// Numeric //////////////////////////////////////

PyObject *
g2p_bool2Bool(SCM sobj,SCM stemplate)
{
  if (SCM_BOOLP(sobj)) { //(SCM_BOOL_F != scm_boolean_p(sobj))
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_bool2Bool: successful conversion of ~S into a Python Bool value\n"),scm_list_1(sobj));
    }
    if (SCM_EQ_P(SCM_BOOL_T,sobj)) {
      Py_INCREF(Py_True);
      return(Py_True);
    }
    else {
      Py_INCREF(Py_False);
      return(Py_False);
    }
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_bool2Bool: unsuccessful conversion: ~S is not a bool value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_num2Int(SCM sobj,SCM stemplate)
{
  if (SCM_INUMP(sobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_num2Int: successful conversion of ~S into a Python Int value\n"),scm_list_1(sobj));
    }
    return(PyInt_FromLong(scm_num2long(sobj,0,"g2p_long2Int")));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_num2Int: unsuccessful conversion: ~S is not a num value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_real2Float(SCM sobj,SCM stemplate)
{
  if (SCM_INUMP(sobj) || SCM_REALP(sobj)) { //(SCM_BOOL_F != scm_real_p(sobj))
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_real2Float: successful conversion of ~S into a Python Float value\n"),scm_list_1(sobj));
    }
    return(PyFloat_FromDouble(scm_num2double(sobj,0,"g2p_real2Float")));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_real2Float: unsuccessful conversion: ~S is not a real value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_complex2Complex(SCM sobj,SCM stemplate)
{
  if (SCM_COMPLEXP(sobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_complex2Complex: successful conversion of ~S into a Python Complex value\n"),scm_list_1(sobj));
    }
    double re = SCM_COMPLEX_REAL(sobj);
    double im = SCM_COMPLEX_IMAG(sobj);
    return(PyComplex_FromDoubles(re,im));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_complex2Complex: unsuccessful conversion: ~S is not a complex value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_bignum2Long(SCM sobj,SCM stemplate)
{
  // Like schemepy, we accomplish this conversion by first
  // converting into string and then evaluating the string.
  if (SCM_BIGP(sobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_bignum2Long: successful conversion of ~S into a Python Long value\n"),scm_list_1(sobj));
    }
    SCM swrite_proc = scm_variable_ref(scm_c_lookup("write"));
    SCM sbignumstr = scm_object_to_string(sobj,swrite_proc);
    char *pstr = scm_to_locale_string(sbignumstr);
    if (NULL == pstr) {
      scm_memory_error("g2p_bignum2Long");  // NOT COVERED BY TESTS
    }

    PyObject *pres = PyInt_FromString(pstr, NULL, 10); // Will return PyLong if the value does not fit into PyInt.
    free(pstr);
    PyObject *pexception = PyErr_Occurred();
    if (pexception) {
      Py_XDECREF(pres);  // NOT COVERED BY TESTS
      PyErr_Clear();     // NOT COVERED BY TESTS
      scm_misc_error("g2p_bignum2Long","internal conversion error of bignum ~S",     // NOT COVERED BY TESTS
		     sobj);
    }
    return(pres);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_bignum2Long: unsuccessful conversion: ~S is not a bignum value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

///////////////////// Pairs and Lists //////////////////////////////////

PyObject *
g2p_pair2Tuple(SCM sobj,SCM stemplate)
{
  // We expect the template to be a pair.
  // SCM_CAR(stemplate) is used to convert SCM_CAR(sobj), and similarly
  // for SCM_CDR.
  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(sobj))) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2Tuple: unsuccessful conversion: ~S is not a pair\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    scm_misc_error("g2p_pair2Tuple","bad template ~S",
		   scm_list_1(stemplate));
  }

  // Transform it into Python tuple.
  PyObject *ppair = PyTuple_New(2);
  if (NULL == ppair) {
    scm_memory_error("g2p_pair2Tuple");  // NOT COVERED BY TESTS
  }

  // CAR
  PyObject *pitem = g2p_apply(SCM_CAR(sobj),SCM_CAR(stemplate));
  if (NULL == pitem) {
    Py_DECREF(ppair);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2Tuple: unsuccessful conversion: CAR conversion failure\n"),SCM_EOL);
    }
    return(NULL);   // Conversion failure.
  }
  if (-1 == PyTuple_SetItem(ppair, 0, pitem)) {
    Py_DECREF(ppair);  // NOT COVERED BY TESTS
    // Py_DECREF(pitem); // already performed by PyTuple_SetItem
    scm_misc_error("g2p_pair2Tuple","PyTuple_SetItem car failure (~S)",  // NOT COVERED BY TESTS
		   scm_list_1(SCM_CAR(sobj)));
  }

  // CDR
  pitem = g2p_apply(SCM_CDR(sobj),SCM_CDR(stemplate));
  if (NULL == pitem) {
    Py_DECREF(ppair);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2Tuple: unsuccessful conversion: CDR conversion failure\n"),SCM_EOL);
    }
    return(NULL);  // Conversion failure.
  }
  if (-1 == PyTuple_SetItem(ppair, 1, pitem)) {
    Py_DECREF(ppair);  // NOT COVERED BY TESTS
    // Py_DECREF(pitem); // already performed by PyTuple_SetItem
    scm_misc_error("g2p_pair2Tuple","PyTuple_SetItem cdr failure (~S)",  // NOT COVERED BY TESTS
		   scm_list_1(SCM_CDR(sobj)));
  }

  // Done
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2Tuple: successful conversion of ~S into a Python 2-Tuple\n"),scm_list_1(sobj));
  }
  return(ppair);
}

// Very similar to g2p_pair2Tuple() above.
PyObject *
g2p_pair2List(SCM sobj,SCM stemplate)
{
  // We expect the template to be a pair.
  // SCM_CAR(stemplate) is used to convert SCM_CAR(sobj), and similarly
  // for SCM_CDR.
  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(sobj))) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2List: unsuccessful conversion: ~S is not a pair\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    scm_misc_error("g2p_pair2List","bad template ~S",
		   scm_list_1(stemplate));
  }

  // Transform it into Python tuple.
  PyObject *ppair = PyList_New(2);
  if (NULL == ppair) {
    scm_memory_error("g2p_pair2List");  // NOT COVERED BY TESTS
  }

  // CAR
  PyObject *pitem = g2p_apply(SCM_CAR(sobj),SCM_CAR(stemplate));
  if (NULL == pitem) {
    Py_DECREF(ppair);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2List: unsuccessful conversion: CAR conversion failure\n"),SCM_EOL);
    }
    return(NULL);
  }
  if (-1 == PyList_SetItem(ppair, 0, pitem)) {
    Py_DECREF(ppair);    // NOT COVERED BY TESTS
    // Py_DECREF(pitem); // already performed by PyList_SetItem
    scm_misc_error("g2p_pair2List","PyList_SetItem car failure (~S)",  // NOT COVERED BY TESTS
		   scm_list_1(SCM_CAR(sobj)));
  }

  // CDR
  pitem = g2p_apply(SCM_CDR(sobj),SCM_CDR(stemplate));
  if (NULL == pitem) {
    Py_DECREF(ppair);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2List: unsuccessful conversion: CDR conversion failure\n"),SCM_EOL);
    }
    return(NULL);
  }
  if (-1 == PyList_SetItem(ppair, 1, pitem)) {
    Py_DECREF(ppair);  // NOT COVERED BY TESTS
    // Py_DECREF(pitem); // already performed by PyList_SetItem
    scm_misc_error("g2p_pair2List","PyList_SetItem cdr failure (~S)",  // NOT COVERED BY TESTS
		   scm_list_1(SCM_CDR(sobj)));
  }

  // Done
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_pair2List: successful conversion of ~S into a Python 2-List\n"),scm_list_1(sobj));
  }
  return(ppair);
}

PyObject *
g2p_list2Tuple(SCM sobj,SCM stemplate)
{
  // sobj is expected to be a list.

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(sobj))) {
    // sobj is not a list, so this is the wrong conversion function for it.
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2Tuple: unsuccessful conversion: ~S is not a list\n"),scm_list_1(sobj));
    }
    return(NULL);
  }

  // The template may be either a G2P_SMOB (to be used for converting
  // all list items) or a list of templates.
  long listlen = scm_num2long(scm_length(sobj),0,"g2p_list2Tuple");
  PyObject *plist = PyTuple_New(listlen);
  if (NULL == plist) {
    scm_memory_error("g2p_list2Tuple");  // NOT COVERED BY TESTS
  }

  // Conversion loop for the case in which the template is a single G2P_SMOB
  if (IS_G2P_SMOBP(stemplate)) {
    long ind1;
    for (ind1 = 0; ind1 < listlen; sobj = SCM_CDR(sobj),++ind1) {
      SCM sitem = SCM_CAR(sobj);
      PyObject *pobj1 = g2p_apply(sitem,stemplate);
      if (NULL == pobj1) {
	Py_DECREF(plist);
	if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	  scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2Tuple: unsuccessful conversion of element ~A: ~S does not match template\n"),scm_list_2(scm_long2num(ind1),sitem));
	}
	return(NULL);  // Conversion failure.
      }
      if (-1 == PyTuple_SetItem(plist, ind1, pobj1)) {
	Py_DECREF(plist);  // NOT COVERED BY TESTS
	//Py_DECREF(pobj1);
	scm_misc_error("g2p_list2Tuple","PyTuple_SetItem ~S failure (~S)",  // NOT COVERED BY TESTS
		       scm_list_2(scm_long2num(ind1),sitem));
      }
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2Tuple: successful conversion of list ~S\n"),scm_list_1(sobj));
    }
    return(plist);
  }

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    // Bad template.
    scm_wrong_type_arg("g2p_list2Tuple",SCM_ARG2,stemplate);
  }

  // Conversion loop for the case in which the template is a list.
  long ind2;
  SCM stemp = SCM_EOL; // We loop over stemplate again and again as needed.
  for (ind2 = 0; ind2 < listlen;
       sobj = SCM_CDR(sobj), stemp=SCM_CDR(stemp), ++ind2) {
    if (SCM_EQ_P(stemp,SCM_EOL)) {
      stemp = stemplate;  // Loop back to stemplate's beginning.
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2Tuple - processing item CAR(sobj)=~S  CAR(stemp)=~S\n"),scm_list_2(SCM_CAR(sobj),SCM_CAR(stemp)));
    }
    PyObject *pobj2 = g2p_apply(SCM_CAR(sobj),SCM_CAR(stemp));
    if (NULL == pobj2) {
      Py_DECREF(plist);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2Tuple: unsuccessful conversion of element ~A: ~S does not match personalized template\n"),scm_list_2(scm_long2num(ind2),SCM_CAR(sobj)));
      }
      return(NULL);  // Conversion failure.
    }
    if (-1 == PyTuple_SetItem(plist, ind2, pobj2)) {
      Py_DECREF(plist);  // NOT COVERED BY TESTS
      //Py_DECREF(pobj2);
      scm_misc_error("g2p_list2Tuple","PyTuple_SetItem ~S failure (~S)",  // NOT COVERED BY TESTS
		     scm_list_2(scm_long2num(ind2),SCM_CAR(stemp)));
    }
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2Tuple: successful conversion of list ~S by template\n"),scm_list_1(sobj));
  }
  return(plist);
}

// Very similar to g2p_list2Tuple() above.
PyObject *
g2p_list2List(SCM sobj,SCM stemplate)
{
  // sobj is expected to be a list.

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(sobj))) {
    // sobj is not a list, so this is the wrong conversion function for it.
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2List: unsuccessful conversion: ~S is not a list\n"),scm_list_1(sobj));
    }
    return(NULL);
  }

  // The template may be either a G2P_SMOB (to be used for converting
  // all list items) or a list of templates.
  long listlen = scm_num2long(scm_length(sobj),0,"g2p_list2List");
  PyObject *plist = PyList_New(listlen);
  if (NULL == plist) {
    scm_memory_error("g2p_list2List");  // NOT COVERED BY TESTS
  }

  // Conversion loop for the case in which the template is a single G2P_SMOB
  if (IS_G2P_SMOBP(stemplate)) {
    long ind1;
    for (ind1 = 0; ind1 < listlen; sobj = SCM_CDR(sobj),++ind1) {
      SCM sitem = SCM_CAR(sobj);
      PyObject *pobj1 = g2p_apply(sitem,stemplate);
      if (NULL == pobj1) {
	Py_DECREF(plist);
	if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	  scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2List: unsuccessful conversion of element ~A: ~S does not match template\n"),scm_list_2(scm_long2num(ind1),sitem));
	}
	return(NULL);  // Conversion failure.
      }
      if (-1 == PyList_SetItem(plist, ind1, pobj1)) {
	Py_DECREF(plist);  // NOT COVERED BY TESTS
	//Py_DECREF(pobj1);
	scm_misc_error("g2p_list2List","PyList_SetItem ~S failure (~S)",  // NOT COVERED BY TESTS
		       scm_list_2(scm_long2num(ind1),sitem));
      }
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2List: successful conversion of list ~S\n"),scm_list_1(sobj));
    }
    return(plist);
  }

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    // Bad template.
    scm_wrong_type_arg("g2p_list2List",SCM_ARG2,stemplate);
  }

  // Conversion loop for the case in which the template is a list.
  long ind2;
  SCM stemp = SCM_EOL; // We loop over stemplate again and again as needed.
  for (ind2 = 0; ind2 < listlen;
       sobj = SCM_CDR(sobj), stemp=SCM_CDR(stemp), ++ind2) {
    if (SCM_EQ_P(stemp,SCM_EOL)) {
      stemp = stemplate;  // Loop back to stemplate's beginning.
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# DEBUG: g2p_list2List - processing item CAR(sobj)=~S  CAR(stemp)=~S\n"),scm_list_2(SCM_CAR(sobj),SCM_CAR(stemp)));
    }
    PyObject *pobj2 = g2p_apply(SCM_CAR(sobj),SCM_CAR(stemp));
    if (NULL == pobj2) {
      Py_DECREF(plist);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2List: unsuccessful conversion of element ~A: ~S does not match personalized template\n"),scm_list_2(scm_long2num(ind2),SCM_CAR(sobj)));
      }
      return(NULL);  // Conversion failure
    }
    if (-1 == PyList_SetItem(plist, ind2, pobj2)) {
      Py_DECREF(plist);  // NOT COVERED BY TESTS
      //Py_DECREF(pobj2);
      scm_misc_error("g2p_list2List","PyList_SetItem ~S failure (~S)",  // NOT COVERED BY TESTS
		     scm_list_2(scm_long2num(ind2),SCM_CAR(stemp)));
    }
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_list2List: successful conversion of list ~S by template\n"),scm_list_1(sobj));
  }
  return(plist);
}

///////////////////////// strings and symbols //////////////////////////

PyObject *
g2p_char2String(SCM sobj,SCM stemplate)
{
  if (SCM_CHARP(sobj)) {
    return(PyString_FromFormat("%c",(int) SCM_CHAR(sobj)));
  }
  else {
    return(NULL);
  }
}

PyObject *
g2p_string2String(SCM sobj,SCM stemplate)
{
  if (SCM_STRINGP(sobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_string2String: successful conversion of ~S into a Python String value\n"),scm_list_1(sobj));
    }
    PyObject *pstr = PyString_FromStringAndSize(scm_to_locale_string(sobj),SCM_STRING_LENGTH(sobj));
    if (NULL == pstr) {
      scm_memory_error("g2p_string2String");  // NOT COVERED BY TESTS
    }
    return(pstr);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_string2String: unsuccessful conversion: ~S is not a string value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

// Guile is case-sensitive by default, so we don't have to
// ensure that symbols always lowercase their characters.
PyObject *
g2p_symbol2String(SCM sobj,SCM stemplate)
{
  if (SCM_SYMBOLP(sobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_symbol2String: successful conversion of ~S into a Python String value\n"),scm_list_1(sobj));
    }
    PyObject *pstr = PyString_FromStringAndSize(SCM_SYMBOL_CHARS(sobj),SCM_SYMBOL_LENGTH(sobj));
    if (NULL == pstr) {
      scm_memory_error("g2p_symbol2String");  // NOT COVERED BY TESTS
    }
    return(pstr);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_symbol2String: unsuccessful conversion: ~S is not a symbol value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

PyObject *
g2p_keyword2String(SCM sobj,SCM stemplate)
{
  if (SCM_KEYWORDP(sobj)) { //(SCM_BOOL_F != scm_keyword_p(sobj))
    SCM symb = scm_keyword_dash_symbol(sobj);
    // We want to remove the leading '-' from the keyword, so that
    // it can be used in keyword function arguments in a natural way.
    const char *symchars = SCM_SYMBOL_CHARS(symb);
    int symlength = SCM_SYMBOL_LENGTH(symb);
    if (symlength < 1) {
      scm_out_of_range("g2p_keyword2String",sobj);  // NOT COVERED BY TESTS
      // The symbol is too short to have dash.
      // We allow symbols like '#:', which are converted here into empty
      // strings.  Guile does not accept them for version 1.8.x and later,
      // but this does not matter here.
    }
    PyObject *pstr = PyString_FromStringAndSize(symchars+1,symlength-1);
    if (NULL == pstr) {
      scm_memory_error("g2p_keyword2String");  // NOT COVERED BY TESTS
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_keyword2String: successful conversion of ~S into a Python String value\n"),scm_list_1(sobj));
    }
    return(pstr);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_keyword2String: unsuccessful conversion: ~S is not a keyword value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}

///////////////////////// opaque datatypes /////////////////////////////

// scm_procedure_p
// scm_procedure_with_setter_p - not implemented yet.

// Reasonable default template for procedure objects
static SCM g2p_procedure2PySCMObject_template_default;
// The above variable is to be assigned the value:
// scm_permanent_object(scm_vector(scm_list_5(...)))
// where the arguments of scm_list_5() are:
//   scm_variable_ref(scm_c_lookup("python2guile"))
//   scm_variable_ref(scm_c_lookup("python2guile"))
//   guile2python_smob
//   scm_variable_ref(scm_c_lookup("apply"))
//   SCM_BOOL_F
//
// To clone the above and set other templates, use
// Scheme procedure: (set! cloned (copy-tree obj))
// and C function: SCM scopy = scm_copy_tree(SCM sobj)

PyObject *
g2p_procedure2PySCMObject(SCM sobj,SCM stemplate)
{
  if (SCM_EQ_P(stemplate,SCM_UNSPECIFIED)) {
    stemplate = g2p_procedure2PySCMObject_template_default;
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_vector_p(stemplate))) {
    // Bad template
    scm_wrong_type_arg("g2p_procedure2PySCMObject",SCM_ARG2,stemplate);
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_procedure_p(sobj))) {
    // Not a procedure
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_procedure2PySCMObject: unsuccessful conversion: ~S is not a procedure\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
  PyObject *pobj = wrap_scm(sobj,stemplate);
  if (NULL != pobj) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_procedure2PySCMObject: successful conversion: ~S has been wrapped\n"),scm_list_1(sobj));
    }
  }
  return(pobj);
}


PyObject *
g2p_opaque2Object(SCM sobj,SCM stemplate)
{
  if (IS_PYSMOBP(sobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_opaque2Object: the Python object inside opaque pysmob ~S is unwrapped\n"),scm_list_1(sobj));
    }
    PyObject *pobj = unwrap_pysmob(sobj);
    Py_INCREF(pobj);
    return(pobj);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_opaque2Object: unsuccessful conversion: ~S is not an opaque pysmob value\n"),scm_list_1(sobj));
    }
    return(NULL);
  }
}


////////////////////////////////////////////////////////////////////////
// Big default conversion function
////////////////////////////////////////////////////////////////////////
// The guile2python function chooses reasonable defaults, whenever
// there is a possibility for ambiguity concerning the desired
// Python datatype.

static SCM guile2python_smob;   // Used when we need it as hash default value.
static SCM guile2python_template_default;  // used by guile2python().
static SCM guile2python_pair_template_default;  // used by guile2python().
static SCM guileassoc2pythondict_default;  // used by guileassoc2pythondict.
                                        // It is set to an empty hash table.
static SCM g2p_alist_template_default;     // used by g2p_alist2Dict.

// This function does Py_INCREF() to its return values.
PyObject *
guile2python(SCM sobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# guile2python: entry: seeking to convert sobj=~S; unused stemplate=~S\n"),scm_list_2(sobj,stemplate));
  }
  PyObject *pres = NULL;

  //////////// Scheme sequences

  // SCM '() is converted into Python None.
  pres = g2p_null2PyNone(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  // We check lists before pairs because every list in Scheme is
  // also a pair.
  //printf("# DEBUG: guile2python, before 1st call to g2p_list2List\n");
  pres = g2p_list2List(sobj,guile2python_template_default);
  if (NULL != pres) return(pres);

  pres = g2p_pair2Tuple(sobj,guile2python_pair_template_default);
  if (NULL != pres) return(pres);

  //////////// Scheme numbers

  pres = g2p_bool2Bool(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_num2Int(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_bignum2Long(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_real2Float(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);
  // NOTE: in Guile 1.6, rational numbers and real numbers are
  //       internally represented the same way.

  pres = g2p_complex2Complex(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  //////////// Scheme strings

  pres = g2p_char2String(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_string2String(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_symbol2String(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_keyword2String(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  //////////// Other Scheme data types

  pres = g2p_procedure2PySCMObject(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  pres = g2p_opaque2Object(sobj,SCM_UNSPECIFIED);
  if (NULL != pres) return(pres);

  // !!! More simple data types: regexp
  // !!! To wrap: procedures, macros(opaque), variables,
  // !!!          opaque:  asyncs, dynamic roots, fluids, hooks, ports

  // !!! Scheme objects

  // !!! More complex data types: vectors,records,structures,arrays,


  else {
    scm_wrong_type_arg("guile2python",SCM_ARG1,sobj);
  }
}

////////////////////////////////////////////////////////////////////////
// Quick conversion from alist into Dict
////////////////////////////////////////////////////////////////////////
// Treat the SCM object as an association list and convert it into
// Python hash, whose keys are strings corresponding to the
// association list's keys (which must be keywords).
//
// This version is meant for quick conversion of keyword arguments,
// and it allows only keywords as keys.
//
// Checks:
// 1. Validity of keys.
// 2. No duplicate keys.
//
// The stemplate argument must be an hash table (keys are checked
// using eq?).

PyObject *
guileassoc2pythondict(SCM sobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# guileassoc2pythondict: entry: seeking to convert sobj=~S using stemplate=~S\n"),scm_list_2(sobj,stemplate));
  }

  if (SCM_UNBNDP(stemplate)) {
    stemplate = guileassoc2pythondict_default;
  }
  PyObject *pdict = NULL;
  PyObject *pkey = NULL;
  PyObject *pval = NULL;

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(sobj))) {
    scm_wrong_type_arg("guileassoc2pythondict",SCM_ARG1,sobj);
  }
  // TODO: add here a call to SCM_HASHP(stemplate) to validate that the
  // template is hashtable.

  long listlen = scm_num2long(scm_length(sobj),0,"guileassoc2pythondict");
  pdict = PyDict_New();
  if (NULL == pdict) {
    scm_memory_error("guileassoc2pythondict");  // NOT COVERED BY TESTS
  }
  long ind;
  for (ind = 0,pkey = NULL,pval = NULL; ind < listlen; ++ind) {
    SCM spair = SCM_CAR(sobj);
    if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(spair))) {
      // Not a pair.
      Py_DECREF(pdict);
      scm_wrong_type_arg("guileassoc2pythondict",ind+1,spair);
    }

    pkey = g2p_keyword2String(SCM_CAR(spair),SCM_UNSPECIFIED);
    if (NULL == pkey) {
      // Illegal key - it must be a keyword.
      scm_wrong_type_arg("guileassoc2pythondict",ind+1,SCM_CAR(spair));
    }
    if (0 != PyDict_Contains(pdict,pkey)) {
      // Duplicate key or some error
      Py_DECREF(pdict);
      Py_DECREF(pkey);
      scm_misc_error("guileassoc2pythondict","duplicate key (~S)",
		     scm_list_1(SCM_CAR(spair)));
    }

    SCM sitem_template = scm_hashq_ref(stemplate,SCM_CAR(spair),guile2python_smob);
    pval = g2p_apply(SCM_CDR(spair),sitem_template);
    if (NULL == pval) {
      Py_DECREF(pdict);
      Py_DECREF(pkey);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# guileassoc2pythondict: unsuccessful conversion of element ~A: ~S does not match template\n"),scm_list_2(SCM_CAR(spair),SCM_CDR(spair)));
      }
      return(NULL);     // Conversion failure.
    }

    if (-1 == PyDict_SetItem(pdict,pkey,pval)) {
      Py_XDECREF(pdict);  // NOT COVERED BY TESTS
      //Py_XDECREF(pkey);
      //Py_XDECREF(pval);
      scm_misc_error("guileassoc2pythondict","PyDict_SetItem failure (~S : ~S)",  // NOT COVERED BY TESTS
		     scm_list_2(SCM_CAR(spair),SCM_CDR(spair)));
    }
    sobj = SCM_CDR(sobj);
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# guileassoc2pythondict: successful conversion of ~S\n"),scm_list_1(sobj));
  }
  return(pdict);
}

////////////////////////////////////////////////////////////////////////
// Generalized conversion from alist into Dict
////////////////////////////////////////////////////////////////////////
// The following function is meant for conversion of alists into
// general Python Dicts.
// It allows any immutable object as key.
// NOTE: no check for immutability is made here!
//
// The stemplate argument must be a list of pairs (i.e. structured
// like an alist).

PyObject *
g2p_alist2Dict(SCM sobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict sobj=~S  stemplate=~S\n"),scm_list_2(sobj,stemplate));
  }
  if (SCM_UNBNDP(stemplate) || SCM_EQ_P(stemplate,SCM_EOL)) {
    stemplate = g2p_alist_template_default;
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict - default template was chosen: ~S\n"),scm_list_1(stemplate));
    }
  }

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(sobj))) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict: unsuccessful conversion: argument is not list, let alone alist\n"),SCM_EOL);
    }
    return(NULL);   // Conversion failure.
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    scm_wrong_type_arg("g2p_alist2Dict",SCM_ARG2,sobj);  // Bad template.
  }

  long listlen = scm_num2long(scm_length(sobj),0,"g2p_alist2Dict");
  PyObject *pdict = PyDict_New();
  if (NULL == pdict) {
    scm_memory_error("g2p_alist2Dict");  // NOT COVERED BY TESTS
  }

  long ind;
  SCM stemp = SCM_EOL; // We loop over stemplate again and again as needed.
  for (ind = 0; ind < listlen;
       sobj = SCM_CDR(sobj),stemp=SCM_CDR(stemp), ++ind) {
    if (SCM_EQ_P(stemp,SCM_EOL)) {
      stemp = stemplate;  // Loop back to stemplate's beginning.
    }

    if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(SCM_CAR(stemp)))) {
      // Not a template pair - bad template.
      Py_DECREF(pdict);
      scm_wrong_type_arg("g2p_alist2Dict",SCM_ARG2,SCM_CAR(stemp));
    }
    SCM spair = SCM_CAR(sobj);
    if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(spair))) {
      // Not a data pair - conversion failure.
      Py_DECREF(pdict);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict: unsuccessful conversion: alist item is not pair: ~S\n"),scm_list_1(spair));
      }
      return(NULL);
    }

    PyObject *pkey = g2p_apply(SCM_CAR(spair),SCM_CAAR(stemp));
    if (NULL == pkey) {
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict: unsuccessful conversion: key ~S, template ~S\n"),scm_list_2(SCM_CAR(spair),SCM_CAAR(stemp)));
      }
      return(NULL);      // Conversion failure.
    }
    if (0 != PyDict_Contains(pdict,pkey)) {
      // Duplicate key or some error.
      Py_DECREF(pdict);
      Py_DECREF(pkey);
      scm_misc_error("g2p_alist2Dict","duplicate key (~S)",
		     scm_list_1(SCM_CAR(spair)));
    }

    PyObject *pval = g2p_apply(SCM_CDR(spair),SCM_CDAR(stemp));
    if (NULL == pval) {
      Py_DECREF(pdict);
      Py_DECREF(pkey);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict: unsuccessful conversion: value ~S, template ~S\n"),scm_list_2(SCM_CDR(spair),SCM_CDAR(stemp)));
      }
      return(NULL);     // Conversion failure.
    }

    if (-1 == PyDict_SetItem(pdict,pkey,pval)) {
      Py_XDECREF(pdict);  // NOT COVERED BY TESTS
      //Py_XDECREF(pkey);
      //Py_XDECREF(pval);
      scm_misc_error("g2p_alist2Dict","PyDict_SetItem failure (~S : ~S)",  // NOT COVERED BY TESTS
		     scm_list_2(SCM_CAR(spair),SCM_CDR(spair)));
    }
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# g2p_alist2Dict: successful conversion\n"),SCM_EOL);
  }
  return(pdict);
}

// NOTE:
// After all, we'll not support hash tables.
// This is because I found no function to identify an hash table.
// Hash table can be converted into alist using:
// (hash-fold acons '() hashtable)

////////////////////////////////////////////////////////////////////////
// Register all g2p_* functions

#include "guiletopy.inc"

// The following must happen after registration of all g2p_* and p2g_*
// functions.
void
init_default_guiletopy_templates(void)
{
  SCM s_python2guile = scm_variable_ref(scm_c_lookup("python2guile"));
  g2p_procedure2PySCMObject_template_default
    = scm_permanent_object(scm_vector(scm_list_5(
	s_python2guile,
	s_python2guile,
	guile2python_smob,
	scm_variable_ref(scm_c_lookup("apply")),
	SCM_BOOL_F)));
  scm_c_define("pyscm-default-template",g2p_procedure2PySCMObject_template_default);
}

////////////////////////////////////////////////////////////////////////
// End of guiletopy.c
