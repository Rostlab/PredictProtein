#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "read BLAST.rdb and spits out list of pairs for uniqueList.pl";
$scrIn=      "*blastRdb";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " writes list of pairs for 'uniqueList.pl'\n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="NOTE: input file expected to have column: id1,id2,lali,pide,dist \n";
$scrHelpTxt.="      change \$ptr\{\} in iniDef to adopt to other files!\n";
$scrHelpTxt.="NOTE2: fasta files of all the proteins in the input file MUST exist!!!\n";
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
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Aug,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();
if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
	      die '*** during initialising $scrName   ';}

				# ------------------------------
				# variables
				# ------------------------------

				# ------------------------------
				# note: remaining only for 
				#       option 'doMirro'
				# 
$#fin=0; $nprot=0;		# final rdb for option: mirror 
				#    protein mue, column it (see %ptr defined in iniDef)
				#    $fin[$mue][$it] mue=1..nprot
$#ptr_this2fin=0;		#    $ptr_this2fin[$itrow]=$mue for particular file the
				#        row $itrow points to the final counting (@fin) mue
undef %finRes;			# final resolution $finRes{"$id1"}
undef %finLen;			# final length $finRes{"$id1"}

				# --------------------------------------------------
				# read PDB resolution
				# out GLOBAL: $res{"$id"} 
				#     resolution for $id (note: NO chains!!)
				# --------------------------------------------------
if ($par{"doPairs"} && defined $fileRes) {
    ($Lok,$msg)=
	&fileResRd($fileRes);   &errScrMsg("*** ERROR $scrName: after fileResRd=$fileRes:",
					   $msg,$scrName) if (! $Lok);}

				# --------------------------------------------------
				# process file(s)
				# --------------------------------------------------
open($fhout,">".$fileOutPairs) ||
    die("*** ERROR $scrName: failed opening fileOutPairs=$fileOutPairs!\n");
print $fhout
    "# Perl-RDB  blastProcessRdb format\n",
    "# --------------------------------------------------------------------------------\n",
    "# FORM  beg          blastProcessRdb \n",
    "# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n",
    "# FORM  general:     - columns are delimited by tabs\n",
    "# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n",
    "# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n",
    "# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n",
    "# FORM  1st row:     column names  (tab delimited)\n",
    "# FORM  2nd row (may be): column format (tab delimited)\n",
    "# FORM  rows 2|3-N:  column data   (tab delimited)\n",
    "# FORM  end          blastProcessRdb \n",
    "# --------------------------------------------------------------------------------\n",
    "# NOTA  begin        blastProcessRdb ABBREVIATIONS\n",
    "# NOTA               column names \n",
    "# NOTA: id1          =  first identifier\n",
    "# NOTA: len          =  length of id1\n",
    "# NOTA: id2          =  second identifier     (list separated by ',')\n",
    "# NOTA: dist         =  distance between id1 and id2 from threshold (list separated by ',')\n",
    "# NOTA               parameters\n",
    "# PARA  end          blastProcessRdb \n",
    "# --------------------------------------------------------------------------------\n";
print $fhout
    "id1","\t","len","\t","id2","\t","dist","\n";

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on filein=$fileIn!\n" if ($par{"verbose"});

    open($fhin, $fileIn) || die '*** $scrName ERROR opening filein=$fileIn';
    $ctrowErr=0;
				# ------------------------------
				# header
    $ptr_id1=$ptr_id2=$ptr_lali=$ptr_pide=$ptr_dist=$ptr_prob=$ptr_score=0;
    while (<$fhin>) {
	++$ctrowErr;
	next if ($_=~/^\#/);	# skip comments
	if ($_=~/^id1/){
	    @tmp=split(/\s*\t\s*/,$_);
	    foreach $it (1..$#tmp){
		if    ($tmp[$it]=~/id1/)  { $ptr_id1=$it;}
		elsif ($tmp[$it]=~/id2/)  { $ptr_id2=$it;}
		elsif ($tmp[$it]=~/lali/) { $ptr_lali=$it;}
		elsif ($tmp[$it]=~/pide/) { $ptr_pide=$it;}
		elsif ($tmp[$it]=~/dist/) { $ptr_dist=$it;}
		elsif ($tmp[$it]=~/prob/) { $ptr_prob=$it;}
		elsif ($tmp[$it]=~/score/){ $ptr_score=$it;}
		else {
		    print "*** WARN file=$fileIn, it=$it, name=$tmp[$it], not recognised!\n";}
	    }
	    die("*** missing id1=$ptr_id1, or id2=$ptr_id2, or lali=$ptr_lali, or dist=$ptr_dist,")
		if (! defined $ptr_id1  || ! defined $ptr_id2 || 
		    ! defined $ptr_lali || ! defined $ptr_dist);
	    last;}}

				# ------------------------------
				# body
    $id1Prev=0;
    $ct=$ctId1=0;
    while (<$fhin>) {
	++$ctrowErr;
	++$ct;
	next if ($_=~/none/);	# skip empty
	$_=~s/\n//g;
	$line=$_;
	$_=~s/^\s*|\s*$//g;	# security: purge leading blanks
				# lower caps
	$_=~tr/[A-Z]/[a-z]/
	    if ($LnamesLower);
				# br hack 2001-03 ignore lines with mistakes
	next if ($_=~/^[0-9\.]+\t/);

	@tmp=split(/\s*\t\s*/,$_);
				# ignore self
	next if ($tmp[$ptr_id1] eq $tmp[$ptr_id2]);
				# ignore too close
	next if ($par{"doThresh"} && $tmp[$ptr_dist]<$par{"minDist"});

	if ($tmp[$ptr_id1] ne $id1Prev){
				# write all
	    if ($id1Prev){
		print $fhout
		    $tmp[$ptr_id1],"\t",$len,"\t",$id2;
		print $fhout
		    "\t",$dist  if ($par{"doThresh"});
		print $fhout
		    "\n";
	    }
	    ++$ctId1;
	    $id1Prev=$tmp[$ptr_id1];
	    $dist=  int($tmp[$ptr_dist]) if ($par{"doThresh"}) ;
	    $id2=   $tmp[$ptr_id2];
	    undef %id2tmp;
				# get original sequence
	    $fileFasta=$par{"dirDataOrigin"}.$id1Prev.$par{"extOrigin"};
	    if (! -e $fileFasta) {
		$tmp=$id1; $tmp=~s/^[^\_]+\_(.).*$/$1/g;
		$fileFasta=$par{"dirDataOrigin"}.$tmp."/".$id1.$par{"extOrigin"};}
	    &errScrMsg("original fasta id=$id1Prev ($fileFasta, dirDataOrigin=x) missing")   
		if (! -e $fileFasta);
	    &errScrMsg("original fasta ($fileFasta) not FASTA")
		if (! &isFasta($fileFasta));
	    ($Lok,$id,$seq)=
		&fastaRdGuide($fileFasta);
	    &errScrMsg("failed reading fasta ($fileFasta)",$id) if (! $Lok);
		
	    $seq=~s/[^A-Za-z]//g;
	    $len=length($seq); 
	}
				# add to previous (avoid duplication)
	elsif (! defined $id2tmp{$tmp[$ptr_id2]}) {
	    $dist.=  ",".int($tmp[$ptr_dist]) if ($par{"doThresh"}) ;
	    $id2.=   ",".$tmp[$ptr_id2];
	}

				# where are we?
	print "--- reading row=$ctRowErr, ctid1=$ctId1\n" if (defined $ctRowErr  &&
							      $ctRowErr > 10000  && 
							      (int($ctRowErr/10000)==$ctRowErr/10000));
	
    }
    close($fhin);
				# write last
    print $fhout
	$id1Prev,"\t",$len,"\t",$id2;
    print $fhout
	"\t",$dist  if ($par{"doThresh"});
    print $fhout
	"\n";
    close($fhout);
}
				# ------------------------------
if ($par{"verbose"}) { 
    print "--- $scrName ended fine .. -:\)\n";

    $timeEnd=time; # runtime , run time
    $timeRun=$timeEnd-$timeBeg;
    print 
	"--- date     \t \t $Date \n",
	"--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";

#    printf "--- output id1 (%5d) in %-s\n",$#id1All,$fileOutId1    if (-e $fileOutId1);
#    printf "---        id2 (%5d) in %-s\n",$#id2All,$fileOutId2    if (-e $fileOutId2); 
    printf "---      pairs (%5d) in %-s\n",$ctId1, $fileOutPairs  if (-e $fileOutPairs); 
#    printf "---     mirror (%5d) in %-s\n",$nprot,  $fileOutMirror if (-e $fileOutMirror); 
}
exit;


#==============================================================================
# library collected (begin)
#==============================================================================


#===============================================================================
sub blastGetSummary {
    local($fileInLoc,$minLaliLoc,$minDistLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,%hdrLoc,@idtmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastGetSummary             BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#       in:                     $fileInLoc    : file with BLAST output
#       in:                     $minLaliLoc   : take those with LALI > x      (=0: all)
#       in:                     $minDistLoc   : take those with $pide>HSSP+X  (=0: all)
#       out:                    1|0,msg,$tmp{}, with
#                               $tmp{"NROWS"}     : number of pairs
#                               $tmp{"id",$it}    : name of protein it
#                               $tmp{"len",$it}   : length of protein it
#                               $tmp{"lali",$it}  : length of alignment for protein it
#                               $tmp{"prob",$it}  : BLAST probability for it
#                               $tmp{"score",$it} : BLAST score for it
#                               $tmp{"pide",$it}  : pairwise percentage sequence identity
#                               $tmp{"dist",$it}  : distance from HSSP-curve
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastGetSummary";$fhinLoc="FHIN_"."blastGetSummary";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # adjust
    $minLaliLoc=0               if (! defined $minLaliLoc || ! $minLaliLoc);
    $minDistLoc=-100            if (! defined $minDistLoc || ! $minDistLoc);
                                # ------------------------------
                                # read file
                                # ------------------------------
    undef %hdrLoc;
    ($Lok,$msg,%hdrLoc)=   
        &blastpRdHdr($fileInLoc);
    return(&errSbrMsg("failed reading blast header ($fileInLoc)",$msg)) if (! $Lok);

    $hdrLoc{"id"}=~s/,*$//g;       # interpret
    @idtmp=split(/,/,$hdrLoc{"id"});
                                # ------------------------------
                                # loop over all pairs found
                                # ------------------------------
    undef %tmp; 
    $ct=0;
    foreach $idtmp (@idtmp) {
        next if ($hdrLoc{"$idtmp","lali"} < $minLaliLoc);
                                # compile distance to HSSP threshold (new)
        ($pideCurve,$msg)= 
#            &getDistanceHsspCurve($hdrLoc{"$idtmp","lali"});
            &getDistanceNewCurveIde($hdrLoc{"$idtmp","lali"});
        return(&errSbrMsg("failed getDistanceNewCurveIde",$msg))  
            if ($msg !~ /^ok/);
            
        $dist=$hdrLoc{"$idtmp","ide"}-$pideCurve;
        next if ($dist < $minDistLoc);
                                # is ok -> TAKE it
        ++$ct;
        $tmp{"id","$ct"}=       $idtmp;
	foreach $kwd ("len","lali","prob","score"){
	    $tmp{"$kwd","$ct"}= $hdrLoc{"$idtmp","$kwd"}; }
        $tmp{"pide","$ct"}=     $hdrLoc{"$idtmp","ide"};
        $tmp{"dist","$ct"}=     $dist;
    } 
    $tmp{"NROWS"}=$ct;
    %rd=%tmp;
    undef %hdrLoc;		# slim-is-in !
    undef %tmp;			# slim-is-in !
    return(1,"ok $sbrName");
}				# end of blastGetSummary

#===============================================================================
sub blastpRdHdr {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@idFoundLoc,
	  $Lread,$name,%hdrLoc,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRdHdr                 reads header of BLASTP output file
#       in:                     $fileBlast
#       out:                    (1,'ok',%hdrLoc)
#       out:                    $hdrLoc{"$id"}='id1,id2,...'
#       out:                    $hdrLoc{"$id","$kwd"} , with:
#                                  $kwd=(score|prob|ide|len|lali)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpRdHdr";$fhinLoc="FHIN-blastpRdHdr";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")    if (! defined $fileInLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc") if (! -e $fileInLoc);
				# ------------------------------
				# open BLAST output
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n");
				# ------------------------------
    $#idFoundLoc=$Lread=0;	# read file
    while (<$fhinLoc>) {
	last if ($_=~/^\s*Sequences producing /i);}
				# ------------------------------
				# skip header summary
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)<1 || $_ !~/\S/); # skip empty line
	$Lread=1 if (! $Lread && $_=~/^\s*>/);
	next if (! $Lread);
	last if ($_=~/^\s*Parameters/i); # final
				# ------------------------------
	$line=$_;		# read ali paras
				# id
	if    ($line=~/^\s*>\s*(.*)/){
	    $name=$1;$id=$name;$id=~s/^([\S]+)\s+.*$/$1/g;
	    if (length($id)>0){
		push(@idFoundLoc,$id);$Lskip=0;
		$hdrLoc{"$id","name"}=$name;}
	    else              {
		$Lskip=1;}}
				# length
	elsif (! $Lskip && ! defined $hdrLoc{"$id","len"} && 
	       ($line=~/^\s*Length = (\d+)/)) {
	    $hdrLoc{"$id","len"}=$1;}
				# sequence identity
	elsif (! $Lskip && ! defined $hdrLoc{"$id","ide"} &&
	       ($line=~/^\s* Identities = \d+\/(\d+) \((\d+)/) ) {
	    $hdrLoc{"$id","lali"}=$1;
	    $hdrLoc{"ide","$id"}=$hdrLoc{"$id","ide"}=$2;}
				# score + prob (blast3)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = [\d\.]+ bits \((\d+)\).*, Expect = \s*([\d\-\.e]+)/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}
				# score + prob (blast2)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}}close($fhinLoc);
				# ------------------------------
    $hdrLoc{"id"}="";		# arrange to pass the result
    for $id(@idFoundLoc){
	$hdrLoc{"id"}.="$id,"; } $hdrLoc{"id"}=~s/,*$//g;

    $#idFoundLoc=0;		# save space
    return(1,"ok $sbrName",%hdrLoc);
}				# end of blastpRdHdr 

#==============================================================================
sub brIniErr {
    local($local)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniErr                    error check for initial parameters
#       in GLOBAL:              $par{},@ARGV
#       in:                     $exceptions = 'kwd1,kwd2'
#                                  key words not to check for file existence
#       out:                    ($Lok,$msg)
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."brIniErr";
    @kwd= keys (%par)       if (defined %par && %par);
				# ------------------------------
				# exclude some keyword from check?
    undef %tmp; 
    $#excl=0;
    @excl=split(/,/,$local) if (defined $local);
    if ($#excl>0){
	foreach $kwd(@excl){
	    $tmp{$kwd}=1;}}
    $msgHere="";
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{$kwd});
	if   ($kwd=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' not executable!\n".
                "***       do the following \t 'chmod +x ".$par{$kwd}."'\n"
                    if (! -x $par{$kwd});}
	elsif($kwd=~/^file/){
	    next if ($par{$kwd} eq "unk" || length($par{$kwd})==0 || !$par{$kwd});
	    $msgHere.="*** ERROR file ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});} # 
    }
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of brIniErr

#==============================================================================
sub brIniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniGetArg                 standard reading of command line arguments
#       in GLOBAL:              @ARGV,$defaults{},$par{}
#       out GLOBAL:             $par{},@fileIn
#       out:                    @arg_not_understood (i.e. returns 0 if everything ok!)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniGetArg";
    $#argUnk=0;                 # ------------------------------
				# (1) get input directory
    foreach $arg (@ARGV){	# search in command line
	if ($arg=~/^dirIn=(.+)$/){$par{"dirIn"}=$1;
				  last;}}
				# search in defaults
    if ((! defined $par{"dirIn"} || ! -d $par{"dirIn"}) && 
 	defined %defaults && %defaults){
	if (defined $defaults{"dirIn"}){
	    $par{"dirIn"}=$defaults{"dirIn"};
	    $par{"dirIn"}=$PWD    
		if (defined $PWD &&
		    ($par{"dirIn"}=~/^(local|unk)$/ || length($par{"dirIn"})==0));}}
    $par{"dirIn"}.="/" if (defined $par{"dirIn"} && -d $par{"dirIn"} && $par{"dirIn"}!~/\/$/); #  slash
    $par{"dirIn"}=""   if (! defined $par{"dirIn"} || ! -d $par{"dirIn"}); # empty
                                # ------------------------------
    if (defined %par && %par){  # all keywords used in script
        @tmp=sort keys (%par);}
    else{
	$#tmp=0;}

    $Lverb3=0 if (! defined $Lverb3);
    $Lverb2=0 if (! defined $Lverb2);
    $#fileIn=0;                 # ------------------------------
    foreach $arg (@ARGV){	# (2) key word driven input
	if    ($arg=~/^verb\w*3=(\d)/)           {$par{"verb3"}=$Lverb3=$1;}
	elsif ($arg=~/^verb\w*3/)                {$par{"verb3"}=$Lverb3=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)           {$par{"verb2"}=$Lverb2=$1;}
	elsif ($arg=~/^verb\w*2/)                {$par{"verb2"}=$Lverb2=1;}
	elsif ($arg=~/^verbose=(\d)/)            {$par{"verbose"}=$Lverb=$1;}
	elsif ($arg=~/^verbose/)                 {$par{"verbose"}=$Lverb=1;}
	elsif ($arg=~/^not_?([vV]er|[sS]creen)/) {$par{"verbose"}=$Lverb=0; }
	else  {$Lok=0;		# general
               if (-e $arg && ! -d $arg){ # is it file?
                   $Lok=1;push(@fileIn,$arg);}
               if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
                   $Lok=1;push(@fileIn,$par{"dirIn"}.$arg);}
				# any of the paras defined ?
               if (! $Lok && $arg=~/=/){
                   foreach $kwd (@tmp){
                       if ($arg=~/^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
                                                last;}}}
               push(@argUnk,$arg) if (! $Lok);}}
    return(@argUnk);
}				# end of brIniGetArg

#==============================================================================
sub brIniHelp {
    local(%tmp)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelp                   initialise help text
#       out:                    \d,txt
#       err:                    0,$msg  -> error
#       err:                    1,'fin' -> wanted help, given help
#       err:                    1,$msg  -> continue, was just trying
#       in:                     $tmp{} with
#                               $tmp{sourceFile}=  name and path of calling script
#                               $tmp{scrName}=     name of calling script (no .pl)
#                               $tmp{scrIn}=       input arguments for script
#                               $tmp{scrGoal}=     what script does
#                               $tmp{scrNarg}=     number of argument needed for script
#                               $tmp{scrHelpTxt}=  long blabla about script
#                                   separate by '\n'
#                               $tmp{scrAddHelp}=  help option other than standard
#                                   e.g.: "help xyz     : explain .xyz "
#                                   many: '\n' separated
#                                   NOTE: this will be an entry to $tmp{$special},
#                                   -> $special =  'help xyz' will give explanation 
#                                      $tmp{$special}
#                               $tmp{special}=     'kwd1,kwd2,...' special keywords
#                               $tmp{$special}=    explanation for $special
#                                   syntax: print flat lines (or '--- $line'), separate by '\n'
#                               $tmp{scrHelpHints}= hints (tab separated)
#                               $tmp{scrHelpProblems}= known problems (tab separated)
#       in GLOBULAR:            @ARGV
#                               $par{fileHelpOpt}
#                               $par{fileHelpMan}
#                               $par{fileHelpHints}
#                               $par{fileHelpProblems}
#                               $par{fileDefautlts}
#       in unk:                 leave undefined, or give value = 'unk'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniHelp"; 
				# ------------------------------
				# check input
    if (0){
	foreach $kwd ("sourceFile","scrName","scrIn","scrGoal",
		      "scrNarg","scrAddHelp","special"){
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{$kwd},",\n";}
    }
    @scrTask=
        ("--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- Input: ".$tmp{"scrIn"},
#         "---                 i.e. requires at least ".$tmp{"scrNarg"}.
#	      " command line argument(s)",
         "--- ");
    $tmp{"scrNameFull"}=$0      if (! defined $tmp{"scrNameFull"});
				# ------------------------------
				# additional help keywords?
				# ------------------------------
    $#tmpAdd=0;
    if (defined $tmp{"scrAddHelp"} && $tmp{"scrAddHelp"} ne "unk"){
	@tmp=split(/\n/,$tmp{"scrAddHelp"});$Lerr=0;
	foreach $tmp(@tmp){
	    push(@tmpAdd,$tmp{"scrNameFull"}." ".$tmp);
	    $tmp2=$tmp;$tmp2=~s/^(.+)\s+\:.*$/$1/;$tmp2=~s/\s*$//g;
	    if (!defined $tmp{"$tmp2"}){
		$Lerr=1;
		print "-*- WARN $sbrName: miss \$tmp{\$special}  for '$tmp2'\n";}}
	if ($Lerr){
	    print  
		"-*- " x 20,"\n","-*- WARN $sbrName: HELP on HELP\n",
		"-*-      if you provide special help in tmp{scrAddHelp}, then\n",
		"-*-      provide also the respective explanation in tmp{\$special},\n",
		"-*-      where \$special is e.g. 'help xyz' in \n",
		"-*-      scrAddHelp='help xyz : what to do'\n","-*- " x 20,"\n";}}
				# ------------------------------
				# build up help standard
				# ------------------------------
    @scrHelp=
	("--- Help:  For further information on input options type:",
	 "--- "." " x length($tmp{"scrNameFull"}).
	 "              ........................................");
    @scrHelpLoop=
	($tmp{"scrNameFull"}." help          : lists all options",
	 $tmp{"scrNameFull"}." def           : writes default settings",
	 $tmp{"scrNameFull"}." def keyword   : settings for keyword",
	 $tmp{"scrNameFull"}." help keyword  : explain key, e.g. 'special', or how for 'how' and 'howie'");
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." problems      : known problems") 
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /problems/);
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." hints         : hints for users")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /hints/);
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." manual        : will cat the entire manual (... MAY be it will)")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /manual/);

    push(@scrHelpLoop,@tmpAdd) if ($#tmpAdd>0);

    push(@scrHelp,@scrHelpLoop,
	 "--- "." " x length($tmp{"scrNameFull"}).
	        "              ........................................");
				# ------------------------------
				# additional general information
				# ------------------------------
    $#scrHelpTxtLoc=0;
    if (defined $tmp{"scrHelpTxt"}){
	@tmp=split(/\n/,$tmp{"scrHelpTxt"});
				# '--- scrHelptTxt'
				# '> program'       i.e. use: '>' to ommitt '--- '
	foreach $txt (@tmp){
	    push(@scrHelpTxtLoc,"--- $txt\n") if ($txt !~ /^[>\%]/);
	    push(@scrHelpTxtLoc,"$txt\n")     if ($txt =~ /^[>\%]/); }}
				# ------------------------------
				# additional special info
				# ------------------------------
    $#scrSpecialLoc=0;
    if (defined $tmp{"special"}) {
	@kwdLoc=split(/,/,$tmp{"special"});
	if ($#kwdLoc>1){
	    foreach $kwd (@kwdLoc){
		$tmp=" "; $tmp=$tmp{$kwd} if (defined $tmp{$kwd});
		$tmp=~s/\n$//;
		$tmpWrt=sprintf ("---   %-15s %-s\n",$kwd,$tmp); 
		push(@scrSpecialLoc,$tmpWrt); } }}
				# ------------------------------
				# general:
				# ------------------------------
    $fstLineLoc= "-" x 80 . "\n";
    $fstLineLoc.="--- Perl script $scrName.pl (" . $tmp{"sourceFile"} . ")\n";
    $syntaxLoc=  "-" x 80 . "\n";
    $syntaxLoc.= "---    Syntax used to set parameters by command line:\n";
    $syntaxLoc.= "---       'keyword=value'\n";
    $syntaxLoc.= "---    where 'keyword' is one of the following keywords:\n";
	
				# ------------------------------
				# no input
    if ($#ARGV < 1) {		# ------------------------------
	print $fstLineLoc;
	print join("\n",@scrTask,"\n");
	print @scrHelpTxtLoc;
	print join("\n",@scrHelp); print "\n";
	return(1,"fin");}
				# ------------------------------
				# help request
				# ------------------------------
    elsif ($#ARGV < 2 && $ARGV[1] =~ /^(help|man|-m|-h)$/){
	print $fstLineLoc;
	print join("\n",@scrTask,"\n");
	print @scrHelpTxtLoc;
	if ($#scrSpecialLoc > 0) {
	    print "-" x 80,"\n"; 
	    print "---    'special' keywords:\n"; 
	    print @scrSpecialLoc,"\n"; }
        if (defined %par) {
	    @kwdLoc=sort keys (%par);
	    if ($#kwdLoc>1){
		print $syntaxLoc;
		$ct=0;print "OPT \t ";
		foreach $kwd(@kwdLoc){
		    ++$ct;
		    printf "%-20s ",$kwd;
		    if ($ct==4){
			$ct=0;print "\nOPT \t ";}}
		print "\n";}
            print 
                "--- \n",
                "---    you may get further explanations on a particular keyword\n",
                "---    by typing:\n",
                $tmp{"scrNameFull"}." help keyword\n",
                "---    this could explain the key.  Type 'how' for info on ".
		    "'how,howie,show'.\n",
		    "--- \n";}
        else { 
	    print "--- no other options enabled by \%par\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants manual
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "manual"){
	print $fstLineLoc;
	if (defined $par{"fileHelpMan"} &&  -e $par{"fileHelpMan"}){
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		print $_;}close(FHIN);}
	else {
	    print "no manual in \%par{'fileHelpMan'}!!\n";}
	return(1,"fin");}
				# ------------------------------
				# wants hints
				# ------------------------------
    elsif ($#ARGV==1  && $ARGV[1] eq "hints"){
	print $fstLineLoc;
	print "--- Hints for users:\n";$ct=0;
	if (defined $par{"fileHelpHints"} && -e $par{"fileHelpHints"}){
	    open("FHIN",$par{"fileHelpHints"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpHints"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpHints"}){
	    @tmp=split(/\n/,$par{"scrHelpHints"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- the only hint to give: try another help option!\n";
            print "---                        sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants problems
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "problems"){
	print $fstLineLoc;
	print "--- Known problems with script:\n";$ct=0;
	if (defined $par{"fileHelpProblems"} && -e $par{"fileHelpProblems"}){
	    open("FHIN",$par{"fileHelpProblems"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpProblems"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpProblems"}){
	    @tmp=split(/\n/,$par{"scrHelpProblems"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- One problem is: there is no problem annotated.\n";
            print "---                 sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants default settings
				# ------------------------------
    elsif ($#ARGV<2 && $ARGV[1] eq "def"){
	print $fstLineLoc;
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                foreach $kwd(@kwdLoc){
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                print 
                    "--- \n",
                    "---    to get settings for particular keywords use:\n",
                    $tmp{"scrNameFull"}," def keyword'\n \n";}}
        else { print "--- no setting defined in \%par\n";
	       print "---                       sorry...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# help for particular keyword
				# ------------------------------
    elsif ($#ARGV>=2 && $ARGV[1] eq "help" ||
	   $#ARGV==1 && $ARGV[1] eq "special"){
	print $fstLineLoc;
	$kwdHelp=$ARGV[2]         if ($#ARGV > 1); 
	$kwdHelp=$ARGV[1]         if ($#ARGV== 1); 
	$tmp="help $kwdHelp";	# special?
	$tmp=~tr/[A-Z]/[a-z]/;	# make special keywords case independent 
        $tmp2=$tmp;$tmp2=~s/help //;
	$tmpSpecial=$tmp{"$tmp"}  if (defined $tmp{"$tmp"});
	$tmpSpecial=$tmp{"$tmp2"} if (! defined $tmp{"$tmp"} && defined $tmp{"$tmp2"});

        $#kwdLoc=$#expLoc=0;    # (1) get all respective keywords
        if (defined %par && $kwdHelp ne "special"){
            @kwdLoc=keys (%par);$#tmp=0;
            foreach $kwd (@kwdLoc){
                push(@tmp,$kwd) if ($kwd =~/$kwdHelp/i);}
            @kwdLoc=sort @tmp;}
                                # (2) is there a 'help option file' ?
        if (defined $par{"fileHelpOpt"} && -e $par{"fileHelpOpt"} && 
	    $kwdHelp ne "special"){
	    print $syntaxLoc;
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		next if ($_=~/^\#/);
		$line=$_;
		$tmp=$_;$tmp=~s/\s//g;
		next if (length($tmp)<2);
		next if ($_=~/^\s/ && ! $Lok);	   
		if    ($Lok && $_=~/^\s/){
		    print $_;
		    next;}
		elsif ($Lok && $_!~/^\s/){
		    $Lok=0;}
		if (! $Lok && $_ !~ /^[\s\t]+/){
		    $line=$_;
		    ($tmp1,$tmp2)=split(/[\s\t]+/,$_);
		    $Lok=1 if (length($tmp1)>1 && $tmp1 =~ /$kwdHelp/i);
		    print $line if ($Lok);}}close(FHIN);
	    print "-" x 80, "\n";}
                                # (3) is there a default file?
        elsif (defined $par{"fileDefaults"} && -e $par{"fileDefaults"} &&
	    $kwdHelp ne "special"){
	    ($Lok,$msg,%def)=&brIniRdDef($par{"fileDefaults"});
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
	    @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
	    foreach $kwd (@kwdLoc){
		if ($kwd =~/$kwdHelp/i){
		    push(@tmp,$kwd); 
		    if (defined $def{$kwd,"expl"}){
			$def{$kwd,"expl"}=~s/\n/\n---                        /g;
			push(@expLoc,$def{$kwd,"expl"});}
		    else {
			push(@expLoc," ");}}}
	    @kwdLoc=@tmp;}
				# (4) else: read itself
        elsif ($kwdHelp ne "special"){
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmp{"sourceFile"});
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                next if ($kwd !~/$kwdHelp/i && $kwdHelp !~ /$kwd/ );
		push(@tmp,$kwd); 
		if (defined $def{$kwd}){
		    $def{$kwd}=~s/\n[\t\s]*/\n---                        /g;
		    push(@expLoc,$def{$kwd});}
		else {push(@expLoc," ");}}
            @kwdLoc=@tmp;}
	$Lerr=1;
        if ($#kwdLoc>0){        # (4) write the stuff
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            foreach $it(1..$#kwdLoc){
                $tmp=" "; $tmp=$expLoc[$it] if (defined $expLoc[$it]);
                printf "--- %-20s   %-s\n",$kwdLoc[$it],$tmp;}
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;}

				# (5) special help?
	if (defined $tmpSpecial || 
	    ($kwdHelp eq "special" && defined $tmp{"special"})){
            print  "---    Special help for '$kwdHelp':\n";
	    if ($kwdHelp eq "special"){
		print @scrSpecialLoc,"\n";}
	    else {
		foreach $scrSpecialLoc (@scrSpecialLoc) {
		    $scrSpecialLoc=~s/\n$//;
		    next if ($scrSpecialLoc !~ /$kwdHelp/);
		    print "$scrSpecialLoc";}
		print "\n";}
	    $Lerr=0;
	    return(1,"fin") if ($kwdHelp eq "special");}
	print "--- sorry, no explanations found for keyword '$kwdHelp'\n" if ($Lerr);
	return(1,"fin loop?");}
				# ------------------------------
				# wants settings for keyword
				# ------------------------------
    elsif ($#ARGV>=2  && $ARGV[1] eq "def"){
	$kwdHelp=$ARGV[2];
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                foreach $kwd(@kwdLoc){
                    next if ($kwd !~ /$kwdHelp/);
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                print  " \n";}}
	else { print "--- sorry, no setting defined in \%par\n";}
	return(1,"fin loop?");}

    return(1,"ok $sbrName");
}				# end of brIniHelp

#==============================================================================
sub brIniHelpLoop {
    local($promptLoc,%tmp)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpLoop               loop over help 
#       in/out:                 see brIniHelp
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpLoop";$fhinLoc="FHIN_"."brIniHelpLoop";

    ($Lok,$msg)=		# want help?
	&brIniHelp(%tmp);       
                                return(&errSbrMsg("after brIniHelp",$msg)) if (! $Lok);
				# ------------------------------
				# loop over help
				# ------------------------------
    if ($msg =~ /^fin loop/) {
	$#tmp=0;
	foreach $txt (@scrHelpLoop) { $txt=~s/^.*\.pl\s*//g;
				      push(@tmp,$txt); }
	@scrHelpLoop2=@tmp;
	
	$Lquit=0; 
	$def="help"; 
	$ct=0;
	while (! $Lquit) {
	    printf "%-s %-s\n",      $promptLoc,"-" x (79 - length($promptLoc));
	    printf "%-s %-15s %-s\n",$promptLoc,"",              "Interactive help";
	    printf "%-s %-15s %-s\n",$promptLoc,"OPTIONS","";
	    foreach $txt (@scrHelpLoop2) { 
		printf "%-s %-15s %-s\n",$promptLoc," ",$txt; }
	    printf "%-s %-15s %-s\n",$promptLoc,"","";
	    printf "%-s %-15s %-s\n",$promptLoc,"ABBREVIATIONS", "h=help, d=def (e.g. 'h kwd')";
	    printf "%-s %-15s %-s\n",$promptLoc,"ENOUGH ?",      "[quit|q|e|exit] to end";

	    $def="$ARGV[1]"     if (defined $def);   # take previous
		
	    $ansr=
		&get_in_keyboard("type",$def,$promptLoc);

				# <--- QUIT
	    $tmp=$ansr;$tmp=~s/\s//g;
	    if ($ansr=~/^[q|quit|e|exit]$/) { 
		$Lquit=1; 
		last; }
				# redefine @ARGV
	    @ARGV=split(/\s+/,$ansr);
	    $ARGV[1]="help"     if ($ARGV[1] eq "h" || $ARGV[1] eq "H");
	    $ARGV[1]="def"      if ($ARGV[1] eq "d" || $ARGV[1] eq "D");

	    ++$ct;
				# add keyword help
	    if ($ct > 1 && $#ARGV < 2) {
		$ARGV[2]=$ARGV[1];
		$ARGV[1]="help";}

	    $txt1="start again with(";
	    $txt2=join(' ',@ARGV);
	    $lenfin=80 - 6 - (length($txt1) + length($txt2));
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";
	    print "--- ",$txt1,$txt2,")\n";
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";

				# call again
	    ($Lok,$msg)=
		&brIniHelp(%tmp); return(&errSbrMsg("after brIniHelp",$msg)) if (! $Lok);
				# <--- QUIT
	    $Lquit=1            if ($msg eq "fin");
	} 
	$msg="fin";
    }
    return(1,$msg);
}				# end of brIniHelpLoop

#==============================================================================
sub brIniHelpRdItself {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpRdItself           reads the calling perl script (scrName),
#                               searches for 'sub\siniDef', and gets comment lines
#       in:                     perl-script-source
#       out:                    (Lok,$msg,%tmp), with:
#                               $tmp{"kwd"}   = 'kwd1,kwd2'
#                               $tmp{"$kwd1"} = explanations for keyword 1
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpRdItself";$fhinLoc="FHIN_"."brIniHelpRdItself";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n") if (! $Lok);
                                # read file
    while (<$fhinLoc>) {        # search for initialising subroutine
        last if ($_=/^su[b] iniDef.* \{/);}
    $Lis=0; $#tmp=0;
    undef %tmp; 
    while (<$fhinLoc>) {        # read lines with '   %par{"kwd"}= $val  # comment '
        $_=~s/\n//g;
        last if ($_=~/^su[b] .*\{/ && $_!~/^su[b] iniDef.* \{/);
				# new expression 
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]*\#\s*(.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd); 
	    $tmp{$kwd}=$2 if (defined $2);}
				# end if only '------' line
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
				# add to previous (only if it had an explanation)
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{$kwd}.="\n".$1;}
				# end if nothing followed
        elsif ($Lis){
            $Lis=0;}}close($fhinLoc);
    $tmp{"kwd"}=join(',',@tmp);
    return(1,"ok $sbrName",%tmp);
}				# end of brIniHelpRdItself

#==============================================================================
sub brIniRdDef {
    local ($fileLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniRdDef                  reads defaults for initialsing parameters
#       in GLOBAL:              $par{},@ARGV
#       out GLOBAL:             $par{} (i.e. changes settings automatically)
#       in:                     file_default
#       out:                    ($Lok,$msg,%defaults) with:
#                               $defaults{"kwd"}=         'kwd1,kwd2,...,'
#                               $defaults{"$kwd1"}=       val1
#                               $defaults{"$kwd1","expl"}=explanation for kwd1
#                               note: long explanations split by '\n'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniRdDef"; $fhin="FHIN_brIniRdDef";

    &open_file("$fhin","$fileLoc") ||
	return(0,"*** ERROR $sbrName: failed to open in '$fileLoc'\n");

    undef %defaults; 
    $#kwd=0; $Lis=0;
				# ------------------------------
    while (<$fhin>){		# read file
	next if (length($_)<3 || $_=~/^\#/ || $_!~/\t/); # ignore lines beginning with '#'
	$_=~s/\n//g;
	$line=$_;
	$tmp=$line; $tmp=~s/[\s\#\-\*\.\=\t]//g;
				# ignore lines with only spaces or '-|#|*|='
	next if (length($tmp)<1);
				# purge leading blanks and tabs
	$line=~s/^[\s\t]*|[\s\t]*$//g;
				# ------------------------------
				# (1) case 'kwd  val  # comment'
	if    ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]+\# ?(.*)$/){
	    $kwd=$1; push(@kwd,$kwd); $defaults{$kwd}=$2; 
            $defaults{$kwd,"expl"}=$3 if (defined $3 && length($3)>1); $Lis=1;}
				# (2) case 'kwd  val'
	elsif ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]*$/){
	    $kwd=$1; $defaults{$kwd}=$2; $Lis=1; $defaults{$kwd,"expl"}=""; }
				# (3) case '          # ----'
	elsif ($Lis && $line =~ /^\#\s*[\-\=\_\.\*]+/){
	    $Lis=0;}
	elsif ($Lis && defined $defaults{$kwd,"expl"} && $line =~ /^\#\s*(.*)$/){
	    $defaults{$kwd,"expl"}.="\n".$1;}}
    close($fhin);
				# ------------------------------
    foreach $kwd (@kwd){        # fill in wild cards
        $defaults{$kwd}=$ARCH if ($defaults{$kwd}=~/ARCH/);}
                                # ------------------------------
    foreach $kwd (@kwd){        # complete it
	$defaults{$kwd,"expl"}=" " if (! defined $defaults{$kwd,"expl"});}
    $defaults{"kwd"}=join(',',@kwd);
				# ------------------------------
				# check the defaults read
				# AND OVERWRITE $par{} !!
    @kwdDef=keys %par; foreach $kwd (@kwdDef){ $tmp{$kwd}=1;}
    $Lok=1;
    foreach $kwd (@kwd){
	if (! defined $tmp{$kwd}){
	    $Lok=0;
	    print 
		"*** ERROR $sbrName: wrong keyword ($kwd) in defaults file ",
		$par{"fileDefaults"},"\n";}
				# ******************************
	else {			# overwrite
				# ******************************
	    $par{$kwd}=$defaults{$kwd};}}
    return(0,"*** ERROR $sbrName failed finishing to read defaults file\n") if (! $Lok);

    return(1,"ok $sbrName",%defaults);
}				# end of brIniRdDef

#==============================================================================
sub brIniSet {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniSet                    changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniSet";
    @kwd=sort keys(%par) if (defined %par && %par);
				# ------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwd){
        if (defined $kwd && length($kwd)>=1 && defined $par{$kwd}){
            push(@tmp,$kwd);}
	else { print "-*- WARN $sbrName: for kwd '$kwd', par{kwd} not defined!\n";}}
    @kwd=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwd){
	$par{$kwd}=~s/jobid/$par{"jobid"}/;}
                                # ------------------------------
                                # WATCH it for file lists: add dirIn
    if (defined $par{"dirIn"} && $par{"dirIn"} ne "unk" && $par{"dirIn"} ne "local" 
        && length($par{"dirIn"})>1){
	foreach $fileIn(@fileIn){
	    next if (-e $fileIn);
	    $fileIn=$par{"dirIn"}.$fileIn if ($fileIn !~/$par{"dirIn"}/);
	    if (! -e $fileIn){ print "*** $sbrName: no fileIn=$fileIn, dir=",$par{"dirIn"},",\n";
			       return(0);}}} 
    $#kwdFileOut=0;		# ------------------------------
    foreach $kwd (@kwd){	# add 'pre' 'title' 'ext' to output files not specified
	next if ($kwd !~ /^fileOut/);
	push(@kwdFileOut,$kwd);
	next if (defined $par{$kwd} && $par{$kwd} ne "unk" && length($par{$kwd})>0);
	$kwdPre=$kwd; $kwdPre=~s/file/pre/;  $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	$pre="";$pre=$par{"$kwdPre"} if (defined $par{"$kwdPre"});
	$ext="";$ext=$par{"$kwdExt"} if (defined $par{"$kwdExt"});
	if (! defined $par{"title"} || $par{"title"} eq "unk"){
	    $par{"title"}=$scrName;$par{"title"}=~tr/[a-z]/[A-Z]/;} # capitalize title
	$par{$kwd}=$pre.$par{"title"}.$ext;}
				# ------------------------------
				# add output directory
    if (defined $par{"dirOut"} && $par{"dirOut"} ne "unk" && $par{"dirOut"} ne "local" 
        && length($par{"dirOut"})>1){
	if (! -d $par{"dirOut"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirOut"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print 
		"*** $sbrName failed making directory '",
		$par{"dirOut"},"'\n" if (! $Lok);}
				# add slash
	$par{"dirOut"}.="/"     if (-d $par{"dirOut"} && $par{"dirOut"} !~/\/$/);
	foreach $kwd (@kwdFileOut){
	    next if (-e $par{$kwd});
	    next if ($par{$kwd} =~ /^$par{"dirOut"}/);
	    next if ($par{$kwd} eq "unk" || ! $par{$kwd});
	    $par{$kwd}=$par{"dirOut"}.$par{$kwd} if (-d $par{"dirOut"});}}
				# ------------------------------
				# push array of output files
    $#fileOut=0 if (! defined @fileOut);
    foreach $kwd (@kwdFileOut){
	push(@fileOut,$par{$kwd});}
				# ------------------------------
				# temporary files: add work dir
    if (defined $par{"dirWork"} && $par{"dirWork"} ne "unk" && $par{"dirWork"} ne "local" 
	&& length($par{"dirWork"})>1) {
	if (! -d $par{"dirWork"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirWork"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirWork"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print "*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);}
	$par{"dirWork"}.="/" if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwd){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Out|Help|Def)/i);
            $par{$kwd}=~s/jobid/$par{"jobid"}/ ;
	    next if (-e $par{$kwd});
	    next if ($par{$kwd} =~ /^$par{"dirWork"}/);
	    $par{$kwd}=$par{"dirWork"}.$par{$kwd};}}
				# ------------------------------
				# blabla
    $Lverb=1  if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=1 if (defined $par{"verb2"}   && $par{"verb2"});
    $Lverb3=1 if (defined $par{"verb3"}   && $par{"verb3"});
				# ------------------------------
				# add ARCH
    if (defined $ARCH || defined $par{"ARCH"}){
	$ARCH=$par{"ARCH"}      if (! defined $ARCH &&   defined $par{"ARCH"});
	$par{"ARCH"}=$ARCH      if (  defined $ARCH && ! defined $par{"ARCH"});
	foreach $kwd (@kwd){	# add directory to executables
	    next if ($kwd !~ /^exe/);
	    next if ($par{$kwd} !~ /ARCH/);
	    $par{$kwd}=~s/ARCH/$ARCH/;}}

				# ------------------------------
    foreach $kwd (@kwd){	# add directory to executables
	next if ($kwd !~/^exe/);
	next if (-e $par{$kwd} || -l $par{$kwd});
				# try to add perl script directory
	next if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"});
	next if ($par{$kwd}=~/$par{"dirPerl"}/); # did already, no result
	$tmp=$par{"dirPerl"}; $tmp.="/" if ($tmp !~ /\/$/);
	$tmp=$tmp.$par{$kwd};
	next if (! -e $tmp && ! -l $tmp);
	$par{$kwd}=$tmp; }

				# ------------------------------
				# priority
    if (defined $par{"optNice"} && $par{"optNice"} ne " " && length($par{"optNice"})>0){
	$niceNum="";
	if    ($par{"optNice"}=~/nice\s*-/){
	    $par{"optNice"}=~s/nice-/nice -/;
	    $niceNum=$par{"optNice"};$niceNum=~s/\s|nice|\-|\+//g; }
	elsif ($par{"optNice"}=~/^\d+$/){
	    $niceNum=$par{"optNice"};}
	$niceNum=~s/\D//g;
	setpriority(0,0,$niceNum) if (length($niceNum)>0); }

    return(1);
}				# end of brIniSet

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
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#==============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#==============================================================================
sub getDistanceHsspCurve {
    local ($laliLoc,$laliMaxLoc) = @_ ;
    $[=1;
#--------------------------------------------------------------------------------
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#       in:                     $lali,$lailMax
#                               note1: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#                               note2: saturation at 100
#       out:                    value curve (i.e. percentage identity)
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceHsspCurve";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);
    $laliMaxLoc=100             if (! defined $laliMaxLoc);
    $laliLoc=~s/\s//g;

    $laliLoc=$laliMaxLoc        if ($laliLoc > $laliMaxLoc);	# saturation
    $val= 290.15*($laliLoc **(-0.562)); 
    $val=100                    if ($val > 100);
    $val=25                     if ($val < 25);
    return ($val,"ok $sbrName");
}				# end getDistanceHsspCurve

#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#==============================================================================
sub getDistanceNewCurveSim {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveSim      out= psim value for new curve
#       in:                     $lali
#       out:                    $sim
#                               psim= 420 * L ^ { -0.335 (1 + e ^-(L/2000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveSim";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.335 * ( 1 + exp (-$laliLoc/2000) );
    $loc= 420 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveSim

#==============================================================================
sub getDistanceThresh {
    local($modeLoc,$laliLoc,$pideLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceThresh           compiles the distance from a threshold
#       in:                     $modeLoc: which filter ('old|new|newIde|newSim')
#       in:                     $laliLoc: alignment length
#       in:                     $pideLoc: percentages sequence identity/similarity
#       out:                    1|0,msg,$dist
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."getDistanceThresh";$fhinLoc="FHIN_"."getDistanceThresh";
				# check arguments
    return(&errSbr("not def modeLoc!",$SBR))          if (! defined $modeLoc);
    return(&errSbr("not def laliLoc!",$SBR))          if (! defined $laliLoc);
    return(&errSbr("not def pideLoc!",$SBR))          if (! defined $pideLoc);

    return(&errSbr("mode must be 'old|new|newSim' is '$modeLoc'",$SBR))
	if ($modeLoc !~ /^(old|new|newIde|newSim)$/i);
    return(&errSbr("lali must be integer is '$laliLoc'",$SBR)) if ($laliLoc !~ /^\d+$/);
    return(&errSbr("pide must be number 0..100 is '$pideLoc'",$SBR)) 
	if ($pideLoc !~ /^[\d\.]+$/ || $pideLoc < 0 || $pideLoc > 100);
	
				# ------------------------------
				# distance from threshold:
    if    ($modeLoc eq "old"){
	($pideCurve,$msg)= 
	    &getDistanceHsspCurve($lali); 
	return(&errSbrMsg("failed getDistanceHsspCurve",$msg,$SBR))  if ($msg !~ /^ok/); }
    elsif ($modeLoc =~ /^newSim$/i){
	($pideCurve,$msg)= &getDistanceNewCurveSim($lali); 
	return(&errSbrMsg("failed getDistanceNewCurveSim",$msg,$SBR))  if ($msg !~ /^ok/); }
    else {
	($pideCurve,$msg)= &getDistanceNewCurveIde($lali); 
	return(&errSbrMsg("failed getDistanceNewCurveIde",$msg,$SBR))  if ($msg !~ /^ok/); }

    $dist=$pideLoc - $pideCurve;
    return(1,"ok $sbrName",$dist);
}				# end of getDistanceThresh

#==============================================================================
sub get_in_keyboard {
    local($des,$def,$pre,$Lmirror)=@_;local($txt);
#--------------------------------------------------------------------------------
#   get_in_keyboard             gets info from keyboard
#       in:                     $des :    keyword to get
#       in:                     $def :    default settings
#       in:                     $pre :    text string beginning screen output
#                                         default '--- '
#       in:                     $Lmirror: if true, the default is mirrored
#       out:                    $val : value obtained
#--------------------------------------------------------------------------------
    $pre= "---"                 if (! defined $pre);
    $Lmirror=0                  if (! defined $Lmirror || ! $Lmirror);
    $txt="";			# ini
    printf "%-s %-s\n",          $pre,"-" x (79 - length($pre));
    printf "%-s %-15s:%-s\n",    $pre,"type value for",$des; 
    if (defined $def){
	printf "%-s %-15s:%-s\n",$pre,"type RETURN to enter value, or to keep default";
	printf "%-s %-15s>%-s\n",$pre,"default value",$def;}
    else {
	printf "%-s %-15s>%-s\n",$pre,"type RETURN to enter value"; }

    $txt=$def                    if ($Lmirror);	# mirror it
    printf "%-s %-15s>%-s",      $pre,"type",$txt; 

    while(<STDIN>){
	$txt.=$_;
	last if ($_=~/\n/);}     $txt=~s/^\s+|\s+$//g;
    $txt=$def                   if (length($txt) < 1);
    printf "%-s %-15s>%-s\n",    $pre,"--> you chose",$txt;
    return ($txt);
}				# end of get_in_keyboard

#==============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    &open_file("$fhinLoc2","$fileLoc") || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if (($one =~ /^\s*>\s*\w+/) && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/);
    return(0);
}				# end of isFasta

#==============================================================================
sub isRdb {
    local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    return (0) if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB";
    open("$fh", $fileInLoc) || return(0);
    $tmp=<$fh>;
    close($fh);
    return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
    return 0; 
}				# end of isRdb

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
sub pdbGrepResolution {
    local($fileInLoc,$exclLoc,$modeLoc,$resMaxLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbGrepResolution           greps the 'RESOLUTION' line from PDB files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for RESOLUTION  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       in:                     $resMaxLoc=  resolution assigned if none found
#       out:                    1|0,msg,$res (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."pdbGrepResolution";$fhinLoc="FHIN_"."pdbGrepResolution";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
    $resMaxLoc=1107                                if (! defined $resMaxLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep 'RESOLUTION\. ' $fileInLoc`; 
				# process output
    $tmp=~s/\n//g;
    if ($tmp=~/^.*RESOLUTION\.\s*([\d\.]+) .*$/){
	$tmp=~s/^.*RESOLUTION\.\s*([\d\.]+) .*$/$1/g; $tmp=~s/\n|\s//g;}
    else {
	$tmp=$resMaxLoc;}
    $Lok=1;
				# restrict?
    if (defined $exclLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of pdbGrepResolution

#==============================================================================
sub rdbGenWrtHdr {
    local($fhoutLoc2,%tmpLoc)= @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbGenWrtHdr                writes a general header for an RDB file
#       in:                     $file_handle_for_out
#       in:                     $tmp2{}
#                               $tmp2{"name"}    : name of program/format/.. eg. 'NNdb'
#                notation:     
#                               $tmp2{"nota","expect"}='name1,name2,...,nameN'
#                                                : column names listed
#                               $tmp2{"nota","nameN"}=
#                                                : description for nameN
#                               additional notations:
#                               $tmp2{"nota",$ct}='kwd'.'\t'.'explanation'  
#                                                : the column name kwd (e.g. 'num'), and 
#                                                  its description, 
#                                                  e.g. 'is the number of proteins'
#                parameters:           
#                               $tmp2{"para","expect"}='para1,para2' 
#                               $tmp2{"para","paraN"}=
#                                                : value for parameter paraN
#                               $tmp2{"form","paraN"}=
#                                                : output format for paraN (default '%-s')
#       out:                    implicit: written onto handle
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."rdbGenWrtHdr";
                                # defaults, read
    $name="";        $name=$tmpLoc{"name"}." "   if (defined $tmpLoc{"name"});
    $#colNamesTmp=0; @colNamesTmp=split(/,/,$tmpLoc{"nota","expect"})
                                                 if (defined $tmpLoc{"nota","expect"});
    $#paraTmp=0;     @paraTmp=    split(/,/,$tmpLoc{"para","expect"})
                                                 if (defined $tmpLoc{"para","expect"});

    print $fhoutLoc2 
	"# Perl-RDB  $name"."format\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORM  beg          $name\n",
	"# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORM  general:     - columns are delimited by tabs\n",
	"# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n",
	"# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n",
	"# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n",
	"# FORM  1st row:     column names  (tab delimited)\n",
	"# FORM  2nd row (may be): column format (tab delimited)\n",
	"# FORM  rows 2|3-N:  column data   (tab delimited)\n",
        "# FORM  end          $name\n",
	"# --------------------------------------------------------------------------------\n";
                                # ------------------------------
				# explanations
                                # ------------------------------
    if ($#colNamesTmp>0 || defined $tmpLoc{"nota","1"}){
        print  $fhoutLoc2 
            "# NOTA  begin        $name"."ABBREVIATIONS\n",
            "# NOTA               column names \n";
        foreach $kwd (@colNamesTmp) { # column names
            next if (! defined $kwd);
            next if (! defined $tmpLoc{"nota","$kwd"});
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$tmpLoc{"nota","$kwd"}; }
        print  $fhoutLoc2 
            "# NOTA               parameters\n";
        foreach $it (1..1000){      # additional info
            last if (! defined $tmpLoc{"nota","$it"});
            ($kwd,$expl)=split(/\t/,$tmpLoc{"nota","$it"});
            next if (! defined $kwd);
            $expl="" if (! defined $expl);
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$expl; }
        print $fhoutLoc2 
            "# NOTA  end          $name"."ABBREVIATIONS\n",
            "# --------------------------------------------------------------------------------\n"; }

                                # ------------------------------
				# parameters
                                # ------------------------------
    if ($#paraTmp > 0) {
        print $fhoutLoc2
            "# PARA  beg          $name\n";
        foreach $kwd (@paraTmp){
	    next if (! defined $tmpLoc{"para","$kwd"});
            $tmp="%-s";
            $tmp=$tmpLoc{"form","$kwd"} if (defined $tmpLoc{"form","$kwd"});
	    printf $fhoutLoc2
		"# PARA: %-12s =\t$tmp\n",$kwd,$tmpLoc{"para","$kwd"}; }
        print $fhoutLoc2 
            "# PARA  end          $name\n",
            "# --------------------------------------------------------------------------------\n"; }

}				# end of rdbGenWrtHdr

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/",
	  "/home/rost/pub/perl/"
	  );
    $exe_ctime="ctime.pl";	# local ctime library

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    foreach $tmp (@tmp){
		$exe_tmp=$tmp.$exe_ctime;
		if (-e $tmp){
		    $Lok=
			require("$exe_tmp");
		    last;}}}
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
    return($Date);
}				# end of sysDate



#==============================================================================
# library collected (end)
#==============================================================================



#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."ini";     
				# ------------------------------
    foreach $arg(@ARGV){	# highest priority ARCH
	if ($arg=~/ARCH=(.*)$/){
	    $ARCH=$ENV{'ARCH'}=$1; 
	    last;}}
    $ARCH=$ARCH || $ENV{'ARCH'} || "SGI64";

    $PWD= $ENV{'PWD'}          if (! defined $PWD  && defined $ENV{'PWD'}); 
    if (! defined $PWD){
	$tmp=`pwd`;
	$tmp=~s/\n//g;
	$tmp=~s/\s//g;
	$PWD=$tmp;}
    $PWD=~s/\/$//              if ($PWD=~/\/$/);
    $pwd= $PWD                 if (defined $PWD);
    $pwd.="/"                  if (defined $pwd && $pwd !~ /\/$/);

				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();


				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);   
                                return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 

				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg;

    $LnamesLower=0;

    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|PWD)=/);
	if    ($arg=~/^fileOutId1=(.*)$/)     { $fileOutId1=       $1; }
	elsif ($arg=~/^fileOutId2=(.*)$/)     { $fileOutId2=       $1; }
	elsif ($arg=~/^fileOutPairs=(.*)$/)   { $fileOutPairs=     $1; }
	elsif ($arg=~/^fileRes=(.*)$/i)       { $fileRes=          $1; }

	elsif ($arg=~/^de?bu?g$/)             { $par{"debug"}=     1;
						$par{"verbose"}=   1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $par{"verbose"}=   0;}

	elsif ($arg=~/^dirFasta=(.*)$/i)      { $par{"dirDataOrigin"}=$1;}

	elsif ($arg=~/^lower/)                { $LnamesLower=      1;}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}

	elsif ($arg=~/^dis.*=(.*)$/)          { $par{"minDist"}=   $1;
						$par{"doThresh"}=  1; 
						$par{"doPairs"}=   1; }
	elsif ($arg=~/^(lali)=(.*)$/)         { $par{"minLali"}=   $1;}
	elsif ($arg=~/^(len)=(.*)$/)          { $par{"minLen1"}=   $1;}

	elsif ($arg=~/^(noself|skip)$/i)      { $par{"allowSelf"}= 0; }
	elsif ($arg=~/^filter$/)              { $par{"doThresh"}=  1; }
	elsif ($arg=~/^nofil\w*$/)            { $par{"doThresh"}=  0; }
	elsif ($arg=~/^doThresh$/)            { $par{"doThresh"}=  1; }
	elsif ($arg=~/^pairs?$/)              { $par{"doPairs"}=   1; }
	elsif ($arg=~/^nopairs?$/)            { $par{"doPairs"}=   0; }
	elsif ($arg=~/^doPairs$/i)            { $par{"doPairs"}=   1; }
	elsif ($arg=~/^pdb$/i)                { $par{"doPairs"}=   1;
						$par{"doCheckRes"}=1; }
	elsif ($arg=~/^mirror?$/)             { $par{"doMirror"}=  1; }
	elsif ($arg eq "debug")               { $par{"debug"}=     1; }
	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb2"}=1             if ($par{"debug"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
	$par{"$kwd"}.="/"       if ($par{"$kwd"} !~ /\/$/);}

                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

    if (defined $par{"isList"} && $par{"isList"} eq "1" ||
	$fileIn[1] =~/\.list/){ # input is file list
        open($fhin,$fileIn[1]) ||
            return(&errSbr("failed to open fileIn[1]=$fileIn[1]\n"));
        $#fileIn=0 if ($#fileIn==1);
        while (<$fhin>) {
	    $_=~s/\s|\n//g;
	    push(@fileIn,$_) if (-e $_);
	}
	$par{"isList"}=1;
	$fileList=$fileIn[1];
	$par{"isBlastOriginal"}=1;
	close($fhin);}

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet();            return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);
				# output files
    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
	$fileOut= $par{"dirOut"}.$par{"title"}."-xyz".  $par{"extOut"};}

				# template for list
    $fileIn=$fileIn[1];
    $fileIn=$fileList           if (defined $par{"isList"} && $par{"isList"});
				# list id1
    if    (! defined $fileOutId1 && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutId1=$fileOut; $fileOutId1=~s/xyz/id1/; }
	else                 { $fileOutId1="Outid1-".$fileOut;}}
    elsif (! defined $fileOutId1){
	$tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutId1="Outid1-".$tmp;}
				# list id1
    if    (! defined $fileOutId2 && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutId2=$fileOut; $fileOutId2=~s/xyz/id2/; }
	else                 { $fileOutId2="Outid2-".$fileOut;}}
    elsif (! defined $fileOutId2){
	$tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutId2="Outid2-".$tmp;}
				# pairs
    if    (! defined $fileOutPairs && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutPairs=$fileOut; $fileOutPairs=~s/xyz/pairs/; }
	else                 { $fileOutPairs="Outpairs-".$fileOut;}}
    elsif (! defined $fileOutPairs){
	$tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutPairs="Outpairs-".$tmp;}
				# mirror
    if    (! defined $fileOutMirror && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutMirror=$fileOut; $fileOutMirror=~s/xyz/mirror/; }
	else                 { $fileOutMirror="Outmirror-".$fileOut;}}
    elsif (! defined $fileOutMirror){
	$tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutMirror="Outmirror-".$tmp;}

				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n".$msg)) if (! $Lok);  


                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($par{"verb2"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$fhTrace="STDOUT";}
				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"});
    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);
    return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); 

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
                                # d.d
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";
#    $par{"dirData"}=            "/home/rost/data/";
    $par{"dirData"}=            "/data/";

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
#    $par{""}=                   "";

    $par{"dirDataPdb"}=         $par{"dirData"}."/pdb/";            # for grepping resolution
    $par{"dirDataOrigin"}=      $par{"dirData"}."/hsspFasta/";      # directory of files which were 
    $par{"dirDataOrigin"}=      $par{"dirData"}."/swissFasta/";     # directory of files which were 
    $par{"dirDataOrigin"}=      $par{"dirData"}."derived/big/splitSwiss/";     # directory of files which were 
    $par{"dirDataOrigin"}=      "/dodo3/rost/w/uni-2001/pdb-fasta/";
    $par{"dirDataOrigin"}=      "/dodo9/rost/genome/seq/";
    $par{"dirDataOrigin"}=      "/dodo9/rost/func_curve/fasta/";

    $par{"dirDataOrigin"}=      "/home/rost/current/cafasp/fasta/";
				                                    #    originially run by BLAST
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "POST-BLAST";                    # output files may be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMP-BLAST-";                    # title for temporary files

    $par{"fileOut"}=            "unk";
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE"."jobid".".tmp";   # tracing some warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # dumb out from system calls

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
#    $par{""}=                   "";
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".dat";

    $par{"extPdb"}=             ".brk";
    $par{"extOrigin"}=          ".f";

    $par{"doThresh"}=           1; # if 1: extract BLAST hits according to HSSP threshold
    $par{"doThresh"}=           0; # if 1: extract BLAST hits according to HSSP threshold
    $par{"minLali"}=           30; # minimal alignment length to consider hit
    $par{"minDist"}=            3; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"modeFilter"}=         "old"; # filter according to old or new ide


    $par{"minDist"}=           -10; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"modeFilter"}=         "new"; # filter according to old or new ide

    $par{"doMirror"}=           0; # mirrors the same RDB file, applying filter/noself asf,
				   #    (and adding resolution/length for doPairs)
    $par{"doPairs"}=            1; # write list of pairs
    $par{"doCheckRes"}=         0; # check resolution for PDB
    $par{"resMax"}=          1107; # to put for resolution if none found
    $par{"resUnk"}=           100; # to put for resolution if no PDB file was there to check it

    $par{"allowSelf"}=          1; # if set to 1: also accepts columns with 1pdb-1pdb !
    

				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=            1; # blabla on screen
    $par{"verb2"}=              0; # more verbose blabla

    $par{"isList"}=             0; # if input file is list of files
    $par{"isBlastOriginal"}=    0; # if input file(s) are NOT rdb but original BLAST

#    $par{""}=                   "";
				# --------------------
				# parameters

				# --------------------
				# executables
    $par{"exe"}=                "";
#    $par{""}=                   "";

				# ------------------------------
				# pointers to recognise correct
				#    columns in input file
				# ------------------------------
    %ptr=(
	  'id1',  1,		# position of 1st id (no of RDB col)
	  'id2',  2,		# position of 2nd id (no of RDB col)
	  'lali', 3,		# position of alignment length
	  'pide', 4,		# position of sequene identity
	  'dist', 5
	  );

    $SEP="\t";			# separator for output files

}				# end of iniDef

#===============================================================================
sub iniHelp {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpNet                  specific help settings
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniHelp";
				# standard help
    $tmp=$0; $tmp=~s/^\.\/// if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 
	  'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpTxt);
				# missing stuff
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);

    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "filter".",". "nofilter".",". "noself".",";
    $tmp{"special"}.=        "pairs".","."nopairs".",". "pdb".",". "mirror".",". "fileRes".",";
    $tmp{"special"}.=        "verb".",". "verb2".",". "".",". "".",";
    $tmp{"special"}.=        "fileOutId1".",". "fileOutId2".",". "fileOutPairs".",";
    $tmp{"special"}.=        "fileOutMirror".",";
    $tmp{"special"}.=        "minLali".","."minDist".","."dis".","."len".","."lali".",";
    $tmp{"special"}.=        "dirFasta".",". "lower".",". "".",". "".",";
#    $tmp{"special"}.=        "".",". "".",". "".",". "".",";
        
    $tmp{"filter"}=          "OR doThresh=1,   redo the filtering procedure (HSSP threshold)";
    $tmp{"nofilter"}=        "OR doThresh=0,   NOT redo the filtering (HSSP threshold)";
    $tmp{"noself"}=          "OR allowSelf=0,  ignore hits of 1pdb onto 1pdb";
    $tmp{"pairs"}=           "OR doPairs=1,    write list of pairs (for uniqueList.pl)";
    $tmp{"nopairs"}=         "OR doPairs=0,    no pairs (for uniqueList.pl)";
    $tmp{"pdb"}=             "OR doCheckRes=1, check resolution (sets also pairs!)";
    $tmp{"mirror"}=          "OR doMirror=1,   write RDB again including res/len, excl self";

    $tmp{"fileRes"}=         "=x, file with PDB resolution \n".
	"---                   format:'id'.\t.'res' 100=no pdb, 1107=no res in pdb";

    $tmp{"dirFasta"}=        "directory of FASTA files";
    $tmp{"lower"}=           "all names to lower caps";

    $tmp{"filOutId1"}=       "name for file with list of id1";
    $tmp{"filOutId2"}=       "name for file with list of id2";
    $tmp{"filOutPairs"}=     "name for file with list of pairs";
    $tmp{"filOutMirror"}=    "name for mirrored input file";
    
    $tmp{"minLali"}=         "minimal number of aligned residues\n";
    $tmp{"minDist"}=         "minimal distance according to HSSP threshold\n";
    $tmp{"minLen1"}=         "minimal length of guide\n";
    $tmp{"dis"}=             "short for minDist\n";
    $tmp{"len"}=             "short for minLali\n";
    $tmp{"lali"}=            "short for minLali\n";

    $tmp{"verb"}=            "OR verbose=1,    i.e. verbose output";
    $tmp{"verb2"}=           "OR verb2=1,      i.e. very verbose output";
#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelpNet

#===============================================================================
sub conv_blast2rdb_here {
    local($ra_fileInLoc,$fileOutTmp) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   conv_blast2rdb_here         reads list of blast files and writes big RDB
#       in:                     $ra_fileIn: reference to array with all input files
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."conv_blast2rdb_here";
    $fhinLoc="FHIN_"."conv_blast2rdb_here";
    $fhoutLoc="FHOUT_"."conv_blast2rdb_here";
				# check arguments
    return(&errSbr("not def $ra_fileInLoc!"))          if (! defined $ra_fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    $sepTmp="\t";
    
    open($fhoutLoc,">".$fileOutTmp) || return(&errSbr("fileOutTmp=,$fileOutTmp, not created"));

    print $fhoutLoc
	
	"# Perl-RDB  format\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORM  beg          \n",
	"# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORM  general:     - columns are delimited by tabs\n",
	"# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n",
	"# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n",
	"# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n",
	"# FORM  1st row:     column names  (tab delimited)\n",
	"# FORM  2nd row (may be): column format (tab delimited)\n",
	"# FORM  rows 2|3-N:  column data   (tab delimited)\n",
	"# FORM  end          \n",
	"# --------------------------------------------------------------------------------\n",
	"# NOTA  begin        ABBREVIATIONS\n",
	"# NOTA               column names \n",
	"# NOTA: id1          =  guide sequence\n",
	"# NOTA: id2          =  aligned sequence\n",
	"# NOTA: lali         =  alignment length\n",
	"# NOTA: pide         =  percentage sequence identity\n",
	"# NOTA: dist         =  distance from new HSSP curve\n",
	"# NOTA: prob         =  BLAST probability\n",
	"# NOTA: score        =  BLAST raw score\n",
	"# NOTA               parameters\n",
	"# NOTA  end          ABBREVIATIONS\n",
	"# --------------------------------------------------------------------------------\n",
	"# PARA  beg          \n",
	"# PARA: minLali      =     12\n",
	"# PARA: minDist      =    -5.0\n",
	"# PARA  end          \n",
	"# --------------------------------------------------------------------------------\n";

    printf $fhoutLoc "%-10s$sepTmp%-10s$sepTmp","id1","id2";
    printf $fhoutLoc "%-5s$sepTmp","lali";
    printf $fhoutLoc "%-6s$sepTmp%-6s$sepTmp","pide","dist";
    printf $fhoutLoc "%-8s$sepTmp%-6s\n","prob","score";

				# ------------------------------
				# loop over all BLAST files
				# ------------------------------
    $fh=$fhoutLoc;
    foreach $fileInLoc (@{$ra_fileInLoc}){
	print "--- $sbrName: reading file=$fileInLoc!\n" if ($par{"debug"});

				# extract info
				# GLOBAL out: %rd
	($Lok,$msg)=
	    &blastGetSummary($fileInLoc,$par{"minLali"},$par{"minDist"});
	return(&errSbrMsg("file=$fileInLoc failed getting blast summary",$msg)) 
	    if (! $Lok);
				# write RDB
	$id1=$fileInLoc;
	$id1=~s/^.*\///g;	# purge dir
	$id1=~s/\..*$//g;	# purge ext
	$id1=~s/\s//g;		# purge blanks
				# upper to lower
	$id1=~tr/[A-Z]/[a-z]/
	    if ($LnamesLower);

	foreach $it (1..$rd{"NROWS"}){
				# purge id 
	    $rd{"id",$it}=~s/^.*\|//g;      # purge db
	    $rd{"id",$it}=~s/\s//g;         # purge blank
				            # upper to lower
	    $rd{"id",$it}=~tr/[A-Z]/[a-z]/
		if ($LnamesLower);

				# ids
	    printf $fh "%-10s$sepTmp%-10s$sepTmp",$id1,$rd{"id",$it};
				# lali
	    printf $fh "%5d$sepTmp",$rd{"lali",$it};
				# pide, dist
	    printf $fh "%6.1f$sepTmp%6.1f$sepTmp",$rd{"pide",$it},$rd{"dist",$it};
				# prob, score
	    printf $fh "%8.2e$sepTmp%6.1f\n",$rd{"prob",$it},$rd{"score",$it};
	}
    }				# end of loop over all BLAST files
    close($fhoutLoc);
	
    return(1,"ok $sbrName");
}				# end of conv_blast2rdb_here

#===============================================================================
sub fileInRd {
    local($fileInLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileInRd                    reads RDB file
#       in/out GLOBAL:          all
#       out GLOBAL:             $rd[$itrow]->[$itcol] : RDB columns read (id,lali,pide)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fileInRd";$fhinLoc="FHIN_"."fileInRd";

    undef @rd; undef @ptr_this2fin;
    $ncol=$nrow=0; $ct=0; $itrow=0;
				# open file
    open($fhin, $fileInLoc) || die '*** $scrName ERROR opening file $fileInLoc';
    $ctrowErr=0;
    while (<$fhin>) {
	++$ctrowErr;
	next if ($_=~/^\#/);	# skip comments
	++$ct;
	next if ($ct==1);	# skip names
	next if ($ct==2 && $_=~/\d+[NFS][\s\t]+|[\s\t]+\d+[NFS]/); # skip formats
	next if ($_=~/none/);	# skip empty
	$_=~s/\n//g;
	$line=$_;
	$_=~s/^\s*|\s*$//g;	# security: purge leading blanks
				# lower caps
	$_=~tr/[A-Z]/[a-z]/
	    if ($LnamesLower);
				# br hack 2001-03 ignore lines with mistakes
	next if ($_=~/^[0-9\.]+\t/);

	@tmp=split(/\s*\t\s*/,$_);
	foreach $tmp (@tmp) {
	    $tmp=~s/\s//g; }
	$ncol=$#tmp            if ($#tmp > $ncol);
				# ------------------------------
				# NO filter 
	if (! $par{"doThresh"}) {
	    &fileInRd_oneLine();
	    next; }
				# ------------------------------
				# wrong number of columns
	if (! $par{"doThresh"} || $ncol < 3) {
	    return(&errSbr("for mode filter (doThresh=1), $fileInLoc must have at least 3 columns!\n".
			   "actually read: $ncol, ".join(',',@tmp,"\n"))); }

				# ------------------------------
				# filter
	($Ltake,$dist)=
	    &filter1Loc($itrow,@tmp);

	next if (! $Ltake);	# no further action!

	&fileInRd_oneLine();
				# distance
	$dist=~s/\..*$//g;	# skip real accuracy
	$rd[$itrow][$ncol]=$dist;
	$fin[$nprot][$itcol]=$tmp[$ncol] if ($par{"doMirror"});
				# where are we?
	print "--- reading row $itrow\n" if ($itrow > 10000 && (int($itrow/10000)==$itrow/10000));
	
    }
    $nrow=$itrow;
    close($fhin);
    undef @tmp;

    return(1,"ok $sbrName");
}				# end of fileInRd

#===============================================================================
sub fileInRd_oneLine {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileInRd_oneLine            stores the line read in RDB
#-------------------------------------------------------------------------------
    ++$itrow;
    if ($par{"doMirror"}) { 
	++$nprot;
	$ptr_this2fin[$itrow]=$nprot; 
    }
				# store array read
    foreach $itcol (1..$#tmp){
	$rd[$itrow][$itcol]= $tmp[$itcol];
				# add to final for mirroring option
	$fin[$nprot][$itcol]=$tmp[$itcol] if ($par{"doMirror"});
    }
				# massage id (if NOT pdb)
    if (! $par{"doCheckRes"} && $LnamesLower){
	if (defined $rd[$itrow][$ptr{"id1"}]){
	    $rd[$itrow][$ptr{"id1"}]=~tr/[A-Z]/[a-z]/;}
	if (defined $rd[$itrow][$ptr{"id2"}]){
	    $rd[$itrow][$ptr{"id2"}]=~tr/[A-Z]/[a-z]/;}
    }
    if (defined $rd[$itrow][$ptr{"id2"}]){
	$rd[$itrow][$ptr{"id2"}]=~s/^.*\|//g;
    }
}				# end of fileInRd_oneLine 

#===============================================================================
sub fileResRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileResRd                   reads the RDB file with PDB resolutions
#       NOTE:                   1107 means resolution not given in PDB
#                               100  means PDB file was not existing (when I 
#                                    compiled the list..)
#       FORMAT:                 
#                               #
#                               id     res
#                               1pdb   3.0
#                               
#       out GLOBAL:             $res{"$id"} : resolution for $id (note: NO chains!!)
#                               
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fileResRd";
    $fhinLoc="FHIN_"."fileResRd";$fhoutLoc="FHIN_"."fileResRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);

    if (! -e $fileInLoc) { 
	$tmp="*** $scrName: seems you wanted to pass a file (fileRes=$fileRes) with\n".
	     "    all PDB resolutions as input, but the file is missing!!\n";
	return(&errSbr($tmp));}

				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %res;

				# ------------------------------
    while (<$fhinLoc>) {	# read file
	next if ($_=~/^\#/);	# skip comments
	$_=~s/\n//g;
	next if ($_=~/^id/);	# skip names
	$_=~s/[\s\t]*$//g;	# purge ending blanks,tabs
	@tmp=split(/[\s\t]+/,$_);
	$id= $tmp[1];
	$res=$tmp[$#tmp];
	$res{$id}=$res; 
    } close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of fileResRd

#===============================================================================
sub filter1Loc {
    local($itrowLoc,@lineRd)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   filter1Loc                  filters pairs (one line)
#       in:                     $itrow:  counting protein pairs in current file
#       in:                     @lineRd: current line, columns
#       out:                    $Ltake (0|1), $dist (only for take)
#       in/out GLOBAL:          all
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."filter1Loc";$fhinLoc="FHIN_"."filter1Loc";

				# ------------------------------
				# skip identical
    if (! $par{"allowSelf"} && $lineRd[$ptr{"id1"}] eq $lineRd[$ptr{"id2"}]){
	return(0,0); }
				# ------------------------------
				# length:
    $lali=$lineRd[$ptr{"lali"}];
    if (! defined $lali){ 
	print "*** ERROR: itrowLoc=$itrowLoc, tot=$ctrowErr, col for lali (",$ptr{"lali"},") missing\n";
	print "***        line=$line\n";
	exit;} 
				# ---> too short
    return(0,0) if ($lali < $par{"minLali"});

				# sequence identity
    $pide=$lineRd[$ptr{"pide"}];
    if (! defined $pide){ 
	print "*** ERROR: itrowLoc=$itrowLoc, col for pide (",$ptr{"pide"},") missing\n";
	print "***        line=$line\n";
	exit;} 
				# ------------------------------
				# distance from threshold:
    ($Lok,$msg,$dist)=
	&getDistanceThresh($par{"modeFilter"},$lali,$pide);
    if (! $Lok) { 
	print 
	    "*** ERROR $sbrName: failed on getDistanceThresh",
	    " for (lali=$lali, pide=$pide)",$msg,"\n"; 
	return(0,0); }
				# ---> too far
    return(0,0) if ($dist <= $par{"minDist"});
#	print "xx lali=$lali, pide=$pide, dist=$dist,\n";
				# ------------------------------
				# take
    return(1,$dist);
}				# end of filter1Loc

#===============================================================================
sub getPairsLoc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPairsLoc                 all pairs into : %pairs, @pairs 
#       in  GLOBAL:             @Ltake, @rd, @dist, $nrow, %ptr, $resMax
#       out GLOBAL:             $pairs{$id1,"res"}= resolution of id1
#       out GLOBAL:             $pairs{$id1,"len"}= length of id1
#       out GLOBAL:             $pairs{$id1}=       "a, b, c"
#       out GLOBAL:             $pairs{$id1,"dist"}="Da,Db,Dc"
#       out GLOBAL:             @pairs=           array of all uniq first ids
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."getPairsLoc";$fhinLoc="FHIN_"."getPairsLoc";
    foreach $itrow (1..$nrow){
	$id1=$rd[$itrow][$ptr{"id1"}];
	if (! defined $pairs{$id1}){
	    push(@pairs,$id1);
	    $pairs{$id1}="";
	    $pairs{"$id1","dist"}="";
				# ------------------------------
				# get length
	    $fileFasta=$par{"dirDataOrigin"}.$id1.$par{"extOrigin"};
	    if (! -e $fileFasta) {
		$tmp=$id1; $tmp=~s/^[^\_]+\_(.).*$/$1/g;
		$fileFasta=$par{"dirDataOrigin"}.$tmp."/".$id1.$par{"extOrigin"};}
	    return(&errSbr("original fasta id=$id1 ($fileFasta, dirDataOrigin=x) missing"))   if (! -e $fileFasta);
	    return(&errSbr("original fasta ($fileFasta) not FASTA")) if (! &isFasta($fileFasta));
	    ($Lok,$id,$seq)=
		&fastaRdGuide($fileFasta);
	    return(&errSbrMsg("failed reading fasta ($fileFasta)",$id)) if (! $Lok);
	    $seq=~s/[^A-Za-z]//g;
	    $len=length($seq); 
	    $pairs{"$id1","len"}=$len;
				# mirror option
	    $finLen{"$id1"}=$len if ($par{"doMirror"});
				# ------------------------------
				# get resolution
	    if ($par{"doCheckRes"}) {
		($Lok,$msg)=
		    &ass_getRes();
		return(&errSbrMsg("failed getting resolution (id=$id1)\n",$msg)) if (! $Lok); }
	}
				# skip?
	$id2=$rd[$itrow][$ptr{"id2"}];
	next if ($id2 eq $id1);	# skip self
	$pairs{$id1}.=$id2.",";
	return(&errSbr("itrow=$itrow, no distance defined ".
		       "($id1,$id2)")) if (! defined $rd[$itrow][$ncol]);
	$pairs{"$id1","dist"}.=sprintf("%-d,",int($rd[$itrow][$ptr{"dist"}]));
    }

    return(1,"ok $sbrName");
}				# end of getPairsLoc

#===============================================================================
sub ass_getRes {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass_getRes                  gets resolution
#       in|out GLOBL:           all
#       err:                    0|1,$msg
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."ass_getRes";
    $idx=substr($id1,1,4);
				# (1) resolution given in file
    if (defined %res){
	$res=$par{"resUnk"};
	$res=$res{"$idx"} if (defined $res{"$idx"}); }
				# (2) grep resolution from PDB file
    elsif (defined $par{"dirDataPdb"} && -d $par{"dirDataPdb"}){
	$filePdb=$par{"dirDataPdb"}.$idx.$par{"extPdb"};
	$res=$par{"resMax"};

	if (-e $filePdb){
	    ($Lok,$msg,$res)=
		&pdbGrepResolution($filePdb,0,0,$par{"resMax"});
	    return(&errSbrMsg("failed on grepping PDB resolution from $filePdb",
			      $msg)) if (! $Lok); } }
    else {
	return(&errSbr("come on you do NOT give a valid PDB directory (".
		       $par{"dirDataPdb"}.")\n".
		       "you do NOT give a file by fileRes=x, but you want the \n".
		       "PDB resolution to be checked??? \n".
		       "do provide the argument 'doCheckRes=0' on the comand line!\n".
		       "or a good PDB directory"));}
    $pairs{"$id1","res"}=$res; 
				# mirror option
    $finRes{"$id1"}=$res if ($par{"doMirror"});

    return(1,"ok $sbrName");
}				# end of ass_getRes

#===============================================================================
sub uniqIdLoc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   uniqIdLoc                   get lists of unique identifiers to take (write)
#       in/out GLOBAL:          all
#                               $rd[itrow][itcol], $ncol, $nrow
#       out GLOBAL:             $id1[1..$nrow], $id2[1..$nrow]
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."uniqIdLoc";$fhinLoc="FHIN_"."uniqIdLoc";

    $#id1=$#id2=0;
    foreach $itrow (1..$nrow){
	$id1=$rd[$itrow][$ptr{"id1"}];
	return(&errSbr("no ptr id1 (itrow=$itrow)=".$ptr{"id1"}.", ?")) if (! defined $id1);
	$id2=$rd[$itrow][$ptr{"id2"}];
	return(&errSbr("no ptr id2 (itrow=$itrow, id1=$id1, ptr(id2)=".
		       $ptr{"id2"}.",?")) if (! defined $id2);
				# first 
	if (! defined $id1{$id1}) { 
	    push(@id1,$id1);
	    $id1{$id1}=$id2.",";}
	else                      { 
	    $id1{$id1}.=$id2.",";}
				# second
	if (! defined $id2{$id2}) { 
	    push(@id2,$id2);
	    $id2{$id2}=$id1.",";}
	else                      { 
	    $id2{$id2}.=$id1.",";}
	if ($par{"verb2"}){
	    $lali=$rd[$itrow][$ptr{"lali"}];
	    $pide=$rd[$itrow][$ptr{"pide"}];
	    $dist="?";
	    $dist=$rd[$itrow][$ncol] if (defined $rd[$itrow][$ncol]);
	    printf "%-6s %-6s %5d %5d %6.1f\n",$id1,$id2,$lali,$pide,$dist if ($dist ne "?");
	    printf "%-6s %-6s %5d %5d %6s\n",  $id1,$id2,$lali,$pide,$dist if ($dist eq "?");
	}
    }
    return(1,"ok $sbrName");
}				# end of uniqIdLoc

#===============================================================================
sub wrtMirrorLoc {
    local($fileOutLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtMirrorLoc                mirror the input file with 
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtMirrorLoc";$fhoutLoc="FHOUT_"."wrtMirrorLoc";
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);
				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") 
	|| return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
				# header 
				# ------------------------------
    $expect=  "id1,id2,lali,pide,dist,len1";   $expect.=",res,"  if ($par{"doCheckRes"});
    $para=    "numProt,modeDist";              $para.=",maxRes"  if ($par{"doCheckRes"}); 
    $tmp{"name"}=           $scrName;
    $tmp{"nota","expect"}=  $expect;
    $tmp{"nota","id1"}=     "first identifier  (guide sequence)";
    $tmp{"nota","id2"}=     "second identifier (aligned sequence)";
    $tmp{"nota","lali"}=    "alignment length";
    $tmp{"nota","pide"}=    "percentage sequence identity";
    $tmp{"nota","dist"}=    "distance from HSSP (new) threshold";
    $tmp{"nota","len1"}=    "length of id1     (guide sequence)";
    $tmp{"nota","res"}=     "PDB resolution of id1 (resMax=".$par{"resMax"}.")";
    
    $tmp{"nota","1"}=       "numProt". "\t"."number of proteins (rows)";
    $tmp{"nota","2"}=       "modeDist"."\t"."threshold curve used: old=HSSP, new=newIde, newSim";
    $tmp{"nota","3"}=       "maxRes".  "\t"."resolution used if not provided in PDB";

    $tmp{"para","expect"}=  $para;
    $tmp{"para","numProt"}= $nprot;
    $tmp{"para","modeDist"}=$par{"modeFilter"};
    $tmp{"para","maxRes"}=  $par{"resMax"};
    $tmp{"form","numProt"}= "%6d";
    $tmp{"form","maxRes"}=  "%6d";

    ($Lok,$msg)=
	&rdbGenWrtHdr($fhoutLoc,%tmp);
    return(&errSbrMsg("failed writing RDB header for $fileOutLoc",$msg)) if (! $Lok);
				# ------------------------------
				# names
				# ------------------------------
    print $fhoutLoc "id1",$SEP,"id2",$SEP,"lali",$SEP,"pide",$SEP,"dist",$SEP,"len1";
    print $fhoutLoc $SEP,"res"     if ($par{"doCheckRes"});
    print $fhoutLoc "\n";
				# ------------------------------
				# data
				# ------------------------------
    foreach $it (1..$nprot){
	$id1=$fin[$it][$ptr{"id1"}];

	$tmpWrt=     $id1;
	$tmpWrt.=    $SEP.$fin[$it][$ptr{"id2"}];
	$tmpWrt.=    sprintf ("$SEP%6d",  $fin[$it][$ptr{"lali"}]);
	$tmpWrt.=    sprintf ("$SEP%6d",  $fin[$it][$ptr{"pide"}]);
	$tmpWrt.=    sprintf ("$SEP%6.1f",$fin[$ptr{"dist"}]);
	$tmpWrt.=    sprintf ("$SEP%6d",  $finLen{"$id1"});
	$tmpWrt.=    sprintf ("$SEP%6.2f",$finRes{"$id1"}) if ($par{"doCheckRes"});

	print $fhoutLoc $tmpWrt,"\n";
	print      $tmpWrt,"\n" if ($par{"verb2"});
    }
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of wrtMirrorLoc

#===============================================================================
sub wrtPairsLoc {
    local($fileOutLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtPairsLoc                 writes RDB of all pairs
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtPairsLoc";$fhoutLoc="FHOUT_"."wrtPairsLoc";
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);
				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") 
	|| return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
				# header 
				# ------------------------------
    $expect=  "id1,len,";   $expect.="res," if ($par{"doCheckRes"}); $expect.="id2,dist";
    $para=    "numProt,modeDist,features"; $para.=",maxRes"  if ($par{"doCheckRes"}); 
    $features="len";                       $features.=",res" if ($par{"doCheckRes"}); 
    $tmp{"name"}=           $scrName;
    $tmp{"nota","expect"}=  $expect;
    $tmp{"nota","id1"}=     "first identifier";
    $tmp{"nota","len"}=     "length of id1";
    $tmp{"nota","res"}=     "PDB resolution of id1 (resMax=".$par{"resMax"}.")";
    $tmp{"nota","id2"}=     "second identifier     (list separated by ',')";
    $tmp{"nota","dist"}=    "distance between id1 and id2 from threshold (list separated by ',')";
    $tmp{"nota","1"}=       "numProt". "\t"."number of proteins (rows)";
    $tmp{"nota","2"}=       "modeDist"."\t"."threshold curve used: old=HSSP, new=newIde, newSim";
    $tmp{"nota","3"}=       "features"."\t"."list of features for id1 (e.g. 'len,res')";
    $tmp{"nota","4"}=       "maxRes".  "\t"."resolution used if not provided in PDB";

    $tmp{"para","expect"}=  $para;
    $tmp{"para","numProt"}= $#pairs;
    $tmp{"para","modeDist"}=$par{"modeFilter"};
    $tmp{"para","features"}=$features;
    $tmp{"para","maxRes"}=  $par{"resMax"};
    $tmp{"form","numProt"}= "%6d";
    $tmp{"form","maxRes"}=  "%6d";

    ($Lok,$msg)=
	&rdbGenWrtHdr($fhoutLoc,%tmp);
    return(&errSbrMsg("failed writing RDB header for $fileOutLoc",$msg)) if (! $Lok);
				# ------------------------------
				# names
				# ------------------------------
    print $fhoutLoc "id1",$SEP,"len";
    print $fhoutLoc $SEP,"res"  if ($par{"doCheckRes"});
    print $fhoutLoc $SEP,"id2",$SEP,"dist","\n";

				# ------------------------------
				# data
				# ------------------------------
    foreach $id1 (@pairs){
	$tmpWrt=     "$id1";
	$tmpWrt.=    $SEP.$pairs{"$id1","len"};
	$tmpWrt.=    $SEP.$pairs{"$id1","res"} if ($par{"doCheckRes"});
				# get id2 arrays
	$pairs{$id1}=~s/,*$//g;          @tmp_id2= split(/,/,$pairs{$id1});
	$pairs{"$id1","dist"}=~s/,*$//g; @tmp_dist=split(/,/,$pairs{"$id1","dist"});
	return(&errSbr("id1=$id1, arrays for id2 and dist differ:\n".
		       "id2 =".$pairs{$id1}."\n".
		       "dist=".$pairs{"$id1","dist"})) if ($#tmp_id2 != $#tmp_dist);
				# write id2,dist arrays
	$tmpWrt.=    $SEP.$pairs{$id1};
	$tmpWrt.=    $SEP.$pairs{"$id1","dist"};
	print $fhoutLoc $tmpWrt,"\n";
	print      $tmpWrt,"\n" if ($par{"verb2"});
    }
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of wrtPairsLoc

