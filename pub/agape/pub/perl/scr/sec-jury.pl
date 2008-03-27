#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "compiles jury decision over various output files (phd,prof)\n".
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
#$dirScr=$0; $dirScr=~s/^(.*\/)[^\/]*$/$1/;
#$lib="lib-proferr.pl"; $Lok=0;

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------

				# --------------------------------------------------
				# loop over all proteins
				# --------------------------------------------------
$ctid=0;
foreach $id (@id){
    ++$ctid;
    if (! defined $id || 
	! defined $fileIn{$id}){
	print "-*- WARN $scrName: id=$id, no filein!\n";
	next; }
    @filetmp=split(/,/,$fileIn{$id});

    undef %rdb;
    $rdb{"id"}=$id;
#    $rdb{"NALIGN"}=$rdb{"PROT_NALI"} if (! defined $rdb{"NALIGN"} && defined $rdb{"PROT_NALI"});
				# ----------------------------------------
				# (1) loop over all predictions
				# ----------------------------------------
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$id,$ctid,(100*$ctid/$#id)
	    if ($par{"verbose"});
    $nprd= $#filetmp;
    $ctprd=0;
    foreach $fileIn (@filetmp){
	if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
			  --$nprd;
			  next;}
	++$ctprd;
	print "--- $scrName: \t file=$fileIn\n" 
	    if ($par{"debug"});
				# ------------------------------
				# read RDB file
				#      GLOBAL out: %rdbloc
	if (! $LisCaspFormat){
	    ($Lok,$msg)=
		&rdRdb_here
		    ($fileIn);  &errScrMsg("reading RDB file=$fileIn") if (! defined $rdbloc{"NROWS"});}
	else {			# read CASP file
				#      GLOBAL out: %rdbloc
	    ($Lok,$msg)=
		&rdCaspObsPrd
		    ($fileIn);  &errScrMsg("failed CASPfile=$fileIn") if (! defined $rdb{"NROWS"});}

	if (0){
	    foreach $itres (1..$rdbloc{"NROWS"}){
		print "xx $itres oHL=",$rdbloc{$itres,"OHEL"},", p=",$rdbloc{$itres,"PHEL"},"\n";
	    }die;
	}
		     
				# everything we need there?
	&errScrMsg("fileIn=$fileIn, seems no observed sec str given!!\n")
	    if (! defined $rdbloc{1,"OHEL"} && ! defined $rdbloc{1,"OTL"}  &&
		! defined $rdbloc{1,"OHL"}  && ! defined $rdbloc{1,"OEL"}  &&
		! defined $rdbloc{1,"OCL"}  && ! defined $rdbloc{1,"OHELBGT"} && 
		! defined $rdbloc{1,"OMN"}  );

				# ------------------------------
				# all into one array
	foreach $kwd (keys %rdbloc){
	    $rdb{$ctprd,$kwd}=$rdbloc{$kwd};
	}
	$rdb{"NROWS"}=
	    $rdbloc{"NROWS"}    if ($ctprd==1);
	
    }				# end of loop over this protein
				# ----------------------------------------
    
				# ----------------------------------------
				# (2) compile jury decision
				#     assumes e.g. keyword 'OtH'
				# ----------------------------------------
    $Lok=0;
				# not weighted
    if ($par{"optJury"} !~ /^weight/){
	foreach $itprd (1..$nprd){
	    $weight[$itprd]=1;}}
				# get weights
    else {
	foreach $itprd (1..$nprd){
	    $sum=0;
	    foreach $itres (1..$rdb{"NROWS"}){
		$sum+=$rdb{$itprd,$itres,$par{"sec_kwdri"}};}
	    $sum=$sum/$rdb{"NROWS"};
	    $weight[$itprd]=$sum/$rdb{"NROWS"};
	}}
	
	
    foreach $itres (1..$rdb{"NROWS"}){
	$#tmp=0;
	foreach $itout (1..$par{"sec_nstates"}){
	    $tmp[$itout]=0;}
				# 
	foreach $itprd (1..$nprd){
	    $#tmp1=0;
	    foreach $itout (1..$par{"sec_nstates"}){
		push(@tmp1,$rdb{$itprd,$itres,$par{"sec_kwdave"}.$outnum2sym[$itout]}); 
	    }
				# norm
	    $sum=0;
	    foreach $itout (1..$par{"sec_nstates"}){
		$sum+=$tmp1[$itout]; }
				# add to jury
	    foreach $itout (1..$par{"sec_nstates"}){
		$tmp[$itout]+=$weight[$itprd]*($tmp1[$itout]/$sum); }
	}
				# normalise jury
	$sum=0;
	foreach $itout (1..$par{"sec_nstates"}){
				# 
	    $tmp[$itout]=$tmp[$itout]/$nprd;
	    $sum+=$tmp[$itout]; }
				# output 0-100
	foreach $itout (1..$par{"sec_nstates"}){
	    $tmp[$itout]=int(100*$tmp[$itout]/$sum);}
				# winner
	$iwin=$max=0;
	foreach $itout (1..$par{"sec_nstates"}){
	    if ($max < $tmp[$itout]){
		$max=$tmp[$itout];
		$iwin=$itout;}}
	$rdb{$itres,"P".$par{"sec_states"}}=$outnum2sym[$iwin];
	foreach $itout (1..$par{"sec_nstates"}){
	    $rdb{$itres,$par{"sec_kwdave"}.$outnum2sym[$itout]}=
		$tmp[$itout];}
	$rdb{$itres,"O".$par{"sec_states"}}=
	    $rdb{1,$itres,"O".$par{"sec_states"}} if (defined $rdb{1,$itres,"O".$par{"sec_states"}});
	$rdb{$itres,"AA"}=$rdb{1,$itres,"AA"};
    }
				# ----------------------------------------
				# (3) write output
				# ----------------------------------------
    $fileOut=$id.$par{"extOutRdb"};
				# open file
    open($fhout,">".$fileOut) || &errScrMsg("to open fileout=$fileOut","line=".__LINE__);
    print $fhout
	"\# Perl-RDB\n",
	"\# \n",
	"\# jury sec (njury=".$nprd.")\n",
	"\# \n";
    print $fhout "No",$sep,"AA";
    print $fhout $sep,"O".$par{"sec_states"}
	if (defined $rdb{1,"O".$par{"sec_states"}});
    print $fhout $sep,"P".$par{"sec_states"};
    foreach $itout (1..$par{"sec_nstates"}){
	print $fhout
	    $sep,$par{"sec_kwdave"}.$outnum2sym[$itout];
    }
    print $fhout "\n";
    foreach $itres (1..$rdb{"NROWS"}){
	print $fhout $itres,$sep,$rdb{$itres,"AA"};
	print $fhout 
	    $sep,$rdb{$itres,"O".$par{"sec_states"}} if (defined $rdb{1,"O".$par{"sec_states"}});
	print $fhout $sep,$rdb{$itres,"P".$par{"sec_states"}};

	foreach $itout (1..$par{"sec_nstates"}){
	    print $fhout
		$sep,$rdb{$itres,$par{"sec_kwdave"}.$outnum2sym[$itout]};
	}
	print $fhout "\n";
    }
    close($fhout);
}
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
    $par{"sec_kwdave"}=         "Ot";
    $par{"sec_kwdri"}=          "RI_S";
    $par{"sec_states"}=         "HEL";
    $par{"sec_nstates"}=        3;

    $par{"extOutRdb"}=          ".jury_rdb";
    $par{"optJury"}=            "normal";
#    $par{"optJury"}=            "weight"; # compiles a weighted average over jurys
    
    $Ldebug=0;
    $Lverb= 1;
				# ------------------------------
    if ($#ARGV<$scrNarg){	# help
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName $scrIn'\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
	printf "%5s %-15s=%-20s %-s\n","","title",   "x",       "added to column names";
	printf "%5s %-15s=%-20s %-s\n","","sep",     "TAB|SPACE","used to separate columns";

	printf "%5s %-15s %-20s %-s\n","","list",    "no value","list of RDB files (automatically recognised: extension '.list')";
	
	printf "%5s %-15s %-20s %-s\n","","casp",     "no value","expects CASP format ";
	printf "%5s %-15s %-20s %-s\n","","casp1",    "no value","expects CASP format ONE protein ";
	printf "%5s %-15s %-20s %-s\n","","",         "",        "-> output onto screen with RES=";

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
    $fhout="FHOUT";
    $#fileIn=      0;
    $LisList=      0;
    $sep=          "\t";
    $LisCaspFormat=0;
    $LisCaspOne=   0;
#    $LisHELBGT=    0;

    @kwdRdBody=
	("AA","OHEL","PHEL","RI_S",
	 "OHL","PHL","OEL","PEL","OCL","PCL",
	 "OMN","PMN","RI_H",
	 );
    @kwdRdHead=
	("NALIGN","PROT_NALI","PROT_NFAR","PROT_ID"
	 );


				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	next if ($arg =~ /^pack/);
	if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=                  $1;}
	elsif ($arg=~/^de?bu?g$/)             { $par{"debug"}=  $Ldebug=   1;
						$par{"verbose"}=$Lverb=    1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $par{"verbose"}=$Lverb=    1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $par{"verbose"}=$Lverb=    0;
						$par{"debug"}=$Ldebug=     0;}
	
	elsif ($arg=~/^(is)?list$/i)          { $LisList=                  1;}

	elsif ($arg=~/^casp$/)                { $LisCaspFormat=            1;}
	elsif ($arg=~/^casp1$/)               { $LisCaspFormat=            1;
						$LisCaspOne=               1;}

	elsif ($arg=~/^sep=(.*)$/)            { $tmp=                      $1;
						$sep="\t"                  if ($tmp=~/TAB/);
						$sep=" "                   if ($tmp=~/SPACE|\s/); }
#	elsif ($arg=~/^=(.*)$/){ $=$1;}

	elsif ($arg=~/^title=(.*)$/)          { $par{"errPrd_title"}=      $1;}

#	elsif ($arg=~/^htm$/)                 { $modeprd=                  "htm";}
#	elsif ($arg=~/^modepre?d=(.*)$/)      { $modeprd=                  $1;}

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
	    $fileOut="Out-jury.dat";}}


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


				# output state naming
    @outnum2sym=split(//,$par{"sec_states"});
    $par{"sec_nstates"}=$#outnum2sym;

    foreach $sym (@outnum2sym){
	push(@kwdRdBody,$par{"sec_kwdave"}.$sym);
    }

    foreach $kwd (@kwdRdBody){
	$kwdRdBody{$kwd}=1;}

				# ------------------------------
				# (1) sort into ids
				# ------------------------------
    $#id=0;
    undef %fileIn;
    foreach $fileIn (@fileIn){
	$id=$fileIn;
	$id=~s/^.*\///g;	# purge dir
	$id=~s/\..*$//g;	# purge ext
				# new id
	if (! defined $fileIn{$id}){
	    push(@id,$id);
	    $fileIn{$id}=$fileIn;
	}
				# existing
	else {
	    $fileIn{$id}.=",".$fileIn;}
    }
	    
	
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
sub get_ri {
    local($modepredLoc,$bitaccLoc,@vecLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_ri                      compiles the reliability index from FORTRAN output
#       in:                     $modepred:      short description of what the job is about
#       in:                     $bitacc:        accuracy of @vec, i.e. output= integers, 
#       in:                                     out/bitacc = real
#       in:                     @vec:           output vector 
#       out:                    1|0,msg,$ri
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_ri";
				# check arguments
    return(&errSbr("not def modepredLoc!",$SBR6),0)         if (! defined $modepredLoc);
    return(&errSbr("not def bitaccLoc!",$SBR6),0)           if (! defined $bitaccLoc);
    return(&errSbr("bitaccLoc < 1!",$SBR6),0)               if ($bitaccLoc<1);
    return(&errSbr("no vector (vecLoc,$SBR6)!"),0)          if (! defined @vecLoc || $#vecLoc<1);
                                # --------------------------------------------------
                                # distinguish prediction modes
                                # --------------------------------------------------
                                # ------------------------------
                                # sec|htm|acc (2,3 states)
    if    ($modepredLoc eq "sec" || $modepredLoc eq "htm" ||
        ($modepredLoc eq "acc" && $#vecLoc<=3) ){
        return(&errSbr("for mode=$modepredLoc, should be more than ".
		       $#vecLoc." output units",$SBR6),0) 
            if ($#vecLoc<2);
        $max=$max2=0;
        foreach $itout (1..$#vecLoc){
            if    ($vecLoc[$itout]>$max) { 
                $max2=$max;$max=$vecLoc[$itout];}
            elsif ($vecLoc[$itout]>$max2){ 
                $max2=$vecLoc[$itout];}}
                                # define reliability index
        $ri=int( 10 * ($max-$max2)/$bitaccLoc );  $ri=0 if ($ri<0); $ri=9 if ($ri>9);
        return(1,"ok $SBR6",$ri);}
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 

                                # ------------------------------
                                # acc (10 states)
    elsif ($modepredLoc eq "acc" && $#vecLoc>3) {
        return(&errSbr("for mode=acc, wrong number of vectors, should be <10 is=".
		       $#vecLoc." output units",$SBR6),0) 
            if ($#vecLoc>10);
        $max=$pos=$max2=$pos2=0;
        foreach $itout (1..$#vecLoc){ # max
            if ($vecLoc[$itout]>$max) { 
                $max=$vecLoc[$itout]; $pos=$itout;}}
        foreach $itout (1..$#vecLoc){ # 2nd best, at least three units away!
            if ($vecLoc[$itout]>$max2 && ( $itout < ($pos-2) || $itout > ($pos+2) ) ){
                $max2=$vecLoc[$itout]; $pos2=$itout;}}
				# correct if 2nd too close
	$max2=0                 if (&func_absolute($pos2-$pos)<3);
            
#        return(&errSbr("for mode=acc and numout=".$#vecLoc.", the maximal unit was found to be:$pos, ".
#                       "the 2nd:$pos2, this is less than 2 units apart (out=".
#		       join(',',@vecLoc).")",$SBR6),0)
                                # define reliability index
        $ri=int( 30 * ($max-$max2)/$bitaccLoc );  $ri=0 if ($ri<0); $ri=9 if ($ri>9);

        return(1,"ok $SBR6",$ri);}
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 

                                # ------------------------------
    else {                      # unk
        return(&errSbr("combination of modepredLoc=$modepredLoc, numout=".$#vecLoc.", unknown",
                       $SBR6),0);}
        
    return(0,"*** ERROR $SBR6: should have never come her...",0);
}				# end of get_ri

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
	last; }

    undef %rdbloc;
    $#ptr_num2name=$#col2read=0;
				# ------------------------------
				# names
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
    }

    $ctrow=0;
				# ------------------------------
				# read file body
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	$line=$_;
	++$ctrow;
	@tmp=split(/\s+/,$line);
	foreach $it (@col2read){
	    $rdbloc{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	}
    } 
    close($fhinLoc);
				# ------------------------------
				# replace 'C' -> 'L' (convert)
				#    RI -> 10*RI
    foreach $itres (1..$ctrow){
	$rdbloc{$itres,"OHEL"}=~s/C/L/;
	$rdbloc{$itres,"PHEL"}=~s/C/L/;
	if (defined $rdbloc{$itres,"RI_S"}){
	    $rdbloc{$itres,"RI_S"}=int(10*$rdbloc{$itres,"RI_S"});
	}}

    $rdbloc{"NROWS"}=$ctrow;
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
    undef %rdbloc;
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
		    next if (defined $rdbloc{$kwd});
		    if ($_=~/^.*(PARA\S*|VAL\S*)\s*:?\s*$kwd\s*[ :,\;=]+(\S+)/){
			$tmp=$2;
			$kwd2=$kwd; $kwd2=~tr/[A-Z]/[a-z]/; $kwd2=~s/prot_//g;
			$rdbloc{$kwd2}=$tmp;
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
		$rdbloc{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	    }
	}
    }
    close($fhinLoc);
    $rdbloc{"NROWS"}=$ctrow;
    return (1,"ok");
}				# end of rdRdb_here

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
