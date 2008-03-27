#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "dir";
$scrGoal="returns statistics (how many files/dirs/kilobytes)\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   \n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Jan,    	2003	       #
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
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=$#dirIn=0;
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
    elsif (-l $arg||-d $arg)              { push(@dirIn,$arg); }
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

if (defined @fileIn){
    $fileIn=$fileIn[1] ;
    die ("*** ERROR $scrName: missing input file=$fileIn!\n") 
	if (! -e $fileIn);
}
elsif (defined @dirIn){
    $dirIn=$dirIn[1];
    die ("*** ERROR $scrName: missing input dir=$dirIn!\n") 
	if (! -d $dirIn && ! -l $dirIn);
}
else{
    die ("*** ERROR $scrName: no input dir?\n");
}
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);

$fileOut="stat-out.tmp"         if (! defined $fileOut);


				# ------------------------------
				# (1) read file(s)
				# ------------------------------
if (defined @fileIn){
    $ctfile=0;
    foreach $fileIn (@fileIn){
	++$ctfile;
	if (! -e $fileIn && ! -l $fileIn){
	    print "-*- WARN $scrName: no fileIn=$fileIn\n";
	    next;}
	print "--- $scrName: working on fileIn=$fileIn!\n" if ($Ldebug);
	$cmd="du -ka ".$fileIn;
	print "--- system '$cmd'\n" if ($Ldebug);
	@tmp=`$cmd`;
	foreach $tmp (@tmp){
	    $tmp=~s/\s*$//g;
	}
	foreach $tmp (@tmp){print "xx '$tmp'\n";}die;
    }
}
if (defined @dirIn){
    $ctfile=0;
    foreach $dirIn (@dirIn){
	$dirIn=~s/\/$//g;
	++$ctfile;
	if (! -d $dirIn && ! -l $dirIn){
	    print "-*- WARN $scrName: no dirIn=$dirIn\n";
	    next;}
	print "--- $scrName: working on dirIn=$dirIn!\n" if ($Ldebug);
	$cmd="du -kaP ".$dirIn;
	print "--- system '$cmd'\n" if ($Ldebug);
	@tmp=`$cmd`;
	$res{$dirIn}=0;
	$maxlevel=0;
	foreach $tmp (@tmp){
	    next if ($tmp=~/\s\.|\/\./);
	    $tmp=~s/\s*$//g;
	    $tmp=~s/^\s*//g;
	    @tmp2=split(/\s+/,$tmp);
	    if ($#tmp2<2){
		print "*** ERROR tmp=$tmp looks strange\n";
		exit;
	    }
	    $size=$tmp2[1];
	    $file=$tmp2[2];
	    next if ($size<5);
	    next if ($file eq $dirIn);
	    next if ($file=~/link2nam/);
	    $file=~s/^$dirIn//g;
	    $file=~s/^\///g;
	    $dir=$file;
#	    print "xx size=$size file=$file\n";
	    			# now dissect
	    if ($file =~/\.jpg/i || !-d $file){
		$file_end=$file;
		$file_end=~s/^\///g;
		$dir=~s/\/[^\/]*$//g;
	    }
	    else {
		$size=0;
	    }
	    if (length($dir)>0){
		@tmp3=split(/\//,$dir);
		$maxlevel=$#tmp3 if ($#tmp3>$maxlevel);
		$first=$tmp3[1];
		if (! defined $res{$first,"count"}){
		    $res{$first,"maxlevel"}=$res{$first,"byte"}=$res{$first,"count"}=0;
		    push(@first,$first);
		}
		$res{$first,"maxlevel"}=$#tmp3 if ($#tmp3>$res{$first,"maxlevel"});
		++$res{$first,"count"};
		$res{$first,"byte"}+=$size;
	    }
	}
    }
}
				# ------------------------------
				# (2) 
				# ------------------------------
$ct=$byte=0;
$wrt="";
$wrt.=sprintf("%-10s$sep%3s$sep%8s$sep%10s\n",
	      "dir","max","count","kbyte");
foreach $first (@first){
    $wrt.=sprintf("%-10s$sep%2d$sep%8d$sep%10d\n",
		  $first,$res{$first,"maxlevel"},$res{$first,"count"},int($res{$first,"byte"}/1000));
    $ct+=$res{$first,"count"};
    $byte+=$res{$first,"byte"};
}
$wrt.=sprintf("%-10s$sep%2d$sep%8d$sep%10d\n",
	      $dirIn[1],$maxlevel,$ct,int($byte/1000));

print $wrt,"\n"                 if ($Ldebug);
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

