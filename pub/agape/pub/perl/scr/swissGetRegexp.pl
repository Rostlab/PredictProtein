#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# goal:   greps keywords from SWISS-PROT files
# usage:  'script file regexp'
#
$[ =1 ;
				# initialise variables

if ($#ARGV<2){print "goal:   greps keywords from SWISS-PROT files\n";
	      print "usage:  'script regexp \@files (or id's)'\n";
	      print "        regular expression can be perl type\n";
	      print "output: array with matching lines (0 if none)\n";
	      print "option:\n";
	      print "        dir=x (directory of swissprot)\n";
	      print "        fileOut=x\n";
	      print "        verbose \n";
	      exit;}

$fhout="FHOUT_swissGetRegexp";
$Lscreen=1;			# write output onto screen?
				# command line
$regexp=$ARGV[1];		# input expression

$#tmp=0;
foreach $it (2..$#ARGV){
    if ($ARGV[$it]=~/^dir=/){	# keyword (swissprot directory)
	$tmp=$ARGV[$it];$tmp=~s/^dir=//g;$par{"dir"}=&complete_dir($tmp);} # external lib-ut.pl
    elsif ($ARGV[$it]=~/^verbose/){
	$Lscreen=1;}
    elsif ($ARGV[$it]=~/^fileOut=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^fileOut=//g;$par{"fileOut"}=$tmp;}
    else {
	push(@tmp,$ARGV[$it]);}}
				# process input
$#file=0;
foreach $input(@tmp){
    if (-e $input){		# is existing file
	push(@file,$input);}
    else {			# search for existing
	$out=&swissGetFile($input,$Lscreen,$par{"dir"}); # external lib-ut.pl
	if (! $out){
	    next;}
	push(@file,$out);}}
				# ------------------------------
				# re-adjust defaults
if (! defined $par{"fileOut"}){
    $par{"fileOut"}="Out-"."swissGetRegexp".".tmp";}
$fileOut=$par{"fileOut"};

if ($Lscreen){print 
		  "--- end of ini settings:\n",
		  "--- regexp = \t '$regexp'\n","--- file out: \t '$fileOut'\n",
		  "--- dirSwiss: \t '",$par{"dir"},"'\n","--- swiss files: \n";
	      foreach $file (@file){print"--- \t $file\n";}}

				# ------------------------------
				# now do for list
$#fin=$#finId=0;
foreach $file (@file){
    @linesRd=&swissGetRegexp($file,$regexp);
    if ($Lscreen){		# print STDOUT
	print "--- '$regexp' in $file:\n";foreach $tmp(@linesRd){print "--- \t $tmp\n";}}
    push(@fin,@linesRd);	# 
    $id=$file;$id=~s/^.*\///g;$id=~s/\n|\s//g;
    foreach $it (1..$#linesRd){
	push(@finId,$id);}
}
				# ------------------------------
				# output file (RDB)
&open_file("$fhout", ">$fileOut");
print $fhout "\# Perl-RDB\n";
printf $fhout "%5s\t%-15s\t%-s\n","lineNo","id","match $regexp";
printf $fhout "%5s\t%-15s\t%-s\n","5N","15","";
foreach $it (1..$#fin){
    printf $fhout "%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
    printf "%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
}
close($fhout);
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir


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
    elsif (-d $Lscreen)       {
	@dirLoc=($LscreenLoc,@dirLoc);
	$LscreenLoc=0;}
    @dirSwissLoc=("/data/swissprot/current/"); # swiss dir's

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
sub swissGetRegexp {
    local ($fileLoc,$regexpLoc) = @_ ;
    local($sbrName,$fhinLoc,@outLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetregexp              searches in SWISS-PROT file for regular expression           
#       in:                     file name
#       out:                    @lines_with_expression
#--------------------------------------------------------------------------------
    $sbrName="swissGetregexp";$fhinLoc="FHIN"."$sbrName";
    &open_file("$fhinLoc", "$fileLoc");
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (/$regexpLoc/){
	    push(@outLoc,$_);}}close($fhinLoc);
    if ($#outLoc>0){
	return(@outLoc);}
    else {
	return(0);}
}				# end of swissGetRegexp



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
