#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract a range (and or chain) from DSSP file";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
$par{"dirDssp"}=                "/home/data/dssp/";
$par{"dirDssp"}=                ".dssp";
				# ------------------------------
				# help
if ($#ARGV<2){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file_hssp chain ('0' for wild card)'\n";
    print "opt: \t pdbno=1-5,8-100 (reads PDBno as given, i.e., 2nd column in DSSP)\n";
    print "or:  \t no=1-5,8-100    (reads the DSSP no, i.e., first column)\n";
    print "     \t \n";
    print "     \t fileOut=x\n";
    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=  $ARGV[1];
$chainIn= $ARGV[2];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

$Ldssp=$Lpdb=0;
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);next if ($_ eq $ARGV[2]);
    if   ($_=~/^fileOut=(.*)$/) {$fileOut=$1;}
    elsif($_=~/^no=(.*)$/)      {$rangeIn=$1;$Ldssp=1;}
    elsif($_=~/^pdbno=(.*)$/i)  {$rangeIn=$1;$Lpdb=1;}
    elsif($_=~/^fileHssp=(.*)$/){$fileHssp=$1;}
    else { if ($_ eq $ARGV[3])  {$rangeIn=$ARGV[3];
				 next;}
	   print"*** wrong command line arg '$_'\n";
	   die;}}
if (! -e $fileIn){
    print "*** ERROR no DSSP $fileHssp for $fileIn\n";
    die;}
				# ------------------------------
				# (1) get range
@tmp=split(/,/,$rangeIn);
foreach $it (1..10000){$ok[$it]=0;}
$nres=0;
foreach $tmp(@tmp){
    $tmp=~s/\s//g;
    @tmp2=split(/-/,$tmp);
    foreach $it ($tmp2[1]..$tmp2[2]){++$nres;
				     $ok[$it]=1;}
    $max=$tmp2[2];}
				# ------------------------------
				# (2) read DSSP file
&open_file("$fhin", "$fileIn");
$#rd=0;
while (<$fhin>) {push(@rd,$_);
		 last if ($_=~/^\s+\#\s+RES/);}
while (<$fhin>) {$line=$_;
		 $chain= substr($_,12,1);
		 $pdbNo= substr($_,6,5);$pdbNo=~s/\s//g;
		 $dsspNo=substr($_,1,5);$dsspNo=~s/\s//g;
		 next if ($Lpdb  && length($pdbNo)<1);
		 next if ($Ldssp && length($dsspNo)<1);
		 next if ($chainIn ne "0" && $chain ne $chainIn);
		 next if ($Lpdb  && ! $ok[$pdbNo]) ; # if mode is range of PDBno
		 next if ($Ldssp && ! $ok[$dsspNo]); # if mode is range of DSSPno
		 push(@rd,$line);
		 ++$ctRes; 
		 if ($ctRes > ($nres+10)){ # allow for more (PDB 64,64A,...)
		     print "*** $fileIn too many residues now $ctRes max=$max, nres=$nres,\n";
		     exit;}}
close($fhin);
$nres=$ctRes;			# correct for additional PDB residues

				# ------------------------------
				# (3) write DSSP output
print "--- write DSSP $fileOut\n";
&open_file("$fhout",">$fileOut"); 
foreach $rd(@rd){
    if ($rd =~/TOTAL NUMBER OF RES/){
	printf $fhout "%5d%-s\n",$nres,substr($rd,6);}
    else{
	print $fhout $rd;}}
close($fhout);
				# ------------------------------
				# (4) write output
print "--- output in $fileOut\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


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
# library collected (end)   lll
#==============================================================================


1;
