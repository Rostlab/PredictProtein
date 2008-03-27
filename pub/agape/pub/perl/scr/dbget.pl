#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract sequences from a FASTA database";
$scrIn=      "database_file sequences_to_get ";			# 
$scrNarg=    2;		        # minimal number of input arguments
                                # additional information about script
$okFormOut=  "fasta";
#$okFormOut=  "hssp,dssp,msf,saf,daf,fastamul,pirmul,fasta,pir,gcg";
$okFormIn=   "fasta";
#$okFormIn=   "hssp,dssp,fssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,phdrdb,swiss";
                             @okFormOut=split(/,/,$okFormOut);@okFormIn=split(/,/,$okFormIn);
#                             $okFormOutOr=join('|',@okFormOut);$okFormInOr=join('|',@okFormIn);
$scrHelpTxt= "Format supported: \n"  if ($#okFormIn+$#okFormOut== 2);
$scrHelpTxt= "Formats supported: \n" if ($#okFormIn+$#okFormOut > 2);
$scrHelpTxt.="  * Input:   ".  $okFormOut."\n";
#$scrHelpTxt.="  * Output:  ".  $okFormIn ."\n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="For faster search index the database first:\n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="$scrName database_file index=file_name_where_indices_will_be_stored\n";
$scrHelpTxt.="$scrName database_index_file sequences_to_get\n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="NOTE: dbget index files recognised by extension '.dbgetIndex'\n";
$scrHelpTxt.="    \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
#  
#  
#  - $par{"kwd"}  : global parameters, available on command line by 'kwd=value'
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Mar,    	1999	       #
#------------------------------------------------------------------------------#
#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables

#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			

$fhTrace="STDERR";		# output to STDERR

if (! $Lok) { print $fhTrace "*** ERROR $scrName:after ini\n",$msg,"\n";
	      die; }

# print "xx came off with db=$fileData[1], idWanted=",join(',',@idWant,"\n");

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# open output file if to write
				# ------------------------------
if    ($fileOut) {
    open($fhout,">".$fileOut) ||
	do { print $fhTrace "*** $scrName: fileOut=$fileOut, not opened\n";
	     print $fhTrace "---> sequences will now be dumped onto STDOUT!\n";
	     $fhout="STDOUT"; }; }
				# open file for indices
elsif ($fileIndex) {
    open($fhout,">".$fileIndex) ||
	do { print $fhTrace "*** $scrName: fileIndex=$fileIndex, not opened\n";
	     print $fhTrace "---> sequences will now be dumped onto STDOUT!\n";
	     $fhout="STDOUT"; }; 
				# header for index file
    if ($fhout ne "STDOUT") {
	print  $fhout 
	    "# Perl-RDB dbget index\n";
	printf $fhout 
	    "%-s\t%-s\t%-20s\t%8s\%8s\t%-s\n",
	    "id","idPath","database","first line","last line","protein description"; }}
	
else {
    $fhout="STDOUT"; }

				# ------------------------------
				# rename (since GLOBAL variable)
				# ------------------------------
@NAMES_WANT=@idWant; $#idWant=0;

				# --------------------------------------------------
				# read database(s)
				# --------------------------------------------------
foreach $fileData (@fileData) {
    if (! -e $fileData && ! -l $fileData) { 
	print $fhTrace "-*- WARN $scrName: you wanted to read non existing file=$fileData!\n";
	next; }
				# ------------------------------
				# MODE: extract INDEX file
    if (! $fileIndex && $fileData =~ /\.dbget/) {
				# in  GLOBAL: @NAMES_WANT
				# out GLOBAL: @NAMES_WANT
	($Lok,$msg,$tmp)=
	    &dbExtractIndex($fileData,$fhout,$fhTrace);
	print $fhTrace "-*- WARN $scrName: problem with db=$fileData\n",$msg,"\n"
	    if (! $Lok);
	next; }

				# ------------------------------
				# MODE: extract FLAT
    if (! $fileIndex && $fileData !~ /\.dbget/) {
				# in  GLOBAL: @NAMES_WANT
				# out GLOBAL: @NAMES_WANT
	($Lok,$msg,$tmp)=
	    &dbExtractFlat($fileData,$fhout,$fhTrace);
	print $fhTrace "-*- WARN $scrName: problem with db=$fileData\n",$msg,"\n"
	    if (! $Lok);
	next; }

				# ------------------------------
				# MODE: create indices
				# in  GLOBAL: @NAMES_WANT
				# out GLOBAL: @NAMES_WANT
    ($Lok,$msg,$tmp)=
	&dbIndex($fileData,$fhout,$fhTrace);
    print $fhTrace "-*- WARN $scrName: problem with db=$fileData\n",$msg,"\n"
	if (! $Lok);
    next; }

				# ------------------------------
				# anyone not found?
				# ------------------------------
if ($par{"debug"} || $par{"verbose"}) {
    if ($#NAMES_WANT > 0) {
	print $fhTrace "--- the following names were never found:\n";
	foreach $name (@NAMES_WANT) {
	    print $fhTrace "$name\n";
	}}

    print $fhTrace "--- output  in $fileOut\n"   if ($fileOut && -e $fileOut);
    print $fhTrace "--- indices in $fileindex\n" if ($fileindex && -e $fileindex);
}
exit;


#===============================================================================
sub ini {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":ini";
				# ------------------------------
				# defaults
    $par{"dirData"}=            "/data/";
    $par{"swissprot"}=          $par{"dirData"}."swissprot/swiss";     # swissprot in FASTA
    $par{"swissnew"} =          $par{"dirData"}."swissnew/swissnew";   # new swissprot in FASTA
    $par{"trembl"}=             $par{"dirData"}."trembl/trembl";       # TREMBL in FASTA

#    $par{""}=                   "";

    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=            1; # blabla on screen

    $fhin="FHIN"; $fhout="FHOUT";

				# ------------------------------
    if ($#ARGV<$scrNarg){	# help
	@kwd=sort (keys %par);
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName $scrIn'\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-20s=%-20s %-s\n","","fileOut",  "x",       "";
#	printf "%5s %-20s %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
#	                                                     " note: automatic if extension *.list!!";
	printf "%5s %-20s %-20s %-s\n","","swiss",    "no value","use swissprot as database";
	printf "%5s %-20s %-20s %-s\n","","swissprot","no value","use swissprot as database";
	printf "%5s %-20s %-20s %-s\n","","swissnew", "no value","use swissnew as database";
	printf "%5s %-20s %-20s %-s\n","","trembl",   "no value","use trembl as database";

	printf "%5s %-20s %-20s %-s\n","","dbg",      "no value","debug mode (full screen)";
	printf "%5s %-20s %-20s %-s\n","","<noScreen|silent>", "no value","no info onto screen";

#	printf "%5s %-20s %-20s %-s\n","","", "no value","";

	printf "%5s %-20s=%-20s %-s\n","","db",       "x",        "database file from which to extract";
	printf "%5s %-20s=%-20s %-s\n","","index",    "x",        "file name storing indices";
#	printf "%5s %-20s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-20s=%-20s %-s\n","","",   "x", "";

	if (defined %par && $#kwd > 0){
	    $tmp= sprintf("%5s %-20s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	    $tmp.=sprintf("%5s %-20s  %-20s %-s\n","","other:","default settings: "," ");
	    $tmp2="";
	    foreach $kwd (@kwd){
		next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
		if    ($par{"$kwd"}=~/^\d+$/){
		    $tmp2.=sprintf("%5s %-20s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
		elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		    $tmp2.=sprintf("%5s %-20s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
		else {
		    $tmp2.=sprintf("%5s %-20s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	    } 
	    print $tmp, $tmp2       if (length($tmp2)>1);
	}
	exit;}
				# initialise variables
    $fhin="FHIN";$fhout="FHOUT";
    $fileOut=0;
				# ------------------------------
				# read command line

				# default: first argument is databas
    $#fileData=0;
    @fileData=($ARGV[1])        if ($ARGV[1] && (-e $ARGV[1] || -l $ARGV[1]));

    $#idWant=0;			# array with names to extract
    $#fileWant=0;		# files with list of proteins to extract
    $fileIndex=0;

				# other arguments
    foreach $arg (@ARGV){
	next if ($#fileData && $arg eq $ARGV[1]);
				# wants output as file
	if    ($arg=~/^(fileOut|out)=(.*)$/)  { $fileOut=$2;}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif ($arg=~/^(fileIndex|index)=(.*)$/){ $fileIndex=$2;}
				# logicals: names are in a file
	elsif ($arg =~ /^de?bu?g$/)           { $par{"debug"}=   1;}
	elsif ($arg =~ /^(silent|no.creen)$/) { $par{"debug"}=   0;}
				# existing file -> assume is a list
	elsif (-e $arg)                       { push(@fileWant, $arg);}
	elsif ($arg=~/^swiss$/)               { push(@fileData, $par{"swissprot"});}
	elsif ($arg=~/^trembl$/)              { push(@fileData, $par{"trembl"});}
	elsif ($arg=~/^swissnew$/)            { push(@fileData, $par{"swissnew"});}
	elsif ($arg=~/^swissprot$/)           { push(@fileData, $par{"swissprot"});}
	elsif ($arg=~/^(db|database)=(.*)$/i) { push(@fileData, split(/,/,$2));}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
				# no keyword -> assume is protein name or list thereof
	elsif ($arg!~/=/)                     { push(@idWant,split(/,/,$arg));}
				# search in $par{}
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					       last;}}}
	    if (! $Lok){ print $fhTrace "*** ERROR $scrName: wrong command line arg '$arg'\n";
			 exit;}}}
    
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
    if ($#fileWant) {
	foreach $fileWant (@fileWant){
	    if (! -e $fileWant) { 
		print "-*- WARN $sbrName: you wanted to read non existing file=$fileWant!\n";
		next; }
	    open($fhin,$fileWant) || return(0,"*** ERROR failed to open file=$fileWant!\n");
	    while(<$fhin>){
		$_=~s/\n//g; $_=~s/\s//g;
		push(@idWant,$_);}
	    close($fhin);}}
    $#fileWant=0;		# slim-is-in

				# ------------------------------
				# (1) change names to DB standard
				# ------------------------------
    if ($#idWant>0) {
	if ($fileData[1] =~ /swiss|trembl/) {
	    foreach $idWant (@idWant) {
		$idWant=~tr/[a-z]/[A-Z]/;
	    }
	}

				# yy do it anyway
	else {
	    foreach $idWant (@idWant) {
		$idWant=~tr/[a-z]/[A-Z]/;
	    }
	}
    }

    return(1,"ok $sbrName");
}				# end of ini

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub dbExtractFlat {
				# NOTE: change the passing one day
    local($fileDb,$fhoutDb,$fhoutMsg)=@_;
    local($sbrName,$fhinLoc,$Lok,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dbExtractFlat               reads database file, and extracts sequence
#       in:                     $fileDb     file with database
#       in:                     $fhoutDb    file handle for writing what was found
#       in:                     $fhoutMsg   file handle for printing info
#       in GLOBAL:              @NAMES_WANT  names of proteins wanted
#       out:                    (<1|0>,$msg,@NAMES_WANT)
#       out:                    @namesMiss  names of proteins wanted, but not found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":dbExtractFlat"; $fhinLoc="FHIN_".$sbrName;

				# open file
    open($fhinLoc,$fileDb) || 
	return(0,"*** WARN $sbrName: missing fileDb=$fileDb",0);

    $Lwrt=0;
				# ------------------------------
				# read db file
    while (<$fhinLoc>){
				# finish if none left to read
	last if (! $Lwrt && $#NAMES_WANT==0);
				# skip if not ID and not to write
	next if (! $Lwrt && $_!~/^\s*>/);
		 
				# write if not ID
	if ($Lwrt && $_!~/^\s*>/) {
	    print $fhoutDb $_; 
	    next; }
				# new ID -> reset flag 
	$Lwrt=0;
				# go through list (CPU eater!!)
	$#found=0;
	foreach $it (1..$#NAMES_WANT) {
	    next if ($_ !~ /$NAMES_WANT[$it]/);
	    print $fhoutDb $_;
	    $Lwrt=1;		# set flag
	}
				# regroup want list
	$#tmp=0;
	foreach $it (1..$#NAMES_WANT) {
	    push(@tmp,$NAMES_WANT[$it]) if (! defined $found[$it]);
	}
	$#NAMES_WANT=0; @NAMES_WANT=@tmp; $#tmp=0;
    }
    close($fhinLoc);

				# return those not found (as GLOBAL)
    return(1,"ok",1);
#    return(1,"ok",@NAMES_WANT);
}				# end of dbExtractFlat

#===============================================================================
sub dbExtractIndex {
				# NOTE: change the passing one day
    local($fileDb,$fhoutDb,$fhoutMsg)=@_;
    local($sbrName,$fhinLoc,$Lok,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dbExtractIndex               reads database file, and extracts sequence
#       in:                     $fileDb     file with database
#       in:                     $fhoutDb    file handle for writing what was found
#       in:                     $fhoutMsg   file handle for printing info
#       in GLOBAL:              @NAMES_WANT  names of proteins wanted
#       out:                    (<1|0>,$msg,@NAMES_WANT)
#       out:                    @namesMiss  names of proteins wanted, but not found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":dbExtractIndex"; $fhinLoc="FHIN_".$sbrName;

    undef %id_wanted;
				# ------------------------------
				# do it with grep
    foreach $name (@NAMES_WANT) {
	@tmp=`grep '^$name' $fileDb`;
	next if ($#tmp<1);
	$tmp[1]=~s/\n//g;
	next if (length($tmp[1])<5);
	$id_wanted{$name}=1;
	push(@found,$tmp[1]); }
				# track databases to open
    $#dbNamesLoc=0; undef %dbNamesLoc;

				# --------------------------------------------------
				# (1) read index file
				# --------------------------------------------------
    while (@found) {
	$_=shift @found;
				# skip header
	next if ($_=~/^[\s\t]*\#/);
	next if ($_=~/^id\s*\t/);
				# digest index file format
	$_=~s/\n//g;
#	($db,$beg,$end,$id)=split(/[\t\s]+/,$_);
	($id,$idPath,$db,$beg,$end,$des)=split(/\t/,$_);
				# add to database list
	if (! defined $dbNamesLoc{$db}) {
	    $dbNamesLoc{$db}=1;
	    push(@dbNamesLoc,$db);
	    $#{$db}=0; }
				# store numbers to read (will append all 
	push(@{$db},$beg .. $end);
#	    print "xx id=$id, array=",join(',',@{$db},"\n");
    }

				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 
				# none found ..
    return(0,"*** WARN no hit found in index list $fileDb!\n",0)
	if ($#dbNamesLoc < 1);
				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 

				# --------------------------------------------------
				# (2) extract from databases
				# --------------------------------------------------
    foreach $db (@dbNamesLoc) {
#	print "xx now read db=$db,\n";
	if (! -e $db && ! -l $db) {
	    print $fhoutMsg "*** WARN $sbrName: wanted to open missing db=$db!\n";
	    next; }
				# open database
	open($fhinLoc,$db) ||
	    do { print $fhoutMsg "*** WARN $sbrName: failed opening db=$db!\n";
		 next; };
				# sort line numbers
	@tmp=sort bynumber (@{$db});
	$#{$db}=0;		# slim-is-in

				# speed up through logicals
	$#Ltake=0;
	foreach $tmp (@tmp) {
	    $Ltake[$tmp]=1;
	}
#	print "xx wants to get lines=",join(',',@tmp,"\n");

				# now read respective lines
	$ctLine=0;
	while (<$fhinLoc>) {
	    ++$ctLine;
	    last if ($ctLine > $tmp[$#tmp]);
	    next if (! defined $Ltake[$ctLine]);
	    print $fhoutDb $_;
	}
	close($fhinLoc);
    }
				# ------------------------------
    $#tmp=0;			# update: some left?
    foreach $name (@NAMES_WANT) {
	next if (defined $id_wanted{$name});
	push(@tmp,$name);
    }
    @NAMES_WANT=@tmp; $#tmp=0; 
				# return those not found (as GLOBAL)
    return(1,"ok",1);
#    return(1,"ok",@NAMES_WANT);
}				# end of dbExtractIndex

#===============================================================================
sub dbExtractIndexVerySlow {
				# NOTE: change the passing one day
    local($fileDb,$fhoutDb,$fhoutMsg)=@_;
    local($sbrName,$fhinLoc,$Lok,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dbExtractIndexVerySlow               reads database file, and extracts sequence
#       in:                     $fileDb     file with database
#       in:                     $fhoutDb    file handle for writing what was found
#       in:                     $fhoutMsg   file handle for printing info
#       in GLOBAL:              @NAMES_WANT  names of proteins wanted
#       out:                    (<1|0>,$msg,@NAMES_WANT)
#       out:                    @namesMiss  names of proteins wanted, but not found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":dbExtractIndexVerySlow"; $fhinLoc="FHIN_".$sbrName;

				# open file
    open($fhinLoc,$fileDb) || 
	return(0,"*** WARN $sbrName: missing fileDb=$fileDb");

    $Lwrt=0;
				# track databases to open
    $#dbNamesLoc=0; undef %dbNamesLoc;
				# --------------------------------------------------
				# (1) read index file
				# --------------------------------------------------
    while (<$fhinLoc>){
				# skip header
	next if ($_=~/^[\s\t]*\#/);
	next if ($_=~/^database\s*\t/);
				# finish if none left to read
	last if (! $Lwrt && $#NAMES_WANT==0);
				# digest index file format
	$_=~s/\n//g;
#	($db,$beg,$end,$id)=split(/[\t\s]+/,$_);
	($db,$beg,$end,$id)=split(/\t/,$_);
				# go through list (CPU eater!!)
	$#found=0;
	foreach $it (1..$#NAMES_WANT) {
	    next if ($id !~ /$NAMES_WANT[$it]/);

	    if (! defined $dbNamesLoc{$db}) {
		$dbNamesLoc{$db}=1;
		push(@dbNamesLoc,$db);
		$#{$db}=0; }
				# store numbers to read (will append all 
	    push(@{$db},$beg .. $end);
#	    print "xx id=$id, array=",join(',',@{$db},"\n");
	}
				# regroup want list
	$#tmp=0;
	foreach $it (1..$#NAMES_WANT) {
	    push(@tmp,$NAMES_WANT[$it]) if (! defined $found[$it]);
	}
	$#NAMES_WANT=0; @NAMES_WANT=@tmp; $#tmp=0;
    }
    close($fhinLoc);

				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 
				# none found ..
    return(0,"*** WARN no hit found in index list $fileDb!\n",0)
	if ($#dbNamesLoc < 1);
				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 

				# --------------------------------------------------
				# (2) extract from databases
				# --------------------------------------------------
    foreach $db (@dbNamesLoc) {
#	print "xx now read db=$db,\n";
	if (! -e $db && ! -l $db) {
	    print $fhoutMsg "*** WARN $sbrName: wanted to open missing db=$db!\n";
	    next; }
				# open database
	open($fhinLoc,$db) ||
	    do { print $fhoutMsg "*** WARN $sbrName: failed opening db=$db!\n";
		 next; };
				# sort line numbers
	@tmp=sort bynumber (@{$db});
	$#{$db}=0;		# slim-is-in

				# speed up through logicals
	$#Ltake=0;
	foreach $tmp (@tmp) {
	    $Ltake[$tmp]=1;
	}
#	print "xx wants to get lines=",join(',',@tmp,"\n");

				# now read respective lines
	$ctLine=0;
	while (<$fhinLoc>) {
	    ++$ctLine;
	    last if ($ctLine > $tmp[$#tmp]);
	    next if (! defined $Ltake[$ctLine]);
	    print $fhoutDb $_;
	}
	close($fhinLoc);
    }

				# return those not found (as GLOBAL)
    return(1,"ok",1);
#    return(1,"ok",@NAMES_WANT);
}				# end of dbExtractIndexVerySlow

#===============================================================================
sub dbIndex {
    local($fileDb,$fhoutDb,$fhoutMsg)=@_;
    local($sbrName,$fhinLoc,$Lok,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dbIndex                     reads database file, and writes indices
#       in:                     $fileDb     file with database
#       in:                     $fhoutDb    file handle for writing what was found
#       in:                     $fhoutMsg   file handle for printing info
#       out:                    (<1|0>,$msg,@NAMES_WANT)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":dbIndex"; $fhinLoc="FHIN_".$sbrName;

				# open file
    open($fhinLoc,$fileDb) || 
	return(0,"*** WARN $sbrName: missing fileDb=$fileDb");

    $Lwrt=0;
    $ctLine=0;			# counter for lines
    $des=0;
				# ------------------------------
				# read db file
    while (<$fhinLoc>){
	++$ctLine;
				# non-id lines: just count
	next if ($_!~/^\s*>/);
	
				# id line

				# dump previous one
	if ($des) {
	    $idPath=$des;	# idPath= 'swiss|P18646|10KD_VIGUN'
	    $idPath=~s/^\s*>\s*(\S+).*$/$1/g;
				# id='18KD_VIGUN'
	    $id=$idPath; $id=~s/^.*\|//g;
				# now write
	    printf $fhoutDb 
		"%-s\t%-s\t%-s\t%-d\t%-d\t%-s\n",
		$id,$idPath,$fileDb,$beg,($ctLine-1),$des;
	}

				# new protein
	$des=$_; $des=~s/^\s*|\s*$//g; # purge leading blanks
	$beg=$ctLine; 
    }
    close($fhinLoc);

				# return those not found (as GLOBAL)
    return(1,"ok",1);
#    return(1,"ok",@NAMES_WANT);
}				# end of dbIndex

