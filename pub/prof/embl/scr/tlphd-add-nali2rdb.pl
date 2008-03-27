#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="add line with number of alignments to PHD.rdb file\n".
    "     \t input:  id|file_phd.rdb\n".
    "     \t output: OVERWRITE!\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2001	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2001	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'extPhd',  ".rdbPhd",			# 
      'extHssp', ".hssp",			# 
      '', "",			# 
      );
$dirHssp="/data/hssp/";

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *phdRdb'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";

    printf "%5s %-15s=%-20s %-s\n","","dirHssp",  "x",       "where to search for HSSP files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$dirOut=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^dirHssp=(.*)$/i)       { $dirHssp= $1;
					    $dirHssp.="/"    if ($dirHssp !~ /\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
				# 
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);

$fileOut="TMP_".$$.".tmp"       if (! defined $fileOut);
    

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on fileIn=$fileIn!\n";
    $id=$fileIn;
    $id=~s/^.*\///g;
    $id=~s/\..*$//g;
    $hssp=$fileIn;
    $hssp=~s/$par{"extPhd"}/$par{"extHssp"}/;
    if (! -e $hssp){		# try dir
	$hssp=~s/^.*\///g;
	$hssp=$dirHssp.$hssp;
    }
    if (! -e $hssp){
	print "*** ERROR $scrName: hssp file=$hssp (dir=$dirHssp) missing!\n";
	exit;}

    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$id,$ctfile,(100*$ctfile/$#fileIn);
				# ------------------------------
				# read hssp
    $tmp=`grep '^NALIGN ' $hssp`;
    $tmp=~s/[\s\n]*$//g;
    $tmp=~s/^\s*NALIGN\s*(\d+).*$/$1/g;
    $nali=$tmp;

				# ------------------------------
				# now read and write

    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    $Lok=0;
#....,....1....,....2....,....3
## LENGTH        :    26
## NALI     :     15
    while (<$fhin>) {
	if ($_=~/^\#/){
	    print $fhout
		$_;
				# insert after '# LENGTH '
	    if ($_=~/^\#\s*LENGTH/){
		printf $fhout
		    "%-15s %-s%6d\n","# NALIGN",":",$nali;
		$Lok=1;
	    }
	    next; }
	if (! $Lok){		# failed ot insert, force after comments!
	    printf $fhout
		"%-15s %-s%6d\n","# NALIGN",":",$nali;
	    $Lok=1;
	}
	print $fhout
	    $_;
    }
    close($fhin);
    close($fhout);
				# ------------------------------
				# new to old
    $old=$fileIn;
    $old=~s/^.*\///g;
    $old.="_old";
    $cmd="\\mv ".$fileIn." ".$old;
    system("$cmd");             print "--- system '$cmd'\n" if ($Ldebug);
    $new=$fileIn;
    $new=~s/^.*\///g;
    $cmd="\\mv ".$fileOut." ".$new;
    system("$cmd");             print "--- system '$cmd'\n" if ($Ldebug);
}

unlink($fileOut)                if (-e $fileOut);

exit;


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
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

