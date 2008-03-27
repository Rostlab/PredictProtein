#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# extracts file with fold libraries (and probs) from TOPITS aliList\n";
#
$[ =1 ;
				# ------------------------------
				# ini (a.a)
@kwd=           ("exeFsspExtrIde","dirFssp","fileOutList","fileOutRdb","verbose","debug");
@kwdFsspLibProb=("pdbId","prob","homosId");
$fhout="FHOUT";

$par{"exeFsspExtrIde"}="/home/rost/perl/scr/fssp_ide_ali.pl";
$par{"argFsspExtrIde"}="up=95 zmin=3 ";
$par{"dirFssp"}=       "/data/fssp/";

$par{"fileOutList"}=   "unk";
$par{"fileOutRdb"}=    "unk";

$par{"verbose"}=       1;
$par{"debug"}=         0;
				# ------------------------------
				# help
if ($#ARGV<1){print"goal:    extracts file with fold libraries (and probs) from TOPITS aliList\n";
	      print"usage:   'script aliList'\n";
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
$fileTmpFsspList="List-fssp".$$.".tmp";$fileOutError="Error-missing-fssp".$$.".tmp";
$fileTmpOrphans="Orphans-fssp".$$.".tmp";
$fileTmpIdpairs="Idpairs-fssp".$$.".tmp";
$fileTmpOut=    "Out-fssp".$$.".tmp";

				# ------------------------------
				# convert TOPITS aliList to FSSP
$Lok= &convDsspList2FsspList($fileIn,$fileTmpFsspList,$fileOutError,
			     $fileTmpFsspList,$par{"dirFssp"});

push(@fileTmp,$fileTmpFsspList); # temporary
				# ------------------------------
				# extract information from FSSP
$arg= $par{"exeFsspExtrIde"}." $fileTmpFsspList ".$par{"argFsspExtrIde"}." file=".$fileIn;
$arg.=" fileOut=$fileTmpOut fileOutIdpairs=$fileTmpIdpairs fileOutOrphans=$fileTmpOrphans";

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
%lib=
    &getFsspLibProb($par{"fileOutRdb"},@kwdFsspLibProb);

@tmp=split(/,/,$lib{"all"});
print "xx consistency check (all pairs):\n";
foreach $tmp (@tmp){
    print "xx $tmp, p=",$lib{"prob","$tmp"},", homos=",$lib{"homosId","$tmp"},",\n";}

if (! $par{"debug"}){
    foreach $file (@fileTmp){ unlink $file;}}

print "--- output in files: ";
foreach $des ("fileOutList","fileOutRdb"){ print $par{"$des"},",";}print"\n";
exit;




#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir


#==============================================================================
sub fsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileFssp,$dir,$tmp,$chain,@dir2,$idLoc,$fileHssp,$chainHssp,$it,@chainHssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspGetFile                 searches all directories for existing FSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($fssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.fssp not found -> try 1prc.fssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;$chain="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir =~ /\/data\/fssp/) { $Lok=1;}
	push(@dir2,$dir);}
    @dir=@dir2;  if (!$Lok){push(@dir,"/data/fssp/");} # give default
    
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $title=$fileInLoc;$title=~s/^.*\/|\.fssp.*$//g;
    $fsspFileTmp=$fileInLoc;$fsspFileTmp=~s/\s|\n//g;
				# loop over all directories
    $fileFssp=&fsspGetFileLoop($fsspFileTmp,$Lscreen,@dir);

    if ( ! -e $fileFssp ) {	# still not: cut non [A-Za-z0-9]
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.fssp.*)$/$1$2/g;
	$fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileFssp ) {	# still not: assume = chain
	$tmp1=substr($fileInLoc,1,4);$chain=substr($fileInLoc,5,1);
	$tmp_file=$fileInLoc; $tmp_file=~s/^($tmp1).*(\.fssp.*)$/$1$2/;
	$fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileFssp ) {	# still not: version up
	$tmp1=substr($idLoc,2,3);
	foreach $it(1..9){$tmp_file="$it"."$tmp1".".fssp";
			  $fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
				# still not: try to add chain
    if ( (! -e $fileFssp) && (length($title)==4) ) {
	$fileHssp=$fileInLoc;$fileHssp=~s/\.fssp/\.hssp/;$fileHssp=~s/^.*\///g;
	$fileHssp= &hsspGetFile($fileHssp,0);
	$chainHssp=&hsspGetChain($fileHssp);$#chainHssp=0;
	if ($chainHssp ne " "){
	    foreach $it(1..length($chainHssp)){push(@chainHssp,substr($chainHssp,$it,1));}
	    foreach $chainHssp(@chainHssp){
		$tmp=$fileInLoc; $tmp=~s/\.fssp/$chainHssp\.fssp/;
		$fileFssp=&fsspGetFileLoop($tmp,$Lscreen,@dir); 
		last if (-e $fileFssp);}}}

    if ( ! -e $fileFssp) { return(0);}
    if (length($chain)>0) { return($fileFssp,$chain);}
    else                  { return($fileFssp);}
}				# end of fsspGetFile

#==============================================================================
sub fsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
    $fileOutLoop="unk";
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$fileInLoop"; # try directory
	if ($Lscreen)           { print "--- fsspGetFileLoop: \t trying '$tmp'\n";}
	if (-e $tmp) { $fileOutLoop=$tmp;
		       last;}
	if ($tmp!~/\.fssp/) {	# missing extension?
	    $tmp.=".fssp";
	    if ($Lscreen)       { print "--- fsspGetFileLoop: \t trying '$tmp'\n";}
	    if (-e $tmp) { $fileOutLoop=$tmp;
			   last;}}}
    $fileOutLoop=~s/\s|\n//g;	# security..
    return($fileOutLoop);
}				# end of fsspGetFileLoop

#==============================================================================
sub hsspGetChain {
    local ($fileIn) = @_ ;
    local ($fhin,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChain                extracts all chain identifiers in HSSP file
#       in:                     $file
#       out:                    $chains (ABC) ,%rdLoc
#                      no chain -> $chains=' '
#       out                        $rdLoc{"NROWS"},$rdLoc{"$ct","chain"},
#       out                        $rdLoc{"$ct","ifir"},$rdLoc{"$ct","ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    return(0,"no file") if (! -e $fileIn);
    &open_file("$fhin","$fileIn");
    while(<$fhin>){		# until start of data
	last if ($_=~/^ SeqNo/);}
    $chainLoc=$posLoc="";
    while(<$fhin>){
	if ($_=~/^\#/ && (length($chainLoc)>1) ) {
	    $posLoc.="$ifirLoc-$ilasLoc".",";
	    last;}
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	next if ($aaRd eq "!") ;  # skip over chain break
	if ($chainLoc !~/$chainRd/){	# new chain?
	    $posLoc.=         "$ifirLoc-$ilasLoc"."," if (length($chainLoc)>1);
	    $chainLoc.=       "$chainRd".",";
	    $ifirLoc=$ilasLoc=$posRd;}
	else { 
	    $ilasLoc=$posRd;}
    }close($fhin);
    $chainLoc=~s/^,|,$//g;
    $posLoc=~s/\s//g;$posLoc=~s/^,|,$//g; # purge leading ','
				# now split chains read
    undef %rdLoc; 
    $ctLoc=0;
    @cLoc=split(/,/,$chainLoc);
    @pLoc=split(/,/,$posLoc);

    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	next if ($tmp2 == $tmp1); # exclude chains of length 1
	++$ctLoc;
	$rdLoc{"NROWS"}=         $ctLoc;
	$rdLoc{"$ctLoc","chain"}=$cLoc[$itLoc];
	$rdLoc{"$ctLoc","ifir"}= $tmp1;
	$rdLoc{"$ctLoc","ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

#==============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#                               kwd  = noSearch -> no DB search
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#==============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

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
sub convDsspList2FsspList {
    local($fileInLoc,$fileOutLoc,$fileOutNotLoc,$dirFsspLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convDsspList2FsspList       reads in a list of dssp files (from Topits aliList)
#                               and returns list of fssp files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."convDsspList2FsspList";
    $fhinLoc="FHIN"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";$fhoutNotLoc="FHOUT_NOT"."$sbrName";
    $LscreenLoc2=0;

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutLoc' not opened\n";
		return(0);}
    $Lok=       &open_file("$fhoutNotLoc",">$fileOutNotLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutNotLoc' not opened\n";
		return(0);}

    while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			if (length($_)==0){
			    next;}
			$_=~s/^.*\///g;	# purge before dir
			$_=~s/dssp|hssp//g; $_=~s/[_!\.]//g;
			if (length($_)<4){
			    print "xx strange=$_, rd=$tmp,\n";
			    next;}
			$id=$_;
			$fssp=&fsspGetFile($id,$LscreenLoc2,$dirFsspLoc);
			if (-e $fssp){
			    print $fhoutLoc "$fssp\n";}
			else {
			    print $fhoutNotLoc "-*- $sbrName missing FSSP=$fssp, for id=$id, \n";}}
    close($fhinLoc);close($fhoutLoc);
    return(1);
}				# end of convDsspList2FsspList

#===============================================================================
sub getFsspPairList {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$sepLoc,$tmp,$Lok,$tmpId,$tmpMatchList,$id,
	  @idRd,@idTot,@tmp,%Lok,%rd);
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
    $#idRd=$#idTot=0;		# read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (length($_)==0){
	    next;}
	$_=~s/_//g;		# delete HSSP chain identifier _
	@tmp=split(/\t/,$_); foreach $tmp (@tmp){$tmp=~s/\s//g;} # split 'idGuide  id1,id2,..'
	if (! defined $Lok{"$tmp[1]"}){	# collect unique list
	    push(@idTot,$tmp[1]); $Lok{"$tmp[1]"}=1; }
	push(@idRd,$tmp[1]);$tmpId=$tmp[1]; $tmpMatchList=$tmp[2]; $tmpMatchList=~s/^,*|,*$//g;
	$rd{"id","$tmpId"}=$tmpMatchList;
	@tmp=split(/,/,$tmpMatchList);foreach $tmp(@tmp){$tmp=~s/\s//g;} # split list of homologues
	$rd{"n","$tmpId"}=$#tmp;
	if ($tmpMatchList eq "none"){
	    next;}
	foreach $idMatch(@tmp){
	    if (! defined $Lok{"$idMatch"}){
		push(@idTot,$idMatch); $Lok{"$idMatch"}=1; }}}close($fhinLoc);

				# ------------------------------
				# write new file
    $Lok=&open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    print $fhoutLoc "# Perl-RDB\n","# \n","# FSSP pairs and counts\n","# \n",;
    printf $fhoutLoc "# %-20s : %6d (total number of chains in fold library)\n","NTOT",$#idTot;
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION PDBid","PDB (4 char) + chain (1 char) identifier";
    printf $fhoutLoc 
	"# %-20s : %-s\n","NOTATION PROB","=Nhits/NTOT, i.e. chance of hitting on family";
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION HOMOS","PDB + chain identifiers of homologues";
				# names and formats
    printf $fhoutLoc "%15s$sepLoc%10s$sepLoc%s\n","pdbId","prob","homosId";
    printf $fhoutLoc "%15s$sepLoc%10s$sepLoc%s\n","15","10.8F"," ";
    foreach $id (@idRd){
	printf $fhoutLoc 
	    "%-15s$sepLoc%10.8f$sepLoc%-s\n",$id,($rd{"n","$id"}/$#idTot),$rd{"id","$id"}; }
    return(1);
}				# end of getFsspPairList

#===============================================================================
sub getFsspLibProb {
    local ($fileInLoc,@desLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFsspLibProb              reads the file with the fold families
#       in:                     file
#       out:                    $rd{"all"}                -> idGuide1,idGuid2,...
#                               $rd{"allN"}               -> number of folds read
#                               $rd{"homosId","$idGuide"} -> matching familiy for idGuide
#                               $rd{"prob","$idGuide"}    -> probability of random hit for idGuide
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getFsspLibProb";$fhinLoc="FHIN"."$sbrName";

    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){
	print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
	return(0);}
				# read RDB file
				#    keywords should be 'pdbId,prob,homosId'
    %rdLoc=
	&rdRdbAssociative($fileInLoc,"body",@desLoc);
				# convert
    $rd{"all"}="";$#idAll=0;
    foreach $it (1..$rdLoc{"NROWS"}){
	foreach $kwd (@desLoc){	# purge blanks
	    if (!defined $rdLoc{"$kwd","$it"}){
		print "-*- WARNING $sbrName rdLoc it=$it, kwd=$kwd, not defined\n";}
	    else { $rdLoc{"$kwd","$it"}=~s/\s//g;}}
	$id=$rdLoc{"pdbId","$it"};
	push(@idAll,$id);$rd{"all"}.="$id,";
	foreach $kwd (@desLoc){
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

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#         c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (length($_)==0){
	    next;}
    } close($fhinLoc);

}				# end of subx

