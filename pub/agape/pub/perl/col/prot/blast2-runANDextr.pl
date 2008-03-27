#!/usr/sbin/perl -w
#
#  runs BLASTP and extract from BLASTP output
#
$[ =1 ;
				# ------------------------------
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# initialise
				# set blast evnironment parameters
#system("setenv BLASTMAT /home/pub/molbio/blast/blastapp/matrix");
#system("setenv BLASTDB  /home/rost/pub/ncbi/db");
$ENV{'BLASTMAT'}="/home/pub/molbio/blast/blastapp/matrix";
$ENV{'BLASTDB'}= "/sander/purple1/rost/molbio/blast2/db";

$ARCH=$ENV{'ARCH'};

$exeBlast="/sander/purple1/rost/molbio/bin/blastall.".$ARCH;
$prog=    "blastp";
$parDb=   "pdb";
$parE=    "200000";
$parB=     "10000";

$fileBlast="blastOut-".$$.".tmp";
#$cmdBlast="$exeBlast -p $prog -d $parDb -F F -e $parE -b $parB -o $fileBlast";
$cmdBlast="nice $exeBlast -p $prog -d $parDb -F F -e $parE -b $parB -o $fileBlast";

				# ------------------------------
if ($#ARGV<2){			# digest input
    print"goal:   runs BLASTP2 and extracts output (only those in restrict.list into RDB)\n";
    print"usage:  script file.f restrict.list (pdb ids), e.g. FullDssp.list \n";
    print"        (or file_list, recognised by *.list)\n";
    print"option: =\n";
    die;}

$fileIn=   $ARGV[1];
$fileRestr=$ARGV[2];

$fhin="FHIN";$fhout="FHOUT";undef $fileOut;
				# options

				# ------------------------------
if ($fileIn!~/\.list/){		# single input file
    $fileIn[1]=$fileIn;}
else {				# or list?
    $#fileIn=0;
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\s//g;
		     next if (! -e $_);
		     push(@fileIn,$_);}close($fhin);}
				# ------------------------------
$#id=0;				# read restriction file
&open_file("$fhin", "$fileRestr");
while (<$fhin>) {$_=~s/\n//g;
		 $_=~s/^.*\///g; # purge path
		 $_=~s/_//g;	# purge _ chain
		 $_=~s/\!//g;	# purge exclamation mark
		 $_=~s/\..*$//g; # purge extension
		 if (length($_)>=4){
		     push(@id,$_);}}close($fhin);
				# store as logicals
foreach $id (@id){$id=~tr/[A-Z]/[a-z]/;
		  $ok{"$id"}=1;}
				# --------------------------------------------------
				# loop over all files
foreach $fileIn (@fileIn){	# --------------------------------------------------
    next if (! -e $fileIn);
    if (-e $fileBlast){		# security delete
	system("\\rm $fileBlast");}

    $cmd="$cmdBlast -i $fileIn -o $fileBlast";
    print "--- system \t '$cmd'\n";

    system("$cmd");		# RUN BLAST

				# name of final output file
    $fileOut=$fileIn;$fileOut=~s/^.*\///g;
    $fileOut=~s/\..*$//g;$fileOut.=".rdbBlast2";

    $fileIn=$fileBlast;		# ------------------------------
				# read BLAST
    &open_file("$fhin", "$fileIn");
    &open_file("$fhout",">$fileOut"); # write RDB file
    print $fhout "id\tide\tlen\tscore\tprob\n";

    while (<$fhin>) {
	last if ($_=~/^Sequences producing /);}
    $Lhead=0;			# header of BLAST
				# leaving with first line ' ' after those with 'pdb|..'
    while (<$fhin>) {$_=~s/\n//g;$tmp=$_;
		     if (!$Lhead && ($_=~/^pdb/)){
			 $Lhead=1;}
		     last if (($_!~/^pdb/)&&($Lhead));
		     next;}	# xx following skipped
    undef %res;$Lok=0;		# now ali
    $ctId=$ctOk=0;		# xx
    while (<$fhin>) {
	$_=~s/\n//g;
	last if ($_=~/^Parameters/);
	$line=$_;
	if ($line=~/^\>.*pdb\|/){
	    $tmpId=$line;$tmpId=~s/\>.*pdb\|[^|]*\|//g;$tmpId=~s/-//g;$tmpId=~s/\s.*$//g;
	    $tmpId=~tr/[A-Z]/[a-z]/;undef %res;
	    if (defined $ok{"$tmpId"}){$resId=$tmpId;
				       if (length($resId)>4){
					   $id2=substr($resId,1,4);$tmp=substr($resId,5,1);
					   $tmp=~tr/[a-z]/[A-Z]/;$id2.="_".$tmp;}
				       else {
					   $id2=$resId;}
				       $resId=$id2;++$ctOk;$Lok=1;}else{$Lok=0;}
	    ++$ctId; 
#	    print "xx 1 id=$tmpId, $Lok, $line,\n";
	}
	next if (!$Lok);
	next if ($line=~/^\>.*pdb/);

	if    (($line=~/^\s*Length = (\d+)/)&&
	       (! defined $res{"len"})){
	    $res{"len"}=$1;}
	elsif (($line=~/^\s*Score = \s*([0-9\.]+)\s[^,]*, Expect = \s*([0-9\.e\-]+).*$/)&&
	       (! defined $res{"score"})){
	    $res{"score"}=$1;$res{"prob"}=$2;}
#	    print "xx 2 id=$tmpId, score=$1, prob=$2, line=$line,\n";
#	    $res{"score"}=$score=$1;$res{"prob"}=$prob=$2;}
				# is the last line to get for current ID
	elsif (($line=~/^\s*Identities = \d+\/\d+ \((\d+)/)&&
	       (! defined $res{"ide"})){
	    $res{"ide"}=$1; 
#	    print "xx 3 id=$tmpId, ide=$1, score=$score, prob=$prob, line=$line\n";
				# ------------------------------
				# write the new output line
				# ------------------------------
	    foreach $fh ("$fhout","STDOUT"){
		print $fh $resId;
		foreach $des ("ide","len","score","prob"){
		    print $fh "\t",$res{"$des"};}print $fh "\n";}}
	else {
	    next;}}close($fhin);close($fhout);
    print "--- output in $fileOut, id=$ctId, taken=$ctOk\n";
}				# end of loop over all input files
				# --------------------------------------------------
$cmd="\\rm $fileBlast";print "xxx system \t '$cmd'\n";
system("$cmd");

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

