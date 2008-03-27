#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extracts HYDROGEN donors for DSSP file\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
$par{"thresh-5"}=               "-0.3";
$par{"thresh-4"}=               "-0.4";
$par{"thresh-3"}=               "-0.4";

$par{"thresh-5","1"}=           "-0.8";
$par{"thresh-4","1"}=           "-1.0";
$par{"thresh-3","1"}=           "-1.0";
$par{"extOut"}=                 ".hydro";

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName list_of_files (with 1pdb.dssp_A for chain)'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
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
$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    elsif ($arg=~/dssp_(.)/)              { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
    $par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
#    $fileInOriginal=$fileIn;
    if ($fileIn =~ /[_:](.)$/){
	$fileIn=~s/[_:](.)$//;
	$chnwant=$1;}
    else {
	$chnwant=" ";}
    
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $id=$fileIn;
    $id=~s/^.*\///g;
    $id=~s/\.dssp.*$//g;
    $header=" ";

				# HEADER dssp
    while (<$fhin>) {
	$_=~s/\n//g;
				# get sequence length
	if ($_=~/TOTAL NUMBER OF RESIDUES/){
	    $_=~s/^\s*//g;
	    ($tmp,@tmp)=split(/[\s\t]+/,$_);
	    $len=$tmp;
	    next; }
				# get HEADER
	if ($_=~/^HEADER\s+(\S+.*)$/){
	    $header=$1;
	    $header=~s/ \s+/ /g;
	    next;}

	last if ($_=~/^\s*\#  RESIDUE AA /);
    }


    $chntxt=" ";
    $chntxt="-".$chnwant if ($chnwant ne " ");

    if ($chnwant eq " "){
	$fileOut=$id.$par{"extOut"};}
    else {
	$fileOut=$id."_".$chnwant.$par{"extOut"};}

    if (-e $fileOut){
	$fileOld=$fileOut.$$.".tmp";
	system("\\mv $fileOut $fileOld");}

    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
    print $fhout
	"SEQID      ".$id.$chntxt." ".$header."\n",
	"SEQLEN     ".$len."\n",
	"DATE       Mon Feb 12 15:29:07 2000\n",
	"SEQBASE    Protein Data Bank of Brookhaven (PDB)\n",
	"NALIGN     \n",
	"TOOL       \n",
	"PARAMETER  \n",
	"PARAMETER             e-mail: rost\@columbia.edu\n",
	"## ALIGNMENTS 1 - 0\n",
	" SeqNo  AA  i-3<-i  i-4<-i  i-5<-i \n";

				# BODY dssp
    while (<$fhin>) {
	$_=~s/\n//g;
	$line=$_;
	$no1=  substr($_,1,5);  $no1=~s/\s//g;
	$no2=  substr($_,6,5);  $no2=~s/\s//g;
	$chn=  substr($_,12,1);
				# skip if chain not wanted!
	next if ($chn ne $chnwant);
	$seq=  substr($_,14,1);
#	$sec=  substr($_,17,1);
				# old files
#	$don1= substr($_,41,8); $don1=~s/\s//g;
#	$acc1= substr($_,50,8); $acc1=~s/\s//g;
#	$don2= substr($_,59,8); $don2=~s/\s//g;
#	$acc2= substr($_,68,8); $acc2=~s/\s//g;
# ....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8....,....
#   #  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  O-->H-N  N-H-->O  O-->H-N    
# 
#     1    5   K              0   0  147    0, 0.0   2,-0.3   0, 0.0 364,-0.2   0
#     2    6   S  E     -A  364   0A  17  362,-2.1 362,-2.7  73, 0.0   2,-0.6  -0
#     3    7   V  E     -A  363   0A  64   -2,-0.3 360,-0.2 360,-0.2   3,-0.2  -0
#     4    8   V  E    S+     0   0    1  358,-2.5   2,-0.4  -2,-0.6 359,-0.2   0
#     9   13   G    <   +     0   0   37   -3,-2.2   2,-0.4  20,-0.4  -2,-0.2   0
				# new files
				# NEW
# ....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....
#     1    1   M              0   0   33      0, 0.0    30,-2.0     0, 0.0     2,-0.4   
	$tmp=substr($_,40,45);
	$tmp=~s/^\s*//g;
	$tmp=~s/(\,)\s/$1/g;
	$tmp=~s/(,)/$1/g;
				# fuck is old
	if ($tmp=~/\,\S+\,/){
	    $don1= substr($line,41,8); $don1=~s/\s//g;
#	    $acc1= substr($line,50,8); $acc1=~s/\s//g;
	    $don2= substr($line,59,8); $don2=~s/\s//g;
#	    $acc2= substr($line,68,8); $acc2=~s/\s//g;
	}
				# seems ok with new
	else {
	    @tmp=split(/\s+/,$tmp);
	    $don1= $tmp[1]; $don1=~s/\s//g;
#	    $acc1= $tmp[2]; $acc1=~s/\s//g;
	    $don2= $tmp[3]; $don2=~s/\s//g;
#	    $acc2= $tmp[4]; $acc2=~s/\s//g;
	}

	($donno[1],$donenergy[1])=split(/,/,$don1);
	($donno[2],$donenergy[2])=split(/,/,$don2);
#	($accno[1],$accenergy[1])=split(/,/,$acc1);
#	($accno[2],$accenergy[2])=split(/,/,$acc2);
	$min=1;$alt=2;
	if (! defined $don2){print "xx problem line=$line\n";print "xx $id missing 2:$don2\n";die;}
	if (! defined $don1){print "xx problem line=$line\n";print "xx $id missing 1:$don1\n";die;}
	if (! defined $donenergy[2]){print "xx problem line=$line\n";print "xx $id don2=$don2 missing 2 energ\n";die;}
	if (! defined $donenergy[1]){print "xx problem line=$line\n";print "xx $id don1=$don1 missing 1 energ\n";die;}

	if ($donenergy[1]>$donenergy[2]){
	    $min=2; $alt=1;}

	foreach $i (-3,-4,-5){
	    $ok{$i}=0;
				# energy of larger of the two h-bonds
	    if    ($donno[$min] == $i && $donenergy[$min] <= $par{"thresh".$i}){
		if   ($donenergy[$min] <= $par{"thresh".$i,"1"}){
		    $ok{$i}=1;}
		else {
		    $ok{$i}=
			($donenergy[$min] - $par{"thresh".$i,"1"})/
			    ($par{"thresh".$i}-$par{"thresh".$i,"1"});
		    $ok{$i}=0.5*(2-$ok{$i});
		}}
				# energy of smaller of the two h-bonds
	    elsif ($donno[$alt] == $i && $donenergy[$alt] <= $par{"thresh".$i}){
		if   ($donenergy[$alt] <= $par{"thresh".$i,"1"}){
		    $ok{$i}=1;}
		else {
		    $ok{$i}=
			($donenergy[$alt] - $par{"thresh".$i,"1"})/
			    ($par{"thresh".$i}-$par{"thresh".$i,"1"});
		    $ok{$i}=0.5*(2-$ok{$i});
		}}
	}
	$tmpwrt=     sprintf("%6d %-1s %-1s",
			     $no1,$chn,$seq);
		
	foreach $i (-3,-4,-5){
	    $tmpwrt.=sprintf("   %5.2f",
			     $ok{$i});}
	$tmpwrt.=    "\n";
	print $fhout 
	    $tmpwrt;
	print $tmpwrt if (defined $Ldebug && $Ldebug);
    }
    close($fhin);
    close($fhout);
    print "--- output in $fileOut\n" if (-e $fileOut);
}

print "--- output in $fileOut\n" if (-e $fileOut);
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
sub fileListRd {
    local($fileInLoc) = @_ ;
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
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	$chainTmp="unk";
	$Lok=0;
	if    (-e $file) {
	    $Lok=1;}
	elsif ($file=~/[_:](.)$/){
	    $chainTmp=$1;
	    $tmp=$file;
	    $tmp=~s/[_:](.)$//;
	    $Lok=1               if (-e $tmp);
	}
	if ($Lok){
	    $tmpFile.="$file,";
	    $tmpChain.="*,"  
		if (! defined $chainTmp || $chainTmp eq "unk");
	    $tmpChain.="$chainTmp,"  
		if (defined $chainTmp && $chainTmp ne "unk"); }
	else { 
	    print $fhErrSbr "-*- WARN $sbrName missing file=$file, tmp=$tmp,$_,\n";
	    die;
	}
    }
    close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd


