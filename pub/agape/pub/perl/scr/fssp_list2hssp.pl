#!/usr/bin/perl -w
##!/usr/sbin/perl -w
# converts an fssp list (/data/fssp/1pdbC.fssp) to Hssp (/data/hssp/1pdb.hssp_C)
#
$[ =1 ;


if ($#ARGV<1){print"goal : converts list with /data/fssp/1pdbC.fssp' to '/data/hssp/1pdb.hssp_C'\n";
	      print"usage: 'script file'\n";
	      exit;}

$file_in=$ARGV[1];$fileOut=$file_in."_out";
$fhin="FHIN";$fhout="FHOUT";
&open_file("$fhin", "$file_in");&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n|\s//g;
		 $hssp=$_;$fssp=$_;
		 $hssp=~s/fssp/hssp/g; 
		 if ($hssp=~/\w\w\w\w\w\.hssp/){
		     $hssp=~s/(\w\w\w\w)(\w)\.hssp/$1\.hssp_$2/g;}
		 print "in '$fssp' out '$hssp'\n";
		 $hsspNo=$hssp;$hsspNo=~s/_.$//g;
		 if (-e $hsspNo){
		     print $fhout $hssp,"\n";}
		 else {print"*** missing $hsspNo\n";}}
close($fhin);close($fhout);

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
