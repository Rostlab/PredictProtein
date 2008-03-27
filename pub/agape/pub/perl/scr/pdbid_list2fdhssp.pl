#!/usr/bin/perl -w
##!/usr/sbin/perl -w
# converts a  list of PDB'ids(1pdbC) to H/F/D/ssp (/data/hssp/1pdb.hssp_C)
#
$[ =1 ;


@opt=("dssp","hssp","fssp","dir","ext");
if ($#ARGV<1){print"goal :  converts list of id's 1pdbC into '/data/hssp/1pdb.hssp_C'\n";
	      print"usage:  'script file' \n";
	      print"option: (default hssp) ";&myprt_array(",",@opt);
	      exit;}

$file_in=$ARGV[1];$fileOut=$file_in."_out";
$fhin="FHIN";$fhout="FHOUT";
$par{"mode"}="hssp";
$par{"dir"}= "unk";
$par{"ext"}= "unk";
				# read online arguments
foreach $arg(@ARGV){
    if ($arg=~/^[hdf]ssp/){
	$arg=~s/^([dhf]ssp).*$/$1/g;$par{"mode"}=$arg;}
    else {
	foreach $opt(@opt){if ($arg =~/^$opt=/){$arg=~s/^$opt=//g;$par{"$opt"}=$arg;
						 last;}}}}
				# process input
if ($par{"dir"} eq "unk"){$par{"dir"}="/data/".$par{"mode"}."/";}
if ($par{"ext"} eq "unk"){$par{"ext"}=".".$par{"mode"};}

&open_file("$fhin", "$file_in");&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n|\s//g;$_=~s/_//g;
		 if (length($_)>4){$id=substr($_,1,4);$chain=substr($_,5,1);}
		 else {$id=$_;$chain="";}
		 if ($par{"mode"}=~/^[dh]ssp/){
		     $file=$par{"dir"}.$id.$par{"ext"};
		     if (length($chain)>0){$fileX=$file."_"."$chain";}else{$fileX=$file;}}
		 else {
		     $file=$fileX=$par{"dir"}.$id.$chain.$par{"ext"};}
			 
		 if (-e $file){print $fhout $fileX,"\n";}else {print"*** missing $fileX\n";}}
			       
close($fhin);close($fhout);

print"output in $fileOut\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub myprt_array {
    local($sep,@A)=@_;$[=1;local($a);
#   myprt_array                 prints array ('sep',@array)
    foreach $a(@A){print"$a$sep";}
    print"\n" if ($sep ne "\n");
}				# end of myprt_array

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
