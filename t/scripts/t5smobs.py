#!/usr/bin/python
# Auxiliary functions for exercising pysmobs.
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

class opaq(object):
  def __init__(self,arg1):
    self.arg1 = arg1
  def transform(self):
    self.arg1 = self.arg1 + self.arg1
  def __repr__(self):
    return("opaq(%s)" % repr(self.arg1))

# Work around temporary problem in PyGuile.
def genopaq(arg):
  return(opaq(arg))

class noisydelete(object):
  def __init__(self,id):
    self.id = id
  def __del__(self):
    print "# Deleting class instance %s" % self.id
    #object.__del__()
  def __repr__(self):
    return(repr(self.id))
  def __cmp__(self,other):
    if ((self.id == "me") and (other.id == 42)):
      # Want to prove that this function has indeed been exercised.
      return(0)
    return(cmp(self.id,other.id))

# End of t5smobs.py
