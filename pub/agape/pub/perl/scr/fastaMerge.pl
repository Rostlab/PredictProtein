#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="concetenates list of fasta to fastMul \n".
    "     \t note: also changes id from 1pdb -> 1pdb_A AND changes files with bad characters...";
    
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'minLen',         30,	# minimal length to include protein
      'minAcids',        5,	# minimal number of different acids (excluding '!|X')
      'lenSaturation', 100,	# check minimal number of acids only if shorter than this!!
      '', "",			# 
      );
@kwd=sort (keys %par);
$LdeleteBadOnes=0;
$Ldebug=0;
$Lverb= 0;

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *.f '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s=%-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s=%-20s %-s\n","len",      "N",       "minimal length (otherwise excluded)";
    printf "      %-15s=%-20s %-s\n","dir",      "x",       "directory to take (rather than file list)";
    printf "      %-15s=%-20s %-s\n","db",       "x",       "database identifier to add to protein id";

    if ($LdeleteBadOnes) {
	print  "      *************** WATCH file will be deleted if not fulfilling!!!\n";
	printf "      %-15s %-20s %-s\n","nodel",    "no value","avoid deletion of files"; }
    else {
	printf "      %-15s %-20s %-s\n","del",      "no value","delete BAD files!"; }
	
    printf "      %-15s=%-20s %-s\n","var",      "N",       "min number of different AAs (gene? shit?)".
	                                                     " note: only if len < 100!";
    printf "      %-15s %-20s %-s\n","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";
    printf "      %-15s %-20s %-s\n","change",   "no value","allows to change file";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

#    printf "      %-15s %-20s %-s\n","noScreen", "no value","";
#    printf "      %-15s=%-20s %-s\n","",   "","";
#    printf "      %-15s %-20s %-s\n","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("      %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("      %-15s  %-20s %-s\n","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s=%10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("      %-15s=%10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("      %-15s=%-20s %-s\n",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
#$fhin= "FHIN";
$fhout="FHOUT";$fhoutMerge="FHOUT_MERGE"; $fhoutList="FHOUT_LIST";

$#fileIn=0;
$LisList=$dir=$LdoChange=0;
$databaseId="";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1; 
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^len=(.*)$/)            { $par{"minLen"}=  $1;}
    elsif ($arg=~/^var=(.*)$/)            { $par{"minAcids"}=$1;}
    elsif ($arg=~/^nodel[a-z]*$/i)        { $LdeleteBadOnes= 0;}
    elsif ($arg=~/^del$/i)                { $LdeleteBadOnes= 1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif ($arg=~/^dir=(.*)$/)            { $dir=            $1;}
    elsif ($arg=~/^change$/)              { $LdoChange=      1;}

    elsif ($arg=~/^db=(.*)$/)             { $databaseId=     $1;
					    $databaseId.="|" if ($databaseId !~/\|$/);}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

				# ------------------------------
				# read directory
if ($dir) {
    $dir=~s/\/$//g;		# purge final slash
    if (! -d $dir) { print "*** $scrName: you want to read the non-existing directory=$dir!\n";
		     exit; }
    print "--- readdir $dir\n"  if ($Lverb);
    opendir(DIR,$dir) || die ("-*- ERROR $scrName: failed opening dir(pred)=$dir!\n");
    @tmp=readdir(DIR);  closedir(DIR);
				# filter subdirectories
    $#tmp2=0;
    foreach $tmp (@tmp) { $tmp2=$dir."/".$tmp;
			  next if (-d $tmp2);
			  next if (! -e $tmp2);
			  push(@tmp2,$tmp2); }
    push(@fileIn,@tmp2); 	# add to (may be alread) existing input files
    $#tmp2=$#tmp=0;		# slim-is-in
}


$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);

if    (! defined $fileOut && $#fileIn==1){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $fileOut="Out-".$tmp;
    $fileOut=~s/\.list/.fasta/;}
elsif (! defined $fileOut){
    $fileOut="Out-merge".$#fileIn.".tmp";}

$fileOutList=$fileOut; $fileOutList=~s/\..*/\.merge_list/; 
$fileOutList.=".merge_list"     if ($fileOutList !~/list$/);

				# ------------------------------
				# read list of files?
				# ------------------------------
if ($LisList || $fileIn[1]=~/\.list/) {
    $#fileTmp=0;
    foreach $fileIn (@fileIn){
	if (! $LisList && $fileIn !~ /\.list/){
	    print "--- file=$fileIn, NOT LIST\n" if ($Lverb);
	    push(@fileTmp,$fileIn);
	    next; }
	print "--- file=$fileIn, interpreted as LIST\n" if ($Lverb);
	($Lok,$msg,$file,$tmp)=&fileListRd($fileIn);
	if (! $Lok) { print "*** ERROR $scrName: thought $fileIn is list, but failed reading it!\n",$msg;
		      exit; }
	push(@fileTmp,split(/,/,$file)); }
    @fileIn=@fileTmp;}


$fileOutTmp="TMP".$$.".tmp";
				# --------------------------------------------------
$ctFile=0;			# (1) read file(s)
				# --------------------------------------------------

&open_file("$fhoutMerge",">$fileOut"); 
&open_file("$fhoutList",">$fileOutList"); 

foreach $fileIn (@fileIn){
    ++$ctFile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctFile,(100*$ctFile/$#fileIn) if ($Lverb);

    $id=$fileIn; $id=~s/^.*\/|\..*$//g;

				# ------------------------------
				# read FASTA
    ($Lok,$id,$seqRd)=
	&fastaRdGuide($fileIn);
    if (! $Lok) { print "*** $scrName ERROR: failed reading FASTA $fileIn\n",$id,"\n";
		  exit; }
				# ------------------------------
    $Lskip=0;			# exclude?
    if ($par{"minLen"} > 0) {
	$seq=$seqRd; $seq=~s/[\s!\.\-X]//g;
	$len=length($seq);
				# too short?
	$Lskip=1                if ($len < $par{"minLen"}); 

        if (! $Lskip && $par{"minAcids"} > 0 && 
	    $len < $par{"lenSaturation"}) {
	    @tmp=split(//,$seq); 
	    undef %tmp; 
	    $ct=0;
	    foreach $aa (@tmp) {
		if (! defined $tmp{$aa}){ ++$ct;
					  $tmp{$aa}=1;}}
				# gene or shit??
	    $Lskip=1            if ($ct < $par{"minAcids"}); }}

				# ******************************
    if ($Lskip){		# deleting it if too short!!!
	if ($LdeleteBadOnes){ print "-*- WATCHA: deleting $fileIn\n";
                              print "xx trying to delete $fileIn??\n";die;
			      unlink($fileIn);}
	print "--- skipped $fileIn\n" if ($Lverb);
	next; }

				# ------------------------------
				# build up file content

				# first line: id
    $tmpWrt=         ">".$databaseId.$id."\n";

    $seqRd=~s/\s//g;
    $len=length($seqRd);
				# write in strings of 10: 'AAAAAAAAAA CCCCCC'
    for ($it=1; $it<=$len; $it+=50) {
	for ($it2=$it; $it2< ($it+50); $it2+=10) {
	    last if ($it2 > $len);
	    $tmp=10; $tmp=($len - $it2 + 1) if (($len - $it2)<10);
	    $tmpWrt.=substr($seqRd,$it2,$tmp)." ";
	}
	$tmpWrt.=    "\n"; }
    
				# ------------------------------
				# write merger
    print $fhoutMerge $tmpWrt;
    print $fhoutList  $fileIn,"\n"; # append file names in list

    next if (! $LdoChange);
				# ------------------------------
				# write new FASTA
    &open_file($fhout,">".$fileOutTmp); 
    print $fhout      $tmpWrt;	# write new
    close($fhout);
				# move new to old
    ($Lok,$msg)=&sysMvfile($fileOutTmp,$fileIn);
    if (! $Lok) { print "*** ERROR $scrName: failed moving $fileOutTmp $fileIn\n";
		  print $msg,"\n"; }
}
close($fhoutMerge);
close($fhoutList);
				# ------------------------------
				# (3) write output
				# ------------------------------

print "--- output merge in    $fileOut\n"     if (-e $fileOut);
print "---        new list in $fileOutList\n" if (-e $fileOutList);
exit;


#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#==============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
sub sysMvfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMvfile                   system call '\\mv file'
#       in:                     $fileToCopy,$fileToCopyTo (or dir),$niceLoc
#       out:                    ok=(1,'mv a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMvfile";
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!")  if (! defined $fileToCopyTo);

    system("$niceLoc \\mv $fileToCopy $fileToCopyTo");

    return(0,"*** $sbrName: couldnt copy '$fileToCopy -> $fileToCopyTo' ($Lok)!")
	if (! -e $fileToCopyTo);
    return(1,"$niceLoc \\mv $fileToCopy $fileToCopyTo");
}				# end of sysMvfile



#==============================================================================
# library collected (end)
#==============================================================================
