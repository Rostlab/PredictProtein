#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="splits fastaMul into many FASTA files\n".
    "*** \n".
    "*** WATCH IT use fastaSplitDb.pl for splitting entire databases!!!!!\n".
    "*** \n";

#  
#

$[ =1 ;
				# ------------------------------
				# defaults
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName fastaMul'\n";
    print  "               keyword 'list' to digest lists (or extension .list) !!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","list",   "no value","";
#    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$LisList=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif ($arg=~/^list$/)                { $LisList=1;}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ($LisList || $fileIn=~/list$/){
	&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {$_=~s/\n//g;
			 push(@fileTmp,$_); }
	close($fhin); }
    else {
	push(@fileTmp,$fileIn);} }

@fileIn= @fileTmp; 


$#fileOut=0;
				# ------------------------------
				# (1) read file(s)
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";

				# id='id1\nid2'
    ($Lok,$id,$seq)=
	&fastaRdMul($fileIn,0);
    if (! $Lok){ print "*** failed on $fileIn msg=\n","$id\n";
		 exit; }
    $id=~s/^\n*|\n*$//g;   $seq=~s/^\n*|\n*$//g;
    @id=split(/\n/,$id);   @seq=split(/\n/,$seq);
    if ($#id !~ $#seq) { 
	print "*** ERROR from fastRdMul ".$#id." ids read, but ".$#seq." sequences!\n";
	exit;}
				# ------------------------------
				# (3) write output
				# ------------------------------
    foreach $it (1..$#id){
	$id=$id[$it]; 

#	$id=~s/\s.*$//g;
				# for celegans
	$id=~s/^\s*(\S+)\s+(\S+).*$/$2/g;
	$fileOut=$id.".f";
	$id1=$id[$it]; $id1=~s/\(//g;
	$id=$id." ($id1)";
	
	&open_file("$fhout",">$fileOut"); 
	print $fhout "> $id\n";
	for ($mue=1; $mue<=length($seq[$it]); $mue+=50) {
	    print $fhout substr($seq[$it],$mue,50),"\n"; }
	close($fhout);
	push(@fileOut,$fileOut) if (-e $fileOut);
    }
}

print "--- output in:",join(',',@fileOut,"\n");

exit;


#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub fastaRdMul {
    local($fileInLoc,$rd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdMul                  reads many sequences in FASTA db
#       in:                     $fileInLoc,$rd with:
#                               $rd = '1,5,6',   i.e. list of numbers to read
#                               $rd = 'id1,id2', i.e. list of ids to read
#                               NOTE: numbers faster!!!
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    undef %tmp;
    if (! defined $rd) {
	$LisNumber=1;
	$rd=0;}
    elsif ($rd !~ /[^0-9\,]/){ 
	@tmp=split(/,/,$rd); 
	$LisNumber=1;
	foreach $tmp(@tmp){$tmp{$tmp}=1;}}
    else {$LisNumber=0;
	  @tmp=split(/,/,$rd); }
    
    $ct=$ctRd=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){ # line with id
	    ++$ct;$Lread=0;
	    last if ($rd && $ctRd==$#tmp); # fin if all found
	    next if ($rd && $LisNumber && ! defined $tmp{$ct});
	    $id=$1;
	    $id=~s/^\s*|\s*$//g; # purge leading blanks
	    $id=~s/\s\s*/ /g;	# purge double blank
	    $idLong=$id;
	    $id=~s/^\S*\|//g;	# purge anything before short id (trembl|acc|id)
	    $id=~s/\s.*$//g;	# purge anything after blank

	    $Lread=1 if ( ($LisNumber && defined $tmp{$ct})
			 || $rd == 0);

	    if (! $Lread){	# go through all ids
		foreach $tmp(@tmp){
		    next if ($tmp !~/$id/);
		    $Lread=1;	# does match, so take
		    last;}}
	    next if (! $Lread);

	    ++$ctRd;
	    $tmp{$ctRd,"id"}= $id;
	    $tmp{$ctRd,"des"}=$idLong;
	    $tmp{$ctRd,"seq"}="";}
	elsif ($Lread) {	# line with sequence
	    $tmp{$ctRd,"seq"}.="$_";}}

    $seq=$id="";		# join to long strings
    foreach $it (1..$ctRd) { $id.= $tmp{$it,"id"}."\n";
			     $tmp{$it,"seq"}=~s/\s//g;
			     $seq.=$tmp{$it,"seq"}."\n";}
    $#tmp=0;			# save memory
    undef %tmp;			# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdMul

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
# library collected (end)
#==============================================================================


1;
