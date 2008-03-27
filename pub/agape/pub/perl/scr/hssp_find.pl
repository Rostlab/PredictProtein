#!/usr/bin/perl -w
##!/usr/sbin/perl -w
$[ =1 ;

# finds the HSSP files for a given list of ids or files (/data/x/*.dfhssp_A ignored)

$Lverb=0;
if ( ($#ARGV<1) || &isHelp($ARGV[1])){
    print "goal:   find valid HSSP files (chain as: _C or fourth character\n";
    print "usage:  'script list_of_ids (or files)\n";
    print "option: allChains|all       (will print a list with all chains)\n";
    print "        e.g. 1cse.hssp_E\n";
    print "             1cse.hssp_I\n";
    print "        dir=/data/hssp/     (dir1,dir2 for many)\n";
    print "        ext=.hssp\n";
    print "        nocheck -> not checked whether or not chain existing\n";
    print "                   nor: empty HSSP\n";
    print "        verb                write blabla\n"       if (! $Lverb);
    print "        noscr               no write no blabla\n" if ($Lverb);
    exit;}

$file_in=$ARGV[1];
$LallChains=0; $Lnocheck=0;
$ext=".hssp";
if (defined $ENV{'DATA'}){
    $dir=$ENV{'DATA'}."/hssp/";}

foreach $arg (@ARGV) {
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^all[a-z]*/i)  {$LallChains=1;}
    elsif ($arg=~/^dir=(.+)$/)   {$dir=$1;}
    elsif ($arg=~/^ext=(.+)$/)   {$ext=$1;}
    elsif ($arg=~/^noch[a-z]*$/) {$Lnocheck=1;}
    elsif ($arg=~/^noscr[a-z]*$/){$Lverb=0;}
    elsif ($arg=~/^verb*$/)      {$Lverb=1;}
    else {
	print "*** argument '$arg' not recognised\n";
	exit; }
}

$fhin="FHIN";
$fhoutOk="FHOUT_OK";$fhoutNot="FHOUT_NOT";$fhoutEmpty="FHOUT_EMPTY";$fhoutWrong="FHOUT_WRONG";

$fileOutOk=   $file_in."-ok";
$fileOutNot=  $file_in."-not";
$fileOutEmpty=$file_in."-empty";
$fileOutWrong=$file_in."-wrong";

if (! defined $dir){
    @dir=("/data/hssp/","/sander/purple1/rost/data/hssp/","/home/rost/hssp/");}
else {
    @dir=split(/,/,$dir);}
foreach $dir (@dir){
    $dir.="/"  if ($dir !~/\/$/);}

				# ------------------------------
				# open all files
				# ------------------------------
&open_file("$fhin", "$file_in");
&open_file("$fhoutOk", ">$fileOutOk");
&open_file("$fhoutNot", ">$fileOutNot");
&open_file("$fhoutEmpty", ">$fileOutEmpty");
&open_file("$fhoutWrong", ">$fileOutWrong");
print $fhoutWrong "file             ","\t","chain wanted","\t","chain read","\n";

				# --------------------------------------------------
				# loop over all ids
				# --------------------------------------------------
$ctOk=$ctNot=$ctEmpty=$ctWrong=$ct=0;
$#fileOut=0;

while (<$fhin>) {
    $_=~s/\n|\s//g;
				# chop dir/ext
    $_=~s/^.*\/|$ext//g;

				# handle chain
    $chain="*";
    $_=~s/_(.)$//;
				# handle chain
    $chain=$1                   if (defined $1);

    next if (length($_)<3);	# skip strange ..

				# input file
    $fileIn= $_;
    $fileIn.=$ext;
    $fileIn.="_".$chain           if ($chain ne "*");

				# find respective HSSP file
    print "--- read '$_' \t chain=$chain, file=$fileIn, \n" if ($Lverb);

    ++$ct;
    ($fileRd,$chainRd)=
	&hsspGetFile($fileIn,$Lverb,@dir); 
    $chainRd="*"                if (! defined $chainRd || $chainRd eq " " || length($chainRd)==0);

				# ------------------------------
				# failed to find file: missing
    if (! -e $fileRd){
	++$ctNot;
	print $fhoutNot $fileIn," (chain=$chain)\n";
	next; }
				# ------------------------------
				# found but empty
    if (! $Lnocheck && &is_hssp_empty($fileRd)){
	++$ctEmpty;
	print $fhoutEmpty $fileRd,"\n";
	next; }
				# ------------------------------
    if ($Lnocheck){		# no check!
	push(@fileOut,$fileRd); 
	next; }
				# ------------------------------
				# get all chains actually in file
    ($chainRd2,%tmp)=
	&hsspGetChain($fileRd);

    $chainRd2=~s/ /\*/g;	# replace ' ' -> '*' for no chain
    @chainRd=split(//,$chainRd2);

				# ------------------------------
				# just add all
    if ($chain eq "*"){
	foreach $tmp (@chainRd){
	    $file=$fileRd;
	    $file.="_".$tmp     if ($tmp ne "*");
	    push(@fileOut,$file); } 
	next; }
				# ------------------------------
				# check them
    $Lok=0;
    foreach $tmp (@chainRd) {
	$Lok=1 if ($chain eq $tmp);
	last if ($Lok); }
    if ($Lok){
	$file=$fileRd;
	$file.="_".$chain       if ($chain ne "*");
	push(@fileOut,$file); 
	next; }
				# big shit: wrong chain
    ++$ctWrong;
    print "*** wrong chain for $fileRd: want $chain, got $chainRd2\n";
    print $fhoutWrong $fileRd."\t".$chain."\t".$chainRd2,"\n";
}

foreach $file (@fileOut){
    ++$ctOk;
    print $fhoutOk $file,"\n";}

close($fhin);close($fhoutOk);close($fhoutNot);close($fhoutEmpty);close($fhoutWrong);
				# remove empty
unlink($fileOutWrong)           if ($ctWrong < 1);
unlink($fileOutEmpty)           if ($ctEmpty < 1);
unlink($fileOutNot)             if ($ctNot   < 1);
unlink($fileOutOk)              if ($ctOk    < 1);

print "ok=$ctOk ($fileOutOk)  , not=$ctNot ($fileOutNot)\n";
print "   empty=$ctEmpty ($fileOutEmpty), wrong=$ctWrong ($fileOutWrong)\n";
print "sum =",$ctOk+$ctNot+$ctEmpty+$ctWrong,", sum files=$ct\n";
exit;



#==============================================================================
# library collected (begin)
#==============================================================================


#===============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir

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
    &open_file("$fh", "$fileInLoc") || 
	do {print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	    return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1) if ($tmp=~/^HSSP/);
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
# library collected (end)
#==============================================================================


1;
