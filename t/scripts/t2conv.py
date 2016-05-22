#!/usr/bin/python
# Basic tests to validate conversions from Python to Guile and vice versa.
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

def return_None():
  return None

def return_True():
  return True

def return_False():
  return False

def return_Int1():
  return 1

def return_Int_5():
  return(-5)

def return_BigInt():
  return(1048576*1048576*1048576*32)

def return_BigInt_neg():
  return(-1048576*1048576*1048576*32)

def return_String1():
  return("abcdefghi")

def return_String2():
  return("01abCD%^")

def return_String_Zero():
  return("bef" + chr(0) + chr(163) + "ore")

if (__name__ == '__main__'):
  print "return_None: ",return_None()
  print "return_True: ",return_True()
  print "return_False: ",return_False()
  print "return_Int1: ",return_Int1()
  print "return_Int_5: ",return_Int_5()
  print "return_BigInt: ",return_BigInt()
  print "return_BigInt_neg: ",return_BigInt_neg()
  print "String1: ",return_String1()
  print "String2: ",return_String2()
  print "String_Zero: ",return_String_Zero(),repr(return_String_Zero())

# End of t2conv.py
