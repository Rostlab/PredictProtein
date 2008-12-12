#!/usr/bin/perl -w
##!/usr/sbin/perl -w

#
# reads file and converts ARG2 to ARG3
#
$[ =1 ;


$file_in=$ARGV[1];
$exp_old=$ARGV[2];$exp_old=~s/\'//g;
$exp_new=$ARGV[3];$exp_new=~s/\'//g;
print "replace old ='$exp_old' by new='$exp_new', for file $file_in\n";

$fhin="FHIN";$fhout="FHOUT";
$file_out=$file_in;$file_out=~s/^.*\///g;$file_out.="_prt";

&open_file("$fhin", "$file_in");
&open_file("$fhout", ">$file_out");
while (<$fhin>) {
    $_=~s/$exp_old/$exp_new/g;
    print $fhout $_;
}
close($fhin);close($fhout);
print "--- output in $file_out\n";
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