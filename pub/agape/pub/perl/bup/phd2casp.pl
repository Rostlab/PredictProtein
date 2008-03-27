#!/usr/sbin/perl -w
#
# convert PHD .rdb_phd into CASP2 format
#
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<2){print"goal:   convert to CASP2 format NOTE: you HAVE to give NALIGN\n";
	      print"usage:  'script t000x.rdb_phd nalign'\n";
	      exit;}

$filePhd=$ARGV[1];$nalign=$ARGV[2];
$fhout="FHOUT";

$tNalign1=8;			# threshold in Nali for which ri=ri/10 +1
$tNalign2=3;			# threshold in Nali for which ri=ri/10
				# note: below take 1/2 ri
$numOfSubmission=1;		# number of predictions submitted before

$fileOut=$filePhd; $fileOut=~s/\.rdb.*$/\.abf1_casp2/g;
$name=substr($filePhd,1,5); if ($name !~/^t/){print"*** name should be 't0005'\n";}
$name=~s/^t/T/;


@desRdb=("body","AA","PHEL","RI_S","PREL","RI_A","Pbie");

%rd=
	&rd_rdb_associative($filePhd,@desRdb);

				# write file
&open_file("$fhout", ">$fileOut");
&wrtCasp2("$fhout",$name,$nalign,$tNalign1,$tNalign2,$numOfSubmission);
close($fhout);
				# screen
&wrtCasp2("STDOUT",$name,$nalign,$tNalign1,$tNalign2,$numOfSubmission);

print "x.x output in '$fileOut'\n";
exit;


#==========================================================================================
sub wrtCasp2 {
    local ($fhloc,$name,$nalignLoc,$tNalign1,$tNalign2,$numOfSubmission) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtCasp2                       
#         c
#       in:
#         A                     A
#       out:
#         A                     A
#--------------------------------------------------------------------------------

    print $fhloc 
	"From: rost\@EMBL-Heidelberg.DE\n",
	"To: submit\@sb7.llnl.gov\n",
	"Subject: prediction ABF1 ($name)\n",
	"FCC: /sander/purple1/rost/mail/OUT_CASP2\n",
	"--text follows this line--\n";

    print $fhloc 
	"PFRMAT ABF1\n",
	"TARGET $name\n",
	"AUTHOR 1252-9708-9879, Rost, EMBL, rost\@","embl-heidelberg.de \n",
	"REMARK Automatic usage of PHDsec and PHDacc\n",
	"REMARK AUTHOR:   B. Rost\n",
	"REMARK TITLE:    PHD: predicting 1D protein structure ",
	"REMARK TITLE:    by profile based neural networks\n",
	"REMARK JOURNAL:  Meth. in Enzym, 1996, 266, 525-539\n",
	"REMARK \n";
    if    ($nalignLoc>$tNalign1){$conf=0.72;}
    elsif ($nalignLoc>$tNalign2){$conf=0.70;}
    else                        {$conf=0.68;} 
    printf $fhloc "BEGDAT 1.1 %-2d %-3.1f\n",$numOfSubmission,$conf;
				# sec
    printf $fhloc "SS %6d\n",$rd{"NROWS"};
    foreach $it (1..$rd{"NROWS"}){
	$aa=$rd{"AA","$it"};
	$sec=$rd{"PHEL","$it"}; if ($sec eq "L"){$sec="C";}
	$ri=$rd{"RI_S","$it"};
	if    ($nalignLoc>$tNalign1){++$ri; $ri=$ri/10;}
	elsif ($nalignLoc>$tNalign2){$ri=$ri/10;}
	else                        {$ri=$ri/20;}
	printf $fhloc "%-1s  %-1s  %5.2f\n",$aa,$sec,$ri;}
				# acc
    printf $fhloc "ACC %6d\n",$rd{"NROWS"};
    foreach $it (1..$rd{"NROWS"}){
	$aa=$rd{"AA","$it"};
	$acc=$rd{"PREL","$it"};
	$ri=$rd{"RI_A","$it"};
	if    ($nalignLoc>$tNalign1){++$ri; $ri=$ri/10;}
	elsif ($nalignLoc>$tNalign2){$ri=$ri/10;}
	else                        {$ri=$ri/20;}
	printf $fhloc "%-1s  %-1s  %5.2f\n",$aa,$acc,$ri;}

    print $fhloc "ENDDAT 1.1\n";
    print $fhloc "END\n";
}				# end of wrtCasp2


