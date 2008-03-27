#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "file* <pre|adjust|pre=VAL|old=VAL new=VAL|add=VAL(before ext .jpg|.gif)|ext=x|cut=to-delete|count=pre(will name it 'preDDD')>";
$scrGoal="renames a list of files\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t NOTE:   use 'test' for test run\n".
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
#				version 0.1   	Sep,    	2002	       #
#------------------------------------------------------------------------------#
#
				# 
$[=1; #]				# count from one ]


				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
#  $sep=   "\t";
$increment=1;
  
				# ------------------------------
if ($#ARGV<2 ||	        	# help
      $ARGV[1] =~/^(-h|help|special)/){
      print  "goal: $scrGoal\n";
      print  "use:  '$scrName $scrIn'\n";
      print  "opt:  \n";
				#      'keyword'   'value'    'description'
      printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
      printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
      
      printf "%5s %-15s=%-20s %-s\n","","count",    "x",      "will do 'x' and then count increment=$increment";
      printf "%5s %-15s %-20s %-s\n","","",        "",         "note if 'count=title0040' then will begin counting from 40";
      printf "%5s %-15s=%-20s %-s\n","","pre|adjust",      " ",      "kwd pre alone-> adjust numbers 1,10 -> 01,10 (assumption: differ only in the end, i.e. NOT file1xyz.tmp file10xyz.tmp!)";
      printf "%5s %-15s=%-20s %-s\n","","pre",      "x",      "prepends x";
      printf "%5s %-15s=%-20s %-s\n","","old",      "x",      "replaces pattern 'x' in fileIn";
      printf "%5s %-15s=%-20s %-s\n","","new",      "x",      " .. by patter 'x' in new fileOut";
      printf "%5s %-15s=%-20s %-s\n","","ext",      "x",      "adds 'x' at end!";
      printf "%5s %-15s=%-20s %-s\n","","add",      "x",      "adds 'x' before extension!";
      printf "%5s %-15s=%-20s %-s\n","","tst",      "no val", "only test run nothing done, just check it out";
      printf "%5s %-15s=%-20s %-s\n","","cut",      "x",      "removes pattern x from file";

      printf "%5s %-15s=%-20s %-s\n","","increment","n",      "counter will increment numbers by this";
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
      exit;
}
				# initialise variables
#	$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$dirOut=0;
$pre="";		# 
$add="";
$old="";
$new="";
$Ladjust=0;		# if 1: 1,10->01,10
$extDef="";

				# ------------------------------
				# read command line
$Ltest=0;
$cut="";
$count="";

foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;
					    $Ldebug=         0;}

    elsif ($arg=~/^(pre|adjust)$/)        { $Ladjust=        1;}
    elsif ($arg=~/^pre=(.*)$/)            { $pre=            $1;
					    $pre=~s/\///g;      }
    elsif ($arg=~/^count=(.*)$/)          { $count=          $1;
					    $count=~s/\///g;    }
    elsif ($arg=~/^beg=(.*)$/)            { $count=          $1;
					    $count=~s/\///g;    }
    elsif ($arg=~/^(add|app)=(.*)$/)      { $add=            $2;}

    elsif ($arg=~/^old=(.*)$/)            { $old=            $1;}
    elsif ($arg=~/^new=(.*)$/)            { $new=            $1;}
    elsif ($arg=~/^cut=(.*)$/)            { $cut=            $1;}
    elsif ($arg=~/^ext=(.*)$/)            { $extDef=         $1;}
    
    elsif ($arg=~/^increment=(\d+)$/)     { $increment=      $1;}
    elsif ($arg=~/^(it|iter|step)=(\d+)$/){ $increment=      $2;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^(tst|test)$/)          { $Ltest=          1;
					    $Ldebug=         1;
					    $Lverb=          1; }
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
				# (1) read file(s)
				# ------------------------------

				# set counter
if (length($count)){
    if ($count=~/(\d+)$/){
	$num=$1;
	$count=~s/$num//;
	$digits=length($num);
	$beg=$num;
	$beg=~s/^0//g;
#	print "xx num=$num dig=$digits, beg=$beg, count=$count\n";
    }
    else {
	$beg=0;
	$digits=length($increment*$#fileIn);
    }
    $ext=$fileIn[1];
    $ext=~s/^.*(\.[^\.]+)$/$1/;
}
$ct=$beg;

    				# adjust sorting of input files?
if (0 && $Ladjust){
    $len=$lenmax=0;$lenmin=1000;
    foreach $fileIn (@fileIn){
	$len=length($fileIn);
	if ($len>$lenmax){
	    $lenmax=$len;
#	    $examax=$fileIn;
	}
	if ($len<$lenmin){
	    $lenmin=$len;
#	    $examin=$fileIn;
	}
    }
    if ($lenmin<$lenmax){
	$#tmp=0;
	undef %tmp;
	foreach $fileIn (@fileIn){
	    $len=length($fileIn);
	    if ($len<$lenmax){
		$tmp=$fileIn;
		$tmpadd="0" x ($lenmax-$len);
		$tmp=~s/(\d+\..*$)/$tmpadd$1/;
		push(@tmp,$tmp);
		$tmp{$tmp}=$fileIn;
	    }
	    else {
		push(@tmp,$fileIn);
		$tmp{$fileIn}=$fileIn;
	    }
	}
	$#tmp2=0;
	foreach $tmp (sort(@tmp)){
	    push(@tmp2,$tmp{$tmp});
	}
	@fileIn=@tmp2;
	$#tmp=0;
	$#tmp2=0;
	undef %tmp;
    }
}

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    				# macintosh specific: remove spaces from name
    if ($fileIn=~/\s/){
	$tmp=$fileIn;
	$tmp=~s/\s//g;
	system("\\mv '$fileIn' $tmp");
	$fileIn=$tmp;
    }
    				# case count: priority
    $fileOut=$fileIn;
    if (length($count)){
	$ct+=$increment;
	$tmp= $count;
	$tmp.="0" x ($digits-length($ct)) if ($digits>length($ct));
	$tmp.=$ct.$ext;
	$fileOut=$tmp;
#	print "xx 1 fileout=$fileOut\n";
    }

    else {
	if (length($old)){
	    $fileOut=~s/$old/$new/g;
	}
	if (length($pre)){
	    $fileOut=$pre.$fileOut;
	}
	if (length($add)){
	    $tmp1=$fileOut;
	    $tmp2=$fileOut;
	    if ($tmp2=~/\..*$/){
		$tmp1=~s/(\.[^\.]+)$//;
		$tmp2=~s/^.*(\.[^\.]+)$/$1/;
		$fileOut=$tmp1.$add;
		$fileOut.=$tmp2
	    }
	    else{
		$fileOut.=$add;
	    }
	}
	if (length($cut)){
	    $fileOut=~s/$cut//g;
	}
#	print "xx 2 cut=$cut, add=$add, pre=$pre, old=$old fileout=$fileOut\n";
    }
    				# change extensions
    if    ($fileOut=~/\.JPG/){
	$fileOut=~s/\.JPG/\.jpg/;
    }
    elsif ($fileOut=~/\.jpeg/i){
	$fileOut=~s/\.jpeg/\.jpg/i;
    }
    $fileOut.=$extDef           if (length($extDef)>0);

    $cmd="\\mv $fileIn $fileOut";
    if (-e $fileOut || -l $fileOut){
	print "*** big problem wants to do overwrite $fileOut ($cmd)\n";
	exit;}
    print "--- system '$cmd'\n" if ($Lverb);
    next if ($Ltest);
    system("$cmd");
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

