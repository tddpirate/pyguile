// pytoguile functions
// Functions for conversion from PyObjects into Guile SCMs.
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
//#include <Python.h>     // included in pytoguile.h
//#include <libguile.h>   // included in pytoguile.h
#include "pytoguile.h"
#include "pysmob.h"
#include "g2p2g_smob.h"   // used in pytoguile.inc
#include "verbose.h"
#include "pyscm.h"

////////////////////////////////////////////////////////////////////////
// Convert data from Python (PyObject *) into Guile (SCM)
// representation
////////////////////////////////////////////////////////////////////////

// The following functions convert each a single data type.
// They have to be efficient.
// The interface conventions are:
// 1. The function gets a single PyObject * argument, and upon
//    success - returns a single SCM.
// 2. The function is responsible for checking the data type of
//    and whether the value of its argument is in range.
//    If any of them fails, the function returns SCM_UNDEFINED.
// 3. If there is any error not associated with wrong data type
//    of its argument, the function throws a scm exception.
// 4. Naming convention:
//    p2g_{Python datatype name}2{Guile datatype name}


////////////////////////////////////////////////////////////////////////
// Apply a template to PyObject for converting it into a SCM
////////////////////////////////////////////////////////////////////////

SCM
p2g_apply(PyObject *pobj,SCM stemplate)
{
  if (IS_P2G_SMOBP(stemplate)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_apply: pobj=~S  smob-stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return((get_p2g_function(stemplate))(pobj,SCM_UNSPECIFIED));
  }
  else if (!SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    if (IS_P2G_SMOBP(SCM_CAR(stemplate))) {
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_apply: pobj=~S  pair-stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
      }
      return((get_p2g_function(SCM_CAR(stemplate)))(pobj,SCM_CDR(stemplate)));
    }
    else {
      scm_misc_error("p2g_apply","bad template CAR item ~S",
		     scm_list_1(SCM_CAR(stemplate)));
    }
  }
  else {
    scm_misc_error("p2g_apply","bad template item ~S",
		   scm_list_1(stemplate));
  }
}

////////////////////////// leaf ////////////////////////////////////////

// Perform 'leaf' data conversion.
// Normally, stemplate is a list of templates, to be tried one by one
// until one of them succeeds.
SCM
p2g_leaf(PyObject *pobj,SCM stemplate)
{
  if (IS_P2G_SMOBP(stemplate)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_leaf: pobj=~S  smob-stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return((get_p2g_function(stemplate))(pobj,SCM_UNSPECIFIED));
  }
  if (!SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    // Each template list item is examined.
    // If the template list item is itself a list, then its CAR is invoked
    // and gets its CDR as template, and the whole sobj (which is
    // expected to be Template or List, too) as the argument.
    // If the template list item is a P2G_SMOB, then it is invoked with
    // pobj.
    //
    // At any case, template list items are invoked one by one until
    // one of them succeeds.
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_leaf: pobj=~S  list-stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    SCM slist;
    for (slist = stemplate; (!SCM_EQ_P(slist,SCM_EOL));
	 slist = SCM_CDR(slist)) {
      SCM scandidate = SCM_CAR(slist);
      SCM sobj = p2g_apply(pobj,scandidate);
      if (!SCM_UNBNDP(sobj)) {
	if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
	  scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_leaf: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
	}
	return(sobj);
      }
    }
    return(SCM_UNDEFINED);  // None of the templates in the list fit the sobj.
    // Supports backtracking if the template is so designed.
  }
  scm_wrong_type_arg("p2g_leaf",SCM_ARG2,stemplate);  // Bad template
}

////////////////////////// None ////////////////////////////////////////

// This function is somewhat unusual in that its stemplate argument,
// if specified, does not have to be a P2G_SMOB.
// This argument is the one which is returned if the Python value
// is None.
SCM
p2g_None2SCM_EOL(PyObject *pobj,SCM stemplate)
{
  //return((Py_None != pobj)
  //	 ? SCM_UNDEFINED
  //     : (SCM_EQ_P(stemplate,SCM_UNSPECIFIED) || SCM_UNBNDP(stemplate))
  //	            ? SCM_EOL
  //	            : stemplate);
  if (Py_None != pobj) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_None2SCM_EOL: pobj=~S stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
  else {
    SCM stemp = (SCM_EQ_P(stemplate,SCM_UNSPECIFIED) || SCM_UNBNDP(stemplate))
      ? SCM_EOL : stemplate;
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_None2SCM_EOL: successful conversion of None into ~S\n"),scm_list_1(stemp));
    }
    return(stemp);
  }
}

///////////////////////// Boolean //////////////////////////////////////

SCM
p2g_Bool2SCM_BOOL(PyObject *pobj,SCM stemplate)
{
  if (PyBool_Check(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Bool2SCM_BOOL: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    return (PyInt_AsLong(pobj) ? SCM_BOOL_T : SCM_BOOL_F);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Bool2SCM_BOOL: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

///////////////////////// Numeric //////////////////////////////////////

SCM
p2g_Int2num(PyObject *pobj,SCM stemplate)
{
  if (PyInt_Check(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Int2num: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    return (scm_long2num(PyInt_AsLong(pobj)));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Int2num: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

SCM
p2g_Long2bignum(PyObject *pobj,SCM stemplate)
{
  if (PyLong_Check(pobj)) {
    PyObject *pstr = PyObject_Repr(pobj);
    if (NULL == pstr) {
      PyObject *pexception = PyErr_Occurred();    // NOT COVERED BY TESTS
      if (pexception) {  // NOT COVERED BY TESTS
	PyErr_Clear();  // NOT COVERED BY TESTS
	scm_misc_error("p2g_Long2bignum","internal conversion error of bignum",  // NOT COVERED BY TESTS
		       SCM_UNDEFINED);
      }
      else {
	scm_misc_error("p2g_Long2bignum","unknown internal conversion error of bignum",  // NOT COVERED BY TESTS
		       SCM_UNDEFINED);
      }
    }
    char *cstr = PyString_AsString(pstr);
    long cstrlen = strlen(cstr);
    if (cstrlen < 1) {
      scm_misc_error("p2g_Long2bignum","conversion error of bignum - too short result string",  // NOT COVERED BY TESTS
		     SCM_UNDEFINED);
    }
    if ('L' == cstr[cstrlen-1]) {
      --cstrlen;
    }
    //return(scm_istring2number(cstr,cstrlen,10)); // scm_istring2number seems to be deprecated in newer versions of Guile.
    SCM sstr = scm_mem2string(cstr,cstrlen);
    Py_DECREF(pstr);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      // Note: here verbosity_repr is inefficient in that it converts again
      // a PyObject into a SCM string - but it is not critical for performance
      // and code clarity is more important.
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Long2bignum: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    return(scm_string_to_number(sstr,scm_long2num((long)10)));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Long2bignum: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

SCM
p2g_Float2real(PyObject *pobj,SCM stemplate)
{
  if (PyFloat_Check(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Float2real: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    return (scm_double2num(PyFloat_AsDouble(pobj)));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Float2real: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

SCM
p2g_Complex2complex(PyObject *pobj,SCM stemplate)
{
  if (PyComplex_Check(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Complex2complex: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    double re = PyComplex_RealAsDouble(pobj);
    double im = PyComplex_ImagAsDouble(pobj);
    return(scm_make_complex(re,im));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Complex2complex: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

///////////////////////// Strings //////////////////////////////////////

SCM
p2g_String2string(PyObject *pobj,SCM stemplate)
{
  if (PyString_CheckExact(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2string: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    int strlength = PyString_Size(pobj);
    char *strtext = PyString_AsString(pobj);
    //scm_makfrom0str - duplicates zero-terminated string
    //scm_take0str - takes over ownership of the zero-terminated string
    //scm_mem2string(const char*,len)
    //scm_take_str(const char*,len)
    return(scm_mem2string(strtext,strlength));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2string: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

SCM
p2g_String2symbol(PyObject *pobj,SCM stemplate)
{
  if (PyString_CheckExact(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2symbol: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    //int strlength = PyString_Size(pobj);
    char *strtext = PyString_AsString(pobj);
    return(scm_str2symbol(strtext));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2symbol: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

SCM
p2g_String2keyword(PyObject *pobj,SCM stemplate)
{
  if (PyString_CheckExact(pobj)) {
    int strlength = PyString_Size(pobj);
    if (strlength < 1) {
      // Ensure that there is at least one character in the
      // real string.
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2keyword: failed to convert pobj=~S  using stemplate=~S - zero-length string\n"),scm_list_2(verbosity_repr(pobj),stemplate));
      }
      return(SCM_UNDEFINED);
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2keyword: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    char *strtext = PyString_AsString(pobj);
    // Prefixing dash to the string.
    char *dashstr = malloc(strlength+2);
    dashstr[0] = '-';
    dashstr[1] = '\0';
    strncat(dashstr,strtext,strlength);
    SCM ssymbol = scm_str2symbol(dashstr);
    return(scm_make_keyword_from_dash_symbol(ssymbol));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_String2keyword: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

SCM
p2g_1String2char(PyObject *pobj,SCM stemplate)
{
  if (PyString_CheckExact(pobj)) {
    int strlength = PyString_Size(pobj);
    if (1 != strlength) {
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_1String2char: failed to convert pobj=~S  using stemplate=~S - wrong-length string\n"),scm_list_2(verbosity_repr(pobj),stemplate));
      }
      return(SCM_UNDEFINED);
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_SUCCESSFUL)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_1String2char: successful conversion of ~S into SCM\n"),scm_list_1(verbosity_repr(pobj)));
    }
    char *strtext = PyString_AsString(pobj);
    return(SCM_MAKE_CHAR(strtext[0]));
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_1String2char: failed to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
}

/////////////////////// Aggregates /////////////////////////////////////

// Convert a 2-tuple into a pair.  Fails if the object is not a
// 2-tuple.  The template must be a pair as well.
SCM
p2g_2Tuple2pair(PyObject *pobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_2Tuple2pair: trying to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    scm_misc_error("p2g_2Tuple2pair","bad template item ~S",
		   scm_list_1(stemplate));
  }
  if (!PyTuple_CheckExact(pobj)) {
    return(SCM_UNDEFINED);
  }
  if (2 != PyTuple_GET_SIZE(pobj)) {
    return(SCM_UNDEFINED);
  }

  SCM sobj_car = p2g_apply(PyTuple_GET_ITEM(pobj,0),SCM_CAR(stemplate));
  if (SCM_UNBNDP(sobj_car)) {
    return(SCM_UNDEFINED);
  }
  SCM sobj_cdr = p2g_apply(PyTuple_GET_ITEM(pobj,1),SCM_CDR(stemplate));
  if (SCM_UNBNDP(sobj_cdr)) {
    return(SCM_UNDEFINED);
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_2Tuple2pair: successful conversion\n"),SCM_EOL);
  }
  return(scm_cons(sobj_car,sobj_cdr));
}

// Very similar to p2g_2Tuple2pair.
SCM
p2g_2List2pair(PyObject *pobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_2List2pair: trying to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
  }
  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    scm_misc_error("p2g_2List2pair","bad template item ~S",
		   scm_list_1(stemplate));
  }
  if (!PyList_CheckExact(pobj)) {
    return(SCM_UNDEFINED);
  }
  if (2 != PyList_GET_SIZE(pobj)) {
    return(SCM_UNDEFINED);
  }

  SCM sobj_car = p2g_apply(PyList_GET_ITEM(pobj,0),SCM_CAR(stemplate));
  if (SCM_UNBNDP(sobj_car)) {
    return(SCM_UNDEFINED);
  }
  SCM sobj_cdr = p2g_apply(PyList_GET_ITEM(pobj,1),SCM_CDR(stemplate));
  if (SCM_UNBNDP(sobj_cdr)) {
    return(SCM_UNDEFINED);
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_2List2pair: successful conversion\n"),SCM_EOL);
  }
  return(scm_cons(sobj_car,sobj_cdr));
}

// Convert a Tuple (of any length) into a list.
// The template may be either P2G_SMOB (to be used for converting
// all Tuple items) or a list of templates.
// The length of the list of templates may be shorter than the length
// of the Tuple.  If shorter, list items will be cyclically reused.
SCM
p2g_Tuple2list(PyObject *pobj,SCM stemplate)
{
  if (!PyTuple_CheckExact(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Tuple2list: pobj=~S stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
  int size = PyTuple_GET_SIZE(pobj);
  if (IS_P2G_SMOBP(stemplate)) {
    // Conversion loop for the case in which the template is
    // a single P2G_SMOB
    int ind1;
    SCM slist1 = SCM_EOL;
    for (ind1 = size-1; ind1 >= 0; --ind1) {
      PyObject *pitem1 = PyTuple_GET_ITEM(pobj, ind1);
      if (NULL == pitem1) {
	PyObject *pexception = PyErr_Occurred();    // NOT COVERED BY TESTS
	if (pexception) {     // NOT COVERED BY TESTS
	  PyErr_Clear();     // NOT COVERED BY TESTS
	}
	scm_misc_error("p2g_Tuple2list","access error of Python Tuple",    // NOT COVERED BY TESTS
		       SCM_UNSPECIFIED);
      }
      SCM sitem1 = p2g_apply(pitem1,stemplate);
      if (SCM_UNBNDP(sitem1)) {
	// Conversion failure
	return(SCM_UNDEFINED);
      }
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Tuple2list: 1. converted item pobj=~S[~S], stemplate=~S\n"),scm_list_3(scm_long2num(ind1),verbosity_repr(pitem1),stemplate));
      }
      slist1 = scm_cons(sitem1,slist1);
    }
    return(slist1);
  }

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    // Bad template.
    scm_wrong_type_arg("p2g_Tuple2list",SCM_ARG2,stemplate);
  }
  // Conversion loop for the case in which the template is a list.
  SCM slist2 = SCM_EOL;
  SCM stemp = SCM_EOL;  // We loop over stemplate again and again as needed.
  int ind2;
  for (ind2 = 0; ind2 < size;
       stemp = SCM_CDR(stemp),++ind2) {
    if (SCM_EQ_P(stemp,SCM_EOL)) {
      stemp = stemplate;  // Loop back to stemplate's beginning.
    }
    //scm_simple_format(scm_current_output_port(),scm_makfrom0str("# DEBUG: going to convert item according to template ~S\n"),scm_list_1(SCM_CAR(stemp)));
    PyObject *pitem2 = PyTuple_GET_ITEM(pobj, ind2);
    if (NULL == pitem2) {
      PyObject *pexception = PyErr_Occurred();  // NOT COVERED BY TESTS
      if (pexception) {  // NOT COVERED BY TESTS
	PyErr_Clear();  // NOT COVERED BY TESTS
      }
      scm_misc_error("p2g_Tuple2list","access error of Python Tuple",  // NOT COVERED BY TESTS
		     SCM_UNSPECIFIED);
    }
    SCM sitem2 = p2g_apply(pitem2,SCM_CAR(stemp));
    if (SCM_UNBNDP(sitem2)) {
      // Conversion failure
      return(SCM_UNDEFINED);
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Tuple2list: 2. converted item pobj=~S[~S], stemplate=~S\n"),scm_list_3(scm_long2num(ind2),verbosity_repr(pitem2),SCM_CAR(stemp)));
    }
    slist2 = scm_cons(sitem2,slist2);
  }
  return(scm_reverse(slist2));
}

// Very similar to p2g_Tuple2list above.
SCM
p2g_List2list(PyObject *pobj,SCM stemplate)
{
  if (!PyList_CheckExact(pobj)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_List2list: pobj=~S stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
    }
    return(SCM_UNDEFINED);
  }
  int size = PyList_GET_SIZE(pobj);
  if (IS_P2G_SMOBP(stemplate)) {
    // Conversion loop for the case in which the template is
    // a single P2G_SMOB
    int ind1;
    SCM slist1 = SCM_EOL;
    for (ind1 = size-1; ind1 >= 0; --ind1) {
      PyObject *pitem1 = PyList_GET_ITEM(pobj, ind1);
      if (NULL == pitem1) {
	PyObject *pexception = PyErr_Occurred();  // NOT COVERED BY TESTS
	if (pexception) {  // NOT COVERED BY TESTS
	  PyErr_Clear();  // NOT COVERED BY TESTS
	}
	scm_misc_error("p2g_List2list","access error of Python List",  // NOT COVERED BY TESTS
		       SCM_UNSPECIFIED);
      }
      SCM sitem1 = p2g_apply(pitem1,stemplate);
      if (SCM_UNBNDP(sitem1)) {
	// Conversion failure
	return(SCM_UNDEFINED);
      }
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
	scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_List2list: converted item pobj[~S]=~S, stemplate=~S\n"),scm_list_3(scm_long2num(ind1),verbosity_repr(pitem1),stemplate));
      }
      slist1 = scm_cons(sitem1,slist1);
    }
    return(slist1);
  }

  if (SCM_EQ_P(SCM_BOOL_F,scm_list_p(stemplate))) {
    // Bad template.
    scm_wrong_type_arg("p2g_List2list",SCM_ARG2,stemplate);
  }
  // Conversion loop for the case in which the template is a list.
  SCM slist2 = SCM_EOL;
  SCM stemp = SCM_EOL;  // We loop over stemplate again and again as needed.
  int ind2;
  for (ind2 = 0; ind2 < size;
       stemp = SCM_CDR(stemp),++ind2) {
    if (SCM_EQ_P(stemp,SCM_EOL)) {
      stemp = stemplate;  // Loop back to stemplate's beginning.
    }
    PyObject *pitem2 = PyList_GET_ITEM(pobj, ind2);
    if (NULL == pitem2) {
      PyObject *pexception = PyErr_Occurred();  // NOT COVERED BY TESTS
      if (pexception) {  // NOT COVERED BY TESTS
	PyErr_Clear();  // NOT COVERED BY TESTS
      }
      scm_misc_error("p2g_List2list","access error of Python List",  // NOT COVERED BY TESTS
		     SCM_UNSPECIFIED);
    }
    SCM sitem2 = p2g_apply(pitem2,SCM_CAR(stemp));
    if (SCM_UNBNDP(sitem2)) {
      // Conversion failure
      return(SCM_UNDEFINED);
    }
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_List2list: 2. converted item pobj=~S[~S], stemplate=~S\n"),scm_list_3(scm_long2num(ind2),verbosity_repr(pitem2),SCM_CAR(stemp)));
    }
    slist2 = scm_cons(sitem2,slist2);
  }
  return(scm_reverse(slist2));
}

// Conversion of Dict into alist.
// All keys are convertible using a single template (SCM_CAR(stemplate)).
//
// In the most general case, the keys will be used as keys into
// SCM_CDR(stemplate) which would be an hash table.
// However, this most general case is not currently implemented.
// There is a single template also in SCM_CDR(stemplate), which is
// used for converting all values.  Any flexibility needed is to be
// obtained through wise p2g_leaf() usage.

SCM
p2g_Dict2alist(PyObject *pobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Dict2alist: trying to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
  }

  if (SCM_EQ_P(SCM_BOOL_F,scm_pair_p(stemplate))) {
    scm_misc_error("p2g_Dict2alist","bad template ~S",
		   scm_list_1(stemplate));
  }
  //if (!IS_P2G_SMOBP(SCM_CAR(stemplate))) {
  //  scm_misc_error("p2g_Dict2alist","bad template CAR item ~S",
  //		   scm_list_1(SCM_CAR(stemplate)));
  //}
  //if (!IS_P2G_SMOBP(SCM_CDR(stemplate))) {
  //  scm_misc_error("p2g_Dict2alist","bad template CDR item ~S",
  //		   scm_list_1(SCM_CDR(stemplate)));
  //}

  if (!PyDict_CheckExact(pobj)) {
    return(SCM_UNDEFINED);
  }
  int iterstate = 0;
  PyObject *pkey = NULL;
  PyObject *pval = NULL;
  SCM salist = SCM_EOL;
  while (PyDict_Next(pobj, &iterstate, &pkey, &pval)) {
    SCM skey = p2g_apply(pkey,SCM_CAR(stemplate));
    if (SCM_UNBNDP(skey)) {
      // Conversion failure.
      return(SCM_UNDEFINED);
    }
    SCM sval = p2g_apply(pval,SCM_CDR(stemplate));
    if (SCM_UNBNDP(sval)) {
      // Conversion failure.
      return(SCM_UNDEFINED);
    }
    salist = scm_cons(scm_cons(skey,sval),salist);
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_Dict2alist: successful conversion of Dict into ~S\n"),scm_list_1(salist));
  }
  return(salist);
}

SCM
p2g_PySCMObject2SCM(PyObject *pobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# p2g_PySCMObject2SCM: trying to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
  }

  if (!PySCMObject_Check(pobj)) {
    return(SCM_UNDEFINED);
  }
  return(unwrap_pyscm_object(pobj));
}

////////////////////////////////////////////////////////////////////////
// Big default conversion function
////////////////////////////////////////////////////////////////////////
// The python2guile function chooses reasonable defaults, whenever
// there is a possibility for ambiguity concerning the desired
// Scheme datatype.
// It ignores the stemplate argument.

static SCM python2guile_smob;          // for use by default templates
static SCM python2guile_dict_default;  // used by python2guile().

SCM
python2guile(PyObject *pobj,SCM stemplate)
{
  SCM sres = SCM_UNDEFINED;
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_G2P2G_ALWAYS)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# python2guile: trying to convert pobj=~S  using stemplate=~S\n"),scm_list_2(verbosity_repr(pobj),stemplate));
  }

  if (NULL == pobj) {
    // Regarded as an error.
    scm_misc_error("python2guile","no python value to be converted",
		   SCM_UNSPECIFIED);
    //return(SCM_UNDEFINED);
  }

  sres = p2g_None2SCM_EOL(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  sres = p2g_Bool2SCM_BOOL(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  // Numeric

  sres = p2g_Int2num(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  sres = p2g_Long2bignum(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  sres = p2g_Float2real(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  sres = p2g_Complex2complex(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  // Strings

  sres = p2g_String2string(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  // Aggregates

  sres = p2g_Tuple2list(pobj,python2guile_smob);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  sres = p2g_List2list(pobj,python2guile_smob);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  sres = p2g_Dict2alist(pobj,python2guile_dict_default);
  if (!SCM_UNBNDP(sres)) return(sres);   // if (SCM_UNDEFINED != sres) return(sres);

  // PySCMObjects

  sres = p2g_PySCMObject2SCM(pobj,SCM_UNSPECIFIED);
  if (!SCM_UNBNDP(sres)) return(sres);

  // !!! Implement here hooks for decoding more data types.

  // If none of the above decoded the data type, then just
  // wrap the PyObject with pysmob and return the pysmob.
  return(wrap_pyobject(pobj));
}

////////////////////////////////////////////////////////////////////////
// Register all p2g_* functions

#include "pytoguile.inc"

////////////////////////////////////////////////////////////////////////
// End of pytoguile.c
