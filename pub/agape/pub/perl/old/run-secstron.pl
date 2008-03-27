#! /usr/sbin/perl
#----------------------------------------------------------------------
# perl script to run the PHD server
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: "phd-server file"
#
# procedures:					files generated:
#
#
#----------------------------------------------------------------------#
#	Burkhard Rost			October,	1993           #
#	Reinhard Schneider	change:			1993	       #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1               (rost@EMBL-Heidelberg.DE)      #
#	D-69117 Heidelberg		(schneider@EMBL-Heidelberg.DE) #
#----------------------------------------------------------------------#

push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; $date = join(':',@Date) ;

$path 		= $ENV{'PATH'} ;
$ARCH   	= $ENV{'CPUARC'} ;

#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;
$arg_given = 1;

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < $arg_given) { print "ERROR: number of arguments should be: \n", " \t \t $arg_given \n", "it is: \t \t  \t$ARGV \n"; "with arg1 = job_id and arg2 = number of cycles (optional) \n"; exit; }

#------------------------------
# read argument 1
#------------------------------

$job_id     	= $ARGV[1] ;
$beg_job_id	= substr($job_id,1,3); 
$set1     	= "252xa";
$set2     	= "252xb";
$make_file	= "/zinc2/rost/secstron/prog/make.$ARCH";
$secstron	= "$job_id" . ".$ARCH" ;
$secstron0	= "x.x" ;

if ( $#ARGV == 2 ) { 	$numcycle = $ARGV[2]; 
} else { 		$numcycle = 5; }

&assign_names;
&myprt_line; &myprt_txt("executables: \t $secstron0"); &myprt_txt("\t and: \t\t $secstron "); &myprt_empty;
&myprt_txt("run secstron for:\t $job_id"); 
&myprt_txt("old file: \t\t $dat6_old ");
&myprt_txt("new     : \t\t $dat6_newa "); &myprt_txt("\t and: \t\t $dat6_newb");
&myprt_empty; myprt_empty; &myprt_line; &myprt_empty; myprt_empty; 
&myprt_txt("note: an executable *0 is needed for the first cycle"); &myprt_empty; &myprt_empty; 
print "--- \n" x 2, "-" x 70, "\n", "--- \n" x 2;

#--------------------------------------------------
#  exists executable ? if not: make file
#--------------------------------------------------
   $executable = $secstron0;
   if ( ! -e $executable ) {
      &myprt_txt("executable doesnot exist: \t $executable");
      exit;
#      &make_executable ($make_file, $executable);
   }

   $executable = $secstron;
   if ( ! -e $executable ) {
      &myprt_txt("executable doesnot exist: \t $executable");
      exit;
#      &make_executable ($make_file, $executable);
   }
   print " --- \n";

#--------------------------------------------------
#   run secstron
#--------------------------------------------------

   $count	= 0;
   while ( $count < $numcycle ) {
      ++$count;
      print " ", "-" x 70, "\n", " --- \n";
      print " --- running secstron for list $set1 \t round: \t $count \n", " --- \n";

      if ( $count == 1 ) {
         eval "\$command=\"$secstron0 $set1 >> $job_id\"" ; 
         &run_program ("$command") ;
##         eval "\$command=\"rm -f $secstron0\"" ; &run_program ("$command") ; 
      } else {
         eval "\$command=\"$secstron $set1 >> $job_id\"" ; 
         &run_program ("$command") ;
      }

#      if ( $beg_job_id eq "snd" ) {
#         eval "\$command=\"rm -f $dat6_old\"" ; &run_program ("$command") ; 
#      } else {
#         eval "\$command=\"cat < $dat6_old >> $dat6_newa\"" ; &run_program ("$command") ;
#      }

#----------------------------------------
#     cp A6.DAT to 252a...A6.DAT      
#----------------------------------------
      print "cp: \t\t $dat6_old \n"; print "to: \t\t $dat6_newa \n"; 
      system("\\cp $dat6_old $dat6_newa");

      print " ", "-" x 70, "\n", " --- \n";
      print " --- running secstron for list $set2 \t round: \t $count \n", " --- \n";

      if ( $count == 1 ) {
         eval "\$command=\"$secstron $set2 >> $job_id\"" ; 
         &run_program ("$command") ;
      } else {
         eval "\$command=\"$secstron $set2 >> $job_id\"" ; 
         &run_program ("$command") ;
      }

#      if ( $beg_job_id eq "snd" ) {
#         eval "\$command=\"rm -f $dat6_old\"" ; &run_program ("$command") ; 
#      } else {
#         eval "\$command=\"cat < $dat6_old >> $dat6_newb\"" ; &run_program ("$command") ;
#      }

#----------------------------------------
#     cp A6.DAT to 252a...A6.DAT      
#----------------------------------------
      print "cp: \t\t $dat6_old \n"; print "to: \t\t $dat6_newb \n"; 
      system("\\cp $dat6_old $dat6_newb");


   }
   exit;


#======================================================================
#    sub: make executable
#======================================================================

sub make_executable {
    local ($make_file, $executable) = @_;

    print " ", "-" x 70, "\n", " --- \n";
    print " --- make executable $executable from make: $make_file \n";

    eval "\$command=\"make -f $make_file\"" ; &run_program ("$command") ;
    if ( -e $ARCH.tmp ) {
       &run_program("mv $ARCH.tmp $executable");
    } else { print "ERROR in making $executable from make: $make_file \n"; exit; }
}

#======================================================================
#    sub: assign name
#======================================================================

sub assign_names {
    local ($tmp, $tmp0, $Lstop);

    $xjob_id	= "$job_id";
    if ( substr($job_id,1,3) eq "fst" ) {
	$xjob_id	=~ s/fst252x-|fst252-//g;
	$dat6_old	= "F252x-" . "$xjob_id" . "-A6.DAT";
	$dat6_newa	= "F252xa-" . "$xjob_id" . "-A6.DAT";
	$dat6_newb	= "F252xb-" . "$xjob_id" . "-A6.DAT";
    } else {
	$xjob_id	=~ s/snd252x-|snd252-//g;
	$xjob_id	=~ s/(15pc.+)-252/$1/g;
	$dat6_old	= "S252x-" . "$xjob_id" . "-A6.DAT";
	$dat6_newa	= "S252xa-" . "$xjob_id" . "-A6.DAT";
	$dat6_newb	= "S252xb-" . "$xjob_id" . "-A6.DAT";
    }
    print "\n"; 
    $tmp  = $dat6_old; $tmp =~ s/-A6/-A1/;
    $tmp0 = $secstron . "0";

    if ( -e $tmp  ) {
	$secstron0 = $secstron;
    } elsif ( -e $tmp0 )  {
	$secstron0 = $tmp0;
    } else {
	print "*** trouble making executable for 0'th cycle: \n";
	print "*** either executable not existing or file '-A1.DAT' \n";
	$Lstop = "True";
    }
    print "\n"; 
    print "\n"; 
    print "executable 0: \t $secstron0 \n"; print "executable 1: \t $secstron \n";  
    print "\n"; print "job_id: \t $job_id \n"; print "\n"; 
    print "mv: \t\t $dat6_old \n"; print "to: \t\t $dat6_newa \n"; 
    if ( $Lstop =~ /T/ ) {
	exit;
    }
#    exit;

}

