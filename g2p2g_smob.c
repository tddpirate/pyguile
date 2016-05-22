// g2p2g_smob implementation
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
// Implements the G2P2G_SMOB type, which encapsulates g2p and p2g
// conversion routines, for use in defining templates for converting
// arguments and results of Python functions.

#include "g2p2g_smob.h"

static scm_t_bits tag_g2p2g_smob;

////////////////////////////////////////////////////////////////////////
// Private functions
////////////////////////////////////////////////////////////////////////

// static SCM mark_g2p2g_smob(SCM g2p2g_smob)
// not needed, as the default will be used.

// static size_t free_g2p2g_smob(SCM g2p2g_smob)
// not needed, as the default will be used.

static int
print_g2p2g_smob(SCM smob, SCM port, scm_print_state* prstate)
{
  if (!SCM_SMOB_PREDICATE(tag_g2p2g_smob,smob)) {
    scm_wrong_type_arg("print-g2p2g-smob",SCM_ARG1,smob);  // NOT COVERED BY TESTS
  }
  if (!SCM_PORTP(port)) {
    scm_wrong_type_arg("print-g2p2g-smob",SCM_ARG2,port);  // NOT COVERED BY TESTS
  }
  // I don't know how to validate the 3rd argument.

  const char *name = (const char *) SCM_CELL_WORD_2(smob);
  scm_puts("'",port);
  scm_puts(name,port);
  return(1);  // Nonzero means success.
}

// static SCM equalp_g2p2g_smob(SCM smob1, SCM smob2)
// not needed, as the default will be used.

////////////////////////////////////////////////////////////////////////
// Public functions
////////////////////////////////////////////////////////////////////////

// Return nonzero if sobj is of type g2p2g_smob.
//extern int IS_G2P2G_SMOBP(SCM sobj);
#define IS_G2P2G_SMOBP(sobj) SCM_SMOB_PREDICATE(tag_g2p2g_smob,sobj)

// Return nonzero if sobj is of type pysmob.
//int
//IS_G2P2G_SMOBP(SCM sobj)
//{
//  return(SCM_SMOB_PREDICATE(tag_g2p2g_smob,sobj));
//}

int
IS_G2P_SMOBP(SCM sobj)
{
  if (!SCM_SMOB_PREDICATE(tag_g2p2g_smob,sobj)) {
    return (0);
  }
  const char *name = (const char *) SCM_CELL_WORD_2(sobj);
  return('g' == name[0]);
}

int
IS_P2G_SMOBP(SCM sobj)
{
  if (!SCM_SMOB_PREDICATE(tag_g2p2g_smob,sobj)) {
    return (0);
  }
  const char *name = (const char *) SCM_CELL_WORD_2(sobj);
  return('p' == name[0]);
}

g2p_func_ptr
get_g2p_function(SCM smob)
{
  return((g2p_func_ptr) SCM_CELL_WORD_1(smob));
}

p2g_func_ptr
get_p2g_function(SCM smob)
{
  return((p2g_func_ptr) SCM_CELL_WORD_1(smob));
}

SCM
bind_g2p_function(PyObject *(*g2p_func)(SCM,SCM), const char* name)
{
  if (NULL == g2p_func) {
    if (NULL == name) {        // NOT COVERED BY TESTS
      name = "<null>";         // NOT COVERED BY TESTS
    }
    scm_misc_error("bind_g2p_function","NULL g2p_func pointer for ~S",scm_list_1(scm_mem2string(name,strlen(name))));      // NOT COVERED BY TESTS
  }
  if (NULL == name) {
    scm_misc_error("bind_g2p_function","no name was specified",SCM_UNSPECIFIED);    // NOT COVERED BY TESTS
  }
  if ('g' != name[0]) {
    scm_misc_error("bind_g2p_function","name does not start with 'g': ~S",scm_list_1(scm_mem2string(name,strlen(name))));      // NOT COVERED BY TESTS
  }
  SCM scm_g2p;
  SCM_NEWSMOB2(scm_g2p,tag_g2p2g_smob,g2p_func,name);
  scm_c_define(name,scm_g2p);
  return(scm_g2p);
}

SCM
bind_p2g_function(SCM(*p2g_func)(PyObject *,SCM), const char* name)
{
  if (NULL == p2g_func) {
    if (NULL == name) {       // NOT COVERED BY TESTS
      name = "<null>";        // NOT COVERED BY TESTS
    }
    scm_misc_error("bind_p2g_function","NULL p2g_func pointer for ~S",scm_list_1(scm_mem2string(name,strlen(name))));  // NOT COVERED BY TESTS
  }
  if (NULL == name) {
    scm_misc_error("bind_p2g_function","no name was specified",SCM_UNDEFINED);  // NOT COVERED BY TESTS
  }
  if ('p' != name[0]) {
    scm_misc_error("bind_p2g_function","name does not start with 'p': ~S",scm_list_1(scm_mem2string(name,strlen(name))));  // NOT COVERED BY TESTS
  }
  SCM scm_p2g;
  SCM_NEWSMOB2(scm_p2g,tag_g2p2g_smob,p2g_func,name);
  scm_c_define(name,scm_p2g);
  return(scm_p2g);
}


////////////////////////////////////////////////////////////////////////

void
init_g2p2g_smob_type(void)
{
  tag_g2p2g_smob = scm_make_smob_type("g2p2g_smob",0);
  scm_set_smob_print(tag_g2p2g_smob,print_g2p2g_smob);
  bind_g2p_functions();  // defined in guiletopy.inc
  bind_p2g_functions();  // defined in pytoguile.inc
}

// End of g2p2g_smob.c
