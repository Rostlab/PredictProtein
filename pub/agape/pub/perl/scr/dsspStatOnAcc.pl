#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compiles statistics on buried/exposed\n".
    "     \t input:  file from dsspExtrSeqSecAcc.pl file-dssp.list accrel\n".
    "     \t output: stat\n".
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
#				version 0.1   	Jul,    	2002	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one
#$x1="xx" ;$x2="x";
#print "12 $x1 matches $x2" if ($x1=~/$x2/);
#print "21 $x2 matches $x1" if ($x2=~/$x1/);
#die;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
$Lverb2=0;
				# % relative accessibility to distinguish
				# output = cumulative
@inter=("0","5","9","16","25","36","49","100");
@inter=("0","5","16","100");
@inter=("0","100");
@inter=("0","1","4","9","16","25","36","49","100");
#@inter=("16","100");

$aatxt="ACDEFGHIKLMNPQRSTVWY";
@aa=split(//,$aatxt);

@class=("KL","DE");

				# minimal length of protein
$lenMin=30;

$sep="\t";
#$sep=" ";


				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
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
    printf "%5s %-15s %-20s %-s\n","","verb2",    "no value","more verbose";
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
    elsif ($arg=~/^verb2$|^det$/)         { $Lverb2=         1;
					    $Lverb=          1;}
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
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    undef %res;
    $#id=0;
    while (<$fhin>) {
	next if ($_=~/^id/);
	$_=~s/\n//g;
	@tmp=split(/\s*\t\s*/,$_);
	$id=$tmp[1];
#	if (defined $res{$id,"len"}){
#	    $id.="xx";
#	}
	next if (defined $res{$id,"len"});
	push(@id,$id);
	$res{$id,"len"}=$tmp[2];
	@aard= split(//,$tmp[3]);
	@accrd=split(/,/,$tmp[5]);
	$res{$id,"leneff"}=0;
	foreach $it (1..$#aard){
	    next if (! defined $aard[$it] || ! defined $accrd[$it] ||
		     $aard[$it]!~/^[ABCDEFGHIKLMNPQRSTVWYZ]$/ ||
		     $accrd[$it]!~/^\d+$/);
	    ++$res{$id,"leneff"};
				# ini
	    $res{$id,$aard[$it],$accrd[$it]}=0 if (! defined $res{$id,$aard[$it],$accrd[$it]});
	    $res{$id,$accrd[$it]}=0            if (! defined $res{$id,$accrd[$it]});
	    $res{$id,$aard[$it]}= 0            if (! defined $res{$id,$aard[$it]});

	    ++$res{$id,$aard[$it],$accrd[$it]};
	    ++$res{$id,$accrd[$it]};
	    ++$res{$id,$aard[$it]};
	}
    }
    close($fhin);
}
				# ------------------------------------------------------------
				# (2) sum values
				# ------------------------------------------------------------
foreach $id (@id){
				# ------------------------------
				# first sum residues to include in stuff
    $leneff=0;
    $#aaok=0;
    foreach $aa (@aa){
	next if (! defined $res{$id,$aa});
	push(@aaok,$aa);
	$leneff+=$res{$id,$aa};
    }
				# ------------------------------
				# now group by acids
    foreach $sym (@class){
	$res{$id,"sum",$sym}=0;
	foreach $aa (@aaok){
	    next if ($sym !~/$aa/);
	    $res{$id,"sum",$sym}+=$res{$id,$aa};
#	    print "xx aa($aa)=",$res{$id,$aa},", sum($sym)=",$res{$id,"sum",$sym},"\n";
	}
    }
				# ------------------------------
				# now group by accessibility
    $cum=0;
    $#relok=0;
    foreach $rel (@inter){
				# ini
	if    ($rel==0){
	    $res{$id,"sum",$rel}=0;}
	elsif ($rel==$inter[1]){
	    $res{$id,"sum",$rel}=0;
	    $prev=0;}
				# if starting from 0
	if ($rel==0){
	    if (defined $res{$id,$rel} && $res{$id,$rel}){
		$cum=$res{$id,"sum",$rel}=$res{$id,$rel};
		push(@relok,$rel);}
	}
				# else sum
	else {
	    $loc=0;
	    foreach $rel2 (($prev+1)..$rel){
		next if (! defined $res{$id,$rel2});
		push(@relok,$rel2);
		$loc+=$res{$id,$rel2};
	    }
	    $cum+=$loc;
	    $res{$id,"sum",$rel}=$cum;
	}
	$prev=$rel;
#	print "xx loc=$loc, cum($rel)=$cum\n";
    }				# end of all intervals to consider

				# ------------------------------
				# now group by accessibility interval AND acid type

				# 1. by acids
    foreach $sym (@class){
	@aaoktmp=split(//,$sym);
				# now all acc
	foreach $rel (@relok){
	    $tmp{$sym,$rel}=0;
	    foreach $aa (@aaoktmp){
		next if (! defined $res{$id,$aa,$rel});
		$tmp{$sym,$rel}+=$res{$id,$aa,$rel};
	    }
	}
    }
    foreach $sym (@class){
	foreach $rel (@relok){
	    $res{$id,$sym,$rel}=$tmp{$sym,$rel};
	}}

				# 2. in intervals
    foreach $sym (@class){
	$cum=0;
	foreach $rel (@inter){
				# ini
	    if    ($rel==0){
		$res{$id,"sum",$sym,$rel}=0;}
	    elsif ($rel==$inter[1]){
		$res{$id,"sum",$sym,$rel}=0;
		$prev=0;}
				# if starting from 0
	    if ($rel==0){
		$cum=$res{$id,"sum",$rel}=
		    $res{$id,$sym,$rel}  if (defined $res{$id,$sym,$rel} && $res{$id,$sym,$rel});
	    }
				# else sum
	    else {
		$loc=0;
		foreach $rel2 (($prev+1)..$rel){
		    next if (! defined $res{$id,$sym,$rel2});
		    $loc+=$res{$id,$sym,$rel2};
		}
		$cum+=$loc;
		$res{$id,"sum",$sym,$rel}=$cum;
	    }
	    $prev=$rel;
#	    print "xx sym=$sym, loc=$loc, cum($rel)=$cum\n";
	}			# end of acc
    }				# end of acc + acid
}		 
		 
    

				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";

$#tmp=0;
@tmp=("id","len");
foreach $sym (@class){
    push(@tmp,$sym);
}
foreach $rel (@inter){
    push(@tmp,"%".$rel);
    foreach $sym (@class){
	push(@tmp,"%".$sym);
    }
    foreach $sym (@class){
	push(@tmp,"%".$sym."of".$rel);
    }
    foreach $sym (@class){
	push(@tmp,"%".$sym."of".$sym);
    }
}
$tmpprt=
    join($sep,
	 @tmp,"\n");
print $fhout
    "# note: all values are cumulative\n",
    $tmpprt;
				# 
print $tmpprt                   if ($Lverb);

undef %sum;
				# ini
$sum{"len"}=0;
foreach $sym (@class){
    $sum{$sym}=0;}
foreach $rel (@inter){
    $sum{$rel}=0;
    foreach $sym (@class){
	$sum{$sym,$rel}=0;
	$sum{$sym."of".$rel,$rel}=0;
	$sum{$sym."of".$sym,$rel}=0;}}

$id_taken=0;
foreach $id (@id){
    $len=$res{$id,"leneff"};
#    $len=$res{$id,"len"};
    next if ($len < $lenMin);	# too short->skip
    $sum{"len"}+=$len;
    ++$id_taken;

    @tmp=($id,$len);
#    @tmp=(sprintf("%10s",$id),$len); # xx
    foreach $sym (@class){
	$tmp=100*$res{$id,"sum",$sym}/$len;
	push(@tmp,
	     int($tmp));
	$sum{$sym}+=$tmp;}

    foreach $rel (@inter){
	if (! $res{$id,"sum",$rel}){
	    push(@tmp,0);
	    foreach $sym (@class){
		push(@tmp,0);}
	    foreach $sym (@class){
		push(@tmp,0);}
	    next;}

	$tmp=100*$res{$id,"sum",$rel}/$len;
	push(@tmp,
	     int($tmp));
	$sum{$rel}+=$tmp;
				# % of all
	foreach $sym (@class){
	    $tmp=100*$res{$id,"sum",$sym,$rel}/$len;
	    push(@tmp,
		 int($tmp));
	    $sum{$sym,$rel}+=$tmp;}
				# % of this acc interval
	foreach $sym (@class){
	    if (! defined $res{$id,"sum",$rel} || ! $res{$id,"sum",$rel}){
		push(@tmp,
		     0,0);
		next; }
	    $tmp=100*$res{$id,"sum",$sym,$rel}/$res{$id,"sum",$rel};
	    push(@tmp,
		 int($tmp));
	    $sum{$sym."of".$rel,$rel}+=$tmp;
	}
				# % of this type
	foreach $sym (@class){
	    if (! defined $res{$id,"sum",$sym} || ! $res{$id,"sum",$sym}){
		push(@tmp,
		     0,0);
		next; }
	    $tmp=100*$res{$id,"sum",$sym,$rel}/$res{$id,"sum",$sym};
	    push(@tmp,
		 int($tmp));
	    $sum{$sym."of".$sym,$rel}+=$tmp;
	}

    }

    $tmpprt=
	join($sep,
	     @tmp,
	     "\n");
    print $fhout
	$tmpprt;
    print $tmpprt               if ($Lverb2);
}
$#tmp=0;
@tmp=(int($sum{"len"}/$id_taken));
foreach $sym (@class){
    push(@tmp,int($sum{$sym}/$id_taken));
}
foreach $rel (@inter){
    push(@tmp,int($sum{$rel}/$id_taken));
				# % of all
    foreach $sym (@class){
	push(@tmp,int($sum{$sym,$rel}/$id_taken));
    }
				# % of this acc interval
    foreach $sym (@class){
	push(@tmp,int($sum{$sym."of".$rel,$rel}/$id_taken));
    }
				# % of this type
    foreach $sym (@class){
	push(@tmp,int($sum{$sym."of".$sym,$rel}/$id_taken));
    }
}

$tmpprt=
    join($sep,
#	 sprintf("%10s","sum_".$id_taken), # xx
	 "sum_".$id_taken,			
	 @tmp,
	 "\n");
print $fhout
    $tmpprt;
print $tmpprt               if ($Lverb);

close($fhout);

$fileOut2=$fileOut; $fileOut2=~s/Out/Outsum/i;
$fileOut2.="_sum" if ($fileOut2 eq $fileOut);
open($fhout,">".$fileOut2) || warn "*** $scrName ERROR fileout2=$fileOut2";
$tmpprt=
    join($sep,
	 "field","value",
	 "\n");
print $fhout
    $tmpprt;
print $tmpprt               if ($Lverb);

$tmpprt=
    join("\n",
	 "%KL-all="."...".$sep.int($sum{"KL"}/$id_taken),
	 "%DE-all="."...".$sep.int($sum{"DE"}/$id_taken),
	 "\n");
print $fhout
    $tmpprt;
print $tmpprt               if ($Lverb);

foreach $rel (@inter){
    $#tmp=0;
    $relprt=$rel;
    while (length($relprt)<3){
	$relprt=".".$relprt;}
    push(@tmp,"%all-acc=".$relprt.$sep.int($sum{$rel}/$id_taken));
    foreach $sym (@class){
	push(@tmp,"-%".$sym."-acc=".$relprt.$sep.int($sum{$sym,$rel}/$id_taken));
    }
    foreach $sym (@class){
	push(@tmp,"-%".$sym."-acc=".$relprt.$sep.int($sum{$sym."of".$sym,$rel}/$id_taken));
    }
    
    $tmpprt=
	join("\n",
	     @tmp,
	     "\n");
    print $fhout 
	$tmpprt;
    print 
	$tmpprt               if ($Lverb);
}

close($fhout);

$fileOut3=$fileOut2; $fileOut3=~s/Outsum/Outsum2/i;
$fileOut3.="_sum3" if ($fileOut3 eq $fileOut2);
fileOut3.="xx"     if ($fileOut eq $fileOut3);
open($fhout,">".$fileOut3) || warn "*** $scrName ERROR fileout3=$fileOut3";
@tmp=("acc","%acc-all");
foreach $sym (@class){
    push(@tmp,"%".$sym);
}
foreach $sym (@class){
    push(@tmp,"%".$sym."of"."acc");
}
foreach $sym (@class){
    push(@tmp,"%".$sym."of".$sym);
}
	 
$tmpprt=
    join($sep,
	 @tmp,
	 "\n");
print $fhout
    $tmpprt;
print $tmpprt               if ($Lverb);

foreach $rel (@inter){
    $#tmp=0;
    push(@tmp,
	 $rel,
	 int($sum{$rel}/$id_taken));
				# % of all
    foreach $sym (@class){
	push(@tmp,
	     int($sum{$sym,$rel}/$id_taken));}
				# % of this acc interval
    foreach $sym (@class){
	push(@tmp,
	     int($sum{$sym."of".$rel,$rel}/$id_taken));}
				# % of this type
    foreach $sym (@class){
	push(@tmp,
	     int($sum{$sym."of".$sym,$rel}/$id_taken));}
    
    $tmpprt=
	join($sep,
	     @tmp,
	     "\n");
    print $fhout 
	$tmpprt;
    print 
	$tmpprt               if ($Lverb);
}

close($fhout);

print "--- output in $fileOut\n"  if (-e $fileOut);
print "--- output in $fileOut2\n" if (-e $fileOut2);
print "--- output in $fileOut3\n" if (-e $fileOut3);
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

