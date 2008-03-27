#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs the dssp extract";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
$par{"dirDsspData"}=        "/data/dssp/";
$par{"exeExtrDsspRange"}=   "/home/rost/perl/scr/dsspExtrRange.pl";
$par{"dirDsspLoc"}=         "dsspDom";
$par{"extDssp"}=            ".dssp";
				# ------------------------------
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-with-domains (from orengo-domain-rd.pl)'\n";
    print "opt: \t \n";
    print "     \t dirDsspData=x      (default: ",$par{"dirDsspData"},")\n";
    print "     \t exeExtrDsspRange=x (default: ",$par{"exeExtrDsspRange"},")\n";
    print "     \t dirDsspLoc=x       (default: ",$par{"dirDsspLoc"},")\n";
    print "     \t extDssp=x          (default: ",$par{"extDssp"},")\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^dirDsspData=(.*)$/)     {$par{"dirDsspData"}=$1;}
    elsif($_=~/^exeExtrDsspRange=(.*)$/){$par{"exeExtrDsspRange"}=$1;}
    elsif($_=~/^dirDsspLoc=(.*)$/)      {$par{"dirDsspLoc"}=$1;}
    elsif($_=~/^extDssp=(.*)$/)         {$par{"extDssp"}=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
$dirDsspData= &complete_dir($par{"dirDsspData"});
$dirDsspLoc=  &complete_dir($par{"dirDsspLoc"});
$exe=         $par{"exeExtrDsspRange"};

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
    $fileDssp=$dirDsspData.$id.$par{"extDssp"};
    $fileOut= $dirDsspLoc.$idx.$par{"extDssp"};
				# ------------------------------
				# check existence
    if (! -e $fileDssp){
	print "*** fileDssp '$fileDssp' missing\n";
	next;}
				# ------------------------------
				# call dsspExtrDsspRange
    $cmd="$exe $fileDssp $chain pdbNo=$range fileOut=$fileOut ";
    print "--- system \t '$cmd'\n";
    system("$cmd");		# external script

    next if (! -e $fileOut );
    push(@fileOk,$fileOut);
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
