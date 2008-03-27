#!/usr/bin/perl -- -*- C -*-

# This is the minimalist script to demonstrate the use of 
# the cgi-lib.pl library
# Copyright (C) 1994 Steven E. Brenner  
# $Header: /cys/people/seb1005/http/docs/web/RCS/minimal.cgi,v 1.1 1994/06/28 23:06:02 seb1005 Exp $

require "/home/schneide/perl/cgi-lib.pl";

if (&MethGet) {
  print &PrintHeader,
       '<form method=POST><input type="submit"> Data: <input name="myfield">';
} else {
  &ReadParse(*input);
  print &PrintHeader, &PrintVariables(%input);
}




