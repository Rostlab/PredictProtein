#!/usr/local/bin/perl -w
##!/usr/sbin/perl -w
##!/usr/pub/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="sends the PP result in HTML format as attachement";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
#

#$[ =1 ;

				# ------------------------------
				# defaults
%par=(
      'from', "predictprotein\@columbia.edu",
      'subj', "result from PredictProtein in HTML format (for WWW browser)",
      'text', "\nYou may display the file attached with your WWW browser (e.g. Netscape).",
      'smtp', "localhost",
      '', "",
      '', "",
      '', "",
      );

@kwd=sort (keys %par);

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file_with_result.html user'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","user",     "x",       "receiver of mail";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit(0);}
				# initialise variables
$fhin="FHIN"; # $fhout="FHOUT";

				# ------------------------------
				# libraries used
				# ------------------------------
#use lib '/home/$ENV{USER}/server/pub/perl';
#use QuotedPrint;

#use MIME::Base64;
#use Sendmail; # doesn't work with v. 0.74!

use MIME::QuotedPrint;
use Mail::Sendmail 0.75; # doesn't work with v. 0.74!
#require "/usr/share/lib/perl5/Mail/Sendmail.pm"; # doesn't work with v. 0.74!
#use Mail::Sendmail 0.75; # doesn't work with v. 0.74!

$fileHtml=$ARGV[0];
$fileHtmlName=$fileHtml; $fileHtmlName=~s/^.*\///g;

$user=    $ARGV[1];		# check!

				# ------------------------------
				# other arguments
foreach $arg (@ARGV) {
    next if ($arg eq $user ||
	     $arg eq $fileHtml);

    $Lok=0;
    foreach $kwd (keys %par) {
	next if (length($kwd)<1);
	if ($arg=~/$kwd=(.+)$/) {
	    $tmp=$1;
	    $Lok=1;
	    $par{$kwd}=$tmp;
	    $par{$kwd}=
		"\n\n".$par{$kwd} if ($kwd eq "text"); }
	last if ($Lok); }
    next if ($Lok);

    if ($arg=~/html/)    { $Lhtml=1;
			   next;}
    if ($arg=~/ascii/ ||
	$arg=~/^te?xt$/) { $Lhtml=0;
			   next;}
    print "*** unknown arg=$arg!\n";
    exit;}

				# ******************************
				#  hack: to me if no user!!
$user=    "liu\@cubic.bioc.columbia.edu" 
    if (! defined $user || $user !~/\@/ || $user=~/^(phd|predict)/);

%mail = (
	 SMTP    => $par{"smtp"},
	 from    => $par{"from"},
	 to      => $user,
	 subject => $par{"subj"},
	 );
        
#$message = encode_qp("Voilý le fichier demandÈ");
$message = encode_qp($par{"text"});

				# ------------------------------
				# paste in the HTML file
open($fhin, $fileHtml) or 
    die "Cannot read input HTML file ($fileHtml): $!";
$mail{"body"}="";
while (<$fhin>) {
    $mail{"body"}.= encode_qp($_);}
close ($fhin);

$boundary = "====" . time() . "====";
$mail{"content-type"} = "multipart/mixed; boundary=\"$boundary\"";

$boundary = '--'.$boundary;
$mail{"body"}=
    $boundary."\n".
    "Content-Type: text/plain; charset=\"iso-8859-1\"\n".
    "Content-Transfer-Encoding: quoted-printable\n".
    "Content-Disposition: inline\n".
    $message."\n".

    $boundary."\n".
    "Content-Type: text/html; charset=\"iso-8859-1\"; name=\"$fileHtmlName\"\n".
    "Content-Transfer-Encoding: quoted-printable\n".
    "Content-Disposition: attachment; filename=\"$fileHtmlName\"\n".

    $mail{"body"};


sendmail(%mail) || print "Error: $Mail::Sendmail::error\n";

exit(1);


#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
