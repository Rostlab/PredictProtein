#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="finds location in SWISS-PROT (nothing returned if not annotated)";

$[ =1 ;
				# initialise variables

if ($#ARGV<1){print "goal:   $scrGoal\n";
	      print "usage:  'script \@files (or id's)'\n";
	      print "output: array with matching lines (0 if none)\n";
	      print "option:\n";
	      print "        dir=x      (directory of swissprot)\n";
	      print "        fileOut=x  (RDB output, default 'Out-swissLoci.tmp')\n";
	      print "        verbose \n";
	      exit;}

$fhout="FHOUT_swissGetLocation";$fhin="FHIN_swissGetLocation";
$Lscreen=1;			# write output onto screen?
$regexp="^CC .*SUBCELLULAR LOCATION:";

				# ------------------------------
				# read command line
$#tmp=0;
foreach $it (1..$#ARGV){
    if ($ARGV[$it]=~/^dir=/){	# keyword (swissprot directory)
	$tmp=$ARGV[$it];$tmp=~s/^dir=//g;$par{"dir"}=&complete_dir($tmp);} # external lib-ut.pl
    elsif ($ARGV[$it]=~/^verb(ose)?/){
	$Lscreen=1;}
    elsif ($ARGV[$it]=~/^fileOut=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^fileOut=//g;$par{"fileOut"}=$tmp;}
    else {
	push(@tmp,$ARGV[$it]);}}


				# ------------------------------
$timeBeg=     time;		# date and time

				# ------------------------------
				# process input
$#file=0;
foreach $input(@tmp){

    if    (&isSwiss($input)){	# is SWISS-PROT file
	$file[1]=$input; }
    elsif ($input =~ /\.list/ || &isSwissList($input)){ # is list of SWISS-PROT files
	print "xx read list $input\n";
	open($fhin, $input) || die "*** $scrName failed opening input list=$input\n";

	while (<$fhin>) {
	    $_=~s/\n//g; $rd=$_;
	    $file1=$_;
				# is swiss-prot file
	    if (-e $file1) { push(@file,$file1);
			     next;}
				# add dir
	    if (defined $par{"dir"} && -d $par{"dir"}) {
		$file2=$par{"dir"}.$_; }
	    if (-e $file2) { push(@file,$file2);
			     next;}
				# add full dir
	    $tmp=$rd; $tmp=~s/^.+_(.).+$/$1/g;
	    if (defined $par{"dir"} && -d $par{"dir"}) {
		$file3=$par{"dir"}.$tmp."/".$rd; }
	    if (-e $file3) { push(@file,$file3);
			     next;}
	    print "*** ERROR input file=$input, failed getting SWISS-PROT for $rd\n";
	    print "*** file1=$file1, file2=$file2, file3=$file3,\n";
	    exit; }
	close($fhin);}

    else {			# search for existing
	$out=
	    &swissGetFile($input,$Lscreen,$par{"dir"}); # external lib-ut.pl
	next if (! $out);
	push(@file,$out);}}
				# ------------------------------
				# re-adjust defaults
if (! defined $par{"fileOut"}){
    $par{"fileOut"}="Out-"."swissLoci".".tmp";}
$fileOut=$par{"fileOut"};
if (!defined $par{"dir"}){$par{"dir"}="";}

if ($Lscreen){print 
		  "--- end of ini settings:\n",
		  "--- regexp = \t '$regexp'\n","--- file out: \t '$fileOut'\n",
		  "--- dirSwiss: \t '",$par{"dir"},"'\n","--- swiss files: \n";
	      foreach $file (@file){print"--- \t $file\n";}}

				# ------------------------------
				# now do for list
$#out=0;
$nfileIn=$#file;
$it=0;
foreach $file (@file){
    ++$it;
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$it);
    $estimate="?"               if ($it < 5);
    printf 
	"--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	$file,$it,(100*$it/$nfileIn),"%",$estimate;

				# ------------------------------
				# get location
				# returns 'location blabla \t id' for many proteins
    ($Lok,$msg,@tmp)=
	&swissGetLocation($regexp,"STDOUT",$file); # external lib-prot.pl

				# none found -> skip
    next if (! defined $tmp[1] || length($tmp[1])<1);
    push(@out,@tmp);
}

$#fin=$#finId=0;
foreach $out (@out){
    $out=~s/\n//g;
    next if (! $out);
    ($fin,$finId)=split(/\t+/,$out);
    push(@fin,$fin);push(@finId,$finId);}
				# ------------------------------
				# output file (RDB)
&open_file("$fhout", ">$fileOut");
print $fhout "\# Perl-RDB\n";
printf $fhout "%5s\t%-15s\t%-s\n","lineNo","id","location ";
printf $fhout "%5s\t%-15s\t%-s\n","5N","15","";
foreach $it (1..$#fin){
    printf $fhout 	
	"%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
    printf 
	"%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
    print "xx finId=$finId[$it],\n";
}
close($fhout);

print "--- finished out=$fileOut\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir

#===============================================================================
sub fctRunTimeLeft {
    local($timeBegLoc,$num_to_run,$num_did_run) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the time the job still needs to run
#       in:                     $timeBegLoc : time (time) when job began
#       in:                     $num_to_run : number of things to do
#       in:                     $num_did_run: number of things that are done, so far
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $percLoc=0;
    $percLoc=100*($num_did_run/$num_to_run) if ($num_to_run > 0);

    if ($percLoc) {
	$timeTot=int(100*($timeRun/$percLoc));
	$timeLeft=$timeTot-$timeRun;
	$tmp=
	    &fctSeconds2time($timeLeft); 
	@tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
	$estimateLoc= "";
	$estimateLoc.=    $tmp[1]."h " if ($tmp[1] > 9);
	$estimateLoc.=" ".$tmp[1]."h " if (9 >= $tmp[1] && $tmp[1] > 0);
	$estimateLoc.=    $tmp[2]."m " if ($tmp[2] > 9);
	$estimateLoc.=" ".$tmp[2]."m " if (9 >= $tmp[2] && $tmp[2] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[2] <= 0 && $tmp[1] > 0);
	$estimateLoc.=    $tmp[3]."s " if ($tmp[3] > 9);
	$estimateLoc.=" ".$tmp[3]."s " if (9 >= $tmp[3] && $tmp[3] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[3] <= 0 && ($tmp[1] > 0 || $tmp[2] > 0));
	$estimateLoc= "done"        if (length($estimateLoc) < 1);}
    else {
	$estimateLoc="?";}
    return($estimateLoc);
}				# end of fctRunTimeLeft

#===============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open("$fhinLoc","$fileLoc"); $Lok=0;
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#==============================================================================
sub isSwissList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isSwissList                 checks whether or not file is list of Swiss files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_SwissList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (! -e $fileTmp){return(0);}
			if (&isSwiss($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isSwissList

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
sub swissGetFile { 
    local ($idLoc,$LscreenLoc,@dirLoc) = @_ ; 
    local ($fileLoc,$dirLoc,$tmp,@dirSwissLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissprotGetFile           returns SWISS-PROT file for given filename
#        in:                   $id,$LscreenLoc,@dirLoc
#        out:                  $file  (id or 0 for error)
#--------------------------------------------------------------------------------
    return($idLoc)  if (-e $idLoc); # already existing directory
    $#dirLoc=0      if (! defined @dirLoc);
    if    (! defined $LscreenLoc){
	$LscreenLoc=0;}
    elsif (-d $Lscreen) {
	@dirLoc=($LscreenLoc,@dirLoc);
	$LscreenLoc=0;}
    @dirSwissLoc=("/data/swissprot/current/"); # swiss dirs

				# add species sub directory
    foreach $dirLoc(@dirSwissLoc){
	next if (! defined $dirLoc || ! -d $dirLoc || $dirLoc !~/current/);
	$dirCurrent=$dirLoc;
	last;}
    $tmp=$idLoc;$tmp=~s/^[^_]+_(.).+$/$1/g;
    $dirSpecies=&complete_dir($dirCurrent)."$tmp"."/" if (defined $dirCurrent && -d $dirCurrent);
    push(@dirSwissLoc,$dirSpecies) if (defined $dirSpecies && -d $dirSpecies);
				# go through all directories
    foreach $dirLoc(@dirSwissLoc){
	next if (! defined $dirLoc);
	next if (! -d $dirLoc);	# directory not existing
	$fileLoc=&complete_dir($dirLoc)."$idLoc";
	return($fileLoc) if (-e $fileLoc);
	$tmp=$idLoc;$tmp=~s/^.*\///g; # purge directory
	$tmp=~s/^.*_(.).*$/$1/;$tmp=~s/\n//g; # get species
	$fileLoc=&complete_dir($dirLoc).$tmp."/"."$idLoc";
	return($fileLoc) if (-e $fileLoc);}
    return(0);
}				# end of swissGetFile

#==============================================================================
sub swissGetLocation {
    local ($regexpLoc,$fhLoc,@fileInLoc) = @_ ;
    local($sbrName,$fhoutLoc,$LverbLoc,@outLoc,@rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetLocation            searches in SWISS-PROT file for cell location           
#       in:                     $regexp,$handle,@file
#                               $regexp e.g. = "^CC .*SUBCELLULAR LOCATION:"
#                               $fhLoc  = 0,1,FHOUT (file handle for blabla)
#                               @file   = swissprot files to read
#       out:                    ($Lok,$msg,@lines_with_expression)
#--------------------------------------------------------------------------------
    $sbrName="swissGetLocation";$fhinLoc="FHIN_$sbrName";
    if    ($fhLoc eq "0"){$fhoutLoc=0;$LverbLoc=0;}	# file handle
    elsif ($fhLoc eq "1"){$fhoutLoc="STDOUT";$LverbLoc=0;}
    else                 {$fhoutLoc=$fhLoc;$LverbLoc=0;}

				# ------------------------------
				# read swiss-prot files
    $#finLoc=0;
    foreach $fileTmp (@fileInLoc){
	next if (! -e $fileTmp);
	open($fhinLoc, $fileTmp) ||
	    return(0,"*** ERROR could NOT openf fileIn=$fileTmp");
	;$Lok=$Lfin=0;$loci="";
	while (<$fhinLoc>) {
	    $_=~s/\n//g;
	    if ($_=~/$regexpLoc/) {	# find first line (CC )
		$_=~s/$regexpLoc//g; # purge keywords
		$Lok=1;
		$loci=$_." ";}
	    elsif ($Lok && $_=~/^CC\s+\-+\s*$/) { # end if new expression
		$Lfin=1;}
	    elsif ($Lok && $_=~/^[^C]|^CC\s+-\!-/) { # end if new expression
		$Lfin=1;}
	    elsif ($Lok){
		$_=~s/^CC\s+//;
		$loci.=$_." ";}
	    last if ($Lfin);}
	close($fhinLoc);
	next if (length($loci)<5);
	$loci=~s/\t+/\s/g; 
	print $fhoutLoc "--- '$regexpLoc' in $fileTmp:$loci\n"
	    if ($LverbLoc);
	$id=$fileTmp;
	$id=~s/^.*\///g;$id=~s/\n|\s//g;
	$tmp="$loci"."\t"."$id";
	push(@finLoc,"$tmp");}
    return(1,"ok",@finLoc);
}				# end of swissGetLocation


#==============================================================================
# library collected (end)   lll
#==============================================================================
