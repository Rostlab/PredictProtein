#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs BLASTP against PRODOM and extracts output\n";
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# defaults
$ARCH=$ENV{'ARCH'};

%Arch_exeBlastp=		# blast exe
    ('SGI64',           "/usr/pub/bin/molbio/blastp",
     'ALPHA',           "/usr/pub/bin/molbio/blastp");

%parProDom=
    ('parProBlastDb',   "/home/rost/pub/ncbi/db/prodom_34_2", # database to run BLASTP against
     'parProBlastN',    "500",
     'parProBlastE',    "0.1", # E=0.1 when calling BLASTP (PRODOM)
     'parProBlastP',    "0.1", # probability cut-off for PRODOM
     'exeBlastp',        $Arch_exeBlastp{$ARCH},

     'envBlastmat',       "/home/pub/molbio/blast/blastapp/matrix",
     'envBlastdb',        "/home/rost/pub/ncbi/db/",
     );
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file.f'\n";
    print "opt: \t fileOut=x\n";
    foreach $kwd (keys %parProDom){
	print "     \t $kwd=",$parProDom{"$kwd"}," (default)\n";}
#    print "     \t \n";
    exit;}
				# ------------------------------
				# read command line
$fileIn=   $ARGV[1];
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    $Lok=0;
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1; $Lok=1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {
	foreach $kwd (keys(%parProDom)){
	    if ($_=~/^$kwd=(.*)$/){$Lok=1;
				   $parProDom{"$kwd"}=$1;}}}
    if (! $Lok){print"*** wrong command line arg '$_'\n";
		die;}}
				# existence check
die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# run BLAST
$jobId=$$;
$jobId=11;			# xx
$fileProdomTmp="PRODOM.blast-".$jobId;
if (! defined $fileOut){
    $fileProdom=   "PRODOM.out-".$jobId ;}
else {$fileProdom=$fileOut;}
    
($Lok,$msg)=
    &prodomRun($fileIn,$fileProdomTmp,$fileProdom,"STDOUT",
	       $parProDom{"exeBlastp"},$parProDom{"envBlastdb"},$parProDom{"envBlastmat"},
	       $parProDom{"parProBlastDb"},$parProDom{"parProBlastN"},
	       $parProDom{"parProBlastE"}, $parProDom{"parProBlastP"});

print "--- output in $fileProdom\n";
exit;

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         $fhoutLoc             file handle print output
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileLoc!")          if (! defined $fileLoc);

    return(0,"*** $sbrName: miss in file '$fileLoc'!")  if (! -e $fileLoc);

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print $fhErrSbr "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

