#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs the dssp extract, do max stuff for domains";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
$par{"exeExtrHsspRange"}=   "/home/rost/perl/scr/hsspExtrRange.pl";
$par{"exePhd"}=             "/home/rost/pub/phd/phd.pl";

$par{"dirDsspData"}=        "/data/dssp/";
$par{"dirHsspData"}=        "/data/hssp/";

$par{"extDssp"}=            ".dssp"; # extension of DSSP files (as in /data/ and as will be written)
$par{"extHssp"}=            ".hssp"; # extension of hssp files (as in /data/ and as will be written)
$par{"extPhdRdb"}=          ".rdbPhd"; # ext of PHD file (as will be written)

$par{"dirDsspLoc"}=         "dsspDom";
$par{"dirHsspLoc"}=         "hsspDom";
$par{"dirPhdRdbLoc"}=       "rdbPhdDom";

if (! defined $ENV{'ARCH'}){print "*** setenv ARCH to machine type (for MAXHOM and PHD)\n";
			    exit;}
$ARCH=$ENV{'ARCH'};
				# ------------------------------
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-with-domains (from orengo-domain-rd.pl)'\n";
    print "opt: \t \n";
    print "     \t noPhd / noMax / noDssp (will no run PHD/Maxhom/not store DSSP file\n";
    print " exe\n";
    print "     \t exeExtrHsspRange=x (default: ",$par{"exeExtrHsspRange"},")\n";
    print "     \t exePHD=x           (default: ",$par{"exePhd"},")\n";
    print " data\n";
    print "     \t dirDsspData=x      (default: ",$par{"dirDsspData"},")\n";
    print "     \t dirHsspData=x      (default: ",$par{"dirHsspData"},")\n";
    print " local\n";
    print "     \t dirDsspLoc=x       (default: ",$par{"dirDsspLoc"},")\n";
    print "     \t dirHsspLoc=x       (default: ",$par{"dirHsspLoc"},")\n";
    print " ext\n";
    print "     \t extDssp=x          (default: ",$par{"extDssp"},")\n";
    print "     \t extHssp=x          (default: ",$par{"extHssp"},")\n";
    print "     \t extPhdRdb=x        (default: ",$par{"extPhdRdb"},")\n";
#    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";
$LnoPhd=$LnoMax=$LnoDssp=0;
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^dirDsspData=(.*)$/)     {$par{"dirDsspData"}=$1;}
    elsif($_=~/^dirHsspData=(.*)$/)     {$par{"dirHsspData"}=$1;}
    elsif($_=~/^exeExtrHsspRange=(.*)$/){$par{"exeExtrHsspRange"}=$1;}
    elsif($_=~/^exePhd=(.*)$/)          {$par{"exePhd"}=$1;}
    elsif($_=~/^dirDsspLoc=(.*)$/)      {$par{"dirDsspLoc"}=$1;}
    elsif($_=~/^dirHsspLoc=(.*)$/)      {$par{"dirHsspLoc"}=$1;}
    elsif($_=~/^extDssp=(.*)$/)         {$par{"extDssp"}=$1;}
    elsif($_=~/^extHssp=(.*)$/)         {$par{"extHssp"}=$1;}
    elsif($_=~/^extPhdRdb=(.*)$/)       {$par{"extPhdRdb"}=$1;}
    elsif($_=~/^noPhd/i)                {$LnoPhd=1;}
    elsif($_=~/^noMax/i)                {$LnoMax=1;}
    elsif($_=~/^noDssp/i)               {$LnoDssp=1;}
#    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

foreach $dir ("dirHsspData","dirDsspData","dirPhdRdbLoc","dirDsspLoc","dirHsspLoc"){
    $par{"$dir"}=&complete_dir($par{"$dir"});}
$exePhd=$par{"exePhd"};
				# ------------------------------
				# (1) read file
$#fileOk=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    next if ($_=~/^no|^id/);
				# ------------------------------
				# get range, chain, asf
    @tmp=split(/\t/,$_);
    $idx=$tmp[2];$idx=~s/\*/0/g;$id=$tmp[4];
    $chain=$tmp[5];$chain=~s/\*/0/g;$range=$tmp[6];$len=$tmp[3];$len=~s/\s//g;
    $fileDssp=    $par{"dirDsspData"}.$id. $par{"extDssp"};
    $fileHssp=    $par{"dirHsspData"}.$id. $par{"extHssp"};
    $fileOutHssp= $par{"dirHsspLoc"} .$idx.$par{"extHssp"};
    $fileOutDssp= $par{"dirDsspLoc"} .$idx.$par{"extDssp"};
				# ------------------------------
				# check existence
    if (! -e $fileDssp){
	print "*** fileDssp '$fileDssp' missing\n";
	next;}
#    $tmpHssp="/data/hssp/$id".".hssp";
				# ------------------------------
				# call dsspExtrDsspRange
    $cmd= $par{"exeExtrHsspRange"}." $fileDssp $chain pdbno=$range";
    $cmd.=" fileHssp=$fileHssp fileOutDssp=$fileOutDssp fileOutHssp=$fileOutHssp";
    print "--- system \t '$cmd'\n";
    system("$cmd");		# external script

    next if (! -e $fileOutHssp || &is_hssp_empty($fileOutHssp));
				# ------------------------------
				# run PHD
    if (! $LnoPhd){
	if ($ARCH =~/SGI64/){$exePhd="/home/rost/pub/phd/phdPhenix.pl";}
	$fileRdb=$fileOut;$fileRdb=~s/^.*\///g;$fileRdb=~s/\.hssp//g;
	$fileRdb.=$par{"extPhdRdb"};
	$cmd=$par{"exePhd"}." $fileOutHssp acc fileRdb=$fileRdb";print "--- system \t '$cmd'\n";
	system("$cmd");
				# ------------------------------
				# move and remove files
	$tmp=$fileRdb;$tmp=~s/\.rdb.*$/\.phd/;
	if (-e $tmp){unlink($tmp);}
	if (-e $fileRdb){
	    $cmd="\\mv $fileRdb ".$par{"dirPhdRdbLoc"};print "--- system \t '$cmd'\n";
	    system("$cmd");}}
    $cmd="\\mv $fileOutHssp ".$par{"dirHsspLoc"};  print "--- system \t '$cmd'\n";
    system("$cmd");
    
    push(@fileOk,$fileOutHssp);
}close($fhin);
print "--- output files =";foreach $fileOk(@fileOk){print "$fileOk,";}print "\n";
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
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

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