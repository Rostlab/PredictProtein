#!/usr/bin/perl -w
##!/usr/sbin/perl 
#----------------------------------------------------------------------
# greps for time asf in output of secstron
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"chophssp.pl file.hssp"
#
# task:		chopping the profiles off from appended hssp file
# 		besides: grep for swissprot release number
#
#----------------------------------------------------------------------
#                                                                      #
#----------------------------------------------------------------------#
#	Burkhard Rost			October,	1993           #
#			changed:		,      	1993           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {
   die "*** ERROR: \n*** usage: \tchophssp.pl file \n";
   print "number of arguments:  \t$ARGV \n";
}

#------------------------------
# read argument 1
#------------------------------
$file_in = $ARGV[1];
print "-" x 70, "\n";
print "--- \n";
print "--- summary for the secstron run: \n";
print "--- \n";
print "--- input file: \t $file_in \n";
print "--- \n";
print "-" x 70, "\n";
print "--- \n";
print "--- \n";
print "  	     time      Q3      Q      QH   QE   QC   CorrH  CorrE  CorrC error     d=o=1\n";
print "\n";

#------------------------------
# check existence of file
#------------------------------
if ( ! -e $file_in ) {
   print "--- \n";
   print "--- INFO: \t file $file_in does not exist \n";
   print "--- \n";
}

#--------------------------------------------------
# open files
#--------------------------------------------------

open(FILEIN,$file_in) || warn "Can't open $file_in: $!\n";

$count	=0;
$lres 	= "False";
$c2	=0;
while ( <FILEIN> ) {
   if ( m,/zinc2/rost/data/List253x.-train, ) {
      $tmp = $_;
      $tmp =~ s/(list of train chains:)//;
      $tmp =~ s/[\s]|\/|zinc2|rost|data|List|-train//g;
#      ++$count;
#      print "$count: \t $tmp \n";
#      push(@set,$tmp);
   }
   if ( /(helix \(H,I,G\):    34.49)/ ) {
      $setx = "252x a ";
   }
   if ( /(helix \(H,I,G\):    31.91)/ ) {
      $setx = "252x  b";
   }
   if ( /(time      Q3      Q      QH   QE)/ ) {
      ++$count;
      $lres = "True";
   } elsif ( $lres eq "True" ) {
      if ( /^( ---)/ ) { $lres = "False" ; $c2 = 0;
      } elsif ( /[0.0]/ ) {
         s/^(      )//;
         ++$c2;
         if ( $c2 > 1 ) {
            printf "%11s %s", " ", " $_ ";
         } else {
            printf " %2d %7s %s", $count, "$setx", "$_";
         }
      }
   }
}
print  "--- \n";
print  "-" x 70, "\n";
exit;
