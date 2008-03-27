#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "[auto|unique.list]";
$scrGoal="takes unique list from EVA, finds all corresponding HSSP|DSSP|PDB entries into lists\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: uni-[dssp|hssp|pdb].list\n".
    "     \t need:   /home/ftp/pub/eva/unique_list.txt\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2002	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Dec,    	2002	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'fileUnique',  "/home/ftp/pub/eva/unique_list.txt",
      '', "",			# 
      'preOut',      "uni-",
      'extOut',      ".list",
      '', "",			# 
      );

$par{"dirWork"}=        "/dodo9/rost/wbup/";
$par{"dirOut"}=         "/dodo9/rost/wbup/";

$par{"dirData","dssp"}= "/data/dssp/";
$par{"dirData","hssp"}= "/data/hssp/";
$par{"dirData","pdb"}=  "/data/pdb/";

$par{"ext","dssp"}=     ".dssp";
$par{"ext","hssp"}=     ".hssp";
$par{"ext","pdb"}=      ".pdb";

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
#$sep=   "\t";
@db2do=
    (
     "pdb",
     "hssp",
     "dssp",
     );
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s %-20s %-s\n","","auto",    "no value","uses default settings (does them all)";

    printf "%5s %-15s %-20s %-s\n","","def",     "no value","shows default settings";

    printf "%5s %-15s %-20s %-s\n","","pdb",     "no value","do pdb list";
    printf "%5s %-15s %-20s %-s\n","","hssp",    "no value","do hssp list";
    printf "%5s %-15s %-20s %-s\n","","dssp",    "no value","do dssp list";

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
$#fileIn=      0;
$dirOut=       0;
$LshowDef=     0;
$Lauto=        0;

$dbAdd="";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=          $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut=           $1;
					    $dirOut.="/"       if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^auto$/)                { $Lauto=            1;}
    elsif ($arg=~/^(def|set)$/)           { $LshowDef=         1;}

    elsif ($arg=~/^(pdb|hssp|dssp)$/)     { $dbAdd.=           $1.",";}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=           1;
					    $Lverb=            1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=            1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=            0;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg || -l $arg)            { $par{"fileUnique"}=$arg;}

#    elsif (-e $arg)                       { push(@fileIn,$arg); }

    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){
		    $Lok=1;$par{$kwd}=$1;
		    last;
		}
	    }
	}
	if (! $Lok){ 
	    print "*** wrong command line arg '$arg'\n";
	    exit;
	}
    }
}

if (defined $dbAdd && length($dbAdd)>1){
    $dbAdd=~s/^,|,$//g;
    if (! $Lauto){
	$#db2do=0;
    }
    foreach $tmp (split(/,/,$dbAdd)){
	push(@db2do,$tmp);
    }
}

if ($LshowDef){
    printf "--- %-15s %-s\n","parameters",":";
    foreach $kwd (keys %par){
	next if (length($kwd)<1);
	printf "PAR %-15s %-s\n",$kwd,$par{$kwd};
    }
    printf "--- %-15s %-s\n","directories 2 do",":";
    print join("\n",@db2do);
#    print join("\n",@dir2do,"\n");
    exit;
}

if (! $dirOut){
    $dirOut="";
}
else {
    $dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);
}

				# ------------------------------
				# (1) read list of unique
				# ------------------------------
if ($Lauto){
    $cmd="scp1 rost\@maple:\/home\/ftp\/pub\/eva\/unique_list.txt ".$dirOut;
    print "--- NOTE still doing scp\n";
    print "--- system '$cmd'\n";
    system("$cmd");}

if ($Lauto){
    $fileIn=$par{"fileUnique"};
    $fileIn=~s/^.*\///g;
    $fileIn=$dirOut.$fileIn;
}
else {
    $fileIn=$par{"fileUnique"};
}

if (! -e $par{"fileUnique"}){
    print "*** ERRROR $scrName fileUniqueList=$fileIn, orig=",$par{"fileUnique"},", missing!\n";
    exit;
}

print "--- $scrName: working on fileIn=$fileIn!\n" if ($Ldebug);

open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
$#id=$#idnochn=0;
undef %tmp;
while (<$fhin>) {
    $_=~s/\n//g;
    next if ($_=~/^\#/);	# skip comments
    next if ($_=~/^id/);	# skip names
    $_=~s/\s//g;		# purge blanks
    $id=$_;
    $idnochn=$id;
    $idnochn=~s/[\_\:].$//      if ($id=~/[\:\_].$/);
    if (! defined $tmp{"id",$id}){
	$tmp{"id",$id}=1;
	push(@id,$id);}
    if (! defined $tmp{"idnochn",$idnochn}){
	$tmp{"idnochn",$idnochn}=1;
	push(@idnochn,$idnochn);}
}
close($fhin);

				# ------------------------------
				# copy original lists
$fileOut=$dirOut.$par{"preOut"}."id".$par{"extOut"};
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
foreach $file (@id){	
    print $fhout $file,"\n";
}
close($fhout);
if (-e $fileOut){ push(@fileOut,$fileOut);
		  $fileOut{$fileOut}=$#id; }
$fileOut=$dirOut.$par{"preOut"}."idnochn".$par{"extOut"};
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
foreach $file (@idnochn){	
    print $fhout $file,"\n";
}
close($fhout);
if (-e $fileOut){ push(@fileOut,$fileOut);
		  $fileOut{$fileOut}=$#idnochn; }


				# ------------------------------
				# (2) now write all lists
				# ------------------------------

foreach $db (@db2do){
    if (! defined $par{"dirData",$db}){
	print "*-* STRONG WARN $scrName: dirData($db) not defined\n";
	next;
    }
    if (! defined $par{"ext",$db}){
	print "*-* STRONG WARN $scrName: ext($db) not defined\n";
	next;
    }
    if (! -d $par{"dirData",$db} && ! -l $par{"dirData",$db}){
	print "*-* STRONG WARN $scrName: dirData($db)=",$par{"dirData",$db},", missing!\n";
	next;
    }
    $#tmpid=0;
    if ($db=~/hssp|dssp|pdb/){
	@tmpid=@idnochn;
    }
    else {
	@tmpid=@id;}

    print "--- $scrName: working on db=$db!\n" if ($Ldebug);
    $dir=$par{"dirData",$db};
    $dir.="/"                   if ($dir!~/\/$/);
    $ext=$par{"ext",$db};

    $#ok=0;
    foreach $id (@tmpid){
	$file=$dir.$id.$ext;
	if (! -e $file && ! -l $file){
	    print "-*- WARN missing file($db)=$file\n" 
		if ($Ldebug);
	    next; }
	push(@ok,$file);
    }
				# ------------------------------
				# write list
    $fileOut=$dirOut.$par{"preOut"}.$db.$par{"extOut"};
    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
    foreach $file (@ok){	
	print $fhout $file,"\n";
    }
    close($fhout);
    if (-e $fileOut){
	push(@fileOut,$fileOut);
	$fileOut{$fileOut}=$#ok;
    }
}
				# ------------------------------
				# (3) write output
				# ------------------------------
if ($Lverb){
    printf "--- %6d total unique\n",$#id;
    printf "--- %6d total unique(nochn)\n",$#idnochn;

    foreach $fileOut (@fileOut){
	printf "--- %6d %-s\n",$fileOut{$fileOut},$fileOut;
    }
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

