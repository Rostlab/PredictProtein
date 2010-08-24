#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="convert PHDrdb to HTML";
# 
# 
# NOTE: for easy exchange with PHD, all major subroutines shared between
#       PHD and this program appear at the end of it (after 'lllend')
# 

# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Apr,    	1999	       #
#				version 0.2   	Mar,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# find library
$dirScr=$0; $dirScr=~s/^(.*\/)[^\/]*$/$1/;
$lib="lib-phdhtml.pm"; $Lok=0;
foreach $dir ($dirScr,
	      $dirScr."pack/",
	      "",
	      "pack/",
	      "/home/rost/nn/phd2000/scr/",
	      "/nfs/home1/yachdav/work/SNAP/phd/scr/",
	      "/nfs/home1/yachdav/work/SNAP/phd/scr/pack/"){
    next if (! -e $dir.$lib);
    $Lok=require($dir.$lib); }
die("*** ERROR $scrName: could NOT find lib=$lib!\n") if (! $Lok);
				# ------------------------------
				# ini
($Lok,$msg)=&ini();		die("*** ERROR $scrName: failed in ini:\n".
				    $msg."\n") if (! $Lok);

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=0;
foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);

				# name of output file
    $fileOut1=$fileOut          if ($fileOut);
    $fileOut1=0                 if (! $fileOut);
    if (! $fileOut1) {
	$tmp=0;
	$tmp1=$tmp2=$tmp3=""; 
	$tmp1=$par{"dirOut"}    if ($par{"dirOut"});
	$tmp1=$par{"dirWork"}   if (! $par{"dirOut"} && $par{"dirWork"});
	if    (length($tmp1)<1 || $tmp1=~ /^0/ || $tmp1 =~/unk/){
	    $tmp1="";}
	elsif ($tmp1 !~ /\/$/){
	    $tmp1.="/";}
	$tmp2=$par{"titleOut"}  if ($par{"titleOut"});
	$tmp3=$par{"extOut"}    if ($par{"extOut"});
	if ($par{"titleOut"}) {
	    $fileOut1=$tmp1.$tmp2.$tmp3; }
	else {
	    $tmp2=$fileIn; $tmp2=~s/^\.*|\..*$//g;
	    $fileOut1=$tmp1.$tmp2.$tmp3; }
	if (-e $fileOut1) {
	    print "-*- WARN $scrName: remove existing output file $fileOut1\n";
	    unlink($fileOut1);}}

    ($Lok,$msg)=
	&convPhd2Html
	    ($fileIn,$fileOut1,$modeWrtLoc,
	     $par{"nresPerRow"},
	     $par{"riSubSec"},$par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSym"},
	     "STDOUT");
    if (! $Lok){
	print "*** $scrName: no output=$fileOut1\n","*** ERROR msg from where it failed\n","$msg\n";
	next;}
    if (! -e $fileOut1){
	print "*** $scrName: no output=$fileOut1\n";
	next;}
    print "--- $scrName: out=$fileOut1\n"       if ($Lverb);
}

print "--- last output in $fileOut1\n" if (-e $fileOut1);
exit;

#===============================================================================
sub ini {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ini";

				# ------------------------------
				# defaults
    %par=(
	  'dirOut',    0,		# will be added to output file name (if no 0)
	  'dirWork',   0,
	  'extOut',    "_phd.html",	# will be added to output file name (if no 0)
	  'titleOut',  0,		# will be added to output file name (if no 0)
				        # used to steer what will be written, possible
				        #    'html:<all|body|head>'
				        #    'data:<all|brief|normal|detail>'
	  'parHtml',   "html:all,data:all",
	  '', "",
	  );
    
    $par{"riSubSec"}=           5;      # minimal RI for subset PHDsec
    $par{"riSubAcc"}=           4;      # minimal RI for subset PHDacc
    $par{"riSubHtm"}=           7;      # minimal RI for subset PHDhtm
    $par{"riSubSym"}=           ".";    # symbol for residues predicted with RI<SubSec/Acc
    $par{"nresPerRow"}=        100;     # number of residues per line in human readable files
				        # written for each protein
				        # =0 -> endless line

    $par{"txt","quote","phd1994"}= "B Rost (1996) Methods in Enzymology, 266:525-539";
    $par{"txt","quote","phdsec"}=  "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","phdacc"}=  "B Rost & C Sander (1994) Proteins, 20:216-226";
    $par{"txt","quote","phdhtm"}=  "B Rost, P Fariselli & R Casadio (1996) Prot Science, 7:1704-1718";
    $par{"txt","quote","globe"}=   "B Rost (1998) unpublished";
    $par{"txt","quote","topits"}=  "B Rost, R Schneider & C Sander (1997) J Mol Biol, 270:1-10";

    $par{"txt","copyright"}=       "Burkhard Rost, ROSTLAB";
    $par{"txt","contactEmail"}=    "info\@rostlab.org";
#    $par{"txt","contactFax"}=      "+1-212-305 3773";
    $par{"txt","contactWeb"}=      "http://www.rostlab.org";
    $par{"txt","version"}=         "1.96";


				# minimal number of residues to run network 
				#    otherwise prd=symbolPrdShort
    $par{"numresMin"}=          9;
				# default prediction for too short sequences
    $par{"symbolPrdShort"}=     "*";
				# explain 'skipping'
    $par{"notation","phd_skip"}=   
	"note: sequence stretches with less than ".$par{"numresMin"}.
	    " are not predicted, the symbol '".$par{"symbolPrdShort"}.
		"' is used!";

    $Ldebug=0;
    $Lverb=0;

    @kwd=sort (keys %par);
				# ------------------------------
    if ($#ARGV<1){		# help
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName '\n";
	print  "note: \n";
	print  "      parHtml=x     controls what will be written, possible\n";
	print  "      'html:<all|body|head>,data:<all|brief|normal|detail>'\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
	printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "name of output directory";

#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

	printf "%5s %-15s %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";

	printf "%5s %-15s %-20s %-s\n","","dbg",      "no value","debug mode";
	printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","no screen output";
	printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
	printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
	printf "%5s %-15s %-20s %-s\n","","brief",    "no value","only brief HTML of PHD";
	printf "%5s %-15s %-20s %-s\n","","normal",   "no value","normal HTML of PHD (incl SUB)";
	printf "%5s %-15s %-20s %-s\n","","detail",   "no value","detail HTML (incl graph)";
	printf "%5s %-15s %-20s %-s\n","","body",     "no value","only BODY of HTML";
	printf "%5s %-15s %-20s %-s\n","","head",     "no value","only HEAD of HTML";
	if (defined %par && $#kwd > 0){
	    $tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	    $tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	    $tmp2="";
	    foreach $kwd (@kwd){
		next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
		if    ($par{"$kwd"}=~/^\d+$/){
		    $tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
		elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		    $tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
		else {
		    $tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	    } 
	    print $tmp, $tmp2       if (length($tmp2)>1);
	}
	exit;}
				# initialise variables
#    $fhin="FHIN";$fhout="FHOUT";
    $LisList=0;
    $#fileIn=0;
    $modeWrtLoc="";
				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
	elsif ($arg=~/^dirOut=(.*)$/)         { $par{"dirOut"}=    $1;}

	elsif ($arg=~/^de?bu?g$/)             { $Ldebug= 1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=  1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=  0;}

	elsif ($arg=~/^brief$/)               { $modeWrtLoc.="data:brief,"; }
	elsif ($arg=~/^normal$/)              { $modeWrtLoc.="data:normal,"; }
	elsif ($arg=~/^detail$/)              { $modeWrtLoc.="data:detail,"; }
	elsif ($arg=~/^body$/)                { $modeWrtLoc.="html:body,"; }
	elsif ($arg=~/^head$/)                { $modeWrtLoc.="html:head,"; }
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif ($arg=~/^list$/i)               { $LisList=        1;}
	elsif (-e $arg)                       { push(@fileIn,$arg); 
					    # automatic detection of list
						$LisList=        1 if ($arg =~ /\.list/); }
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 exit;}}}

    $fileIn=$fileIn[1];
    die ("missing input $fileIn\n") if (! -e $fileIn);
    $fileOut=0                      if (! defined $fileOut);
    $par{"dirOut"}.="/"             if ($par{"dirOut"} && $par{"dirOut"}!~/\/$/);
    $par{"dirWork"}.="/"            if ($par{"dirWork"} && $par{"dirWork"}!~/\/$/);

				# correct goal
    $modeWrtLoc=$par{"parHtml"}     if (length($modeWrtLoc) < 1) ;

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" || ! $par{$kwd});
	$par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);
	if ($kwd=~/dirOut/ && 
	    (! -d $par{$kwd} || ! -l $par{$kwd})){
	    $dir=$par{$kwd};
	    $dir=~s/\/$//g;
	    system("mkdir $dir");}}


				# ------------------------------
				# digest file (list?)
				# ------------------------------
    $#fileTmp=0;
    foreach $fileIn (@fileIn){
	if ( ($#fileIn==1 && ! $LisList) || $fileIn !~/\.list/) {
	    push(@fileTmp,$fileIn);
	    next;}
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);return(&errSbrMsg("failed getting input list, file=$fileIn",
						   $msg))  if (! $Lok);
	@tmpf=split(/,/,$file); push(@fileTmp,@tmpf);}
    @fileIn= @fileTmp; 
    $#fileTmp=0;		# slim-is-in

    return(1,"ok $sbrName");
}				# end of ini


#==============================================================================
# library collected (begin) lll
#==============================================================================

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
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

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
sub getSegment {
    local($stringInLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSegment                  takes string, writes segments and boundaries
#       in:                     $stringInLoc=  '  HHH  EE HHHHHHHHHHH'
#       out:                    1|0,msg,%segment (as reference!)
#                               $segment{"NROWS"}=   number of segments
#                               $segment{$it}=       type of segment $it (e.g. H)
#                               $segment{"beg",$it}= first residue of segment $it 
#                               $segment{"end",$it}= last residue of segment $it 
#                               $segment{"ct",$it}=  count segment of type $segment{$it}
#                                                    e.g. (L)1,(H)1,(L)2,(E)1,(H)2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getSegment";
    $fhinLoc="FHIN_"."getSegment";$fhoutLoc="FHOUT_"."getSegment";
				# check arguments
    return(&errSbr("not def stringInLoc!"))          if (! defined $stringInLoc);
    return(&errSbr("too short stringInLoc!"))        if (length($stringInLoc)<1);

				# set zero
    $prev=""; undef %segment; $ctSegment=0; undef %ctSegment;
				# into array
    @tmp=split(//,$stringInLoc);
    foreach $it (1..$#tmp) {	# loop over all 'residues'
	$sym=$tmp[$it];
				# continue segment
	next if ($prev eq $sym);
				# finish off previous
	$segment{"end",$ctSegment}=($it-1)
	    if ($it > 1);
				# new segment
	$prev=$sym;
	++$ctSegment;
	++$ctSegment{$sym};
	$segment{$ctSegment}=      $sym;
	$segment{"beg",$ctSegment}=$it;
	$segment{"seg",$ctSegment}=$ctSegment{$sym};
    }
				# finish off last
    $segment{"end",$ctSegment}=$#tmp;
				# store number of segments
    $segment{"NROWS"}=$ctSegment;

    $#tmp=0;			# slim-is-in

    return(1,"ok",\%segment);
}				# end of getSegment

#===============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#===============================================================================
sub rdRdb_here {
    local ($fileInLoc,$ra_kwdRdHead,$ra_kwdRdBody) = @_ ;
    local ($sbr_name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdb_here                  reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               $ra_kwdRdHead: $ra_kwdRdHead->[1]  = $kwdRdHead[1]
#       out:                    $rdb{"NROWS"} returns the numbers of rows read
#                               $rdb{$itres,$kwd}
#--------------------------------------------------------------------------------
				# avoid warning
    $sbr_name="rdRdb_here";
				# set some defaults
    $fhinLoc="FHIN_RDB";
				# get input
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("failed opening fileIn=$fileInLoc!\n",$sbr_name));
    undef %rdb;
    $#ptr_num2name=$#col2read=0;

				# ------------------------------
				# for quick finding
    if (! defined %kwdRdBody){
	foreach $kwd (@$ra_kwdRdBody){
	    $kwdRdBody{$kwd}=1;}}

	
    $ctLoc=$ctrow=0;
				# ------------------------------
				# header  
    $rdb{"header"}="";
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
	$rdb{"header"}.=$line;
	if ( $_=~/^\#/ ) { 
	    next if ($_=~/NOTATION/);
	    foreach $kwd (@$ra_kwdRdHead){
				# avoid duplication
		next if (defined $rdb{$kwd});
		if ($_=~/^.*\s.*$kwd\s*[:,\;=]\s*(\S+)/i){
		    $rdb{$kwd}=$1;
		    next; 
		}
	    }
	    next; }
	last; }

				# ------------------------------
				# names
    @tmp=split(/\s*\t\s*/,$line);
    $kwd_original="";		# avoid warnings
    foreach $it (1..$#tmp){
	$kwd=$tmp[$it];
				# translate names
	if (! defined $kwdRdBody{$kwd}){
	    if (defined $transData{$kwd}){
		$kwd_original=$kwd;
		$kwd=$transData{$kwd};}
	    else {
		next;}}
	$ptr_num2name[$it]=$kwd;
	push(@col2read,$it); }

    $ctLoc=2;
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
				# ------------------------------
				# skip format?
	if    ($ctLoc==2 && $line!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc;}
	elsif ($ctLoc==2){
	    next; }
				# ------------------------------
				# data
	if ($ctLoc>2){
	    ++$ctrow;
	    @tmp=split(/\s*\t\s*/,$line);
	    foreach $it (@col2read){
		$rdb{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	    }
	}
    }
    close($fhinLoc);
    $rdb{"NROWS"}=$ctrow;

    $#col2read=0; 
    undef %ptr_num2name;

    return (1,"ok");
}				# end of rdRdb_here

#==============================================================================
# library collected (end) lllend
#==============================================================================

