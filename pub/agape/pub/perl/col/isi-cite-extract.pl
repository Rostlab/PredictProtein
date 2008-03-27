#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="count citations from ISI list\n".
    "     \t input:  cite-name* (NOTE: file name MUST be like 'cite-'\$name\n".
    "     \t output: \n".
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
      '', "",			# 
      );

@kwd=sort (keys %par);
$sep="\t";
$Ldebug=0;
$Lverb= 0;
$Ldet=  0;

@excl_rost=("ohnemus","zondervan","buergin","hellwig");
$excl_rost_or=join("|",@excl_rost);


				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName cite-name*'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'

    printf "%5s %-15s %-20s %-s\n","","det",   "no value",   "write details";

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

    elsif ($arg=~/^det$/)                 { $Ldet=           1;}

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
$fileOut="syn-cite.tmp";
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";

$tmp= sprintf("%-20s","name");
$tmp.=$sep.
    "npaper".$sep."SumCite".$sep."MaxCite".$sep."AveC".$sep.
    "Npap1".$sep."Sum1".$sep."Max1".$sep."Ave1".
    "\n";

print $fhout
    $tmp;
print $tmp                     if ($Lverb || $Ldebug);

foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $name2get=$fileIn;
    $name2get=~s/^.*\/|\..*$//g;
    $name2get=~s/cite-//g;
    $name2get=~s/\d//g;
#    print "xx name2get=$name2get\n";

    $Lname=$Lnum=0;
    $Lskip= 0;
    $npub=0;
    undef %tmp;
    while (<$fhin>) {
	$_=~s/\n//g;
	if    ($_=~/^\s*Author/){
	    $Lname= 1;
	    $author=0;
	    $Lskip= 0;
	    next;}
	elsif ($_=~/^\s*AU (.*)/){
	    $Lname=1;
	    $author=$1;
	    $Lskip= 0;
	    while (<$fhin>){
		last if ($_=~/^TI/);
		$_=~s/\n//g;
		$_=~s/^\s*//g;
		$author.=$sep.$_;}
	}
	elsif ($_=~/^\s*Times/){
	    $Lnum=1;
	    $Lval=$val= 0;
	    next;}
	elsif ($_=~/^\s*TC (\S+)/){
	    $Lnum=$Lval=1;
	    $val= $1;
	    next;}
	elsif ($_=~/^\s*(SO|PY|VL|BP|EP) (\S+.*)\s*$/){
	    $kwdtmp=$1;
	    $quote.=$2;		# 
	    $quote.=" "         if ($kwdtmp=~/SO|PY|VL|EP/);
	    $quote.="-"         if ($kwdtmp=~/BP/);
	}
	elsif ($_=~/^\s*UT /){
	    $tmp{$npub,"quote"}=$quote;
	    $quote="";
	    next;
	}

	if ($Lname && ! $Lskip){
	    if ($author){
		$tmpName=$author;}
	    else {
		$_=~s/^\s*//g;
		$_=~s/\s*$//g;
		$tmpName=$_;}
	    $tmpx=$name2get;
#	    $tmpx.=", am" if ($tmpx=~/christiano/);
	    $Lname=0;
	    if ($tmpName!~/$tmpx/i){
		$Lskip=1;
	    }
	    else {
		++$npub;
		$tmpName=~tr/[A-Z]/[a-z]/;
		$tmp{$npub,"name"}=$tmpName;
	    }
#	    print "xx $tmpx $Lskip, $tmpName\n";
#	    die if ($Lskip);
	    next;}
	if ($Lnum){
	    if ($Lval){
		$tmp{$npub,"cite"}=$val;}
	    else {
		$_=~s/\D//g;
		$tmp{$npub,"cite"}=$_;}
	    $Lnum=0;
#	    print "xx npub=$npub, val=$val\n";
	    next;}

	next;

	$_=~s/^.*\///g;		# purge directories

	next if ($_=~/^\#/);	# skip comments
	next if ($_=~/^id/);	# skip names

	$_=~s/\#.*$//g;		# purge after comment
	$_=~s/\s//g;		# purge blanks

	@tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}
    }
    close($fhin);

    $sum=$max=$sum1=$max1=$npub1=0;
    $name2get=~tr/[A-Z]/[a-z]/;

    foreach $it (1..$npub){
	if ($tmp{$it,"cite"}>$max){
	    $max=$tmp{$it,"cite"};
	}
	$sum+=$tmp{$it,"cite"};
#	print "xx $it  sum=$sum ",$tmp{$it,"cite"},"\n";
				# only first and last
	$tmp=$tmp{$it,"name"};
	$tmp=~tr/[A-Z]/[a-z]/;

#	next if ($tmp !~ /^$name2get/ &&  $tmp!~ /$name2get\s\S+$/);
				# first or last?
	if ($tmp !~ /^$name2get/ &&  $tmp!~ /$name2get[\s,]+\S+$/){
#	    print "xx skip $tmp\n";
	    next;}

				# special skip for rost
	$Lok=1;
	if ($name2get =~ /rost/i){
	    $Lok=0
		if ($tmp =~/$excl_rost_or/);
#	    foreach $excltmp (@excl_rost){
#		if ($tmp=~/$excltmp/){
#		    $Lok=0;
#		    last;}}
	    if (! $Lok){
		$tmp2=$tmp; $tmp2=~s/\t/\; /g;
		print "---       excluded no=$it authors:$tmp2\n";
	    }
	}
	next if (! $Lok);

	if ($tmp{$it,"cite"}>$max1){
	    $max1=$tmp{$it,"cite"};
	}
	$sum1+=$tmp{$it,"cite"};
	++$npub1;

#	print "xx author=",$tmp{$it,"name"},"\n";

				# write details
	if ($Ldet){
	    push(@wrtdet,
		 sprintf("%5d\t%6d\t%-s",
			 $it,$tmp{$it,"cite"},$tmp{$it,"quote"})
		 );
	}
    }
    
    $ave= 0;
    $ave= ($sum/$npub) if ($npub>0);
    $ave1=0;
    $ave1=($sum1/$npub1) if ($npub1>0);
    if (0){
	print 
	    "xx npub=$npub\n",
	    "xx sum  =$sum\n",
	    "xx   ave=$ave\n",
	"xx sum1 =$sum1\n",
	    "xx  ave1=$ave1\n";
    }

    $tmp=sprintf("%-20s",$name2get);
    $tmp.=$sep.$npub.$sep.$sum.$sep.$max.$sep.sprintf("%5.1f",$ave);
    $tmp.=$sep.$npub1.$sep.$sum1.$sep.$max1.$sep.sprintf("%5.1f",$ave1);

    print $fhout 
	$tmp,"\n";
    print $tmp,"\n"             if ($Lverb || $Ldebug);
	
}
				# ------------------------------
				# (2) 
				# ------------------------------

if ($Ldet){
    print $fhout "\n";
    print $fhout "#--- details\n";
    print $fhout "\n";

    foreach $tmp (@wrtdet){
	print $tmp,"\n"         if ($Lverb);
	print $fhout 
	    "# ",$tmp,"\n";
    }}

				# ------------------------------
				# (3) write output
				# ------------------------------
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
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

