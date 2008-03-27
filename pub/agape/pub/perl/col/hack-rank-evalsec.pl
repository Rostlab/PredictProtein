#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "file.rdb_from_evalsec";
$scrGoal="input file must have many IDs and many methods,\n".
    "     \t program will compile all kinds of ranking models\n".
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
#				version 0.1   	Feb,    	2003	       #
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
$#id=$#method=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n" if ($Ldebug);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $ctline=0;
    while (<$fhin>) {
	++$ctline;
	$_=~s/\n//g;
#	$_=~s/^.*\///g;		# purge directories

	next if ($_=~/^\#/);	# skip comments
	$line=$_;

	if ($_=~/^method/){	# read title
	    @tmp=split(/\t/,$_);
	    $ptr_method=1;
	    $ptr_id=    0;
	    $ptr_q3=    0;
	    $ptr_sov=   0;
	    foreach $it (1..$#tmp){
		$tmp[$it]=~s/\s//g;
		if    ($tmp[$it]=~/^Q3$/i){
		    $ptr_q3=$it;}
		elsif ($tmp[$it]=~/^sov$/i){
		    $ptr_sov=$it;}
		elsif ($tmp[$it]=~/^id$/i){
		    $ptr_id=$it;}
	    }
	    if (! $ptr_q3 || ! $ptr_sov || ! $ptr_id){
		print "xx pointers missing id=$ptr_id, q3=$ptr_q3, sov=$ptr_sov, line=\n";
		print $line,"\n";
		print "*** offending file=$fileIn\n"; # 
		die;
	    }
	    next;
	}
	next if ($line=~/\tid\t/);
				# all the others 
	@tmp=split(/\t/,$_);
	foreach $tmp (@tmp){
	    $tmp=~s/\s//g;
	}
	$method=$tmp[$ptr_method];
	$id=    $tmp[$ptr_id]; $id=~s/\..*$//g;
	$q3=    $tmp[$ptr_q3];
	$sov=   $tmp[$ptr_sov];
	if ($sov =~/[^0-9\.]/){
	    print "xx sov=$sov, for line($ctline)=$line\n";
	    die;}
	if ($q3 =~/[^0-9\.]/){
	    print "xx q3=$q3, for line($ctline)=$line\n";
	    die;}

	if (! defined $res{"id",$id}){
	    push(@id,$id);
	    $res{"id",$id}=$method;
	}
	else {
	    $res{"id",$id}.=",".$method;}
	if (! defined $res{"method",$method}){
	    push(@method,$method);
	    $res{"method",$method}=$method;
	}
	else {
	    $res{"method",$method}.=",".$method;}

	$res{$method,$id,"q3"}= $q3;
	$res{$method,$id,"sov"}=$sov;
    }
    close($fhin);
}

$nprot=$#id;
$nmethod=$#method;

print "--- Nprot=",$nprot,", Nmethods=",$nmethod,"\n" if ($Lverb);

				# ------------------------------
				# (2) averages
				# ------------------------------
foreach $method (@method){
    $res{"winner_q3",$method}=0;
    $res{"winner_sov",$method}=0;

    $res{"above_ave_q3",$method}=0;
    $res{"above_ave_sov",$method}=0;

    $res{"rank_q3",$method}=0;
    $res{"rank_sov",$method}=0;
}

foreach $id (@id){
    $ave_sov=$ave_q3=0;
    $max_sov=$max_q3=0;
    foreach $method (@method){
	$ave_sov+=$res{$method,$id,"sov"};
	$ave_q3+= $res{$method,$id,"q3"};
	if ($res{$method,$id,"q3"}>$max_q3){
	    $max_q3=  $res{$method,$id,"q3"};
	    $winnerq3=$method;}
	if ($res{$method,$id,"sov"}>$max_sov){
	    $max_sov= $res{$method,$id,"sov"};
	    $winnersov=$method;}
    }
    ++$res{"winner_q3",$winnerq3};
    ++$res{"winner_sov",$winnersov};

    $ave_sov=$ave_sov/$#method;
    $ave_q3= $ave_q3/$#method;

    $res{"ave_sov",$id}=sprintf("%6.2f",$ave_sov);$res{"ave_sov",$id}=~s/\s//g;
    $res{"ave_q3",$id}= sprintf("%6.2f",$ave_q3); $res{"ave_q3",$id}=~s/\s//g;
				# above average?
    foreach $method (@method){
	++$res{"above_ave_q3",$method}  if ($res{$method,$id,"q3"} >$res{"ave_q3",$id});
	++$res{"above_ave_sov",$method} if ($res{$method,$id,"sov"}>$res{"ave_sov",$id});
    }

				# now rank numerically q3
    undef %tmpq3;  $#tmpq3=0;
    undef %tmpsov; $#tmpsov=0;
    foreach $method (@method){
	$q3= $res{$method,$id,"q3"};
	if (! defined $tmpq3{$q3}){
	    push(@tmpq3,$q3);
	    $tmpq3{$q3}=$method;}
	else {
	    $tmpq3{$q3}.=",".$method;}

	$sov=$res{$method,$id,"sov"};
	if (! defined $tmpsov{$sov}){
	    push(@tmpsov,$sov);
	    $tmpsov{$sov}=$method;}
	else {
	    $tmpsov{$sov}.=",".$method;}
    }
    $ctrank=0;
    foreach $q3 (sort bynumber_high2low(@tmpq3)){
	++$ctrank;
	@tmp=split(/,/,$tmpq3{$q3});
	foreach $method (@tmp){
	    $res{"rank_q3",$method}+=$ctrank;
	}
    }
    $ctrank=0;
    foreach $sov (sort bynumber_high2low(@tmpsov)){
	++$ctrank;
	@tmp=split(/,/,$tmpsov{$sov});
	foreach $method (@tmp){
	    $res{"rank_sov",$method}+=$ctrank;
	}
    }
}

				# ------------------------------
				# (3) write output
				# ------------------------------
$tmpwrt= "";
$tmpwrt.="# nprot=".$#id."\n";
$tmpwrt.=
    "Method". " " x 9 .
    $sep."WinnerQ3".$sep."AboveAveQ3".$sep."AveRankQ3".
    $sep."WinnerSOV".$sep."AboveAveSOV".$sep."AveRankSOV".
    "\n";
foreach $method (@method){
    $tmpwrt.=$method. " " x (15-length($method));
    $tmpwrt.=$sep.$res{"winner_q3",$method}.$sep.$res{"above_ave_q3",$method};
    $tmpwrt.=$sep.sprintf("%6.1f",$res{"rank_q3",$method}/$#id);
    $tmpwrt.=$sep.$res{"winner_sov",$method}.$sep.$res{"above_ave_sov",$method};
    $tmpwrt.=$sep.sprintf("%6.1f",$res{"rank_sov",$method}/$#id);
    $tmpwrt.="\n";
}
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout
    $tmpwrt;
close($fhout);

if ($Lverb){
    print $tmpwrt;
}
if ($Lverb){
    print "--- output in $fileOut\n" if (-e $fileOut);
}
exit;


#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low


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

