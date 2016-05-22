// pysmob implementation
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
// Implements the Guile SMOB type, which encapsulates Python objects.
// While those SMOBs can be used to encapsulate any PyObject* object,
// they are typically used to encapsulate only class instances.
//
////////////////////////////////////////////////////////////////////////
//
// Note about verbosity handling:
//
// This module uses printf() rather than scm_simple_format & Co. for
// PYGUILE_VERBOSE_GC and PYGUILE_VERBOSE_GC_DETAILED.
// The reason is that scm_* functions cannot be used during garbage
// collection.
//
////////////////////////////////////////////////////////////////////////
#include "pysmob.h"
#include "verbose.h"

#ifndef Py_ssize_t
#define Py_ssize_t int
#endif /* Py_ssize_t */

static scm_t_bits tag_pysmob;

////////////////////////////////////////////////////////////////////////
// Wrapped PyObject memory management
////////////////////////////////////////////////////////////////////////

static PyObject *pdict_wrapped_pyobjects;
// Pointer at Dict, whose keys are addresses of wrapped PyObjects.
// (The keys have to be addresses, because the objects themselves
// can be mutable and hence unsuitable for use as Dict keys.)

//scm_t_c_hook_function clear_pdict_values;
//scm_t_c_hook_function delete_unmarked_pdict_keys;

void *
clear_pdict_values(void *hook_data, void *func_data, void *data)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC)) {
    //scm_simple_format(scm_current_output_port(),scm_makfrom0str("# Starting garbage collection (mark phase) - entered clear_pdict_values\n"),SCM_EOL);
    printf("# Starting garbage collection (mark phase) - entered clear_pdict_values\n");
  }
  PyObject *pdict = (PyObject *)func_data;
  if (!PyDict_CheckExact(pdict)) {
    scm_misc_error("clear_pdict_values","invalid pysmobs Dict",SCM_EOL);  // NOT COVERED BY TESTS
  }

  PyObject *key;
  PyObject *value;
  Py_ssize_t pos = 0;
  while(PyDict_Next(pdict,&pos,&key,&value)) {
    Py_INCREF(Py_False);
    if (0 != PyDict_SetItem(pdict,
			    key,
			    Py_False)) {
      Py_DECREF(Py_False);  // NOT COVERED BY TESTS
      scm_misc_error("clear_pdict_values","failed to clear pysmobs Dict",SCM_EOL);  // NOT COVERED BY TESTS
    }
  }
  return(NULL);
}

void *
delete_unmarked_pdict_keys(void *hook_data, void *func_data, void *data)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC)) {
    //scm_simple_format(scm_current_output_port(),scm_makfrom0str("# Going to finish garbage collection (sweep phase) - entered delete_unmarked_pdict_keys\n"),SCM_EOL);
    printf("# Going to finish garbage collection (sweep phase) - entered delete_unmarked_pdict_keys\n");
  }
  PyObject *pdict = (PyObject *)func_data;
  if (!PyDict_CheckExact(pdict)) {
    scm_misc_error("delete_unmarked_pdict_keys","invalid pysmobs Dict",SCM_EOL);  // NOT COVERED BY TESTS
  }

  PyObject *pdict_clone = PyDict_Copy(pdict);
  if (NULL == pdict_clone) {
    PyErr_Clear();  // NOT COVERED BY TESTS
    scm_misc_error("delete_ummarked_pdict_keys","failed to prepare for deleting from Dict",SCM_EOL);  // NOT COVERED BY TESTS
  }

  PyObject *key;
  PyObject *value;
  Py_ssize_t pos = 0;
  while(PyDict_Next(pdict_clone,&pos,&key,&value)) {
    if (Py_False == value) {
      Py_INCREF(key);
      if (0 != PyDict_DelItem(pdict,key)) {
	PyErr_Clear();  // NOT COVERED BY TESTS
	Py_DECREF(key);  // NOT COVERED BY TESTS
	Py_DECREF(pdict_clone);  // NOT COVERED BY TESTS
	scm_misc_error("delete_ummarked_pdict_keys","failed to delete item from Dict",SCM_EOL);  // NOT COVERED BY TESTS
      }
      long pptr = PyLong_AsLong(key);
      Py_DECREF((PyObject *)pptr);  // Actually delete (if necessary) the formerly-wrapped PyObject.
      Py_DECREF(key);
      if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC_DETAILED)) {
	//scm_simple_format(scm_current_output_port(),scm_makfrom0str("# delete_unmarked_pdict_keys: deleting ~S\n"),scm_list_1(scm_long2num(pptr)));
	printf("# delete_unmarked_pdict_keys: deleting 0x%08lX\n",pptr);
      }
    }
  }
  Py_DECREF(pdict_clone);
  return(NULL);
}


////////////////////////////////////////////////////////////////////////
// Private functions
////////////////////////////////////////////////////////////////////////

static SCM
mark_pysmob(SCM psmob)
{
  // New system of garbage collection:
  // Each time we wrap a PyObject, we add its address, as a key, to
  // a Python Dict, which will serve as hash table.
  //
  // Python facilities will be used for this purpose.
  //
  // When starting the mark phase, we clear all values in the
  // aforementioned Python Dict.
  //
  // For each pysmob to be marked, we mark the corresponding Python
  // Dict value.
  //
  // At end of the sweep phase, we delete from the Python Dict any
  // items not marked.
  // The reference counting will be maintained by ownership by the
  // Python Dict.  Guile will not deal with reference counting
  // related to pysmobs at all.

  long key = (long) unwrap_pysmob(psmob);
  PyObject *pkey = PyLong_FromLong(key);
  if (NULL == pkey) {
    PyErr_Clear();  // NOT COVERED BY TESTS
    scm_memory_error("mark_pysmob");  // NOT COVERED BY TESTS
  }
  int ret = PyDict_Contains(pdict_wrapped_pyobjects,pkey);
  if (-1 == ret) {
    PyErr_Clear();  // NOT COVERED BY TESTS
    Py_DECREF(pkey);  // NOT COVERED BY TESTS
    scm_misc_error("mark_pysmob","error when checking pysmobs Dict for ~S",scm_list_1(psmob));  // NOT COVERED BY TESTS
  }
  if (0 == ret) {
    Py_DECREF(pkey);
    scm_misc_error("mark_pysmob","smob not found in pysmobs Dict: ~S",scm_list_1(psmob));
  }
  Py_INCREF(Py_True);
  if (0 != PyDict_SetItem(pdict_wrapped_pyobjects,
			  pkey,
			  Py_True)) {
    Py_DECREF(pkey);
    scm_misc_error("mark_pysmob","failed to mark pysmob ~S",scm_list_1(psmob));
  }
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC_DETAILED)) {
    //scm_simple_format(scm_current_output_port(),scm_makfrom0str("# mark_pysmob: marking ~S\n"),scm_list_1(scm_long2num(key)));
    printf("# mark_pysmob: marking 0x%08lX\n",key);
  }

  // scm_gc_mark(any SCM object referred to by the Python object);
  // One SCM object is returned to the caller (who will mark it).
  return(SCM_UNSPECIFIED);  // No need to mark any SCM object for now
  // (until PyObjects learn to hold wrapped SCM objects).
}


//static size_t
//free_pysmob(SCM psmob)
//{
//  PyObject *pobj = unwrap_pysmob(psmob);
//  if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC_DETAILED)) {
//    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# free_pysmob: freeing object ~S\n"),scm_list_1(scm_long2num((long)pobj)));
//  }
//  Py_XDECREF(pobj);
//  return(0);
//}

static int
print_pysmob(SCM smob, SCM port, scm_print_state* prstate)
{
  if (!SCM_SMOB_PREDICATE(tag_pysmob,smob)) {
    scm_wrong_type_arg("print-pysmob",SCM_ARG1,smob);  // NOT COVERED BY TESTS
  }
  if (!SCM_PORTP(port)) {
    scm_wrong_type_arg("print-pysmob",SCM_ARG2,port);  // NOT COVERED BY TESTS
  }
  // I don't know how to validate the 3rd argument.
  PyObject *prepr = PyObject_Repr(unwrap_pysmob(smob));
  if (NULL != prepr) {
    char *pstr = PyString_AsString(prepr);
    scm_puts("(python-eval ",port);
    scm_puts(pstr, port);
    scm_puts(" #t)",port);
    Py_DECREF(prepr);       // also invalidates pstr.
  }
  else {
    scm_misc_error("print-pysmob","repr(~S) failure",scm_list_1(smob));  // NOT COVERED BY TESTS
    //scm_puts("*nil*", port);
  }
  return(1);  // Nonzero means success.
}

static SCM
equalp_pysmob(SCM smob1, SCM smob2)
{
  if (!SCM_SMOB_PREDICATE(tag_pysmob,smob1)) {
    scm_wrong_type_arg("equalp-pysmob",SCM_ARG1,smob1);
  }
  if (!SCM_SMOB_PREDICATE(tag_pysmob,smob2)) {
    scm_wrong_type_arg("equalp-pysmob",SCM_ARG2,smob2);
  }
  PyObject *pobj1 = unwrap_pysmob(smob1);
  if (NULL == pobj1) {
    scm_misc_error("equalp-pysmob","argument 1 (~S) unwrapping failure",  // NOT COVERED BY TESTS
		   scm_list_1(smob1));
  }
  PyObject *pobj2 = unwrap_pysmob(smob2);
  if (NULL == pobj2) {
    scm_misc_error("equalp-pysmob","argument 2 (~S) unwrapping failure",  // NOT COVERED BY TESTS
		   scm_list_1(smob2));
  }
  switch (PyObject_RichCompareBool(pobj1,pobj2,Py_EQ)) {
  case 0:
    return(SCM_BOOL_F);
  case 1:
    return(SCM_BOOL_T);
  case -1:
  default:
    // Error.
    scm_misc_error("equalp-pysmob","comparison failure ~S vs. ~S",
		   scm_list_2(smob1,smob2));
    return(SCM_UNDEFINED);
  }
}

////////////////////////////////////////////////////////////////////////
// Public functions
////////////////////////////////////////////////////////////////////////


// Return nonzero if sobj is of type pysmob.
int
IS_PYSMOBP(SCM sobj)
{
  return(SCM_SMOB_PREDICATE(tag_pysmob,sobj));
}

// Create a pysmob corresponding to a PyObject.
SCM
wrap_pyobject(PyObject *pobj)
{
  if (NULL == pobj) {
    scm_misc_error("wrap-pyobject","NULL PyObject",SCM_EOL);  // NOT COVERED BY TESTS
    //return(SCM_UNSPECIFIED);
  }
  else {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_NEW_PYSMOB)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# wrap_pyobject: new wrapped object ~S\n"),scm_list_1(scm_long2num((long)pobj)));
    }
    Py_INCREF(pobj);
    Py_INCREF(Py_True);
    PyDict_SetItem(pdict_wrapped_pyobjects,
		   PyLong_FromLong((long)pobj),
		   Py_True);
    SCM_RETURN_NEWSMOB(tag_pysmob,pobj);
  }
}

// Provide reference to PyObject embedded in a pysmob.
// No ownership transfer is implied.
PyObject *
unwrap_pysmob(SCM sobj)
{
  if (!SCM_SMOB_PREDICATE(tag_pysmob,sobj)) {
    scm_wrong_type_arg("unwrap-pysmob",SCM_ARG1,sobj);  // NOT COVERED BY TESTS
  }
  PyObject *pobj = (PyObject *)SCM_SMOB_DATA(sobj);
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_UNWRAP_PYSMOB)) {
    // The scm_simple_format code can safely be invoked if we know
    // that we are not inside garbage collection.
    // TODO:  invoke a flag for this purpose.
    //scm_simple_format(scm_current_output_port(),scm_makfrom0str("# unwrap_pysmob: accessing object ~S\n"),scm_list_1(scm_long2num((long)pobj)));
    printf("# unwrap_pysmob: accessing object 0x%08lX\n",(long)pobj);
  }
  return(pobj);
}

////////////////////////////////////////////////////////////////////////

void finalize_pysmob_type(void)
{
  Py_DECREF(pdict_wrapped_pyobjects);
}

void init_pysmob_type(void)
{
  tag_pysmob = scm_make_smob_type("pysmob",0);
  scm_set_smob_mark (tag_pysmob, mark_pysmob);
  //scm_set_smob_free(tag_pysmob,free_pysmob);  // does nothing in the new scheme of managing PyObjects during garbage collection.
  scm_set_smob_print(tag_pysmob,print_pysmob);
  scm_set_smob_equalp(tag_pysmob,equalp_pysmob);

  // Py_Initialize must have already been invoked
  // by init_pysmob_type()'s caller.
  pdict_wrapped_pyobjects = PyDict_New();
  if (atexit(finalize_pysmob_type)) {
    fprintf(stderr,"cannot set pysmob finalization function\n");  // NOT COVERED BY TESTS
    exit(1);  // NOT COVERED BY TESTS
  }

  // Register garbage collection hooks.
  scm_c_hook_add(&scm_before_mark_c_hook,&clear_pdict_values,
		 (void *)pdict_wrapped_pyobjects,0);
  scm_c_hook_add(&scm_after_sweep_c_hook,&delete_unmarked_pdict_keys,
		 (void *)pdict_wrapped_pyobjects,0);
}

// End of pysmob.c
