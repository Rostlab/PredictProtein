#!/usr/sbin/perl -w
#
#  reads the file SwIdNo-hssp849-40.list (from hsspIdeList2No-hack.pl)
#  and compiles big matrix i x i with M(i,j) = no of ids in common
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print "goal:   reads the file SwIdNo-hssp849-40.list (from hsspIdeList2No-hack.pl)\n";
	      print "        and compiles big matrix i x i with M(i,j) = no of ids in common\n";
	      print "usage:  script SwIdNo-hssp849-40.dat \n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$Lverb= 1;
$Lverb2=0;
$Lverb2=1;

$fileOut="Matrix-".$fileIn;$fileOut=~s/[sS]w[iI]d2[nN][ou]/cross/g;
				# ------------------------------
				# read file
&open_file("$fhin", "$fileIn");
$#id=$#swiss=0;
if ($Lverb){print "--- reading $fileIn\n";}
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
		 next if (/^\#|^id/);
		 $_=~s/,+/,/g;
		 @tmp=split(/\t/,$_);
		 next if (! defined $tmp[2]);
		 next if (length($tmp[2])==0);
		 if ($Lverb2){print "--- read for \t $tmp[1]\n";}
		 $tmp[1]=~s/\s//g;$tmp[2]=~s/\s//g;
		 next if ((length($tmp[1])<5)||(length($tmp[2])<5));
		 push(@id,$tmp[1]);push(@swiss,$tmp[2]);}close($fhin);
$#tmp=0;
if ($Lverb){print "--- after reading $fileIn\n";}
				# ------------------------------
				# each with each
				# --------------------
foreach $it1 (1..$#id){		# loop over rows
    next if (!defined $swiss[$it1]);
    @tmp1=split(/,/,$swiss[$it1]); # all swiss for it1
    %ok=0;foreach $tmp1(@tmp1){$ok{"$tmp1"}=1;}	# store logicals
				# --------------------
    foreach $it2 (1..$#id){	# loop over columns
	next if (!defined $swiss[$it2]);
	@tmp2=split(/,/,$swiss[$it2]); # all swiss for it2
	$ct=0;
	foreach $tmp2(@tmp2){
	    if (defined $ok{"$tmp2"}){++$ct;}}
	$res{"$id[$it1]","$id[$it2]"}=$ct;}
    $#tmp1=$#tmp2=0;%ok=0;
    if ($Lverb2){print "--- store res after \t it1=$it1 ($id[$it1])\n";}
}
				# ------------------------------
				# now write matrix
&open_file("$fhout",">$fileOut"); 
print $fhout "\# NUMBER OF ROWS: ",$#id,"\n";
print $fhout "\# ALL IDS       : ";
foreach $id (@id){print $fhout "$id,";}print $fhout "\n";
print $fhout "id1\tid2\tN in both\n";
foreach $it1 (1..$#id){		# loop over rows
    foreach $it2 (1..$#id){	# loop over columns
				# skip zero counts
	next if ($res{"$id[$it1]","$id[$it2]"}==0);
	next if ($it2 == $it1);	# only off-diagonal!
				# skip: identical protein, different chain
	next if (substr($id[$it1],1,4) eq substr($id[$it2],1,4));

	print $fhout $id[$it1],"\t",$id[$it2],"\t",$res{"$id[$it1]","$id[$it2]"},"\n";}
    if ($Lverb2){print "--- write after it1=$it1, id=$id[$it1]\n";}
}
close($fhout);

print "--- output in $fileOut\n";
exit;
