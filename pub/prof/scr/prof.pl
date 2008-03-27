#!/usr/bin/perl
##!/usr/bin/perl -w
##!/bin/env perl
##!/usr/sbin/perl -w
##!/usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@columbia.edu	       #
#	Wilckensstr. 15		http://cubic.bioc.columbia.edu/ 	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Aug,    	1998	       #
#				version 2.0   	Oct,    	1998	       #
#				version 2.1   	Dec,    	1999	       #
#				version 2.2   	Mar,    	2000	       #
#------------------------------------------------------------------------------#

# ---------------------------------------------------------------------------- #
# change to port (install) program:                                            #
# ---------------------------------------------------------------------------- #
                                # -------------------------------------
				# directory where you find prof.tar
				# before doing the install 
				# e.g. /home/you/
$par{"dirHome"}=                "/nfs/data5/users/ppuser/server/pub/";
                                # -------------------------------------
				# final directory with PROF 
                                # resulting from 'tar -xvf prof.tar'
$par{"dirProf"}=                 $par{"dirHome"}. "prof/";
                                # -------------------------------------
				# architecture to run PROF 
				# e.g. SGI32|SGI64|ALPHA|SUNMP|MAC|LINUX
#$ARCH_DEFAULT=                  "SGI32";
$ARCH_DEFAULT=                  "LINUX";
$ARCH_DEFAULT=                  "LINUX";
$ARCH_DEFAULT=                  "LINUX";
				# ------------------------------
				# configurations for PROF
$par{"confProf"}=               $par{"dirProf"}.  "scr/CONFprof.pl";
				# ------------------------------
				# package running PROF
$par{"packProf"}=               $par{"dirProf"}.  "scr/lib/prof.pm";
#
# see sbr iniDef for further parameters
# --------------------------------------------------
#
#------------------------------------------------------------------------------#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "neural network switching";
$scrIn=      "list_of_files (or single file) parameter_file";
$scrNarg=    2;                  # minimal number of input arguments

$okFormIn=   "hssp,dssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,swiss";
$scrHelpTxt= "Input file formats accepted: \n";
$scrHelpTxt.="      ".  $okFormIn."\n";

#  - xx: allow to input directly to FORTRAN input vectors!!!  (currently, input must be nndb.rdb)
#    xx: i.e. change (b)+(c) for (1) and (2)!

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# specific information about mode
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# all specific interpretation should be covered by:
#  MAIN:
#  - iniDef
#  - iniDefNet
#  - iniInterpret
#    in particular the latter should contain all job-specific settings
#  LIB (lib-nn):
#  - get_ri           : compiles rel index from @out
#  - 
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# build input to 2nd level:
#    file_<trn|tst|val>_out.dat: will automatically detect modetvt:
#        trn-> train, tst-> test, val-> validate
#   + fileTransl-from-previous run 
#   + nn.defaults
#    
# 
# 
# TO DO:
# 
#  - allow to input directly to FORTRAN input vectors!!!  (currently, input must be nndb.rdb)
#  
#  - fill in for sparse alignments (doCorSparse)
#  - 
#  
#  - handle many network input
#  - speed up for single input files
# 
#    **************************************
#  - dissect HSSP automatically into chains
#    **************************************
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  
#  - $par{"kwd"}  : global parameters, available on command line by 'kwd=value'
# 
#
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dependencies
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#                               ---------------------
#   nn                          internal subroutines:
#                               ---------------------
#
# 
#                               ---------------------
#   nn                          external subroutines:
#                               ---------------------
#
#   call from lib-nn:           dbgWrtPar,is_nnDefaults,is_nnTranslate,is_nnTvtId,nn_defRd
#                               nn_tvtIdRd
#   
#   call from lib-br:           brIniGetArg,brIniHelpLoop,errSbr,errSbrMsg,fileListRd
#                               getFileFormatQuick,is_chain,is_nndb_rdb,is_nninFor
#                               open_file,rdRdbAssociative
#   
#   call from lib-ut:           sysDate
#
#
#------------------------------------------------------------------------------#

$[ =1 ;				# sets array count to start at 1, not at 0

				# ------------------------------
				# search package
if (! -e $par{"packProf"} && ! -l $par{"packProf"}){
    $tmp=$0;  $tmp=~s/\.pl$/.pm/;
    if (! -e $tmp && ! -l $tmp){
	$tmp1=$tmp; $tmp1=~s/^.*\///g;
	$par{"dirProf"}.="/"     if ($par{"dirProf"} !~/\/$/);
	$tmp1=$par{"dirProf"}.$tmp1;
	$tmp=$tmp1;}
    if (! -e $tmp && ! -l $tmp){
	print 
	    "*** ERROR $scrName: could NOT find 'packProf'!\n",
	    "    default is=",$par{"packProf"},"!\n",
	    "    please change this in the top of the file $0!\n",
	    "    note: possible locations are in the prof directory (DIR_PROF):\n",
	    "          DIR_PROF/scr/lib/prof.pm \n",
	    "    or    DIR_PROF/scr/prof.pm \n",
	    "    or    .... :-( sorry no idea what else ... \n";
	exit;}
    $par{"packProf"}=$tmp;}
				# ------------------------------
				# use package
$Lok=require($par{"packProf"});
if (! $Lok){
    print "*** ERROR $scrName: failed to require package packProf=",$par{"packProf"},"!\n";
    exit; }

				# ------------------------------
				# run PROF
($Lok,$msg)=
    &prof::full($par{"dirHome"},$par{"dirProf"},$par{"confProf"},$ARCH_DEFAULT,
		   $scrName,$scrGoal,$scrIn,$scrNarg,$okFormIn,$scrHelpTxt,
		   @ARGV);

if (! $Lok){
    print 
	"*** ERROR $scrName: after package prof:full (",$par{"packProf"},")\n",
	$msg,"\n";
    exit;}

exit;

