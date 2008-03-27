#!/usr/bin/perl -w
##!/usr/pub/bin/perl -w
#
# hack
# 
# input: arg1 = file-with-HSSP-headers    (hssp_extr_header.pl on list)
#        arg2 = file-with-SWISS-locations (getSwissLocation.pl on list)
#
$[ =1 ;

# 				# include libraries
# push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
@lociAbbrev=    ("cyt","pla","ret","ext","gol",
		 "lys","mit","nuc","oxi","vac","rip");
				# help?
if ($#ARGV<2){print"goal:   merges the HSSP headers and the swiss locations\n";
	      print"in:     arg1 = file-with-HSSP-headers    (hssp_extr_header.pl on list)\n";
	      print"in:     arg2 = file-with-SWISS-locations (getSwissLocation.pl on list)\n";
	      print"            or interpretation thereof do:\n";
	      print"            'lociInterpretSwiss.pl Euka2-allLoci.rdb'\n";
	      print"usage:  'script fileAlis fileLoci' (HSSP-headers.rdb swissLoci.rdb\n";
	      print"option: fileOut=x \n";
	      print"        loci=cyt,ext,nuc or:\n";
	      print"            =";
	      foreach $loci(@lociAbbrev){print"$loci,";}print"\n";
	      exit;}
				# read command line
$fileAlis=    $ARGV[1];
$fileLoci=    $ARGV[2];
$fileOut="out-xx-hack-combi95.rdb";
$lociGet="cyt,ext,nuc";
foreach $it (3..$#ARGV){
    if   ($ARGV[$it]=~/^fileOut=(.+)/){$fileOut=$1;}
    elsif($ARGV[$it]=~/^loci=(.+)/)   {$lociGet=$1;}}
if ($lociGet eq "all"){@lociGet=("cyt","pla","ret","ext","gol",
				 "lys","mit","nuc","oxi","vac","rip");}
else {
    $lociGet=~s/^,|,$//g;
    @lociGet=split(/,/,$lociGet);}
@lociGet=("cyt","pla","ret","ext","gol",
	  "lys","mit","nuc","oxi","vac","rip","unk");
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
				# read all loci
&open_file("$fhin", "$fileLoci");$ct=$Linter=0;
while (<$fhin>) {		# header
    if (/\# SWISS-PROT .* loc.* \(inter/){$Linter=1;}
    if (/\#/){next;}
    ++$ct; last if ($ct==2);}

if ($Linter){print "--- $fileLoci is interpreted SWISS-PROT location\n";}

while (<$fhin>) {		# body
    $_=~s/\n//g;$_=~s/^\s*|\s*$//g;
    @tmp=split(/\t/,$_);
    $loci=$tmp[3];$name=$tmp[2];$name=~s/\s//g;
				# interpreted version (loci = ext,cyt,nuc)
    if ($Linter){
	$Lok=0;$loci=~s/\s//g;
	foreach $lociGet(@lociGet){
	    if ($loci eq "$lociGet"){$Lok=1;$loci=$lociGet;
				     $loci{"$name"}=$loci;
				     last;}}
	if (! $Lok){$loci="unk";}}
				# non-interpreted version (loci = raw SWISS-PROT line)
    else {
	if ($loci =~/ AND /){
	    $loci="unk";}
	elsif ($loci =~ /CYTOPLASMIC\.|NUCLEAR\.|EXTRACELLULAR\./){
	    $loci=~s/^.*?(CYTOPLASMIC|NUCLEAR|EXTRACELLULAR).*$/$1/;
	    $loci=~tr/[A-Z]/[a-z]/;
	    $loci=~s/\s//g;$name=~s/\s//g;
	    $loci{"$name"}=$loci;}}
}close($fhin);
				# ------------------------------
				# now compare two sets
%Ldone=0;
$ctSingle=$ctAll=0;
				# read all sequences in HSSP
$#swiss=$#hssp=0;
&open_file("$fhin", "$fileAlis");$ct=0;
&open_file("$fhout", ">$fileOut");

while (<$fhin>) {
    if (/\#/){
	print $fhout $_;
	next;}
    ++$ct; 
    if    ($ct==1){ $_=~s/ID(\s*\t)/ID2$1/;
		    printf $fhout "%-10s\t%-15s\t","king","loci";} # name
    elsif ($ct==2){ printf $fhout "%-10s\t%-15s\t","10S","15S";} # format
    
    print $fhout $_ ;
#    print $fhout $_ ,"\n";
    last if ($ct==2);}
while (<$fhin>) {
    $_=~s/\n//g;$_=~s/^\s+|\s+$//g;
    @tmp=split(/\t/,$_);
    $swiss=$tmp[4];$hssp=$tmp[3];
    $swiss=~s/\s//g;$hssp=~s/\s//g;

    if (defined $loci{"$swiss"}){
	++$ctAll;
	printf $fhout "%-10s\t%-15s\t","euka",$loci{"$swiss"};
	print $fhout $_,"\n";
    }
    else {
	print "xx not defined for '$swiss'\n";
    }
    if (defined $Ldone{"$hssp"}){
	next;}
    if (defined $loci{"$swiss"}){
	$Ldone{"$hssp"}=1;
	++$ctSingle;}
}close($fhin);close($fhout);
print "--- fin single=$ctSingle, all=$ctAll, out=$fileOut\n";

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

