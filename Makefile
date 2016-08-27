# Infrastructure for invoking Python from Guile, via extension
# functions.
########################################################################
#
# Copyright (C) 2008 Omer Zak.
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library, in a file named COPYING; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA  02111-1307  USA
#
# For licensing issues, contact <w1@zak.co.il>.
#
########################################################################
#
# make
#   Build the software
#
# make coverage
#   Build a special version which includes coverage analysis code
#
# make clean
#   Clean intermediate files
#
# make distclean
#   Clean also targets
#
# make check
#   Run all tests in the test suite
#
# make gcov.out
#   Summarize coverage analysis files into gcov.out
#
########################################################################

#PYVERSION = `python -V 2>&1 | cut -d\  -f2 | cut -d. -f1-2`
PYVERSION = `python -c "import sys;sys.stdout.write(sys.version[:3])"`

PYINC = $(shell python-config --includes)
PYLIB = -lpython$(PYVERSION)
PERL = /usr/bin/perl
TEST_VERBOSE = 0
TEST_FILES = t/*.t
TEST_LIBDIRS =
RUN_GUILE_TESTS = ./t/scripts/RunGuileTests.pl
EXTRACT_CONVERSION_FUNCTIONS_PY = ./extract_conversion_functions.py
EXTRACT_CONVERSION_FUNCTIONS = python $(EXTRACT_CONVERSION_FUNCTIONS_PY) --inc
EXTRACT_CONVERSION_EXPORTS = python $(EXTRACT_CONVERSION_FUNCTIONS_PY) --scm pyguile.scm.in

CDEBUG = -g -Wall
CFLAGS = $(CDEBUG) `guile-config compile` $(PYINC) $(GCOVFLAGS)
CPPFLAGS = `guile-config compile` $(PYINC)
LDFLAGS = $(shell guile-config link) $(GCOVFLAGS) -Wl,-rpath="$(shell python-config --prefix)/lib"
RM = rm -v


SRCS = pyguile.c pysmob.c pytoguile.c guiletopy.c g2p2g_smob.c verbose.c pyscm.c
TARGETS = libpyguile.so pyguile.scm

all: $(TARGETS)
all: GCOVFLAGS =
coverage: $(TARGETS)
coverage: GCOVFLAGS = -fprofile-arcs -ftest-coverage

libpyguile.so: $(SRCS:.c=.o)
	$(CC) -shared $(LDFLAGS) -o $@ $^ $(PYLIB) $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ -fPIC $<

guiletopy.inc: guiletopy.c $(EXTRACT_CONVERSION_FUNCTIONS_PY)
	$(EXTRACT_CONVERSION_FUNCTIONS) < $< > $@

pytoguile.inc: pytoguile.c $(EXTRACT_CONVERSION_FUNCTIONS_PY)
	$(EXTRACT_CONVERSION_FUNCTIONS) < $< > $@

pyguile.scm: pyguile.scm.in guiletopy.c pytoguile.c $(EXTRACT_CONVERSION_FUNCTIONS_PY)
	cat guiletopy.c pytoguile.c | $(EXTRACT_CONVERSION_EXPORTS) > $@

version.h:
	echo "#define PYGUILE_VERSION \"0.3.1\"" > $@

.build:
	echo 1 > $@
	echo Initial build number file was created

########################################################################
# Clean up

FILES_TO_CLEAN = *~ *.d *.inc *.o core *.pyc \
        version.h \
        *.gcda *.gcno *.gcov gcov.out
clean:
	-$(RM) $(FILES_TO_CLEAN)
	-cd t; pwd; $(RM) $(FILES_TO_CLEAN)
	-cd t/scripts; pwd; $(RM) $(FILES_TO_CLEAN)

distclean: clean
	-$(RM) $(TARGETS)

########################################################################
# Test and coverage analysis

check: $(TARGETS)
	$(PERL) $(TEST_LIBDIRS) $(RUN_GUILE_TESTS) $(TEST_FILES)

gcov.out:
	gcov -a -l -p *.c
	-$(RM) *usr*include*.h.gcov
	cat *.gcov > gcov.out

manualcheck: $(TARGETS)
	for testfile in $(TEST_FILES); do guile -s $$testfile; done

########################################################################
# Build dependencies

-include $(SRCS:.c=.d)

%.d: %.c
	@set -e; rm -f $@; \
  $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
  sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
  rm -f $@.$$$$

# We want to force those *.inc files to be created before building
# the *.d files.
pyguile.d: version.h
pytoguile.d: pytoguile.inc
guiletopy.d: guiletopy.inc

########################################################################
# End of PyGuile Makefile
