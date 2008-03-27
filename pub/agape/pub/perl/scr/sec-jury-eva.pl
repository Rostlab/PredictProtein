#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="run JURY on many predictions\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'defjury3', "prof1,phdpsi,psipred",
#      'defjury3', "prof1,psipred,sspro",
      'defjury4', "prof1,phdpsi,psipred,sspro",
#      'defjury5', "prof1,phdpsi,psipred,samt99_sec,sspro",
      'defjury5', "jpred,prof1,phdpsi,psipred,sspro",
      'defjury6', "jpred,phdpsi,prof1,psipred,samt99_sec,sspro",
      'defjury7', "jpred,phdpsi,prof1,prof_king,psipred,samt99_sec,sspro",
      'defjury8', "jpred,prof1,prof_king,phd,phdpsi,psipred,samt99_sec,sspro",
      'defjuryN', "4",
      '', "",
      'extOut',    ".eva",
      );
@kwd=sort (keys %par);
				# weigths (= averages over all proteins)
#$par{"weight",""}=
$par{"weight","jpred"}=     0.598;
$par{"weight","phdpsi"}=    0.441;
$par{"weight","prof1"}=     0.474;
$par{"weight","prof_king"}= 0.752;
$par{"weight","psipred"}=   0.696;
$par{"weight","samt99_sec"}=0.589;
$par{"weight","sspro"}=     1.000;

$Ldebug=0;
$Lverb= 0;

$Lweight=0;			# if 1: weight decision!
$Lwin=   0;			# if 1: weight decision!

				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file*casp'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "name of output file";
    printf "%5s %-15s %-20s %-s\n","","<3|4|5|6>","no value","respective number of methods averaged";
    printf "%5s %-15s %-20s %-s\n","","psipred,prof",  " ",  "  yet another way to specify";

    printf "%5s %-15s %-20s %-s\n","","weight",   "no value","weight decision by reliability";
    printf "%5s %-15s %-20s %-s\n","","win",      "no value","sum who ever did win";
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
undef %jury;

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^ext=(.*)$/)            { $par{"extOut"}=  $1;
					    $par{"extOut"}=  ".".$par{"extOut"} if ($par{"extOut"}!~/^\./);}
    elsif ($arg=~/^(ri|wei)/i)            { $Lweight=        1;
					    $Lwin=           0;}
    elsif ($arg=~/^win.*/i)               { $Lwin=           1;
					    $Lweight=        0;}

    elsif ($arg=~/^([\d,]+)$/)            { $tmpjury_no=     $1;}
    elsif ($arg=~/^([a-z0-9,\_]+)$/)      { $tmpjury_name=   $1;}
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

				# ------------------------------
				# jury over how many methods?
$#juryname=0;
if    (! defined $tmpjury_no && !defined $tmpjury_name){
    @juryname=split(/,/,$par{"defjury".$par{"defjuryN"}});}
elsif (defined $tmpjury_no){
    @juryname=split(/,/,$par{"defjury".$tmpjury_no});}
elsif (defined $tmpjury_name){
    @juryname=split(/,/,$tmpjury_name);}

$njury=$#juryname;

$par{"weight","all"}=0;
foreach $method (@juryname){
    $take{$method}=1;
    if ($Lweight && ! defined $par{"weight",$method}){
	print "*** ERROR $scrName: weight for method=$method missing\n";
	exit;
    }
    $par{"weight","all"}+=$par{"weight",$method};
}
print "--- to jury: ",join(',',@juryname,"\n") if ($Ldebug);


$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

die ("*** ERROR $scrName: no method!\n")
    if ($#juryname<2);
				# ------------------------------
				# take only those used for jury
$#tmp=0;
undef %id2file;
$#id=0;

foreach $file (@fileIn){
    $method=$file;
    $method=~s/^.*\///g;	# purge chain
    $method=~s/^(.*)\.(.+)$/$2/;
    $id=$1;
    next if (! defined $take{$method});
    push(@tmp,$file);
    if (! defined $id2file{$id}){
	push(@id,$id);
	$id2file{$id}=1;
	$id2file{$id,$method}=$file;}
    else {
	++$id2file{$id};
	$id2file{$id,$method}=$file;}
}
				# sort ids
@id=sort(@id);

				# ------------------------------
				# loop over all proteins
foreach $id (@id){
    if (! defined $id2file{$id}){
	print "*** ERROR $scrName: id2file($id) missing!\n";
	die;
    }
				# too few
    next if ($id2file{$id} < $njury);
				# too many???
    if ($id2file{$id} > $njury){
	print "xx error too many for id=$id, =",$id2file{$id},"\n";
	die;}
				# read them all
    undef %statetmp;
    undef @statetmp;
    undef %jury;
    $minres=0;			# some may be shorter

    foreach $method (@juryname){
	$fileIn=$id2file{$id,$method};
	if (! -e $fileIn){
	    print "xx missing file=$fileIn, id=$id, method=$method,\n";
	    die;}
	open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
				# CASP header
	while (<$fhin>) {
	    last if ($_=~/^SS /);
	    last if ($_=~/^MODEL /);
	}
				# CASP body
	$ctres=0;
	$#sec=$#prob=0;
	$sumprob=0;
	while (<$fhin>) {
	    last if ($_=~/^(END|ACC)/);
	    next if ($_!~/^\s*\S\s+[A-Z]/);
	    $_=~s/\n//g;
	    $_=~s/^\s|\s*$//g;	# purge leading blanks
	    ($seq,$sec,$prob)=split(/\s+/,$_);
	    push(@sec, $sec);
	    push(@prob,$prob);
	    ++$ctres;
	    $sumprob+=$prob;
	    if (! defined $jury{$ctres,"seq"}){
		$jury{$ctres,"seq"}=$seq;
		$minres=            $ctres;
		$jury{"NROWS"}=     $ctres;}
	    if (! defined $jury{$ctres,"sec",$sec}){
		if (! defined $statetmp{$sec}){
		    push(@statetmp,$sec);
		    $statetmp{$sec}=1;}
		$jury{$ctres,"sec",$sec}=0;}
	}
	$minres=$jury{"NROWS"}=$ctres
	    if ($ctres < $minres);
	    
				# weights for method
	if ($Lweight){
				# all sum to 1 now
	    $norm2one= $par{"weight",$method}/$par{"weight","all"};
				# protein average better or worse than average?
	    $norm4prot=($sumprob/$jury{"NROWS"})/$par{"weight",$method};
	}

	foreach $itres (1..$jury{"NROWS"}){
	    $probtmp=$prob[$itres];
				# weight
	    $probtmp=$probtmp/($norm2one*$norm4prot)
		if ($Lweight);
	    $probtmp=1
		if ($Lwin);
	    $jury{$itres,"sec",$sec[$itres]}+=$probtmp;
	}
	close($fhin);
    }
				# now compile weighted winner take it all
    foreach $itres (1..$jury{"NROWS"}){
	$max=0;
	$win="";
#	$tmpwrt="res=$itres ";	# xx
	$sum=0;
	foreach $sec (@statetmp){
	    next if (! defined $jury{$itres,"sec",$sec});
#	    $tmpwrt.=$sec.":".$jury{$itres,"sec",$sec}." ";
	    $sum+=$jury{$itres,"sec",$sec};
	    if ($max < $jury{$itres,"sec",$sec}){
		$max=$jury{$itres,"sec",$sec};
		$win=$sec;
	    }
	}
	if (! $max){
	    print "*** oops id=$id, itres=$itres, no winner?\n";
#	    print "xx states=",join(',',@statetmp,"\n");
#	    print "xx tmpwrt=$tmpwrt\n";
	    die;}
	$jury{$itres,"win"}= $win;
	$jury{$itres,"prob"}=$jury{$itres,"sec",$win}/$sum;
#	print $tmpwrt." win=$win\n";
    }

				# ------------------------------
				# now write output
    $fileOut=$id.$par{"extOut"}.$njury;
    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
				# header
    print $fhout
	"PFRMAT SS\n",
	"TARGET ".$id."\n",
	"AUTHOR EVA\n",
	"REMARK Automatic combination of ".join(',',@juryname)."\n",
	"REMARK PARAMETERS:    DEFAULT\n",
	"REMARK\n",
	"METHOD SERVERNAME:    EVA\n",
	"METHOD PROGRAM:       EVA_jury_sec\n",
	"METHOD SERVER URL:    http://cubic.bioc.columbia.edu\n",
	"MODEL 1\n";
    foreach $itres (1..$jury{"NROWS"}){
	print $fhout
	    $jury{$itres,"seq"},"  ",$jury{$itres,"win"},"  ",
	    sprintf("%4.2f",$jury{$itres,"prob"}),"\n";
    }
    print $fhout
	"ENDDAT 1.1\n",
	"END\n";
    close($fhout);

    print "--- output in $fileOut\n" if (-e $fileOut);
}
exit;


#===============================================================================
sub htmlIndex {
    local($dirInLoc,$dirPublic_html_loc) = @_ ;
    local($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndex                   makes index of WWW directory: output in HTML
#       in:                     $dirInLoc:           full path to directory
#       in:                     $dirPublic_html_loc: full path to HOME dir, 
#                                                    needed to find icons
#                               
#       in GLOBAL:              $par{"dirXchDo"."eval".$type}
#       in GLOBAL:              $par{"debug"}
#       in GLOBAL:              $par{}
#       in GLOBAL:              
#                               
#       out GLOBAL              
#       out GLOBAL              
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR3=$packName.":"."htmlIndex";
    $SBR3="htmlIndex";
    $fhinLoc="FHIN_"."htmlIndex";$fhoutLoc="FHOUT_"."htmlIndex";
				# check arguments
    return(&errSbr("not def dirInLoc!",  $SBR3)) if (! defined $dirInLoc);
#    return(&errSbr("not def !",$SBR3)) if (! defined $);

    return(&errSbr("no dirIn=$dirInLoc!",$SBR3)) if (! -d $dirInLoc && 
						     ! -l $dirInLoc && 
						     ! -e $dirInLoc);

				# ------------------------------
				# find icon dir
    if (! defined $dirPublic_html_loc){
	$dirPublic_html_loc=$dirInLoc;
	$dirPublic_html_loc=~s/(eva\/).*$/$1/g;
    }
    $dirTmp=$dirInLoc;
    $dirTmp.="/"                if ($dirTmp !~ /\/$/);
    $dirTmp=~s/$dirPublic_html_loc//g;
    $dirTmp=substr($dirTmp,2)   if ($dirTmp =~ /^\//);
    $dirTmp=~s/[^\/]*(\/)/..$1/g;
    $dirTmp.="Dicon/";
				# ------------------------------
				# read directory
    opendir ($fhinLoc,$dirInLoc) || return(&errSbr("failed opening dirInLoc=$dirInLoc!",$SBR3));
    @tmp=readdir($fhinLoc);
    closedir($fhinLoc);
    $#tmp2=0;
    foreach $tmp (@tmp){
	next if ($tmp =~ /^\./);        # starting with '.'
	push(@tmp2,$tmp);
    }
    @tmp=@tmp2; $#tmp2=0;
				# open output file
    $dirInLoc.="/"              if (length($dirInLoc)>1 && $dirInLoc !~ /\/$/);

    $fileOutLoc=$dirInLoc."index.html";
				# ------------------------------
				# write header for index file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR3));
    $dirRelative=$dirInLoc;
    $dirRelative=~s/\/$//g;
    $dirRelative=~s/^.*\///g;
    print $fhoutLoc
	"<HTML>\n",
	"<HEAD><TITLE>INDEX ".$dirRelative."</TITLE></HEAD>\n",
	"<BODY>\n",
	"<H1>Index for directory ".$dirRelative."</H1>\n",
	"<BR>",
	"<IMG SRC=\"".$dirTmp."mis_hand_up.gif\">","&nbsp\;",
	"<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"<P>";
				# sort
    @tmp=sort(@tmp);
				# ------------------------------
				# write data for index file
    foreach $tmp (@tmp){
	next if ($tmp=~/^index.html/);
	if    (-d $dirInLoc.$tmp){
	    print $fhoutLoc
		"<IMG SRC=\"".$dirTmp."mis_dir.gif\">","&nbsp\;",
		"<A HREF=\"$tmp\">".$tmp."</A><BR>\n";}
	elsif (-e $dirInLoc.$tmp){
	    print $fhoutLoc
		"<IMG SRC=\"".$dirTmp."mis_file.gif\">","&nbsp\;",
		"<A HREF=\"$tmp\">".$tmp."</A><BR>\n";}
	else {
	    print $fhoutLoc
		"<IMG SRC=\"".$dirTmp."mis_link.gif\">","&nbsp\;",
		"<A HREF=\"$tmp\">".$tmp."</A><BR>\n";}
    }
    print $fhoutLoc
	"<P>\n",
	"<IMG SRC=\"".$dirTmp."mis_back.gif\">","&nbsp\;",
	       "<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"</BODY>\n",
	"</HTML>\n";
    close($fhoutLoc);
				# ------------------------------
				# make sure it is readable
    $cmd="chmod +r $fileOutLoc";
    ($Lok,$msg)=
	&sysRunProg($cmd,0,
		    0);         &assPrtWarn("failed system '$cmd'\n".$msg,$SBR3) if (! $Lok);

    return(1,"ok $SBR3");
}				# end of htmlIndex

#======================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system fileOut=$fileScrLoc, cmd=\n$prog\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg

#===============================================================================
sub wrtRankHtml_indexOld {
    local($typeLoc) = @_ ;
    local($SBR5,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRankHtml_indexOld                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=    "wrtRankHtml_indexOld";
    $fhinLoc= "FHIN_".$SBR5;
    $fhoutLoc="FHOUT_".$SBR5;

				# ------------------------------
				# read directory with all old common
				# ------------------------------

    $dir=$par{"dirWebResBupCommon".$typeLoc};

    opendir ($fhinLoc,$dir) ||
	return(&errSbr("failed opening dirWebResBupCommon$typeLoc=".$dir."!",$SBR5));
    @tmp=readdir($fhinLoc);
    closedir($fhinLoc);

				# expected file:
    $filecommon=$par{"fileOutWebResRank".$typeLoc.1};
    $filecommon=~s/^.*\///g;
    $#tmp2=0;
    $dir.="/"                   if ($dir !~ /\/$/);
    foreach $tmp (@tmp){
	next if ($tmp =~ /^\./);        # starting with '.'
	next if ($tmp=~/index/);
	$tmp2=$dir.$tmp."/".$filecommon;
	$tmp3=$tmp."/".$filecommon;
				# WATCH it: here some existence required!!!
	push(@tmp2,$dir.$tmp3)
	    if (-e $tmp2);
    }

				# ------------------------------
				# now write index file
				# ------------------------------

    $fileOutLoc= $par{"dirWebResBupCommon".$typeLoc};
    $fileOutLoc.="/"            if ($fileOutLoc !~ /\/$/);
    $fileOutLoc.="index.html";

    open($fhoutLoc,">".$fileOutLoc) ||
	return(&errSbr("fileOutLoc=$fileOutLoc, not opened",$SBR5));

    $titleLoc=  "EVA".$typeLoc." old common\n";
    $titleH1Loc="EVA".$typeLoc." old common index\n";
    $dirRelIcon="../../Dicon/";
    
    print $fhoutLoc
	"<HTML>",
	"<HEAD><TITLE>".$titleLoc."</TITLE></HEAD>",
	"<BODY bgcolor=#FFFFFF>",
	"<H1>".$titleH1Loc."</H1>\n";

    print $fhoutLoc
	"<BR>",
	"<IMG SRC=\"".$dirRelIcon."mis_hand_up.gif\">","&nbsp\;",
	"<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"<P>";

    @tmp2=sort(@tmp2);
    foreach $tmp (@tmp2){
	print "xx in $tmp\n";
				# purge dir
	$tmp=~s/^$par{"dirWebResBupCommon".$typeLoc}//g;
	$tmp2=$tmp;
	$tmp2=~s/.common.*$//g;
	print "xx nw $tmp\n";

	print $fhoutLoc
	    "<IMG SRC=\"".$dirRelIcon."mis_link.gif\">","&nbsp\;",
	    "<A HREF=\"$tmp\">".$tmp2."</A><BR>\n";
    }
    print $fhoutLoc
	"<P>\n",
	"<IMG SRC=\"".$dirRelIcon."mis_back.gif\">","&nbsp\;",
	       "<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"</BODY>\n",
	"</HTML>\n";
    print $fhoutLoc
	"</BODY></HTML>\n";
    close($fhoutLoc);

    $#tmp2=$#tmp=0;
    return(1,"ok $SBR5");
}				# end of wrtRankHtml_indexOld

#===============================================================================
sub month2num {
    local($nameIn) = @_ ;
    local($sbrName,%tmp);
#-------------------------------------------------------------------------------
#   month2num                   converts name of month to number
#       in:                     Jan (or january)
#       out:                    1
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."month2num";$fhinLoc="FHIN"."$sbrName";
    return(0) if (! defined $nameIn);
    $nameIn=~tr/[A-Z]/[a-z]/;	# all small letters
    $nameIn=substr($nameIn,1,3);
    %tmp=('jan',1,'feb',2,'mar',3,'apr', 4,'may', 5,'jun',6,
	  'jul',7,'aug',8,'sep',9,'oct',10,'nov',11,'dec',12);
    return($tmp{"$nameIn"});
}				# end of month2num

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

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/ctime.pl",           # HARD_CODED
	  "/home/rost/pub/perl/ctime.pl",       # HARD_CODED
	  "/home/phd/server/scr/lib/ctime.pm"   # HARD_CODED
	  );
    foreach $tmp (@tmp) {
	next if (! -e $tmp && ! -l $tmp);
	$exe_ctime=$tmp;	# local ctime library
	last; }

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    $Lok=
		require($exe_ctime)
		    if (-e $exe_ctime); }
				# ------------------------------
				# found one: use it
	if ($Lok && 
	    defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);} }
				# ------------------------------
	 			# found none: take system
    if (! $Lok) {
	$localtime=`date`;
	@Date=split(/\s+/,$localtime);
	$Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
    $date=$Date; $date=~s/(199\d|200\d)\s*.*$/$1/g;
    return($Date,$date);
}				# end of sysDate

