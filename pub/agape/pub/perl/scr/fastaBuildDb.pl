#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "from list of <swissprot|trembl> ids 2 FASTA database file\n";
$scrIn=      "database_name sequences_to_get ";			# 
$scrNarg=    2;		        # minimal number of input arguments
#  
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
				# initialise variables
				# out GLOBAL: @idWant= all names
($Lok,$msg)=
    &ini();			

$fhTrace="STDERR";		# output to STDERR

if (! $Lok) { print $fhTrace "*** ERROR $scrName:after ini\n",$msg,"\n";
	      die; }

# print "xx came off with db=$fileData[1], wanted=",join(',',@idWant,"\n");

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
else {
    $fhout="STDOUT"; }

$fhoutScreen=0;			# no output to screen
$fhoutScreen="STDOUT"           if ($fileOut   && $par{"debug"});
$fhoutScreen="STDERR"           if (! $fileOut && $par{"debug"});

				# --------------------------------------------------
				# read database(s)
				# --------------------------------------------------
foreach $dirDbFasta (@dirDbFasta) {
    if (! -d $dirDbFasta) {
	print $fhTrace "-*- WARN $scrName: you wanted to read missing dirDb=$dirDbFasta!\n";
	next; }
				# add final slash
    $dirDbFasta.="/"            if ($dirDbFasta !~/\/$/);

				# ------------------------------
				# search for files
    $#found=0;
    foreach $it (1..$#idWant) {
	$idWant=$idWant[$it];
				# file with FASTA format (from e.g. /data/swissprot/split/)
	$file=$dirDbFasta.$idWant.$par{"ext"};
				# file not found
	next if (! -e $file && ! -l $file);
	$found[$it]=1;
				# cat file
	if ($fileOut) {		#          .. to output file
	    $cmd="cat < $file >> $fileOut"; }
	else {			#          .. to STDOUT
	    $cmd="cat < $file "; }

				# system call

	($Lok,$msg)=
	    &sysSystem($cmd,$fhoutScreen);
    }
				# regroup want
    $#tmp=0;
    foreach $it (1..$#idWant) {
	push(@tmp,$idWant[$it]) if (! defined $found[$it]);
    }
    $#idWant=0; @idWant=@tmp; $#tmp=0;
}

				# ------------------------------
				# anyone not found?
				# ------------------------------
if ($par{"debug"} || $par{"verbose"}) {
    if ($#idWant > 0) {
	print $fhTrace "--- the following names were never found:\n";
	foreach $name (@idWant) {
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
				# full database in single fasta files:
    $par{"swissprot"}=          $par{"dirData"}."swissprot/split/";     # swissprot in FASTA
    $par{"swissnew"} =          $par{"dirData"}."swissnew/split/";   # new swissprot in FASTA
    $par{"trembl"}=             $par{"dirData"}."trembl/split/";       # TREMBL in FASTA

    $par{"ext"}=                ".f"; # extension of file in split dir

#    $par{""}=                   "";

    $par{"debug"}=              0; # if 1 : keep (most) temporary files

    $fhin="FHIN"; $fhout="FHOUT";

				# ------------------------------
    if ($#ARGV < $scrNarg){	# help
	@kwd=sort (keys %par);
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName $scrIn'\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-20s=%-20s %-s\n","","<fileOut|out>",  "x",       "";

	printf "%5s %-20s %-20s %-s\n","","swiss",    "no value","use swissprot as database";
	printf "%5s %-20s %-20s %-s\n","","swissprot","no value","use swissprot as database";
	printf "%5s %-20s %-20s %-s\n","","swissnew", "no value","use swissnew as database";
	printf "%5s %-20s %-20s %-s\n","","trembl",   "no value","use trembl as database";

	printf "%5s %-20s %-20s %-s\n","","dbg",      "no value","debug mode (full screen)";
	printf "%5s %-20s %-20s %-s\n","","<noScreen|silent>", "no value","no info onto screen";

#	printf "%5s %-20s %-20s %-s\n","","", "no value","";

	printf "%5s %-20s=%-20s %-s\n","","db",       "x",        "database path (many: 'db1,db2')";
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
    $#dirDbFasta=0;
    @dirDbFasta=($ARGV[1])      if ($ARGV[1] && (-e $ARGV[1] || -l $ARGV[1]));

    $#idWant=0;			# array with names to extract
    $#fileWant=0;		# files with list of proteins to extract

				# other arguments
    foreach $arg (@ARGV){
	next if ($#dirDbFasta && $arg eq $ARGV[1]);
				# wants output as file
	if    ($arg=~/^(fileOut|out)=(.*)$/)  { $fileOut=$2;}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
				# logicals: names are in a file
	elsif ($arg =~ /^de?bu?g$/)           { $par{"debug"}=   1;}
	elsif ($arg =~ /^(silent|no.creen)$/) { $par{"debug"}=   0;}
				# existing file -> assume is a list
	elsif (-e $arg)                       { push(@fileWant, $arg);}
	elsif ($arg=~/^swiss$/)               { push(@dirDbFasta, $par{"swissprot"});}
	elsif ($arg=~/^trembl$/)              { push(@dirDbFasta, $par{"trembl"});}
	elsif ($arg=~/^swissnew$/)            { push(@dirDbFasta, $par{"swissnew"});}
	elsif ($arg=~/^swissprot$/)           { push(@dirDbFasta, $par{"swissprot"});}
	elsif ($arg=~/^(db|database)=(.*)$/i) { push(@dirDbFasta, split(/,/,$2));}
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
	if (defined $dirDbFasta[1] &&
	    $dirDbFasta[1] =~ /swiss|trembl/) {
	    foreach $idWant (@idWant) {
		$idWant=~tr/[A-Z]/[a-z]/;
		$idWant=~s/\s//g;
	    }
	}

				# yy do it anyway
	else {
	    foreach $idWant (@idWant) {
		$idWant=~tr/[A-Z]/[a-z]/;
		$idWant=~s/\s//g;
	    }
	}
    }

    return(1,"ok $sbrName");
}				# end of ini

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub sysSystem {
    local($cmdLoc,$fhLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSystem                   simple way of running system command + documenting them
#       in:                     $cmd:   will do system($cmd)
#       in:                     $fhLoc: will write trace onto fhLoc
#                                 =<! defined> -> STDOUT
#                                 =0           -> no output
#       out:                    <1|0>,<"value from system"|$errorMessag>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."sysSystem";
				# no argument given
    return(0,"*** ERROR $sbrName: no input argument (system command)")
	if (! defined $cmdLoc || ! $cmdLoc);

				# default
    $fhLoc="STDOUT"             if (! defined $fhLoc);
    
				# ------------------------------
				# write
    print $fhLoc "--- system: \t $cmdLoc\n" if ($fhLoc);

				# ------------------------------
				# run system
    $Lsystem=
	system("$cmdLoc");

    return(1,$Lsystem);
}				# end of sysSystem


