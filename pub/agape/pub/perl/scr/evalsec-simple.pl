#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "Evaluate secondary structure prediction\n".
    "      \t compute protein averages over ri and simple Q2/Q3 \n".
    "      \t \n";
$scrIn=      "file*rdb (or list)";            # 
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
$scrHelpTxt.=" \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
#  
#  
#  - $par{"kwd"}  : global parameters, available on command line by 'kwd=value'
# 
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Feb,    	2000	       #
#------------------------------------------------------------------------------#
#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
				# find library
$dirScr=$0; $dirScr=~s/^(.*\/)[^\/]*$/$1/;
$lib="lib-proferr.pl"; $Lok=0;
				# find in command line
foreach $arg (@ARGV){
    next if ($arg !~ /^pack=(.*)$/);
    $pack=$1; }

if (defined $pack && -e $pack){
    $Lok=require($pack);
}
else {
    foreach $dir (
#eva		  "/home/eva/server/pub/perl/pack/",

		  "/home/rost/pub/prof/scr/lib/",
		  "/home/rost/perl/scr/pack/",
		  $dirScr,"","pack/",
		  ){
	$want=$dir.$lib;
	next if (! -e $want && ! -l $want);
	$Lok=require($want);
	last if ($Lok);
    }}
die("*** ERROR $scrName: could NOT find lib=$lib!\n") if (! $Lok);

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------


if (defined $modeprd &&
    $modeprd =~ /htm/){
    $kwdRi= "RI_H";
    $kwdPrd="PHL";
    $kwdObs="OHL";
    
    $par{"errPrd_doq3"}= 0;
    $par{"errPrd_doq2"}= 1;
    $par{"errPrd_dobad"}=0; 

    @outnum2sym=("H","L");

    $mode{"htmnumout"}=  2;
    $mode{"htmKwdRi"}=   $kwdRi;
    $mode{"htmKwdPrd"}=  $kwdPrd;
    $mode{"htmKwdObs"}=  $kwdObs;
}
				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$ctprot=0;
$#id=0;undef %id;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$#fileIn) 
			 if ($par{"verbose"});

    $Lskip=0;
				# ------------------------------
				# read RDB file
    if (! $LisCaspFormat){
	($Lok,$msg)=
	    &rdRdb_here($fileIn
			);      &errScrMsg("reading RDB file=$fileIn") if (! defined $rdb{"NROWS"});}
			    
				# read CASP file
    else {
	($Lok,$msg)=
	    &rdCaspObsPrd($fileIn
			  );    
	if (! $Lok || ! defined $rdb{"NROWS"}){
	    &errScrMsg("failed CASPfile=$fileIn",$msg);}
	elsif ($Lok eq 2) {
	    print "-*- skip $fileIn\n";
	    $Lskip=1;
	}
    }
    if ($Lskip && $Ldebug){
	print "--- WARN skipped $fileIn\n";
    }
    next if ($Lskip);
    ++$ctprot;
	
				# hack xx
    $rdb{"id"}=$fileIn;
    $rdb{"id"}=~s/^.*\///g;
    $rdb{"id"}=~s/\.rdb.*$//g;
    $rdb{"nali"}=$rdb{"NALIGN"} if (defined $rdb{"NALIGN"});
	
				# everything we need there?
    &errScrMsg("fileIn=$fileIn, seems no observed sec str given!!\n")
	if (! defined $rdb{1,"OHEL"} && ! defined $rdb{1,"OTL"}  &&
	    ! defined $rdb{1,"OHL"}  && ! defined $rdb{1,"OEL"}  &&
	    ! defined $rdb{1,"OCL"}  && ! defined $rdb{1,"OHELBGT"} && 
	    ! defined $rdb{1,"OMN"}  );
				# hack
    if (defined $modeprd && 
	$modeprd=~/htm/          && 
	! defined $rdb{1,$kwdRi} &&
	defined $rdb{1,"RI_S"}   ){
	foreach $itres (1..$rdb{"NROWS"}){
	    $rdb{$itres,$kwdRi}=$rdb{$itres,"RI_S"};}}
    
    if (! defined $modeprd){
	$modeprd="sec";
	$kwdRi=  "RI_S";
	if (defined $rdb{1,"OMN"} || defined $rdb{1,"OHL"}) {
	    $modeprd="htm";
	    $kwdRi=  "RI_H"      if (defined $rdb{1,"RI_H"});
	}
	$#outnum2sym=0;
	foreach $kwd ("HEL","HL","EL","TL","CL","MN"){
	    if (defined $rdb{1,"O".$kwd}){
		@outnum2sym=split(//,$kwd);
		$kwdPrd="P".$kwd;
		$kwdObs="O".$kwd;
		$mode{"secnumout"}= length($kwd);
		if ($mode{"secnumout"}==3){
		    $par{"errPrd_doq3"}=1;}
		else{
		    $par{"errPrd_doq2"}=1;}
		last;}}
	$mode{"secKwdRi"}= $kwdRi;
	$mode{"secKwdPrd"}=$kwdPrd;
	$mode{"secKwdObs"}=$kwdObs;
	die ("*** ERROR $scrName: failed assigning outnum2sym for $fileIn!\n")
	    if (! $#outnum2sym); 
    }
    elsif ($LisHELBGT){
	$modeprd=           "sec6";
	$mode{"secnumout"}= 6;
	$mode{"secKwdRi"}=  $kwdRi;
	$mode{"secKwdPrd"}= $kwdPrd;
	$mode{"secKwdObs"}= $kwdObs;
	$mode{"outnum2sym"}=join(',',@outnum2sym);
    }
				# further dirty hacks
    if (defined $par{"forceKwdRi"}){
	$mode{"secKwdRi"}= $kwdRi="RI_SNOphd";
    }

    if (0){			# 
	foreach $itres (1..$rdb{"NROWS"}){
	    print "xx $itres oHL=",$rdb{$itres,"OHL"},", p=",$rdb{$itres,"PHL"},"\n";
#	    print "xx $itres orel=",$rdb{$itres,"OREL"},", prel=",$rdb{$itres,"PREL"},"\n";
	}die;}

    $rdb{"NALIGN"}=$rdb{"PROT_NALI"} if (! defined $rdb{"NALIGN"} && defined $rdb{"PROT_NALI"});
				# digest info
				# out GLOBAL: %res, @id
#    foreach $itres (1..$rdb{"NROWS"}){
#	print "xx $itres o=",$rdb{$itres,"OHELBGT"},", p=",$rdb{$itres,"PHELBGT"},"\n";
#    }die;

    ($Lok,$msg)=
	&errPrd_analyseSec($ctprot,$modeprd,$kwdRi,$kwdPrd,$kwdObs,@outnum2sym
			   );   &errScrMsg("failed to analyse for file=$fileIn",$msg) if (! $Lok);
				# SOV
    if ($par{"errPrd_dosov"}){
	($Lok,$msg,@tmp)=
	    &evalsecSovDo($par{"exeSov"},"AA",$kwdPrd,$kwdObs,\%rdb,$par{"fileTmpSov"}
			  );    &errScrMsg("failed evalsecSovDo for file=$fileIn",$msg) if (! $Lok);
	$error{$ctprot,$modeprd,"sov"}=$tmp[1];
	foreach $itout (1..$#outnum2sym){
	    $error{$ctprot,$modeprd,"sov".$outnum2sym[$itout]}=$tmp[1+$itout];
	}
    }
    
}
$nfileIn=$ctprot;
				# hack some error somewhere!
$modeprd="sec6"                 if ($LisHELBGT);

				# ------------------------------
				# (2) postprocess and write
				# ------------------------------
$par{"casp1"}=1                 if ($LisCaspOne);

if ($Lnodie){
    $nfileIn=$ctprot;
}
    
($Lok,$msg)=
    &errPrdFin($nfileIn,$fileOut,$modeprd,\%mode
	       );               &errScrMsg("failed to errPrdFin",$msg) if (! $Lok);

print "--- output in $fileOut\n"
    if (-e $fileOut && $par{"verbose"});
unlink($fileOut)                if ($LisCaspOne);
exit;


#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."ini";     

				# ------------------------------
				# defaults
    %par=(
	  '', "",			# 
	  'title',            "",	    # to be used in output file (added to column names)
	  '', "",			# 
	  'dirHssp',          "/data/hssp/",			
#	  'dirDssp',          "/data/dssp/",
	  'dirDssp',          "/home/eva/server/data/dssp_eva/",

	  'extHssp',          ".hssp",
	  'extDssp',          ".dssp",

	  'extRidet',         ".dat_ri",      # used for output of details on reliability index
	  'extLen',           ".dat_len",     # used for output of details on length distribution


	  'fileTmpSov',       "SOV-".$$."tmp",      # name of file used to communicate with SOV

	  'exeSov',           "/home/rost/pub/prof/bin/sov".".SGI64",
#eva	  'exeSov',           "/home/eva/server/bin/sov".".SGI64",
	  '', "",			# 
	  'errPrd_dori',              1,       # read and compile reliability index
	  'errPrd_doridetail',        0,       # read and compile detailed ri (coverage vs acc)
	  'errPrd_doq2',              0,       # note: assigned according to mode
	  'errPrd_doq3',              1,       # note: assigned according to mode
	  'errPrd_doqN',              0,       # note: many state prediction (for HELBGT)
	  'errPrd_dodetail',          1,       # compile e.g. Q2b%obs,Q2e%obs,Q2e%prd,Q2e%prd
	  'errPrd_dobad',             1,       # compile the confusion H->E, and E->H
	  'errPrd_dosov',             0,       # compile segment-accuracy = SOV score (external program)
	  'errPrd_docontent',         1,       # compile correlation between sec str content
	  'errPrd_doclass',           1,       # compile sec str class error

	  );

    $par{"errPrd_dolength"}=     0;       # compile accuracy in predicting segment lengths

				          #    
    $par{"errPrd_domatthews"}=   1;       # compile Matthews correlation coefficient:
				          #    B W Matthews (1975) Biochim. Biophys. Acta 405, 442-451
				          #                 p(i)*n(i) - u(i)*o(i)
				          #    c(i) = ----------------------------------
				          #           sqrt{ (p(i)+u(i))*(p(i)+o(i))*(n(i)+u(i))*(n(i)+o(i)) }
				          #    
    $par{"errPrd_doinfo"}=       1;       # compile Rost information index:
		      		          #    B Rost & C Sander (1993) JMB, 232, 584-599
		      		          #    
		      		          #            SUM/i,1-3[PRDi*ln(PRDi)] - SUM/ij [Aij * ln Aij]
		      		          #    I = 1 - ------------------------------------------------
		      		          #                NRES*ln(NRES) - SUM/i [OBSi*ln(OBSi)
		      		          #    
		      		          #    with 
		      		          #    
		      		          #    PRDi = number of residues predicted in state i
		      		          #    OBSi = number of residues observed in state i
		      		          #    NRES = number of residues (protein length)
		      		          #    
		      		          #    note: I%obs and I%prd (PRD <-> OBS for the later)
		      		          #    
    $par{"errPrd_domatrix"}=     1;       # compile entire matrix of numbers: Aij=
		      		          #    Aij = residues observed in state i and predicted in j
		      		          #    note: sums for vector stored in Akj (k=4), and Ail (l=4)
		      		          #    

    $par{"class",1}=              "all-alpha";
    $par{"class",2}=              "all-beta";
    $par{"class",3}=              "alpha-beta";
    $par{"class",4}=              "other";

    $par{"class","definition",1}= "len > 60 && percH > 45 && percE <  5";
    $par{"class","definition",2}= "len > 60 && percH <  5 && percE > 45";
    $par{"class","definition",3}= "len > 60 && percH > 30 && percE < 20";
    $par{"class","definition",4}= "else";

    # definition of classes
    # class        Nres   percH  percE
    # all-alpha     > 60   > 45   <  5
    # all-beta      > 60   <  5   > 45
    # alpha-beta    > 60   > 30   > 20
    # other              ELSE 
    # 

    $par{"txt","quote","evalacc"}= "B Rost & C Sander (1994) Proteins, 20:216-226";
    $par{"txt","quote","evalsec"}= "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","evalsov"}= "A Zemla, C Venclovas, K Fidelis and B Rost (1999) Proteins, 34:220-223";


    @kwd=sort (keys %par);

    @kwdRdBody=
	("AA","OHEL","PHEL",
	 "RI_S",
	 "RI_SNOphd",
	 "OHL","PHL","OEL","PEL","OCL","PCL",
	 "OMN","PMN","RI_H",
	 );
    @kwdRdHead=
	("NALIGN","PROT_NALI");
    push(@kwdRdHead,
	 "PROT_NFAR",
	 "PROT_NFAR50-5",
	 "PROT_NFAR40-5",
	 "PROT_NFAR30-5",
	 "PROT_NFAR5")         if ($LdetNali);
    push(@kwdRdHead,
	 "PROT_ID"
	 );
    $#kwdRdHeadNfar=0;
    @kwdRdHeadNfar=
	(
	 "nfar",
	 "nfar50-5",
	 "nfar40-5",
	 "nfar30-5",
	 "nfar5",
	 )                      if ($LdetNali);
	    

    $Ldebug=0;
    $Lverb= 0;
				# ------------------------------
    if ($#ARGV<$scrNarg){	# help
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName $scrIn'\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
	printf "%5s %-15s=%-20s %-s\n","","title",   "x",       "added to column names";
	printf "%5s %-15s=%-20s %-s\n","","sep",     "TAB|SPACE","used to separate columns";

	printf "%5s %-15s=%-20s %-s\n","","dirHssp", "x",       "temporary: give to grep NALIGN (if not local)";
	

	printf "%5s %-15s %-20s %-s\n","","list",    "no value","list of RDB files (automatically recognised: extension '.list')";
	
	printf "%5s %-15s %-20s %-s\n","","<6|helbgt>",   "no value","6 state secondary structure";

	printf "%5s %-15s %-20s %-s\n","","<nali>",       "no value","details on Nali vs accuracy";

	printf "%5s %-15s %-20s %-s\n","","<ri|nori>",    "no value","do (not) reliability index";
	printf "%5s %-15s %-20s %-s\n","","<q2|noq2>",    "no value","do (not) two-state acc";
	printf "%5s %-15s %-20s %-s\n","","<q3|noq3>",    "no value","do (not) three-state acc";
	printf "%5s %-15s %-20s %-s\n","","<sov|nosov>",  "no value","do (not) SOV segment score";
	printf "%5s %-15s %-20s %-s\n","","<bad|nobad>",  "no value","do (not) BAD score";
	printf "%5s %-15s %-20s %-s\n","","<cont|nocont>","no value","do (not) sec str content";
	printf "%5s %-15s %-20s %-s\n","","<len|nolen>",  "no value","do (not) length of segments";

	printf "%5s %-15s %-20s %-s\n","","casp",     "no value","expects CASP format ";
	printf "%5s %-15s %-20s %-s\n","","casp1",    "no value","expects CASP format ONE protein ";
	printf "%5s %-15s %-20s %-s\n","","",         "",        "-> output onto screen with RES=";

	printf "%5s %-15s %-20s %-s\n","","ridet",    "no value","do detailed reliability index";
	printf "%5s %-15s %-20s %-s\n","","",         "",        "-> coverage vs Q3";

	printf "%5s %-15s=%-20s %-s\n","","exe",      "x",       "sov binary (def=".$par{"exeSov"}.")";

	printf "%5s %-15s=%-20s %-s\n","","kwdri",    "RI_SNOphd","use this column for RI";


	printf "%5s %-15s %-20s %-s\n","","nodie",    "no value","continue even when errors";

#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

	printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
	printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
	printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
	if (defined %par && $#kwd > 0){
	    $tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	    $tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	    $tmp2="";
	    foreach $kwd (@kwd){
		next if (! defined $par{$kwd});
		next if ($kwd=~/^\s*$/);
		next if ($kwd=~/^class/);
		next if ($kwd=~/^txt/);
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
#    $fhin="FHIN";
#    $fhout="FHOUT";
    $#fileIn=      0;
    $LisList=      0;
    $sep=          "\t";
    $LisCaspFormat=0;
    $LisCaspOne=   0;
    $LisHELBGT=    0;
    $LdetNali=     0;
    $Lnodie=       0;		# continue through errors in align_a_la_blast

				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	next if ($arg =~ /^pack/);
	if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=                  $1;}
	elsif ($arg=~/^out=(.*)$/i)           { $fileOut=                  $1;}
	elsif ($arg=~/^de?bu?g$/)             { $par{"debug"}=  $Ldebug=   1;
						$par{"verbose"}=$Lverb=    1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $par{"verbose"}=$Lverb=    1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $par{"verbose"}=$Lverb=    0;
						$par{"debug"}=$Ldebug=     0;}
	
	elsif ($arg=~/^(is)?list$/i)          { $LisList=                  1;}

	elsif ($arg=~/^(6|HELBGT|sec6)$/i)    { $LisHELBGT=                1;}

	elsif ($arg=~/^(ri|q2|q3|sov|bad)$/)  { $par{"errPrd_do".$1}=      1;}
	elsif ($arg=~/^(class)$/)             { $par{"errPrd_do".$1}=      1;}
	elsif ($arg=~/^(len|length)$/)        { $par{"errPrd_dolength"}=   1;}
	elsif ($arg=~/^(cont|content)$/)      { $par{"errPrd_docontent"}=  1;}

	elsif ($arg=~/^no(ri|q2|q3|sov|bad)$/){ $par{"errPrd_do".$1}=      0;}
	elsif ($arg=~/^no(cont|content)$/)    { $par{"errPrd_docontent"}=  0;}
	elsif ($arg=~/^no(len|length)$/)      { $par{"errPrd_dolength"}=   0;}
	elsif ($arg=~/^no(class)$/)           { $par{"errPrd_do".$1}=      0;}

	elsif ($arg=~/^ridet.*$/)             { $par{"errPrd_doridetail"}= 1;}
	elsif ($arg=~/^det.*$/)               { $par{"errPrd_dodetail"}=   1;}
	elsif ($arg=~/^nodet.*$/)             { $par{"errPrd_dodetail"}=   0;}

	elsif ($arg=~/^casp$/)                { $LisCaspFormat=            1;}
	elsif ($arg=~/^casp1$/)               { $LisCaspFormat=            1;
						$LisCaspOne=               1;}

	elsif ($arg=~/^sep=(.*)$/)            { $tmp=                      $1;
						$sep="\t"                  if ($tmp=~/TAB/);
						$sep=" "                   if ($tmp=~/SPACE|\s/); }
	elsif ($arg=~/^exe=(.*)$/)            { $par{"exeSov"}=            $1;}

	elsif ($arg=~/^kwdri=(.*)$/)          { $par{"forceKwdRi"}=        $1;}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}

				# details for NALI vs acc?
	elsif ($arg=~/^nali$/)                { $LdetNali=                 1;}

	elsif ($arg=~/^title=(.*)$/)          { $par{"errPrd_title"}=      $1;}

	elsif ($arg=~/^htm$/)                 { $modeprd=                  "htm";}
	elsif ($arg=~/^modepre?d=(.*)$/)      { $modeprd=                  $1;}

	elsif ($arg=~/^nodie$/)               { $Lnodie=                   1;}


	elsif (-e $arg)                       { push(@fileIn,$arg); 
						$LisList=                  1 if ($arg=~/\.list/);}
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 exit;}}}

    $fileIn=$fileIn[1];
    return(&errSbr("*** ERROR $scrName: missing input $fileIn\n"))
	if (! -e $fileIn);
    if (! defined $fileOut){
	if ($LisList || $fileIn[1]=~/\.list/){
	    $tmp=$fileIn[1];
	    $tmp=~s/^.*\///g;$tmp=~s/\.list.*$//g;
	    $fileOut="Out-".$tmp.".dat";}
	else {
	    $fileOut="Out-evalsec.dat";}}

				# ------------------------------
				# change some settings
    if ($LisHELBGT){
	$par{"errPrd_doqN"}=      1;
	$par{"errPrd_dodetail"}=  1;

	$par{"errPrd_doq2"}=      0;
	$par{"errPrd_doq3"}=      0;
	$par{"errPrd_dosov"}=     0;
	$par{"errPrd_dobad"}=     0;
	$par{"errPrd_docontent"}= 0;
	$par{"errPrd_dori"}=      0;
	$par{"errPrd_doinfo"}=    0;
	$par{"errPrd_domatrix"}=  0;
	$par{"errPrd_domatthews"}=0;
#	$par{"errPrd_dori"}=      0;

	@kwdRdBody=
	    ("AA","OHELBGT","PHELBGT","RI_S"
	     );
	$modeprd="sec6";
	$kwdObs= "OHELBGT";
	$kwdPrd= "PHELBGT";
	$kwdRi=  "RI_S";
	@outnum2sym=("H","G","E","B","T","L");
    }

				# add columns to also read
    if (defined $par{"forceKwdRi"}){
	push(@kwdRdBody,$par{"forceKwdRi"});
    }
	

    foreach $kwd (@kwdRdBody){
	$kwdRdBody{$kwd}=1;}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
    $#fileTmp=0;
    foreach $fileIn (@fileIn){
	if ( ! $LisList && $fileIn !~/\.list/) {
	    push(@fileTmp,$fileIn);
	    next;}
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
						 exit; }

	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
    }
    @fileIn= @fileTmp;
    $#fileTmp=0;			# slim-is-in

				# ------------------------------
				# write settings
				# ------------------------------
    if ($par{"verbose"}){
	$exclude="kwd,dir*,ext*,txt*";	# keyword not to write
	$fhloc="STDOUT";
	($Lok,$msg)=
	    &brIniWrt($exclude,$fhloc);
	return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); }

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub evalsecSovDo {
    local($exeSovLoc,$kwdSeqLoc,$kwdPrdLoc,$kwdObsLoc,$rh_rdb,$fileTmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   evalsecSovDo                compiles segment score SOV
#                               by running the SOV program from Fidelis et al.
#                               
#       QUOTE                   A Zemla, C Venclovas, K Fidelis and B Rost (1999) Proteins, 34:220-223
#                               
#       in:                     $exeSovLoc:    SOV binary (call with 'exe FILE')
#       in:                     $kwdSeqLoc:    keyword used in %rdb for sequence
#                                   -> 0  if not defined!
#       in:                     $kwdPrdLoc:    keyword used for prediction  (HEL)
#       in:                     $kwdObsLoc:    keyword used for observation (HEL)
#       in:                     $rdb{"NROWS"}: number of residues
#       in:                     $rdb{$itres,$kwd} kwd=<$kwdRi|$kwdPrd|$kwdObs>
#       in:                     $fileTmpLoc:   temporary file to communicate with C binary
#       in:                     $: 
#                                   the keywords for reliability index           
#                                
#       in:                     $: 
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."evalsecSovDo";
    $fhinLoc="FHIN_"."evalsecSovDo";$fhoutLoc="FHOUT_"."evalsecSovDo";
				# check arguments
    return(&errSbr("not def exeSovLoc!")) if (! defined $exeSovLoc);
    return(&errSbr("not def kwdSeqLoc!")) if (! defined $kwdSeqLoc);
    return(&errSbr("not def kwdPrdLoc!")) if (! defined $kwdPrdLoc);
    return(&errSbr("not def kwdObsLoc!")) if (! defined $kwdObsLoc);
    return(&errSbr("not def rh_rdb!"))    if (! defined $rh_rdb);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no exeSovLoc=$exeSovLoc!")) if (! -e $exeSovLoc && ! -l $exeSovLoc);

				# ------------------------------
				# local settings
    $fileTmpLoc="SOV".$$.".tmp" if (! defined $fileTmpLoc || ! $fileTmpLoc) ;

				# ------------------------------
				# write file to input to SOV
    open($fhoutLoc,">".$fileTmpLoc) || return(&errSbr("fileTmpLoc=$fileTmpLoc, not created"));
    printf $fhoutLoc "%-3s %-4s %-4s\n","AA","OSEC","PSEC";
    foreach $itres (1.. $rh_rdb->{"NROWS"}){
	$seq=$rh_rdb->{$itres,"AA"};
				# skip strange ones
	next if ($seq eq "!");
	$prd=$rh_rdb->{$itres,$kwdPrdLoc}; $prd=~s/[ L]/C/;
	$obs=$rh_rdb->{$itres,$kwdObsLoc}; $obs=~s/[ L]/C/;
	printf $fhoutLoc 
	    "%-3s %-4s %-4s\n",$seq,$obs,$prd;
    }
    close($fhoutLoc);

				# ------------------------------
				# run it
    $cmd=$exeSovLoc." ".$fileTmpLoc;
    $#tmpout=0;
    @tmp=`$cmd`;		# system call!
    foreach $tmp (@tmp){
	if ($tmp =~ /^\s+SOV[\s\t]+:\s+(\d.*)\s*$/){
	    $line=$1;
	    @tmpout=split(/[\s\t]+/,$line);
	    last;
	}
    }
    return(&errSbr("SOV ($cmd) failed to get SOV scores\n".join('',@tmp,"\n")))
	if (! $#tmpout);
				# clean up
    unlink($fileTmpLoc);
    $#tmp=0;			# slim-is-in
    return(1,"ok $sbrName",@tmpout);
}				# end of evalsecSovDo

#===============================================================================
sub evalsecSovWrt {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   evalsecSovWrt                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."evalsecSovWrt";
    $fhinLoc="FHIN_"."evalsecSovWrt";$fhoutLoc="FHOUT_"."evalsecSovWrt";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty


    } close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of evalsecSovWrt

#===============================================================================
sub hackGrepNali {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hackGrepNali                gets NALIGN from HSSP file
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."hackGrepNali";
				# check arguments
    return(&errSbr("not def fileInLoc!"))     if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

    $fileHssp=$fileInLoc; 
    $fileHssp=~s/^.*\///g;	# purged dir
    $fileHssp=~s/\.(rdb|phd).*$//g; # purge ext
    $fileHssp.=$par{"extHssp"}  if ($fileHssp !~/$par{"extHssp"}/);
    $fileHssp=$par{"dirHssp"}.$fileHssp
	if (! -e $fileHssp);
	

    return(2,"missing HSSP file $fileHssp (you may have to set dirHssp=x on command line)")
       if (! -e $fileHssp);
    $tmp=`grep '^NALIGN  ' $fileHssp`;
    $tmp=~s/\n//g;
    $tmp=~s/^NALIGN\s*//g;
    $tmp=~s/\s//g;
    return(1,"ok $sbrName",$tmp);
}				# end of hackGrepNali

#===============================================================================
sub rdCaspObsPrd {
    local ($fileInLoc) = @_ ;
    local($SBR6,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdCaspObsPrd                reads content of CASP file with obs AND prd
#       in:                     $fileInLoc
#       out:                    rdrdb{"NALIGN"},rdrdb{$ct,"POS"},rdrdb{$ct,"NPROT"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR6=$tmp."rdCaspObsPrd";
    $fhinLoc="FHIN_"."rdCaspObsPrd";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!",   $SBR6)) if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!",$SBR6)) if (! -e $fileInLoc && ! -l $fileInLoc);

       				# extract id
    $idLoc=$fileInLoc;
    $idLoc=~s/^.*\/|\..*$//g;
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

				# ------------------------------
				# read file header
    while (<$fhinLoc>) {
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty
	$line=$_;
	last if ($_=~/PSEC/   ||
		 $_=~/^[A-Z]\s+/); }

    undef %rdb;
    $#ptr_num2name=$#col2read=0;
    $ctrow=0;
				# ------------------------------
				# is simple CASP -> no observed
    if ($line =~ /^[A-Z]\s+/){
	@tmp=split(/\s+/,$line);
	$ptr_num2name[1]="AA";
	$ptr_num2name[2]="PHEL";
	push(@col2read,1,2);
	if ($#tmp > 2){
	    $ptr_num2name[3]="RI_S";
	    push(@col2read,3);}
	++$ctrow;
	foreach $it (@col2read){
	    $rdb{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	}}
				# ------------------------------
				# names for CASP-mutants
    else {
	@tmp=split(/\s+/,$line);
	foreach $it (1..$#tmp){ 
	    $kwd=$tmp[$it];
	    $Lok=0;
	    if    ($kwd eq "OSEC"){
		$ptr_num2name[$it]="OHEL"; $Lok=1; }
	    elsif ($kwd eq "PSEC"){
		$ptr_num2name[$it]="PHEL"; $Lok=1; }
	    elsif ($kwd eq "RISEC"){
		$ptr_num2name[$it]="RI_S"; $Lok=1; }
	    elsif ($kwd eq "AA"){
		$ptr_num2name[$it]="AA";   $Lok=1; }
	    push(@col2read,$it)     if ($Lok);
	}}

				# ------------------------------
				# read file body
    while (<$fhinLoc>) {
	last if ($_=~/^(END|ACC)/);
	$_=~s/\n//g;
	$line=$_;
	++$ctrow;
	@tmp=split(/\s+/,$line);
	foreach $it (@col2read){
	    $rdb{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	}
    } 
    close($fhinLoc);
    $rdb{"NROWS"}=$ctrow;

				# ------------------------------
				# now add observed if missing!
    if (! defined $rdb{1,"OHEL"}){
				# search for file
	$tmp=$fileInLoc;
	$tmp=~s/^.*\///g;	# purge dir
	$tmp=~s/\.[^\.]*$//g;	# purge ext
	$chn=" ";
	$tmp2=$tmp;
	$tmp=~s/[:_](.)$//g;	# purge chain
	$chn=$1 if (defined $1);
	$fileDssp=$par{"dirDssp"}.$tmp.$par{"extDssp"};
	if (! -e $fileDssp){
	    $fileDssp=$par{"dirDssp"}.$tmp2.$par{"extDssp"};
	    $chn=" ";}
	$fileHssp=$par{"dirHssp"}.$tmp.$par{"extHssp"};
	if (! -e $fileHssp && ! -e $fileDssp){
	    $fileHssp=$par{"dirHssp"}.$tmp2.$par{"extHssp"};
	    $chn=" ";}
	$fileType="dssp";
	if    (! -e $fileDssp && ! -e $fileHssp){
	    print "*** ERROR $SBR6 missing fileDssp=$fileDssp, incasp=$fileInLoc\n";
	    print "*** ERROR $SBR6 missing also fileHssp=$fileHssp, incasp=$fileInLoc\n";
	    die;}
	elsif (! -e $fileDssp){
	    $fileType="hssp";
	}
				# read DSSP
	if ($fileType eq "dssp"){
	    ($Lok,$msg)=
		&dsspRdSeqSecAcc
		    ($fileDssp,$chn,
		     "seq,sec"
		     );         return(&errSbrMsg("after dsspRdSeqSecAcc($fileDssp,$chn)",
						  $msg,$SBR6))  if (! $Lok); 
	}
				# read HSSP
	else {
	    ($Lok,$msg)=
		&hsspRdSeqSecAcc
		    ($fileHssp,$chn,
		     "seq,sec"
		     );         return(&errSbrMsg("after hsspRdSeqSecAcc($fileHssp,$chn)",
						  $msg,$SBR6))  if (! $Lok); 
	}
				# convert lower case to C
	$seqdssp="";
	foreach $itres (1..$tmp{"NROWS"}){
	    if ($tmp{$itres,"seq"} =~ /^[A-Z]$/){
		$seqdssp.=$tmp{$itres,"seq"};
		next; }
	    $tmp{$itres,"seq"}="C";
	    $seqdssp.=$tmp{$itres,"seq"};
	}
	$seqpred="";
#	$secpred="";
#	$secobs="";
	foreach $itres (1..$rdb{"NROWS"}){
	    $seqpred.=$rdb{$itres,"AA"};
#	    $secpred.=$rdb{$itres,"PHEL"};
#	    $secobs.=$tmp{$itres,"sec"};
	}
				# check sequences
	($Lok,$msg,$max,$beg1,$beg2)=
	    &align_a_la_blast($seqpred,$seqdssp);
	if ($max < 30){
	    print "xx returned $Lok,$msg, file=$fileInLoc, dssp=$fileDssp\n";
	    print "xx dssp=$seqdssp\n";
	    print "xx pred=$seqpred\n";
	    print "xx max=$max, beg1=$beg1, b eg2=$beg2\n";
	    return(2,"skip problem");
	    die;
	}

				# seems ok, just correct: 1st array
	undef %rdb2;
	$ct=0;
	foreach $it (1..$rdb{"NROWS"}){
	    next if ($it < $beg1);
	    next if ($it > ($beg1-1+$max));
	    ++$ct;
	    foreach $kwd ("RI_S","AA","PHEL"){
		$rdb2{$ct,$kwd}=$rdb{$it,$kwd};
	    }
	}
	$rdb2{"NROWS"}=$ct;
	%rdb=%rdb2;
				# seems ok, just correct: 2nd read structure
	$ct2=$beg2-1;$ct=0;
	$obs="";
	foreach $it (1..$rdb{"NROWS"}){
	    ++$ct2;
	    ++$ct; 
	    last if ($ct > $max);
	    $obs.=$tmp{$ct2,"sec"};
	    if ($rdb{$it,"AA"} ne $tmp{$ct2,"seq"}){ # 
		print "xx it=$it, ct2=$ct2, prdseq=",$rdb{$it,"AA"},", dsspseq=",$tmp{$ct2,"seq"},", dssp=",$tmp{$ct2,"sec"},",\n";
		die;}
	}

				# convert sec str
	($Lok,$msg,$obs_convert)=
	    &convert_secFine($obs,"HEL");
	foreach $itres (1..$rdb{"NROWS"}){
	    if (length($obs) < $itres){
		print "xx problem itres=$itres, len(obs)=",length($obs)," obs=$obs, \n";
		die;}		# 
	    $rdb{$itres,"OHEL"}=substr($obs_convert,$itres,1);
	}
    }
    
				# ------------------------------
				# replace 'C' -> 'L' (convert)
				#    RI -> 10*RI
    foreach $itres (1..$rdb{"NROWS"}){
	$rdb{$itres,"OHEL"}=~s/C/L/;
	$rdb{$itres,"PHEL"}=~s/C/L/;
	$tmp1.=$rdb{$itres,"OHEL"};
	$tmp2.=$rdb{$itres,"PHEL"};
	$rdb{$itres,"RI_S"}=int(10*$rdb{$itres,"RI_S"})
	    if (defined $rdb{$itres,"RI_S"});
    }
    if ($Ldebug){
	print "$SBR6 id=$idLoc, file=$fileInLoc\n";
	print "sec obs:$tmp1\n";
	print "sec prd:$tmp2\n";
    }

    return(1,"ok $SBR6");
}				# end of rdCaspObsPrd

#===============================================================================
sub rdRdb_here {
    local ($fileInLoc) = @_ ;
    local ($sbr_name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdb_here            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{$ct,"POS"},rdrdb{$ct,"NPROT"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $sbr_name="rdRdb_here";
				# set some defaults
    $fhinLoc="FHIN_RDB";
				# get input
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("failed opening fileIn=$fileInLoc!\n",$sbr_name));
    undef %rdb;
    $#ptr_num2name=$#col2read=0;

    $ctLoc=$ctrow=0;
				# ------------------------------
				# header  
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
	if ($_=~/^\#/ ) { 
	    if ($_=~/PARA|VALUE/ ||
		$_=~/:\s*\d/ && $_!~/NOTATION/){
		foreach $kwd (@kwdRdHead){
		    next if (defined $rdb{$kwd});
		    if ($_=~/^.*$kwd\s*[ :,\;=]+(\S+)/){
			$tmp=$1;
			$kwd2=$kwd; $kwd2=~tr/[A-Z]/[a-z]/; $kwd2=~s/prot_//g;
			$rdb{$kwd2}=$rdb{$kwd}=$tmp;
			print "xx kwd=$kwd, kwd2=$kwd2, tmp=$tmp\n";
			next; 
		    }
		}
	    }
	    next; }
				# temporary hack xx
	next if ($_=~/^\s*Note/);
	last; }
				# ------------------------------
				# names
    $kwdRdBody{"OtH"}=1;$kwdRdBody{"OtE"}=1;$kwdRdBody{"OtL"}=1; # xx
    @tmp=split(/\s*\t\s*/,$line);
    foreach $it (1..$#tmp){
	$kwd=$tmp[$it];
	next if (! defined $kwdRdBody{$kwd});
	$ptr_num2name[$it]=$kwd;
	push(@col2read,$it); 
    }

    $ctLoc=2;
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
				# ------------------------------
				# skip format?
	if    ($ctLoc==2 && $line!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc;}
	elsif ($ctLoc==2){
	    next; }
				# ------------------------------
				# data
	if ($ctLoc>2){
	    ++$ctrow;
	    @tmp=split(/\s*\t\s*/,$line);
	    foreach $it (@col2read){
		$rdb{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	    }

				# xx
	    if (0){		# compile probability based reliability index
		$max=$sum=0;
		foreach $kwd ("OtH","OtE","OtL"){
		    $sum+=$rdb{$ctrow,$kwd};
		    if ($max<$rdb{$ctrow,$kwd}){$max=$rdb{$ctrow,$kwd};}
		}
		$rdb{$ctrow,"RI_S"}=int(10*($max/$sum));
		$rdb{$ctrow,"RI_S"}=0 if ($rdb{$ctrow,"RI_S"}<0);
		$rdb{$ctrow,"RI_S"}=9 if ($rdb{$ctrow,"RI_S"}>10);
	    }
	}
    }
    close($fhinLoc);
    $rdb{"NROWS"}=$ctrow;
    return (1,"ok");
}				# end of rdRdb_here

#==============================================================================
# library collected (begin) lll
#==============================================================================

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

#==============================================================================
sub brIniWrt {
    local($exclLoc,$fhTraceLocSbr)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniWrt                    write initial settings on screen
#       in:                     $excl     : 'kwd1,kwd2,kw*' exclude from writing
#                                            '*' for wild card
#       in:                     $fhTrace  : file handle to write
#                                  = 0, or undefined -> STDOUT
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniWrt";
    
    return(0,"*** $sbrName: no settings defined in %par\n") if (! defined %par || ! %par);
    $fhTraceLocSbr="STDOUT"    if (! defined $fhTraceLocSbr || ! $fhTraceLocSbr);

    if (defined $Date) {
	$dateTmp=$Date; }
    else {
	$tmp=`date`; $tmp=~s/\n//g if (defined $tmp);
	$dateTmp=$tmp || "before year 2000"; }

    print $fhTraceLocSbr "--- ","-" x 80, "\n";
    print $fhTraceLocSbr "--- Initial settings for $scrName ($0) on $dateTmp:\n";
    @kwd= sort keys (%par);
				# ------------------------------
				# to exclude
    @tmp= split(/,/,$exclLoc)   if (defined $exclLoc);
    $#exclLoc=0; 
    undef %exclLoc;
    foreach $tmp (@tmp) {
	if   ($tmp !~ /\*/) {	# exact match
	    $exclLoc{"$tmp"}=1; }
	else {			# wild card
	    $tmp=~s/\*//g;
	    push(@exclLoc,$tmp); } }
    if ($#exclLoc > 0) {
	$exclLoc2=join('|',@exclLoc); }
    else {
	$exclLoc2=0; }
	
    
	    
    $#kwd2=0;			# ------------------------------
    foreach $kwd (@kwd) {	# parameters
	next if (! defined $par{$kwd});
	next if ($kwd=~/expl$/);
	next if (length($par{$kwd})<1);
	if ($kwd =~/^fileOut/) {
	    push(@kwd2,$kwd);
	    next;}
	next if ($par{$kwd} eq "unk");
	next if (defined $exclLoc{$kwd}); # exclusion required
	next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}
				# ------------------------------
    if ($#kwd2>0){		# output files
	print $fhTraceLocSbr "--- \n","--- Output files:\n";
	foreach $kwd (@kwd2) {
	    next if ($par{$kwd} eq "unk"|| ! $par{$kwd});
	    next if (defined $exclLoc{$kwd}); # exclusion required
	    next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	    printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}}
				# ------------------------------
				# input files
    if    (defined @fileIn && $#fileIn>1){
				# get dirs
	$#tmpdir=0; 
	undef %tmpdir;
	foreach $file (@fileIn){
	    if ($file =~ /^(.*\/)[^\/]/){
		$tmp=$1;$tmp=~s/\/$//g;
		if (! defined $tmpdir{$tmp}){push(@tmpdir,$tmp);
					     $tmpdir{$tmp}=1;}}}
				# write
	print  $fhTraceLocSbr "--- \n";
	printf $fhTraceLocSbr "--- %-20s number =%6d\n","Input files:",$#fileIn;
	printf $fhTraceLocSbr "--- %-20s dirs   =%-s\n","Input dir:", join(',',@tmpdir) 
	    if ($#tmpdir == 1);
	printf $fhTraceLocSbr "--- %-20s dirs   =%-s\n","Input dirs:",join(',',@tmpdir) 
	    if ($#tmpdir > 1);
	for ($it=1;$it<=$#fileIn;$it+=5){
	    print $fhTraceLocSbr "--- IN: "; 
	    $it2=$it; 
	    while ( $it2 <= $#fileIn && $it2 < ($it+5) ){
		$tmp=$fileIn[$it2]; $tmp=~s/^.*\///g;
		printf $fhTraceLocSbr "%-18s ",$tmp;++$it2;}
	    print $fhTraceLocSbr "\n";}}
    elsif ((defined @fileIn && $#fileIn==1) || (defined $fileIn && -e $fileIn)){
	$tmp=0;
	$tmp=$fileIn    if (defined $fileIn && $fileIn);
	$tmp=$fileIn[1] if (! $tmp && defined @fileIn && $#fileIn==1);
	print  $fhTraceLocSbr "--- \n";
	printf $fhTraceLocSbr "--- %-20s '%-s'\n","Input file:",$tmp;}
    print  $fhTraceLocSbr "--- \n";
    printf $fhTraceLocSbr "--- %-20s %-s\n","excluded from write:",$exclLoc 
	if (defined $exclLoc);
    print  $fhTraceLocSbr "--- \n","--- ","-" x 80, "\n","--- \n";
	
    return(1,"ok $sbrName");
}				# end of brIniWrt

#===============================================================================
sub convert_accRel2oneDigit {
    local ($accRelLoc) = @_;
    $[=1;
#----------------------------------------------------------------------
#   convert_accRel2oneDigit     project relative acc to numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$converted_acc
#       err:                    (1,'ok'), (0,'message')
#----------------------------------------------------------------------
				# check input
    return(0,"*** ERROR convert_accRel2oneDigit: relAcc=$accRelLoc???\n")
	if ( $accRelLoc < 0 );
				# SQRT
    $out= int ( sqrt ($accRelLoc) );
                                # saturation: limit to 9
    $out= 9  if ( $out >= 10 );
    return(1,"ok",$out);
}				# end of convert_accRel2oneDigit

#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
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

#==============================================================================
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
    &open_file("$fhinLoc","$fileInLoc") ||
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

#===============================================================================
sub get_zscore { local ($score,@data) = @_ ; local ($ave,$var,$sig,$zscore);
		 $[ =1 ;
#--------------------------------------------------------------------------------
#   get_zscore                  returns the zscore = (score-ave)/sigma
#       in:                     $score,@data
#       out:                    zscore
#--------------------------------------------------------------------------------
		 ($ave,$var)=&stat_avevar(@data);
		 $sig=sqrt($var);
		 if ($sig != 0){ $zscore=($score-$ave)/$sig; }
		 else          { print"xx get_zscore: sig=$sig,=0?\n";$zscore=0; }
		 return ($zscore);
}				# end of get_zscore

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
# library collected (end)   lll
#==============================================================================
