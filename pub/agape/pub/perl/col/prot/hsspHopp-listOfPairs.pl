#!/usr/sbin/perl -w
#
# list of pairs (hssp1,hssp2) will be searched for similar ids
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$par{"dirHssp"}="/data/hssp/";
$par{"extHssp"}=".hssp";

$fhin="FHIN";$fhout="FHOUT";

if ($#ARGV<1){print"goal:   list of pairs (hssp1,hssp2) will be searched for similar ids\n";
	      print"usage:  script rdb-file-with-pairs (and optional IDE,LALI)\n";
	      print"option: dirHssp=x, extHssp=.hssp\n";
	      exit;}
				# file there?
$fileIn=$ARGV[1];if (! -e $fileIn){$fileIn=$par{"dirHssp"}.$fileIn;}
if (! -e $fileIn){print"*** no $fileIn (file with HSSP families: id1\tswiss1,swiss2)\n";
		  die;}
@desRd=("ID1","ID2","IDE","DIS","WSIM","LEN1","LEN2","LALI","NGAP","LGAP");
				# --------------------------------------------------
				# read RDB file (ID1\tID2 optional: IDE\tLALI)
%rdb=&rdRdbAssociative($fileIn,"header","body",@desRd);

				# --------------------------------------------------
				# loop over all pairs
foreach $itPair (1..$rdb{"NROWS"}){
    $id1Rdb=$rdb{"ID1","$itPair"};$id1Rdb=~s/_.*$//g; # hack purge chain
    $id2Rdb=$rdb{"ID2","$itPair"};$id2Rdb=~s/_.*$//g; # hack purge chain
				# ------------------------------
    $#id1=0;%rd=%ok=0;		# read all names in guide file
    $file1=$par{"dirHssp"}.$id1Rdb.$par{"extHssp"};
    $file2=$par{"dirHssp"}.$id2Rdb.$par{"extHssp"};
    if (! -e $file1){print "*** HSSP 1:$file1, missing\n";$resCt[$itPair]=-1;
		     next;}
    if (! -e $file2){print "*** HSSP 2:$file2, missing\n";$resCt[$itPair]=-1;
		     next;}
    %rd=&hssp_rd_header($file1);
    $resCt[$itPair]=-1;
    if ($rd{"NROWS"}<1){$resCt[$itPair]=-1;
			next;}	# none found
				# digest all homologues
    foreach $it (1..$rd{"NROWS"}){
	$rd{"$it","ID"}=~s/\s+.*$//g; # delete possible 'lyn_rat 1nyf' 
	$rd{"$it","ID"}=~s/\d[A-Z0-9][A-Z0-9][A-Z0-9].*$//g; # delete possible 'lck_human1CWD_?' 
	if (length($rd{"$it","ID"})>4){
	    push(@id1,$rd{"$it","ID"});}}
    foreach $id1(@id1){		# ini res
	$ok{"$id1"}=1;}
    if ($#id1<1){$resCt[$itPair]=-1;
		 next;}		# none found
#    print "--- $file1: ids read ($fileIn): ";foreach $id1(@id1){print "$id1,";}print"\n","--- 2=$file2\n"; # xx
				# ------------------------------
				# read names in to-be-checked-file
    %rd=0;%rd=&hssp_rd_header($file2);
    $idFile2=$file2;$idFile2=~s/^.*\///g;$idFile2=~s/\.hssp.*$//g;
    $ctOverlapp=0;%ok2=0;
    foreach $it (1..$rd{"NROWS"}){
	$rd{"$it","ID"}=~s/\s+.*$//g; # delete possible 'lyn_rat 1nyf' 
	$rd{"$it","ID"}=~s/\d[A-Z0-9][A-Z0-9][A-Z0-9].*$//g; # delete possible 'lck_human1CWD_?' 
	$id2=$rd{"$it","ID"};
	next if (length($rd{"$it","ID"})<4);	# wrong id
	next if (! $ok{"$id2"}); # not in HSSP1
	next if ( $ok2{"$id2"}); # avoid counting twice
	$ok2{"$id2"}=1;++$ctOverlapp;}
    $resCt[$itPair]=$ctOverlapp;$resPerc[$itPair]=100*($ctOverlapp/$#id1);
}
				# --------------------------------------------------
				# print output
$fileOut="Out-".$fileIn;
&open_file("$fhout",">$fileOut"); 
print $fhout "# Perl-RDB\n#\n";

@fh=("$fhout","STDOUT");
#@fh=("STDOUT");
				# header
foreach $fh(@fh){
    foreach $des ("ID1","ID2","IDE","LALI","DIS"){
	if (defined $rdb{"$des","1"}){print $fh "$des\t";}}
    printf $fh "%4s\t%5s","Npair","Ppair";
    foreach $des ("WSIM","LEN1","LEN2","NGAP","LGAP"){
	if (defined $rdb{"$des","1"}){print $fh "\t$des";}}print $fh "\n";}
				# numbers
print $fhout " \n";		# hack

foreach $itPair (1..$rdb{"NROWS"}){
    foreach $fh(@fh){
	foreach $des ("ID1","ID2","IDE","LALI","DIS"){
	    if (defined $rdb{"$des","1"}){print $fh $rdb{"$des","$itPair"},"\t";}}
	if (! defined $resCt[$itPair]){
	    print $fh "00\t000";}
	elsif ($resCt[$itPair] == -1){
	    print $fh " \t ";}
	else {
	    printf $fh "%4d\t%5.1f",$resCt[$itPair],$resPerc[$itPair];}
	foreach $des ("WSIM","LEN1","LEN2","NGAP","LGAP"){
	    if (defined $rdb{"$des","1"}){print $fh "\t",$rdb{"$des","$itPair"};}}
	print $fh "\n";}}
close($fhout);

if (-e $fileOut){print "output in $fileOut\n";}
    
exit;
