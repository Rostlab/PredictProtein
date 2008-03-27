#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="takes file *dat with columns 'id len glob norm' -> add probability\n".
    "     \t note:  prob read from second file (recognised if 'Prob')\n".
    "     \t note2: expected column numbers via 'ptrId|Len|Glob|Norm'";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'ptrId',         1,
      'ptrLen',        2,
      'ptrGlob',       3,
      'ptrNorm',       4,	# not used at moment!!
      '', "",			# 
      'ptrProbVal',    2,
      'ptrProbProb',   4,
      '', "",			# 
      );
@kwd=sort (keys %par);
$SEP="\t";
				# ------------------------------
if ($#ARGV < 2){		# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file_with_prob file_column (or many)'\n";
    print  "      name the probability histogram file 'Prob-'!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
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
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ($fileIn =~ /^Prob/i) {
	$fileProb=$fileIn;
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp; 
$#fileTmp=0;			# slim-is-in

				# ------------------------------
				# (1) read prob
				# ------------------------------

($Lok,$msg,$nrowsProb,$ra_prob)=
    &fileColumnGenRd_5($fileProb,$par{"ptrProbVal"},$par{"ptrProbProb"});
&errScrMsg("failed reading prob file=$fileProb\n",$msg) if (! $Lok);

foreach $itrow (1..$nrowsProb) {
    print "xx $itrow, val=",$ra_prob->[$itrow][$par{"ptrProbVal"}],", prob=",$ra_prob->[$itrow][$par{"ptrProbProb"}],"\n";
}
				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";

    ($Lok,$msg,$nrowsData,$ra_data)=
	&fileColumnGenRd_5($fileIn,$par{"ptrId"},$par{"ptrLen"},$par{"ptrGlob"});
    &errScrMsg("failed reading prob file=$fileIn\n",$msg) if (! $Lok);
				# ------------------------------
				# redo norm
    $idlen=0;			# find length of id for output format
    foreach $itrow (1..$nrowsData){
	$idlen=length($ra_data->[$itrow][$par{"ptrId"}])
	    if (length($ra_data->[$itrow][$par{"ptrId"}]) > $idlen);

	next if ($ra_data->[$itrow][$par{"ptrLen"}] < 0);
				# redo norm
	$tmp=($ra_data->[$itrow][$par{"ptrGlob"}]/$ra_data->[$itrow][$par{"ptrLen"}]);
				# cut accuracy
	$tmp=~s/(\.\d\d\d\d).*$/$1/;
	$norm[$itrow]=$tmp;
    }
				# ------------------------------
				# assign prob
    foreach $itrow (1..$nrowsData) {
	$Lok=0;			# find interval
	foreach $itprob (1..$nrowsProb) {
	    if ($norm[$itrow] < $ra_prob->[$itprob][$par{"ptrProbVal"}]) {
		$prob[$itrow]=$ra_prob->[$itprob][$par{"ptrProbProb"}];
		$Lok=1;
		last;}}
				# none found: assumed end
	if (! $Lok) {
	    print "xx none assigned for itrow=$itrow, val=",$norm[$itrow],"\n";
	    if ($norm[$itrow] >= $ra_prob->[$nrowsProb][$par{"ptrProbVal"}]) {
		$prob[$itrow]=$ra_prob->[$nrowsProb][$par{"ptrProbProb"}]; }
	    else {
		&errScrMsg("file=$fileIn, itrow=$itrow, norm=".$norm[$itrow].
			   ", not assigned\n");}}
    }
				# ------------------------------
    undef %itrow; $#id=0;	# sort output data by id
    foreach $itrow (1..$nrowsData) {
	$id=$ra_data->[$itrow][$par{"ptrId"}];
	push(@id,$id);
	$itrow{$id}=$itrow;
    }

    @id = sort @id;
				# ------------------------------
				# write new file
    $fileOut=$fileIn; $fileOut=~s/^.*\///g; $fileOut=~s/(\..+)$/\-prob$1/;
    open("$fhout",">$fileOut") || warn "*** $scrName ERROR creating file $fileOut";
    print "xx writing to fileout=$fileOut\n";
				# header
    $tmpWrt=           sprintf ("%-".$idlen."s".$SEP."%6s".$SEP."%6s".$SEP."%8s".$SEP."%8s\n",
				"id","len","glob","norm","prob");
    print $fhout $tmpWrt;

				# data
    foreach $id (@id) {
	$itrow=$itrow{$id};
	$wrt=          sprintf ("%-".$idlen."s".$SEP."%5d".$SEP."%5d".$SEP."%8.3f".$SEP."%8.3f\n",
				$ra_data->[$itrow][$par{"ptrId"}],
				$ra_data->[$itrow][$par{"ptrLen"}],
				$ra_data->[$itrow][$par{"ptrGlob"}],
				$norm[$itrow],$prob[$itrow]);
	print $fhout $wrt;
    }
    close($fhout);
    print "xx idlen=$idlen,\n";
    print "--- wrote $fileOut\n";
				# clean up
    if ($#fileIn > 1) {
	undef %wrt; undef @{$ra_data}; $#id=0; # slim-is-in
    }

}
				# ------------------------------
				# (2) 
				# ------------------------------


				# ------------------------------
				# (3) write output
				# ------------------------------
close($fhout);

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
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

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
sub fileColumnGenRd_5 {
    my($fileInLoc,@colNumLoc) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,@rd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileColumnGenRd_5           general reader for column formats
#                               (ignoring '#' and first line)
#       in:                     $fileInLoc
#       in:                     @colNum : column numbers, if 0: read all
#       out:                    1|0,msg,$nrows,\%rd
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br5:"."fileColumnGenRd_5";
    $fhinLoc="FHIN_"."fileColumnGenRd_5";$fhoutLoc="FHIN_"."fileColumnGenRd_5";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %rd;
    $errWrt="";
    $ctLine=0;			# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	++$ctLine; $itrow=$ctLine-1;
	next if ($ctLine==1);	# skip first line
	$_=~s/\n//g;
	$_=~s/^[\s\t]*|[\s\t]*$//g; # purge leading blanks|tabs

	@tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}

	if ($itrow==1){		# only first time: check numbers passed
	    @colNumLoc=(1..$#tmp) if (! defined @colNumLoc || ! @colNumLoc); }

				# read columns
	foreach $itcol (@colNumLoc) {
	    $tmp=$tmp[$itcol];
	    if (! defined $tmp){
		$errWrt.="*** ERROR $SBR: itrow=$itrow, itcol=$itcol, not defined (file=$fileInLoc)\n";
		next; }
	    $rd[$itrow][$itcol]=$tmp[$itcol];
	}
    } close($fhinLoc);
    $nrows=$itrow;

    return(1,$errWrt)           if (length($errWrt) > 0);
    return(1,"ok $sbrName",$nrows,\@rd);
}				# end of fileColumnGenRd_5

