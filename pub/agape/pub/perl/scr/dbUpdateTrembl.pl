#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="updates the trembl version in /data (RUN in directory of NEW trembl!!)";
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
      'fasta_ftp',      "sp_tr_nrdb/fasta/trembl.fas",
      'fasta_data',     "trembl",
      '', "",			# 
      'exe_uncompress', "/usr/bsd/uncompress",
      'exe_compress',   "/usr/bsd/compress",
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
#$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq "auto");
    if ($arg=~/^de?bu?g$/)                { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

				# uncompress
$par{"fasta_ftp"}.=".Z";
if (! -e $par{"fasta_ftp"}){
    print "*** ERROR file with trembl.fasta (",$par{"fasta_ftp"},") missing!\n";
    exit;}

$file=$par{"fasta_ftp"};
$cmd= $par{"exe_uncompress"}." $file";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");
$file=~s/\.Z//g;
if (! -e $file) {
    print "*** ERROR file $file missing after $cmd\n";
    exit; } 
				# copy to new file
$fileNew=$par{"fasta_data"};
$cmd="cp $file $fileNew";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");
if (! -e $fileNew) {
    print "*** ERROR new file $fileNew missing after $cmd\n";
    exit; }
				# recompress
$cmd= $par{"exe_compress"}." $file";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");
				# change '>ACC (ACC)' to '>trembl|Acc|acc'
$fileTremblTmp="trembl_".$$.".tmp";
$fhoutSbr="STDOUT"              if ($Ldebug || $Lverb);
($Lok,$msg)=&tremblChangeFasta($fileNew,$fileTremblTmp,$fhoutSbr);
&errScrMsg("failed on tremblChangeFasta",$msg,$scrName) if (! $Lok);
				# change file!
if (-e $fileTremblTmp) {
    $cmd="\\mv $fileTremblTmp $fileNew\n";
    print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
    system("$cmd");}
    
				# create the BLAST binaries
$cmd=$par{"exe_formatdb"}." -t trembl -p T -i $fileNew";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");
$cmd=$par{"exe_setdb"}." -t trembl $fileNew";
print "--- system '$cmd'\n"     if ($Ldebug || $Lverb);
system("$cmd");

				# move binaries to blast
$dir=$par{"dir_blast"}."old/";
system("mkdir $dir")            if (! -d $dir);
    
$#fileOutBlast=0;
foreach $file ("trembl.ahd",
	       "trembl.atb",
	       "trembl.bsq",
	       "trembl.dat",
	       "trembl.phr",
	       "trembl.pin",
	       "trembl.psq") {
    $fileOld=$par{"dir_blast"}.$file;
				# save old
    if (-e $fileOld){
	$cmd="\\mv $fileOld $dir";
	print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
#	system("$cmd");
    }
				# now move new
    
    $cmd="\\mv $file $fileOld";
    print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
#    system("$cmd");
    push(@fileOutBlast,$fileOld);
				# link
    if (-e $fileOld) {
	$cmd=$par{"exe_ln"}." -s $fileOld .";
	print "--- system '$cmd'\n" if ($Ldebug || $Lverb);
	system("$cmd");
    }
}

print "--- blast binaries:",join(",",@fileOutBlast,"\n");
print "--- new fasta:",$par{"fasta_data"},"\n";
print "--- still move the entire directory to /data/trembl\n";

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

