#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="updates version of big /data/derived/big (RUN in work directory!!)";
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
      '', "",			# 
      'trembl',          0,
      'pdb',             0,
      'swiss',           0,
      'fasta_pdb',       "/data/derived/pdbSeq/pdb.fasta",
      'fasta_trembl',    "/data/trembl/trembl",
      'fasta_swiss',     "/data/swissprot/swiss",
      'fasta_big',       "/data/derived/big/big",

#      'index_pdb',       "/data/derived/big/INDEX.splitPdb",
#      'index_swiss',     "/data/derived/big/INDEX.splitSwiss",
#      'index_trembl',    "/data/derived/big/INDEX.splitTrembl",
      'index_pdb',       "INDEX.splitPdb",
      'index_swiss',     "INDEX.splitSwiss",
      'index_trembl',    "INDEX.splitTrembl",

      'exe_gzip',       "/usr/sbin/gzip",
      'exe_gunzip',     "/usr/sbin/gunzip",
      'exe_ln',         "/sbin/ln",

      'exe_formatdb',   "/home/rost/molbio/bin/formatdb.SGI64", # formatdb -t title -p T -i file.fasta
      'exe_setdb',      "/home/rost/molbio/bin/setdb.SGI64",    # setdb -t title file.fasta

      'dir_blast',      "/data/blast/",			# 

      '', "",			# 
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
#    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
#    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",      "no value", "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value", "no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value", "verbose";
    printf "%5s %-15s %-20s %-s\n","","swiss",    "no value", "update swissprot";
    printf "%5s %-15s %-20s %-s\n","","trembl",   "no value", "update trembl";
    printf "%5s %-15s %-20s %-s\n","","pdb",      "no value", "update pdb";
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
$fhin="FHIN";
$fhout="FHOUT";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq "auto");
    if ($arg=~/^de?bu?g$/)                { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^pdb$/i)                { $par{"pdb"}=     1;}
    elsif ($arg=~/^swiss$/i)              { $par{"swiss"}=   1;}
    elsif ($arg=~/^trembl$/i)             { $par{"trembl"}=  1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileBigNew="big";
unlink($fileBigNew)             if (-e $fileBigNew);

foreach $kwd ("pdb","swiss","trembl") {
				# file existing?
    $file=$par{"fasta_".$kwd};
    if (! -e $file){
	print "*** ERROR db=$kwd, fileFasta=$file, missing!\n";
	exit;}
				# trembl: change id first
    if ($kwd eq "trembl"){
	$fileTremblTmp="trembl_".$$.".tmp";
	$fhoutSbr="STDOUT"      if ($Ldebug || $Lverb);
	($Lok,$msg)=&tremblChangeFasta($file,$fileTremblTmp,$fhoutSbr);
	&errScrMsg("failed on tremblChangeFasta",$msg,$scrName) if (! $Lok);
	$file=$fileTremblTmp    if (-e $fileTremblTmp);
    }

				# add to big
    $cmd="cat < $file >> $fileBigNew";
    print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
    system("$cmd");
				# skip
    next if (! defined $par{$kwd} || ! $par{$kwd});

				# split file
    $#index=0;
    open($fhin,$file) || die "*** $scrName ERROR opening file $file";
    undef $dirSplit;
    $dirSplit="splitSwiss/"     if ($kwd eq "swiss");
    $dirSplit="splitTrembl/"    if ($kwd eq "trembl");
    $dirSplit="splitPdb/"       if ($kwd eq "pdb");
    if (! defined $dirSplit) {
	print "*** dirSplit not defined for kwd=$kwd\n";
	exit;}
    system("mkdir $dirSplit")   if (! -d $dirSplit);
    $id=0;
    while (<$fhin>) {
	$_=~s/\n//g;
	$line=$_;
				# is new id
	if ($_=~/^>/){
				# close previous
	    close($fhout)       if ($id);
	    $id=$line; 
				# SWISSPROT id
	    if    ($kwd eq "swiss"){
		$id=~s/^>\s*.*\|//g; # purge db id
		$id=~s/^(\S+)\s.*$/$1/g; # all other
		$id=~tr/[A-Z]/[a-z]/;
		$tmp=$id; $tmp=~s/^[^\_]+\_(.).*$/$1/g;	# get directory name (first letter of species)
		$dir=$dirSplit.$tmp."/";
		system("mkdir $dir") 
		    if (! -d $dir);
		$fileOut=$dir.$id.".f";
				# security
		$fileOut=~s/[\s\>]//g;
		push(@index,$fileOut);
		open("$fhout",">$fileOut") || die "*** $scrName ERROR creating file $fileOut"; 
	    }
				# PDB id
	    elsif ($kwd eq "pdb"){
		$id=~s/^>\s*.*\|//g; # purge db id
		$id=~s/^(\S+)\s.*$/$1/g; # all other
		$id=~tr/[A-Z]/[a-z]/;
		$dir=$dirSplit;
		system("mkdir $dir") 
		    if (! -d $dir);
				# security
		$fileOut=~s/[\s\>]//g;
		$fileOut=$dir.$id.".f";
		push(@index,$fileOut);
		open("$fhout",">$fileOut") || die "*** $scrName ERROR creating file $fileOut"; 
	    }
				# TREMBL id
	    elsif ($kwd eq "trembl"){
		$id=~s/^>\s*\S*\|//g; # purge db id
		$id=~s/^(\S+)\s.*$/$1/g; # all other
				# add db identifier!
		$id=~tr/[A-Z]/[a-z]/;
		$tmp=substr($id,1,1);
		$dir=$dirSplit.$tmp."/";
		system("mkdir $dir") 
		    if (! -d $dir);
		$fileOut=$dir.$id.".f";
				# security
		$fileOut=~s/[\s\>]//g;
		push(@index,$fileOut);
		open("$fhout",">$fileOut") || die "*** $scrName ERROR creating file $fileOut"; 
	    }
	    else {
		print "*** ERROR db=$kwd does not have special case of id!\n";
		exit;}
	}
	print $fhout $line,"\n";
    }
    close($fhin);
    close($fhout);
				# write index
    $fileOut=$par{"index_".$kwd};
    open("$fhout",">$fileOut") || die "*** $scrName ERROR creating file $fileOut"; 
    foreach $file (@index) {
	print $fhout $file,"\n";
    }
    close($fhout);
}				# end of loop over all 3


				# create the BLAST binaries
$cmd=$par{"exe_formatdb"}." -t big -p T -i $fileBigNew";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");
$cmd=$par{"exe_setdb"}." -t big $fileBigNew";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");

				# move binaries to blast
$dir=$par{"dir_blast"}."old/";
system("mkdir $dir")            if (! -d $dir);
    
$#fileOutBlast=0;
$tmp="big";
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
print "--- new fasta:$fileBigNew\n";
print "--- still do the following:\n";
print "---    * move new dir to /data/derived/big/\n";
print "---    * move trembl ($fileTremblTmp)\n" if (defined $fileTremblTmp && 
							 -e $fileTremblTmp);
print "---    * move the indices to big\n";

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

#===============================================================================
sub tremblChangeFasta {
    local($fileInLoc,$fileOutLoc,$fhoutSbr) = @_ ;
    local($sbrName3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   tremblChangeFasta           changes the fasta trembl from
#                                  >ACC (ACC)
#                               to
#                                  >trembl|ACC|ACC
#       in:                     $fileInLoc,$fileOutLoc(temporary),$fhtrace
#       out:                    1|0,msg,  implicit: new file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName3="tremblChangeFasta";
    $fhinLoc="FHIN_"."tremblChangeFasta";$fhoutLoc="FHOUT_"."tremblChangeFasta";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $fileOutLoc="trembl_".$$.".tmp"                if (! defined $fileOutLoc);
    $fhoutSbr=0                                    if (! defined $fhoutSbr);
    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
    $Lchange=0;
				# ------------------------------
				# read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	$line=$_;
	if ($_=~/^>/ && $_!~/>\s*trembl/){
	    $line=~s/^>\s*/>trembl\|/; # '>acc' -> '>trembl|acc
	    $line=~s/^(>trembl\|\S+)\s*\((\S+)\)/$1\|$2/; # trembl|acc (acc) -> trembl|acc|acc
	    $Lchange=1;}
	print $fhoutLoc $line,"\n";}
    close($fhinLoc);
    close($fhoutLoc);
				# ------------------------------
				# delete if no change
    if (! $Lchange){
 	print $fhoutSbr "--- $sbrName3: $fileInLoc did not have to be changed\n" if ($fhoutSbr);
 	unlink($fileOutLoc);}
				# ------------------------------
				# move file
#     if ($Lchange){
# 	$cmd="\\mv $fileOutLoc $fileInLoc";
# 	print $fhoutSbr "--- $sbrName3: system '$cmd'\n" if ($fhoutSbr);
# 	system("$cmd");
#     }
    return(1,"ok $sbrName3");
}				# end of tremblChangeFasta

