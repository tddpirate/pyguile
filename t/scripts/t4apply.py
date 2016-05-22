#!/usr/bin/python
# Auxiliary functions for exercising python-apply.
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

def return_args(*args,**kw):
  return("positional: %s      keywords: %s" % (repr(args),repr(kw)))

class cl1(object):
  def __init__(self,num=1,str="2"):
    self.num = num
    self.str = str

  def myfunc(self,arg="x"):
    return(arg + self.str)

class cl2(object):
  def __init__(self,num=3):
    self.num2 = num
    self.mycl1 = cl1(10,str="Twenty")

  def cl2func(self,argx="y"):
    return(str(self.num2) + argx)

mainobj = cl2(33)

# End of t4apply.py
