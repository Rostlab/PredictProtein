#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "columns with 'rino:0,1,2,3,4,5,6,7,8,9,10 TAB riok: ..' from EVAsec";
$scrGoal="converts EVAs version of RIsec to statistics\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   \n".
    "     \t \n".
    "     \t ";
#  
# FIXME:
#------------------------------------------------------------------------------#
#	Copyright				        	2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Aug,    	2003	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
$sep=   "\t";
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
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

if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    if ($dirOut){
	$fileOut=$dirOut."Out-".$tmp;}
    else {
	$fileOut="Out-".$tmp;}}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    
    $ptr_rino=$ptr_riok=0;
    $ctline=0;
    while (<$fhin>) {
	++$ctline;
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
				# read names (find columns if more than 2 given)
	if ($_=~/^(date|id|ri)/){
	    @tmp=split(/\t/,$_);
	    $ncol=$#tmp;
	    $ptr_rino=$ptr_riok=0;
	    foreach $it (1..$ncol){
		if    ($tmp[$it]=~/rino/){
		    $ptr_rino=$it;}
		elsif ($tmp[$it]=~/riok/){
		    $ptr_riok=$it;}
	    }
	    if (! $ptr_rino || ! $ptr_riok){
		print "*** oops big problem ctline=$ctline file=$fileIn has no column with 'rino' or none with 'riok'!\n";
		exit;
	    }
	    			# now assign the values
	    $rino=$tmp[$ptr_rino];
	    $rino=~s/^.*rino\:\D*//g;
	    @rino=split(/,/,$rino);
	    $nrino=$#rino;
	    foreach $it (1..$nrino){
		$rino_txt[$it]=$rino[$it];
		$res_nrino[$it]=$res_nriok[$it]=0;
	    }
	    next;}
	if (! $ptr_rino || ! $ptr_riok){
	    print "*** oops bigger problem ctline=$ctline names not in file=$fileIn has no column with 'rino' or none with 'riok'!\n";
	    exit;
	}
				# remove quotes
	$_=~s/\"//g;
	@tmp=split(/\t/,$_);
	if (! defined $tmp[$ptr_rino]){
	    print "*** problem line=$ctline, no column rino($ptr_rino)\n",join("\n",@tmp,"\n");
	    exit;}
	if (! defined $tmp[$ptr_riok]){
	    print "*** problem line=$ctline, no column riok($ptr_riok)\n",join("\n",@tmp,"\n");
	    exit;}

	$rino=$tmp[$ptr_rino];
	$riok=$tmp[$ptr_riok];

	@rino=split(/,/,$rino);
	@riok=split(/,/,$riok);
	foreach $it(1..$nrino){
	    next if ($rino[$it]!~/^\d+$/);
	    $res_nrino[$it]+=$rino[$it];
	}
	foreach $it(1..$nrino){
	    next if ($riok[$it]!~/^\d+$/);
	    $res_nriok[$it]+=$riok[$it];
	}
    }
    close($fhin);
}
				# ------------------------------
				# (2) 
				# ------------------------------

				# compile cumulative
foreach $it (1..$nrino){
    $res_ncrino[$it]=$res_ncriok[$it]=0;
}

$ntot=0;
foreach $it (1..$nrino){
    $invit=1+$nrino-$it;
    foreach $it2 (1..$nrino){
	next if ($it2<$invit);
	$res_ncrino[$invit]+=$res_nrino[$it2];
	$res_ncriok[$invit]+=$res_nriok[$it2];
    }
    $ntot+=$res_nrino[$invit];
}

#print "xx total number=$ntot,\n";
$wrt="";
$wrt.=sprintf("%-2s$sep%-5s$sep%-10s$sep%-10s$sep%-6s$sep%-6s$sep%-10s$sep%-10s$sep%-6s$sep%-6s\n",
	      "no","RIsec",
	      "Nocc","Nok","Pocc","Pok",
	      "NCocc","NCok",
	      "Cumulative percentage of residues predicted at RI",
	      "Cumulative percentage of correctly predicted residues"
	      );
foreach $it (1..$nrino){
#    print "xx it=$it no=$res_nrino[$it] ok=$res_nriok[$it] per=",100*($res_nriok[$it]/$res_nrino[$it]),"\n";
    $wrt.=sprintf("%2d$sep%-5s$sep%10d$sep%10d$sep%6.1f$sep%6.1f$sep%10d$sep%10d$sep%6.1f$sep%6.1f\n",
		  $it,$rino_txt[$it],
		  $res_nrino[$it],$res_nriok[$it],100*($res_nrino[$it]/$ntot),100*($res_nriok[$it]/$res_nrino[$it]),
		  $res_ncrino[$it],$res_ncriok[$it],100*($res_ncrino[$it]/$ntot),100*($res_ncriok[$it]/$res_ncrino[$it])
		  );
}
if ($Ldebug){
    print $wrt;
}

				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout $wrt;
close($fhout);

if ($Lverb){
    print "--- output in $fileOut\n" if (-e $fileOut);
}
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

