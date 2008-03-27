#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "";
$scrGoal="evaluate accuracy in getting helix, strand caps\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   \n".
    "     \t \n".
    "     \t ";
#  
# FIXME:
#------------------------------------------------------------------------------#
#	Copyright				        	2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Aug,    	2003	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one


				# ------------------------------
				# defaults
%par=(
      'dirDataDsspcont', "/data/dsspcont/",			# 
      'extDsspcont',     ".dsspc",
      '',  "",
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
$sep=   "\t";


$maxdiff=2;			# allow +- 3 difference between observed and predicted helix
$LdoDsspcont=0; 		# compare to DSSPcont
$LdoDsspcont=0; 		# compare to DSSPcont

$ptrcont{"chn","beg"}=12;$ptrcont{"chn","len"}= 1;
$ptrcont{"seq","beg"}=14;$ptrcont{"seq","len"}= 1;
$ptrcont{"sec","beg"}=17;$ptrcont{"sec","len"}= 1;
$ptrcont{"G","beg"}=  40;$ptrcont{"G","len"}=   3;
$ptrcont{"H","beg"}=  44;$ptrcont{"H","len"}=   3;
$ptrcont{"I","beg"}=  48;$ptrcont{"I","len"}=   3;
$ptrcont{"T","beg"}=  52;$ptrcont{"T","len"}=   3;
$ptrcont{"E","beg"}=  56;$ptrcont{"E","len"}=   3;
$ptrcont{"B","beg"}=  60;$ptrcont{"B","len"}=   3;
$ptrcont{"S","beg"}=  64;$ptrcont{"S","len"}=   3;
$ptrcont{"L","beg"}=  68;$ptrcont{"L","len"}=   3;

$dsspcontThreshFuzzy=90;	# when to call it fuzzy (i.e. if  sum(HGI)>this)
$dsspcontThreshFuzzy=80;	# when to call it fuzzy (i.e. if  sum(HGI)>this)
$dsspcontThreshFuzzy=100;	# when to call it fuzzy (i.e. if  sum(HGI)>this)

				# delete all helices < 4 residues
$minlenHelix=        0;         # to take them all
$minlenStrand=       0;         # to take them all
if (0){
    $minlenHelix=        4;
    $minlenStrand=       1;
}


				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","max",       "x",       "maximal slack in calling HE right (def=$maxdiff)";
    if ($LdoDsspcont){
	printf "%5s %-15s %-20s %-s\n","","nocont",    "no value","do not compare to DSSPcont (currently done)";
    }
    else {
	printf "%5s %-15s %-20s %-s\n","","cont",      "no value","compare to DSSPcont (currently NOT done)";
    }
    print "\n";
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",        "name of output file";
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

    elsif ($arg=~/^(max|maxdiff|diff|dist)=(.*)$/){ $maxdiff=     $2;}
    elsif ($arg=~/^(cont|dsspcont|dssp)$/i)       { $LdoDsspcont= 1;}
    elsif ($arg=~/^no(cont|dsspcont|dssp)$/i)     { $LdoDsspcont= 0;}

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
    if ($#fileIn>1){
	$tmp="statprof.rdb";}
    else {
	$tmp=$fileIn;
	$tmp=~s/^.*\///g;
    }
    if ($dirOut){
	$fileOut=$dirOut."Out-".$tmp;}
    else {
	$fileOut="Out-".$tmp;}}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$ctprot=0;

				# set to zero
foreach $type ("HX","EX","XH","XE"){
    foreach $kwd ("prd","obs"){
	$res{$kwd,$type}=0;
    }
    foreach $dist (0..$maxdiff){
	$res{$type,$dist}=0;
    }
}
    				# cont stuff
foreach $type ("HX","EX","XH","XE"){
    $res{"sum","cont"}=0;
    $type1=$type;
    $type1=~s/X//g;
    foreach $kwd2 ("contclear","contfuzzy"){
	$res{$type,$kwd2}=0;
	$res{$type1,$kwd2}=0;
	$res{"sum",$kwd2}=0;
	foreach $dist (0..($maxdiff+1)){
	    $res{$type,$kwd2,$dist}=0;
	    $res{$type1,$kwd2,$dist}=0;
	    $res{"sum",$kwd2,$dist}=0;
	}
    }
}
	
$#id=0;
foreach $fileIn (@fileIn){
    				# hard coded shit!
#    next if ($fileIn=~/1hqz|1h8b/);
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n" if ($Ldebug);

    $id=$fileIn;
    $id=~s/^.*\///g;
    $id=~s/\..*$//g;
    $id=~s/\-.*$//g;
    ++$ctprot;
    $id[$ctprot]=$id;
    				# search dsspcont
    $Lok=1;
    if ($LdoDsspcont){
	$idnochn=$id;
	$chnwant=" ";
	$idnochn=~s/\_(.)$//;
	$chnwant=$1  if (defined $1 && length($1)==1);
	$filedsspcont=$par{"dirDataDsspcont"}.$idnochn.$par{"extDsspcont"};
	if (! -e $filedsspcont && ! -l $filedsspcont){
	    $Lok=0;
	    print "*-* skip since DSSPcont=$filedsspcont, missing (you may switch dsspcont mode off)!\n";
	}
				# read DSSPcont first
	else {
	    open($fhin,$filedsspcont) || die "*** $scrName ERROR opening filedsspcont=$filedsspcont!";

	    			# wind to line below
	    while (<$fhin>) {
#		print $_ if ($_=~/RESIDUE AA STRUCTURE BP1/);
		last if ($_=~/RESIDUE AA STRUCTURE BP1/);
	    }
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8....,....9....,....10...,....11...,....12
#  #  RESIDUE AA STRUCTURE BP1 BP2  ACC   G   H   I   T   E   B   S   L      N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
#    1   44 A A              0   0  150   0   0   0   0   0   0   0 100       0, 0.0     2,-0.5     0, 0.0     3,-0.2   0.000 360.0 360.0 360.0 119.4  -24.6   -6.6    8.6
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8....,....9....,....10...,....11...,....12
#    4   47 A E  S    S-     0   0  161   0   0   0   0   0   0 100   0      -3,-0.2    -1,-0.1     1,-0.1    -2,-0.1   0.942 102.5 -45.0 -42.4 -68.2  -23.7   -4.2    0.5
	    $ctres=0;
	    undef %dsspcont;
	    $#dsspcontG8=$#dsspcontH8=$#dsspcontI8=$#dsspcontT8=$#dsspcontE8=$#dsspcontB8=$#dsspcontS8=$#dsspcontL8=0;
	    while (<$fhin>) {
		$_=~s/\n//g;
		++$ctres;
#		print "xx ctres=$ctres line=",substr($_,1,70),"\n";
#		print substr($_,1,70),"\n";
#		print "xx interpret: ";
		foreach $kwd ("seq","chn","sec","G","H","I","T","E","B","S","L"){
		    $tmp{$kwd}=substr($_,$ptrcont{$kwd,"beg"},$ptrcont{$kwd,"len"});
		    if ($kwd=~/[GHITEBSL]/){
			$tmp{$kwd}=~s/\D//g;
		    }
#		    next if ($kwd=~/[GHITEBSL]/ && $tmp{$kwd}<1);
#		    print " $kwd=",$tmp{$kwd},",";
		}
#		print "\n";
				# skip if chain different from what we want
		next if ($tmp{"chn"} ne $chnwant);
				# append into single for entire protein
		foreach $kwd ("seq","chn","sec"){
		    $dsspcont{$kwd}.=$tmp{$kwd};
		}
		foreach $kwd ("G","H","I","T","E","B","S","L"){
		    $dsspcont{$kwd}.=",".$tmp{$kwd};
		}
		push(@dsspcontG8,$tmp{"G"});
		push(@dsspcontH8,$tmp{"H"});
		push(@dsspcontI8,$tmp{"I"});
		push(@dsspcontT8,$tmp{"T"});
		push(@dsspcontE8,$tmp{"E"});
		push(@dsspcontB8,$tmp{"B"});
		push(@dsspcontS8,$tmp{"S"});
		push(@dsspcontL8,$tmp{"L"});
	    }
	    close($fhin);
	    foreach $kwd ("G","H","I","T","E","B","S","L"){
		$dsspcont{$kwd}=~s/^,*|,*$//g;
	    }
	    			# handle cysteines
	    $dsspcont{"seqcc"}=$dsspcont{"seq"};
	    $dsspcont{"seq"}=~s/[a-z]/C/g;
	}
    }
    next if (!$Lok);

#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $ctres=0;
    $seqall=$osecall=$psecall="";
    while (<$fhin>) {
	next if ($_=~/^\#/);	# skip comments
	next if ($_=~/^No/);	# skip names
	$_=~s/\n//g;
	++$ctres;

# 1  2    3    4    5    6    7    8    9   10 11 12 13  14  15   16   17  18  19  20  21  22  23  24  25  26  27  28  29  30
#                                                                                      <1  <4  <9 <16 <25 <36 <49 <64 <81 <100
#No AA OHEL PHEL RI_S OACC PACC OREL PREL RI_A pH pE pL Obe Pbe Obie Pbie OtH OtE OtL Ot0 Ot1 Ot2 Ot3 Ot4 Ot5 Ot6 Ot7 Ot8 Ot9

	@tmp=split(/\t/,$_);
	$seq= $tmp[2];
	$osec=$tmp[3];
	$psec=$tmp[4];
#	@p10= @tmp[21..30];

	$seqall.= $seq;
	$osecall.=$osec;
	$psecall.=$psec;
    }
    close($fhin);
    $res{$id,"nres"}=$ctres;
    @osec=split(//,$osecall);
    @psec=split(//,$psecall);
    				# convert to numbers (faster)
    foreach $it (1..$ctres){
	if    ($osec[$it] eq "H"){
	    push(@onum,1);}
	elsif ($osec[$it] eq "E"){
	    push(@onum,2);}
	else{
	    push(@onum,3);}
	if    ($psec[$it] eq "H"){
	    push(@pnum,1);}
	elsif ($psec[$it] eq "E"){
	    push(@pnum,2);}
	else{
	    push(@pnum,3);}
    }


    				# get boundaries
    undef %tmp;
    foreach $it (1..$ctres){
				# observed boundary i/i-1
	if    ($it>1      && ! defined $tmp{"obs",$it} && ! defined $tmp{"obs",($it-1)} &&
	       ($onum[$it] != $onum[$it-1])){
	    			# type
	    $otype=&ass_type_of_boundary($onum[$it-1],$onum[$it]);
	    $tmp{"obs",$otype}=""     if (! defined $tmp{"obs",$otype});
	    $tmp{"obs",$otype}.=",".$it;
	    $tmp{"obs",$it}=1;
	}
				# observed boundary i/i+1
	elsif ($it<$ctres && ! defined $tmp{"obs",$it} && ! defined $tmp{"obs",($it+1)} &&
	       ($onum[$it] != $onum[$it+1])){
	    			# type
	    $otype=&ass_type_of_boundary($onum[$it],$onum[$it+1]);
	    $tmp{"obs",$otype}=""     if (! defined $tmp{"obs",$otype});
	    $tmp{"obs",$otype}.=",".$it;
	    $tmp{"obs",$it}=1;
	}

				# predicted boundary i/i-1
	if    ($it>1      && ! defined $tmp{"prd",$it} && ! defined $tmp{"prd",($it-1)} &&
	       ($pnum[$it] != $pnum[$it-1])){
	    			# type
	    $ptype=&ass_type_of_boundary($pnum[$it-1],$pnum[$it]);
	    $tmp{"prd",$ptype}=""     if (! defined $tmp{"prd",$ptype});
	    $tmp{"prd",$ptype}.=",".$it;
	    $tmp{"prd",$it}=1;
	}
				# observed boundary i/i+1
	elsif ($it<$ctres && ! defined $tmp{"prd",$it} && ! defined $tmp{"prd",($it+1)} &&
	       ($pnum[$it] != $pnum[$it+1])){
	    			# type
	    $ptype=&ass_type_of_boundary($pnum[$it],$pnum[$it+1]);
	    $tmp{"prd",$ptype}=""     if (! defined $tmp{"prd",$ptype});
	    $tmp{"prd",$ptype}.=",".$it;
	    $tmp{"prd",$it}=1;
	}
    }

    				# count types
    foreach $type ("HX","EX","XH","XE"){
	next if (! defined $tmp{"obs",$type});
	$tmp{"obs",$type}=~s/^,*|,*$//g;
	@tmpx=split(/,/,$tmp{"obs",$type});
	$tmpn=$#tmpx;
	$res{"obs",$type}+=$tmpn;}
    foreach $type ("HX","EX","XH","XE"){
	next if (! defined $tmp{"prd",$type});
	$tmp{"prd",$type}=~s/^,*|,*$//g;
	@tmpx=split(/,/,$tmp{"prd",$type});
	$tmpn=$#tmpx;
	$res{"prd",$type}+=$tmpn;}


    				# before checking the correct ones: bring in DSSPcont
    				# align sequences (check)
    if ($LdoDsspcont){
	($Lok,$msg,$max,$beg1,$beg2)=
	    &align_a_la_blast($seqall,$dsspcont{"seq"});
	if ($max < 30 && $max<length($seqall)){
	    print "xx returned $Lok,$msg, file=$fileIn, dsspcont=$filedsspcont\n";
	    print "xx dssp=",$dsspcont{"seq"},"\n";
	    print "xx prof=$seqall\n";
	    print "xx max=$max, beg1=$beg1, b eg2=$beg2\n";
	    die;
	}
				# sum over helix, strand, other
	$#dsspcontH=$#dsspcontE=0;
	foreach $it (1..$max){
	    $itdssp=$beg2-1+$it;
	    $itprof=$beg1-1+$it;
	    $dsspcontH[$itprof]=$dsspcontG8[$itdssp]+$dsspcontH8[$itdssp]+$dsspcontI8[$itdssp];
	    $dsspcontE[$itprof]=$dsspcontE8[$itdssp]+$dsspcontB8[$itdssp];
	    if (0){
		print "xx dssp($itdssp) prof($itprof) ";
		print " ",substr($dsspcont{"seq"},$itdssp,1);
		print "-",substr($seqall,$itprof,1);
		print " | ",substr($dsspcont{"sec"},$itdssp,1);
		print "-",substr($osecall,$itprof,1);
		printf " | ch=%3d ce=%3d",$dsspcontH[$itprof],$dsspcontE[$itprof];
		print ' GHITEBSL: ';
#		printf ("%3d" x 8,
#		    $dsspcontG8[$itdssp],$dsspcontH8[$itdssp],$dsspcontI8[$itdssp],$dsspcontT8[$itdssp],$dsspcontE8[$itdssp],$dsspcontB8[$itdssp],$dsspcontS8[$itdssp],$dsspcontL8[$itdssp]);
		print "\n";
	    }
	}
    }
    				# clean up
    foreach $type ("HX","EX","XH","XE"){
	if (defined $tmp{"obs",$type}){
	    $tmp{"obs",$type}=~s/^,*|,*$//g;}
	if (defined $tmp{"prd",$type}){
	    $tmp{"prd",$type}=~s/^,*|,*$//g;}
    }

    				# ignore short helices
    if ($minlenHelix){
	$#otmph_exclude=0;
	if (defined $tmp{"obs","XH"}){
	    @otmpxh=split(/,/,$tmp{"obs","XH"});
	    @otmphx=split(/,/,$tmp{"obs","HX"});
	    $numtmp=$#otmpxh;
	    foreach $it (1..$numtmp){
		if (! defined $otmphx[$it]){
		    $end=length($seqall);}
		else {
		    $end=$otmphx[$it];}
		if ((1+$end-$otmpxh[$it])<$minlenHelix){
		    $otmph_exclude[$it]=1;
		}
	    }
	}}
    				# ignore short strands
    if ($minlenStrand){
	$#otmpe_exclude=0;
	if (defined $tmp{"obs","XE"}){
	    @otmpxe=split(/,/,$tmp{"obs","XE"});
	    @otmpex=split(/,/,$tmp{"obs","EX"});
	    $numtmp=$#otmpxe;
	    foreach $it (1..$numtmp){
		if (! defined $otmpex[$it]){
		    $end=length($seqall);}
		else {
		    $end=$otmpex[$it];}
		if ((1+$end-$otmpxe[$it])<$minlenStrand){
		    $otmpe_exclude[$it]=1;
		}
	    }
	}}


    foreach $type ("HX","EX","XH","XE"){
	next if (! defined $tmp{"obs",$type} || ! defined $tmp{"prd",$type});
#	print "xx $type o:",$tmp{"obs",$type},"\n";
#	print "xx $type p:",$tmp{"prd",$type},"\n";
	@otmp=split(/,/,$tmp{"obs",$type});
	@ptmp=split(/,/,$tmp{"prd",$type});
	$ctseg=0;
	foreach $oval (@otmp){
	    ++$ctseg;
	    $dist=$maxdiff+1;
	    $Lexclude=0;
	    			# ignore short helices?
	    if (($type=~/H/ && defined $otmph_exclude[$ctseg]) ||
		($type=~/E/ && defined $otmpe_exclude[$ctseg])){
#		++$ctexcl_xx;
		$Lexclude=1;
#		print "xx exclude $type $ctseg tot=$ctexcl_xx\n";
	    }

#	    next if (($type=~/H/ && defined $otmph_exclude[$ctseg]) ||
#		     ($type=~/E/ && defined $otmpe_exclude[$ctseg]));

	    foreach $pval (@ptmp){
		$abs=&func_absolute($oval-$pval);
		if ($abs<=$maxdiff){
		    $dist=$abs;
		    last;}
		last if ($pval>($oval-$maxdiff));
	    }
	    if ($dist<=$maxdiff){
		++$res{$type,$dist};
		$distx=$dist;
	    }
	    else {
		$distx=$maxdiff+1;
		++$res{$type,$distx};
	    }
	    $type1=$type;
	    $type1=~s/X//g;
	    if ($Lexclude){
		++$res{$type1,$distx,"short"};
	    }
	    else {
		++$res{$type1,$distx,"long"};
	    }
		
		
	    			# now the question: how do we do for dsspcont?
	    if ($LdoDsspcont){
#		print "xx type=$type, oval=$oval, conth=$dsspcontH[$oval], conte=$dsspcontE[$oval]\n";		
		if    ($type=~/(H)/ && $dsspcontH[$oval]>=$dsspcontThreshFuzzy){
		    $type1=$1;
		    $kwd2="contclear";
		}
		elsif ($type=~/(H)/ && $dsspcontH[$oval]<$dsspcontThreshFuzzy){
		    $type1=$1;
		    $kwd2="contfuzzy";
		}
		elsif ($type=~/H/){
		    print "xx big problem type=$type, oval=$oval,  dsspcontH missing??\n";
		    exit;}
		elsif ($type=~/(E)/ && $dsspcontH[$oval]>=$dsspcontThreshFuzzy){
		    $type1=$1;
		    $kwd2="contclear";
		}
		elsif ($type=~/(E)/ && $dsspcontH[$oval]<$dsspcontThreshFuzzy){
		    $type1=$1;
		    $kwd2="contfuzzy";
		}
		elsif ($type=~/E/){
		    print "xx big problem type=$type, oval=$oval,  dsspcontH missing??\n";
		    exit;}
		else {
		    print "xx bigger problem type=$type, oval=$oval,  what is it??\n";
		    exit;}

		++$res{$type,"cont"};
		++$res{$type,$kwd2};
		++$res{$type,$kwd2,$distx};

		++$res{$type1,"cont"};
		++$res{$type1,$kwd2};
		++$res{$type1,$kwd2,$distx};

		++$res{"cont"};
		++$res{$kwd2};
		++$res{$kwd2,$distx};
	    }
	}
    }
    				# number of helices and strands
    $tmp=$osecall;
    $tmp=~s/LL+/L/g;$tmp=~s/HH+/H/g;$tmp=~s/EE+/E/g;
    $tmph=$tmp;$tmph=~s/[LE]//g;
    $tmpe=$tmp;$tmpe=~s/[LH]//g;
    $res{$id,"obs","H"}+=length($tmph);
    $res{$id,"obs","E"}+=length($tmpe);
    $tmp=$psecall;
    $tmp=~s/LL+/L/g;$tmp=~s/HH+/H/g;$tmp=~s/EE+/E/g;
    $tmph=$tmp;$tmph=~s/[LE]//g;
    $tmpe=$tmp;$tmpe=~s/[LH]//g;
    $res{$id,"prd","H"}+=length($tmph);
    $res{$id,"prd","E"}+=length($tmpe);
    				# difference observed-predicted helices
    $res{$id,"o-p","H"}=($res{$id,"obs","H"}-$res{$id,"prd","H"});
    $res{$id,"o-p","E"}=($res{$id,"obs","E"}-$res{$id,"prd","E"});

    				# sum H+E
    foreach $kwd ("obs","prd","o-p"){
	$res{$id,$kwd,"sum"}=0;
	foreach $type1 ("H","E"){
	    $res{$id,$kwd,"sum"}+=$res{$id,$kwd,$type1};
	}
    }
    				# ok for this protein
    if (0){
	print "xx id=$id num ";
	foreach $type1 ("H","E"){
	    print "o$type1:",$res{$id,"obs",$type1}," p$type1:",$res{$id,"prd",$type1}," o-p$type1:",$res{$id,"o-p",$type1},"|";
	}
	print "\n";
    }
    

    if ($Ldebug){
#    if (0){
	$tmpo=$osecall;$tmpo=~s/L/ /g;
	$tmpp=$psecall;$tmpp=~s/L/ /g;
	$npoints=100;
	for ($it=1;$it<=length($osecall);$it+=$npoints){
	    print "xx $id\n";
	    print "xx   ",&myprt_npointsfull($npoints,($it-1+$npoints)),"\n";
	    $endtmp=100; $endtmp=(1+length($osecall)-$it) if ((1+length($osecall)-$it)<$npoints);
	    print "xx o=",substr($tmpo,$it,$endtmp),"\n";
	    print "xx p=",substr($tmpp,$it,$endtmp),"\n";
	}
	
	printf "%-5s". " %4s" x ($maxdiff+1) ." | %5s %5s\n","dist=",(0..$maxdiff),"obs","prd";
	foreach $type ("HX","EX","XH","XE"){
	    printf "%-5s",$type;
	    foreach $dist (0..$maxdiff){
		printf " %4d",($res{$type,$dist}||0);
	    }
	    printf " | %5d",($res{"obs",$type}||0);
	    printf " %5d",($res{"prd",$type}||0);
	    print "\n";
	}
#	die;
    }
}

				# sum types
foreach $dist (0..$maxdiff){
    $res{"sum",$dist}=0;
}
foreach $kwd ("prd","obs"){
    $res{$kwd,"sum"}=0;
}

foreach $type1 ("H","E"){
    foreach $kwd ("prd","obs"){
	$res{$kwd,$type1,"1"}=0;
    }
    foreach $dist (0..$maxdiff){
	$res{$type1,"1",$dist}=0;
    }
    				# 
    foreach $type ($type1."X","X".$type1){
	foreach $kwd ("prd","obs"){
	    $res{$kwd,$type1,"1"}+=$res{$kwd,$type};
	    $res{$kwd,"sum"}+=$res{$kwd,$type};
	}
	foreach $dist (0..$maxdiff){
	    $res{$type1,"1",$dist}+=$res{$type,$dist};
	    $res{"sum",$dist}+=$res{$type,$dist};
	}
    }
    if (0){
	foreach $kwd ("prd","obs"){
	    print "xx $type1 $kwd ",$res{$kwd,$type1,"1"},"\n";}
	foreach $dist (0..$maxdiff){
	    print "xx sum ok $type1 d=$dist n= ",$res{$type1,"1",$dist},"\n";}
    }
}

				# ------------------------------
				# simple version (no DSSPcont)
$wrt=sprintf("%3s","sec");
foreach $dist (0..$maxdiff){
    $wrt.=sprintf("$sep%6s$sep%6s",
		  "$dist\%o","$dist\%p");
}
$wrt.=sprintf("$sep%6s$sep%6s",
	      "cum\%o","cum\%p");
$wrt.="\n";

$oktot=0;
foreach $type1 ("H","E"){
    $wrt.=sprintf("%3s",$type1);
    $ok=0;
    foreach $dist (0..$maxdiff){
	$wrt.=sprintf("$sep%6.1f$sep%6.1f",
		      100*($res{$type1,"1",$dist}/$res{"obs",$type1,"1"}),
		      100*($res{$type1,"1",$dist}/$res{"prd",$type1,"1"})
		      );
	$ok+=$res{$type1,"1",$dist};
	$oktot+=$res{$type1,"1",$dist};
    }
    $wrt.=sprintf("$sep%6.1f$sep%6.1f",
		  100*($ok/$res{"obs",$type1,"1"}),
		  100*($ok/$res{"prd",$type1,"1"})
		  );
    $wrt.="\n";
}
$wrt.=sprintf("%3s","sum");
foreach $dist (0..$maxdiff){
    $wrt.=sprintf("$sep%6.1f$sep%6.1f",
		  100*($res{"sum",$dist}/$res{"obs","sum"}),
		  100*($res{"sum",$dist}/$res{"prd","sum"})
		  );
}
$wrt.=sprintf("$sep%6.1f$sep%6.1f",
	      100*($oktot/$res{"obs","sum"}),
	      100*($oktot/$res{"prd","sum"})
	      );
$wrt.="\n";

    
print $wrt;

				# ------------------------------
				# distinguish long and short
if ($minlenHelix || $minlenStrand){
    foreach $kwd2 ("short","long"){
	$res{"sub",$kwd2}=0;
	foreach $type1 ("H","E"){
	    $res{"sub",$type1,$kwd2}=0;
	    foreach $dist (0..($maxdiff+1)){
		next if (! defined $res{$type1,$dist,$kwd2});
		$res{"sub",$type1,$kwd2}+=$res{$type1,$dist,$kwd2};
	    }
	    $res{"sub",$kwd2}+=$res{"sub",$type1,$kwd2};
	}
    }
    foreach $type1 ("H","E"){
	$res{"sub",$type1}=0;
	foreach $kwd2 ("short","long"){
	    $res{"sub",$type1}+=$res{"sub",$type1,$kwd2};
	}
    }
	

				# header short
    $wrtlen="SUBSET Of long short\n";
    $wrtlen.=sprintf("%3s","sec");
    foreach $dist (0..($maxdiff+1)){
	foreach $kwd2 ("short","long"){
	    $wrtlen.=sprintf("$sep%6s","$dist\%".substr($kwd2,1,1));
	}
    }
    $wrtlen.=sprintf("$sep%6s$sep%6s","cum\%s","cum\%l");
    $wrtlen.="\n";
				# body short
    foreach $type1 ("H","E"){
	$wrtlen.=sprintf("%3s",$type1);
	foreach $dist (0..($maxdiff+1)){
	    foreach $kwd2 ("short","long"){
		$tmp=$perc=0;	# 
		$tmp=$res{$type1,$dist,$kwd2}        if (defined $res{$type1,$dist,$kwd2});
		$perc=100*$tmp/$res{"sub",$type1,$kwd2}    if (defined $res{"sub",$type1,$kwd2} && $res{"sub",$type1,$kwd2}>0);
		$wrtlen.=sprintf("$sep%6.1f",$perc);
	    }
	}
				# sums
	foreach $kwd2 ("short","long"){
	    $tmp=$perc=0;
	    $tmp=$res{"sub",$type1,$kwd2}     if (defined $res{"sub",$type1,$kwd2});
	    $perc=100*$tmp/$res{"sub",$type1} if (defined $res{"sub",$type1} && $res{"sub",$type1}>0);
	    $wrtlen.=sprintf("$sep%6.1f",$perc);
	}
	$wrtlen.="\n";
    }
    print "$wrtlen\n";
}

				# ------------------------------
				# DSSPcont all that are clear (wrt cont wrt dsspcont)
    				# header
$wrtcont="";
$wrtcont.="# note maxdiff=$maxdiff, ".($maxdiff+1)." used to indicate all outside of max\n";
$wrtcont.=sprintf("%3s","sec");
foreach $dist (0..($maxdiff+1)){
    $wrtcont.=sprintf("$sep%6s$sep%6s","$dist\%clear","$dist\%fuzzy");
}
$wrtcont.=sprintf("$sep%6s$sep%6s","ok\%c","ok\%f");
$wrtcont.=sprintf("$sep%6s$sep%6s$sep%6s","s\%c","s\%f","sum");
$wrtcont.="\n";
    				# body
$oktot{"contclear"}=$oktot{"contfuzzy"}=0;
$anytot{"contclear"}=$anytot{"contfuzzy"}=0;
foreach $type1 ("H","E"){
    $wrtcont.=sprintf("%3s",$type1);
    $ok{"contclear"}=$ok{"contfuzzy"}=0;
    $any{"contclear"}=$any{"contfuzzy"}=0;
    foreach $dist (0..($maxdiff+1)){
	foreach $kwd2 ("contclear","contfuzzy"){
	    if (! defined $res{$type1,"cont"} || ! $res{$type1,"cont"}){
		$wrtcont.=sprintf("$sep%6s","");
		next;}
	    			# at distance(clear|fuzzy) as percentage of all 
#	    $wrtcont.=sprintf("$sep%6.1f",100*($res{$type1,$kwd2,$dist}/$res{$type1,"cont"}));
	    			# at distance(clear|fuzzy) as percentage of all clear|fuzzy
	    $wrtcont.=sprintf("$sep%6.1f",100*($res{$type1,$kwd2,$dist}/$res{$type1,$kwd2}));
	    $any{$kwd2}+=$res{$type1,$kwd2,$dist};
	    $anytot{$kwd2}+=$res{$type1,$kwd2,$dist};
	    next if ($dist>$maxdiff);
	    $ok{$kwd2}+=$res{$type1,$kwd2,$dist};
	    $oktot{$kwd2}+=$res{$type1,$kwd2,$dist};
	}
    }
    $sumok=0;
    foreach $kwd2 ("contclear","contfuzzy"){
	$sumok+=$ok{$kwd2};
    }
    				# all ok
    foreach $kwd2 ("contclear","contfuzzy"){
				# percentage correct(clear|fuzzy) as percentage of all correct
#	$wrtcont.=sprintf("$sep%6.1f",100*($ok{$kwd2}/$sumok));
				# percentage correct(clear|fuzzy) as percentage of all clear|fuzzy
	$wrtcont.=sprintf("$sep%6.1f",100*($ok{$kwd2}/$res{$kwd2}));
    }
    				# all (last should be 100%)
    $any=0;
    foreach $kwd2 ("contclear","contfuzzy"){
	$wrtcont.=sprintf("$sep%6.1f",100*($any{$kwd2}/$res{$type1,"cont"}));
	$any+=$any{$kwd2};
    }
    $wrtcont.=sprintf("$sep%6.1f",100*($any/$res{$type1,"cont"}));
    $wrtcont.="\n";
}
$wrtcont.=sprintf("%3s","sum");
foreach $dist (0..($maxdiff+1)){
    foreach $kwd2 ("contclear","contfuzzy"){
	$wrtcont.=sprintf("$sep%6.1f",100*($res{$kwd2,$dist}/$res{"cont"}));
    }
}
				# all ok
$sumok=0;
foreach $kwd2 ("contclear","contfuzzy"){
    $sumok+=$oktot{$kwd2};
}
foreach $kwd2 ("contclear","contfuzzy"){
	    			# all types (clear|fuzzy) as percentage of all 
#    $wrtcont.=sprintf("$sep%6.1f",100*($oktot{$kwd2}/$sumok));
    				# all types as percentage of clear|fuzzy
    $wrtcont.=sprintf("$sep%6.1f",100*($oktot{$kwd2}/$res{$kwd2}));
}
$any=0;
foreach $kwd2 ("contclear","contfuzzy"){
    $wrtcont.=sprintf("$sep%6.1f",100*($anytot{$kwd2}/$res{"cont"}));
    $any+=$anytot{$kwd2};
}
$wrtcont.=sprintf("$sep%6.1f",100*($any/$res{"cont"}));
$wrtcont.="\n";

print "# DSSPcont version\n";
print $wrtcont;
				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout $wrt;
print $fhout "# DSSPcont version\n";
print $fhout $wrtcont;
close($fhout);
				# now distribution of errors
$wrt="";
$wrt.="id".$sep."Hobs".$sep."Hprd".$sep."Ho-p".$sep."Eobs".$sep."Eprd".$sep."Eo-p".$sep."HEobs".$sep."HEprd".$sep."HEo-p"."\n";
foreach $id (@id){
    $wrt.=$id;
    foreach $type1 ("H","E","sum"){
	foreach $kwd ("obs","prd","o-p"){
	    if (! defined $res{$id,$kwd,$type1}){
		$wrt.=sprintf("$sep%8s","");
		next;}
	    $wrt.=sprintf("$sep%8d",$res{$id,$kwd,$type1});
	}
    }
    $wrt.="\n";
}      

$fileOut2=$fileOut."_histo";
open($fhout,">".$fileOut2) || warn "*** $scrName ERROR creating fileOut2(histo)=$fileOut2";
print $fhout $wrt;
close($fhout);


if ($Lverb){
    print "--- output in $fileOut\n"  if (-e $fileOut);
    print "--- output in $fileOut2\n" if (-e $fileOut2);
}
exit;


#===============================================================================
sub align_a_la_blast {
    local($seq1Loc,$seq2Loc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   align_a_la_blast            finds longest common word between string 1 and 2
#       in:                     $string1
#       in:                     $string2
#       out:                    1|0,msg,$lali,$beg1,$beg2
#                               $lali      length of common substring
#                               $beg1      first matching residue in string1
#                               $beg2      first matching residue in string2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."align_a_la_blast";
    $fhinLoc="FHIN_"."align_a_la_blast";$fhoutLoc="FHOUT_"."align_a_la_blast";
				# ------------------------------
				# check arguments
    return(&errSbr("not def seq1Loc!"))          if (! defined $seq1Loc);
    return(&errSbr("not def seq2Loc!"))          if (! defined $seq2Loc);
#    return(&errSbr("not def !"))          if (! defined $);

#    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# ------------------------------
				# local defaults
    $wordlenLoc=               10;
    $wordlenLoc=$par{"wordlen"} if (defined $par{"wordlen"});

				# ------------------------------
				# all upper
    $seq1Loc=~tr/[a-z]/[A-Z]/;
    $seq2Loc=~tr/[a-z]/[A-Z]/;

				# long enough
    $len1=length($seq1Loc);
    if ($len1 < $wordlenLoc){
	return(2,"sequence 1 too short (is $len1, should be > $wordlenLoc)");
    }
				# chop up sequence 1
    $#tmpbeg=$#tmpend=0;
    
    @seq1Loc=split(//,$seq1Loc);
    $it=0;
    while ($it <= ($len1-$wordlenLoc)){
	++$it;
	$word1=substr($seq1Loc,$it,$wordlenLoc);
				# DOES match: try to extend
	if ($seq2Loc=~/$word1/){
	    $it2=$it+$wordlenLoc-1;
	    while ($seq2Loc=~/$word1/ && 
		   ($it2 < $len1)){
		++$it2;
		$word1.=$seq1Loc[$it2];
	    }
				# last did not match anymore
	    chop($word1)        if ($seq2Loc!~/$word1/);
	    $beg=$it;
	    $end=$it+length($word1)-1;
	    $it=$end;
	    push(@tmpbeg,$beg);
	    push(@tmpend,$end);
	}
    }
				# ------------------------------
				# find longest
    $max=$pos=0;
    foreach $it (1..$#tmpbeg){
	$len=1+$tmpend[$it]-$tmpbeg[$it];
	if ($max < $len){
	    $max=$len;
	    $pos=$it;}
    }
				# ------------------------------
				# find out where it matches
    
    $word1=substr($seq1Loc,$tmpbeg[$pos],$max);
    $beg1=$tmpbeg[$pos];
    $#seq1Loc=$#tmpbeg=$#tmpend=0;

    $tmp=$seq2Loc;
    $pre="";
    if ($tmp=~/^(.*)$word1/){
	$tmp=~s/^(.*)($word1)/$2/;
	$pre=$1                 if (defined $1);}
    $beg2=1;
    $beg2=length($pre)+1       if (length($pre)>0);
    return(1,"ok $sbrName",$max,$beg1,$beg2);
}				# end of align_a_la_blast

#===============================================================================
sub myprt_npointsfull {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npointsfull           writes line with N dots of the form '....,....10...,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
#	    $tmp=substr($num,1,1); 
	    $tmp=$num;
	    $out="....,....".$tmp; 
	    $prevover=length($num);
	}
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); 
	    $tmp=$num;
	    $out.= "." x (5-$prevover) .",....".$tmp; 
	    $prevover=length($num);
	}
	elsif ($i==($npoints/10) && $ctprev>=9){
#	    $tmp1=substr($ctprev,2);
#	    $tmp2="." x (4-length($tmp1));
#	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); 
	    $tmp=$num;
	    $out.= "." x (5-$prevover) .",....".$tmp; 
	    $prevover=length($num);
	}
	else                                   {
#	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
#	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); 
	    $tmp=$num;
	    $out.= "." x (5-$prevover) .",....".$tmp; 
	    $prevover=length($num);
	}
	last if ($num>$num_in);
    }
    return ($out);
}				# end of myprt_npoints

sub ass_type_of_boundary{
    ($tmp1,$tmp2)=@_;

    if    ($tmp1==1 && $tmp2==2){
	$tmptype="HX";}
    elsif ($tmp1==1 && $tmp2==3){
	$tmptype="HX";}
    elsif ($tmp1==2 && $tmp2==1){
	$tmptype="EX";}
    elsif ($tmp1==2 && $tmp2==3){
	$tmptype="EX";}
    elsif ($tmp1==3 && $tmp2==1){
	$tmptype="XH";}
    elsif ($tmp1==3 && $tmp2==2){
	$tmptype="XE";}
    else{
	print "xx big problem $tmp1 $tmp2\n";die;
    }
    return($tmptype);
}

sub ass_type_of_boundary_det{
    ($tmp1,$tmp2)=@_;

    if    ($tmp1==1 && $tmp2==2){
	$tmptype="HE";}
    elsif ($tmp1==1 && $tmp2==3){
	$tmptype="HL";}
    elsif ($tmp1==2 && $tmp2==1){
	$tmptype="EH";}
    elsif ($tmp1==2 && $tmp2==3){
	$tmptype="EL";}
    elsif ($tmp1==3 && $tmp2==1){
	$tmptype="LH";}
    elsif ($tmp1==3 && $tmp2==2){
	$tmptype="LE";}
    else{
	print "xx big problem $tmp1 $tmp2\n";die;
    }
    return($tmptype);
}

#===============================================================================
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

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

