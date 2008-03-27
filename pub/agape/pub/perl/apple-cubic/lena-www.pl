#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "title [auto|*jpg]";
$scrGoal="makes www pages of photos (priv)\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   xhistory.rdb gives all other directories\n".
    "     \t note:   first argument MUST be new directory name\n".
    "     \t auto:   need directory 'new'\n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 1.0   	Dec,    	2002	       #
#				version 1.1   	Aug,    	2003	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults

%par=(
      'path',                   "", # directory or URL path for files
      '', "",			# 
      'width',                  "150",
      'height',                 "100",
      'email',                  "rost\@columbia.edu",
      'www',                    "http://cubic.bioc.columbia.edu/~rost/xpriv/photos/",
      '', "",			# 
#      'arrowUp',                $par{"dirHome"}."/MAT/arrow-up.gif",
#      'arrowDown',              $par{"dirHome"}."/MAT/arrow-down.gif",
      '', "",			# 
      'ftpUrl',                 "ftp://cubic.bioc.columbia.edu/pub/mis/talks/",
      'exeTar',                 "/usr/bin/tar",
      'exeGzip',                "/usr/bin/gzip",
      );


$par{"dirHome"}=                "/home/rost/public_html/rost/";
$par{"dirPhoto"}=               $par{"dirHome"}.  "xpriv/photos/";
$par{"dirIcon"}=                $par{"dirPhoto"}. "Dicon/";

$par{"dirNew"}=                 $par{"dirPhoto"}. "new/";
$par{"dirNewNail"}=             $par{"dirPhoto"}. "newnail/";
$par{"dirDoNail"}=              $par{"dirPhoto"}. "xdonail/";
#$par{"dirNewNail"}=             $par{"dirPhoto"}. "newnail/";
$par{"dirArchive"}=             $par{"dirPhoto"}. "archive/";

$par{"dirWalkRel"}=             "walk/";
$par{"dirNailRel"}=             "nail/";
$par{"dirArchiveRel"}=          "../archive/";

$par{"fileOutHistory"}=         $par{"dirPhoto"}. "xhistory.rdb";
$par{"fileNopub"}=              $par{"dirPhoto"}. "xnopub.rdb";

$par{"fileIconUp"}=             $par{"dirIcon"}.  "arrow-up.gif";
$par{"fileIconDown"}=           $par{"dirIcon"}.  "arrow-down.gif";
$par{"fileIconForward"}=        $par{"dirIcon"}.  "arrow-forward.gif";
$par{"fileIconBack"}=           $par{"dirIcon"}.  "arrow-back.gif";

$par{"fileIconUpRel"}=          "../../Dicon/".   "arrow-up.gif";
$par{"fileIconDownRel"}=        "../../Dicon/".   "arrow-down.gif";
$par{"fileIconForwardRel"}=     "../../Dicon/".   "arrow-forward.gif";
$par{"fileIconBackRel"}=        "../../Dicon/".   "arrow-back.gif";

$par{"titleCentral"}=           "Photos";
$par{"titleAllinone"}=          "all";
$par{"titleArchive"}=           "archive";

$par{"extHtml"}=                ".html";
$par{"extTar"}=                 ".tar";
$par{"extGzip"}=                ".gz";

$par{"doGzip"}=                 1;

$par{"picPerLane"}=             10;


@kwd=sort (keys %par);

$sep=   "\t";
$Ldebug=0;
$Lverb= 0;
$Lclean=0;
				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName title *gif'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirPhoto",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    printf "%5s %-15s %-20s %-s\n","","clean",    "no value","clean up new/ newnail/";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
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
$fhout="FHOUT";
$#fileIn=0;
$title=$ARGV[1]; $title=~s/title=//g;
$Lauto=  0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);

    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^title=(.*)$/)          { $title=          $1;}

    elsif ($arg=~/^auto$/)                { $Lauto=          1;}
    elsif ($arg=~/^clean$/)               { $Lclean=         1;}

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

if ($Lauto){
    $#fileOriginal=0;
    $dir=$par{"dirNew"};
    				# read directory with new files
    print "--- readdir $dir\n"  if ($Lverb);
    opendir(DIR,$dir) || die ("-*- ERROR $scrName: failed opening dir(pred)=$dir!\n");
    @tmp=readdir(DIR);  closedir(DIR);
				# filter subdirectories
    $#tmp2=0;
    foreach $tmp (@tmp) { 
	$tmp2=$dir;
	$tmp2.="/"              if ($tmp2 !~/\/$/);
	$tmp2.=$tmp;
	next if (-d $tmp2);
	next if (! -e $tmp2);
	push(@tmp2,$tmp2); 
    }
    push(@fileIn,@tmp2); 	# add to (may be alread) existing input files
    push(@fileOriginal,@tmp2);
    				# read directory with new nails

    $dir=$par{"dirNewNail"};
    print "--- readdir $dir\n"  if ($Lverb);
    opendir(DIR,$dir) || die ("-*- ERROR $scrName: failed opening dir(pred)=$dir!\n");
    @tmp=readdir(DIR);  closedir(DIR);
				# filter subdirectories
    $#tmp2=0;
    foreach $tmp (@tmp) { 
	$tmp2=$dir;
	$tmp2.="/"              if ($tmp2 !~/\/$/);
	$tmp2.=$tmp;
	next if (-d $tmp2);
	next if (! -e $tmp2);
	push(@tmp2,$tmp2); 
    }
    @fileInNail=@tmp2;	 # add to (may be alread) existing input files
    push(@fileOriginal,@tmp2);
}
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);


				# ------------------------------
				# (1) copy all files
				# ------------------------------
$dirOut=$par{"dirPhoto"}.$title."/";
if (! -e $dirOut && ! -l $dirOut && ! -d $dirOut){
    $cmd="mkdir $dirOut";
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
    $cmd="chmod go+r $dirOut";
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
    $Lisnew=1;
}
else {
    $Lisnew=0;
}
$dirOutNail=$dirOut.$par{"dirNailRel"};
if (! -e $dirOutNail && ! -l $dirOutNail && ! -d $dirOutNail){
    $cmd="mkdir $dirOutNail";
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
    $cmd="chmod go+r $dirOutNail";
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
}
				# folder for walk-through
$dirOutWalk=$dirOut.$par{"dirWalkRel"};
if (! -e $dirOutWalk && ! -l $dirOutWalk && ! -d $dirOutWalk){
    $cmd="mkdir $dirOutWalk";
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
    $cmd="chmod go+r $dirOutWalk";
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
}
   				# hack correct file names
foreach $file (@fileIn,@fileInNail){
    $file=~s/\/(\/)/$1/g;
}

   				# copy pictures to new
foreach $file (@fileIn){
    $file=~s/\/(\/)/$1/g;
    $fileTmp=$file;
    $fileTmp=~s/^.*\///g;
    $fileTmp=$dirOut.$fileTmp;
    $fileTmp=~s/\/(\/)/$1/g;
    next if (-e $fileTmp || -l $fileTmp);
    $cmd="\\cp $file ".$dirOut;
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
}
				# any files in the directory we do not already have?
if (! $Lisnew){
    undef %fileIn;
    foreach $file (@fileIn){
	$tmp=$file;
	$tmp=~s/^.*\///g;
	$fileIn{$tmp}=1;
    }
    $dir=$dirOut;
    print "--- readdir $dir\n"  if ($Lverb);
    opendir(DIR,$dir) || die ("-*- ERROR $scrName: failed opening dir(pred)=$dir!\n");
    @tmp=readdir(DIR);  
    closedir(DIR);

				# filter subdirectories
    $dir.="/"                   if ($dir !~/\/$/);
    $#tmp2=0;
    undef %tmp;
    foreach $tmp (@tmp) { 
	$tmp2=$dir.$tmp;
	next if (-d $tmp2);
	next if (! -e $tmp2);
	next if ($tmp=~/^\./);
	next if ($tmp2 !~ /\.(gif|jpg|jpeg)$/);
	push(@tmp2,$tmp2); 
	$tmp3=$tmp;
	$tmp3=~s/^.*\///g;
	$tmp{$tmp3}=1;
    }

    @tmp=@fileIn;
    foreach $tmp (@tmp2){
	$tmp3=$tmp;
	$tmp3=~s/^.*\///g;
	next if (defined $fileIn{$tmp3});
	push(@tmp,$tmp);
    }
    @fileIn=sort(@tmp);
    $#tmp=$#tmp2=0;
}

   				# copy nails to new
foreach $file (@fileInNail){
    $fileTmp=$file;
    $fileOriginal{$file}=$fileTmp;
    				# hack: change file name
    $dir=$fileTmp;
    $dir=~s/^(.*\/)([^\/]+)$/$1/;
    $name=$2;
    if ($name=~/_/){
	$name2=$name;
	$name2=~s/_/-/g;
	$fileTmp2=$dir.$name2;
	$cmd="\\mv ".$fileTmp." ".$fileTmp2;
	print "--- system '$cmd'\n"     if ($Ldebug);
#	print "xx before file=$file, new=$fileTmp2,\n";
	system("$cmd");
	$fileTmp=$file=$fileTmp2;
	$fileOriginal{$file}=$fileTmp2;
				# security: also one without dir
	$fileTmp3=$file;
	$fileTmp3=~s/^.*\///g;
	$fileOriginal{$fileTmp3}=$fileTmp2;
#	print "xx after  file=$file, new=$fileTmp2,\n";
    }
    else {
	print "xx nothing to do? file=$fileTmp,name=$name\n";
    }
    $fileTmp=~s/^.*\///g;
    $fileTmp=$dirOutNail.$fileTmp;
    next if (-e $fileTmp || -l $fileTmp);
    $file=~s/\/(\/)/$1/g;
    $cmd="\\cp $file ".$dirOutNail;
    system("$cmd");
    print "--- system '$cmd'\n"     if ($Ldebug);
}
foreach $file (@fileInNail){
    $file=~s/_/-/g;
}
    
if (0){
   				# block some files from public
    $fileInLoc=$par{"fileNopub"};
    open($fhin,$fileInLoc) ||
	die("*** ERROR $scrName: fileIn(nopub)=$fileInLoc, not opened\n");
    $dir="";
    $ctline=0;
    $par{"dirPhoto"}.="/"           if ($par{"dirPhoto"}!~/\/$/);
    $#block=0;
    while(<$fhin>){
	++$ctline;
	next if ($_=~/^\#/);
	next if ($_=~/^\s*$/);
	$_=~s/\n//g;
	if ($_=~/^dir=(\S+)/){
	    $dir=$par{"dirPhoto"}.$1;
	    $dir.="/"               if ($dir!~/\/$/);
	    next;
	}
	if (length($dir)<1){
	    die("*** ERROR $scrName: no dir in line=$ctline of file=$fileInLoc!\n");
	}
	$file=$_;
	$file=~s/\s//g;
	$file=$dir.$file;
	$block{$file}=1;
	push(@block,$file);
    }
    close($fhin);
   				# remove all blocked files
    foreach $file (@block){
	if (-e $file || -l $file){
	    print "--- $scrName remove $file (blocked from ".$par{"fileNopub"}.")\n" if ($Lverb);
	    unlink($file);
	}
	$tmp1=$file;
	$tmp2=$file;
	$tmp1=~s/(\/)[^\/]+$/$1/;
	$tmp2=~s/^.*\///g;
	$file=$tmp1.$par{"dirNailRel"}.$tmp2;
	if (-e $file || -l $file){
	    print "--- $scrName remove $file (blocked from ".$par{"fileNopub"}.")\n" if ($Lverb);
	    unlink($file);
	}
    }
}
				# ------------------------------
				# (2) get history
				# ------------------------------
if (-e $par{"fileOutHistory"}){
    open($fhin,$par{"fileOutHistory"}) ||
	die "*** ERROR $scrName: failed open fileOutHistory=".$par{"fileOutHistory"}."!\n";
    
    while(<$fhin>){
	next if ($_=~/^\#/);
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	push(@folderHistory,$tmp[1]);
	$npic{$tmp[1]}=$tmp[2];
    }
    close($fhin);
}
else {
    $#folderHistory=0;
}
   				# add new to history
push(@folderHistory,$title);
@folderHistory=sort(@folderHistory);
$npic{$title}=$#fileIn;

    				# avoid duplication
undef %tmp; 
$#tmp=0;
foreach $folder (@folderHistory){
    if (! defined $tmp{$folder}){
	$tmp{$folder}=1;
	push(@tmp,$folder);
    }
}
@folderHistory=@tmp;

				# avoid non pictures
$#tmp=0;
undef %tmp;
foreach $file (@fileIn){
    next if ($file !~/\.(jpg|gif|jpeg)/);
    next if (defined $tmp{$file});
    push(@tmp,$file);
}
@fileIn=@tmp;
				# ------------------------------
				# (3) write index.html for folder
				# ------------------------------
$fileOut=$dirOut."index.html";
open($fhout,">".$fileOut)|| 
    die "*** ERROR $scrName: failed open fileOut=$fileOut!\n";
($Lok,$msg)=
    &htmlIndexFolderHead($fhout,$title);

($Lok,$msg)=
    &htmlIndexFolderBody($fhout,$dirOutWalk,@fileIn);

($Lok,$msg)=
    &htmlIndexFolderFoot($fhout,$title);

close($fhout);

				# ------------------------------
				# (4) write new history
				# ------------------------------
open($fhout,">".$par{"fileOutHistory"}) ||
    die "*** ERROR $scrName: failed open fileOutHistory(new)=".$par{"fileOutHistory"}."!\n";
foreach $folder (@folderHistory){
    if (defined $npic{$folder}){
	print $fhout
	    $folder,$sep,$npic{$folder},"\n";
    }
    else {
	print "-*- WARN $scrName: missing number of pics for folder=$folder\n";
	print $fhout
	    $folder,$sep,"?","\n";
    }
}
close($fhout);
				# ------------------------------
				# (5) all in TAR
				# ------------------------------
chdir($par{"dirPhoto"});
$fileTar=$title.$par{"extTar"};
foreach $file ($fileTar,$fileTar.".gz",$dirOut.$fileTar,$dirOut.$fileTar.".gz"){
    next if (!-e $file && ! -l $file);
    unlink($file);
}

$dir2tar=$title."/";
$cmd=$par{"exeTar"}. " -cf " . $fileTar." ". $dir2tar;
print "--- system '$cmd'\n"     if ($Lverb);
system("$cmd");

if (! -e $fileTar){
    print "-*- oops trouble tar file=$fileTar missing (from system '$cmd')\n";
    exit;}

if ($par{"doGzip"}){
    $cmd=$par{"exeGzip"}. " -f " . $fileTar;
    print "--- system '$cmd'\n" if ($Lverb);
    system("$cmd");
    $fileTar.=".gz";
}
$cmd="\\mv ".$fileTar." ".$par{"dirArchive"};
print "--- system '$cmd'\n" if ($Lverb);
system("$cmd");

				# ------------------------------
				# (6) write main index.html
				# ------------------------------
$fileOut=$par{"dirPhoto"}."index.html";
open($fhout,">".$fileOut)|| 
    die "*** ERROR $scrName: failed open fileOut=$fileOut!\n";
($Lok,$msg)=
    &htmlIndexMainHead($fhout);

($Lok,$msg)=
    &htmlIndexMainBody($fhout);

($Lok,$msg)=
    &htmlIndexMainFoot($fhout);

close($fhout);

				# ------------------------------
				# (7) clean up new/ newnail/
				# ------------------------------
if ($Lclean){
    print "--- cleaning up \n";
    foreach $file (@fileOriginal){
	print "xx now file=$file\n";
	if ($file !~/$par{"dirNew"}/ &&
	    $file !~/$par{"dirNewNail"}/){
	    print "-*- skip from cleaning $file\n";
	    next;}
	if (-e $file || -l $file){
	    print "--- remove $file\n" if ($Ldebug);
	    unlink($file);
	}
	$filenodir=$file;
	$filenodir=~s/^.*\///g;
	
	next if (! defined $fileOriginal{$file} &&
		 ! defined $fileOriginal{$filenodir});
	if (defined $fileOriginal{$file}){
	    $file2=$fileOriginal{$file};
	    if ($file2 !~/new/){
		print "xx problem file2=$file2\n";
		next; 
	    }
	    if (-e $file2 || -l $file2){
		print "--- remove $file2\n" if ($Ldebug);
		unlink($file2);
	    }
	}
	if (defined $fileOriginal{$filenodir}){
	    $file2=$fileOriginal{$filenodir};
	    if ($file2 !~/new/){
		print "xx problem file2=$file2\n";
		next; 
	    }
	    if (-e $file2 || -l $file2){
		print "--- remove $file2\n" if ($Ldebug);
		unlink($file2);
	    }
	}

    }
}




exit;

#===============================================================================
sub htmlIndexFolderHead {
    local($fhoutLoc,$titleLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
#    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndexFolderHead                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlIndexFolderHead";
				# check arguments
    print $fhoutLoc
	"<HTML>\n",
	"<HEAD>\n",
	"<TITLE>\n",
	"\tPhotos for folder ".$par{"titleCentral"}.":".$titleLoc."\n",
	"<\/TITLE>\n",
	"<\/HEAD>\n",
	"<BODY BGCOLOR=\"WHITE\">\n",
	"\n";

    print $fhoutLoc
	"<CENTER>\n",
	"<A HREF=\"../index.html\">".$par{"titleCentral"}."<\/A>"." \&nbsp\; ",
	"<\/CENTER>\n";
    
    print $fhoutLoc
	"<CENTER><FONT SIZE=\"-1\">\n";

    foreach $folder (@folderHistory){
	$tmp=$folder;
	$tmp=~s/^.*\///g;
	$tmp2=$tmp;
	$tmp="../".$tmp;
	$tmp.="/index.html"     if ($tmp!~/index.html/);
	$tmp=~s/\/(\/)/$1/g;
	print $fhoutLoc
	    "<A HREF=\"".$tmp."\">".$tmp2."<\/A> \&nbsp\; ";
    }
    print $fhoutLoc
	"<\/FONT><\/CENTER>\n";

    return(1,"ok $sbrName");
}				# end of htmlIndexFolderHead

#===============================================================================
sub htmlIndexFolderBody {
    local($fhoutLoc,$dirOutWalkLoc,@fileTmpLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndexFolderBody                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlIndexFolderBody";
    $fhoutLoc2="FHOUT_"."htmlIndexFolderBody";
    				# sort files
    undef %tmp; $#tmp=0;
    foreach $tmp (@fileTmpLoc){
	$tmp2=$tmp;
	$tmp2=~s/^.*\///g;
	$tmp{$tmp2}=$tmp;
	push(@tmp,$tmp2);
    }
    @tmp=sort(@tmp);
    $#fileTmpLoc=0;
    foreach $tmp (@tmp){
	push(@fileTmpLoc,$tmp{$tmp});
    }
    $#tmp=0; undef %tmp;

    				# --------------------------------------------------
    				# (1) walk through talk
    
    				# output file names
    $#tmpnames=$#tmpnamesRel=0;
    $ct=0;
    foreach $file(@fileTmpLoc){
	++$ct;
	$fileOutTmp="0" x (3-length($ct)) . $ct;
	$fileOutTmp.=".html";
	$tmpnamesRel[$ct]=$fileOutTmp;
	$fileOutTmp=$dirOutWalkLoc.$fileOutTmp;
	$tmpnames[$ct]=$fileOutTmp;
    }
    $ct=0;
    $nfile=$#fileTmpLoc;
    				# write html page for each (into walk/)
    foreach $file(@fileTmpLoc){
	++$ct;
	$fileOutTmp=$tmpnames[$ct];
	open($fhoutLoc2,">".$fileOutTmp)||
	    return(0,"failed to open $fileOutTmp");
	$fileRel=$file;
	$fileRel=~s/^.*\///g;
	$fileRel="../".$fileRel;
	$filePrev=$file;
	$fileNext=$file;

	if    ($ct>1 && $ct < $nfile){
	    $filePrev=$tmpnamesRel[$ct-1];
	    $fileNext=$tmpnamesRel[$ct+1];
	}			# 
	elsif ($ct>1 && $ct == $nfile){
	    $filePrev=$tmpnamesRel[$ct-1];
	    $fileNext=$tmpnamesRel[1]; # 
	}
	elsif ($ct==1 && $ct < $nfile){
	    $filePrev=$tmpnamesRel[$nfile];
	    $fileNext=$tmpnamesRel[$ct+1];
	}

	print $fhoutLoc2
	    "<HTML><HEAD><TITLE>".$title."-".$ct."</TITLE></HEAD><BODY BGCOLOR=WHITE>\n",
	    "<A HREF=\""."../index.html"."\">INDEX</A> <BR>",
	    "<A HREF=\"".$filePrev."\" ALT=PREVIOUS><IMG SRC=\"".$par{"fileIconBackRel"}."\">   \&nbsp\; PREVIOUS</A><BR> ",
	    "<A HREF=\"".$fileNext."\" ALT=NEXT>    <IMG SRC=\"".$par{"fileIconForwardRel"}."\">\&nbsp\; NEXT</A> <BR> ",
	    "<P>\&nbsp\;</P>\n",
	    "<A HREF=\"".$fileRel."\"><IMG SRC=\"".$fileRel."\"></A>\n",
	    "<P>\&nbsp\;</P>\n",
	    "<A HREF=\""."../index.html"."\">INDEX</A> <BR>",
	    "<A HREF=\"".$filePrev."\" ALT=PREVIOUS><IMG SRC=\"".$par{"fileIconBackRel"}."\">   \&nbsp\; PREVIOUS</A> <BR> ",
	    "<A HREF=\"".$fileNext."\" ALT=NEXT>    <IMG SRC=\"".$par{"fileIconForwardRel"}."\">\&nbsp\; NEXT</A> <BR> ",
	    "</BODY></HTML>\n";
	close($fhoutLoc2);
    }

    				# ------------------------------
    				# (2) entire thing
    $fileOutTmp=$par{"titleAllinone"}.$par{"extHtml"};
    open($fhoutLoc2,">".$dirOut.$fileOutTmp)||
	return(0,"failed to open $dirOut$fileOutTmp");
    print $fhoutLoc2
       "<HTML><HEAD><TITLE>".$title."-".$ct."</TITLE></HEAD><BODY BGCOLOR=WHITE>\n",
       "<A HREF=\""."../index.html"."\">INDEX</A>\n",
       "<BR>\n";

       				# make table
    print $fhoutLoc2
       "<TABLE BORDER=0 CELLSPACING=3 CELLPADDING=3 COLS=".$par{"picPerLane"}.">\n",
       "\n";
       
    for ($it=1;$it<=$nfile;$it+=$par{"picPerLane"}){
	print $fhoutLoc2
	    "<TR>";

	foreach $it2(0..($par{"picPerLane"}-1)){
	    $ct=$it+$it2;
	    last if ($ct > $nfile);
	    $file=$fileTmpLoc[$ct];
	    $file=~s/^.*\///g;
	    $fileNail=   $dirOutNail.$file;
	    $fileNailRel=$par{"dirNailRel"}.$file;
	    $tmpname=$file;
	    $tmpname=~s/^.*\///g;
	    $tmpname=~s/\..*$//g;
	    if (! -e $fileNail && ! -l $fileNail){
		$cmd="\\cp ".$dirOut.$file." ".$par{"dirDoNail"};
		system("$cmd");
		print "--- system '$cmd'\n" if ($Lverb);
		print $fhoutLoc2
		    "\t<TD ALIGN=CENTER VALIGN=MIDDLE>",
		    "<A HREF=\"".$file."\"><IMG SRC=\"".$file."\" HEIGHT=".$par{"height"}." WIDTH=".$par{"width"}.
		    " ALT=\"CDonly\"></A>",
		    "<BR><FONT SIZE=\"-1\">",$tmpname,"</FONT>",
		    "</TD>\n";
	    }
	    else {
		print $fhoutLoc2
		    "\t<TD ALIGN=CENTER VALIGN=MIDDLE>",
		    "<A HREF=\"".$file."\"><IMG SRC=\"".$fileNailRel."\" ALT=\"CDonly\"></A>",
		    "<BR><FONT SIZE=\"-1\">",$tmpname,"</FONT>",
		    "</TD>\n";
	    }
		    
	}
	print $fhoutLoc2
	    "<\/TR>\n";
    }
    print $fhoutLoc2
       "</TABLE>\n",
       "<BR><A HREF=\""."../index.html"."\">INDEX</A>\n",
       "</BODY></HTML>\n";
    close($fhoutLoc2);
    
    				# ------------------------------
    				# (3) finally the index
    $filetmp=$fileOutTmp;
    $filetmp=~s/^.*\///g;
    $fileArchiveTmp=$par{"dirArchiveRel"}.$title.$par{"extTar"};
    $fileArchiveTmp.=$par{"extGzip"} if ($par{"doGzip"});

    print $fhoutLoc
	"<UL>\n",
	"<LI><A HREF=\"walk/001.html\">Walk through current folder, one by one</A></LI>\n",
	"<LI><A HREF=\"".$filetmp."\">All photos of current folder in one file</A></LI>\n",
	"<LI><A HREF=\"".$fileArchiveTmp."\">All photos and web pages in tar archive</A></LI>\n",
	"</UL>\n",
	"\n";

    return(1,"ok $sbrName");
}				# end of htmlIndexFolderBody

#===============================================================================
sub htmlIndexFolderFoot {
    local($fhoutLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
#    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndexFolderFoot                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlIndexFolderFoot";

    print $fhoutLoc
	"<\/BODY>\n",
	"<\/HTML>\n";

    return(1,"ok $sbrName");
}				# end of htmlIndexFolderFoot



#===============================================================================
sub htmlIndexMainHead {
    local($fhoutLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndexMainHead                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlIndexMainHead";

    print $fhoutLoc
	"<HTML>\n",
	"<HEAD>\n",
	"<TITLE>\n",
	"\tRost: ".$par{"titleCentral"}."\n",
	"<\/TITLE>\n",
	"<\/HEAD>\n",
	"<BODY BGCOLOR=\"WHITE\">\n",
	"\n";

    print $fhoutLoc
	"<CENTER> ",
	"<A HREF=\"".$par{"www"}."\">".$par{"www"}."<\/A> ",
	"<\/CENTER>\n";
    
    print $fhoutLoc
	"<CENTER><FONT SIZE=\"-1\"> ";

    foreach $folder (@folderHistory){
	$tmp=$folder;
	$tmp=~s/^.*\///g;
	$tmp2=$tmp;
	$tmp.="/index.html"     if ($tmp!~/index.html/);
	$tmp=~s/\/(\/)/$1/g;
	print $fhoutLoc
	    "<A HREF=\"".$tmp."\">".$tmp2."<\/A> \&nbsp\; ";
    }
    print $fhoutLoc
	"<\/FONT><\/CENTER>\n";


    return(1,"ok $sbrName");
}				# end of htmlIndexMainHead

#===============================================================================
sub htmlIndexMainBody {
    local($fhoutLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
#    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndexMainBody                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlIndexMainBody";

    print $fhoutLoc
       "<H2>".$par{"titleCentral"}."</H2>\n";

    print $fhoutLoc
       "<TABLE BORDER=1 CELLSPACING=3 CELLPADDING=3 COLS=4>\n",
       "\n";

    print $fhoutLoc
       "<TR>",
       "<TH ALIGN=LEFT  VALIGN=MIDDLE>Folder</TH>",
       "<TH ALIGN=RIGHT VALIGN=MIDDLE>Number of photos</TH>",
       "<TH ALIGN=LEFT  VALIGN=MIDDLE>Archive of all pages</TH>",
       "<TH ALIGN=RIGHT VALIGN=MIDDLE>Size of archive <BR><FONT SIZE=\"-1\">in MegaByte!</FONT></TH>",
       "</TR>\n";

       				# all folders
    $sumNpic=$sumSize=0;
    $dirArchiveLoc=$par{"dirArchive"};
    $dirArchiveLoc=~s/$par{"dirPhoto"}//g;
    $dirArchiveLoc="./".$dirArchiveLoc;

    foreach $folder (@folderHistory){
	$npic="?";
	if (defined $npic{$folder}){
	    $npic=$npic{$folder};
	    $sumNpic+=$npic;}

	$fileArchiveTmp=$dirArchiveLoc.$folder.$par{"extTar"};
	$fileArchiveTmp.=$par{"extGzip"} if ($par{"doGzip"});
	if (-e $fileArchiveTmp || -l $fileArchiveTmp){
	    ($tmp,$tmp,$tmp,$tmp,$tmp,$tmp,$tmp,
	     $tmpsize,@tmp)=stat ($fileArchiveTmp);
	    if ($tmpsize < 1000000){
		$tmpsize=$tmpsize/1000000;
		$tmpsize=~s/^([\-\d]+\.\d\d).*$/$1/;}
	    else {
		$tmpsize=int($tmpsize/1000000);
	    }
	    $tmpwrt_size=$tmpsize;
	    $sumSize+=$tmpsize;
	}
	else {
	    $tmpwrt_size="?";}
       
	$folder=~s/^.*\///g;
	print $fhoutLoc
	    "<TR>",
	    "<TD ALIGN=LEFT  VALIGN=MIDDLE><A HREF=\"".$folder."/index.html\">".$folder."</A></TD>",
	    "<TD ALIGN=RIGHT VALIGN=MIDDLE>".$npic."</TD>",
	    "<TD ALIGN=LEFT  VALIGN=MIDDLE><A HREF=\"".$fileArchiveTmp."\">".$fileArchiveTmp."</A></TD>",
	    "<TD ALIGN=RIGHT VALIGN=MIDDLE>".$tmpwrt_size."</TD>",
	    "</TR>\n";
    }
    print $fhoutLoc
	"<TR>",
	"<TD ALIGN=LEFT  VALIGN=MIDDLE><I>SUM</I></TD>",
	"<TD ALIGN=RIGHT VALIGN=MIDDLE><I>".$sumNpic."</I></TD>",
	"<TD ALIGN=LEFT  VALIGN=MIDDLE><I> </I></TD>",
	"<TD ALIGN=RIGHT VALIGN=MIDDLE><I>".$sumSize."</I></TD>",
	"</TR>\n";
    print $fhoutLoc
       "</TABLE>\n";

     return(1,"ok $sbrName");
}				# end of htmlIndexMainBody

#===============================================================================
sub htmlIndexMainFoot {
    local($fhoutLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
#    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndexMainFoot                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlIndexMainFoot";

    print $fhoutLoc
	"<\/BODY>\n",
	"<\/HTML>\n";

    return(1,"ok $sbrName");
}				# end of htmlIndexMainFoot


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

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd


