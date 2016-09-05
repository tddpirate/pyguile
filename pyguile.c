// pyguile functions
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

//#include <Python.h>     // included in pyguile.h
//#include <libguile.h>   // included in pyguile.h
#include "pyguile.h"
#include "pytoguile.h"
#include "guiletopy.h"
#include "pysmob.h"
#include "g2p2g_smob.h"
#include "verbose.h"
#include "pyscm.h"
#include "version.h"

////////////////////////////////////////////////////////////////////////
// Invoke Python function
////////////////////////////////////////////////////////////////////////

// !!! TODO:
// Problems:
// 1. There is a general problem that exceptions seem not to be properly
//    harvested!


static SCM sargtemplate_default;
static SCM skwtemplate_default;
static SCM srestemplate_default;

// python_apply implements the function call:
// (python-apply ("module.submodule" 'obj 'func)
//               (arg1 arg2 arg3)
//               (('keyword1 . val4) ('keyword2 . val5))
//               sargtemplate
//               skwtemplate)
// which is the basic way to invoke a Python function.
//
// sfunc specifies the function to be invoked.  The possibilities
// are:
//   String - denotes a top level function ("func" means __main__.func).
//   pysmob - assumed to be a callable object.
//   ("module.submodule" ...) - a List of strings/symbols/keywords
//     in which the first item must be a string denotes:
//     Module "module.submodule" (which should have already been imported
//       using python-import)
//     followed by name of object in that module, followed by attribute,...,
//     until the final callable attribute.
//   (pysmob ...) - a List starting with pysmob followed by
//     strings/symbols/keywords - processed similarly, except that the
//     pysmob stands for the module.
// sarg is a list of arguments (in Python it's *arg)
// skw is an alist (in Python it's **kw).
// sargtemplate - specifies how to convert sarg - optional argument.
// skwtemplate - specifies how to convert skw - optional argument.
// srestemplate - specifies how to convert the result back into
//     SCM - optional argument.
SCM
python_apply(SCM sfunc, SCM sarg, SCM skw,
	     SCM sargtemplate, SCM skwtemplate,	SCM srestemplate)
{
  PyObject *pfunc = NULL;
  PyObject *parg = NULL;
  PyObject *pkw = NULL;

  PyObject *pfuncobj = NULL;
  PyObject *pres = NULL;
  SCM sres = SCM_UNDEFINED;

  if (SCM_UNBNDP(sargtemplate)) { //(sargtemplate == SCM_UNDEFINED) // SCM_UNSPECIFIED
    sargtemplate = sargtemplate_default;
  }
  if (SCM_UNBNDP(skwtemplate)) {
    skwtemplate = skwtemplate_default;
  }
  if (SCM_UNBNDP(srestemplate)) {
    srestemplate = srestemplate_default;
  }

  // Retrieve the function object.

  pfunc = guile2python(sfunc,SCM_UNSPECIFIED);
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYTHON_APPLY)) {
    char *preprfunc = PyString_AsString(PyObject_Repr(pfunc));
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# python_apply: decoded pfunc ~S\n"),scm_list_1(scm_makfrom0str(preprfunc)));
  }
  if (NULL == pfunc) {
    scm_misc_error("python-apply","conversion failure (~S)",
		   scm_list_1(SCM_CDR(sfunc)));
  }
  // If it is a string, prepend it with "__main__".
  if (PyString_CheckExact(pfunc)) {
    // Convert it into a List of two items, to unify
    // subsequent treatment.
    PyObject *plist = PyList_New(2);
    if (NULL == plist) {
      Py_DECREF(pfunc);  // NOT COVERED BY TESTS
      scm_memory_error("python-apply");  // NOT COVERED BY TESTS
    }
    if (-1 == PyList_SetItem(plist,0,PyString_FromString("__main__"))) {
      Py_DECREF(pfunc);  // NOT COVERED BY TESTS
      Py_DECREF(plist);  // NOT COVERED BY TESTS
      scm_misc_error("python-apply","PyList_SetItem 0 failure (~S)",  // NOT COVERED BY TESTS
		     scm_list_1(SCM_CAR(sfunc)));
    }
    if (-1 == PyList_SetItem(plist,1,pfunc)) {
      Py_DECREF(pfunc);  // NOT COVERED BY TESTS
      Py_DECREF(plist);  // NOT COVERED BY TESTS
      scm_misc_error("python-apply","PyList_SetItem 1 failure (~S)",  // NOT COVERED BY TESTS
		     scm_list_1(SCM_CAR(sfunc)));
    }
    pfunc = plist;  // plist stole previous pfunc's value's reference.
  }
  else if (IS_PYSMOBP(sfunc)) {
    // We check the SCM object because guile2python() destroys
    // the indication whether the SCM was originally a pysmob, when it
    // converts it into PyObject.
    PyObject *plist1 = PyList_New(1);
    if (NULL == plist1) {
      Py_DECREF(pfunc);  // NOT COVERED BY TESTS
      scm_memory_error("python-apply");  // NOT COVERED BY TESTS
    }
    if (-1 == PyList_SetItem(plist1,0,pfunc)) {
      Py_DECREF(pfunc);  // NOT COVERED BY TESTS
      Py_DECREF(plist1);  // NOT COVERED BY TESTS
      scm_misc_error("python-apply","PyList_SetItem 0 failure (~S)",  // NOT COVERED BY TESTS
		     scm_list_1(SCM_CAR(sfunc)));
    }
    pfunc = plist1;  // plist1 stole previous pfunc's value's reference.
    // Now pfunc is an 1-member list, and this member is
    // expected to be callable.
  }
  else if (!PyList_CheckExact(pfunc)) {
    // Now, the qualified function name must be a proper list.
    scm_wrong_type_arg("python-apply",SCM_ARG1,sfunc);
  }

  if (1 > PyList_Size(pfunc)) {
    // The list must consist of at least one callable module name/object.
    scm_misc_error("python-apply",
		   "first argument must contain at least one callable object (~S)",
		   scm_list_1(SCM_CAR(sfunc)));
  }

  if (PyString_CheckExact(PyList_GetItem(pfunc,0))) {
    // If it is a string, we assume it to be the name of a module
    // which has already been imported.
    // Due to the existence of dots, 
    // we don't allow it to be symbol or keyword.

    pfuncobj = PyImport_AddModule(PyString_AsString(PyList_GetItem(pfunc,0)));
    if (NULL == pfuncobj) {
      Py_DECREF(pfunc);
      scm_misc_error("python-apply",
		     "module ~S could not be accessed - probably not imported",
		     scm_list_1(SCM_CAR(sfunc)));
    }
    Py_INCREF(pfuncobj);
  }
  else {
    // We assume that it is a callable or object with attributes.
    pfuncobj = PyList_GetItem(pfunc,0);
    if (NULL == pfuncobj) {
      Py_DECREF(pfunc);
      scm_misc_error("python-apply",
		     "could not access object starting ~S",
		     scm_list_1(sfunc));
    }
    Py_INCREF(pfuncobj);
  }

  // Here we dereference attributes (if any).
  int listsize = PyList_Size(pfunc);
  int ind;

  for (ind = 1; ind < listsize; ++ind) {
    PyObject *pnextobj = PyObject_GetAttr(pfuncobj,PyList_GetItem(pfunc,ind));
    if (NULL == pnextobj) {
      PyObject *pexception = PyErr_Occurred();
      Py_DECREF(pfunc);
      Py_DECREF(pfuncobj);
      if (pexception) {
	PyErr_Clear();
	// An AttributeError exception is expected here.
	if (!PyErr_GivenExceptionMatches(pexception,PyExc_AttributeError)) {
	  PyObject *prepr = PyObject_Repr(pexception);
	  if (NULL == prepr) {
	    scm_misc_error("python-apply",
			   "python exception - could not be identified",
			   SCM_UNSPECIFIED);
	  }
	  else {
	    int strlength = PyString_Size(prepr);
	    char *pstr = PyString_AsString(prepr);
	    SCM srepr = scm_list_1(scm_mem2string(pstr,strlength));
	    Py_DECREF(prepr);
	    scm_misc_error("python-apply",
			   "Python exception (~A) while dereferencing object attribute",
			   srepr);
	  }
	}
	// else we got the expected AttributeError exception.
      }
      // else we got NULL==pnextobj without Python exception.
      scm_misc_error("python-apply",
		     "could not dereference ~Ath level attribute in ~S",
		     scm_list_2(scm_long2num(ind),sfunc));
    }
    Py_INCREF(pnextobj);
    Py_DECREF(pfuncobj);
    pfuncobj = pnextobj;
  }
  Py_DECREF(pfunc);  // We do not need it anymore.  pfuncobj points at
                     // the function actually to be invoked.
  if (!PyCallable_Check(pfuncobj)) {
    Py_DECREF(pfuncobj);
    scm_misc_error("python-apply","function denoted by ~S is not callable",scm_list_1(sfunc));
  }

  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYTHON_APPLY)) {
    char *preprfuncobj = PyString_AsString(PyObject_Repr(pfuncobj));
    scm_simple_format(scm_current_output_port(),
		      scm_makfrom0str("# python_apply: decoded function actually to be invoked: ~S\n"),
		      scm_list_1(scm_makfrom0str(preprfuncobj)));
  }

  // Retrieve positional arguments

  parg = g2p_apply(sarg,sargtemplate);
  if (NULL == parg) {
    Py_DECREF(pfuncobj);
    scm_misc_error("python-apply","positional arguments conversion failure (~S)",
		   scm_list_1(sarg));
  }
  // Validate that it is indeed a tuple.
  if (!PyTuple_CheckExact(parg)) {
    Py_DECREF(pfuncobj);
    Py_DECREF(parg);
    scm_wrong_type_arg("python-apply",SCM_ARG2,sarg);
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYTHON_APPLY)) {
    char *pposarg = PyString_AsString(PyObject_Repr(parg));
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# python_apply: decoded positional arguments ~S\n"),scm_list_1(scm_makfrom0str(pposarg)));
  }

  // Retrieve keyword arguments.

  pkw = guileassoc2pythondict(skw,skwtemplate);
  if (NULL == pkw) {
    // Seems that PyDict_CheckExact() does not handle NULL argument gracefully.
     Py_DECREF(pfuncobj);
     Py_DECREF(parg);
     scm_misc_error("python-apply","keyword arguments conversion failure (~S)",
		    scm_list_1(skw));
  }
  if (!PyDict_CheckExact(pkw)) {
     Py_DECREF(pfuncobj);
     Py_DECREF(parg);
     Py_DECREF(pkw);
     scm_misc_error("python-apply",
		    "keyword arguments (~S) not properly converted into Python Dict",
		    scm_list_1(skw));
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYTHON_APPLY)) {
    char *pkwarg = PyString_AsString(PyObject_Repr(pkw));
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# python_apply: decoded keyword arguments ~S\n"),scm_list_1(scm_makfrom0str(pkwarg)));
  }

  // Ready to invoke the function.

  pres = PyEval_CallObjectWithKeywords(pfuncobj,parg,pkw);
  PyObject *pexception = PyErr_Occurred();
  if (pexception) {
    PyObject *prepr = PyObject_Repr(pexception);
    Py_DECREF(pfuncobj);
    Py_DECREF(parg);
    Py_DECREF(pkw);
    Py_XDECREF(pres);
    PyErr_Clear();
    if (NULL == prepr) {
      scm_misc_error("python-apply",
		     "python exception - could not be identified",
		     SCM_UNSPECIFIED);
    }
    else {
      int strlength = PyString_Size(prepr);
      char *pstr = PyString_AsString(prepr);
      SCM srepr = scm_list_1(scm_mem2string(pstr,strlength));
      Py_DECREF(prepr);
      scm_misc_error("python-apply","Python exception: ~A",
		     srepr);
    }
  }
  if (NULL != pres) {
    sres = p2g_apply(pres,srestemplate);
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYTHON_APPLY)) {
      char *presstr = PyString_AsString(PyObject_Repr(pres));
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# python_apply: decoded results:\n#     Python: ~S\n#     Scheme: ~S\n"),scm_list_2(scm_makfrom0str(presstr),sres));
    }
  }
  else {
    // else sres remains SCM_UNDEFINED.
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYTHON_APPLY)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# python_apply: Python code returned <NULL>\n"),SCM_EOL);
    }
  }
  return(sres);
}

////////////////////////////////////////////////////////////////////////
// Run Python code
////////////////////////////////////////////////////////////////////////

SCM
python_eval(SCM sobj,SCM smode)
{
  if (!SCM_STRINGP(sobj)) {
    scm_wrong_type_arg("python-eval",SCM_ARG1,sobj);
  }

  int start = (SCM_UNBNDP(smode)) || (SCM_EQ_P(SCM_BOOL_F,smode))
    ? Py_file_input
    : Py_eval_input;

  char *pstr = scm_to_locale_string(sobj);
  if (NULL == pstr) {
    scm_memory_error("python-eval");  // NOT COVERED BY TESTS
    //return(SCM_UNSPECIFIED);
  }

  PyObject *pmaindict =
    PyModule_GetDict(PyImport_AddModule("__main__"));
  if (NULL == pmaindict) {
    scm_misc_error("python-eval","could not get __main__ for (~S), mode ~A",  // NOT COVERED BY TESTS
		   scm_list_2(sobj,smode));
  }
  Py_INCREF(pmaindict);
  PyObject *pres = PyRun_String(pstr, start, pmaindict, pmaindict);
  Py_DECREF(pmaindict);
  free(pstr);

  PyObject *pexception = PyErr_Occurred();
  if (pexception) {
    PyObject *prepr = PyObject_Repr(pexception);
    Py_XDECREF(pres);
    PyErr_Clear();
    if (NULL == prepr) {
      scm_misc_error("python-eval",  // NOT COVERED BY TESTS
		     "python exception - could not be identified",
		     SCM_UNSPECIFIED);
    }
    else {
      int strlength = PyString_Size(prepr);
      char *pstr = PyString_AsString(prepr);
      SCM slist = scm_list_1(scm_mem2string(pstr,strlength));
      Py_DECREF(prepr);
      scm_misc_error("python-eval","Python exception: ~A",
		     slist);
    }
  }

  switch(start) {
  case Py_eval_input:
    {
      if (NULL != pres) {
	SCM sres = p2g_apply(pres,
			     SCM_EQ_P(SCM_BOOL_T,smode)
			          ? srestemplate_default : smode);
	Py_DECREF(pres);
	return(sres);
      }
      else {
	scm_misc_error("python-eval","could not return result of evaluation",
		       SCM_UNSPECIFIED);
	return(SCM_UNSPECIFIED);
      }
    }
  case Py_file_input:
  default:
    {
      Py_XDECREF(pres);
      return(SCM_UNSPECIFIED);
    }
  }
}

////////////////////////////////////////////////////////////////////////
// Import a Python module and return a wrapped pointer to it.
////////////////////////////////////////////////////////////////////////

SCM
python_import(SCM smodulename)
{
  if (!SCM_STRINGP(smodulename)) {
    scm_wrong_type_arg("python-import",SCM_ARG1,smodulename);
  }
  else {
    char *mname = scm_to_locale_string(smodulename);
    PyObject *pmodule = PyImport_ImportModule(mname);
    PyObject *pexception = PyErr_Occurred();
    if (pexception) {
      PyObject *prepr = PyObject_Repr(pexception);
      Py_XDECREF(pmodule);
      PyErr_Clear();

      SCM smname = scm_list_1(scm_mem2string(mname,strlen(mname)));
      free(mname);
      if (NULL == prepr) {
	scm_misc_error("python-import",  // NOT COVERED BY TESTS
		       "Python exception during module ~A import - could not be identified",
		       smname);
      }
      else {
	int strlength = PyString_Size(prepr);
	char *pstr = PyString_AsString(prepr);
	SCM slist = scm_list_2(SCM_CAR(smname),scm_mem2string(pstr,strlength));
	Py_DECREF(prepr);
	scm_misc_error("python-import",
		       "Python exception during module ~A import: ~A",
		       slist);
      }
    }
    // OK, exception did not occur.  Do we have a module?
    if (NULL == pmodule) {
      SCM slist = scm_list_1(scm_mem2string(mname,strlen(mname)));
      free(mname);
      scm_misc_error("python-eval","could not import module ~S",
		     slist);
    }
    free(mname);
    SCM smodule = wrap_pyobject(pmodule);
    Py_DECREF(pmodule);  // wrap_pyobject did Py_INCREF
    return(smodule);
  }
}

////////////////////////////////////////////////////////////////////////
// Version and build information
////////////////////////////////////////////////////////////////////////

// The macros used below are defined in version.h.
SCM
pyguile_version(void)
{
  return(scm_makfrom0str("PyGuile Version " PYGUILE_VERSION));
}

void
init_wrapper (void)
{
  Py_Initialize();
  if (atexit(Py_Finalize)) {
    fprintf(stderr,"cannot set Python finalization function\n");  // NOT COVERED BY TESTS
    exit(1);  // NOT COVERED BY TESTS
  }
  initpyscm();

  init_pysmob_type();
  init_g2p2g_smob_type();

  // The following must happen after init_g2p2g_smob_type().
  init_default_guiletopy_templates();

  SCM s_default_g2p = scm_variable_ref(scm_c_lookup("guile2python"));
  sargtemplate_default = scm_permanent_object(scm_list_2(scm_variable_ref(scm_c_lookup("g2p_list2Tuple")),s_default_g2p));
  skwtemplate_default = SCM_UNDEFINED; // guileassoc2pythondict will choose the right default.
  srestemplate_default = scm_permanent_object(scm_variable_ref(scm_c_lookup("python2guile")));

  scm_c_define_gsubr ("python-eval",1,1,0,python_eval);
  scm_c_define_gsubr ("python-apply",3,3,0,python_apply);
  scm_c_define_gsubr ("python-import",1,0,0,python_import);
  scm_c_define_gsubr ("pyguile-verbosity-set!",1,0,0,pyguile_verbosity_set);
  scm_c_define_gsubr ("pyguile-version",0,0,0,pyguile_version);
}

////////////////////////////////////////////////////////////////////////
// End of pyguile.c
