// pyscm implementation file
// Python data type for wrapping Guile SCM objects
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
// Implements PySCM data type - used for wrapping SCM objects in Python
// and making it possible to call them and access/manipulate their
// attributes.

#include "pyscm.h"
#include "guiletopy.h"
#include "pytoguile.h"
#include "verbose.h"

////////////////////////////////////////////////////////////////////////
// Guile Data Structures
////////////////////////////////////////////////////////////////////////

static SCM pyscm_registration_hash;  // Hash table for preservation of SCMs referred to by PySCM instances.  We use *_hashv_* functions for the keys.  !!!to ensure that eqv? comparisons are OK here
static long pyscm_registration_index; // Used for building keys for the above hash table.


////////////////////////////////////////////////////////////////////////
// Python Data Structures
////////////////////////////////////////////////////////////////////////

//static PyObject *ErrorObject;

typedef struct {
  PyObject_HEAD
  long ob_scm_index;  // Index into the SCM registration hash table.
} pyscm_PySCMObject;


//static struct PyMethodDef pyscm_PySCM_methods[] = {
//  {NULL,		NULL}		/* sentinel */
//};


static char pyscm_PySCMtype__doc__[] = 
"PyGuile SCM wrapper object"
;


static int pyscm_PySCM_print(pyscm_PySCMObject *self, FILE *fp, int flags);
static PyObject *pyscm_PySCM_getattr(pyscm_PySCMObject *self, char *name);
static int pyscm_PySCM_setattr(pyscm_PySCMObject *self,
			       char *name, PyObject *v);
static long pyscm_PySCM_hash(pyscm_PySCMObject *self);
static PyObject *pyscm_PySCM_call(pyscm_PySCMObject *self,
				  PyObject *args, PyObject *kwargs);
static PyObject *pyscm_PySCM_str(pyscm_PySCMObject *self);
static void pyscm_PySCM_dealloc(pyscm_PySCMObject *self);
static PyObject *pyscm_PySCM_new(PyTypeObject *type,
				 PyObject *args, PyObject *kwds);


static PyTypeObject pyscm_PySCMType = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,                         /*ob_size*/
  "pyscm.PySCM",             /*tp_name*/
  sizeof(pyscm_PySCMObject), /*tp_basicsize*/
  0,                         /*tp_itemsize*/
  /* methods */
  (destructor)pyscm_PySCM_dealloc,    /*tp_dealloc*/
  (printfunc)pyscm_PySCM_print,       /*tp_print*/
  (getattrfunc)pyscm_PySCM_getattr,   /*tp_getattr*/
  (setattrfunc)pyscm_PySCM_setattr,   /*tp_setattr*/
  (cmpfunc)0,                /*tp_compare*/
  (reprfunc)0,               /*tp_repr*/
  0,                         /*tp_as_number*/
  0,                         /*tp_as_sequence*/
  0,                         /*tp_as_mapping*/
  (hashfunc)pyscm_PySCM_hash,                         /*tp_hash */
  (ternaryfunc)pyscm_PySCM_call,                         /*tp_call*/
  (reprfunc)pyscm_PySCM_str,                         /*tp_str*/
  0,                         /*tp_getattro*/
  0,                         /*tp_setattro*/
  0,                         /*tp_as_buffer*/
  Py_TPFLAGS_DEFAULT /*| Py_TPFLAGS_BASETYPE*/ ,        /*tp_flags*/ // We don't expect to subclass this class.
  pyscm_PySCMtype__doc__,    /* tp_doc */
  0,		             /* tp_traverse */
  0,		             /* tp_clear */
  0,		             /* tp_richcompare */
  0,		             /* tp_weaklistoffset */
  0,		             /* tp_iter */
  0,		             /* tp_iternext */
  0,                         /* tp_methods */
  0,                         /* tp_members */
  0,                         /* tp_getset */
  0,                         /* tp_base */
  0,                         /* tp_dict */
  0,                         /* tp_descr_get */
  0,                         /* tp_descr_set */
  0,                         /* tp_dictoffset */
  (initproc)0,               /* tp_init */
  0,                         /* tp_alloc */
  (newfunc)pyscm_PySCM_new,  /* tp_new */
};


////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////

static int
pyscm_PySCM_print(pyscm_PySCMObject *self, FILE *fp, int flags)
{
  PyObject *pstr = pyscm_PySCM_str(self);
  if (NULL == pstr) {
    scm_memory_error("pyscm_PySCM_print");
  }
  int retval = PyObject_Print(pstr,fp,flags);
  Py_DECREF(pstr);
  return(retval);
}


// Documentation of the stemplate data structure, which is paired
// with the actual SCM wrapped by an PySCM instance.
// It is a 5-element vector with the following elements.
// The first 4 elements deal with the SCM being wrapped by a callable
// PySCM.
// If any of the three templates is SCM_EOL, then the corresponding type
// of arguments/result is not expected to exist (if the SCM object
// returns a value to template of SCM_EOL, then the value is discarded
// and None is returned to Python).
// If GET_APPLY_FUNC() has the value SCM_EOL instead of a function,
// it means that the object is not callable.
// 
// If the relevant template value is #t, then a default is used. (CANCELLED - when building the template, can use a macro to fill in defaults.)
//   0. p2g template for positional arguments
#define GET_P2G_POSITIONAL_ARGS_TEMPLATE(stemplate) scm_vector_ref(stemplate,scm_long2num(0))
//   1. p2g template for keyword arguments
#define GET_P2G_KEYWORD_ARGS_TEMPLATE(stemplate)    scm_vector_ref(stemplate,scm_long2num(1))
//   2. g2p template for result
#define GET_G2P_RESULT_TEMPLATE(stemplate)          scm_vector_ref(stemplate,scm_long2num(2))
//   3. function for actually applying the SCM object on the arguments
//      (default being 'apply').
#define GET_APPLY_FUNC(stemplate)                   scm_vector_ref(stemplate,scm_long2num(3))
//   4. Either #f or a hash (_hashv_ type) whose keys are described below.
#define GET_ATTRS_HASH(stemplate)                   scm_vector_ref(stemplate,scm_long2num(4))
//
// If the 5th element is #f, then the SCM has no attributes.
// Otherwise, the SCM has attributes (which can be either data or methods),
// and the 5th element is supposed to be an hash.
//
// The hash keys are as follows:
//   #t - for default values (CANCELLED - when building the template, can use
//                            a macro to fill in defaults.)
//   #f - how to deal with a missing attribute - value can be either
//        another #f (throw an attribute error exception to Python) or a
//        4-element vector as described below.
//   #:-keyword - refers to attribute 'keyword'
// The values are either #t (to use defaults for everything) (CANCELLED - when
//                            building the template, can use a macro to fill
//                            in defaults.)
// or 4-element vectors:
//   0. p2g template for converting __setattr__ value
#define GET_H_P2G_SETATTR_TEMPLATE(shashvalue)      scm_vector_ref(shashvalue,scm_long2num(0))
//   1. g2p template for converting __getattr__ value
#define GET_H_G2P_GETATTR_TEMPLATE(shashvalue)      scm_vector_ref(shashvalue,scm_long2num(1))
//   2. function (func sobj #:-keyword . value) for doing the real
//      setattr work; if the value is missing, do delattr.
//      It is expected to return #f if it failed, or any other value (including
//      SCM_UNDEFINED) if it succeeded.
#define GET_H_SETATTR_FUNC(shashvalue)              scm_vector_ref(shashvalue,scm_long2num(2))
//   3. function (func sobj #:-keyword) for doing the real getattr
//      work.
#define GET_H_GETATTR_FUNC(shashvalue)              scm_vector_ref(shashvalue,scm_long2num(3))
// If any of the above is #t then get the corresponding element from
// the default vector. (CANCELLED)
// If any of the GET_H_{GET,SET}ATTR_FUNC values is SCM_EOL, then the
// corresponding function is suppressed.  The *_TEMPLATE values must be
// valid whenever the corresponding function exists.
// The value corresponding to the key #f can also be another #f, which
// would cause Python attribute error to be raised.  This
// mechanism allows objects to decide how they wish currently-nonexistent
// attributes to be handled.
// In the case of an attribute which is recognized by Python as a method,
// the g2p template for __getattr__ would be a pair of g2p_opaque2PySCM
// and a whole stemplate as described above.
//
// Signatures of SCM functions to be invoked by Python:
// Callable SCM objects wrapped by PySCM - always have two arguments.
//   When default templates are used, the first argument's value is a list,
//   and the second argument's value is an alist.
// Apply procedure (obtained by GET_APPLY_FUNC()) - has the same signature
//   as Scheme's apply procedure i.e. (apply func . args)


// Functions for manipulating vectors:
//   SCM_VECTORP()
//   SCM_VECTOR_LENGTH()
//   scm_vector(scm_list_2(sobj1,sobj2))
//   scm_vector_ref(vector,scm_long2num(index_zero_based))

// PROBLEM: need to prepend "-" to name before converting it into
// #:-keyword - inefficient!  How to eliminate this?

// Common code for pyscm_PySCM_getattr() and pyscm_PySCM_setattr():
// Retrieve and return the 4-element vector corresponding to desired
// attribute of the pyscm_PySCMObject.
// Perform also validity checking and raise Python exception if
// invalid.
// Since it is needed later, also the SCM object, corresponding to the
// pyscm_PySCMObject, is returned to the caller, put into 2-element
// list together with the #:-keyword corresponding to name.
static SCM
retrieve_sattr_vector(pyscm_PySCMObject *self, char *name, SCM *sobj_keyword)
{
  SCM shandle = scm_hashv_get_handle(pyscm_registration_hash,scm_long2num(self->ob_scm_index));
  if (SCM_BOOLP(shandle) && SCM_EQ_P(SCM_BOOL_F,shandle)) {
    Py_FatalError("PySCM object lost its associated SCM object");
  }
  // Now:
  // SCM_CADR(shandle) is the SCM object itself
  // SCM_CDDR(shandle) is the stemplate.
  SCM sattrshash = GET_ATTRS_HASH(SCM_CDDR(shandle));

  if (SCM_EQ_P(SCM_BOOL_F,sattrshash)) {
    PyErr_SetString(PyExc_AttributeError, name);
    return(SCM_UNDEFINED);  // Error return
  }

  // The object has attributes.  Build the hash key (a keyword).

  size_t nlength = strlen(name);
  char *dashstr = malloc(nlength+2);
  dashstr[0] = '-';
  dashstr[1] = '\0';
  strncat(dashstr,name,nlength);
  SCM skeyword = scm_make_keyword_from_dash_symbol(scm_str2symbol(dashstr));
  // !!! Do we have to free dashstr?
  // !!! Similar code is used also in pytoguile.c - review it.

  SCM sattr_vector_handle = scm_hashv_get_handle(sattrshash,skeyword);
  if (SCM_EQ_P(SCM_BOOL_F,sattr_vector_handle)) {
    // Missing attribute.  How to deal with it?
    sattr_vector_handle = scm_hashv_get_handle(sattrshash,SCM_BOOL_F);
    if (SCM_EQ_P(SCM_BOOL_F,sattr_vector_handle)) {
      // Hash value corresponding to key #f is itself another #f, which
      // means that the object does not wish to exhibit to Python
      // unknown attributes.
      PyErr_SetString(PyExc_AttributeError, name);
      return(SCM_UNDEFINED);  // Error return
    }
    // Otherwise, we'll use the hash value corresponding to #f as
    // a catch-all for all attributes not otherwise defined.
  }
  *sobj_keyword = scm_list_2(SCM_CADR(shandle),skeyword);
  return(SCM_CDR(sattr_vector_handle));
}

static PyObject *
pyscm_PySCM_getattr(pyscm_PySCMObject *self, char *name)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_getattr: trying to get attribute=~S from pobj=~S\n"),scm_list_2(scm_makfrom0str(name),verbosity_repr((PyObject *)self)));
  }
  SCM sobj_keyword;
  SCM sattr_vector = retrieve_sattr_vector(self,name,&sobj_keyword);
  if (SCM_UNBNDP(sattr_vector)) {
    // Attribute error exception was raised by retrieve_sattr_vector().
    return(NULL);
  }

  SCM sgetattr_func = GET_H_GETATTR_FUNC(sattr_vector);
  if (SCM_EQ_P(SCM_EOL,sgetattr_func)) {
    PyErr_SetString(PyExc_AttributeError, name);
    return(NULL);
  }
  SCM stemplate = GET_H_G2P_GETATTR_TEMPLATE(sattr_vector);

  SCM sresult = scm_apply(sgetattr_func,sobj_keyword,SCM_EOL);
  return(g2p_apply(sresult,stemplate));
}

static int
pyscm_PySCM_setattr(pyscm_PySCMObject *self, char *name, PyObject *v)
{
  /* Set attribute 'name' to value 'v'. v==NULL means delete */
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_setattr: trying to set attribute=~S from pobj=~S to value ~S\n"),scm_list_3(scm_makfrom0str(name),verbosity_repr((PyObject *)self),verbosity_repr(v)));
  }
  SCM sobj_keyword;
  SCM sattr_vector = retrieve_sattr_vector(self,name,&sobj_keyword);
  if (SCM_UNBNDP(sattr_vector)) {
    // Attribute error exception was raised by retrieve_sattr_vector().
    return(-1);
  }

  SCM ssetattr_func = GET_H_SETATTR_FUNC(sattr_vector);
  if (SCM_EQ_P(SCM_EOL,ssetattr_func)) {
    PyErr_SetString(PyExc_AttributeError, name);
    return(-1);
  }

  if (NULL != v) {
    SCM sval = p2g_apply(v,
			 GET_H_P2G_SETATTR_TEMPLATE(sattr_vector));
    scm_append_x(scm_list_2(sobj_keyword,sval));
  }

  SCM sresult = scm_apply(ssetattr_func,sobj_keyword,SCM_EOL);
  return(SCM_EQ_P(SCM_BOOL_F,sresult) ? (-1) : 0);
}

static long
pyscm_PySCM_hash(pyscm_PySCMObject *self)
{
  /* Return a hash of self (or -1) */
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_hash: hash is ~S\n"),scm_list_1(scm_long2num(self->ob_scm_index)));
  }
  return(self->ob_scm_index);
}

// Compute logical XOR of a and b
int logical_xor(int a,int b)
{
  return((a == 0)
	 ? (b != 0)
	 : (b == 0));
}
// Compute logical equivalence of a and b (logical inverse of XOR)
int logical_equiv(int a,int b)
{
  return((a != 0)
	 ? (b != 0)
	 : (b == 0));
}

static PyObject *
pyscm_PySCM_call(pyscm_PySCMObject *self, PyObject *args, PyObject *kwargs)
{
  /* Return the result of calling self with argument args */

  SCM shandle = scm_hashv_get_handle(pyscm_registration_hash,scm_long2num(self->ob_scm_index));
  if (SCM_BOOLP(shandle) && SCM_EQ_P(SCM_BOOL_F,shandle)) {
    Py_FatalError("PySCM object lost its associated SCM object");  // NOT COVERED BY TESTS
  }
  // Now:
  // SCM_CADR(shandle) is the SCM object itself
  // SCM_CDDR(shandle) is the stemplate.
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_call: calling ~S with args=~S and keywords=~S; stemplate=~S\n"),scm_list_4(SCM_CADR(shandle),verbosity_repr(args),verbosity_repr(kwargs),SCM_CDDR(shandle)));
  }

  SCM sapply_func = GET_APPLY_FUNC(SCM_CDDR(shandle));
  if (SCM_EQ_P(SCM_EOL,sapply_func)) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_call: raising exceptions.TypeError due to \"PySCM wraps a non-callable SCM\"\n"),SCM_EOL);
    }
    PyErr_SetString(PyExc_TypeError, "PySCM wraps a non-callable SCM");
    return(NULL);
  }

  // Process arguments.
  SCM sargs_template = GET_P2G_POSITIONAL_ARGS_TEMPLATE(SCM_CDDR(shandle));
  SCM skwargs_template = GET_P2G_KEYWORD_ARGS_TEMPLATE(SCM_CDDR(shandle));
  /*if (logical_xor(SCM_EQ_P(SCM_EOL,sargs_template),(NULL==args))
    || logical_xor(SCM_EQ_P(SCM_EOL,skwargs_template),(NULL==kwargs)))*/
  // The following allows template to exist without actual arguments.
  if ((SCM_EQ_P(SCM_EOL,sargs_template) && (NULL != args))
      || (SCM_EQ_P(SCM_EOL,skwargs_template) && (NULL != kwargs))) {
    if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
      scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_call: raising exceptions.TypeError due to \"wrapped SCM does not take some of the provided arguments\"\n"),SCM_EOL);
    }
    PyErr_SetString(PyExc_TypeError, "wrapped SCM does not take some of the provided arguments");
    return(NULL);
  }

  SCM sargs = SCM_EQ_P(SCM_EOL,sargs_template) || (NULL == args)
    ? SCM_EOL : p2g_apply(args,sargs_template);
  SCM skwargs = SCM_EQ_P(SCM_EOL,skwargs_template) || (NULL == kwargs)
    ? SCM_EOL : p2g_apply(kwargs,skwargs_template);

  SCM sresult = scm_apply(sapply_func,scm_list_2(SCM_CADR(shandle),scm_list_2(sargs,skwargs)),SCM_EOL);
  SCM sresult_template = GET_G2P_RESULT_TEMPLATE(SCM_CDDR(shandle));
  if (SCM_EQ_P(SCM_EOL,sresult_template)) {
    Py_RETURN_NONE;
  }
  else {
    return(g2p_apply(sresult,sresult_template));
  }
}

// Does not include the template object in the string representation.
static PyObject *
pyscm_PySCM_str(pyscm_PySCMObject *self)
{
  if (0 == self->ob_scm_index) {
    return(PyString_FromString("<no SCM association>"));
  }
  SCM shandle = scm_hashv_get_handle(pyscm_registration_hash,scm_long2num(self->ob_scm_index));
  if (SCM_BOOLP(shandle) && SCM_EQ_P(SCM_BOOL_F,shandle)) {
    Py_FatalError("PySCM object lost its associated SCM object");
  }
  SCM sstr = scm_object_to_string(SCM_CADR(shandle),scm_variable_ref(scm_c_lookup("write")));

  PyObject *pstr = PyString_FromStringAndSize(SCM_STRING_CHARS(sstr),SCM_STRING_LENGTH(sstr));
  return(pstr);  // possibly NULL.
}

static void
pyscm_PySCM_dealloc(pyscm_PySCMObject *self)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_dealloc: deallocating PySCMObject with hash ~S\n"),scm_list_1(scm_long2num(self->ob_scm_index)));
  }
  if (0 != self->ob_scm_index) {
    // Unregister the associated SCM from the hash table.
    SCM shashkey = scm_long2num(self->ob_scm_index);
    scm_hashv_remove_x(pyscm_registration_hash,shashkey);
    // If ob_scm_index is zero, no SCM was associated yet with
    // this PySCM instance.
  }
  self->ob_type->tp_free((PyObject*)self);
}

static PyObject *
pyscm_PySCM_new(PyTypeObject *type, PyObject *args, PyObject *kwds)
{
  pyscm_PySCMObject *self;
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_GC_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# pyscm_PySCM_new: was called\n"),SCM_EOL);
  }
  self = (pyscm_PySCMObject *)type->tp_alloc(type,0);
  if (NULL != self) {
    self->ob_scm_index = 0;
  }
  return((PyObject *)self);
}

////////////////////////////////////////////////////////////////////////
// Interface to the rest of PyGuile
////////////////////////////////////////////////////////////////////////

// Create a pyscm_PySCMObject instance, which wraps sobj and associates
// with it with template for data conversions when python accesses data
// and functions/methods associated with sobj.
PyObject *
wrap_scm(SCM sobj,SCM stemplate)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# wrap_scm: was called to wrap ~S\n"),scm_list_1(sobj));
  }
  pyscm_PySCMObject *pwrapper = PyObject_New(pyscm_PySCMObject,&pyscm_PySCMType);
  if (NULL == pwrapper) {
    scm_memory_error("wrap_scm");  // NOT COVERED BY TESTS
  }
  //PyObject_Init(pwrapper,&pyscm_PySCMType);  // Is it needed or does PyObject_New() take care of it?
  //if (NULL == pwrapper) {
  //  scm_misc_error("wrap_scm","could not wrap object ~S with PySCM when using conversion template ~S",
  //		   scm_list_2(sobj,stemplate));
  //}
  else {
    SCM sconsed = scm_cons(sobj,stemplate);
    SCM shashkey = scm_long2num(++pyscm_registration_index);
    scm_hashv_create_handle_x(pyscm_registration_hash,shashkey,sconsed);
    pwrapper->ob_scm_index = pyscm_registration_index;
    return((PyObject *)pwrapper);
  }
}

// Return 0 if pobj is not of this type and/or does not wrap a SCM.
// Otherwise, return a nonzero value.
int
PySCMObject_Check(PyObject *pobj)
{
  if (!PyObject_TypeCheck(pobj, &pyscm_PySCMType)) {
    return(0);
  }
  return ((0 == ((pyscm_PySCMObject *)pobj)->ob_scm_index)
	  ? 0   // pobj does not actually wrap a SCM.
	  : 1);
}

// Unwrap a pyscm_PySCMObject instance and get from it the original
// SCM object.  If the object is not a pyscm_PySCMObject or does not
// wrap a SCM object, raise an error.
SCM
unwrap_pyscm_object(PyObject *pobj)
{
  if (pyguile_verbosity_test(PYGUILE_VERBOSE_PYSCM)) {
    scm_simple_format(scm_current_output_port(),scm_makfrom0str("# unwrap_pyscm_object: trying to unwrap pobj=~S\n"),scm_list_1(verbosity_repr(pobj)));
  }

  if (!PySCMObject_Check(pobj)) {
    Py_FatalError("Trying to pyscm-unwrap a non-PySCM");
  }
  SCM shandle = scm_hashv_get_handle(pyscm_registration_hash,scm_long2num(((pyscm_PySCMObject *)pobj)->ob_scm_index));
  return(SCM_CADR(shandle));
}

////////////////////////////////////////////////////////////////////////
// Initializer
////////////////////////////////////////////////////////////////////////

static struct PyMethodDef pyscm_methods[] = {
	
	{NULL,	 (PyCFunction)NULL, 0, NULL}		/* sentinel */
};


/* Initialization function for the module (*must* be called initpyscm) */

static char pyscm_module_documentation[] = 
"pyscm - defines the Custom Python datatype PySCM for wrapping SCM objects"
;

#ifndef PyMODINIT_FUNC	/* declarations for DLL import/export */
#define PyMODINIT_FUNC void
#endif
PyMODINIT_FUNC
initpyscm(void)
{
  PyObject *m;

  /*pyscm_PySCMType.tp_new = PyType_GenericNew;*/
  if (PyType_Ready(&pyscm_PySCMType) < 0) {
    return;  // NOT COVERED BY TESTS
  }

  /* Create the module and add the functions */
  m = Py_InitModule4("pyscm", pyscm_methods,
		     pyscm_module_documentation,
		     (PyObject*)NULL,PYTHON_API_VERSION);
  if (NULL == m) {
    return;  // NOT COVERED BY TESTS
  }

  Py_INCREF(&pyscm_PySCMType);
  PyModule_AddObject(m, "PySCM", (PyObject *)&pyscm_PySCMType);

  /* Add some symbolic constants to the module */
  //PyObject *d;
  //d = PyModule_GetDict(m);
  //ErrorObject = PyString_FromString("pyscm.error");
  //PyDict_SetItemString(d, "error", ErrorObject);

  /* Add constants here */
  // Currently, none is needed.

  /* Check for errors */
  if (PyErr_Occurred()) {
    Py_FatalError("can't initialize module pyscm");  // NOT COVERED BY TESTS
  }

  // This part initializes the Guile data structures needed
  // by this module.
  pyscm_registration_hash = scm_permanent_object(scm_c_make_hash_table(65537));
  pyscm_registration_index = 0;
}

////////////////////////////////////////////////////////////////////////
// End of pyscm.c
