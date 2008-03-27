#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# extracts file with fold libraries (and probs) from FSSP unique\n";
#
$[ =1 ;
				# ------------------------------
				# ini (a.a)
@kwd=           ("exeFsspExtrIde","dirFssp","fileOutList","fileOutRdb","verbose","debug");
@kwdLibProbBody=("pdbId","homosN","prob","homosId");
@kwdLibProbHead=("NCLASS","NPROT","NPAIR");
$fhout="FHOUT";

$par{"exeFsspExtrIde"}=   "/home/rost/perl/scr/fssp_ide_ali.pl";
$par{"argFsspExtrIde"}=   "up=95 zmin=3 ";
$par{"dirFssp"}=          "/data/fssp/";
$par{"fileTopitsAliList"}="/home/rost/pub/topits/mat/Topits_dssp849.list"; # to restrict
$par{"fileOutList"}=      "unk";
$par{"fileOutRdb"}=       "unk";

$par{"verbose"}=          1;
$par{"debug"}=            0;
				# ------------------------------
				# help
if ($#ARGV<1){print"goal:    extracts file with fold libraries (and probs) from FSSP unique\n";
	      print"usage:   'script fssp-unique.list'\n";
	      print"options: \n";
	      foreach $kwd (@kwd){print "         $kwd='x' (def: ",$par{"$kwd"},")\n";}
	      exit;}
				# ------------------------------
$fileIn=$ARGV[1]; shift @ARGV;	# digest command line
foreach $arg (@ARGV){ 
    $Lok=0;
    foreach $kwd (@kwd){
	if ($arg=~/^$kwd=/){$arg=~s/^.*=//g;$arg=~s/\s//g;
			    $par{"$kwd"}=$arg;$Lok=1;
			    last;}}
    if (!$Lok){print"*** unrecognised argument '$arg'\n";
	       exit;}}
foreach $des ("fileOutList","fileOutRdb"){ # change output file names
    if ($par{"$des"} eq "unk"){$par{"$des"}=$fileIn;$par{"$des"}=~s/dssp/fsspPairs/;
			       if ($par{"$des"} eq $fileIn){$par{"$des"}="XX-".$par{"$des"};}}
    if ($des eq "fileOutRdb") {$par{"$des"}=~s/\.list/\.rdb/;}}
				# ------------------------------
$#fileTmp=0;			# temporary files
$fileTmpOrphans="Orphans-fssp".$$.".tmp";
$fileTmpIdpairs="Idpairs-fssp".$$.".tmp";
$fileTmpOut=    "Out-fssp".$$.".tmp";

				# ------------------------------
				# extract information from FSSP
$arg= $par{"exeFsspExtrIde"}." $fileIn ".$par{"argFsspExtrIde"}.
    " file=".$par{"fileTopitsAliList"}.
    " fileOut=$fileTmpOut fileOutIdpairs=$fileTmpIdpairs fileOutOrphans=$fileTmpOrphans";

print "--- system \t '$arg'\n";
system ("$arg");		# call fssp_ide_ali.pl

foreach $file ("$fileTmpOut","$fileTmpIdpairs","$fileTmpOrphans"){ # temporary
    if (-e $file){ push(@fileTmp,$file);}}
				# ------------------------------
				# read ids from lists
@rd=
    &getIds($fileTmpIdpairs,$fileTmpOrphans);
				# ------------------------------
				# write list
$fileOut=$par{"fileOutList"};
$Lok=       &open_file("$fhout",">$fileOut");
if (! $Lok){print "*** ERROR fssp_extr_foldLibProb.pl: fileOut=$fileOut, not opened\n";
	    die;}
foreach $rd(@rd){print $fhout "$rd\n";}close($fhout);
				# ------------------------------
				# write RDB
$Lok= 
    &getFsspPairList($fileOut,$par{"fileOutRdb"});
				# ------------------------------
                                # consistency check
$tmpHead="";foreach $tmp(@kwdLibProbHead){$tmpHead.="$tmp,";}
$tmpBody="";foreach $tmp(@kwdLibProbBody){$tmpBody.="$tmp,";}
%lib=
    &getFsspLibProb($par{"fileOutRdb"},$tmpHead,$tmpBody);

@tmp=split(/,/,$lib{"all"});
print "xx consistency check (all pairs):\n";
$ct=0;
foreach $tmp (@tmp){
    ++$ct;
    printf "xx %4d %-6s %5d %6.4f %-s\n",
    $ct,$tmp,$lib{"homosN","$tmp"},$lib{"prob","$tmp"},$lib{"homosId","$tmp"},",\n";
}
print "xx number of pairs=$#tmp,\n";

if (! $par{"debug"}){
    foreach $file (@fileTmp){ unlink $file;}}

print "--- output in files: ";
foreach $des ("fileOutList","fileOutRdb"){ print $par{"$des"},",";}print"\n";
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
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhinLoc","$fileInLoc");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in","$it"}=$tmp[$it];
	    $rdrdb{"$des_in","$it"}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#==============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;
		    $READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
#===============================================================================
sub getFsspPairList {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$sepLoc,$tmp,$Lok,$tmpId,$tmpMatchList,$id,
	  @idClass,@idTot,@tmp,%Lok,%rd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFsspPairList             reads file written by fssp_ide_ali.pl
#       in:                     file with: 'idGuide  id1,id2,...'
#                                      or: 'idGuide  none'
#       out:                    RDB file ($fileOut):
#                                    'idGuide  prob(=Nhomos/N_folds_in_library)  idList'
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getFsspPairList";$fhinLoc="FHIN"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
    $sepLoc="\t";		# for RDB file: separation of columns by sepLoc

    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
				# ------------------------------
    $ctHomo=$#idClass=$#idTot=0;	# read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (length($_)==0){
	    next;}
	$_=~s/_//g;		# delete HSSP chain identifier _
	@tmp=split(/\t/,$_); # split 'idGuide  id1,id2,..'
	foreach $tmp (@tmp){$tmp=~s/\s//g;}	# purge blanks

	if (! defined $Lok{"$tmp[1]"}){	# collect unique list
	    push(@idTot,$tmp[1]); $Lok{"$tmp[1]"}=1; }
	push(@idClass,$tmp[1]);
	$tmpId=$tmp[1]; $tmpMatchList=$tmp[2]; $tmpMatchList=~s/^,*|,*$//g;
	$rd{"id","$tmpId"}=$tmpMatchList;
	@idHomo=split(/,/,$tmpMatchList);
	$ctHomo+=($#idHomo);
	foreach $idHomo(@idHomo){$idHomo=~s/\s//g;} # split list of homologues
	$rd{"n","$tmpId"}=$#idHomo;
	if ($tmpMatchList eq "none"){
	    next;}
	foreach $idMatch(@idHomo){
	    if (! defined $Lok{"$idMatch"}){
		push(@idTot,$idMatch); $Lok{"$idMatch"}=1; }}}close($fhinLoc);

				# ------------------------------
				# write new file
    $Lok=&open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    print $fhoutLoc "# Perl-RDB\n","# \n","# FSSP pairs and counts\n","# \n",;
    printf $fhoutLoc "# %-20s : %6d (number of fold classes)\n","NCLASS",$#idClass;
    printf $fhoutLoc "# %-20s : %6d (number of unique chains in library)\n","NPROT",$#idTot;
    printf $fhoutLoc "# %-20s : %6d (number of pairs in library)\n","NPAIR",$ctHomo;
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION PDBid","PDB (4 char) + chain (1 char) identifier";
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION homosN","number of homologues for given class";
    printf $fhoutLoc 
	"# %-20s : %-s\n","NOTATION prob","=nHomo/NPAIR, i.e. chance of hitting on family";
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION homosId","PDB + chain identifiers of homologues";
				# names and formats
    printf $fhoutLoc "%-15s$sepLoc%6s$sepLoc%10s$sepLoc%s\n","pdbId","homosN","prob","homosId";
    printf $fhoutLoc "%-15s$sepLoc%6s$sepLoc%10s$sepLoc%s\n","15","6N","10.8F"," ";
    foreach $id (@idClass){
	printf 
	    "%-15s$sepLoc%6d$sepLoc%10.8f$sepLoc%-s\n",
	    $id,$rd{"n","$id"},($rd{"n","$id"}/$ctHomo),$rd{"id","$id"}; 
	printf $fhoutLoc 
	    "%-15s$sepLoc%6d$sepLoc%10.8f$sepLoc%-s\n",
	    $id,$rd{"n","$id"},($rd{"n","$id"}/$ctHomo),$rd{"id","$id"}; }
    close($fhoutLoc);
    return(1);
}				# end of getFsspPairList

#===============================================================================
sub getFsspLibProb {
    local($fileInLoc2,$tmpHeadLoc,$tmpBodyLoc) = @_ ;
    local($sbrName,$fhinLoc2,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFsspLibProb              reads the file with the fold families
#       in:                     file
#       out:                    $rd{"all"}                -> idGuide1,idGuid2,...
#                               $rd{"nclass"}             -> number of folds read
#                               $rd{"nprot"}              -> number of proteins in library
#                               $rd{"npair"}              -> number of pairs
#                               $rd{"homosId","$idGuide"} -> matching familiy for idGuide
#                               $rd{"nHhomos","$idGuide"} -> number of homologues
#                               $rd{"prob","$idGuide"}    -> probability of random hit for idGuide
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getFsspLibProb";$fhinLoc2="FHIN"."$sbrName";
    $tmpHeadLoc=~s/^,|,$//;@tmpHeadLoc=split(/,/,$tmpHeadLoc);
    $tmpBodyLoc=~s/^,|,$//;@tmpBodyLoc=split(/,/,$tmpBodyLoc);
				# read RDB file
				#    keywords should be 'pdbId,prob,homosId'
    %rdLoc=
	&rdRdbAssociative($fileInLoc2,"head",@tmpHeadLoc,"body",@tmpBodyLoc);
				# convert
    $rd{"all"}="";$#idAll=0;
    foreach $it (1..$rdLoc{"NROWS"}){
	foreach $kwd (@tmpBodyLoc){	# purge blanks
	    if (!defined $rdLoc{"$kwd","$it"}){
		print "-*- WARNING $sbrName rdLoc it=$it, kwd=$kwd, not defined\n";}
	    else { $rdLoc{"$kwd","$it"}=~s/\s//g;}}
	$id=$rdLoc{"pdbId","$it"};
	push(@idAll,$id);$rd{"all"}.="$id,";
	foreach $kwd (@tmpBodyLoc){
	    $rd{"$kwd","$id"}=$rdLoc{"$kwd","$it"};}}
    return(%rd);
}				# end of getFsspLibProb

#===============================================================================
sub getIds {
    local($fileInLoc1,$fileInLoc2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getIds                      reads ids from the files written by fssp_ide_ali.pl
#      in (file formats):
#                               file 1: idpairs
#                                   1ak2    2ak3_B,2ak3_A,
#                                   2ak3A   1ak2,
#                               file 2: orphans
#                                   /data/fssp/1aep.fssp
#                                   /data/fssp/1aep.fssp
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getIds";$fhinLoc="FHIN"."$sbrName";
				# read idpairs
    $Lok=       &open_file("$fhinLoc","$fileInLoc1");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc1' not opened\n";
		return(0);}
    $ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;$_=~s/,$//g;
			if (length($_)==0){
			    next;}++$ct;
			$rd{"pair","$ct"}="$_";}close($fhinLoc);$rd{"pair","NROWS"}=$ct;
				# read orphans
    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
		return(0);}
    $ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;$_=~s/^.*\///g;$_=~s/\.fssp//g;
			if (length($_)==0){
			    next;}++$ct;
			$rd{"orph","$ct"}="$_\tnone";}close($fhinLoc);$rd{"orph","NROWS"}=$ct;
				# ------------------------------
				# sort
    $#tmp=0;			# 1pdb -> pdb
    foreach $des ("pair","orph"){
	foreach $it(1..$rd{"$des","NROWS"}){
	    ($tmp1,$tmp)=split(/\s+/,$rd{"$des","$it"});
	    $id=substr($tmp1,2);
	    $ptr{"$id"}="$des,$it";
	    push(@tmp,$id);}}
    @tmpSort=sort (@tmp);
    foreach $id (@tmpSort){
	($des1,$des2)=split(/,/,$ptr{"$id"});
	push(@tmpFin,$rd{"$des1","$des2"});
    }
    return(@tmpFin);
}				# end of getIds

