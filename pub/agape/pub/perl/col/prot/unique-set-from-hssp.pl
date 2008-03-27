#!/usr/sbin/perl -w
#
#  constructs set with < n% pairwise ide from HSSP headers /PDB files!
#
$[ =1 ;
$ideMax=80;
$lenMin=80;
				# help
if ($#ARGV<1){
    print "goal:    constructs set with < n% pairwise ide from HSSP headers /PDB files!\n";
    print "note:    currently a hack, chains ignored\n\n";
    print "usage:   script list-of-headers \n";
    print "options: take=file    (file with ids to be included)\n";
    print "         fileOut=x\n";
    print "         ide=x (def=$ideMax, max ide)\n";
    print "         len=x (def=$lenMin , min length, or half the protein for short ones)\n";
    print "         \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$fileOut="Missing-".$fileIn;

foreach $_(@ARGV){
    next if ($_ eq $fileIn);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^ide=(.*)$/)    {$ideMax=$1;}
    elsif($_=~/^len=(.*)$/)    {$lenMin=$1;}
    elsif($_=~/^take=(.*)$/)   {$fileTake=$1; 
				if (!-e $fileTake){print "*** file take '$fileTake' missing\n";
						   die;}}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
				# ------------------------------
				# now read the list of HSSP files
&open_file("$fhin", "$fileIn");
&open_file("$fhout", ">$fileOut");
$#file=$#id=$ct=0; undef %ptrId;	
while (<$fhin>) {$_=~s/\n|\s//g;
		 $_=~s/(hssp)[_!]*[A-Z0-9]/$1/;
		 if (! -e $_){
		     print "-*- missing '$_'\n";
		     print $fhout "$_\n";
		     next;}
		 ++$ct;$id=$_;$id=~s/^.*\///g;$id=~s/[_!]//g;$id=~s/\.hssp.*$//g;
		 push(@file,$_);push(@id,$id);$ptrId{$id}=$ct;}close($fhin);
close($fhout);
				# ------------------------------
				# open file take (highest priority)
				# i.e. all in here taken anyway
$#take=0;undef %take;
if (defined $fileTake){
    &open_file("$fhin", "$fileTake");
    while (<$fhin>) {$_=~s/\n|\s//g;$_=~s/^.*\///g;$_=~s/[_!]//g;
		     $id=$_;$id2=substr($_,1,4); # 2nd : no chain
		     if (!defined $ptrId{$id2}){
			 print "*** missing $id2\n";
			 exit;}
		     push(@take,$id2);$take{$id2}=1;}close($fhin);}
				# ------------------------------
foreach $it(1..$#file){		# read all hssp files
    $file=$file[$it];
    printf "--- read file %5d %-s : ",$it,$file;
    &open_file("$fhin", "$file");
    while (<$fhin>) {last if ($_=~/^  NR\./);
		     if   ($_=~/^SEQLENGTH\s+(\d+)/)  {$len1=$1;}}
    $ct=0;$pair[$it]="";undef (%tmp);
    while (<$fhin>) {last if (/^\#\#/);
				# not if no PDBID
		     next if (substr($_,21,4) !~ /[A-Z0-9]+/); 
		     $ide=substr($_,29,4);$ide=~s/\s//g;$ide=100*$ide;
				# ignore if too distant
		     next if ($ide<$ideMax);
		     $lali=substr($_,60,5);$lali=~s/\s//g;
				# ignore if too short
		     next if (($lali<$lenMin)&&(($lali<($len1/2))));
		     $id2=substr($_,21,4);$id2=~s/\s//g;$id2=~tr/[A-Z]/[a-z]/;
				# not if id not in list of all files to read
		     next if ((defined $tmp{$id2})|| (! defined $ptrId{$id2}));
		     $tmp{$id2}=1; ++$ct;	# count all taken
		     $pair[$it].=$ptrId{$id2}.","; # store numbers, not ids less memory
		 }close($fhin);
    $pair[$it]=~s/,$//;$pairN[$it]=$ct;
    printf " n=%3d : %-s\n",$pairN[$it], $pair[$it];
}

$#file=0;			# clean up
	
				# ------------------------------
foreach $id (@take){		# (1) go through those with priority
    $ptr=$ptrId{$id};
    @tmp=split(/,/,$pair[$ptr]);
    foreach $id2(@tmp){
	if (! defined $take{$id2}){ # if not already flaged to be taken
	    $take{$id2}=0;}}}
				# ------------------------------
$#occ=0;			# (2) link number to id
foreach $it (1..$#id){$num=$pairN[$it];
		      if (! defined $occ[$num]){
			  $occ[$num]="$it,";}
		      else {
			  $occ[$num].="$it,";}}
				# ------------------------------
				# (3) according to population, 
				# start with protein with most pairs (that one will be taken!)
@sort=sort bynumber_high2low (@pairN);
undef %tmp;$#tmp=0;
foreach $sort(@sort){		# reduce to non-redundant
    if (! defined $tmp{$sort}){
	push(@tmp,$sort);$tmp{$sort}=1;}}
@sort=@tmp;
$#num=0;
foreach $num(@sort){
    next if (defined $num[$num]); # avoid counting twice
    $num[$num]=1;
    $occ[$num]=~s/,$//g;
    print "xx scanning all with N=$num pairs (occ=$occ[$num])\n";
    @tmp=split(/,/,$occ[$num]);	# all files with N pairs found
				# --------------------
    foreach $it (@tmp){		# all with N pairs
	$take{$id[$it]}=1 if (! defined $take{$id[$it]});
	next if (! $take{$id[$it]}); # skip if to be excluded
	print "it=$it, id=$id[$it], pairs=$pair[$it]\n";
	$take{$id[$it]}=1;	# take the guide sequence
	next if ($num==0);
				# loop over all ids for that
	@id2=split(/,/,$pair[$it]);
	foreach $id2Num(@id2){
	    $id2=$id[$id2Num];
	    print "xx id2=$id2,\n";
	    next if (defined $take{$id2}); # if not already flagged to be taken
	    print "xx will be flagged\n";
	    $take{$id2}=0;}}}
				# ------------------------------
				# harvest
$tmp=$fileIn;$tmp=~s/^.*\///g;
$fileNot="Unique-not-".$tmp;
$fileOk= "Unique-ok-".$tmp;

$sep="\n";
&open_file("$fhout",">$fileOk"); 
$ok=0;
foreach $id(@id){
    if ($take{$id}){++$ok;
		    print $fhout "$id","$sep";}}
close($fhout);
&open_file("$fhout",">$fileNot"); 
$not=0;
foreach $id(@id){
    if (! $take{$id}){++$not;
		      print $fhout "$id","$sep";}}
close($fhout);

printf "--- all files %5d\n",$#id;
printf "--- not taken %5d\n",$not;
printf "---     taken %5d\n",$ok;

print "--- output in $fileOk, $fileNot, missing files in $fileOut\n";
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

