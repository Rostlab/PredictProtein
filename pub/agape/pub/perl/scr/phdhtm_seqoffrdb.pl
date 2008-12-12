#!/usr/bin/perl -w
##!/usr/sbin/perl -w
##!/usr/pub/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="removes the column seq from file bs-htm07.rdb (generated by phdHtm-rdb2table.pl)\n".
    "     \t ";
#  
#
$[ =1 ;
				# defaults
$LwrtSeq=0;			# writes sequences into long FASTA format

if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName bs*rdb' (i.e. list of files)\n";
    print "opt: \t \n";
#    print "     \t titleOut=x\n";
    print "     \t fileOut=x\n";
    print "     \t wrtSeq      (will write sequences into long FASTA format)\n";
    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];$#fileIn=0;push(@fileIn,$fileIn);
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/) {$fileOut=$1;}
#    elsif($_=~/^titleOut=(.*)$/){$titleOut=$1;}
    elsif($_=~/^wrtSeq/)        {$LwrtSeq=1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    elsif(-e $_)                {push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

die ("missing input $fileIn\n") if (! -e $fileIn);

				# ------------------------------
				# (1) read files
foreach $fileIn(@fileIn){
    $fileOut=$fileIn;$fileOut=~s/^.*\///g;$fileOut=~s/-htm/Tab/;$fileOut=~s/\.rdb/\.dat/;
    print "--- reading $fileIn (out $fileOut)\n";
    if ($LwrtSeq){$#id=0;undef %seq;}
    &open_file("$fhin", "$fileIn");
    &open_file("$fhout",">$fileOut"); 
    while (<$fhin>) {$_=~s/\n//g;
		     if ($_=~/^\#|^num/){print $fhout $_,"\n";
					 next;}
		     @tmp=split(/\t/,$_);
		     $id= $tmp[2];    $id=~s/\s//g;
		     if ($LwrtSeq){$seq=$tmp[$#tmp];$seq=~s/\s//g;
				   $seq{$id}=$seq;push(@id,$id);}
		     print $fhout $tmp[2];
		     foreach $it (3..($#tmp-1)){print $fhout "\t",$tmp[$it];}
		     print $fhout "\n";}close($fhin);close($fhout);
    if ($LwrtSeq){
	$fileOut=~s/Tab/Seq/;
	print "--- write sequence into $fileOut\n";
	&open_file("$fhout",">$fileOut"); 
        @sortId=sort (@id);
        foreach $id (@sortId){
            print $fhout "> GENOME|$id\n";
            for ($it=1;$it<=length($seq{$id});$it+=50){
                print $fhout substr($seq{$id},$it,50),"\n";}}
	close($fhout);
	$#sortId=$#id=0;}
}

print "--- output in $fileOut\n";
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