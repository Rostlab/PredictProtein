#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs the program COILS from Lupas";
#  
#
$[ =1 ;
				# include libraries
				# defaults
if (defined $ENV{'ARCH'}){$ARCH=$ENV{'ARCH'};}
else { print "*** ERROR define cpu arch 'setenv ARCH SGI64|ALPHA'\n";
       die;}
$exeCoils= "/home/phd/server/bin/coils.".$ARCH;
$metric=   "MTK";		# metric 1
#$metric=   "MTIDK";		# metric 2
#$optOut=   "row";		# row-wise output (probabilities projected)
#$optOut=   "cutoff";		# user defined cut-off for reporting prob
#$optOut=   "winsize";		# size of window def = 14, 21, 28
$optOut=   "col";		# column-wise output (probabilities)
$minProb=  0.5;			# minimal probability to report coiled-coils

$LmarkCoiled=0;			# if 1 : write fasta formatted file with coiled-coil regions as 'x'

				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file'\n";
    print "opt: \t exe=$exeCoils   (default)\n";
    print "     \t mark            (mark coiled coil regions)\n";
    print "     \t fileOut=    x\n";
    print "     \t fileOutMark=x\n";
    print "     \t metr=$metric    (possible = MTK|MTIDK)\n";
    print "     \t opt=$optOut     (possible = col|row|winsize=|cutoff=)\n";
    print "     \t =x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
#$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut=$tmp;$fileOut=~s/\..*$//g;$fileOut.=".coils";

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^fileOutMark=(.*)$/){$fileOutMark=$1;}
    elsif($_=~/^exe=(.*)$/)    {$exeCoils=$1;}
    elsif($_=~/^metr=(.*)$/)   {$metric=$1;}
    elsif($_=~/^opt=(.*)$/)    {$optOut=$1;}
    elsif($_=~/^mark/i)        {$LmarkCoiled=1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

if (! -e $fileIn)  {print "*** ERROR missing input file $fileIn\n";
		    die;}
if (! -e $exeCoils){print "*** ERROR missing coils exe $exeCoils\n";
		    die;}

				# run
($Lok,$err)=
    &coilsRun($fileIn,$fileOut,$exeCoils,$metric,$optOut,"STDOUT");
die("*** $scrName: coilsRun ($fileIn,$fileOut,$exeCoils,$metric,$optOut) failed: $err\n") 
    if (! $Lok);
				# ------------------------------
$fileTmp=$fileOut."_2";		# analyse results
($Lok,$err)=
    &coilsRd($fileOut,$fileTmp,$minProb,"STDOUT");

if    ($Lok == 2){		# below threshold
    $fileTmp=~s/\..*$/\.notCoils/g;
    system("echo 'no coiled-coil above $minProb' >> $fileTmp");}
elsif ($Lok == 1){		# may be coiled-coil
    $fileTmp2=$fileTmp;$fileTmp2=~s/\..*$/\.coilsSyn/g;
    system("\\mv $fileTmp $fileTmp2");
    print "--- is coiled coil $fileOut (syn=$fileTmp2)\n";}
elsif ($Lok == 0){		# not coiled-coil
    unlink($fileTmp);
    print "--- no coiled coil $fileOut\n";}

				# ------------------------------
				# write fasta format with X
if ($Lok && $LmarkCoiled){
    if (! defined $fileOutMark){
	$tmp=$fileIn;$tmp=~s/^.*\///g;
	$fileOutMark=$tmp;$fileOutMark=~s/\..*$//g;$fileOutMark.=".coilsMarked";}
    ($Lok,$err)=
	&coilsMark($fileOut,$fileOutMark,$minProb,"STDOUT");
    die("*** $scrName: coilsMark ($fileIn,$fileOutMark) failed: $err\n") 
	if (! $Lok);}

exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub coilsMark {
    local($fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsMark                     reads the column format of coils
#       in:                     $fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr
#         $fileInLoc            file with COILS output (column format expected)
#         $probMinLoc           minimal probability (otherwise returns '2,$msg')
#       out:                    fileOut
#       err:                    (0,$err), (1,'ok '), (2,'info...') -> not Coils
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsMark";$fhinLoc="FHOUT"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";

				# minimal number of residues required to be coiled-coil to 'X'out
    $numResCoilsMin=10;
				# ------------------------------
				# open COILS output
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n") if (! $Lok);

    $seq=$win[1]=$win[2]=$win[3]="";
    $max[1]=$max[2]=$max[3]=0;
#    $sum[1]=$sum[2]=$sum[3]=0;
    $ptr[1]=14;$ptr[2]=21;$ptr[3]=28;
    while (<$fhinLoc>) {	
				# get name of protein
	if ($_=~/\>(.*)\n/){
	    $protNameLoc=$1;
	    next;}
	last if ($_=~/^\s*[\.]+/);}
				# find ma
    ($max,$pos)=&get_max($max[1],$max[2],$max[3]);
    while (<$fhinLoc>) {
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g; # 
	@tmp=split(/\s+/,$_);
	next if ($#tmp<11);
	$seq.="$tmp[2]";
#	$sum[1]+=$tmp[5]; $sum[2]+=$tmp[8];  $sum[3]+=$tmp[11];  
	$win[1].="$tmp[5],";  $max[1]=$tmp[5]  if ($tmp[5]> $max[1]);
	$win[2].="$tmp[8],";  $max[2]=$tmp[8]  if ($tmp[8]> $max[2]);
	$win[3].="$tmp[11],"; $max[3]=$tmp[11] if ($tmp[11]>$max[3]);
    }close($fhinLoc);
				# ------------------------------
				# none above threshold
    return (2,"maxProb ($ptr[1]=$max[1], $ptr[2]=$max[2], $ptr[3]=$max[3]) < $probMinLoc")
	if ( ($max[1]<$probMinLoc) && ($max[2]<$probMinLoc) && ($max[3]<$probMinLoc) );
				# ------------------------------
    undef %posCoil;		# positions with probability > 0.5
    $nresLoc=0;
    foreach $itw (1..3){
	@tmp=split(/,/,$win[$itw]);
	return(0,"*** ERROR $sbrName: couldnt read coils format $fileInLoc\n")
	    if ($#tmp>length($seq));
	$LisCoil=0;
	$nresLoc=$#tmp          if ($itw==1);
	foreach $it(1..$#tmp){	# prob to 0-9
	    if ($tmp[$it] >= $probMinLoc) {
		if (! $LisCoil){
		    $LisCoil=1;
		    $#posTmp=0;}
		push(@posTmp,$it);}
	    elsif ($LisCoil){
		if ($#posTmp >= $numResCoilsMin) {
		    foreach $tmp (@posTmp){
			next if ($posCoil{$tmp});
			$posCoil{$tmp}=1;}}
		$LisCoil=0;}
	}}
    $seqX="";
				# loop over entire protein
				# goal: find maximal number of 'x' in all 3 windows
    foreach $it (1..$nresLoc){
	if (! $posCoil{$it}){
	    $seqX.=substr($seq,$it,1);}
	else {
	    $seqX.="x";}}
    
				# ------------------------------
				# write new output file
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    return(0,"*** ERROR $sbrName: new '$fileOutLoc' not opened\n") if (! $Lok);
    print $fhoutLoc  ">$protNameLoc\n";
    for ($it=1;$it<=length($seqX);$it+=50){
	print $fhoutLoc substr($seqX,$it,50),"\n";
    }
    close($fhoutLoc);
				# ------------------------------
				# write out marked fasta file
    
    return(1,"ok $sbrName");
}				# end of coilsMark

#==============================================================================
sub coilsRd {
    local($fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsRd                     reads the column format of coils
#       in:                     $fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr
#         $fileInLoc            file with COILS output (column format expected)
#         $probMinLoc           minimal probability (otherwise returns '2,$msg')
#       out:                    fileOut
#       err:                    (0,$err), (1,'ok '), (2,'info...') -> not Coils
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsRd";$fhinLoc="FHOUT"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
				# ------------------------------
				# open COILS output
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n") if (! $Lok);

    $seq=$win[1]=$win[2]=$win[3]="";
    $max[1]=$max[2]=$max[3]=0;
#    $sum[1]=$sum[2]=$sum[3]=0;
    $ptr[1]=14;$ptr[2]=21;$ptr[3]=28;
    while (<$fhinLoc>) {
	last if ($_=~/^\s*[\.]+/);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g; # 
	@tmp=split(/\s+/,$_);
	next if ($#tmp<11);
	$seq.="$tmp[2]";
#	$sum[1]+=$tmp[5]; $sum[2]+=$tmp[8];  $sum[3]+=$tmp[11];  
	$win[1].="$tmp[5],";  $max[1]=$tmp[5]  if ($tmp[5]> $max[1]);
	$win[2].="$tmp[8],";  $max[2]=$tmp[8]  if ($tmp[8]> $max[2]);
	$win[3].="$tmp[11],"; $max[3]=$tmp[11] if ($tmp[11]>$max[3]);
    }close($fhinLoc);
				# ------------------------------
				# none above threshold
    return (2,"maxProb ($ptr[1]=$max[1], $ptr[2]=$max[2], $ptr[3]=$max[3]) < $probMinLoc")
	if ( ($max[1]<$probMinLoc) && ($max[2]<$probMinLoc) && ($max[3]<$probMinLoc) );
				# ------------------------------
				# find ma
    ($max,$pos)=&get_max($max[1],$max[2],$max[3]);
    foreach $itw (1..3){
	@tmp=split(/,/,$win[$itw]);
	return(0,"*** ERROR $sbrName: couldnt read coils format $fileInLoc\n")
	    if ($#tmp>length($seq));
	$val[$itw]="";
	foreach $it(1..$#tmp){	# prob to 0-9
	    $tmp=int(10*$tmp[$it]); $tmp=9 if ($tmp>9);$tmp=0 if ($tmp<0);
	    $val[$itw].="$tmp";}
    }
				# ------------------------------
				# write new output file
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    return(0,"*** ERROR $sbrName: new '$fileOutLoc' not opened\n") if (! $Lok);
    print $fhoutLoc  "\n";
    print $fhoutLoc  "--- COILS HEADER: SUMMARY\n";
    print $fhoutLoc  "--- best window has width of $ptr[$pos]\n";
    print $fhoutLoc  "--- \n";
    print $fhoutLoc  "--- COILS: SYMBOLS AND EXPLANATIONS ABBREVIATIONS\n";
    printf $fhoutLoc "--- %-12s : %-s\n","seq","one-letter amino acid sequence";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin14","window=14, normalised prob [0-9], 9=high, 0=low";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin21","window=21, normalised prob [0-9], 9=high, 0=low";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin28","window=28, normalised prob [0-9], 9=high, 0=low";
    print $fhoutLoc "--- \n";
    for ($it=1;$it<=length($seq);$it+=50){
	printf $fhoutLoc "COILS %-10s %-s\n","   ",  &myprt_npoints(50,$it);
	printf $fhoutLoc "COILS %-10s %-s\n","seq",  substr($seq,$it,50);
	foreach $itw(1..3){
	    printf $fhoutLoc
		"COILS %-10s %-s\n","normWin".$ptr[$itw],substr($val[$itw],$it,50);}}
    close($fhoutLoc);
				# ------------------------------
				# write out marked fasta file
    
    return(1,"ok $sbrName");
}				# end of coilsRd

#==============================================================================
sub coilsRun {
    local($fileInLoc,$fileOutLoc,$exeCoilsLoc,$metricLoc,$optOutLoc,
	  $fhErrSbr,$fileScreenLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsRun                    runs the COILS program from Andrei Lupas
#       in:                     $fileIn,$exeCoils,$metric,$optOut,$fileOut,$fhErrSbr
#       in:                     NOTE if not defined arg , or arg=" ", then defaults
#       out:                    write into file (0,$err), (1,'ok ')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsRun";$fhinLoc="FHIN"."$sbrName";

    return(0,"*** $sbrName: not def fileInLoc!")      if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")     if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def exeCoilsLoc!")    if (! defined $exeCoilsLoc);
    return(0,"*** $sbrName: not def metricLoc!")      if (! defined $metricLoc);
    return(0,"*** $sbrName: not def optOutLoc!")      if (! defined $optOutLoc);
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);
    $fileScreenLoc=0                                  if (! defined $fileScreenLoc);

    return(0,"*** $sbrName: no in file $fileInLoc")   if (! -e $fileInLoc);
    $exeCoilsLoc="/home/phd/bin/".$ARCH."/coils"      if (! -e $exeCoilsLoc && defined $ARCH);
    $exeCoilsLoc="/home/phd/bin/SGI64/coils"          if (! -e $exeCoilsLoc && ! defined $ARCH); # HARD_CODED
    return(0,"*** $sbrName: no in exe  $exeCoilsLoc") if (! -e $exeCoilsLoc);
    $metricLoc=  "MTK"                                if (! -e $metricLoc); # metric 1
#    $metricLoc=  "MTIDK"                              if (! -e $metricLoc); # metric 2
    $optOutLoc=  "col"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);

				# metric
    if    ($metricLoc eq "MTK")  {$met="1";}
    elsif ($metricLoc eq "MTIDK"){$met="2";}
    else  {
	return(0,"*** ERROR $scrName metric=$metricLoc, must be 'MTK' or 'MTIDK' \n");}
				# output option
    if    ($optOutLoc eq "col")  {$opt="p";}
    elsif ($optOutLoc eq "row")  {$opt="a";}
    elsif ($optOutLoc =~/cut/)   {
	$opt="b";
	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
    elsif ($optOutLoc =~/win/)   {
	$opt="c";
	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
    else {
	return(0,"*** ERROR $scrName optOut=$optOut no known\n");}
    $an=                       "N"; # no weight for position a & d
    $an=                       "Y"; # weight for position a & d

    eval "\$cmd=\"$exeCoilsLoc,$fileInLoc,$fileOutLoc,$met,$an,$opt\"";

    ($Lok,$msg)=
	&sysRunProg($cmd,$fileScreenLoc,$fhErrSbr);

    return(0,"*** ERROR $sbrName: failed to create $fileOutLoc\n".$msg)
	if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of coilsRun

#==============================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
#----------------------------------------------------------------------
#   get_max                     returns the maximum of all elements of @in
#       in:                     @in
#       out:                    returned $max,$pos (position of maximum)
#----------------------------------------------------------------------
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); } # end of get_max


#==============================================================================
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
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system fileOut=$fileScrLoc, cmd=\n$prog\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg



#==============================================================================
# library collected (end)   lll
#==============================================================================

