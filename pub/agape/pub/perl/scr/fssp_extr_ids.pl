#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# extracts pdb'ids from FSSP file
#
$[ =1 ;


if ($#ARGV<1){print"goal:   extracts PDBid's from FSSP file\n";
	      print"usage:  script list-of-files (or as many arg's)\n";
	      print"option: get=id1,id2 (i.e. a list of id's to be grepped)\n";
	      exit;}
$fhin="FHIN";$fhout="FHOUT";
$par{"dirFssp"}="/data/fssp/";
$LnotScreen=0;

$fileIn=$ARGV[1];$#fileIn=0;
$fileOut=$fileIn; $fileOut=~s/^.*\///g;$fileOut="PDBid".$fileOut.".tmp";
$#idSearch=0;

foreach $arg(@ARGV){if    ($arg=~/^get=/){$arg=~s/^get=//g;@idSearch=split(/,/,$arg);
					  last;}
		    elsif ($arg=~/^not_screen|^notScreen/){$LnotScreen=1;
							   last;}}
if (&is_fssp_list($fileIn)){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n//g;
		     if (! -e $_){next;}
		     push(@fileIn,$_);}close($fhin);}
else {
    foreach $arg(@ARGV){if ($arg=~/^get=/){next;}
			$tmp=$par{"dirFssp"}."$arg";
			if    (-e $arg){push(@fileIn,$arg);}
			elsif (-e $tmp){push(@fileIn,$tmp);}}}

				# read all
&open_file("$fhout", ">$fileOut");
foreach $fileIn (@fileIn){
    $#id=0;
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {last if (/^  NR\./);}
    while (<$fhin>) {$_=~s/\n//g;if ($_ !~/\S/){next;}
		     last if (/^\#\#/);
		     $id=substr($_,14,6);$id=~s/\s|-//g;
		     if ($#idSearch>0){
			 foreach $idSearch(@idSearch){
			     if ($idSearch eq $id){
				 push(@id,$id);
				 last;}}}
		     else{
			 push(@id,$id);}}close($fhin);
    print $fhout "for '$fileIn',",$#id," hits\n";
    foreach $id(@id){print $fhout "$id,";}print $fhout "\n"; 
    print "for '$fileIn',",$#id," hits\n";
    foreach $id(@id){print "$id,";}print "\n";
}close($fhout);

if (! $LnotScreen){ print "--- output in $fileOut\n"; }
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub is_fssp {
    local ($fileInLoc) = @_ ;
#--------------------------------------------------------------------------------
#   is_fssp                     checks whether or not file is in FSSP format
#       in:                     $file
#       out:                    1 if is fssp; 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP";
    open($fh, $fileInLoc) || return(0);
    $tmp=<$fh> ;
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^FSSP/);
    return(0);
}				# end of is_fssp

#==============================================================================
sub is_fssp_list {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_fssp_lis                 checks whether or not file is a list of FSSP files
#       in:                     $file
#       out:                    1 if is list of fssp files; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$_=~s/\s|\n//g;
		     if ( -e $_ ) { # is existing file?
			 $Lis=1 if (&is_fssp($_));
			 last; } } close($fh);
    return $Lis;
}				# end of is_fssp_list

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
