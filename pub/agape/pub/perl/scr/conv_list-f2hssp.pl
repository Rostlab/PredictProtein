#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# remove chain name
#
$[ =1 ;

if ($#ARGV<1){print"goal:   remove chain name from 1801A.hssp \n";
	      print"usage:  script file (takes all capitals)\n";
	      print"option: out=hssp, out=dssp (replace ext -> hssp)\n";
	      exit;}

$fileIn=$ARGV[1];
$out="hssp";
foreach $arg(@ARGV){
    if ($arg =~/out=/){$out=$arg;$out=~s/^out=//g;}}

$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");&open_file("$fhout", ">$fileOut");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/[A-Z]//g;$_=~s/(\/?....).?\./$1./;
    $_=~s/.ssp/$out/;
    print "new $_\n";
    print $fhout "$_\n";}
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
