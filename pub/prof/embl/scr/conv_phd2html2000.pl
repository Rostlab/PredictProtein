#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="convert PHDrdb to HTML";

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
#------------------------------------------------------------------------------#
#

$[ =1 ;
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

$par{"riSubSec"}=           5;        # minimal RI for subset PHDsec
$par{"riSubAcc"}=           4;        # minimal RI for subset PHDacc
$par{"riSubHtm"}=           7;        # minimal RI for subset PHDhtm
$par{"riSubSym"}=           ".";      # symbol for residues predicted with RI<SubSec/Acc
$par{"nresPerRow"}=        100;       # number of residues per line in human readable files
                                      # written for each protein
				      # =0 -> endless line
$par{"nresPerRow"}=        0;       # number of residues per line in human readable files

$Ldebug=1;
$Lverb=0;

@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "note: \n";
    print  "      parHtml=x     controls what will be written, possible\n";
    print  "      'html:<all|body|head>,data:<all|brief|normal|detail>'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";

    printf "%5s %-15s %-20s %-s\n","","dbg",      "no value","debug mode";
    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
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
#$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=0;
$modeWrtLoc="";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug= 1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=  1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=  0;}
    elsif ($arg=~/^brief$/)               { $modeWrtLoc.="data:brief,"; }
    elsif ($arg=~/^normal$/)              { $modeWrtLoc.="data:normal,"; }
    elsif ($arg=~/^detail$/)              { $modeWrtLoc.="data:detail,"; }
    elsif ($arg=~/^body$/)                { $modeWrtLoc.="html:body,"; }
    elsif ($arg=~/^head$/)                { $modeWrtLoc.="html:head,"; }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
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
$fileOut=0 if (! defined $fileOut);
$par{"dirOut"}.="/"             if ($par{"dirOut"} && $par{"dirOut"}!~/\/$/);
$par{"dirWork"}.="/"            if ($par{"dirWork"} && $par{"dirWork"}!~/\/$/);

				# correct goal
$modeWrtLoc=$par{"parHtml"}     if (length($modeWrtLoc) < 1) ;


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && ! $LisList) || $fileIn !~/\.list/) {
	push(@fileTmp,$fileIn);
	next;}
    ($Lok,$msg,$file,$tmp)=
	&fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
					     exit; }

    @tmpf=split(/,/,$file); push(@fileTmp,@tmpf);}
@fileIn= @fileTmp; 
$#fileTmp=0;			# slim-is-in
				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=0;
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n" if ($Lverb);

				# name of output file
    $fileOut1=$fileOut          if ($fileOut);
    $fileOut1=0                 if (! $fileOut);
    if (! $fileOut1) {
	$tmp=0;
	$tmp1=$tmp2=$tmp3=""; 
	$tmp1=$par{"dirOut"}    if ($par{"dirOut"});
	$tmp1=$par{"dirWork"}   if (! $par{"dirOut"} && $par{"dirWork"});
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
	&convPhd2Html($fileIn,$fileOut1,$modeWrtLoc,
		      $par{"nresPerRow"},
		      $par{"riSubSec"},$par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSym"},
		      "STDOUT");
    print "--- $scrName: out=$fileOut\n"       if ($Lverb && -e $fileOut1);
    print "*** $scrName: no output=$fileOut\n" if (! -e $fileOut1);
}
exit;


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

#===============================================================================
sub getSegment {
    local($stringInLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSegment                  takes string, writes segments and boundaries
#       in:                     $stringInLoc=  '  HHH  EE HHHHHHHHHHH'
#       out:                    1|0,msg, 
#       out GLOBAL:             %segment (as reference!)
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
    $prev=""; 
    undef %segment;  
    undef %ctSegment;
    $ctSegment=0; 
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
    return(1,"ok");
}				# end of getSegment

#===============================================================================
sub htmlWrtHead {
    local($fhoutLoc,$titleLoc,$txtLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlWrtHead                 writes header of HTML file
#       in:                     $fhoutLoc=    file handle to write
#       in:                     $titleLoc=    title for file
#       in:                     $txtLoc=      optional text (e.g. styles asf)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlWrtHead";
				# check arguments
    return(&errSbr("not def fhoutLoc!"))     if (! defined $fhoutLoc);
    return(&errSbr("not def titleLoc!"))     if (! defined $titleLoc);
    $txtLoc=0                                if (! defined $txtLoc);
#    return(&errSbr("not def !"))          if (! defined $);

				# header tag
    print $fhoutLoc
	"<HTML>\n",
	"<HEAD>\n";
				# additional text (style asf)
    print $fhoutLoc
	$txtLoc,"\n"            if ($txtLoc);

				# title
    print $fhoutLoc
	"<TITLE>\n",
	"        $titleLoc\n",
	"</TITLE>\n",

    return(1,"ok $sbrName");
}				# end of htmlWrtHead

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

#===============================================================================
sub rdRdbAssociative_5 {
    my ($fileInLoc,@tmp) = @_ ;
    my ($sbr_name,$fhinLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative_5          reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       in:                     $des_in[n]='all'      -> all will be read
#       in:                     $des_in[n]='all_head' -> full header will be read
#       in:                     $des_in[n]='all_body' -> full body (all columns) will be read
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# set some defaults
    $sbr_name="rdRdbAssociative_5";$fhinLoc="FHIN_RDB".$sbr_name;
				# get input
    return(0,"*** ERROR $sbr_name: not def fileRdb=$fileInLoc!\n") if (! defined $fileInLoc);
    return(0,"*** ERROR $sbr_name: missing fileRdb=$fileInLoc!\n") if (! -e $fileInLoc);

				# ------------------------------
				# what to read?
				# ------------------------------
    $Lall=$#des_head=$#des_body=0;

    if ($#tmp==1 && $tmp[1] eq "all"){
	$Lall=1;}
    else {
	while (@tmp){ $kwd=shift(@tmp);
		      next if ($kwd=~/head/);
		      last if ($kwd=~/body/);
		      next if ($kwd=~/^\s*$/);
		      push(@des_head,$kwd); }
	while (@tmp){ $kwd=shift(@tmp);
		      next if ($kwd=~/^\s*$/);
		      push(@des_body,$kwd); }}

				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhinLoc,$fileInLoc) || return("*** ERROR $sbr_name: failed opening RDBfile=$fileInLoc\n");

    $ct=0;
    undef %ptr;
    $rdb{"header"}="";
				# ------------------------------
				# (1) header
    while(<$fhinLoc>){
	$_=~s/\n//g;
	$rd=$_;
				# comment
	if ($_=~/^\#/){
				# unspecific for HTML
	    $rdb{"header"}.="# ".$rd."\n";
	    next if ($rd !~/^\s*\#\s*(PARA|VAL.*)\s*:?\s*?(\S+)\s*[ :,\;=]\s*(\S.*)$/);
	    $kwdrd=$2;
	    $valrd=$3;
	    if (! $Lall){
		$Lfound=0;
		foreach $kwd (@des_head) { next if ($kwd !~ $kwdrd);
					   $Lfound=1;
					   last;} }
	    else {
		$Lfound=1;}
	    next if (! $Lfound);
	    if (defined $rdb{$kwdrd}){
		$rdb{$kwdrd}.="\t".$valrd;}
	    else {
		$rdb{$kwdrd}=$valrd;}
	    next; }
				# col name
	else {
	    $_=~s/\t$//g;
	    @tmp=split(/\t/,$_);
				# which ones are there?
	    foreach $it (1..$#tmp){
		$ptr{$tmp[$it]}=$it; 
	    } 
	    if ($Lall){
		@des_found=@tmp; }
	    else {
		foreach $kwd (@des_body){
		    next if (! defined $ptr{$kwd}); # wanted to read $kwd but NOT found in file
		    push(@des_found,$kwd); }}
	    last; }}
				# ------------------------------
				# (2) body
    $LdoneFormat=0;
    $ctrow=0;
    while(<$fhinLoc>){
	$_=~s/\n//g;
				# read formats
	if (! $LdoneFormat &&
	    ($_=~/\dN[\s\t]+/ || $_=~/S[\s\t]+/ || $_=~/\dF[\s\t]+/)){
	    @tmp=split(/\t/,$_);
	    foreach $kwd (@des_found){
		$rdb{"format",$kwd}=$tmp[$ptr{$kwd}];
	    }
	    $LdoneFormat=1;
	    next; }
	++$ctrow;
				# real stuff
	@tmp=split(/\t/,$_);
	foreach $kwd (@des_found){
	    $rdb{$ctrow,$kwd}=$tmp[$ptr{$kwd}];
	}
    }
    close($fhinLoc);
    $rdb{"NROWS"}=$rdb{"NROWS"}=$ctrow;
	
				# ------------------------------
				# safe memory
    $#des_head=$#des_body=$#des_found=
	$#tmp=0;		# slim_is_in !
    undef %ptr;			# slim_is_in !

    return(1,"ok");
}				# end of rdRdbAssociative_5

#==============================================================================
# library collected (end) lll
#==============================================================================

#===============================================================================
sub convPhd2Html {
    local($fileInLoc,$fileOutLoc,$modeWrtLoc,$nresPerLineLoc,
	  $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html                convert PHDrdb to HTML
#       in:                     $fileInLoc=       PHDrdb file
#       in:                     $fileOutLoc=      HTML output file
#                               =0                -> STDOUT
#       in:                     $modeWrtLoc=      mode for job
#                                  html:all       write head,body
#                                  html:<head|body>
#                                  data:all       write brief,normal,detail
#                                  data:<brief|norm|detail>
#                                  e.g. 'data:brief,data:normal,html:body'
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."convPhd2Html";
    $fhinLoc="FHIN_"."convPhd2Html";$fhoutLoc="FHOUT_"."convPhd2Html";
				# check arguments
    return(&errSbr("not def fileInLoc!"))      if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))     if (! defined $fileOutLoc);
    return(&errSbr("not def modeWrtLoc!"))     if (! defined $modeWrtLoc);
    return(&errSbr("not def nresPerLineLoc!")) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!"))    if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!"))    if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!"))    if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!"))    if (! defined $riSubSymLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# ------------------------------
				# HTML file handle
    $fileOutLoc=0               if ($fileOutLoc eq "STDOUT");
    $fhoutHtml="FHOUT_HTML_convPhd2Html";
    $fhoutHtml="STDOUT"         if (! $fileOutLoc);

				# ------------------------------
				# digest mode
				# ------------------------------
    $Lbrief=$Lnormal=$Ldetail=
	$Lhead=$Lbody=0;

				# what to write
    $modeWrtLoc.="data:all"     if ($modeWrtLoc!~/data/);
    $Lbrief=          1         if ($modeWrtLoc=~/data:(brief|all)/);
    $Lnormal=         1         if ($modeWrtLoc=~/data:(normal|all)/);
    $Ldetail=         1         if ($modeWrtLoc=~/data:(det|all)/);
				# which part of HTML
    $modeWrtLoc.="html:all"     if ($modeWrtLoc!~/html/);
    $Lhead=           1         if ($modeWrtLoc=~/html:(head|all)/);
    $Lbody=           1         if ($modeWrtLoc=~/html:(body|all)/);
    
				# --------------------------------------------------
				# (0) ini names
				# out GLOBAL: @kwdWant,$lenAbbr,%transSec2Htm
				#             %transSym,%transAbbr,%transDescr
				# --------------------------------------------------
    ($Lok,$msg)=
	&convPhd2Html_ini($nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc);
    return(&errSbr("failed on convPhd2Html_ini($nresPerLineLoc,".
		   "$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)\n".
		   $msg."\n",$sbrName)) if (! $Lok);

                                # ini HTML css_styles
				# out GLOBAL: %css_phd
    &convPhd2Html_iniStyles();

				# ------------------------------
				# (1) read RDB file
				# ------------------------------
    ($Lok,$msg)=
        &rdRdbAssociative_5($fileInLoc,"all"
			    );  return(&errSbr("failed rdRdb on $fileInLoc")) if (! $rdb{"NROWS"});
    
				# ------------------------------
    $Lis_htm_only=0;		# correct for PHDhtm single
    if ((defined $rdb{"1","PiTo"} && ! defined $rdb{"1","PTN"}) ||
	(defined $rdb{"1","PiMo"} && ! defined $rdb{"1","PMN"}) ||
	(defined $rdb{"1","PiTo"} && 
	 defined $rdb{"1","RI_S"} &&   defined $rdb{"1","OtH"}) ) {
	$Lis_htm_only=1;
	foreach $kwd ("PHL","OHL","PRHL","RI_S","pH","pL","OtH","OtL","PiTo","PTN") {
	    next if (! defined $transData{$kwd} || ! defined $rdb{"1",$kwd});
	    $kwdNew=$transData{$kwd}; $tmp1="";$tmp2="";
	    foreach $it (1 .. $rdb{"NROWS"}) {
		$rdb{$it,$kwdNew}=$sym=$rdb{$it,$kwd};
		$tmp1.=$sym;
		next if (! defined $transSec2Htm{$sym});
		undef $rdb{$it,$kwd};
		$symNew=$transSec2Htm{$sym};
		$tmp2.=$symNew;
		$rdb{$it,$kwdNew}=$symNew;}}}
				# ------------------------------
				# correct for PHDhtm all 3
    else {
	foreach $kwd ("OTN", "PTN", "PRTN","PRFTN","PR2TN","PiTo","RI_H", 
		      "OtT","pT","pN") {
	    next if (! defined $rdb{"1",$kwd});
	    $kwdNew=$kwd;
	    $kwdNew=$transData{$kwd}  if (defined $transData{$kwd});
	    foreach $it (1 .. $rdb{"NROWS"}) {
				# (1) change symbol used
		$sym=$rdb{$it,$kwd};
		$sym=$transSec2Htm{$sym} if (defined $transSec2Htm{$sym});
		undef $rdb{$it,$kwd};
		$rdb{$it,$kwd}=$sym;
				# (2) change keyword
		$rdb{$it,$kwdNew}=$rdb{$it,$kwd} if ($kwdNew ne $kwd);
	    }
	}}
				# ------------------------------
				# (2) get some statistics asf
				# ------------------------------

    $titleLoc=$fileInLoc; $titleLoc=~s/^.*\/|\..*$//g;
    ($Lok,$msg)=
        &convPhd2Html_preProcess();

    return(&errSbr("failed convPhd2Html_preProcess".
                   $msg."\n"))  if (! $Lok);

				# ------------------------------
				# (3) write HTML header
				# ------------------------------
    ($Lok,$msg)=
	&convPhd2Html_wrtHead($fileInLoc,$titleLoc,$Lhead,$fhoutHtml,$fileOutLoc,\%css_phd);

    return(&errSbr("failed convPhd2Html_wrtHead".
                   $msg."\n"))  if (! $Lok);
                                # ------------------------------
                                # (4) write HTML body (header)
				# in GLOBAL: @kwdWant,
				#            %transDescr,%transAbbr
				#            $Lbrief,$Lnormal,$Ldetail
                                # ------------------------------

    ($Lok,$msg)=
	&convPhd2Html_wrtBodyHdr($titleLoc,$fhoutHtml);

    return(&errSbr("failed convPhd2Html_wrtBodyHdr".
                   $msg."\n"))  if (! $Lok);

				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);
	
				# --------------------------------------------------
				# (5) write HTML body: prediction
				# --------------------------------------------------
				# make all of same length
    print $fhoutHtml 
	"<PRE style=\"font-type:courier\">\n";

				# ------------------------------
				# brief summary
				# ------------------------------
    if ($Lbrief) {
	$#kwdWantTmp=0;
	foreach $kwd (@kwdWant) {
	    next if ($kwd=~/^[OP](REL|RTN|RHL|RMN)|^p[HELTMN]/);
	    push(@kwdWantTmp,$kwd); }
	print $fhoutHtml "<STRONG><A NAME=\"phd_brief\">PHD results (brief)<\/A><\/STRONG><P>\n";
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"brief",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      \%css_phd,\@kwdWantTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n"; }

				# ------------------------------
				# normal 
				# ------------------------------
    if ($Lnormal) {
	print $fhoutHtml "<STRONG><A NAME=\"phd_normal\">PHD results (normal)<\/A><\/STRONG><P>\n";
	$#kwdWantTmp=0;
	foreach $kwd (@kwdWant) {
	    next if ($kwd=~/^[OP](REL)|^p[HELTMN]/);
	    push(@kwdWantTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"normal",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      \%css_phd,\@kwdWantTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n";}

				# ------------------------------
				# full details
				# ------------------------------
    if ($Ldetail) {
	print $fhoutHtml "<STRONG><A NAME=\"phd_detail\">PHD results (detail)<\/A><\/STRONG><P>\n";
	$#kwdWantTmp=0;
	foreach $kwd (@kwdWant) {
	    next if ($kwd=~/^RI/ || 
		     $kwd=~/^(PHEL|OHEL|Obie|PRMN|OMN|PMN|PiMo)$/);
	    next if ($Lis_htm_only && $kwd=~/^p[HETL]$/);
	    push(@kwdWantTmp,$kwd); }

				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,
				      "normal",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      \%css_phd,\@kwdWantTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n"; }
    print $fhoutHtml "<\/PRE>\n";

				# ------------------------------
				# (6) write HTML body: fin
				# ------------------------------
	print $fhoutHtml 
	"</BODY>\n",
	"</HTML>\n";
    close($fhoutHtml)           if ($fhoutHtml ne "STDOUT");

    return(1,"ok $sbrName");
}				# end of convPhd2Html

#===============================================================================
sub convPhd2Html_ini {
    local($nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)=@_;
    local($sbrName2,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_ini                       
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp."convPhd2Html_ini";
    $fhinLoc="FHIN_"."convPhd2Html_ini";$fhoutLoc="FHOUT_"."convPhd2Html_ini";
				# check arguments
    return(&errSbr("not def nresPerLineLoc!",$sbrName2))     if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$sbrName2))        if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$sbrName2))        if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$sbrName2))        if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$sbrName2))        if (! defined $riSubSymLoc);

				# columns to read
    @kwdWant=
	(
	 "AA",
	 "OHEL","PHEL","RI_S",               "pH","pE","pL",
	 "Obie","Pbie","RI_A",               "OREL","PREL",
	 "OMN", "PMN", "RI_M","PRMN","PiMo", "pM","pN",
#	 "","","","",
	 );
				# for HTM : header
    @kwdWantHdr=
	("NHTM_BEST","NHTM_2ND_BEST",
	 "REL_BEST","REL_BEST_DIFF", "REL_BEST_DPROJ",
	 "MODEL","MODEL_DAT",
	 "HTMTOP_OBS","HTMTOP_PRD","HTMTOP_MODPRD","HTMTOP_RID","HTMTOP_RIP",
	 );

				# e.g. 'L' to ' ' in writing
    %transSym=
	('L',    " ",
	 'i',    " ",
	 'N',    " ",
	 );
				# translate PHDsec to PHDhtm
    %transSec2Htm=
	('H',    "M",
	 'E',    "N",
	 'L',    "N",
	 'T',    "M",
	 'M',    "M",
	 'N',    "N",
	 );
				# abbreviations translated in array read
    %transData=
	('OTN',    "OMN",
	 'PTN',    "PMN",
	 'PRTN',   "PRMN",
#	 'PFTN',   "PFMN",
	 'PiTo',   "PiMo",
	 'RI_H',   "RI_M",
	 'OtT',    "OtM",
	 'pH',     "pM",
	 'pT',     "pM",
	 'pL',     "pM",
	 
	 'RI_S',   "RI_M",
	 
	 'OHL',    "OMN",
	 'PHL',    "PMN",
	 'PRHL',   "PRMN",
	 'pH',     "pM",
	 'pL',     "pN",
	 'OtH',    "OtM",
	 'OtL',    "OtN",

	 );

				# abbreviations used to write the rows
    %transAbbr=
	(
	 'AA'  ,   "AA ",

	 'OHEL',   "OBS_sec",
	 'PHEL',   "PHD_sec",
	 'RI_S',   "Rel_sec",
	 'SUBsec', "SUB_sec",
	 'pH',     " pH_sec",
	 'pE',     " pE_sec",
	 'pL',     " pL_sec",
#	 '', "",

	 'OREL',   "OBS_acc",
	 'PREL',   "PHD_acc",
	 'Obie',   "O_3_acc",
	 'Pbie',   "P_3_acc",
	 'RI_A',   "Rel_acc",
	 'SUBacc', "SUB_acc",
#	 '', "",

	 'OMN',    "OBS_htm",
	 'PMN',    "PHD_htm",
	 'PRMN',   "PHDrhtm",
#	 'PFMN',   "PHDfhtm",
	 'PiMo',   "PiMohtm",
	 'RI_M',   "Rel_htm",
	 'SUBhtm', "SUB_htm",
	 'pM',     " pT_htm",
	 'pN',     " pN_htm",
#	 '', "",

	 );
	       
    %transDescr=
	(
				# sequence
	 'AA',     "amino acid sequence",
				# secondary structure
	 'OHEL',   "observed secondary structure: H=helix, E=extended (sheet), blank=other (loop)",
	           
	         
	 'PHEL',   "PHD predicted secondary structure: H=helix, E=extended (sheet), blank=other (loop)".
	           "\n"."PHD = PHD: Profile network prediction HeiDelberg",
	 'RI_S',   "reliability index for PHDsec prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBsec', "subset of the PHDsec prediction, for all residues with an expected average accuracy > 82% (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  L: is loop (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubSecLoc\n",
	 'pH',     "'probability' for assigning helix (1=high, 0=low)",
	 'pE',     "'probability' for assigning strand (1=high, 0=low)",
	 'pL',     "'probability' for assigning neither helix, nor strand (1=high, 0=low)",


				# solvent accessibility
	 'OREL',   "observerd relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
	 'PREL',   "PHD predicted relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
	 'Obie',   "observerd relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
	 'Pbie',   "PHD predicted relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
	 'RI_A',   "reliability index for PHDacc prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBacc', "subset of the PHDacc prediction, for all residues with an expected average correlation > 0.69 (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  I: is intermediate (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubAccLoc\n",

	 '', "",

	 'OMN',    "observed membrane helix: M=helical transmembrane region, blank=non-membrane",
	           
	         
	 'PMN',    "PHD predicted membrane helix: M=helical transmembrane region, blank=non-membrane".
	           "\n"."PHD = PHD: Profile network prediction HeiDelberg",
	 'PRMN',   "refined PHD prediction: M=helical transmembrane region, blank=non-membrane",
	 'PiMo',   "PHD prediction of membrane topology: T=helical transmembrane region, i=inside of membrane, o=outside of membrane",
	 'RI_M',   "reliability index for PHDhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBhtm', "subset of the PHDhtm prediction, for all residues with an expected average accuracy > 98% (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  N: is non-membrane region (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubSecLoc\n",
	 'pM',     "'probability' for assigning transmembrane helix",
	 'pN',     "'probability' for assigning globular region",


	 );
    %transDescrShort=
	('i',      "inside region",
	 'o',      "outside region",
	 'M',      "membrane helix",
	 );

    $lenAbbr=10;		# width of abbreviation at begin of each row
		
    return(1,"ok $sbrName2");
}				# end of convPhd2Html_ini

#===============================================================================
sub convPhd2Html_iniStyles {
#-------------------------------------------------------------------------------
#   convPhd2Html_iniStyles    sets styles for convPhd2Html
#       out GLOBAL:             %css_phd{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#-------------------------------------------------------------------------------

    %css_phd=
	(
				# residue charges
	 'res-K',    "{color:blue}",
	 'res-R',    "{color:blue}",
	 'res-D',    "{color:red}",
	 'res-E',    "{color:red}",
				# secondary structure
	 'sec-H',    "{color:red}",
	 'sec-E',    "{color:blue}",
	 'sec-L',    "{color:green}",

	 'sec-Hsub', "{background-color:red;color:white}",
	 'sec-Esub', "{background-color:blue;color:white}",
	 'sec-Lsub', "{background-color:green;color:white}",

	 'sec-pH',   "{background-color:red;color:white}",
	 'sec-pE',   "{background-color:blue;color:white}",
	 'sec-pL',   "{background-color:green;color:white}",

	 'sec-0',    "{color:silver}",
	 'sec-1',    "{color:silver}",
	 'sec-2',    "{color:silver}",
	 'sec-3',    "{color:silver}",
	 'sec-4',    "{color:gray}",
	 'sec-5',    "{color:gray}",
	 'sec-6',    "{color:gray}",
	 'sec-7',    "{color:black}",
	 'sec-8',    "{color:black}",
	 'sec-9',    "{color:black}",
				# transmembrane
	 'htm-M',    "{color:purple}",
	 'htm-N',    "{color:olive}",

	 'htm-Msub', "{background-color:purple;color:white}",
	 'htm-Nsub', "{background-color:olive;color:white}",

	 'htm-pM',   "{background-color:purple;color:white}",
	 'htm-pN',   "{background-color:olive;color:white}",

	 'htm-i',    "{color:olive}",
	 'htm-o',    "{color:teal}",

	 'htm-0',    "{color:silver}",
	 'htm-1',    "{color:silver}",
	 'htm-2',    "{color:silver}",
	 'htm-3',    "{color:silver}",
	 'htm-4',    "{color:silver}",
	 'htm-5',    "{color:gray}",
	 'htm-6',    "{color:gray}",
	 'htm-7',    "{color:gray}",
	 'htm-8',    "{color:black}",
	 'htm-9',    "{color:black}",
				# accessibility
	 'acc-e',    "{color:aqua}",
	 'acc-i',    "{color:gray}",
	 'acc-b',    "{color:maroon}",
	 'acc-esub', "{background-color:aqua;color:white}",
	 'acc-isub', "{background-color:gray;color:white}",
	 'acc-bsub', "{background-color:maroon;color:white}",

	 'acc-PREL', "{background-color:gray;color:white}",
	 'acc-OREL', "{background-color:gray;color:white}",

	 'acc-0',    "{color:silver}",
	 'acc-1',    "{color:silver}",
	 'acc-2',    "{color:gray}",
	 'acc-3',    "{color:gray}",
	 'acc-4',    "{color:gray}",
	 'acc-5',    "{color:black}",
	 'acc-6',    "{color:black}",
	 'acc-7',    "{color:black}",
	 'acc-8',    "{color:black}",
	 'acc-9',    "{color:black}",
	 );
}				# end of convPhd2Html_iniStyles

#===============================================================================
sub convPhd2Html_wrtOneLevel {
    local($nblocksLoc,$lenAbbrLoc,$fhoutHtml,$fileOutLoc,$modeLoc,
	  $nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
	  $rh_css_phd,$ra_kwdWantLoc)=@_;
    local($sbrName3,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtOneLevel    writes one level of detail
#       in:                     $nblocksLoc=      number of blocks 
#                                                 (with NresPerlLineLoc written per block)
#       in:                     $lenAbbrLoc=      
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $fileOutLoc=      HTML output file
#       in:                     $modeLoc=         controls what to write
#                                   <brief|normal|detail>
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       in:                     $rh_css_phd=      reference to %css_phd{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#       in:                     
#       in GLOBAL:              %transSym,%transAbbr
#       out:                    1|0,msg,  implicit: write to $fhoutHtml
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtOneLevel";
				# check arguments
    return(&errSbr("not def nblocksLoc!",$sbrName3))     if (! defined $nblocksLoc);
    return(&errSbr("not def lenAbbrLoc!",$sbrName3))     if (! defined $lenAbbrLoc);
    return(&errSbr("not def fhoutHtml!",$sbrName3))      if (! defined $fhoutHtml);
    return(&errSbr("not def fileOutLoc!"))               if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!"))                  if (! defined $modeLoc);
    return(&errSbr("not def nresPerLineLoc!",$sbrName3)) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$sbrName3))    if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$sbrName3))    if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$sbrName3))    if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$sbrName3))    if (! defined $riSubSymLoc);
    return(&errSbr("not def rh_css_phd!",$sbrName3))     if (! defined $rh_css_phd);
    return(&errSbr("not def $ra_kwdWantLoc!",$sbrName3)) if (! $ra_kwdWantLoc);

				# --------------------------------------------------
				# loop over all blocks
				#    i.e. residues 1-60 ..
				# --------------------------------------------------

    foreach $itBlock (1..$nblocksLoc) {
				# begin and end of current block
	$itBeg=1+($itBlock-1)*$nresPerLineLoc;
	if ($nresPerLineLoc) {	# split into blocks
	    $itEnd=$itBlock*$nresPerLineLoc;}
	else {
	    $itEnd=$rdb{"NROWS"} }
				# correct
	$itEnd=$rdb{"NROWS"} if ($itEnd > $rdb{"NROWS"});

	last if ($itEnd<$itBeg);

				# first: counter
	$ncount=1+$itEnd-$itBeg;

	$string=&myprt_npoints($ncount,$itEnd);
	$tmp=" " x $lenAbbrLoc;
	print $fhoutHtml "$tmp"," ",$string,"\n";

				# --------------------------------------------------
				# loop over all keywords
				#    i.e. all rows (AA,OHEL,PHEL)
				# --------------------------------------------------
	foreach $itKwd (1..$#{$ra_kwdWantLoc}) {
	    $kwd=$ra_kwdWantLoc->[$itKwd];
	    next if (! defined $rdb{$itBeg,$kwd});
				# all into one string
	    $string="";
				# ri
	    if    ($kwd eq "RI_S") { $relStrong=$riSubSecLoc; }
	    elsif ($kwd eq "RI_A") { $relStrong=$riSubAccLoc; }
	    elsif ($kwd eq "RI_M") { $relStrong=$riSubHtmLoc; }
				# probability
	    $#string=0
		if ($kwd=~/^p[HELTMN]$/ || $kwd=~/^[OP]REL/);
	    
				# ------------------------------
				# loop over protein
				# ------------------------------
	    foreach $itRes ($itBeg .. $itEnd) {
		$sym=$rdb{$itRes,$kwd}; 
				# normalise relative acc to numbers 0-9
		$sym=&exposure_project_1digit($sym)
		    if ($kwd =~ /^[OP]REL/);
		
				# ------------------------------
				# probability PHDsec, PHDhtm
		if ($kwd=~/^p[HELTMN]$/) {
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="."; }}}
				# ------------------------------
				# relative accessibility
		elsif ($kwd=~/^[OP]REL$/) {
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="."; }}}
				# ------------------------------
				# simple strings
		else {
		    $symPrt=$sym;
				# HTM: from 'HL' -> 'MN'
		    $symPrt=$transSec2Htm{$sym} if ($kwd=~/^[OP](MN|RMN|FMN)/);
				# for brief RI =< |*>
		    if ($modeLoc eq "brief" && $kwd=~/^RI/) {
			$symPrt="*";
			$symPrt=" " if ($sym < $relStrong); }
				# which style
		    if    ($kwd=~/^[OP]HEL|^p[HEL]|RI_S/)  { 
			$kwdCss="sec-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](REL|bie)|^RI_A/)    { 
			$kwdCss="acc-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](MN|RMN|iMo)|^p[MN]|^RI_M/) { 
			$kwdCss="htm-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# sequence
		    elsif ($kwd=~/^AA/){
			$kwdCss="res-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# 'L' -> ' '
		    $symPrt=$transSym{$sym} if (defined $transSym{$sym} && $kwd !~/^[OP]REL/
						&& $kwd ne "AA" && $kwd !~/PiMo/ 
						&& $symPrt ne " " && $symPrt ne "*");
						
			
		    if    ($kwd eq "AA" && defined $kwdCss && defined $rh_css_phd->{$kwdCss}) {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>"; 
		    }
		    elsif (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss} 
			   || $kwd =~/^[OP]REL/ || $kwd eq "AA"
			   || $symPrt eq " "    || $symPrt eq "*" || $symPrt eq ".") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>"; } } }
#			$string.="<FONT CLASS=\"".$kwdCss."\">".$symPrt."<\/FONT>"; } } }
	    $abbr=$kwd;
	    $abbr=$transAbbr{$kwd} if (defined $transAbbr{$kwd});
	    $empty=" " x ($lenAbbrLoc-length($abbr));
	    $lenTotal=length($empty.$abbr);
				# link description of row to header
	    if ($fileOutLoc) {
#		$abbr="<A HREF=\"$fileOutLoc#$kwd\">$abbr</A>$empty";}
		$abbr="<A HREF=\"#$kwd\">$abbr</A>$empty";}
	    else {
		$abbr="<A HREF=\"#$kwd\">$abbr</A>$empty";}

				# probability PHDsec
	    if ($kwd=~/^p[HELTMN]$/) {
		if ($kwd=~/^p[HEL]$/) {
		    $kwdCss="sec-".$kwd; }
		elsif ($kwd=~/^p[TMN]$/) {
		    $kwdCss="htm-".$kwd; }

		if (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss}) {
		    $tmp1="";
		    $tmp2=""; }
		else {
		    $tmp1="<FONT CLASS=".$kwdCss.">";
		    $tmp2="<\/FONT>";}
		foreach $it (1..9) {
		    $it2=10-$it;
		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)/10;
		    $txt= $abbr.$string[$it2].sprintf("  %2.1f ",$tmp3);
		    $txt.=$abbr if (! $nresPerLineLoc);
		    print $fhoutHtml $txt,"\n";}
		print $fhoutHtml " " x $lenTotal, "-" x $ncount,"\n";}

				# relative acc PHDacc
	    elsif ($kwd=~/^[OP]REL$/) {
		$kwdCss="acc-".$kwd;
		if (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss}) {
		    $tmp1="";
		    $tmp2=""; }
		else {
		    $tmp1="<FONT CLASS=".$kwdCss.">";
		    $tmp2="<\/FONT>";}
		foreach $it (1..9) {
		    $it2=10-$it;
		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)*($it2+1);
		    $txt= $abbr.$string[$it2].sprintf("  %3d%-s ",int($tmp3),"%");
		    $txt.=$abbr if (! $nresPerLineLoc);
		    print $fhoutHtml $txt,"\n";}
		print $fhoutHtml " " x $lenTotal, "-" x $ncount,"\n";}

	    else {
		print $fhoutHtml "$abbr $string\n"; }

				# ------------------------------
				# skip if brief (or detail)
	    if ($modeLoc eq "brief" || $modeLoc eq "detail") {
				# spacer
		print $fhoutHtml "\n"
		    if ($kwd=~/RI/);
		next; }

				# ------------------------------
				# subset after REL
	    if ($kwd=~/RI/) {
		if    ($kwd eq "RI_S") { 
		    $kwdTmp="PHEL"; $kwdTmp2="SUBsec"; $abbr=$transAbbr{"SUBsec"};}
		elsif ($kwd eq "RI_A") { 
		    $kwdTmp="Pbie"; $kwdTmp2="SUBacc"; $abbr=$transAbbr{"SUBacc"};}
		elsif ($kwd eq "RI_M") { 
		    $kwdTmp="PMN";  $kwdTmp2="SUBhtm"; $abbr=$transAbbr{"SUBhtm"};}

		$string="";
		foreach $itRes ($itBeg .. $itEnd) {
		    $sym=$rdb{$itRes,$kwdTmp}; 
		    $rel=$rdb{$itRes,$kwd}; 
		    if ($rel >= $relStrong) {
			$symPrt=$sym; 
				# HTM: from 'HL' -> 'MN'
			$symPrt=$transSec2Htm{$sym} if ($kwd=~/^RI_M/);}
		    else {
			$symPrt=$riSubSymLoc; }
#		    print "xx kwd=$kwd, sym=$sym, symPrt=$symPrt,\n";
		    if    ($kwd=~/^RI_S/) { $kwdCss="sec-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_A/) { $kwdCss="acc-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_M/) { $kwdCss="htm-".$symPrt."sub"; }

		    if (! defined $kwdCss || ! defined $rh_css_phd->{$kwdCss} || $symPrt eq " ") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>";}  
		}

		$empty=" " x ($lenAbbrLoc-length($abbr));
				# link description of row to header
		if ($fileOutLoc) {
#		    $abbr="<A HREF=\"$fileOutLoc#$kwdTmp2\">$abbr</A> $empty"; }
		    $abbr="<A HREF=\"#$kwdTmp2\">$abbr</A> $empty"; }
		else {
		    $abbr="<A HREF=\"#$kwd\">$abbr</A> $empty";}

		print $fhoutHtml $abbr,$string,"\n";
				# after: spacer
		print $fhoutHtml "\n";
	    }			# end of subset

	}			# end of loop over all rows
	print $fhoutHtml "\n";

    }				# end of all blocks
    print $fhoutHtml "\n";
    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtOneLevel

#===============================================================================
sub convPhd2Html_preProcess {
#    local($rh_rdb)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_preProcess     compiles probabilites from network output
#                               and composition AND greps stuff from HEADER!
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#       out:                    $rh_rdb{'p<HELTMN>',$it}=   probability
#       out:                    $rh_rdb{'sec','<HELTMN>'}=  secondary str composition
#				         accuracy: 2 decimals, in percentage
#       out:                    $rh_rdb{'sec','class'}=    sec str class 
#                                                          <all-alpha|all-beta|alpha-beta|mixed>
#       out:                    $rh_rdb{'sec','class','txt'}=description of classes (
#                                                          formatted text)
#       out:                    $rh_rdb{'seq','$aa'}=     residue composition
#				         accuracy: 2 decimals, in percentage
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_preProcess";
				# check arguments
#    return(&errSbr("not def rh_rdb!",   $sbrName3))    if (! defined $rdb{'NROWS'});

				# ------------------------------
				# compile membrane prob
				#      pT and pN normalised to 0-9
				#      pT + pN = 9
				# ------------------------------
    if (defined $rdb{"1","OtM"}) {
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sum=$rdb{$itRes,"OtM"}+$rdb{$itRes,"OtN"};
	    $rdb{$itRes,"pM"}=int(10*($rdb{$itRes,"OtM"}/$sum));
	    $rdb{$itRes,"pM"}=9 if ($rdb{$itRes,"pM"} > 9);
	    $rdb{$itRes,"pN"}=int(10*($rdb{$itRes,"OtN"}/$sum)); 
	    $rdb{$itRes,"pN"}=9 if ($rdb{$itRes,"pN"} > 9);
	}}

				# ------------------------------
				# compile PHDsec prob
				#      pH, pE, pL normalised to 0-9
				#      pH + pE +pL = 9
				# ------------------------------
    if (! defined $rdb{"1","pH"} && defined $rdb{"1","OtH"}) {
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sum=$rdb{$itRes,"OtH"}+$rdb{$itRes,"OtE"}+$rdb{$itRes,"OtL"};
	    $rdb{$itRes,"pH"}=int(10*($rdb{$itRes,"OtH"}/$sum));
	    $rdb{$itRes,"pH"}=9  if ($rdb{$itRes,"pH"} > 9);
	    $rdb{$itRes,"pE"}=int(10*($rdb{$itRes,"OtE"}/$sum)); 
	    $rdb{$itRes,"pE"}=9  if ($rdb{$itRes,"pE"} > 9);
	    $rdb{$itRes,"pL"}=int(10*($rdb{$itRes,"OtL"}/$sum)); 
	    $rdb{$itRes,"pL"}=9  if ($rdb{$itRes,"pL"} > 9);
	} }
    
				# ------------------------------
				# compile residue composition
				# ------------------------------
    if (defined $rdb{"1","AA"}) {
	undef %tmp;
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sym=$rdb{$itRes,"AA"};
	    $tmp{$sym}=0        if (! defined $tmp{$sym});
	    ++$tmp{$sym}; }
				# set zero
	foreach $sym (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	    $rdb{$sym,"seq"}=0; }
	
	if ($rdb{"NROWS"} > 0) {
	    foreach $sym (keys %tmp){
				# accuracy: 2 decimals, in percentage
		$rdb{$sym,"seq"}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rdb{"NROWS"})) ; }}}

				# ------------------------------
				# compile sec str composition
				# ------------------------------
    if (defined $rdb{"1","PHEL"}) {
	undef %tmp;
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sym=$rdb{$itRes,"PHEL"};
	    $tmp{$sym}=0        if (! defined $tmp{$sym});
	    ++$tmp{$sym}; }
                                # set 0
        foreach $sym ("H","E","L","T","N") {
            $rdb{"sec",$sym}=0; }
                                # assign
	if ($rdb{"NROWS"} > 0) {
	    foreach $sym (keys %tmp){
				# accuracy: 2 decimals, in percentage
		$rdb{"sec",$sym}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rdb{"NROWS"})) ; }}
				# ------------------------------
				# assign SEC STR class
				# ------------------------------
        $description= "'all-alpha':   %H > 45% AND %E <  5%\n";
        $description.="'all-beta':    %H <  5% AND %E > 45%\n";
        $description.="'alpha-beta':  %H > 30% AND %E > 20%\n";
        $description.="'mixed':       all others\n";
        $rdb{"sec","class","txt"}=$description;
        if    ($rdb{"sec","H"} > 45 && $rdb{"sec","E"} <  5) {
            $rdb{"sec","class"}="all-alpha";}
        elsif ($rdb{"sec","H"} >  5 && $rdb{"sec","E"} > 45) {
            $rdb{"sec","class"}="all-beta";}
        elsif ($rdb{"sec","H"} > 30 && $rdb{"sec","E"} > 20) {
            $rdb{"sec","class"}="alpha-beta";}
        else {
            $rdb{"sec","class"}="mixed";}
    }
				# ------------------------------
				# HTM header
				# ------------------------------
    if ($#kwdWantHdr > 0 && defined $rdb{"1","PiMo"}) {
	@tmp=split(/\#/,$rdb{"header"});
	undef %tmp;
	foreach $tmpHdr (@tmp) {
	    foreach $kwd (@kwdWantHdr) {
		next if ($tmpHdr !~ /$kwd[\s\t:]/);
		$tmp=$tmpHdr;
		$tmp=~s/^.*$kwd[\s\t:]+(.+)$/$1/g;
		$tmp=~s/^\s*|[\s\n]*$//g;
		$tmp{$kwd}.="\n".$tmp if (defined $tmp{$kwd}); 
		$tmp{$kwd}=$tmp       if (! defined $tmp{$kwd});
		last; }}
	foreach $kwd (@kwdWantHdr) {
	    next if (! defined $tmp{$kwd});
	    $rdb{"header",$kwd}=$tmp{$kwd}; }}

    return(1,"ok $sbrName3");
}				# end of convPhd2Html_preProcess

#===============================================================================
sub convPhd2Html_wrtHead {
    local($fileInLoc,$titleLoc,$Lhead,$fhoutHtml,$fileOutLoc,$rh_css_phd)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtHead        writes HEAD part of HTML file
#       in:                     $fileInLoc=       PHDrdb file
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $Lhead=           if 1 write header,
#                                                 if 0 open file only
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $fileOutLoc=      HTML output file
#       in:                     $rh_css_phd=      reference to %css_phd{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtHead";
				# check arguments
    return(&errSbr("not def fileInLoc!", $sbrName3)) if (! defined $fileInLoc);
    return(&errSbr("not def titleLoc!",  $sbrName3)) if (! defined $titleLoc);
    return(&errSbr("not def fileOutLoc!",$sbrName3)) if (! defined $fileOutLoc);
    return(&errSbr("not def fhoutHtml!", $sbrName3)) if (! defined $fhoutHtml);
    return(&errSbr("not def rh_css_phd!",$sbrName3)) if (! defined $rh_css_phd);

    
    if ($fileOutLoc) {
	&open_file($fhoutHtml,">$fileOutLoc") || 
	    return(&errSbr("fileOutLoc=$fileOutLoc, not created",$sbrName3)); }

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok $sbrName3")    if (! $Lhead);

    $style= "<STYLE TYPE=\"text/css\">\n";
    $style.="<!-- \n";
				# PHDsec
    foreach $kwd ("H","E","L") {
	$style.="FONT."."sec-".$kwd.$rh_css_phd->{"sec-".$kwd}."\n";
	$style.="FONT."."sec-".$kwd."sub".$rh_css_phd->{"sec-".$kwd."sub"}."\n"; 
	$style.="FONT."."sec-"."p".$kwd.$rh_css_phd->{"sec-"."p".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."sec-".$kwd.$rh_css_phd->{"sec-".$kwd}."\n";}
				# PHDacc
    foreach $kwd ("e","i","b") {
	$style.="FONT."."acc-".$kwd.$rh_css_phd->{"acc-".$kwd}."\n"; 
	$style.="FONT."."acc-".$kwd."sub".$rh_css_phd->{"acc-".$kwd."sub"}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."acc-".$kwd.$rh_css_phd->{"acc-".$kwd}."\n";}
    foreach $kwd ("PREL","OREL"){
	$style.="FONT."."acc-".$kwd.$rh_css_phd->{"acc-".$kwd}."\n";}
				# PHDhtm
    foreach $kwd ("M","N") {
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n"; 
	$style.="FONT."."htm-".$kwd."sub".$rh_css_phd->{"htm-".$kwd."sub"}."\n"; 
	$style.="FONT."."htm-"."p".$kwd.$rh_css_phd->{"htm-"."p".$kwd}."\n"; }
    foreach $kwd ("i","o") {
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n";}

				# sequence: only for HTM
    if ($#kwdWantHdr > 0 && defined $rdb{"1","PiMo"}) {
	foreach $kwd ("E","D","K","R") {
	    $style.="FONT."."res-".$kwd.$rh_css_phd->{"res-".$kwd}."\n";}}

    $style.=" -->\n";
    $style.="<\/STYLE>\n";

    ($Lok,$msg)=
	&htmlWrtHead($fhoutHtml,"PHD prediction ($titleLoc)",$style);

    return(&errSbr("failed writing HTML header (file=$fileInLoc)",$sbrName3))
	if (! $Lok);

    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtHead

#===============================================================================
sub convPhd2Html_wrtBodyHdr {
    local($titleLoc,$fhoutHtml)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtBodyHdr     writes first part of HTML BODY (TOC, syntax)
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#       in GLOBAL:              @kwdWant,%transDescr,%transAbbr
#       in GLOBAL:              $Lbrief,$Lnormal,$Ldetail
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtBodyHdr";
				# check arguments
    return(&errSbr("not def titleLoc!",  $sbrName3)) if (! defined $titleLoc);
    return(&errSbr("not def fhoutHtml!", $sbrName3)) if (! defined $fhoutHtml);
#    return(&errSbr("not def rh_rdb!",    $sbrName3)) if (! defined $rdb{'NROWS'});

				# ------------------------------
				# TOC asf
				# ------------------------------
    print $fhoutHtml "<BODY style=\"background:white\">\n"; # body tag
    print $fhoutHtml "<H1>PHD predictions for $titleLoc</H1>\n";
    print $fhoutHtml "\n";
    print $fhoutHtml "<I>Different levels of data:</I>\n";
    print $fhoutHtml "<OL>\n";
    print $fhoutHtml "<LI><A HREF=\"#phd_brief\"> PHD brief <\/A>\n"  if ($Lbrief);
    print $fhoutHtml "<LI><A HREF=\"#phd_normal\">PHD normal<\/A>\n"  if ($Lnormal);
    print $fhoutHtml "<LI><A HREF=\"#phd_detail\">PHD detail<\/A>\n"  if ($Ldetail);
    print $fhoutHtml "<\/OL>\n","<P><BR><P>\n","\n";
    print $fhoutHtml "<P><BR>\n";
				# ------------------------------
				# summary for protein (sec)
				# ------------------------------
    if (defined $rdb{"sec","class"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG>PHDsec summary<\/STRONG>\n";
	$rdb{"sec","class","txt"}=~s/\n/\n<LI>/g;
	$rdb{"sec","class","txt"}=~s/<LI>$//g;
	print $fhoutHtml 
	    "overall your protein can be classified as:<BR>",
	    "<STRONG>",$rdb{"sec","class"},"<\/STRONG>\n",
	    " given the following classes:<BR>\n",
	    "<UL><LI>",$rdb{"sec","class","txt"},"<\/UL>\n"; 
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<P><BR><P>\n";}
	
				# ------------------------------
				# write sec str composition
    if (defined $rdb{"1","PHL"} || defined $rdb{"1","PHEL"}) {
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG>Predicted secondary structure composition for your protein:</STRONG>\n",
	    "<TABLE BORDER=1 CELLPADDING=2>\n",
	    "<TR>";
	$ct=0;
	foreach $sym (split(//,"HEL")) {
	    next if (! defined $rdb{"sec",$sym});
	    printf $fhoutHtml "%-s %3.1f","<TD>%$sym:",$rdb{"sec",$sym};}
	print $fhoutHtml 
	    "<\/TR>\n",
	    "<\/TABLE>\n",
	    "<\/UL><P><BR>\n";}
    print $fhoutHtml "\n";
    
				# ------------------------------
				# summary for protein (htm)
				# ------------------------------
    if (defined $rdb{"header","NHTM_BEST"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG>PHDhtm summary<\/STRONG>\n";

	$nbest=$rdb{"header","NHTM_BEST"};    $nbest=~s/(\d+).*$/$1/g;
	$n2nd= $rdb{"header","NHTM_2ND_BEST"};$n2nd=~s/(\d+).*$/$1/g;
	$txtBest= "helix"; $txtBest= "helices" if ($nbest > 1);
	$txt2nd=  "helix"; $txt2nd=  "helices" if ($n2nd > 1);
	
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG>NHTM=$nbest<\/STRONG><BR>\n",
	        "PHDhtm detected <STRONG>$nbest<\/STRONG> membrane ".
		"$txtBest for the <STRONG>best<\/STRONG> model.".
		    "The second best model contained $n2nd $txt2nd.\n";
	$top=           $rdb{"header","HTMTOP_PRD"}; $top=~s/(\S+).*$/$1/g;
	$rel_best_dproj=$rdb{"header","REL_BEST_DPROJ"};$rel_best_dproj=~s/^(\S+).*$/$1/g;
	$rel_best=      $rdb{"header","REL_BEST"};$rel_best=~s/^(\S+).*$/$1/g;
	$htmtop_rid=    $rdb{"header","HTMTOP_RID"};$htmtop_rid=~s/^(\S+).*$/$1/g;
	$htmtop_rip=    $rdb{"header","HTMTOP_RIP"};$htmtop_rip=~s/^(\S+).*$/$1/g;
	print $fhoutHtml 
	    "<LI><STRONG>TOP=$top<\/STRONG><BR>\n",
	         "PHDhtm predicted the topology ",$top,", i.e. the first loop region is $top",
	      " (Note: this prediction may be problematic when the sequence you sent ",
	      "starts or ends with a region predicted in a membrane helix!)\n",
	    "<LI>Reliability of best model=",$rel_best_dproj," (0 is low, 9 is high)\n",
	    "<LI>Zscore for best model=",$rel_best,"\n",
	    "<LI>Difference of positive charges (K+R) inside - outside=",
	      $htmtop_rid," (the higher the value, the more reliable)\n",
	    "<LI>Reliability of topology prediction =",
	      $htmtop_rip," (0 is low, 9 is high)\n";
				# strength of single HTMs
	if (defined $rdb{"header","MODEL_DAT"}) {
	    @tmp=split(/\n/,$rdb{"header","MODEL_DAT"});
	    print $fhoutHtml 
		"<LI>Details of the strength of each predicted membrane helix:<BR>\n",
		"(sorted by strength, strongest first)<BR>\n";
	    
	    print $fhoutHtml
		"<TABLE BORDER=1>\n",
		"<TR><TD>N HTM<TD>Total score<TD>Best HTM<TD>c-N<\/TR>\n";
	    foreach $tmp (@tmp) {
		$tmp=~s/\n+//g;@tmp2=split(/,/,$tmp);
		print $fhoutHtml "<TR>";
		foreach $tmp2 (@tmp2) {
		    print $fhoutHtml "<TD>$tmp2"; }
		print $fhoutHtml "<\/TR>\n"; }
	    print $fhoutHtml "<\/TABLE>\n"; }
				# table with regions
	$tmp="";
	foreach $it (1..$rdb{"NROWS"}){
	    $tmp.=$rdb{$it,"PiMo"};}
				# get segments
				# out GLOBAL: %segment
	($Lok,$msg)=
	    &getSegment($tmp);  return(&errSbrMsg("failed to get segment for $tmp",
						  $sbrName3)) if (! $Lok);

	print $fhoutHtml
	    "<LI>Overview over transmembrane segments:<BR>\n",
	    "<TABLE BORDER=1>\n",
	    "<TR><TD>Positions<TD>Segments<TD>Explain<\/TR>\n";
	foreach $ctSegment (1..$segment{"NROWS"}){
	    $sym=$segment{$ctSegment};
	    $txt="?=error";
	    $txt=$transDescrShort{$sym} if (defined $transDescrShort{$sym});
	    print $fhoutHtml
		"<TR><TD>",
		sprintf("%5d",$segment{"beg",$ctSegment}),"-",
		sprintf("%5d",$segment{"end",$ctSegment}),
		"<TD>",$segment{$ctSegment},$segment{"seg",$ctSegment},
		"<TD>$txt ",$segment{"seg",$ctSegment},
		"<\/TR>\n"; }
	print $fhoutHtml
	    "<\/TABLE>\n";
	    
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<P><BR>\n";}
	
				# ------------------------------
				# write residue composition
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG>Residue composition for your protein:</STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n",
	"<TR>";
    $ct=0;
    foreach $aa (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	++$ct;
	if ($ct > 5) {$ct=1;
		      print $fhoutHtml "<\/TR>\n<TR>";}
	printf $fhoutHtml "%-s %3.1f","<TD>%"."$aa:",$rdb{$aa,"seq"};}
    print $fhoutHtml 
	"<\/TABLE>\n",
	"<\/UL><P><BR>\n";
    
				# ------------------------------
				# syntax style:
				#      kwd : explanation
				# ------------------------------
    print $fhoutHtml "<P><BR><P>\n";
    print $fhoutHtml "<TABLE BORDER=1 CELLPADDING=2>\n";
    foreach $kwd (@kwdWant) {
	next if (! defined $rdb{"1",$kwd});
	$tmp=$transDescr{$kwd}; $tmp=~s/\n$//; $tmp=~s/\n\n+/\n/g; $tmp=~s/\n/<BR>/g;
	print $fhoutHtml
	    "<TR VALIGN=TOP>",
	    "<TD><A NAME=\"$kwd\">",$transAbbr{$kwd},"<\/A>: <\/TD>",
	    "<TD>$tmp<\/TD><\/TR>\n";
				# subset after REL
	next if ($kwd !~ /RI/);
	if    ($kwd eq "RI_S") { $kwd2="SUBsec"; }
	elsif ($kwd eq "RI_A") { $kwd2="SUBacc"; }
	elsif ($kwd eq "RI_M") { $kwd2="SUBhtm"; }
	$abbr= $transAbbr{$kwd2};
	$descr=$transDescr{$kwd2}; $descr=~s/\n$//; $descr=~s/\n\n+/\n/g; $descr=~s/\n/<BR>/g;
	print $fhoutHtml
	    "<TR VALIGN=TOP>",
	    "<TD><A NAME=\"$abbr\">",$abbr,"<\/A>: <\/TD>",
	    "<TD>$descr<\/TD><\/TR>\n";
				# finish with empty line
	print $fhoutHtml "<TR><TD> <\/TD><TD> <\/TD><TD><\/TD><\/TR>\n";
    } 
    print $fhoutHtml "<\/TABLE>\n";

    print $fhoutHtml "<P><BR><P>\n";
    print $fhoutHtml "<HR>\n";
    print $fhoutHtml "<P><BR><P>\n";

    undef %segment;		# slim-is-in
    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtBodyHdr

