#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="merges the results from the SEG and the PHD runs\n".
    "     \t note: you can change the columns where the data is expected by ptrX=";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'ptrPhdId',    1,
      'ptrPhdLen',   2,
      'ptrPhdGlob',  3,

      'ptrSegId',    1,
      'ptrSegLen',   2,
      'ptrSegCom',   3,
      'ptrSegGlob',  4,
      '', "",
      );

@kwd=sort (keys %par);
$SEP="\t";
				# ------------------------------
if ($#ARGV < 2){		# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName glob-seg.rdb glob-phd.rdb'  (recognised by name 'phd|seg'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
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
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
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

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
if ($fileIn[2]=~/seg/) {	# if 2nd 'seg' switch
    $tmp=$fileIn[2];
    $fileIn[2]=$fileIn[1];
    $fileIn[1]=$tmp; }
				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    if ($fileIn eq $fileIn[1]) {
	($Lok,$msg)=
	    &fileGlobSegRd($fileIn);
	&errScrMsg("failed reading SEG=$fileIn",$msg) if (! $Lok); }
    else {
	($Lok,$msg)=
	    &fileGlobPhdRd($fileIn);
	&errScrMsg("failed reading PHD=$fileIn",$msg) if (! $Lok); }
}
				# ------------------------------
				# (2) compare and join
				# ------------------------------
$#missPhd=$#missSeg=$#ok=0;
$#glob=0;
$ctGlob=0;

foreach $id (@id) {
				# none found in PHD
    if (! defined $phd{$id}) { push(@imissPhd,$id);
			       next; }
				# none found in SEG
    if (! defined $phd{$id}) { push(@imissPhd,$id);
			       next; }
    push(@ok,$id);
				# normalise
    $phd{$id,"norm"}=0;
    $phd{$id,"norm"}=
	($phd{$id,"glob"}/$phd{$id,"len"}) if ($phd{$id,"len"} > 0) ;
				# probability
    ($Lok,$msg,$phd{$id,"prob"})=
	&globeProb($phd{$id,"norm"});
    &errScrMsg("failed globeProb for id=$id (norm=".$phd{$id,"norm"}.")\n",
	       $msg) if (! $Lok);
    
				# joined decision
    ($Lok,$msg,$LisGlobular)=
	&globeJoinPhdSeg($phd{$id,"norm"},$seg{$id,"glob"});     

    &errScrMsg("failed globeJoinePhdSeg for id=$id\n",$msg) if (! $Lok);
    $isGlobular{$id}=$LisGlobular;
    ++$ctGlob                   if ($LisGlobular);
    push(@glob,$id)             if ($LisGlobular);
}
    
				# ------------------------------
				# (3) write output
				# ------------------------------

				# all data
open("$fhout",">$fileOut") || warn "*** $scrName ERROR creating file $fileOut";
printf $fhout 
    "%-19s".$SEP."%5s".$SEP."%5s".$SEP."%6s".$SEP."%6s".$SEP."%6s".$SEP."%6s".$SEP."%1s\n",
    "id","lenPhd","lenSeg","globPhd","probPhd","normPhd","globSeg","join";

foreach $id (@ok) {
    next if ($phd{$id,"len"}<=0);
    $tmpWrt=sprintf ("%-6s".$SEP."%5d".$SEP."%5d".$SEP."%6.1f".$SEP."%6.2f".
		     $SEP."%6.2f".$SEP."%6.1f".$SEP."%1d\n",
		     $id,$phd{$id,"len"},$seg{$id,"len"},
		     $phd{$id,"glob"},$phd{$id,"prob"},$phd{$id,"norm"},
		     $seg{$id,"glob"},$isGlobular{$id});
    print $fhout $tmpWrt;
    $tmpWrt=~s/\t/\s/;
#    print $tmpWrt;
    print "*** id=$id, no phd len\n"  if (! defined $phd{$id,"len"});
    print "*** id=$id, no phd glob\n" if (! defined $phd{$id,"glob"});

    print "*** id=$id, no seg len\n"  if (! defined $seg{$id,"len"});
    print "*** id=$id, no seg glob\n" if (! defined $seg{$id,"glob"});
} close($fhout);

				# all data: globular ones
$fileOutGlob=$fileOut; $fileOutGlob=~s/(\..*)$/-glob$1/;
open("$fhout",">$fileOutGlob") || warn "*** $scrName ERROR creating file $fileOutGlob";
printf $fhout 
    "%-19s".$SEP."%5s".$SEP."%6s".$SEP."%6s".$SEP."%6s\n",
    "id","len","probPhd","normPhd","globSeg";
foreach $id (@ok) {
    next if ($phd{$id,"len"}<=0 || ! $isGlobular{$id});
    $tmpWrt=sprintf ("%-6s".$SEP."%5d".$SEP."%6.2f".$SEP."%6.2f".$SEP."%6.1f\n",
		     $id,$phd{$id,"len"},$phd{$id,"prob"},
		     $phd{$id,"norm"},$seg{$id,"glob"});
    print $fhout $tmpWrt; } close($fhout);

				# all data: NON-globular ones
$fileOutNoGlob=$fileOut; $fileOutNoGlob=~s/(\..*)$/-noglob$1/;
open("$fhout",">$fileOutNoGlob") || warn "*** $scrName ERROR creating file $fileOutNoGlob";
printf $fhout 
    "%-19s".$SEP."%5s".$SEP."%6s".$SEP."%6s".$SEP."%6s\n",
    "id","len","probPhd","normPhd","globSeg";
foreach $id (@ok) {
    next if ($phd{$id,"len"}<=0 ||  $isGlobular{$id});
    $tmpWrt=sprintf ("%-6s".$SEP."%5d".$SEP."%6.2f".$SEP."%6.2f".$SEP."%6.1f\n",
		     $id,$phd{$id,"len"},$phd{$id,"prob"},
		     $phd{$id,"norm"},$seg{$id,"glob"});
    print $fhout $tmpWrt; } close($fhout);

				# found to be globular: ids only
$fileOutGlobId="id-".$fileOut; $fileOutGlob=~s/(\..*)$/-glob$1/;
if ($#glob > 0){
    open("$fhout",">$fileOutGlobId") || warn "*** $scrName ERROR creating file $fileOutGlobId";
    foreach $id (@glob) {
	print $fhout "$id\n";}
    close($fhout); }
				# missing in PHD
$fileOutPhd=$fileOut."-nophd";
if ($#missPhd > 0){open("$fhout",">$fileOutPhd") || warn "*** $scrName ERROR creating file $fileOutPhd";
		   foreach $id (@missPhd) {
		       print $fhout "$id\n";}
		   close($fhout); }

				# missing in SEG
$fileOutSeg=$fileOut."-noseg";
if ($#missSeg > 0){open("$fhout",">$fileOutSeg") || warn "*** $scrName ERROR creating file $fileOutSeg";
		   foreach $id (@missSeg) {
		       print $fhout "$id\n";}
		   close($fhout); }

print "--- output in $fileOut\n" if (-e $fileOut);
print "--- missing in phd (".$#missPhd."): $fileOutPhd\n" if (-e $fileOutPhd);
print "--- missing in seg (".$#missSeg."): $fileOutSeg\n" if (-e $fileOutSeg);

print "--- numprot=",$#id,", numGlob=",$ctGlob,"\n";
print "--- out data for globular     $fileOutGlob\n"      if (-e $fileOutGlob);
print "--- out data for NON globular $fileOutNoGlob\n"    if (-e $fileOutNoGlob);
print "--- out ids of globular ones $fileOutGlobId\n"     if (-e $fileOutGlobId);

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
sub fileGlobPhdRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileGlobPhdRd               reads the stuff from Globe 
#       in|out GLOBAL:          all
#       in:                     $fileInLoc
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."fileGlobPhdRd";
    $fhinLoc="FHIN_"."fileGlobPhdRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %phd;
    $errWrt="";
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	next if ($_=~/^id/);	# skip name
	$_=~s/\n//g;

	@tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}
	$id=  $tmp[$par{"ptrPhdId"}];
	$len= $tmp[$par{"ptrPhdLen"}];
	$glob=$tmp[$par{"ptrPhdGlob"}];

	$errWrt.="*** error PHD id=$id, len=$len, glob=$glob\n" 
	    if (! defined $id || ! defined $len || ! defined $glob);

	$phd{$id}=1;
	$phd{$id,"len"}= $len;
	$phd{$id,"glob"}=$glob;

	if (! defined $id{$id}){
	    $id{$id}=1;
	    push(@id,$id);}
    } close($fhinLoc);

    if (length($errWrt) > 0) {
	print "*** ERROR reading $fileInLoc in $sbrName\n";
	print $errWrt;
	exit; }

    return(1,"ok $sbrName");
}				# end of fileGlobPhdRd

#===============================================================================
sub fileGlobSegRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileGlobSegRd               reads the stuff from Globe 
#       in|out GLOBAL:          all
#       in:                     $fileInLoc
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."fileGlobSegRd";
    $fhinLoc="FHIN_"."fileGlobSegRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %seg;
    $errWrt="";
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	next if ($_=~/^id/);	# skip name
	$_=~s/\n//g;

	@tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}
	$id=  $tmp[$par{"ptrSegId"}];
	$len= $tmp[$par{"ptrSegLen"}];
	$glob=$tmp[$par{"ptrSegGlob"}];

	$errWrt.="*** error PHD id=$id, len=$len, glob=$glob\n" 
	    if (! defined $id || ! defined $len || ! defined $glob);

	$seg{$id}=1;
	$seg{$id,"len"}= $len;
	$seg{$id,"glob"}=$glob;

	if (! defined $id{$id}){
	    $id{$id}=1;
	    push(@id,$id);}
    } close($fhinLoc);

    if (length($errWrt) > 0) {
	print "*** ERROR reading $fileInLoc in $sbrName\n";
	print $errWrt;
	exit; }

    return(1,"ok $sbrName");
}				# end of fileGlobSegRd

#===============================================================================
sub globeJoinIni {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeJoinIni                initialises the function used to apply the rule
#       
#      !   /|   |\   !          - between the vertical lines => IS  globular
#      !  / |   | \  !          - left and right of '!'      => NOT globular
#      ! /  |   |  \ !          ELSE function:
#       lo    0    hi           - everything left of lo      => NON globular
#                               - everything right of hi     => NON globular
#                               - ELSE                       => IS  globular
#                               
#                               lower cut-off   /
#                               y (SEG) = $funcLoAdd + $funcLoFac x (PHD)
#                               higher cut-off  \
#                               y (SEG) = $funcHiAdd + $funcHiFac x (PHD)
#                               
#       out GLOBAL:             $FUNC_LO_FAC,$FUNC_LO_ADD,$FUNC_HI_FAC,$FUNC_HI_ADD,
#                               $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeJoinIni";
				# ------------------------------
				# PHD saturation
    $PHD_LO_NO= -0.10;		# if PHDnorm < $phdLoSat -> not globular
    $PHD_HI_NO=  0.20;		# if PHDnorm > $phdHiSat -> not globular

				# PHD OK
    $PHD_LO_OK= -0.03;		# if $PHD_LO_OK < PHDnorm < $PHD_HI_OK -> IS globular
    $PHD_HI_OK=  0.15;		# if $PHD_LO_OK < PHDnorm < $PHD_HI_OK -> IS globular


				# anchor points: SEG
    $segLo1=   50;
    $segLo2=  100;
    $segHi1=   80;
    $segHi2=  100;
				# ------------------------------
				# empirical function
				# ------------------------------
				# FAC = (y1 - y2) / (x1 - x2)
				# ADD = y1 - x1 * FAC
    $FUNC_LO_FAC= ($segLo2-$segLo1) / ($PHD_LO_NO-$PHD_LO_OK);
    $FUNC_LO_ADD= $segLo1 - $FUNC_LO_FAC * $PHD_LO_NO;

    $FUNC_HI_FAC= ($segHi2-$segHi1) / ($PHD_HI_NO-$PHD_HI_OK);
    $FUNC_HI_ADD= $segHi1 - $FUNC_HI_FAC * $PHD_HI_NO;

}				# end of globeJoinIni

#===============================================================================
sub globeJoinPhdSeg {
    local($globPhd,$globSeg) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeJoinPhdSeg             applies ad-hoc rule to join PHDglobe  and SEG
#                               GLOBULAR   if globSEG > 70%
#                                          if globPHD < -10
#                                          if 
#       in:                     $fileInLoc
#       out:                    1|0,$msg,(yes_is_globular=1|no_is_not_globular=0)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeJoinPhdSeg";
				# check arguments
    return(&errSbr("not def globPhd!"))          if (! defined $globPhd);
    return(&errSbr("not def globSeg!"))          if (! defined $globSeg);
#    return(&errSbr("not def !"))          if (! defined $);
				# check variables
    return(&errSbr("value for globSEG should be percentage [0-100], is $globSeg\n"))
	if (100 < $globSeg || $globSeg < 0);

				# ini the functions
				# out GLOBAL: 
				#     $FUNC_LO_FAC,$FUNC_LO_ADD,$FUNC_HI_FAC,$FUNC_HI_ADD
				#     $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
    &globeJoinIni()             if (! defined $FUNC_LO_FAC || ! defined $FUNC_LO_ADD || 
				    ! defined $FUNC_HI_FAC || ! defined $FUNC_HI_ADD ||
				    ! defined $PHD_LO_NO   || ! defined $PHD_HI_NO   ||
				    ! defined $PHD_LO_OK   || ! defined $PHD_HI_OK );

    $funcLo=    $FUNC_LO_ADD + $FUNC_LO_FAC * $globPhd;
    $funcHi=    $FUNC_HI_ADD + $FUNC_HI_FAC * $globPhd;

				# PHD hard include:
    return(1,"ok",1)            if ($PHD_LO_OK  <= $globPhd  && $globPhd <= $PHD_HI_OK );
				# PHD hard exclude:
    return(1,"ok",0)            if ($globPhd  <  $PHD_LO_NO  || $globPhd  > $PHD_HI_NO );

				# left fit:
    return(1,"ok",0)            if ($globPhd < 0 && $globSeg > $funcLo);
				# right fit:
    return(1,"ok",0)            if ($globPhd > 0 && $globSeg > $funcHi);
				# all others : ok
    return(1,"ok $sbrName",1);
}				# end of globeJoinPhdSeg

#===============================================================================
sub globeProb {
    local($globePhdNormInLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeProb                   translates normalised diff in exp res to prob
#                               
#       in:                     $(norm = DIFF / length)
#       out:                    1|0,$msg,$prob (lookup table!)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeProb";
				# check arguments
    return(&errSbr("globePhdNormInLoc not defined")) 
	if (! defined $globePhdNormInLoc);
    return(&errSbr("globePhdNormInLoc ($globePhdNormInLoc) not number")) 
	if ($globePhdNormInLoc !~ /^[0-9\.\-]+$/);
    return(&errSbr("normalised phdGlobe should be between -1 and 1, is=$globePhdNormInLoc")) 
	if ($globePhdNormInLoc < -1 || $globePhdNormInLoc > 1);
				# ------------------------------
				# ini if table not defined yet!
    &globeProbIni()             if (! defined $GLOBE_PROB_TABLE_MIN || ! defined $GLOBE_PROB_TABLE[1]);

				# ------------------------------
				# normalise
				# too low
    return(1,"ok",0)            if ($globePhdNormInLoc <= $GLOBE_PROB_TABLE_MIN);
				# too high
    return(1,"ok",0)		if ($globePhdNormInLoc >= $GLOBE_PROB_TABLE_MAX);
				# in between: find interval
    $val=$GLOBE_PROB_TABLE_MIN;
    foreach $it (1..$GLOBE_PROB_TABLE_NUM) {
	$val+=$GLOBE_PROB_TABLE_ITRVL;
	last if ($val > $GLOBE_PROB_TABLE_MAX);	# note: should not happen
	return(1,"ok",$GLOBE_PROB_TABLE[$it])
	    if ($globePhdNormInLoc <= $val);
    }
				# none found (why?)
    return(1,"ok",0);
}				# end of globeProb

#===============================================================================
sub globeProbIni {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeProbIni           sets the values for the probability assignment
#       out GLOBAL:             
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeProbIni";

    $GLOBE_PROB_TABLE_MIN=  -0.280;
    $GLOBE_PROB_TABLE_MAX=   0.170;
    $GLOBE_PROB_TABLE_ITRVL= 0.010;
    $GLOBE_PROB_TABLE_NUM=   46;

    $GLOBE_PROB_TABLE[1]= 0.005; # val= -0.280  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[2]= 0.008; # val= -0.270  occ=   0  prob=   0.014
    $GLOBE_PROB_TABLE[3]= 0.010; # val= -0.260  occ=   4  prob=   0.014
    $GLOBE_PROB_TABLE[4]= 0.015; # val= -0.250  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[5]= 0.021; # val= -0.240  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[6]= 0.025; # val= -0.230  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[7]= 0.026; # val= -0.220  occ=   1  prob=   0.003
    $GLOBE_PROB_TABLE[8]= 0.028; # val= -0.210  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[9]= 0.030; # val= -0.200  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[10]=0.032; # val= -0.190  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[11]=0.034; # val= -0.180  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[12]=0.036; # val= -0.170  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[13]=0.040; # val= -0.160  occ=  13  prob=   0.045
    $GLOBE_PROB_TABLE[14]=0.045; # val= -0.150  occ=  11  prob=   0.038
    $GLOBE_PROB_TABLE[15]=0.065; # val= -0.140  occ=  19  prob=   0.065
    $GLOBE_PROB_TABLE[16]=0.070; # val= -0.130  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[17]=0.075; # val= -0.120  occ=   7  prob=   0.024
    $GLOBE_PROB_TABLE[18]=0.080; # val= -0.110  occ=  22  prob=   0.075
    $GLOBE_PROB_TABLE[19]=0.130; # val= -0.100  occ=  71  prob=   0.243
    $GLOBE_PROB_TABLE[20]=0.240; # val= -0.090  occ=  38  prob=   0.130
    $GLOBE_PROB_TABLE[21]=0.312; # val= -0.080  occ=  91  prob=   0.312
    $GLOBE_PROB_TABLE[22]=0.329; # val= -0.070  occ=  96  prob=   0.329
    $GLOBE_PROB_TABLE[23]=0.350; # val= -0.060  occ= 111  prob=   0.380
    $GLOBE_PROB_TABLE[24]=0.380; # val= -0.050  occ= 183  prob=   0.627
    $GLOBE_PROB_TABLE[25]=0.435; # val= -0.040  occ= 104  prob=   0.356
    $GLOBE_PROB_TABLE[26]=0.600; # val= -0.030  occ= 132  prob=   0.452
    $GLOBE_PROB_TABLE[27]=0.700; # val= -0.020  occ= 127  prob=   0.435
    $GLOBE_PROB_TABLE[28]=0.800; # val= -0.010  occ= 151  prob=   0.517
    $GLOBE_PROB_TABLE[29]=0.999; # val=  0.000  occ= 453  prob=   0.959
    $GLOBE_PROB_TABLE[30]=0.950; # val=  0.010  occ= 245  prob=   0.839
    $GLOBE_PROB_TABLE[31]=0.900; # val=  0.020  occ= 292  prob=   1.000
    $GLOBE_PROB_TABLE[32]=0.800; # val=  0.030  occ= 211  prob=   0.723
    $GLOBE_PROB_TABLE[33]=0.750; # val=  0.040  occ= 156  prob=   0.534
    $GLOBE_PROB_TABLE[34]=0.700; # val=  0.050  occ= 224  prob=   0.767
    $GLOBE_PROB_TABLE[35]=0.650; # val=  0.060  occ= 161  prob=   0.551
    $GLOBE_PROB_TABLE[36]=0.600; # val=  0.070  occ= 129  prob=   0.442
    $GLOBE_PROB_TABLE[37]=0.550; # val=  0.080  occ= 103  prob=   0.353
    $GLOBE_PROB_TABLE[38]=0.500; # val=  0.090  occ= 171  prob=   0.586
    $GLOBE_PROB_TABLE[39]=0.200; # val=  0.100  occ=  45  prob=   0.154
    $GLOBE_PROB_TABLE[40]=0.150; # val=  0.110  occ=  17  prob=   0.058
    $GLOBE_PROB_TABLE[41]=0.110; # val=  0.120  occ=  32  prob=   0.110
    $GLOBE_PROB_TABLE[42]=0.050; # val=  0.130  occ=   5  prob=   0.017
    $GLOBE_PROB_TABLE[43]=0.040; # val=  0.140  occ=   1  prob=   0.003
    $GLOBE_PROB_TABLE[44]=0.030; # val=  0.150  occ=   2  prob=   0.007
    $GLOBE_PROB_TABLE[45]=0.020; # val=  0.160  occ=   9  prob=   0.031
    $GLOBE_PROB_TABLE[46]=0.005; # val=  0.170  occ=   2  prob=   0.007
}				# end of globeProbIni

