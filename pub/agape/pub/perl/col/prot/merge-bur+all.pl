#!/usr/sbin/perl -w
#
# merges files with composition for all residues and for exposed residues, only
#
$[ =1 ;

				# include libraries
# push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<2){print"goal:   merges RDB with compo for all res and for expied res, only\n";
	      print"usage:  script file-exp.rdb file-all.rdb \n";
	      print"  e.g.: e4-25-profExp.rdb e4-25-profAll.rdb \n";
	      exit;}

$fileInRdbExp=$ARGV[1];$fileInRdbAll=$ARGV[2];
$fhin="FHIN";$fhout="FHOUT";
$fileOut=$fileInRdbExp;$fileOut=~s/^.*\///g;$fileOut=~s/Exp/ExpAll/g;

@aaNamesHssp=("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D");

$#rdbAll=$#rdbExp=$#head=0;
				# first read header
&open_file("$fhin", "$fileInRdbAll");
while (<$fhin>) {$line=$_;
		 if ($line =~ /^\#/ ){
		     push(@head,$_);}
		 else {
		     last;}}close($fhin);
				# read expied data
%rdbExp=&rdRdbAssociative($fileInRdbExp,"body",
			  "loci","id1","id2","len1","len2","lali","nres",@aaNamesHssp);
				# read all data
%rdbAll=&rdRdbAssociative($fileInRdbAll,"body",
			  "loci","id1","id2","len1","len2","lali","nres",@aaNamesHssp);
				# ------------------------------
				# now merge and write
&open_file("$fhout", ">$fileOut");
foreach $head(@head){		# header
    print $fhout "$head";}
				# --------------------
				# column names
print $fhout "loci";foreach $kwd ("id1","id2"){print $fhout "\t","$kwd";}
foreach $kwd ("len1","len2","lali","nres",@aaNamesHssp){
    print $fhout "\t","$kwd"."E";}
foreach $kwd ("len1","len2","lali","nres",@aaNamesHssp){
    print $fhout "\t","$kwd"."A";}print $fhout "\n";
				# --------------------
				# data
foreach $it (1..$rdbExp{"NROWS"}){
    $idExp=$rdbExp{"id1","$it"}.",".$rdbExp{"id2","$it"};$idExp=~s/\s//g;
    $idAll=$rdbAll{"id1","$it"}.",".$rdbAll{"id2","$it"};$idAll=~s/\s//g;
    if ($idExp ne $idAll){print "*** ERROR it=$it, idExp=$idExp, idAll=$idAll\n";
			  die;}
    print $fhout "$it";
				# exp
    foreach $kwd ("loci","id1","id2","len1","len2","lali","nres",@aaNamesHssp){
	print $fhout "\t",$rdbExp{"$kwd","$it"};}
				# all
    foreach $kwd ("len1","len2","lali","nres",@aaNamesHssp){
	print $fhout "\t",$rdbAll{"$kwd","$it"};}
    print $fhout "\n";
}
close($fhout);
print"--- output in '$fileOut'\n";
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
