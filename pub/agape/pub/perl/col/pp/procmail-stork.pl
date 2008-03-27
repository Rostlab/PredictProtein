#!/usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				  Apr,    	 1998	       #
#	Burkhard Rost 		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			        v 1.0   	  Apr,           1998          #
#------------------------------------------------------------------------------#
#
# processes the procmail output (activated by /home/phd/server/scr/procmail.rc)
# NOTE: this script only write the info into a file HARD_CODED
#
#----------------------------------------------------------------------#
$dirWork= "/home/phd/server/inProc/"; # HARD_CODED
$scrNext= "/home/phd/server/scr/procmail.pl"; # HARD_CODED
$machine= "phenix";		# HARD_CODED

$fileTrace="/home/phd/server/log/procmail-in.log"; # HARD_CODED

$fileOut=  $dirWork. $$ . ".procmail-in"; # HARD_CODED
$fhout=    "FHOUT";
				# --------------------------------------------------
$#line=0;			# read, and write information
while (<>) {$_=~s/\n+$//g;
	    next if (! defined $_ || length($_)<1);
	    push(@line,$_);}
				# --------------------------------------------------
open ("$fhout",">$fileOut");	# write output
foreach $_(@line){next if (! defined $_);
		  print $fhout "$_\n";}close($fhout);

if (! -e $fileOut){system("echo 'no fileOut=$fileOut from procmail-stork.pl' >> $fileTrace");
		   die;}
exit;
				# ------------------------------
				# rsh on phenix
				# ------------------------------
system("rsh $machine '$scrNext $fileOut' ");
				# trace
system("echo 'procmail-stork.pl: rsh $machine $scrNext $fileOut' >> $fileTrace"); # xx
exit;

