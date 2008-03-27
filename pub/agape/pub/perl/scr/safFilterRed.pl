#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="filters redudancy in SAF files\n".
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
#				version 0.1   	Feb,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'extSaf',        ".saf",
      'extFil',        ".safFil",
      'numresPerLine', 80,			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *saf (or list) redundancy (as percentag seq identity)'\n";
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
#$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=0;
				# ------------------------------
				# read command line
$dirOut="";
undef $red;
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
    elsif ($arg=~/^red=(.*)$/ || 
	   $arg=~/^(\d+)$/      )         { $red=            $1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input redundancy (second arg or red=[0-100])\n") if (! defined $red);
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $fileOut=0;
}
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
$ctfile=  0;
$nfileIn= $#fileIn;
$fileTmp="TMP_safFilterRed".$$.".tmp";
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on '$fileIn'\n";
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$nfileIn);
				# ------------------------------
				# read SAF file
				#    x
				# ------------------------------
    ($Lok,$msg)=
	&safRd($fileIn);          
    %saf=%tmp;
    undef %tmp;
    if (! $Lok){
	print "*** ERROR $scrName: after $fileIn\n".$msg."\n";
	next; }
#    return(&errSbrMsg("after call xyz",$msg)) if (! $Lok);

				# ------------------------------
				# write temporary 
    $#excl=0;
    $id=$fileIn;$id=~s/^.*\///g;
    $id=~s/\.saf.*$//g;
    foreach $itali (1..($saf{"NROWS"}-1)){
	next if (defined $excl[$itali]);
	@tmp1=split(//,$saf{"seq",$itali});
	$len=$#tmp1;
				# get all similar to that one
	foreach $itali2 ($itali+1 .. $saf{"NROWS"}){
	    @tmp2=split(//,$saf{"seq",$itali2});
	    $len=$#tmp2 if ($#tmp2 < $len);

	    $ct=$same=0;
	    foreach $itres (1..$len){
		last if ($itres > $#tmp1 || $itres > $#tmp2);
		next if (! defined $tmp1[$itres]);
		next if (! defined $tmp2[$itres]);
		++$same if ($tmp1[$itres] eq $tmp2[$itres]);
		++$ct;
	    }
				# exclude it
	    if ($ct > 0 && (100*$same/$ct)>$red){
		$excl[$itali2]=1;
		print 
		    "--- $id to exclude (from $itali): ",$itali2," red=$red, ide=",
		    (100*$same/$ct),", (ct=$ct, same=$same)\n" if ($Ldebug);}
	    else {
		print 
		    "--- $id       take: ",$itali2," red=$red, ide=",
		    (100*$same/$ct),", (ct=$ct, same=$same)\n" if ($Ldebug);
		last; }
	}
    }				# end of loop over all alis

				# ------------------------------
				# write new
    if (! defined $fileOut || ! $fileOut || $ctfile > 1 ){
	$fileOut=$fileIn;
	$fileOut=~s/^.*\///g;
	$fileOut=$dirOut.$fileOut;
	$fileOut=~s/$par{"extSaf"}/$par{"extFil"}/;
    }

    if ($#excl){
	$excl="";$ctexcl=0;$cttake=0;
	undef %tmp;
	foreach $itali (1..$saf{"NROWS"}){
	    if (defined $excl[$itali]){
		++$ctexcl;
		next;}
	    ++$cttake;
	    $tmp{"id",$cttake}= $saf{"id",$itali};
	    $tmp{"seq",$cttake}=$saf{"seq",$itali};
	}
	$tmp{"HEADER"}="# origin=$fileIn, redundancy reduced by ".$red." % (".$saf{"NROWS"}."->$cttake)\n";
	$tmp{"NROWS"}=$cttake;
	undef %saf;
				# ------------------------------
				# write SAF
				#    in GLOBAL %tmp
				# ------------------------------
	($Lok,$msg)=
	    &safWrt($fileOut);  
	if (! $Lok){ print "*** ERROR $scrName: after safWrt($fileOut)\n".$msg."\n";
		     next; }
#	return(&errSbrMsg("after call xyz",$msg)) if (! $Lok);
	undef %tmp;
	
	print "--- filtered ($red: $ctexcl->$cttake) $fileOut\n" if ($Lverb);
    }
    else {
	print "--- simply copy $fileIn $fileOut\n" if ($Lverb);
	system("\\cp $fileIn $fileOut");
    }
}

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
    open($fhinLoc,$fileInLoc) ||
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

#===============================================================================
sub safRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   safRd                       reads SAF format
#       in:                     $fileOutLoc,
#       out:                    ($Lok,$msg,$tmp{}) with:
#       out:                    $tmp{"NROWS"}  number of alignments
#       out:                    $tmp{"id", $it} name for $it
#       out:                    $tmp{"seq",$it} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."safRd";$fhinLoc="FHIN_"."safRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $LverbLoc=0;

    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ctBlocks=$ctRd=$#nameLoc=0;  
    undef %nameInBlock; 
    undef %tmp;			# --------------------------------------------------
				# read file
    while (<$fhinLoc>) {	# --------------------------------------------------
	$_=~s/\n//g;
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
				# ignore lines with numbers, blanks, points only
	$tmp=$_; $tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1);

	$line=~s/^\s*|\s*$//g;	# purge leading blanks
				# ------------------------------
				# names
	$name=$line; $name=~s/^([^\s\t]+)[\s\t]+.*$/$1/;
				# maximal length: 14 characters (because of MSF2Hssp)
#	$name=substr($name,1,14);
				# ------------------------------
				# sequences
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
	print "--- $sbrName: name=$name, seq=$seq,\n" if ($LverbLoc);
				# ------------------------------
				# guide sequence: determine length
				# NOTE: no 'left-outs' allowed here
				# ------------------------------
	$nameFirst=$name        if ($#nameLoc==0);	# detect first name
	if ($name eq "$nameFirst"){
	    ++$ctBlocks;	# count blocks
	    undef %nameInBlock;
	    if ($ctBlocks == 1){
		$lenFirstBeforeThis=0;}
	    else {
		$lenFirstBeforeThis=length($tmp{"seq","1"});}

	    if ($ctBlocks>1) {	# manage proteins that did not appear
		$lenLoc=length($tmp{"seq","1"});
		foreach $itTmp (1..$#nameLoc){
		    $tmp{"seq",$itTmp}.="." x ($lenLoc-length($tmp{"seq",$itTmp}));}
	    }}
				# ------------------------------
				# ignore 2nd occurence of same name
	next if (defined $nameInBlock{$name}); # avoid identical names

				# ------------------------------
				# new name
	if (! defined ($tmp{$name})){
	    push(@nameLoc,$name); 
	    ++$ctRd;
	    $tmp{$name}=$ctRd; 
	    $tmp{"id",$ctRd}=$name;
	    print "--- $sbrName: new name=$name,\n"   if ($LverbLoc);

	    if ($ctBlocks>1){	# fill up with dots
		print "--- $sbrName: file up for $name, with :$lenFirstBeforeThis\n" if ($LverbLoc);
		$tmp{"seq",$ctRd}="." x $lenFirstBeforeThis;}
	    else{
		$tmp{"seq",$ctRd}="";}}
				# ------------------------------
				# finally store
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$ptr=$tmp{$name};    
	$tmp{"seq",$ptr}.=$seq;
	$nameInBlock{$name}=1; # avoid identical names
    } close($fhinLoc);
				# ------------------------------
				# fill up ends
    $lenLoc=length($tmp{"seq","1"});
    foreach $itTmp (1..$#nameLoc){
	$tmp{"seq",$itTmp}.="." x ($lenLoc-length($tmp{"seq",$itTmp}));}
    $tmp{"NROWS"}=$ctRd;
    $tmp{"names"}=join (',',@nameLoc);  $tmp{"names"}=~s/^,*|,*$//;

    $#nameLoc=0; 
    undef %nameInBlock;

    return(1,"ok $sbrName");
}				# end of safRd

#===============================================================================
sub safWrt {
    local($fileOutLoc) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   safWrt                      writing an SAF formatted file of aligned strings
#       in:                     $fileOutLoc       output file
#                                   = "STDOUT"    -> write to screen
#                                   = "txt"       -> write to string
#       in GLOBAL:              %saf
#                               
#       in:                     $tmp{"NROWS"}     number of alignments
#       in:                     $tmp{"id", $it} name for $it
#       in:                     $tmp{"seq",$it} sequence for $it
#       in:                     $tmp{"PER_LINE"}  number of res per line (def=50)
#       in:                     $tmp{"HEADER"}    'line1\n,line2\n'..
#                                   with line1=   '# NOTATION ..'
#       out:                    1|0,msg implicit: file
#       err:                    ok-> 1,ok | error -> 0,message
#--------------------------------------------------------------------------------
    $sbrName="lib-br:safWrt"; $fhoutLoc="FHOUT_safWrt";
                                # check input
    return(0,"*** ERROR $sbrName: no acceptable output file ($fileOutLoc) defined\n") 
        if (! defined $fileOutLoc || length($fileOutLoc)<1 || $fileOutLoc !~/\w/);
    return(0,"*** ERROR $sbrName: no input given (or not input{NROWS})\n") 
        if (! defined %tmp || ! %tmp || ! defined $tmp{"NROWS"} );
    return(0,"*** ERROR $sbrName: tmp{NROWS} < 1\n") 
        if ($tmp{"NROWS"} < 1);
    $tmp{"PER_LINE"}=50         if (! defined $tmp{"PER_LINE"});
    $fhoutLoc="STDOUT"          if ($fileOutLoc eq "STDOUT");
				# ------------------------------
				# write header
				# ------------------------------
    $prtloc= "# SAF (Simple Alignment Format)\n"."\# \n";
    if (defined $tmp{"HEADER"}){
	@tmp=split(/\n/,$tmp{"HEADER"});
	foreach $tmp (@tmp){
	    $tmp="# ".$tmp      if ($tmp !~ /^\#/);
	    $prtloc.=$tmp;
	}
	$prtloc.="\n";
    }

				# ------------------------------
				# get maximal length of name
    $max=20;
    foreach $it (1..$tmp{"NROWS"}){
	$max=length($tmp{"id",$it}) if (length($tmp{"id",$it}) > $max);
    }
				# ------------------------------
				# write data into file
				# ------------------------------
    for ($itres=1; $itres<=length($tmp{"seq","1"}); $itres+=$tmp{"PER_LINE"}){
	foreach $itpair (1..$tmp{"NROWS"}){
	    $prtloc.=
		sprintf("%-".$max."s ",$tmp{"id",$itpair});
				# chunks of $tmp{"PER_LINE"}
	    $chunkEnd=$itres + ($tmp{"PER_LINE"} - 1);
	    foreach $itchunk ($itres .. $chunkEnd){
		last if (length($tmp{"seq",$itpair}) < $itchunk);
		
		$prtloc.=
		    substr($tmp{"seq",$itpair},$itchunk,1);
				# add blank every 10
		$prtloc.=
		    " " 
			if ($itchunk != $itres && 
			    (int($itchunk/10)==($itchunk/10)));
	    }
	    $prtloc.=
		"\n";
	}
	$prtloc.=
	    "\n";
    }
    $prtloc.=
	"\n";
    $#nameLoc=$#stringLoc=0;	# save space

                                # ------------------------------
                                # open new file
    if ($fhoutLoc ne "STDOUT" &&
	$fhoutLoc ne "txt") {
	open($fhoutLoc,">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); }
    if ($fhoutLoc ne "txt"){
	print $fhoutLoc $prtloc;
	$prtloc="";
	return(1,"ok $sbrName") if ($fhoutLoc eq "STDOUT");
	close($fhoutLoc);
	return(0,"*** ERROR $sbrName: failed to write file $fileOutLoc\n") 
	    if (! -e $fileOutLoc);
	return(1,"ok $sbrName");}

    return(1,"string empty??\n".$prtloc) if (length($prtloc)<10);
    return(1,$prtloc);
}				# end of safWrt

