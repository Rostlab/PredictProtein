#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "Evaluate accessibility prediction\n".
    "      \t compute protein averages over ri and simple Q2/Q3/Q10/corr(in: tmp.exprel)\n".
    "      \t \n";
$scrIn=      "file*rdb (or list0";            # 
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
($Lok,$msg)=			# initialise variables
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$#id=0;undef %id;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
				# ------------------------------
				# read RDB file
    ($Lok,$msg)=
	&rdRdb_here($fileIn
		    );          &errScrMsg("failed reading RDB file=$fileIn") if (! defined $rdb{"NROWS"});
#      print "xx red\n";
	
#    foreach $itres (1..$rdb{"NROWS"}){
#  	print "xx $itres orel=",$rdb{"OREL",$itres},", prel=",$rdb{"PREL",$itres},"\n";
#    }die;
    $rdb{"NALIGN"}=$rdb{"PROT_NALI"} if (! defined $rdb{"NALIGN"} && defined $rdb{"PROT_NALI"});
				# hack: get NALIGN
    if (! defined $rdb{"NALIGN"}){
	($Lok,$msg,$rdb{"NALIGN"})=
	    &hackGrepNali($fileIn
			  );    &errScrMsg("failed to get NALIGN for file=$fileIn",$msg) if (! $Lok);
	print "-*- WARN $scrName: $msg\n" if ($Lok>1); }

				# digest info
				# out GLOBAL: %res, @id
    ($Lok,$msg)=
	&analyse($fileIn);      &errScrMsg("failed to analyse for file=$fileIn",$msg) if (! $Lok);
}
				# ------------------------------
				# (2) postprocess
				# ------------------------------
($Lok,$msg)=
    &postprocess();             &errScrMsg("failed to postprocess",$msg) if (! $Lok);

				# ------------------------------
				# (3) write out
				# ------------------------------
($Lok,$msg)=
    &wrtout($fileOut);          &errScrMsg("failed to wrtout file=$fileOut",$msg) if (! $Lok);

print "--- output in $fileOut\n" if (-e $fileOut);
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
	  'thresh2',           "16",    # <16 -> buried, >= -> exposed
	  'thresh3',           "9,36",  # <9 -> buried, >=36 -> exposed, else intermediate
	  '', "",			# 
	  'title',          "",	    # to be used in output file (added to column names)
	  '', "",			# 
	  'dirHssp',           "/data/hssp/",			# 
	  'extHssp',           ".hssp",			# 
	  '', "",			# 
	  'dori',              1,       # read and compile reliability index
	  'doq2',              1,       # read and compile two state accuracy
	  'doq3',              1,       # read and compile three state accuracy
	  'doq10',             1,       # read and compile ten state accuracy
	  'docorr',            1,       # read and compile correlation
	  'dodetail',          1,       # compile e.g. Q2b%obs,Q2e%obs,Q2e%prd,Q2e%prd
	  );
    @kwd=sort (keys %par);
    @thresh2=split(/,/,$par{"thresh2"});
    @thresh3=split(/,/,$par{"thresh3"});

#    @kwdRes=
#	("q2","q3","q10","corr");

    @kwdRdBody=
	("AA","OREL","PREL","RI_A",
#	 "Obie","Pbie","Ot0","Ot1","Ot2","Ot3","Ot4","Ot5","Ot6","Ot7","Ot8","Ot9"
	 );
    foreach $kwd (@kwdRdBody){
	$kwdRdBody{$kwd}=1;}

    @kwdRdHead=
	("NALIGN","PROT_NALI"
	 );


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
	
	printf "%5s %-15s=%-20s %-s\n","","thresh2", "x",       "16 for binary b|e";
	printf "%5s %-15s=%-20s %-s\n","","thresh3", "a,b",     "e.g 9,36 for ternary b|i|e";

	printf "%5s %-15s %-20s %-s\n","","list",    "no value","list of RDB files (automatically recognised: extension '.list')";
	
	printf "%5s %-15s %-20s %-s\n","ri","",       "no value","do reliability index";
	printf "%5s %-15s %-20s %-s\n","nori","",     "no value","doNOT ";
	printf "%5s %-15s %-20s %-s\n","q2","",       "no value","do two-state acc";
	printf "%5s %-15s %-20s %-s\n","noq2","",     "no value","doNOT ";
	printf "%5s %-15s %-20s %-s\n","q3","",       "no value","do three-state acc";
	printf "%5s %-15s %-20s %-s\n","noq3","",     "no value","doNOT ";
	printf "%5s %-15s %-20s %-s\n","q10","",      "no value","do ten-state acc";
	printf "%5s %-15s %-20s %-s\n","noq10","",    "no value","doNOT ";
	printf "%5s %-15s %-20s %-s\n","corr","",     "no value","do correlation";
	printf "%5s %-15s %-20s %-s\n","nocorr","",   "no value","doNOT ";

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
    $#fileIn=0;
    $LisList=0;
    $sep="\t";
				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
	elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
						$Lverb=          1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
	
	elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}

	elsif ($arg=~/^(ri|q2|q3|q10|corr)$/)   { $par{"do".$1}=   1;}
	elsif ($arg=~/^no(ri|q2|q3|q10|corr)$/) { $par{"do".$1}=   0;}
	elsif ($arg=~/^det.*$/)                 { $par{"dodetail"}=1;}
	elsif ($arg=~/^nodet.*$/)               { $par{"dodetail"}=0;}

	elsif ($arg=~/^sep=(.*)$/)            { $tmp=            $1;
						$sep="\t"        if ($tmp=~/TAB/);
						$sep=" "         if ($tmp=~/SPACE|\s/); }
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif (-e $arg)                       { push(@fileIn,$arg); 
						$LisList=        1 if ($arg=~/\.list/);}
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
	    $fileOut="Out-evalexp.dat";}}

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
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);
    return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); 

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub hackGrepNali {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
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
sub analyse {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   analyse                     compiles accuracy
#       in:                     $fileInLoc
#       in GLOBAL:              %rdb
#       out GLOBAL:             %res
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."analyse";
				# check arguments
    return(&errSbr("not def fileInLoc!"))         if (! defined $fileInLoc);
				# digest info
    $id=$fileInLoc; 
    $id=~s/^.*\///g;		# purge dir
    $id=~s/\..*$//g;		# purge ext

				# ------------------------------
				# watch ids used twice!
    if (defined $id{$id}){
	$cttmp=2;
	$idtmp=$id."-".$cttmp;
	while ($cttmp < 100 && defined $id{$idtmp}){
	    ++$cttmp;
	    $idtmp=$id."-".$cttmp;}
	return(&errSbr("id=$id not unique, increase counter in sbr, or use other ids"))
	    if (defined $id{$idtmp});
	$id=$idtmp;}
    $id{$id}=1;
    push(@id,$id);

    $res{$id,"nres"}=$rdb{"NROWS"};
    $res{$id,"nali"}="?";
    $res{$id,"nali"}=$rdb{"NALIGN"} if (defined $rdb{"NALIGN"});
    return(&errSbr("empty??? nres=0 for file=$fileInLoc")) if (! defined $rdb{"NROWS"} ||
							       $rdb{"NROWS"} < 1);
				# --------------------------------------------------
				# sum reliability index
    $sum=0;
    foreach $itres (1..$res{$id,"nres"}){
	next if (! defined $rdb{"RI_A",$itres} ||
		 $rdb{"AA",$itres} eq "!"      ||
		 $rdb{"RI_A",$itres}=~/\D/     ||
		 length($rdb{"RI_A",$itres})<1 );
	$sum+=$rdb{"RI_A",$itres}; }

    $res{$id,"ri"}=$sum/$res{$id,"nres"};
				# --------------------------------------------------
				# get all relative accessibility values
    $#obs=$#prd;
    foreach $itres (1..$res{$id,"nres"}){
	next if (! defined $rdb{"OREL",$itres} ||
		 $rdb{"AA",$itres} eq "!");
	$obs="?";$prd="?";
	$obs=$rdb{"OREL",$itres} if (defined $rdb{"OREL",$itres} && 
				     $rdb{"OREL",$itres}!~/\D/);
	$prd=$rdb{"PREL",$itres} if (defined $rdb{"PREL",$itres} && 
				     $rdb{"PREL",$itres}!~/\D/);
	push(@obs,$obs);push(@prd,$prd);}

				# --------------------------------------------------
                                # recompile Q2,Q3,Q10,corr
				# --------------------------------------------------
    $cttmp=$#tmpobs=$#tmpprd=0;

    foreach $it (1..$#prd){
	next if ($prd[$it] =~/\D/    || $obs[$it] =~/\D/ ||
		 length($prd[$it])<1 || length($obs[$it])<1);
				# ------------------------------
				# 10 state
	($Lok,$msg,$prd10)=    &convert_accRel2oneDigit($prd[$it]);
	if ($prd10 !~/\D/){
	    ($Lok,$msg,$obs10)=&convert_accRel2oneDigit($obs[$it]);
	    ++$res{$id,"q10"}   if ($obs10 !~/\D/ && $prd10 == $obs10); 
	    ++$res{$id,"n10"}; }
				# ------------------------------
				# 2 state
	++$res{$id,"n2"};	# count all residues for which acc was ok
				# buried
	if ($prd[$it]<= $thresh2[1]){
	    ++$res{$id,"n2p",1};
	    if ($obs[$it] <= $thresh2[1]){
		++$res{$id,"n2o",1};
		++$res{$id,"q2"};
		++$res{$id,"q2",1};}
	    else {
		++$res{$id,"n2o",2};}}
				# exposed
	else {
	    ++$res{$id,"n2p",2};
	    if ($obs[$it] >  $thresh2[1]) {
		++$res{$id,"n2o",2};
		++$res{$id,"q2"};
		++$res{$id,"q2",2};}
	    else {
		++$res{$id,"n2o",1};}}
		
				# ------------------------------
				# 3 state
	++$res{$id,"n3"};	# count all residues for which acc was ok
				# buried
	if    ($prd[$it] <= $thresh3[1]){
	    ++$res{$id,"n3p",1};
	    if    ($obs[$it] <= $thresh3[1]){
		++$res{$id,"n3o",1};
		++$res{$id,"q3"};
		++$res{$id,"q3",1};}
	    elsif ($obs[$it] >  $thresh3[2]){
		++$res{$id,"n3o",3};}
	    else {
		++$res{$id,"n3o",2};}}
				# exposed
	elsif ($prd[$it] >  $thresh3[2]){
	    ++$res{$id,"n3p",3};
	    if    ($obs[$it] >  $thresh3[2]){
		++$res{$id,"n3o",3};
		++$res{$id,"q3"};
		++$res{$id,"q3",3};}
	    elsif ($obs[$it] <= $thresh3[1]){
		++$res{$id,"n3o",1};}
	    else {
		++$res{$id,"n3o",2};}}
				# intermediate
	else {
	    ++$res{$id,"n3p",2};
	    if    ($obs[$it] <= $thresh3[1]){
		++$res{$id,"n3o",1};}
	    elsif ($obs[$it] >  $thresh3[2]){
		++$res{$id,"n3o",3};}
	    else {
		++$res{$id,"n3o",2};
		++$res{$id,"q3"};
		++$res{$id,"q3",2};}}
	++$cttmp;push(@tmpobs,($obs[$it]/100));push(@tmpprd,($prd[$it]/100));
    }
				# ------------------------------
				# get correlation
    $res{$id,"corr"}=
	&correlation($cttmp,@tmpobs,@tmpprd);
    $res{$id,"corr"}=0         if ($res{$id,"corr"}=~/[^\d\.]/);
    
    return(1,"ok $sbrName");
}				# end of analyse


#===============================================================================
sub postprocess {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   postprocess                 compiles averages asf
#       in GLOBAL:              %res,@kwdRes,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."postprocess";     $fhoutLoc="FHOUT_"."postprocess";
    
				# ------------------------------
				# compile z-score for reliability index
    $#tmp=0;
    foreach $id (@id){
	push(@tmp,$res{$id,"ri"});
    }
				# average and variation
    ($ave,$var)=&stat_avevar(@tmp);
    $sig=sqrt($var);
				# problem
    if ($sig == 0){ 
	foreach $id (@id){
	    $res{$id,"zri"}="0";}}
    else {
	foreach $id (@id){
	    $res{$id,"zri"}=($res{$id,"ri"}-$ave)/$sig;
	}}
				# ------------------------------
				# compile sums
    foreach $kwd ("nres","nali","ri","zri",
		  "q2","n2o1","n2o2","q2o1","q2o2","q2p1","q2p2",
		  "q3","n3o1","n3o3","q3o1","q3o2","q3o3","q3p1","q3p2","q3p3",
		  "q10","corr"){
	$res{"sum",$kwd}=0;}

    foreach $id (@id){
	$res{"sum","nres"}+=$res{$id,"nres"};
	$res{"sum","nali"}+=$res{$id,"nali"} if ($res{$id,"nali"}!~/\D/);
				# reliability index
	if ($par{"dori"}){
	    $res{"sum","ri"}+=  $res{$id,"ri"};
	    $res{"sum","zri"}+= $res{$id,"zri"};}
				# two states
	if ($par{"doq2"}){
	    if (defined $res{$id,"q2"} && $res{$id,"q2"}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q2"}/$res{$id,"n2"});
		$res{$id,"q2"}=     $tmp;
		$res{"sum","q2"}+=  $tmp;}
	    else { $res{$id,"q2"}=     0;}
	    if (defined $res{$id,"n2o",1} && $res{$id,"n2o",1}!~/[^\d\.]/){
		$tmp=100*($res{$id,"n2o",1}/$res{$id,"n2"});
		$res{$id,"n2o1"}=   $tmp;
		$res{"sum","n2o1"}+=$tmp;}
	    else { $res{$id,"n2o1"}=   0;}
	    if (defined $res{$id,"n2o",2} && $res{$id,"n2o",2}!~/[^\d\.]/){
		$tmp=100*($res{$id,"n2o",2}/$res{$id,"n2"});
		$res{$id,"n2o2"}=   $tmp;
		$res{"sum","n2o2"}+=$tmp;}
	    else { $res{$id,"n2o2"}=   0;}
	    if (defined $res{$id,"q2",1} && $res{$id,"q2",1}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q2",1}/$res{$id,"n2o",1});
		$res{$id,"q2o1"}=   $tmp;
		$res{"sum","q2o1"}+=$tmp;}
	    else { $res{$id,"q2o1"}=   0;}
	    if (defined $res{$id,"q2",2} && $res{$id,"q2",2}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q2",2}/$res{$id,"n2o",2});
		$res{$id,"q2o2"}=   $tmp;
		$res{"sum","q2o2"}+=$tmp;}
	    else { $res{$id,"q2o2"}=   0;}
	    if (defined $res{$id,"q2",1} && $res{$id,"q2",1}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q2",1}/$res{$id,"n2p",1});
		$res{$id,"q2p1"}=   $tmp;
		$res{"sum","q2p1"}+=$tmp;}
	    else { $res{$id,"q2p1"}=   0;}
	    if (defined $res{$id,"q2",2} && $res{$id,"q2",2}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q2",2}/$res{$id,"n2p",2});
		$res{$id,"q2p2"}=   $tmp;
		$res{"sum","q2p2"}+=$tmp;}
	    else { $res{$id,"q2p2"}=   0;}
	}			# end of Q2

				# three states
	if ($par{"doq3"}){
	    if (defined $res{$id,"q3"} && $res{$id,"q3"}!~/[^\d\.]/){
		$tmp=  100*($res{$id,"q3"}/$res{$id,"n3"});
		$res{$id,"q3"}=   $tmp;
		$res{"sum","q3"}+=$tmp;}
	    else { $res{$id,"q3"}=   0;}
	    if (defined $res{$id,"n3o",1} && $res{$id,"n3o",1}!~/[^\d\.]/){
		$tmp=100*($res{$id,"n3o",1}/$res{$id,"n3"});
		$res{$id,"n3o1"}=   $tmp;
		$res{"sum","n3o1"}+=$tmp;}
	    else { $res{$id,"n3o1"}=   0;}
	    if (defined $res{$id,"n3o",2} && $res{$id,"n3o",2}!~/[^\d\.]/){
		$tmp=100*($res{$id,"n3o",2}/$res{$id,"n3"});
		$res{$id,"n3o2"}=   $tmp;
		$res{"sum","n3o2"}+=$tmp;}
	    else { $res{$id,"n3o3"}=   0;}
	    if (defined $res{$id,"n3o",3} && $res{$id,"n3o",3}!~/[^\d\.]/){
		$tmp=100*($res{$id,"n3o",3}/$res{$id,"n3"});
		$res{$id,"n3o3"}=   $tmp;
		$res{"sum","n3o3"}+=$tmp;}
	    else { $res{$id,"n3o3"}=   0;}
	    if (defined $res{$id,"q3",1} && $res{$id,"q3",1}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q3",1}/$res{$id,"n3o",1});
		$res{$id,"q3o1"}=   $tmp;
		$res{"sum","q3o1"}+=$tmp;}
	    else { $res{$id,"q3o1"}=   0;}
	    if (defined $res{$id,"q3",2} && $res{$id,"q3",2}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q3",2}/$res{$id,"n3o",2});
		$res{$id,"q3o2"}=   $tmp;
		$res{"sum","q3o2"}+=$tmp;}
	    else { $res{$id,"q3o2"}=   0;}
	    if (defined $res{$id,"q3",3} && $res{$id,"q3",3}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q3",3}/$res{$id,"n3o",3});
		$res{$id,"q3o3"}=   $tmp;
		$res{"sum","q3o3"}+=$tmp;}
	    else { $res{$id,"q3o3"}=   0;}
	    if (defined $res{$id,"q3",1} && $res{$id,"q3",1}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q3",1}/$res{$id,"n3p",1});
		$res{$id,"q3p1"}=   $tmp;
		$res{"sum","q3p1"}+=$tmp;}
	    else { $res{$id,"q3p1"}=   0;}
	    if (defined $res{$id,"q3",2} && $res{$id,"q3",2}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q3",2}/$res{$id,"n3p",2});
		$res{$id,"q3p2"}=   $tmp;
		$res{"sum","q3p2"}+=$tmp;}
	    else { $res{$id,"q3p2"}=   0;}
	    if (defined $res{$id,"q3",3} && $res{$id,"q3",3}!~/[^\d\.]/){
		$tmp=100*($res{$id,"q3",3}/$res{$id,"n3p",3});
		$res{$id,"q3p3"}=   $tmp;
		$res{"sum","q3p3"}+=$tmp;}
	    else { $res{$id,"q3p3"}=   0;}
	}			# end of Q3

				# ten states
	if ($par{"doq10"}){
	    if (defined $res{$id,"q10"} && $res{$id,"q10"}!~/[^\d\.]/){
		$tmp= 100*($res{$id,"q10"}/$res{$id,"n10"});
		$res{$id,"q10"}=   $tmp;
		$res{"sum","q10"}+=$tmp;}
	    else { $res{$id,"q10"}=   0;}
	}
				# correlation
	if ($par{"docorr"}){
	    $res{"sum","corr"}+=$res{$id,"corr"};
	}
    }

				# normalise sums
    foreach $kwd ("nres","nali","ri","zri",
		  "q2","n2o1","n2o2","q2o1","q2o2","q2p1","q2p2",
		  "q3","n3o1","n3o2","n3o3","q3o1","q3o2","q3o3","q3p1","q3p2","q3p3",
		  "q10","corr"){
	next if (! defined $res{"sum",$kwd});
	$res{"sum",$kwd}=($res{"sum",$kwd}/$#id);
    }
    return(1,"ok $sbrName");
}				# end of postprocess

#===============================================================================
sub wrtout {
    local($fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtout                      write results
#       in:                     $fileOutLoc
#       in GLOBAL:              %res,@kwdRes,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."wrtout";     $fhoutLoc="FHOUT_"."wrtout";
    
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);

				# ------------------------------
				# open file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# ------------------------------
				# header
    $title=$par{"title"};
    $title="_".$title           if (length($title)>1);

				# protein
    $tmp= sprintf("%-s$sep"."%4s$sep"."%4s$sep",
		  "id".$title,"nres".$title,"nali".$title);
				# reliability index
    $tmp.=sprintf("%6s$sep"."%6s$sep",
		  "<ri>".$title,"z<ri>".$title)    if ($par{"dori"});
				# 2 states
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%5s$sep",
		  "ob".$title,"oe".$title,
		  "Q2".$title)                     if ($par{"doq2"});
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep",
		  "Q2b\%o".$title,"Q2b\%p".$title,
		  "Q2e\%o".$title,"Q2e\%p".$title) if ($par{"doq2"} && $par{"dodetail"});
				# 3 states
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%5s$sep",
		  "ob".$title,"oi".$title,"oe".$title,
		  "Q3".$title)                     if ($par{"doq3"});
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep",
		  "Q3b\%o".$title,"Q3b\%p".$title,
		  "Q3i\%o".$title,"Q3i\%p".$title,
		  "Q3e\%o".$title,"Q3e\%p".$title) if ($par{"doq3"} && $par{"dodetail"});
				# 10 states
    $tmp.=sprintf("%5s$sep","Q10",
		  $title)                          if ($par{"doq10"});
				# correlation
    $tmp.=sprintf("%6s$sep","corr",
		  $title)                          if ($par{"docorr"});
    $tmp=~s/$sep$//;
    $tmp.="\n";

    print $tmp                  if ($Lverb);
    print $fhoutLoc $tmp;

				# ------------------------------
				# body
    foreach $id (@id,"sum"){
	next if ($id eq "sum" && $#id==1);
	$idtmp=$id;
	$idtmp=$id."=".$#id     if ($id =~/^sum$/i);
	$res{$id,"nali"}=0      if (! defined $res{$id,"nali"} || $res{$id,"nali"}=~/\D/);
				# protein
	$tmp= sprintf("%-s$sep"."%4d$sep"."%4d$sep",
		      $idtmp,$res{$id,"nres"},$res{$id,"nali"});
				# reliability index
	$tmp.=sprintf("%5.2f$sep"."%6.3f$sep",
		      $res{$id,"ri"},$res{$id,"zri"})              if ($par{"dori"});
				# 2 states
	$tmp.=sprintf("%4d$sep"."%4d$sep"."%5.1f$sep",
		      int($res{$id,"n2o1"}),int($res{$id,"n2o2"}),
		      $res{$id,"q2"})                              if ($par{"doq2"});
	$tmp.=sprintf("%4d$sep"."%4d$sep"."%4d$sep"."%4d$sep",
		      int($res{$id,"q2o1"}),int($res{$id,"q2p1"}),
		      int($res{$id,"q2o2"}),int($res{$id,"q2p2"})) if ($par{"doq2"} && $par{"dodetail"});
				# 3 states
	$tmp.=sprintf("%4d$sep"."%4d$sep"."%4d$sep"."%5.1f$sep",
		      int($res{$id,"n3o1"}),int($res{$id,"n3o2"}),int($res{$id,"n3o3"}),
		      $res{$id,"q3"})                              if ($par{"doq3"});
	$tmp.=sprintf("%4d$sep"."%4d$sep"."%4d$sep"."%4d$sep"."%4d$sep"."%4d$sep",
		      int($res{$id,"q3o1"}),int($res{$id,"q3p1"}),
		      int($res{$id,"q3o2"}),int($res{$id,"q3p2"}),
		      int($res{$id,"q3o3"}),int($res{$id,"q3p3"})) if ($par{"doq3"} && $par{"dodetail"});
				# 10 states
	$tmp.=sprintf("%5.1f$sep",$res{$id,"q10"})       if ($par{"doq10"});
				# correlation
	$tmp.=sprintf("%5.3f$sep",$res{$id,"corr"})      if ($par{"docorr"});

	$tmp=~s/$sep$/\n/;

	print $tmp              if ($Lverb);
	print $fhoutLoc $tmp;
    }

    close($fhoutLoc);

    return(1,"ok $sbrName");
}				# end of wrtout

#==============================================================================
# library collected (begin) lll
#==============================================================================


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

#================================================================================
sub correlation {
    local($ncol, @data) = @_;
    local($it, $av1, $av2, $av11, $av22, $av12);
    local(@v1,@v2,@v11,@v12,@v22, $den, $dentmp, $nom);
    $[ =1;
#----------------------------------------------------------------------
#   correlation                 compiles the correlation between x and y
#       in:                     ncol,@data, where $data[1..ncol] =@x, rest @y
#       out:                    returned $COR=correlation
#       out GLOBAL:             COR, AVE, VAR
#----------------------------------------------------------------------

    $#v1=0;$#v2=0;
    for ($it=1;$it<=$#data;++$it) {
	if ($it<=$ncol) { push(@v1,$data[$it]); }
	else            { push(@v2,$data[$it]); }
    }
#   ------------------------------
#   <1> and <2>
#   ------------------------------
    $av1=&stat_avevar(@v1); 
    $av2=&stat_avevar(@v2);

#   ------------------------------
#   <11> and <22> and <12y>
#   ------------------------------
    for ($it=1;$it<=$#v1;++$it) { $v11[$it]=$v1[$it]*$v1[$it];} $av11=&stat_avevar(@v11);
    for ($it=1;$it<=$#v2;++$it) { $v22[$it]=$v2[$it]*$v2[$it];} $av22=&stat_avevar(@v22);
    for ($it=1;$it<=$#v1;++$it) { $v12[$it]=$v1[$it]*$v2[$it];} $av12=&stat_avevar(@v12);

#   --------------------------------------------------
#   nom = <12> - <1><2>
#   den = sqrt ( (<11>-<1><1>)*(<22>-<2><2>) )
#   --------------------------------------------------
    $nom=($av12-($av1*$av2));
    $dentmp=( ($av11 - ($av1*$av1)) * ($av22 - ($av2*$av2)) );
    if ($dentmp>0) {$den=sqrt($dentmp);} else {$den="NN"}
    if ( ($den ne "NN") && (($den<-0.00000000001)||($den>0.00000000001) ) ) {
	$COR=$nom/$den;
    } else { $COR="NN" }
    return($COR);
}				# end of correlation

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
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
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
	if ( $_=~/^\#/ ) { 
	    if ($_=~/PARA|VALUE/){
		foreach $kwd (@kwdRdHead){
		    next if (defined $rdb{$kwd});
		    if ($_=~/^.*(PARA\S*|VAL\S*)\s*:?\s*$kwd\s*[ :,\;=]+(\S+)/){
			$rdb{$kwd}=$2;
			next; }}
	    }
	    next; }
				# temporary hack xx
	next if ($_=~/^\s*Note/);
	last; }
				# ------------------------------
				# names
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
		$rdb{$ptr_num2name[$it],$ctrow}=$tmp[$it];
	    }
	}
    }
    close($fhinLoc);
    $rdb{"NROWS"}=$ctrow;
    return (1,"ok");
}				# end of rdRdb_here

#===============================================================================
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @data (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
    foreach $i (@data) { $ave+=$i; } 
    if ($#data > 0) { $AVE=($ave/$#data); } else { $AVE="0"; }
    foreach $i (@data) { $tmp=($i-$AVE); $var+=($tmp*$tmp); } 
    if ($#data > 1) { $VAR=($var/($#data-1)); } else { $VAR="0"; }
    return ($AVE,$VAR);
}				# end of stat_avevar

#==============================================================================
# library collected (end)   lll
#==============================================================================
