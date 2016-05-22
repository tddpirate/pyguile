# pyguile
Invoke Python libraries from Guile

## Introduction
This is PyGuile, a library for running Python code within Guile scripts.

## Background
One of the problems, which less popular scripting languages encounter,
is the lack of libraries for performing various operations.
Most frequently, those libraries are available - but for another scripting
language.

As a first step to alleviate this problem, PyGuile allows scripts written
in Scheme and executed by Guile to invoke Python libraries.  This makes
the rich library ecosystem of Python available also to Guile users.

Blog articles about the package and the philosophy guiding it:
http://www.zak.co.il/tddpirate/category/pyguile/

## Audience
If you think that Scheme is the best programming language in which to
implement your application, but you are held back due to lack of libraries
for performing certain operations, then PyGuile may be the answer for
you.

## Building
See INSTALL for a description of how to build and install this library.

### Note
The initial version has not been maintained since 2008 and will probably not work with modern versions of Guile.

## Executable
There is no executable in this package.  To run it, just run guile and
execute the (use-modules (pyguile)) command.
