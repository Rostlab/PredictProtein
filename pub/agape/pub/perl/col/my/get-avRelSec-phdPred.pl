#!/usr/sbin/perl -w
#
#
$[ =1 ;
				# initialise variables
if ($#ARGV<1){print"goal:   compute protein averages over ri (in: tmp.predrel)\n";
	      print"usage:  script tmp.predrel\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut=$fileIn;$fileOut=~s/^.*\///g;$fileOut=~s/\.pred.*//g;$fileOut="GrsecRiAve-".$fileOut;
$Lverb=0;

&open_file("$fhin", "$fileIn");
$#id=0;
while (<$fhin>) {if    (/^\*/){next;}
		 elsif (/^num\s+\d/){next;}
		 $_=~s/\n//g;
		 if    (/^\s+\d+\s+(\w+)/){
		     if ($Lverb){print "--- reading id=$id,\n";}
		     $id=$1;$id=~s/\..*$//g;push(@id,$id);
		     $ri{$id}=$ct{$id}=$q3ok{$id}=$q3n{$id}=0;}
		 elsif (/^Rel/ && (defined $id)){
		     $_=~s/\|//g;$_=~s/Rel//g;$_=~s/\s//g;
		     if ($Lverb){print "--- ri=$_\n";}
		     @tmp=split(//,$_);$ct{$id}+=$#tmp;
		     foreach $tmp(@tmp){
			 if (defined $ri{$id}){
			     $ri{$id}+=$tmp;}else{$ri{$id}=$tmp;}}}
		 elsif (/^DSP/ && (defined $id)){
		     $_=~s/\|//g;$_=~s/DSP//g;$_=~s/ /L/g;$dssp=$_;}
		 elsif (/^PRD/ && (defined $id)){
		     $_=~s/\|//g;$_=~s/PRD//g;$_=~s/ /L/g;$pred=$_;
		     foreach $it(1..length($pred)){ # recompute Q3
			 if (substr($pred,$it,1) eq substr($dssp,$it,1)){
			     ++$q3ok{$id};}
			 ++$q3n{$id};}}
		 else {
		     next;}}close($fhin);

&open_file("$fhout", ">$fileOut");
print $fhout "# Perl-RDB\n";
print $fhout "id\tsumRi\t<ri>\tq3\n";
#print $fhout "10S\t5N\t6.2F\t6.2F\n";
foreach $id (@id){
    if ($ct{$id}>0) {$riAve=$ri{$id}/$ct{$id};}else{$riAve=0;}
    if ($q3n{$id}>0){$q3=100*($q3ok{$id}/$q3n{$id});}else{$q3=0;}
    if ($Lverb){ printf "%-10s\t%5d\t%6.2f\t%6.2f\n",$id,$ri{$id},$riAve,$q3;}
    printf $fhout "%-10s\t%5d\t%6.2f\t%6.2f\n",$id,$ri{$id},$riAve,$q3;
}
close($fhout);
print "--- fileOut=$fileOut\n";
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
