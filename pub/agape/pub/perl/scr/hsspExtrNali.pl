#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="greps 'NALIGN' from HSSP file\n";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      '', ""
      );
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName list.hssp (or *.hssp)'\n";
    print "opt: \t nali=(ge|gt|le|lt)x     : only those\n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (keys %par){
	    print "     \t $kwd=",$par{"$kwd"}," (def)\n";}}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg (@ARGV){
    if   ($arg=~/^fileOut=(.*)$/)       {$fileOut=$1;}
    elsif($arg=~/^nali=([glet]+)(\d+)$/){$naliExcl=$2; $modeExcl=$1;}
#    elsif($arg=~/^=(.*)$/){$=$1;}
    else {$Lok=0;
	  if (-e $arg){$Lok=1;
		       push(@fileIn,$arg);}
	  if (! $Lok && defined %par){
	      foreach $kwd (keys %par){
		  if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					     last;}}}
	  if (! $Lok){print"*** wrong command line arg '$arg'\n";
		      die;}}}
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    if (defined $naliExcl){
	$tmp2="gt".$naliExcl."-"  if ($modeExcl eq "gt");
	$tmp2="ge".$naliExcl."-"  if ($modeExcl eq "ge");
	$tmp2="lt".$naliExcl."-"  if ($modeExcl eq "lt");
	$tmp2="le".$naliExcl."-"  if ($modeExcl eq "le"); } else {$tmp2="";}
    $fileOut="Out-".$tmp2.$tmp;}
				# ------------------------------
				# read list (if list)
if (! &is_hssp($fileIn)){
    print "--- $scrName: read list '$fileIn'\n";
    $#fileIn=0;
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    while (<$fhin>) {$_=~s/\n|\s//g;
		     next if (length($_)<5);
		     push(@fileIn,$_); } close($fhin);}

				# ------------------------------
				# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $tmp=`grep '^NALIGN' $fileIn`; 
    $tmp=~s/^NALIGN\s*(\d+).*$/$1/g; $tmp=~s/\n|\s//g;
    $Lok=1;
    if (defined $naliExcl) { 
	$Lok=0  if (($modeExcl eq "gt")  && ($tmp <= $naliExcl) );
	$Lok=0  if (($modeExcl eq "ge")  && ($tmp <  $naliExcl) );
	$Lok=0  if (($modeExcl eq "lt")  && ($tmp >= $naliExcl) );
	$Lok=0  if (($modeExcl eq "le")  && ($tmp >  $naliExcl) );}
    if ($Lok){
	$ok{$fileIn}=$tmp;
	print "--- ok $fileIn n=$tmp"; 
	print " : $modeExcl $naliExcl" if (defined $naliExcl);
	print "\n";}
}
				# ------------------------------
				# (2) write output
&open_file("$fhout",">$fileOut"); 
foreach $fileIn(@fileIn){
    next if (! defined $ok{$fileIn});
    $tmp=sprintf("%-40s %5d\n",$fileIn,$ok{$fileIn});
    print $tmp;
    printf $fhout $tmp; 
    
}
close($fhout);

print "--- output in $fileOut\n";
exit;



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || 
	do {print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	    return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1) if ($tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

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
# library collected (end)
#==============================================================================


1;
