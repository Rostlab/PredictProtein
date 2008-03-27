#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# extracts the kingdom for HSSP list
# 'script list fileHssp-swissId fileAllIdSwiss'
#
$[ =1 ;

				# initialise variables

if ($#ARGV<3){print"goal:   extracts the kingdom for HSSP list\n";
	      print"usage:  'script list file1:hsspSwissId file2:allIdSwiss'\n";
	      print"        file1 contains 'pdbid\tswissId'\n";
	      print"              e.g.: ~/pub/data/hssp/hssp4951-swissId.list\n";
	      print"        file2 contains 'swissfile\tswissId\tkingdom'\n";
	      print"              e.g.: ~/pub/data/swiss/allId-swiss.list\n";
	      exit;}

$fileIn=         $ARGV[1];
$fileHssp2Swiss= $ARGV[2];
$fileSwissKing=  $ARGV[3];
$fhin="FHIN";$fhout="FHOUT";$fhoutTrace="FHOUT_TRACE";
$fileOut=$fileIn;$fileOut=~s/\..*$//g;$fileOut="Out-".$fileOut.".tmp";
$fileTrace=$fileOut; $fileTrace=~s/Out/Trace/;
$dirHssp="/data/hssp/";

				# ------------------------------
$#hssp=0;			# read the list
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\s//g;$file=$_;
		 if (! -e $file){$file=$dirHssp."$_";}
		 if (! -e $file){print "*** no hssp '$file'\n";
				 next;}
		 push(@hssp,$file);}close($fhin);
				# ------------------------------
$#hsspId=0;			# extract ids
foreach $hssp(@hssp){
    $hssp=~s/^.*\///g;$hssp=~s/\..*$//g;
    $Lok{"$hssp"}=1;
    push(@hsspId,$hssp);}
				# ------------------------------
undef %hssp2swiss;		# read the HSSP to Swiss file
&open_file("$fhin", "$fileHssp2Swiss");
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t/,$_);
		 $id=$tmp[1];$id=~s/\s//g;
		 if (defined $Lok{"$id"}){
		     $idSwiss=$tmp[2];$idSwiss=~s/\s//g;
		     $Lok{"$idSwiss"}=1;
		     $hssp2swiss{"$id"}=$idSwiss;}}close($fhin);
				# ------------------------------
undef %swiss2king;		# read the Swiss kingdoms
&open_file("$fhin", "$fileSwissKing");
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t/,$_);
		 $id=$tmp[2];$id=~s/\s//g;
		 if (defined $Lok{"$id"}){
		     $king=$tmp[3];$king=~s/\s//g;
		     $swiss2king{"$id"}=$king;}}close($fhin);
				# write HSSP kingdom
&open_file("$fhout", ">$fileOut"); &open_file("$fhoutTrace", ">$fileTrace");
print $fhoutTrace "idHssp\tidSwiss\n";
print $fhout
    "# Perl-RDB\n",
    "# \n",
    "# kingdoms for HSSP files in $fileIn\n";
printf $fhout "%-6s\t%-15s\t%-10s\n","idHssp","idSwiss","kingdom";
printf $fhout "%-6s\t%-15s\t%-10s\n","6","15","10";

foreach $idHssp(@hsspId){
    $idSwiss=$hssp2swiss{"$idHssp"};
    if (defined $swiss2king{"$idSwiss"}){
	$king=$swiss2king{"$idSwiss"};
	printf "%-6s\t%-15s\t%-10s\n",$idHssp,$idSwiss,$king;
	printf $fhout "%-6s\t%-15s\t%-10s\n",$idHssp,$idSwiss,$king;
    }
    else {
	print $fhoutTrace "$idHssp\t$idSwiss\n";}
}
close($fhout);close($fhoutTrace);


print "--- fileOut=$fileOut, error in '$fileTrace'\n";
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
