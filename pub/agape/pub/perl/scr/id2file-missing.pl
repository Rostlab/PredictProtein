#!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads list of ids returns list of existing and missing files";
#  
#
$[ =1 ;
# 
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName list_with_ids'\n";
    print "opt: \t \n";
    print "     \t fileOutOk=x  : file for OK, other: fileOutNo)\n";
    print "     \t dir=x        : dir where to search: \$dir.\$id)\n";
    print "     \t ext=x        : ext to add to id:    \$dir.\$id.\$ext)\n";
    print "     \t chn=del|get  : del=purge chains in search (expect _[A-Z0-9])\n";
    print "     \t                get=check existence of chain, if HSSP\n";
    print "     \t any          : for 1prc will also find 1prc_A\n";
    print "     \t dbg\n";
    print "     \t also         : will report files in dir but NOT in list\n";
    print "     \t delete       : will report files in dir but NOT in list,\n";
    print "     \t                AND actually delete those!!\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
#$dir= "hsspDom/";
#$ext= ".hssp";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/\..*$//g;$fileOutOk="Outok-".$tmp.".list";
$fileOutNo=  $fileOutOk;$fileOutNo=~s/ok/no/;
$fileOutAlso=$fileOutOk;$fileOutAlso=~s/ok/also/;
$fileOutNew= $fileIn;
$fileOutNew=~s/^.*\///g;
$fileOutNew= "new-".$fileOutNew;

$Ldebug= 0;
$Lchndel=0;			# purge chain?
$Lchnget=0;			# find chain?
$Lalso=  0;
$Lchnany=0;			# find any chain
$Ldeletefile=0;
$dir=    0;
$dir=    0;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if    ($_=~/^fileOutOk=(.*)$/)   { $fileOutOk=$1;}
    elsif ($_=~/^fileOutNo=(.*)$/)   { $fileOutNo=$1;}
    elsif ($_=~/^dir=(.*)$/)         { $dir=      $1;}
    elsif ($_=~/^ext=(.*)$/)         { $ext=      $1;}
    elsif ($_=~/^chn=del/i)          { $Lchndel=  1;}
    elsif ($_=~/^chn=get/i)          { $Lchnget=  1;}
    elsif ($_=~/^any/i)              { $Lchnany=  1;}
    elsif ($_=~/^also$/)             { $Lalso=    1;}
    elsif ($_=~/^dbg$/)              { $Ldebug=   1;}
    elsif ($_=~/^delete$/)           { $Lalso=    1;
				       $Ldeletefile=1;}
#    elsif ($_=~/^=(.*)$/){$=$1;}
    else  {print"*** wrong command line arg '$_'\n";
	   die;}}
$dir=&complete_dir($dir)        if ($dir);
if (! -e $fileIn){print "*** missing input file $fileIn\n";
		  die;}

				# ------------------------------
				# (1) read file
$#id=0;
open($fhin, $fileIn) || die("*** ERROR $scrName: failed opening fileIn=$fileIn!\n");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/\s//g;
    $original=$_;
				# purge directory
    $_=~s/^.*\///g              if ($dir);
    if ($Lchndel) {
	$_=~s/\_[A-Z0-9]$//      if ($_=~/\_[A-Z0-9]$/);
	$_=~s/\_[A-Z0-9](\.)/$1/ if ($_=~/\_[A-Z0-9]\./);
    }
    next if (length($_)<1);
    push(@id,$_);
    $original{$_}=$original;
}
close($fhin);
				# ------------------------------
				# (2) search files
$#ok=$#not=$#missingChain=$#hackCheck=0;
$dir=""                         if (! $dir);
$Lhack_once_ok=1;		# dont die on missing 'KCHAIN' lines if successful once!
				# this is yet another HOLM problem ...
foreach $id (@id){
    $file= $dir.$id;
    $file.=$ext                 if ($ext && $file !~ /substr($ext,2)/);
    if ($Ldebug) {
	print "--- search $file "; 
	print "dir=$dir, " if ($dir);
	print "ext=$ext"   if ($ext);
	print "\n";}
    $Ldone=0;
				# ------------------------------
				# check chain?
    if ($Lchnget){
	$_=$file;
	$_=~s/\_[A-Z0-9]$//      if ($_=~/\_[A-Z0-9]$/);
	$_=~s/\_[A-Z0-9](\.)/$1/ if ($_=~/\_[A-Z0-9]\./);
	$fileTmp=$_;
	if ($file ne $fileTmp){
	    $chnHere=$file; $chnHere=~s/$fileTmp//; $chnHere=~s/\_//g;}
	else {
	    undef $chnHere;}
	    
	if    (! -e $fileTmp){
	    $Ldone=1;
	    push(@not,$id);}
	elsif (! defined $chnHere) {
	    $Ldone=1;
	    push(@ok,$id);}
	else {			# grep chain
	    $tmp=`grep KCHAIN $fileTmp`;
	    if (! $Lhack_once_ok &&
		(! defined $tmp || length($tmp)<3 || $tmp !~ /chain/)){
		print "*** ERROR $scrName: para chn=get only effective for HSSP!\n";
		print "       returned tmp=$tmp!\n";      
		print "       fileTmp=$fileTmp!\n";
		print "       file=   $file!\n";
		print "       id=     $id!\n";
		exit;}
	    elsif (! defined $tmp || length($tmp)<3 || $tmp !~ /chain/) {
				# grep again (HOLM error seems to happen for single chains)
		open(FHIN_TMP,$fileTmp)||
		    warn("*** WARN $scrName failed opening fileTmp=$fileTmp\n");
		while(<FHIN_TMP>){
		    next if ($_!~/^\s+\d+\s+\d+ (.)/);
		    $tmp2=$1;
		    last;}close(FHIN_TMP);
		if ($tmp2 eq $chnHere){
		    push(@ok,$id);}
		else {
		    push(@hackCheck,"$id\t$chnHere");}
		$Ldone=1;
	    }
	    else {
		$tmp=~s/\n//g;
		$tmp=~s/^.*chain.s. :\s*(.+)$/$1/g;
		$tmp=~s/\s//g;
		$Lhack_once_ok=1;
		$Lok=0;
		$Lok=1          if ($tmp=~/$chnHere/);
		print "--- $scrName: found chain=$chnHere, in chains=$tmp\n" if ($Ldebug && $Lok);
		print "--- $scrName: NOT   chain=$chnHere, in chains=$tmp\n" if ($Ldebug && ! $Lok);
		$Ldone=1;
		if (! $Lok){
		    push(@missingChain,$id);}
		else {
		    push(@ok,$id);}}}}
				# ------------------------------
				# do not check chain
    elsif (-e $file) {
	$Ldone=1;
	push(@ok,$file);}
    else{
	push(@not,$id);}
}

				# --------------------------------------------------
				# (3) check directory for other files
				# --------------------------------------------------

if ($Lalso || $Lchnany){
    if (! $dir) {
	$dir=`pwd`;
	$dir=~s/\s//g;}
    undef %tmp;
    foreach $id (@id){
	$tmp{$id}=1;
    }
    opendir($fhin,$dir) || die "*** ERROR $scrName: failed to open dir=$dir!\n";
    @tmp=readdir($fhin);
    closedir($fhin);
    $#also=0;
    $ctfile_indir=0;
    $dir.="/"                   if ($dir!~/\/$/);
    foreach $file (@tmp){
	next if ($file=~/^\./);
	++$ctfile_indir;
	$id=$file; $id=~s/$ext//g;
	next if (defined $tmp{$id});
	push(@also,$dir.$file);}
    if ($Ldeletefile && $#also>0){
	foreach $file (@also){
	    unlink($file);
	}
    }}

if ($Lchnany){
    undef %id;
    $#idnot=0;
    foreach $id (@ok){
	$id{$id}=1;
    }
    foreach $id (@not,@missingChain){
	next if (defined $id{$id});
	push(@idnot,$id);
	$id{$id}=1;
    }
    $#chnany=0;
    foreach $also (@also){
	foreach $idnot (@idnot){
	    push(@chnany,$also) if ($also=~/$idnot/);
	    $id{$id}=1;
	}}}
	
				# ------------------------------
				# write output
open($fhout,">".$fileOutOk)  
    || warn("*** WARN $scrName: failed opening fileOutOk=$fileOutOk!\n");
foreach $ok(@ok){
    print $fhout "$ok\n";
}
				# additional chains
if ($Lchnany){
    foreach $id (@chnany){
	print $fhout "$id\n";
    }
}
close($fhout);


open($fhout,">".$fileOutNo)
    || warn("*** WARN $scrName: failed opening fileOutNo=$fileOutNo!\n");
foreach $not(@not){
    next if ($Lchnany && defined $id{$not});
    print $fhout "$not\n";
}
close($fhout);

if ($Lalso && $#also>0){
    open($fhout,">".$fileOutAlso)
	|| warn("*** WARN $scrName: failed opening fileOutAlso=$fileOutAlso!\n");
    foreach $also (@also){
	print $fhout "$also\n";}close($fhout);}
elsif ($Lalso){
    print "--- no additional file found\n";}

if ($#missingChain>0){
    $fileOutMissing=$fileOutNo."_missing_chain";
    open($fhout,">".$fileOutMissing)
	|| warn("*** WARN $scrName: failed opening fileOutMissing=$fileOutMissing!\n");
    foreach $not(@missingChain){
	print $fhout "$not\n";}close($fhout);}
if ($#hackCheck>0){
    $fileOutHack=$fileOutNo."_check_chain";
    open($fhout,">".$fileOutHack)
	|| warn("*** WARN $scrName: failed opening fileOutHack=$fileOutHack!\n");
    foreach $not(@hackCheck){
	print $fhout "$not\n";}close($fhout);}
    
				# ------------------------------
				# write output
open($fhout,">".$fileOutNew)  
    || warn("*** WARN $scrName: failed opening fileOutNew=$fileOutNew!\n");
foreach $ok(@ok){
    $id=$ok;
    $id=~s/^.*\/|\..*$//g;
    if (defined $original{$id}){
	print $fhout $original{$id},"\n";
    }
    else {
	print "*-* missing original for $ok\n";
    }
}
close($fhout);


print "--- output:\n";
print "--- ",sprintf("%5d",$#id),          " wanted from     $fileIn\n";
print "--- ",sprintf("%5d",$#ok),          " original ok     $fileOutNew\n";
print "--- ",sprintf("%5d",$#ok),          " ok in           $fileOutOk\n";
print "--- ",sprintf("%5d",$#also),        " also in dir     $fileOutAlso\n",
      "--- ",sprintf("%5d",$ctfile_indir), " total in dir    $dir\n"            if ($#also>0);
print "--- ",sprintf("%5d",0),             " none other in   $dir\n"            if ($#also==0);
print "--- ",sprintf("%5d",$#not),         " missing in      $fileOutNo\n";
print "--- ",sprintf("%5d",$#missingChain)," missing chains  $fileOutMissing\n" if ($#missingChain>0);
print "--- ",sprintf("%5d",$#hackCheck),   " chains to check $fileOutHack\n"    if ($#hackCheck>0);
exit;



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias


#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir


#==============================================================================
# library collected (end)
#==============================================================================


1;
