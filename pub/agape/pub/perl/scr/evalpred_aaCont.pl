#!/usr/bin/perl -w
##!/usr/sbin/perl -w
$[ =1 ;

# get statistics on PHD.predrel files
# input: phd.predrel

if ($#ARGV<1){print "get statistics on PHD.predrel files\nusage: script phd.predrel\n";
	      exit;}

$file_in=$ARGV[1];
$fhin="FHIN";
$aa20="VLIMFWYGAPSTCHRKQENDBZ";
$aa{"charge"}="ILVHDEKR";
$aa{"chargePos"}="HKR";
$aa{"chargeNeg"}="DE";
$aa{"polar"}="WYHNQSTDEKR";
$aa{"aliphatic"}="ILV";
$aa{"aromatic"}="FWYH";
$aa{"hydrophob"}="CFILMVWY";

@des=    ("obsH","obsL","phdH","phdL","okH","okL");
@desProp=("hydrophob","charge","chargePos","chargeNeg","polar","aliphatic","aromatic");
				# read file phd.predrel
&open_file("$fhin", "$file_in");
$aa=$obs=$phd="";
while (<$fhin>) {if ( /^\s+\d/){$Lnew=1;
				$aa.="!";$obs.="!";$phd.="!";}else{$Lnew=0;}
		 if (! /^AA|^OBS|^PHD/){next;}
		 $_=~s/\n//g;
		 if (/^AA/) {$_=~s/^AA |\|//g;$aa.="$_";}
		 if (/^OBS/){$_=~s/^OBS|\|//g;$obs.="$_";}
		 if (/^PHD/){$_=~s/^PHD|\|//g;$phd.="$_";}}close($fhin);
$obs=~s/ /L/g;$phd=~s/ /L/g;	# replace blanks
$obs=~s/^\!+|\!+$//g;
@obs=split(/!+/,$obs);

$ctLoop=$ctShortLoop5=$ctShortLoop3=$ctShortLoop2=0;		# count loops (and short ones)
foreach $obsx(@obs){
    $obsMin5=$obsx;$obsMin5=~s/LLLLLL+//g;$obsMin5=~s/^H+//g;$obsx=~s/^H+//g;
    $obsMin3=$obsx;$obsMin3=~s/LLLL+//g;$obsMin3=~s/^H+//g;
    $obsMin2=$obsx;$obsMin2=~s/LLL+//g;$obsMin2=~s/^H+//g;
    @loop=split(/H+/,$obsMin5);$nShortLoop=$#loop;$ctShortLoop5+=$nShortLoop;
    @loop=split(/H+/,$obsMin3);$nShortLoop=$#loop;$ctShortLoop3+=$nShortLoop;
    @loop=split(/H+/,$obsMin2);$nShortLoop=$#loop;$ctShortLoop2+=$nShortLoop;
    @loop=split(/H+/,$obsx);$nLoop=$#loop;$ctLoop+=$nLoop;}
				# ini
foreach $it (1..length($aa20)){$tmp=substr($aa20,$it,1);
			       push(@aa20,$tmp);
			       foreach $des (@des){$res{"$tmp","$des"}=0;}}
foreach $des(@des){$res{"sum","$des"}=$res{"per","$des"}=0;
		   foreach $desProp(@desProp){
		       $res{"$desProp","$des"}=0;$res{"per$desProp","$des"}=0;}}
				# statistics
foreach $it (1..length($aa)){
    $aaTmp=substr($aa,$it,1);$obsTmp=substr($obs,$it,1);$phdTmp=substr($phd,$it,1);
    if ($obsTmp eq "H"){
	++$res{"$aaTmp","obsH"};
	if ($phdTmp eq $obsTmp){ # correct?
	    ++$res{"$aaTmp","okH"};}}
    else {
	++$res{"$aaTmp","obsL"};
	if ($phdTmp eq $obsTmp){ # correct?
	    ++$res{"$aaTmp","okL"};}}
    if ($phdTmp eq "H"){
	++$res{"$aaTmp","phdH"};}
    else {
	++$res{"$aaTmp","phdL"};}}

$nAll=length($aa);
foreach $aax (@aa20){		# sum
    foreach $des (@des){$res{"sum","$des"}+=$res{"$aax","$des"};}
    foreach $desProp(@desProp){
	if ($aa{"$desProp"}=~/$aax/){
	    foreach $des (@des){$res{"$desProp","$des"}+=$res{"$aax","$des"};}}}}
				# percentages
foreach $des(@des){$res{"per","$des"}=100*$res{"sum","$des"}/$nAll;
		   foreach $desProp(@desProp){
		       $tmp=$res{"sum","$des"};if ($tmp==0){$tmp=1;}
		       $res{"per$desProp","$des"}=100*$res{"$desProp","$des"}/$tmp;}}
				# ------------------------------
                                # write
print "# following classification used:";
foreach $desProp(@desProp){printf "# %-15s   %-s\n",$desProp,$aa{"$desProp"};}
print "# note: percentage for property = percentage of residues observed in that class!\n";
printf "# %-15s   %5d\n","nLoop=",$ctLoop;
printf "# %-15s   %5d  (length=5)\n","nShortLoop5=",$ctShortLoop5;
printf "# %-15s   %5d\n","pShortLoop5=",int(100*($ctShortLoop5/$ctLoop));
printf "# %-15s   %5d  (length=3)\n","nShortLoop3=",$ctShortLoop3;
printf "# %-15s   %5d\n","pShortLoop3=",int(100*($ctShortLoop3/$ctLoop));
printf "# %-15s   %5d  (length=2)\n","nShortLoop2=",$ctShortLoop2;
printf "# %-15s   %5d\n","pShortLoop2=",int(100*($ctShortLoop2/$ctLoop));
    
printf "%-15s\t","aa";foreach $des (@des){printf "%3s\t",$des;}print "\n";
foreach $aax (@aa20){
    printf "%-15s\t",$aax;foreach $des (@des){printf "%3s\t",$res{"$aax","$des"};}print "\n";
}
				# sums
$aax="sum";printf "%-15s\t",$aax;foreach $des (@des){printf "%3s\t",$res{"$aax","$des"};}print "\n";
foreach $desProp(@desProp){
    printf "%-15s\t",$desProp;foreach$des(@des){printf"%3s\t",$res{"$desProp","$des"};}print"\n";
}
				# percentages
$aax="per";printf "%-15s\t",$aax;foreach $des (@des){printf "%3d\t",int($res{"$aax","$des"});}print "\n";
foreach $desProp(@desProp){
    printf "%-15s\t","$desProp"."Per";foreach$des(@des){printf"%3d\t",int($res{"per$desProp","$des"});}print"\n";
}


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
