#!/usr/sbin/perl -w
#
# reads SWISS-PROT list, returns first residues and location
#
$[ =1 ;

				# initialise variables
if ($#ARGV<1){print"goal:   reads SWISS-PROT list, returns first residues and location\n";
	      print"usage:  statTranslocation.pl swiss-files (or list)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn; if ($#ARGV>1){$fileOut="Out-translocation.tmp";}
@txtLoci=("CYTOPLASMIC","EXTRACELLULAR","NUCLEAR");
$outLoci{CYTOPLASMIC}="cyt";$outLoci{EXTRACELLULAR}="ext";$outLoci{NUCLEAR}="nuc";
$nresWrt=40;

$#file=0;
foreach $arg (@ARGV){
    if (! -e $arg){print "*** file '$arg' missing\n";
		   exit;}
    if (&isSwissList($arg)){&open_file("$fhin", "$arg");
			    while (<$fhin>) {$_=~s/\n//g;
					     if (-e $_){push(@file,$_);}}close($fhin);}
    elsif (&isSwiss($arg)){
	push(@file,$arg);}}

				# now loop over SWISS-PROT files
&open_file("$fhout", ">$fileOut");
foreach $file (@file){
    print "xx reading '$file'\n";
    &open_file("$fhin", "$file");
    $loc="unk";$seq="";
    while (<$fhin>) {$_=~s/\n//g;
		     if (/^.*SUBCELLULAR LOCATION:\s+(.+)$/){
			 $lineLoc=$_;
			 $loc=$1;}
		     elsif (/^\s+/){
			 $_=~s/\s//g;
			 $seq.=$_;}}close($fhin);
    $Lok=0;
    foreach $txt (@txtLoci){if ($loc =~/$txt/){$loc=$outLoci{$txt};
					       $Lok=1;
					       last;}}if (! $Lok){$loc="unk";}
    $id=$file;$id=~s/^.*\///g;
    print "xx id=$id, loc=$loc, line=$lineLoc,\n";
    print $fhout "$id\t$loc\t",substr($seq,1,$nresWrt),"\n";
    print "$id\t$loc\t",substr($seq,1,$nresWrt),"\n";
    
}close($fhout);
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


