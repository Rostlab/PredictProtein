#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal=  "gets file with columns, compiles fringe (27.5) + annual increase (3)\n";
$scrGoal.= "     \t \n";
$scrGoal.= "     \t format of file to input:\n";
$scrGoal.= "     \t \n";
$scrGoal.= "     \t item TAB money TAB years\n";
$scrGoal.= "     \t Prost TAB(100%) all            (MUST be rost in des)\n";
$scrGoal.= "     \t Pstudent\n";
$scrGoal.= "     \t Px\n";
$scrGoal.= "     \t Oother \n";
$scrGoal.= "     \t E-equipment TAB 30000 1,2 \n";
$scrGoal.= "     \t \n";
$scrGoal.= "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'fringe',     27.5,	# 
      'annual',     3,		# percentage annual increase
      '', "",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
$sep=   "\t";

				# ------------------------------
if ($#ARGV<3 ||			# help
	$ARGV[1] =~/^(-h|help|special)$/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName Nyears file n' (n= percentage of my time)\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
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
$nyear=  0;
$me=     0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^(\d+)$/ && 
	   $arg eq $ARGV[3])              { $me=       $1;}
    elsif ($arg=~/^(\d+)$/)               { $nyear=          $1;}
    elsif ($arg=~/^me=(.*)$/)             { $me=             $1;}
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
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$#person=$#other=$#equipment=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    while (<$fhin>) {
	last if ($_=~/\#\s*end/i);
	$_=~s/\n//g;
	$line=$_;
	next if ($_=~/^\s*\#/);	# skip comments
	next if ($_=~/^\s*$/);	# skip empty
	next if ($_=~/^item/);	# skip names

	$_=~s/\#.*$//g;		# purge after comment
	($item,$money,$year)=split(/\s*\t\s*/,$_);  
				# purge commata
	$money=~s/,//g;
	die "*** ERROR line=$line, no money\n" if (! defined $money);
	    
	if    ($item=~/^P(\S+.*)/){
	    $kwd=$1;
	    $kwd=~s/[\s,]/_/g;
				# purge strange characters
	    $kwd=~s/[\(\)\%].*$//g;
	    $kwd=~s/^[_\-]|[_\-]$//g;
	    push(@person,$kwd);
	    if ($item=~/rost/){
		$kwdpart="rost_".$me;
		push(@person,$kwdpart);
		$rd{$kwdpart,"des"}=  "Prost_".$me;
		$rd{$kwdpart,"money"}=$money*$me/100;
		$rd{$kwdpart,"year"}= "all";
	    }}
	elsif ($item=~/^O(\S+.*)/){
	    $kwd=$1;
	    $kwd=~s/[\s,]/_/g;
	    push(@other,$kwd);}
	elsif ($item=~/^E(\S+.*)/){
	    $kwd=$1;
	    $kwd=~s/[\s,]/_/g;
	    push(@equipment,$kwd);}
	$rd{$kwd,"des"}=  $item;
	$rd{$kwd,"money"}=$money;
	$rd{$kwd,"year"}= $year;
    }
    close($fhin);
}
				# ------------------------------
				# (2) process stuff
				# ------------------------------
foreach $kwd (@person){
				# skip me with 100
    if ($kwd=~/rost/ && $kwd !~/$me/){
	$rd{$kwd,"sum",1}=      $rd{$kwd,"money"};

	$rd{$kwd,"fringe"}=0;
	foreach $it (2..$nyear){
	    $rd{$kwd,"sum",$it}=$rd{$kwd,"sum",($it-1)}*(100+$par{"annual"})/100;
	}
	next; }
				# no fringe on students
    if ($kwd =~ /student/){
	$rd{$kwd,"fringe"}=0;}
    else {
	$rd{$kwd,"fringe"}=$rd{$kwd,"money"}*$par{"fringe"}/100;
    }
				# FRINGE old fringe into salary
#    $rd{$kwd,"sum",1}=$rd{$kwd,"money"}+$rd{$kwd,"fringe"};
				# FRINGE new fringe extra
    $rd{$kwd,"sum",1}=$rd{$kwd,"money"};
    $rd{"fringe","sum",1}=0     if (! defined $rd{"fringe","sum",1});
    $rd{"fringe","sum",1}+=$rd{$kwd,"fringe"};
#    print "xx kwd=$kwd, fringe=",$rd{$kwd,"fringe"},", mone=",$rd{$kwd,"money"},", sum=",$rd{"fringe","sum",1},"\n";

				# all other years
    foreach $it (2..$nyear){
	$rd{$kwd,"sum",$it}=$rd{$kwd,"sum",($it-1)}*(100+$par{"annual"})/100;
    }
}
				# FRINGE new fringe extra, get annual increas
foreach $it (2..$nyear){
    $rd{"fringe","sum",$it}=$rd{"fringe","sum",($it-1)}*(100+$par{"annual"})/100;
}

foreach $kwd (@other,@equipment){
				# get sum year one
    $rd{$kwd,"sum",1}=$rd{$kwd,"money"};
    undef %tmp;			# wanted for all years
    if ($rd{$kwd,"year"}=~/^a/){
	@yearWant=(1..$nyear);}
				# wanted for some years
    else{
	$rd{$kwd,"year"}=~s/\s//g;
	@tmp=     split(/,/,$rd{$kwd,"year"});
	$#yearWant=0;
	foreach $tmp (@tmp){
	    if    ($tmp=~/^\d+$/) {
		push(@yearWant,$tmp);}
				# is range
	    elsif ($tmp=~/^(\d+),(\d+)$/){
		foreach $it ($1 .. $2){
		    push(@yearWant,$it);
		}}
	    else {
		print "*** ERROR year ($kwd)=",$rd{$kwd,"year"},"?\n";
		exit;}
	}
    }
    undef %tmp;
    foreach $year (@yearWant){
	$tmp{$year}=1;
    }
				# equipment: split into years, no increase
    if ($rd{$kwd,"des"} =~ /^E/){
	$money4one=$rd{$kwd,"money"}/$#yearWant;
	foreach $it (1..$nyear){
	    if (! defined $tmp{$it}){
		$rd{$kwd,"sum",$it}=0;}
	    else{
		$rd{$kwd,"sum",$it}=$money4one;}
	}
    }
				# all others: increase annually
    else {
				# first as given
	$rd{$kwd,"sum",1}=$rd{$kwd,"money"};
	undef %tmp;
	foreach $year (@yearWant){
	    $tmp{$year}=1;
	}
				# all others: increase annually
	foreach $it (2..$nyear){
	    next if (! defined $tmp{$it});
	    $rd{$kwd,"sum",$it}=$rd{$kwd,"sum",($it-1)}*(100+$par{"annual"})/100;
	}}
}
				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout
    "item",$sep,"original",$sep,"fringe";
foreach $it (1..$nyear){
    print $fhout
	$sep,"sum_year_".$it;
}
print $fhout
    $sep,"sum_years (1-$nyear)",$sep,"sum_average","\n";

$tmpwrt=sprintf("%-35s"."    year %1s" x $nyear ." %10s %10s\n",
		"item",(1..$nyear),"sum $nyear yrs","ave $nyear yrs");

$sum=0;
$sum{"fringe"}=0;
$sum{"money"}= 0;
foreach $it (1..$nyear){
    $sum{"year",$it}=0;
}

foreach $kwd (@person){
				# empty line before my x%
    if ($kwd =~/rost.*$me/){
	$tmpwrt2="-" x 35 ."\n";
#	$tmpwrt2=sprintf("%-35s". "%-s" x ($nyear+3) ."\n",
#			 "------------------------------","" x ($nyear+3));
	print $fhout $tmpwrt2;
	$tmpwrt.=$tmpwrt2;
    }
    print $fhout 
	$rd{$kwd,"des"},$sep,$rd{$kwd,"money"};

    $sum{$kwd}=0;
    $tmpwrt.=sprintf("%-35s",$rd{$kwd,"des"});
    foreach $it (1..$nyear){
	$tmp=0;
	$tmp=$rd{$kwd,"sum",$it} if (defined $rd{$kwd,"sum",$it});
				# trim
	$tmp=~s/(\.\d\d).*$/$1/;
	print $fhout $sep,$tmp;
	$tmpwrt.=sprintf("%10d",int($tmp));
	$sum{$kwd}+=$tmp;
	next if ($kwd =~ /rost/ && $kwd !~ /$me/);
	$sum{"year",$it}+=$tmp;
    }
				# trim
    $sum{$kwd}=~s/(\.\d\d).*$/$1/;
    $ave{$kwd}=$sum{$kwd} / $nyear;
    $ave{$kwd}=~s/(\.\d\d).*$/$1/;

    print $fhout $sep,$sum{$kwd},$sep,$ave{$kwd},"\n";
    $tmpwrt.=sprintf(" %10d %10d\n",int($sum{$kwd}),int($ave{$kwd}));
}
				# compile fringe
print $fhout 
    "Fringe",$sep,$par{"fringe"};

$kwd="fringe";
$sum{$kwd}=0;
$tmpwrt.=sprintf("%-35s","Fringe");
foreach $it (1..$nyear){
    $tmp=0;
    $tmp=$rd{$kwd,"sum",$it} if (defined $rd{$kwd,"sum",$it});
				# trim
    $tmp=~s/(\.\d\d).*$/$1/;
    print $fhout $sep,$tmp;
    $tmpwrt.=sprintf("%10d",int($tmp));
    $sum{$kwd}+=$tmp;
    $sum{"year",$it}+=$tmp;
}
				# trim
$sum{$kwd}=~s/(\.\d\d).*$/$1/;
$ave{$kwd}=$sum{$kwd} / $nyear;
$ave{$kwd}=~s/(\.\d\d).*$/$1/;

print $fhout $sep,$sum{$kwd},$sep,$ave{$kwd},"\n";
$tmpwrt.=sprintf(" %10d %10d\n",int($sum{$kwd}),int($ave{$kwd}));



foreach $kwd (@other,@equipment){
    print $fhout 
	$rd{$kwd,"des"},$sep,"0";
    $tmpwrt.=sprintf("%-35s",$rd{$kwd,"des"});

    $sum{$kwd}=0;
    foreach $it (1..$nyear){
	$tmp=0;
	$tmp=$rd{$kwd,"sum",$it} if (defined $rd{$kwd,"sum",$it});
				# trim
	$tmp=~s/(\.\d\d).*$/$1/;
	print $fhout $sep,$tmp;
	$sum{$kwd}+=$tmp;
	$sum{"year",$it}+=$tmp;
	$tmpwrt.=sprintf("%10d",int($tmp));
    }
				# trim
    $sum{$kwd}=~s/(\.\d\d).*$/$1/;
    $ave{$kwd}=$sum{$kwd} / $nyear;
    $ave{$kwd}=~s/(\.\d\d).*$/$1/;

    print $fhout $sep,$sum{$kwd},$sep,$ave{$kwd},"\n";
    $tmpwrt.=sprintf(" %10d %10d\n",int($sum{$kwd}),int($ave{$kwd}));
}

				# sum over all columns

print $fhout
    "sum",$sep,$sum{"money"},$sep,$sum{"fringe"};

$tmpwrt.="-" x 35 ."\n";
$tmpwrt.=sprintf("%-35s","SUMS");
#$tmpwrt.="-" x 100 ."\n".sprintf("%-35s","SUMS");

$sum=0;
foreach $it (1..$nyear){
    $sum{"year",$it}=~s/(\.\d*\d*).*$/$1/;
    $sum+=$sum{"year",$it};
    print $fhout
	$sep,$sum{"year",$it};
    $tmpwrt.=sprintf("%10d",int($sum{"year",$it}));
}
$ave=$sum/$nyear; 
$ave=~s/(\.\d*\d*).*$/$1/;

print $fhout
    $sep,$sum,$sep,$ave,"\n";

$tmpwrt.=sprintf(" %10d %10d\n",int($sum),int($ave));

close($fhout);

print $tmpwrt ;

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
