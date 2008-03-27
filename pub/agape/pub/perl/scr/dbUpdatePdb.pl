#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="updates the PDB version in /data/derived (RUN in work dir!!)";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Jul,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'dir_pdb',        "/data/pdb/",

#      'fasta_data',     "trembl",

      'exe_ln',         "/sbin/ln",

      'exe_pdb2fasta',  "/home/rost/perl/scr/pdb2fasta.pl",

      'exe_formatdb',   "/home/rost/molbio/bin/formatdb.SGI64", # formatdb -t title -p T -i file.fasta
      'exe_setdb',      "/home/rost/molbio/bin/setdb.SGI64",    # setdb -t title file.fasta

      'dir_blast',      "/data/blast/",			# 

#      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName auto'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file (pdb in fasta)";
#    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
#$fhin="FHIN";
$fhout="FHOUT";
$fileOut=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq "auto");
    if ($arg=~/^de?bu?g$/)                { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}
				# ------------------------------
				# list all PDB files:
				#    watch it: no find since link
				# ------------------------------
if (0){				# xx
$cmd="ls -1 ".$par{"dir_pdb"}."[1-9]*";
@file=`$cmd`;
				# write into file
$fileList="pdb.list";
unlink($fileList)               if (-e $fileList);
open($fhout,">".$fileList) || die "*** failed opening fileOut=$fileList\n";
foreach $file (@file){
    $file=~s/[\s\n]//g;
    print $fhout $file,"\n";
}
close($fhout);
				# ------------------------------
				# now extract sequences
				# ------------------------------
$fileOut="pdb"                  if (! $fileOut);
$cmd=$par{"exe_pdb2fasta"}." $fileList list fileOut=$fileOut";
print "--- $scrName: system '$cmd'\n" if ($Lverb || $Ldebug);
system("$cmd");
}
$fileOut="pdb";

				# ------------------------------
				# build BLAST binaries
				# ------------------------------
				# create the BLAST binaries
$cmd=$par{"exe_formatdb"}." -t pdb -p T -i $fileOut";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");
$cmd=$par{"exe_setdb"}." -t pdb $fileOut";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");

				# move binaries to blast
$dir=$par{"dir_blast"}."old/";
system("mkdir $dir")            if (! -d $dir);
    
$#fileOutBlast=0;
$tmp="pdb";
foreach $file ($tmp.".ahd",
	       $tmp.".atb",
	       $tmp.".bsq",
	       $tmp.".dat",
	       $tmp.".phr",
	       $tmp.".pin",
	       $tmp.".psq") {
    $fileOld=$par{"dir_blast"}.$file;
				# save old
    if (-e $fileOld){
	$cmd="\\mv $fileOld $dir";
	print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
	system("$cmd");
    }
				# now move new
    
    $cmd="\\mv $file $fileOld";
    print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
    system("$cmd");
    push(@fileOutBlast,$fileOld);
				# link
    if (-e $fileOld) {
	$cmd=$par{"exe_ln"}." -s $fileOld .";
	print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
	system("$cmd");
    }
}

print "--- blast binaries:",join(",",@fileOutBlast,"\n");
print "--- new fasta: $fileOut\n";
print "--- still move the entire directory to /data/derived/pdbSeq\n";

exit;


#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

