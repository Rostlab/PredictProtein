#!/usr/sbin/perl -w
#
#  reads output from hssp_extr_seqSec.pl, compiles statistics
#
$[ =1 ;

				# initialise variables
if ($#ARGV<1){print"goal:   reads output from hssp_extr_seqSec.pl, compiles statistics\n";
	      print"usage:  script file\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");
$seq=$sec="";
while (<$fhin>) {
    next if (/\s+LEN\s+\d+|\.\.,\.\./);
    $_=~s/\n//g;$_=~s/!//g;
    if    (/\s+SEQ\s([A-Z]*)/){
	print "seq=$1\n";
	$seq.="$1";}
    elsif (/\s+SEC\s([S TEGHBL]*)/){
	print "sec=$1\n";
	$sec.="$1";}
    else {
	print "*** ERROR '$_' unexpected line\n";die;}
}close($fhin);
				# filter sec str
$sec=~s/S/ /g;$sec=~s/G/H/g;$sec=~s/B/E/g;$sec=~s/ /L/g;
$seq=~s/[a-z]/C/g;

$nall=length($sec);
foreach $ss ("T","L","H","E"){
    $tmp=$sec;$tmp=~s/[^$ss]//g;
    $nss{"$ss"}=length($tmp);}

foreach $aa ("R","K","H","D","E"){
    $tmp=$seq;$tmp=~s/[^$aa]//g;$naa{"$aa"}=length($tmp);}
$tmp2=0;foreach $aa ("R","K"){
    $tmp=$seq;$tmp=~s/[^$aa]//g;$tmp2+=length($tmp);}$naa{"+"}=$tmp2;
$tmp2=0;foreach $aa ("E","D"){
    $tmp=$seq;$tmp=~s/[^$aa]//g;$tmp2+=length($tmp);}$naa{"-"}=$tmp2;

%ncom=0;
foreach $it (1..length($seq)){
    $seq1=substr($seq,$it,1);$sec1=substr($sec,$it,1);
    next if ((!defined $seq1)||(!defined $seq1));
    foreach $ss ("T","L","H","E"){
	foreach $aa ("R","K","H","D","E"){
	    if (($sec1 eq "$ss")&&($seq1 eq "$aa")){
		++$ncom{"$ss","$aa"};}}}}
foreach $ss ("T","L","H","E"){
    $tmp=0;
    foreach $aa ("R","K"){$tmp+=$ncom{"$ss","$aa"};}
    $ncom{"$ss","+"}=$tmp;
    $tmp=0;
    foreach $aa ("D","E"){$tmp+=$ncom{"$ss","$aa"};}
    $ncom{"$ss","-"}=$tmp;}
				# write
$sep=" ";
&wrt("STDOUT",$sep);

&open_file("$fhout",">$fileOut"); 
&wrt($fhout,$sep);
close($fhout);

print "--- output in $fileOut\n";
exit;

# ================================================================================
sub wrt{
    local($fhLoc,$sepLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
    printf $fhLoc 
	"des  $sepLoc%2s$sepLoc%8s$sepLoc%6s$sepLoc%6s$sepLoc%6s$sepLoc%8s\n",
	"Type","Nocc","%all","%res","%str","info";
    printf $fhLoc "Nres $sepLoc%2s$sepLoc%8d\n"," ",$nall;
    foreach $aa ("R","K","H","D","E","+","-"){
	next if (! defined $naa{"$aa"});
	if ($aa eq "+"){printf $fhLoc " \n";}
	printf $fhLoc 
	    "res  $sepLoc%2s$sepLoc%8d$sepLoc%6.2f\n",
	    $aa,$naa{"$aa"},100*($naa{"$aa"}/$nall);}
    printf $fhLoc " \n";
    foreach $ss ("T","L","H","E"){
	next if (! defined $nss{"$ss"});
	printf $fhLoc 
	    "str  $sepLoc%2s$sepLoc%8d$sepLoc%6.2f\n",
	    $ss,$nss{"$ss"},100*($nss{"$ss"}/$nall);}
    printf $fhLoc " \n";
    
    foreach $ss ("T","L","H","E"){
	foreach $aa ("+","-"){
	    next if (! defined $ncom{"$ss","$aa"});
	    &wrtLine($fhLoc,$sepLoc,$aa,$ss);}}
    printf $fhLoc " \n";
    foreach $ss ("T","L","H","E"){
	foreach $aa ("R","K","H","D","E"){
	    next if (! defined $ncom{"$ss","$aa"});
	    &wrtLine($fhLoc,$sepLoc,$aa,$ss);}}
}

# ================================================================================
sub wrtLine{
    local($fhLoc2,$sepLoc2,$aa2,$ss2) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
    printf $fhLoc2 
	"aa/ss$sepLoc2%2s$sepLoc2%8d$sepLoc2%6.2f$sepLoc2%6.2f$sepLoc2%6.2f$sepLoc2%8.4f\n",
	$aa2.$ss2,$ncom{"$ss2","$aa2"},100*($ncom{"$ss2","$aa2"}/$nall),
	100*($ncom{"$ss2","$aa2"}/$naa{"$aa2"}),100*($ncom{"$ss2","$aa2"}/$nss{"$ss2"}),
	($ncom{"$ss2","$aa2"}/$nall)*
	    log(($ncom{"$ss2","$aa2"}/$nall)/($nss{"$ss2"}*$naa{"$aa2"}/$nall*$nall));
}


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

