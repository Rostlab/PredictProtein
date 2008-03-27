#!/usr/sbin/perl -w
#
# reads output of statTranslocation, returns statistics about composition
#
$[ =1 ;

				# initialise variables
if ($#ARGV<1){print"goal:   reads output of statTranslocation, returns composition statistics\n";
	      print"usage:  statCompoTransl.pl out_statTranslocation (id\tlocation\tSEQWENCE)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";$fhout2="FHOUT2";
$fileOut="Out-transloc.rdb";

$nresMin=10;
$nresMax=40;
$nresItrvl=2;
@aaNamesAbcd= ("A","C","D","E","F","G","H","I","K","L",
	       "M","N","P","Q","R","S","T","V","W","Y");
@desLoci=("nuc","cyt","ext");
foreach $des (@desLoci){	# ini
    $rd{"id","$des"}=$rd{"aa","$des"}="";}
&open_file("$fhin", "$fileIn");	# read file
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t+/,$_);foreach $tmp(@tmp){$tmp=~s/\s//g;}
		 $Lok=0;
		 foreach $loc (@desLoci){
		     if ($tmp[2]=~/^$loc/){$rd{"id","$loc"}.="$tmp[1]".",";
					   $rd{"aa","$loc"}.="$tmp[3]".",";
					   $Lok=1;
					   last;}}
		 if (! $Lok){print "*** missing location for '$_'\n";}} close($fhin);
$nres=$nresMin;
while ($nres <= $nresMax){	# intervals from nresMin .. nresMax (in steps of nresItrvl)
    $fileOutTmp=$fileOut; $fileOutTmp=~s/Out-/Out-$nres-/;
    &open_file("$fhout", ">$fileOutTmp");
    print $fhout "# Perl-RDB\n","# translocation residues 1-$nres\n";
    print $fhout "loci\tid2";	# names
    foreach $aaSym (@aaNamesAbcd){print $fhout "\t$aaSym";}print $fhout "\n";
    print $fhout "15S\t10S";	# formats
    foreach $aaSym (@aaNamesAbcd){print $fhout "\t5.2F";}print $fhout "\n";
	
				# ------------------------------
    foreach $loc (@desLoci){	# statistics
	$rd{"id","$loc"}=~s/,$//g; # purge leading commata
	$rd{"aa","$loc"}=~s/,$//g; # purge leading commata
	@protId=split(/,/,$rd{"id","$loc"});
	@protAa=split(/,/,$rd{"aa","$loc"});
	foreach $it (1..$#protAa){ # all proteins
	    printf $fhout "%-15s\t%-10s",$loc,$protId[$it];

	    $tmp=substr($protAa[$it],1,$nres); # take only nres first residues
	    %res=0;		# compute composition
	    @seq=split(//,$tmp);foreach $aaSym (@aaNamesAbcd){$res{$aaSym}=0;} # ini
	    foreach $aaSym (@aaNamesAbcd){
		foreach $seq (@seq){
		    if ($seq eq $aaSym){
			++$res{$aaSym};}}}
	    foreach $aaSym (@aaNamesAbcd){
		if ($aaSym eq $aaNamesAbcd[$#aaNamesAbcd]){$sep="\n";}else{$sep="\t";}
		printf $fhout "%5.2f$sep",100*$res{$aaSym}/$nres;}}
    }close($fhout);
    $nres+=$nresItrvl;
}				# end of looping over intervals
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
