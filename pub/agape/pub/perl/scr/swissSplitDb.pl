#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="\n";
$scrGoal="splits SWISS-PROT.swiss db files into one per id one\n".
    "     \t note: by default output is of form 'c/paho_chick'\n".
    "     \t       if NOT id_species (e.g. TREMBL): take first letter\n".
    "     \t \n".
    "     \t ";
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
#  
#  
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file_swiss' (or *swiss)\n";
    print "opt: \t \n";
    print "     \t fileOut=x   (default id_species -> id[1..n]_species)\n";
    print "     \t dirOut=x    (default local)\n";
    print "     \t nodirsplit  all files written into one single directory!\n";
#    print "     \t \n";
    foreach $kwd (keys %par){
	print "     \t $kwd=",$par{"$kwd"}," (def)\n";}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";

				# ------------------------------
$#fileIn=0;			# read command line
$dirOut="";
$LdirSplit=1;
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut=         $1;}

    elsif ($arg=~/^nodir.*$/i)            { $LdirSplit=      0;}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif($arg=~/^=(.*)$/){$=$1;}

    else {$Lok=0;
	  if (-e $arg){$Lok=1;
		       push(@fileIn,$arg);}
	  if (! $Lok && defined %par){
	      foreach $kwd (keys %par){
		  if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					     last;}}}
	  if (! $Lok){print"*** wrong command line arg '$arg'\n";
		      die;}}}
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;
$dirOut.="/"                    if (length($dirOut)>1 && $dirOut !~/\/$/);
				# ------------------------------
				# (1) read files
$ctfileout=0;
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    open($fhin, $fileIn) || die ("*** $scrName: failed to open fileIn=$fileIn!\n");
    $#tmp=0;
    while (<$fhin>) {
	push(@tmp,$_);
				# first line: id 
	if    ($_=~/^ID \s*(\S+)/){
	    $id=$1;}
	elsif ($_=~/^\/\//){	# last line: end reading THIS protein
	    $id=~tr/[A-Z]/[a-z]/;
				# swissprot
	    if    ($LdirSplit && $id=~/\w\_\w/){
		$tmp=$id;
		$tmp=~s/^[^\_]+\_(.).*$/$1/;
		$dir=$dirOut.$tmp;}
				# trembl
	    elsif ($LdirSplit){
		$tmp=substr($id,1,1);
		$dir=$dirOut.$tmp;}
				# no splitting of directories: all into one!
	    else{
		$dir=$dirOut;}
				# mkdir if missing
	    if (! -d $dir){
		$cmd="mkdir $dir";
		print "--- $scrName: system '$cmd'\n" if ($Lverb);
		system("$cmd");}
	    $dir.="/"           if ($dir!~/\/$/);
	    $fileOut=$dir.$id;
	    ++$ctfileout;
	    open($fhout,">".$fileOut) || die "*** $scrName ERROR creating fileOut=$fileOut!";
	    foreach $tmp (@tmp){
		print $fhout $tmp;
	    }
	    close($fhout);
	    print "--- $scrName: wrote ",$ctfileout," fileout=$fileOut!\n" if ($Lverb);
	    $#tmp=0;}
    }
    close($fhin);

}

print "--- output in $fileOut\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
