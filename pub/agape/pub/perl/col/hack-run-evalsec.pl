#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "files with list of Txxxx.method in casp format for sec str";
$scrGoal="runs evalsec-simple.pl on many casp-formatted files\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   syntax of file name = ID.METHOD\n".
    "     \t \n".
    "     \t note:   will actually do it only on common subset!\n".
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
$par{"exeEvalsec"}=             "/home/rost/perl/scr/evalsec-simple.pl";
$par{"argEvalsec"}=             "";
$par{"argEvalsec"}=             "casp sov";
$par{"dirDssp"}=                "/data/dssp/";
$par{"fileOutPre"}=             "EVALsec_";
$par{"fileOutExt"}=             ".rdb";

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
$Ldobig=0;                      # append all methods into one file if 1
#$sep=   "\t";
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s %-20s %-s\n","","big",   "no value",  "append all methods into one file if 1";

    printf "%5s %-15s=%-20s %-s\n","","exclid",     "file_with_ids","ids to exclude";
    printf "%5s %-15s=%-20s %-s\n","","exclmethod", "file_with_names","methods to exclude";

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
$dirOut="";
$fileTmp="TMP_hack_evalsec.list";
$fileExclId=    "";
$fileExclMethod="";


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

    elsif ($arg=~/^big|dobig$/i)          { $Ldobig=         1;}

    elsif ($arg=~/^exclid=(.*)$/i)        { $fileExclId=     $1;}
    elsif ($arg=~/^exclmeth.*=(.*)$/i)    { $fileExclMethod= $1;}

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
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/ && length($dirOut)>1);

if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    if ($dirOut){
	$fileOut=$dirOut."Out-".$tmp;}
    else {
	$fileOut="Out-".$tmp;}}

				# ------------------------------
				# (0a) some to exclude?
				# ------------------------------
$#exclid=0;
if (length($fileExclId)>1){
    if (! -e $fileExclId){
	print "*** ERROR $scrName: you wanted to exclude ids in file=$fileExclId, but is missing!\n";
	exit;}
    open($fhin,$fileExclId) || die "*** $scrName ERROR opening fileExclId=$fileExclId!";
    while (<$fhin>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	push(@exclid,$_);
    }
    close($fhin);
    print "--- exclude nprot=",$#exclid,", read from file=$fileExclId\n";
}
$#exclmethod=0;
if (length($fileExclMethod)>1){
    if (! -e $fileExclMethod){
	print "*** ERROR $scrName: you wanted to exclude ids in file=$fileExclMethod, but is missing!\n";
	exit;}
    open($fhin,$fileExclMethod) || die "*** $scrName ERROR opening fileExclMethod=$fileExclMethod!";
    while (<$fhin>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	push(@exclmethod,$_);
    }
    close($fhin);
    print "--- exclude nmethod=",$#exclmethod,", read from file=$fileExclMethod\n";
}

foreach $id (@exclid){
    $exclid{$id}=1;
}
foreach $method (@exclmethod){
    $exclmethod{$method}=1;
}


    
				# ------------------------------
				# (1) read file with list of files
				# ------------------------------
$fileIn=$fileIn[1];
print "--- $scrName: working on fileIn(list)=$fileIn!\n" if ($Lverb);
undef %method;
undef %id;
$#id=$#method=0;
undef %res;
undef %file;
if ($Ldobig){
    $fhoutbig=  "FHOUT_big";
    $fileOutBig=$dirOut.$par{"fileOutPre"}."BIG".$par{"fileOutExt"};
}

open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
while (<$fhin>) {
    $_=~s/\n//g;
    next if ($_=~/^\#/);	# skip comments
    $_=~s/\#.*$//g;		# purge after comment
    $_=~s/\s//g;		# purge blanks

    $file=$_;
				# expected syntax 'ID.METHOD'
    $id=    $file; $id=~s/\..*$//g;
    $idnodir=$id; $idnodir=~s/^.*\///g;
    $method=$file; $method=~s/^.*\.//g;
				# to exclude?
    next if (defined $exclid{$idnodir});
    next if (defined $exclmethod{$method});

    if (! defined $res{"method",$method}){
	push(@method,$method);
	$res{"method",$method}=1;}
    else {
	++$res{"method",$method};}
    if (! defined $res{"id",$id}){
	push(@id,$id);
	$res{"id",$id}=1;}
    else {
	++$res{"id",$id};}
    
    $res{$id,$method}=$file;
}
close($fhin);

				# ------------------------------
				# (2) find common subset
				# ------------------------------
$ok=0;
foreach $id (@id){
    next if ($res{"id",$id}<$#method);
    ++$ok;
}
print "--- original common subset=$ok of ",$#id," proteins for Nmethods=",$#method,"\n";
$nprot=$#id;

if ($#id > $ok){
    print "--- simple way of finding common subset (may really fail often)\n";

    $#okid=$#kickid=0;
    foreach $id (@id){
	if ($res{"id",$id}<$#method){
	    push(@kickid,$id);
	}
	else {
	    push(@okid,$id);
	}
    }
    print "--- kicked out N=",$#kickid,", these are: ",join(',',@kickid,"\n");
    print "---     now ok N=",$#okid,  ", these are: ",join(',',@okid,"\n");
    @id=@okid;
}
$nprot=$#id;
				# --------------------------------------------------
				# (3) run evalsec-simple for all methods
				#     one at a time
				# --------------------------------------------------
				# append all results into one file
if ($Ldobig){
    open($fhoutbig,">".$fileOutBig) || 
	warn "*** $scrName ERROR creating fileOutBig=$fileOutBig!";
}

$#missing=0;
undef %missing;    
foreach $method (@method){
				# write list 2 do
    open($fhout,">".$fileTmp) || warn "*** $scrName ERROR creating fileTmp=$fileTmp";
    foreach $id (@id){
	next if (! defined $res{$id,$method});
	print $fhout
	    $res{$id,$method},"\n";
    }
    close($fhout);
				# now build argument to run
    $cmd= $par{"exeEvalsec"}." ".$fileTmp;
    $cmd.=" ".$par{"argEvalsec"};
    $cmd.=" dirDssp=".$par{"dirDssp"};
				# define output file
    $fileOut=$dirOut.$par{"fileOutPre"}.$method.$par{"fileOutExt"};
    $cmd.=" fileOut=".$fileOut;
    $cmd.=" "."dbg"             if ($Ldebug);
    
    print "--- system '$cmd'\n" if ($Lverb);
    system($cmd);

    $fileOut{$method}=$fileOut;
				# read summary of output
    next if (! -e $fileOut);
    open($fhin,$fileOut) || die "*** $scrName ERROR opening fileOut(evalsec,$method)=$fileOut!";
    $ctline=$ctline_data=0;
    undef %oktmp;
    $num=0;
    while (<$fhin>) {
	++$ctline;
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	$_=~s/\#.*$//g;		# purge after comment
	++$ctline_data;
	$line=$_;

				# read first line (once)
	if    ($ctline_data ==1 && $method eq $method[1]){
	    $first=$line;
	    $res{"linename"}=$first;
	    print $fhoutbig
		"method","\t",$first,"\n"
		    if ($Ldobig);
	}
	elsif ($line=~/^sum(\d+)/){
	    $num=$1;
	    $last=$line;
	}
	else {			# merge into big and check missing
	    print $fhoutbig
		$method,"\t",$line,"\n"
		    if ($Ldobig);
				# missing
	    $tmp=$line;
	    $tmp=~s/\t.*$//g;
	    $tmp=~s/\..*$//g;
	    $tmp=~s/\W//g;
	    $oktmp{$tmp}=1;
	}
    }
    close($fhin);
    $res{"nprot",$method}=  $num;
    $res{"linesum",$method}=$last;
    if ($num && $num < $nprot){
	foreach $id (@id){
	    $tmp=$id;
	    $tmp=~s/^.*\///g;
	    $tmp=~s/\W//g;
	    if (! defined $oktmp{$tmp}){
		if (! defined $missing{"method",$method}){
		    $missing{"method",$method}=1;}
		else {
		    ++$missing{"method",$method};}
		if (! defined $missing{$tmp}){
		    push(@missing,$tmp);
		    $missing{$tmp}=1;}
		else{
		    ++$missing{$tmp};
		}
	    }
	}
    }
    elsif (! $num){
	print "*** ERROR $scrName method=$method, no summary line? ($fileOut)\n";
	die;}

    if ($#missing){
	print "xx method=$method, Nmissing=",$#missing,": ",join(",",@missing,"\n");
    }
}
close($fhoutbig) if ($Ldobig);

				# ------------------------------
				# (4) write output with summary
				# ------------------------------
$fileOut=$dirOut.$par{"fileOutPre"}."summary".$par{"fileOutExt"};
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout
    "method","\t","nprot","\t",$res{"linename"},"\n";
foreach $method (@method){
    print $fhout
	$method,"\t",$res{"nprot",$method},"\t",$res{"linesum",$method},"\n";
}
close($fhout);
				# remove temporary file
unlink($fileTmp)                if (! $Ldebug);
if ($#missing){
    $fileOutMissing="ERROR-missing-ids.dat";
    open($fhout,">".$fileOutMissing) || 
	warn "*** $scrName ERROR creating fileOutMissing=$fileOutMissing";
    undef %tmp;
    foreach $missing (sort @missing){
	next if (defined $tmp{$missing});
	print $fhout
	    $missing,"\t",$missing{$missing},"\n";
    }
    close($fhout);
				# which failed most?
    undef %tmp;
    $#tmp=0;
    foreach $method (@method){
	next if (! defined $missing{"method",$method});
	if (! defined $tmp{$missing{"method",$method}}){
	    push(@tmp,$missing{"method",$method});
	    $tmp{$missing{"method",$method}}=$method;
	}
	else {
	    $tmp{$missing{"method",$method}}.=",".$method;
	}
    }   
	
    print "--- missing sorted by culprit\n";
    foreach $num (sort bynumber(@tmp)){
	printf "--- missing N=%3d %-s\n",$num,$tmp{$num};
    }
}
	

if ($Lverb){
    print "--- output  in $fileOut\n" if (-e $fileOut);
    print "--- BIG     in $fileOutBig\n" if ($Ldobig);
    print "--- missing in $fileOutMissing\n" if (defined $fileOutMissing && -e $fileOutMissing);
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

