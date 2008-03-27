#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# extracts the keyword line for list of swiss-prot files
#
$[ =1 ;

				# initialise variables

if ($#ARGV<1){print"goal:   extracts the keyword line for list of swiss-prot files \n";
	      print"usage:  script list_swiss (or file*)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-keyword.tmp";

				# ------------------------------
				# extract command line
$#file=0;
if (&isSwissList($fileIn)){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\s//g;
		     if (-e $_){push(@file,$_);}}}
else {
    foreach $arg(@ARGV){
	if (-e $_){push(@file,$arg);}}}

				# ------------------------------
				# read swissprot files
foreach $file (@file){
    print "--- reading $file\n";
    &open_file("$fhin", "$file");$tmp="";$id=$file;$id=~s/^.*\///g;
    while (<$fhin>) {if ($_ =~ /^KW/){$_=~s/\n//g;$_=~s/^KW\s+//g;
				      $tmp.="$_ ";}}close($fhin);
    print "--- \t kw=$tmp\n";
    push(@kw,$tmp);push(@id,$id);}
				# ------------------------------
				# write id, keyword
&open_file("$fhout", ">$fileOut");
print $fhout "# Perl-RDB\n";
print $fhout "# extract from 'KW' line in SWISS-PROT\n";
print $fhout "swissId\tKW\n";
print $fhout "15S\tS\n";
foreach $it(1..$#kw){
    printf $fhout "%-15s\t%-s\n",$id[$it],$kw[$it];}
close($fhout);
print"--- output in '$fileOut'\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open("$fhinLoc","$fileLoc"); $Lok=0;
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#==============================================================================
sub isSwissList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isSwissList                 checks whether or not file is list of Swiss files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_SwissList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (! -e $fileTmp){return(0);}
			if (&isSwiss($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isSwissList

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
