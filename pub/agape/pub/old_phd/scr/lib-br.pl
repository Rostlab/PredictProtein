#! /usr/local/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    REQUIRES all PERL libraries (for old references).                         #
#                                                                              #
#------------------------------------------------------------------------------#
# 

require ("lib/br.pl")      || die "$0 failed on br.pl";
require ("lib/comp.pl")    || die "$0 failed on comp.pl";
require ("lib/file.pl")    || die "$0 failed on file.pl";
require ("lib/formats.pl") || die "$0 failed on formats.pl";
require ("lib/hssp.pl")    || die "$0 failed on hssp.pl";
require ("lib/molbio.pl")  || die "$0 failed on molbio.pl";
require ("lib/prot.pl")    || die "$0 failed on prot.pl";
require ("lib/scr.pl")     || die "$0 failed on scr.pl";

1;
