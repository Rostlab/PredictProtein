#!/usr/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Aug,    	1998	       #
#				version 2.0   	Oct,    	1998	       #
#				version 2.1   	Dec,    	1999	       #
#				version 2.2   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
#                                                                              # 
#                                                                              #
# description:                                                                 #
#    PERL library with routines needed for PROF                                #
#                                                                              #
# to change at some point:
#    'zz dirty hack'
#                                                                              #
#------------------------------------------------------------------------------#

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."subx";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR2))          if (! defined $fileInLoc);
#    return(&errSbr("not def !",$SBR2))          if (! defined $);
    return(1,"ok $SBR2");
}				# end of subx

#===============================================================================
sub subx2 {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx2                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR=""."subx2";
    $fhinLoc="FHIN_"."subx2";$fhoutLoc="FHOUT_"."subx2";
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
}				# end of subx2

#===============================================================================
sub assAbort {
    local($txtInLoc,$lineNumLoc,$msgInLoc) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assAbort                    aborts program
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."assAbort";
    $txtInLoc=""                if (! defined $txtInLoc);
    $lineNumLoc="?"             if (! defined $lineNumLoc);
    $msgInLoc=""                if (! defined $msgInLoc || ! $msgInLoc);

				# clean up temporary files
				#     NOTE: skipped for debug mode
    &assCleanUp($Lverb,1)       if (! $par{"debug"});
    
				# ------------------------------
				# final words
    print $FHERROR "*** ERROR $scrName: line number of error=$lineNumLoc\n";
    print $FHERROR "*** ERROR ",$txtInLoc,"\n" if (defined $txtInLoc);
    print $FHERROR "*** ERROR msg from where it failed:\n",$msgInLoc,"\n"
	if (defined $msgInLoc && length($msgInLoc)>1);
				# ------------------------------
				# close files
    close($FHTRACE2)  if (defined $FHTRACE2 && defined fileno($FHTRACE2) && $FHTRACE2 !~/^STD/);
    close($FHTRACE)   if (defined $FHTRACE  && defined fileno($FHTRACE) && $FHTRACE  !~/^STD/);
    close($FHERROR)   if (defined $FHERROR  && defined fileno($FHERROR) && $FHERROR  !~/^STD/);

    exit;
}				# end of assAbort

#===============================================================================
sub assCleanUp {
    local($LwrtLoc,$LerrLoc)=@_;
    my($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    assCleanUp                 deletes intermediate files
#        in:                    $LwrtLoc:     if 1: write report of activity
#        in:                    $LerrLoc:     if 0: clean up trace and screen file
#        in GLOBAL:             @FILE_REMOVE: all files to be removed
#-------------------------------------------------------------------------------
    $SBR3=""."assCleanUp";      $fhoutLoc="FHOUT_".$SBR3;
    $LwrtLoc=1                  if (! defined $LwrtLoc);

    if ($#FILE_REMOVE>0){	# remove intermediate files
	foreach $file (@FILE_REMOVE){
	    next if (length($file)<1);
	    next if (! -e $file);
	    print $FHTRACE2 
		"--- $SBR3 unlink '",$file,"'\n" if ($LwrtLoc);
	    unlink($file);
	}
    }
				# remove temporary file
    $LerrLoc=1                  if (! defined $LerrLoc);
    if (! $LerrLoc && -e $par{"fileOutTmp"} && ! $par{"debug"}){
	print $FHTRACE2 
	    "--- $SBR3 unlink '",$par{"fileOutTmp"},"'\n";
	unlink($par{"fileOutTmp"});
    }

				# remove TRACE and SCREEN file
    if (! $LerrLoc){
        foreach $kwd ("fileOutTrace","fileOutScreen"){
            next if (! defined $par{$kwd} || ! -e $par{$kwd});
            print $FHTRACE2 
		"--- $SBR3 unlink '",$par{$kwd},"'\n" if ($LwrtLoc);
            unlink($par{$kwd});}
    }
				# report errors
    if ($#FILE_ERROR || $#FILE_IN_PROBLEM){
	open($fhoutLoc,">".$par{"fileOutErrorConv"}) ||
	    do { warn "*** $SBR3 failed opening =".$par{"fileOutErrorConv"}."!";
		 $fhoutLoc="STDOUT"; };
    }
    if ($#FILE_ERROR){
	foreach $file (@FILE_ERROR){
	    print $fhoutLoc $file,"\n";
	}
    }
    if ($#FILE_IN_PROBLEM){
	print $FHTRACE "\n";
	foreach $file (@FILE_IN_PROBLEM){
	    print $fhoutLoc $file,"\n";
	    print $FHTRACE $file,"\n";
	}
    }
    if ($#FILE_ERROR || $#FILE_IN_PROBLEM){
	close($fhoutLoc)        if ($fhoutLoc !~/^STD/ &&
				    defined fileno($fhoutLoc));
	print $FHTRACE2
	    "--- file with errors from conversion=",$par{"fileOutErrorConv"},"\n";
    }
}				# end of assCleanUp

#===============================================================================
sub assFctRunTimeLeft {
    local($timeBeg,$nfileIn,$ctfileIn,$fileIn,$chainIn) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assFctRunTimeLeft           
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."assFctRunTimeLeft";

    return(1,"ok") if ($nfileIn < 1);
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"               if ($ctfileIn < 5);
    $tmp=$fileIn; 
    $tmp.="_".$chainIn          if ($chainIn ne "unk" && $chainIn ne "*");
    if ($par{"debug"}){
	printf $FHTRACE
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	    $tmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;}
    else {
	printf $FHTRACE
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	    $tmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;}
}				# end of assFctRunTimeLeft

#===============================================================================
sub assNumbers2range {
    local(@tmp) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assNumbers2range            converts numbers to ranges, 
#                               e.g. '1 2 4 5 6'
#                               ->    1-2,4-6  returned as ONE string!
#       in:                     @numbers
#       out:                    1|0,msg,$string  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName=""."assNumbers2range";
    $prev=-1;
    $string="";
    return($tmp[1])             if ($#tmp == 1);


    @tmp=sort bynumber (@tmp);
    foreach $tmp (@tmp){
	if    (($prev+1) < $tmp && $prev > 0 && $string =~ /$prev$/){
	    $string.=",".$tmp;}
	elsif (($prev+1) < $tmp && $prev > 0){
	    $string.="-".$prev.",".$tmp;}
	elsif (($prev+1) < $tmp){
	    $string.=",".$tmp;}
	$prev=$tmp              if ($tmp ne $tmp[$#tmp]);
    }
				# last
    $tmp=$tmp[$#tmp];
    if    (($prev+1) < $tmp && $prev > 0 && $string =~ /$prev$/){
	$string.=",".$tmp;}
    elsif (($prev+1) < $tmp && $prev > 0){
	$string.="-".$prev.",".$tmp;}
    elsif (($prev+1) < $tmp){
	$string.=",".$tmp;}
    elsif ($string !~ /$tmp$/){
	$string.="-".$tmp;}

    $string=~s/,,*/,/g;
    $string=~s/^,*|,*$//g;
    return($string);
}				# end of assNumbers2range

#===============================================================================
sub assWrthash {
    my(%tmpLoc,$sbrName9)=@_;
    $sbrName9="assWrthash";
    foreach $kwd (sort(keys %tmpLoc)){
	if (! defined $tmpLoc{$kwd}){
	    print "*** $sbrName9: not def $kwd\n";}
	else {
	    print "--- $sbrName9: kwd=$kwd hash=",$tmpLoc{$kwd},"\n";}
    }
    undef %tmpLoc;
}				# end of assWrthash

#===============================================================================
sub blastpsiMatRead {
    local($fileInLoc) = @_ ;
    local($SBR7,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpsiMatRead             reads the PSI-BLAST matrix file
#       in:                     $fileInLoc
#                               
#       out GLOBAL:             %BLASTMAT with 
#                               $BLASTMAT{"NROWS"}= number of residues
#                               $BLASTMAT{"aa"}=    'ARNDCQEG...' all amino acids read
#                               $BLASTMAT{$itres,"seq"}= sequence read
#                               $BLASTMAT{$itres,$aa}=   profile for amino acid $aa
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR7=""."blastpsiMatRead";
    $fhinLoc="FHIN_"."blastpsiMatRead";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

				# ------------------------------
				# read file
    undef %tmp;
    $errMsg="";
    $ctline=0;
    $#aatmp=0;
    while (<$fhinLoc>) {	# 
	++$ctline;
	$_=~s/\n//g;
				# skip unused stuff
	next if ($_ =~ /^\s*$/     ||
		 $_ =~ /^Last/     ||
		 $_ =~ /^PSI/      ||
		 $_ =~ /^Standard/ ||
		 $_ =~ /^\s*K.*Lam/);
		 
				# line with amino acids used
				# '           A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V'
	if (! $#aatmp && $_=~/^\s+(A .*)$/){
	    $tmp=$1;
	    $tmp=~s/^s*|\s*$//g;
	    @aatmp=split(/\s+/,$tmp);
	    next; }
				# lines with info
				# '    1 G    0 -2  0 -1 -3 -2 -2  6 -2 -4 -4 -2 -3 -3 -2  0 -2 -2 -3 -3 '
	$_=~s/^\s*|\s*$//g;
	($num,$res,@tmp)=split(/\s+/,$_);
				# wrong number of columns found
	if ($#tmp != $#aatmp){
	    $errMsg="lineno=$ctline, naa expect=".$#aatmp.
		", columns read=".$#tmp.": ".join(',',@tmp,"\n");
	    next; }
	$tmp{$num,"seq"}=$res;
	foreach $it (1..$#tmp){
	    $tmp{$num,$aatmp[$it]}=$tmp[$it];
	}
    } close($fhinLoc);
				# ------------------------------
				# ERROR
    return(0,"*** ERROR $sbrName: failed reading BLAST matrix file=$fileInLoc!\n".
	   "   error messages:\n".$errMsg) if (length($errMsg)>2);

				# ------------------------------
				# ok
    $tmp{"NROWS"}=$num;
    $tmp{"aa"}=join('',@aatmp);
    %BLASTMAT=%tmp;
    undef %tmp;
    $#aatmp=0;

    return(1,"ok $sbrName");
}				# end of blastpsiMatRead

#===============================================================================
sub blastpsiMatReadBlosum {
    local($fileInLoc) = @_ ;
    local($SBR7,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpsiMatReadBlosum       reads the PSI-BLAST BLOSUM62 matrix file for no ali
#       in:                     $fileInLoc
#                               
#       out GLOBAL:             %BLASTMAT with 
#                               $BLASTMAT{"NROWS"}= number of residues
#                               $BLASTMAT{"aa"}=    'ARNDCQEG...' all amino acids read
#                               $BLASTMAT{$itres,"seq"}= sequence read
#                               $BLASTMAT{$itres,$aa}=   profile for amino acid $aa
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR7=""."blastpsiMatReadBlosum";
    $fhinLoc="FHIN_"."blastpsiMatReadBlosum";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

				# ------------------------------
				# read file
    undef %tmp;
    $errMsg="";
    $ctline=0;
    $#aatmp=0;
    while (<$fhinLoc>) {	# 
	++$ctline;
	$_=~s/\n//g;
				# skip unused stuff
	next if ($_ =~ /^\#/);
	next if ($_ =~ /^\*/);
		 
				# line with amino acids used
				# '           A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V'
	if (! $#aatmp && $_=~/^\s+(A .*)$/){
	    $tmp=$1;
	    $tmp=~s/^s*|\s*$//g;
	    @aatmp=split(/\s+/,$tmp);
	    next; }
				# lines with info
				# '    1 G    0 -2  0 -1 -3 -2 -2  6 -2 -4 -4 -2 -3 -3 -2  0 -2 -2 -3 -3 '
	$_=~s/^\s*|\s*$//g;
	($res,@tmp)=split(/\s+/,$_);
				# wrong number of columns found
	if ($#tmp != $#aatmp){
	    $errMsg="lineno=$ctline, naa expect=".$#aatmp.
		", columns read=".$#tmp.": ".join(',',@tmp,"\n");
	    next; }
	foreach $it (1..$#tmp){
	    $tmp{$res,$aatmp[$it]}=$tmp[$it];
	}
    } close($fhinLoc);
				# ------------------------------
				# ERROR
    return(0,"*** ERROR $sbrName: failed reading BLAST matrix file=$fileInLoc!\n".
	   "   error messages:\n".$errMsg) if (length($errMsg)>2);

				# ------------------------------
				# ok
    $tmp{"aa"}=join('',@aatmp);
    %BLASTMAT=%tmp;
    undef %tmp;
    $#aatmp=0;

    return(1,"ok $sbrName");
}				# end of blastpsiMatReadBlosum

#===============================================================================
sub blastpsiRdProf {
    local($fileInLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpsiRdProf                       
#       in:                     $fileInLoc:       BLAST HSSP or any other HSSP file
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#       err:                    (2,'msg') -> skip current file!
#-------------------------------------------------------------------------------
    $SBR6=""."blastpsiRdProf";
				# check arguments
    return(&errSbr("not def fileInLoc!",           $SBR6)) if (! defined $fileInLoc);
#    return(&errSbr("not def !",$SBR6))          if (! defined $);

				# file existing?
    return(&errSbr("missing fileInLoc=$fileInLoc!",$SBR6)) if (! -e $fileInLoc && ! -l $fileInLoc);

				# stuff needed there?
    return(&errSbr("missing par{extBlastMat}!",    $SBR6)) if (! defined $par{"extBlastMat"} ||
							       length($par{"extBlastMat"}) < 3);
    return(&errSbr("missing Hash_ARRAYhssp!",      $SBR6)) if (! defined %hssp || ! %hssp);
    return(&errSbr("missing Norm_ARRAYaa!",        $SBR6)) if (! defined @aa   || ! @aa);




				# 1: try same dir as HSSP file
    $fileMat=$fileInLoc;
    if (defined $par{"extHssp"} && length($par{"extHssp"}) > 3){
	$fileMat=~s/$par{"extHssp"}/$par{"extBlastMat"}/;}
    else {
	$fileMat=~s/\.hssp.*$/$par{"extBlastMat"}/;}
				# 2: try '.hssp'
    if (! -e $fileMat){
	$fileMat=$fileInLoc; $fileMat=~s/\.hssp.*$/$par{"extBlastMat"}/;}
				# 3: try directory of blast mat
    if (! -e $fileMat){
	$fileMat2=$fileMat;
	$fileMat2=~s/^.*\///g;
	$par{"dirBlastMat"}.=     "/" 
	    if ($par{"dirBlastMat"} !~ /\/$/ && length($par{"dirBlastMat"})>1);
	$fileMat2=$par{"dirBlastMat"}.$fileMat2;
	return(&errSbr("missing BLAST matrix, neither=$fileMat, nor=$fileMat2!",$SBR6))
	    if (! -e $fileMat2);
	$fileMat=$fileMat2;
    }
				# ------------------------------
				# read PSI-BLAST matrix
				# out GLOBAL: %BLASTMAT with 
				#             $BLASTMAT{"NROWS"}= number of residues                 
				#             $BLASTMAT{"aa"}=    'ARNDCQEG...' all amino acids read 
				#             $BLASTMAT{$itres,"seq"}= sequence read                 
				#             $BLASTMAT{$itres,$aa}=   profile for amino acid $aa    
				#              
    ($Lok,$msg)=
	&blastpsiMatRead
	    ($fileMat
	     );                 return(&errSbrMsg("after call blastPsiMatRead(".$fileMat.")",
						  $msg,$SBR6)) if (! $Lok);

				# ------------------------------
				# check number of residues
#    return(&errSbr("BLASTMAT=".$fileMat.", seems to have ".$BLASTMAT{"NROWS"}." residues, the HSSP".
#		   "file=".$fileInLoc." in contrast has ".$hssp{"numres"}."!",$SBR6))
				# find overlapping residues

    $#noresMat=$cutBeg=$cutEnd=0;
				# BLASTMAT is longer: find begin and end residues to cut out
    if    ($hssp{"numres"} != $BLASTMAT{"NROWS"} && 
	   $hssp{"numres"} <  $BLASTMAT{"NROWS"} ){
	$mat="";$ali="";
	foreach $itres (1..$BLASTMAT{"NROWS"}){
	    $mat.=$BLASTMAT{$itres,"seq"};}
	foreach $itres (1..$hssp{"numres"}){
	    $ali.=$hssp{"seq",$itres};}
	$tmp=$mat;
	$beg="";$end="";
	if ($tmp=~ /^.+$ali/){ $tmp=~s/^(.+)($ali)/$2/;  # begin
			       $beg=$1;}
	if ($tmp=~ /$ali.*$/){ $tmp=~s/^($ali)(.*)$/$1/; # end
			       $end=$2;}
	$cutBeg=length($beg);$cutEnd=length($end);}
				# BLASTMAT is shorter: find begin and end residues to cut out
    elsif ($hssp{"numres"} != $BLASTMAT{"NROWS"} && 
	   $hssp{"numres"}  > $BLASTMAT{"NROWS"} ){
	$mat="";$ali="";
	foreach $itres (1..$BLASTMAT{"NROWS"}){
	    $mat.=$BLASTMAT{$itres,"seq"};}
	foreach $itres (1..$hssp{"numres"}){
	    $ali.=$hssp{"seq",$itres};}
	$tmp=$ali;
	$beg="";$end="";
	if ($tmp=~ /^.+$mat/){ $tmp=~s/^(.+)($mat)/$2/;  # begin
			       $beg=$1;}
	if ($tmp=~ /$mat.*$/){ $tmp=~s/^($mat)(.*)$/$1/; # end
			       $end=$2;}
				# beg br 2000-08: really needed?
#	foreach $it (1..length($beg)){
#	    $nresMat[$it]=1;}
#	foreach $it ((1+$hssp{"numres"}-length($end)) .. $hssp{"numres"}){
#	    $nresMat[$it]=1;}
				# end br 2000-08: really needed?
	$cutBeg=length($beg);$cutEnd=length($end);
    }
    else {
	$cutBeg=0;
	$cutEnd=0;}
				# ------------------------------
				# check sequence
    $errMsg="";$ctchain=0;
    foreach $itres (1..$hssp{"numres"}){
	$itresBlast=$itres+$cutBeg+$ctchain;
	if ($hssp{"seq",$itres}){
	    ++$ctchain;
	    next;}
	$errMsg.="itres=$itres HSSP=".$hssp{"seq",$itres}.
	    ", BLASTMAT=".$BLASTMAT{$itresBlast,"seq"}."!\n"
		if ($BLASTMAT{$itresBlast,"seq"} ne $hssp{"seq",$itres});
    }
				# ******************************
				# ERROR: failed doing it
    if (length($errMsg)>1){
	system ("echo '$fileInLoc' >> ".$par{"fileOutErrorBlast"});
	$msg="*** ERROR $SBR3: FATAL problem BLAST input mat=".
	    $fileMat.", hssp=".$fileInLoc.", ali=$ali\n";
	print $msg;
	return(2,$msg);
    }
				# end failed doing it
				# ******************************

				# ------------------------------
				# replace HSSP profiles by
				#    converted BLAST
    @aablast=split(//,$BLASTMAT{"aa"});
    $ctchain=0;
    foreach $itres (1..$hssp{"numres"}){
	$itresBlast=$itres+$cutBeg+$ctchain;
	print $FHTRACE "dbg itresblast=$itresBlast, itres=$itres, cutBeg=$cutBeg, ctch=$ctchain,\n"
		if ($par{"verbAli"});
	if (! defined $BLASTMAT{$itresBlast,"seq"} ||
	    $hssp{"seq",$itres} ne $BLASTMAT{$itresBlast,"seq"}){
	    ++$ctchain;
	    next;}
	foreach $aa (@aablast){
	    print $FHTRACE "dbg aa=$aa $itres bef=",$hssp{"prof",$aa,$itres},"\n"
		if ($par{"verbAli"});
	    $hssp{"prof",$aa,$itres}=
		int(100 * &func_sigmoidGen($BLASTMAT{$itresBlast,$aa},
					   $par{"blastConvTemperature"}));
	}}

				# clean up
    $#aablast=0;		# slim-is-in
    undef %BLASTMAT;		# slim-is-in

    return(1,"ok $SBR6");
}				# end of blastpsiRdProf

#===============================================================================
sub buildArg {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   buildArg                    builds up the necessary hierarchy for the NNs
#                               
#       in GLOBAL:              $par{"para"}=          number of parameter files
#       in GLOBAL:              $par{"para",$ctpar}=   number of levels for file ctpar
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel}= number of files 
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel,$ctfile}= current file
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel,$ctfile,$kwd}= 
#       in GLOBAL:                  with kwd=
#                  ("modein","modepred","modenet","numin","numhid","numout")
#                               $par{"par",$ctpar,$ctlevel,"modein"}='modein1,modein2,modein3,...'
#                               -> all input modes to use
#                               $par{"par",$ctpar,$ctlevel,"finfin"}= 
#                                  e.g. 'acc=3:1-4,sec=3:5-13,caph=1:n' 
#                               -> predict accessibility with jury over 3rd level files 1-4
#                                  secondary with jury over 3rd level files 5-13
#                                  helix caps for 1st level ..
#                                        
#                               
#       in/out GLOBAL:          @FILE_REMOVE                        
#                               
#                               
#       out GLOBAL:             $run{"npar"}           number of parameter files
#       out GLOBAL:             $run{"nlevel"}         number of maximal levels
#       out GLOBAL:             $run{$ctpar}           number of levels for parameter file $ctpar
#       out GLOBAL:             $run{$ctpar,$ctlevel}  number of architectures for $ctlevel
#                               
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"filein"}
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"fileout"}
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"filejct"}
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"argFor"}
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"modein"}
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"numwin"}
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"origin"}
#                                   $ctpar TAB $ctlevel TAB $ctfile: points
#                                   to another architecture using the same input
#       out GLOBAL:             $run{$ctpar,$ctlevel,$ctfile,"depend"}
#                                   'i1:j1,i2:j2'
#                                   -> depends on j1-th architecture on level i1 
#                                      AND on j2-th architecture on level i2
#                                
#       out GLOBAL:             @depend3rd   e.g. sec=2:1-8,acc=1:1-4,caph=1:13,cape=1:14
#                                            i.e. use the second level files 1-8 (jury over 
#                                            all) for secondary structure asf
#       out GLOBAL:             %depend3rd{$depend}  e.g. 1:3:1,1:3:2,1:3:3,1:3:4
#                                            i.e. the files from run{1,3,1-4} depend on $depend
#       out GLOBAL:             
#       out GLOBAL:             
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR=""."buildArg";
				# check arguments
#    return(&errSbr("not def fileInLoc!",$SBR2))          if (! defined $fileInLoc);
#    return(&errSbr("not def !",$SBR2))          if (! defined $);

				# --------------------------------------------------
				# (1) build up FORTRAN command
				# --------------------------------------------------
				#  1: "switch"
				#  2: number of input units
				#  3: number of hidden units
				#  4: number of output units
				#  5: number of samples
				#  6: bitacc (typically 100)
				#  7: file with input vectors
				#  8: file with junctions
				#  9: file with output of NN ("none" -> no file written
				# 10: optional : dbg
				# 
    $argFor= "switch";
    $argFor.=" numin";
    $argFor.=" numhid";
    $argFor.=" numout";
    $argFor.=" numsam";
    $argFor.=" ".$par{"bitacc"};
    $argFor.=" filein";
    $argFor.=" filejct";
    $argFor.=" none";
    $argFor.=" dbg"             if ($par{"debug"});


				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# xyyx hack
    if (! $netlevelMax){
	$run{"npar"}=  0;
	$run{"nlevel"}=0;
	$#finfin=      0;
	$run{"numwinWanted"}="";
	return(1,"old");}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# --------------------------------------------------
				# (2) now argument for each level (jct)
				# --------------------------------------------------
    $#run=0; undef %run;
    $#depend3rd=0; undef %depend3rd;
    $#finfin=0;

    foreach $itpar (1..$par{"para"}){
				# unclear why the following may happen 
	next if (! defined $par{"para",$itpar});
				# ----------------------------------------
				# loop over all levels 
				# ----------------------------------------
	foreach $itlevel (1..$par{"para",$itpar}){

	    next if (! defined $par{"para",$itpar,$itlevel});

				# ------------------------------
				# for 3rd level: final
	    if ($itlevel > 2){
		return(&errSbr("missing 'finfin' for 3rd level itpar=$itpar!",$SBR))
		    if (! defined $par{"para",$itpar,$itlevel,"finfin"});
		$run{$itpar,$itlevel,"finfin"}=$par{"para",$itpar,$itlevel,"finfin"};
		push(@finfin,split(/,/,$par{"para",$itpar,$itlevel,"finfin"})); 
	    }
		
				# ------------------------------
				# loop over all architectures
				# ------------------------------
	    foreach $itfile (1..$par{"para",$itpar,$itlevel}){
		($Lok,$msg)=
		    &buildArgOne($itpar,$itlevel,$itfile); 
		return(&errSbrMsg("failed to build one: "."&buildArgOne($itpar,$itlevel,$itfile)",
				  $msg,$SBR)) if (! $Lok);
	    }			# end of loop over all current archis
	}			# end of loop over all modes
    }				# end of loop over all parameter files

				# --------------------------------------------------
				# (3) add info about boundaries
				# --------------------------------------------------
    $run{"npar"}=$par{"para"};
    $maxLevel=0;
    foreach $itpar (1..$par{"para"}){
	next if (! defined $par{"para",$itpar});

	next if (! defined $par{"para",$itpar,1});

				# number of levels for current
	$run{$itpar}=$par{"para",$itpar};
	$maxLevel=$run{$itpar}  if ($run{$itpar}>$maxLevel);

				# store number of files
	foreach $itlevel (1..$par{"para",$itpar}){
	    if (! defined $par{"para",$itpar,$itlevel}){
		$run{$itpar,$itlevel}=0;}
	    else {
		$run{$itpar,$itlevel}=$par{"para",$itpar,$itlevel};}
	}}
    $run{"nlevel"}=$maxLevel;

				# --------------------------------------------------
				# (4) which is the final stuff?
				#     work only for levels < 3!
				# --------------------------------------------------
    foreach $itpar (1..$par{"para"}){
				# already taken (is 3rd level)
	next if ($run{$itpar} > 2);
				# not taken, yet: get all files and mode asf
	$level=      $run{$itpar};
	undef %tmp; $#tmp2=0;
				# ------------------------------
				# get all modes
	foreach $itfile (1..$par{"para",$itpar,$level}){
	    $modepredtmp=$par{"para",$itpar,$level,$itfile,"modepred"};
	    $modeouttmp= $par{"para",$itpar,$level,$itfile,"modeout"};
				# 
	    if (! defined $tmp{$modepredtmp."_".$modeouttmp}){
		$tmp{$modepredtmp."_".$modeouttmp}=$itfile;
		push(@tmp2,$modepredtmp."_".$modeouttmp);}
	    else { $tmp{$modepredtmp."_".$modeouttmp}.=",".$itfile;} 
	}
				# ------------------------------
				# process
	foreach $mode (@tmp2){
	    @tmp=sort bynumber (split(/,/,$tmp{$mode}));
	    $prev=-5; $build=""; $beg=0;
	    foreach $tmp (@tmp){
		if ($tmp != ($prev+1)){
		    if    ($beg && $beg < $tmp) { $build.=$beg."-".$tmp.",";}
		    elsif ($beg)                { $build.=$tmp.",";}
		    else                        { $beg=   $tmp; }
		}
		$prev=$tmp;	# reset
	    }
				# final
	    if    ($beg && $beg < $prev){ $build.=$beg."-".$prev; }
	    else                        { $build.=$prev; }
	    $build=~s/,*$//g;	# purge ending

				# separate modes
	    ($modepredtmp,$modeouttmp)=split(/_/,$mode);
	    $modepredtmp=~tr/[A-Z]/[a-z]/; 
	    if ($modeouttmp !~ /cap/){ 
		$tmp=$modepredtmp; }
	    else {		# caps: <s|h><he>cap
		$tmp=$modepredtmp."_".$modeouttmp;
	    }
	    push(@finfin,$tmp."=".$itpar.":".$level.":".$build);
	}
    }

				# ------------------------------
				# 3rd level -> read the finfin values
    return(&errSbr("NOT defined finfin!\n",$SBR)) if ($#finfin<1);
    if ($par{"verb2"}){
	foreach $want (@finfin){
	    print "--- $SBR: wants final $want\n";}}
    return(1,"ok $SBR");
}				# end of buildArg

#===============================================================================
sub buildArgOne {
    local($itpar,$itlevel,$itfile) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   buildArgOne                       
#       in:                     $itpar:   number of parameter file
#       in:                     $itlevel: number of network level (1st,2nd,3rd)
#       in:                     $itfile:  number of architecture file
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."buildArgOne";
				# check arguments
    return(&errSbr("not def itpar!",$SBR2))   if (! defined $itpar);
    return(&errSbr("not def itlevel!",$SBR2)) if (! defined $itlevel);
    return(&errSbr("not def itfile!",$SBR2))  if (! defined $itfile);

    undef %partmp;

				# ------------------------------
				# error check: all keywords there?
    $run{$itpar,$itlevel,$itfile,"winout"}=
	$tmp{"winout"}=
	    $par{"para",$itpar,$itlevel,$itfile,"winout"}=
		$winout=1;
    foreach $kwd ("modein","modepred","modenet","modeout",
		  "numin","numhid","numout"){
	return(&errSbr("missing kwd=$kwd for $itpar-$itlevel-$itfile!\n",$SBR))
	    if (! defined $par{"para",$itpar,$itlevel,$itfile,$kwd});
	$val=$par{"para",$itpar,$itlevel,$itfile,$kwd};
				# hack: extract output window if any
	if ($kwd eq "modein" &&
	    $val=~/winout=(\d+)/){
	    $winout=$1;
	    $val=~s/winout=(\d+)//g;
	    $val=~s/,,/,/g;
	    $run{$itpar,$itlevel,$itfile,"winout"}=
		$tmp{"winout"}=
		    $par{"para",$itpar,$itlevel,$itfile,"winout"}=
			$winout;
	    return(&errSbr("winout=$winout, MUST be 2*N+1!",$SBR))
		if ($winout != int($winout));
	}
	$run{$itpar,$itlevel,$itfile,$kwd}=
	    $tmp{$kwd}=
		$par{"para",$itpar,$itlevel,$itfile,$kwd};
	
    }

    $modein= $tmp{"modein"};
	
				# ------------------------------
				# store unique modes
				#    ONLY for first level!!
    $Lnew=1;
    if    ($itlevel==1 && ! defined $run{$modein}){
	$run{$modein}=$itpar."\t".$itlevel."\t".$itfile;}
				# has already occurred -> use previous
    elsif ($itlevel==1){
				# check whether same input stuff
	@tmp=split(/\t/,$run{$modein});
	$otherpar=  $tmp[1];
	$otherlevel=$tmp[2];
	$otherfile= $tmp[3];
	$Lnew=0;
	print 
	    "--- $SBR2: $itpar:$itlevel:$itfile repeated from:".join(':',@tmp)." ($modein) \n"
		if ($par{"verb2"});
	foreach $kwd ("numin","numhid","numout"){
	    if ($tmp{$kwd} ne $par{"para",$otherpar,$otherlevel,$otherfile,$kwd}){
		$Lnew=1;
		last; }
	}}
				# ------------------------------
				# is new architecture
    if ($Lnew){
				# name fortran input file
	if ($itfile < 10){
	    $itfileTxt="0".$itfile;}
	else {
	    $itfileTxt="0".$itfile;}
	    
	$run{$itpar,$itlevel,$itfile,"filein"}=
	    $fileinfor=
		$par{"dirWork"}.$par{"titleNetIn"}.
		    $itpar.$itlevel.$itfileTxt.$par{"extOutTmp"};
#		    $itpar."-".$itlevel."-".$itfile.$par{"extNetIn"};
				# temporary file: to remove at end!
	push(@FILE_REMOVE,$fileinfor);
    }
				# ------------------------------
				# is same as previous
				#    ONLY for first level!!
    else {			# in fact we can inheritate input file
	$kwd="filein";
	return(&errSbr("kwd=$kwd, other=($otherpar,$otherlevel,$otherfile) ".
		       "not defined run{}!\n",$SBR2))
	    if (! defined $run{$otherpar,$otherlevel,$otherfile,$kwd});
	$run{$itpar,$itlevel,$itfile,"filein"}=
	    $fileinfor=
		$run{$otherpar,$otherlevel,$otherfile,$kwd}; 
				# set pointer to remeber that this one is done already
	$run{$itpar,$itlevel,$itfile,"origin"}=
	    $run{$modein};}
				# ------------------------------
				# junctions 
    return(&errSbr("FILEJCT NOT DEFINED: modein=$modein, directive=$directive, par=$itpar,".
		   "level=$itlevel,file=$itfile,",$SBR2)) 
	if (! defined $par{"para",$itpar,$itlevel,$itfile});
    return(&errSbr("FILEJCT MISSING=".$par{"para",$itpar,$itlevel,$itfile}.
		   ": modein=$modein, ar=$itpar,"."level=$itlevel,file=$itfile,",$SBR2)) 
	if (! -e $par{"para",$itpar,$itlevel,$itfile});
    $filejct=$par{"para",$itpar,$itlevel,$itfile};
				# ------------------------------
				# name output file 
    if ($itfile < 10){
	$itfileTxt="0".$itfile;}
    else {
	$itfileTxt="0".$itfile;}
	    
    $run{$itpar,$itlevel,$itfile,"fileout"}=
	$fileout=
	    $par{"dirWork"}.$par{"titleNetOut"}.
		$itpar.$itlevel.$itfileTxt.
		    $par{"extOutTmp"};
#		$itpar."-".$itlevel."-".$itfile.
#		    $par{"extNetOut"};
				# security erase existing file
    unlink($fileout)            if (-e $fileout);
    push(@FILE_REMOVE,$fileout);

				# ------------------------------
				# finally argument
    $argTmp=$argFor;
    $argTmp=~s/filein/$fileinfor/g;
    $argTmp=~s/filejct/$filejct/g;
    foreach $kwd ("numin","numhid","numout"){
	$argTmp=~s/$kwd/$tmp{$kwd}/; }
		
				# store stuff
    $run{$itpar,$itlevel,$itfile,"argFor"}= $argTmp;
    $run{$itpar,$itlevel,$itfile,"modein"}= $modein;
    $run{$itpar,$itlevel,$itfile,"filejct"}=$filejct;
    foreach $kwd ("numin","numhid","numout"){
	$run{$itpar,$itlevel,$itfile,$kwd}=$tmp{$kwd}; 
    }
    $numwin=$modein;
    $numwin=~s/^.*win=(\d+),.*$/$1/;
    $run{$itpar,$itlevel,$itfile,"numwin"}=$numwin;
    return(&errSbr("strange numwin=$numwin, file($itpar,$itlevel,$itfile)=".
		   $par{"para",$itpar,$itlevel,$itfile},
		   $SBR2))      if ($numwin=~/\D/);
    
				# check parameter for win max: no reason to not set it higher!
    $par{"numwinMax"}=$numwin   if ($numwin > $par{"numwinMax"});
    $run{"numwinWanted"}=""     if (! defined $run{"numwinWanted"});
    $run{"numwinWanted"}.=$numwin."," if ($run{"numwinWanted"} !~ /$numwin,|$numwin$/);
				# hydro scales
    foreach $scale (@hydrophobicityScales){
	next if (defined $hydrophobicityScalesWant{$scale});
	$hydrophobicityScalesWant{$scale}=1;}
    foreach $scale (@hydrophobicityScales){
	next if (defined $hydrophobicityScalesWantSum{$scale});
	if ($modein =~ /(sum|SUM|Sum)$scale/){
	    $hydrophobicityScalesWantSum{$scale}=1;
	}}

				# ------------------------------
				# get dependency
    if ($itlevel >= 2){
	if (defined $par{"para",$itpar,$itlevel,$itfile,"depend"}){
				# given by val=''
	    $run{$itpar,$itlevel,$itfile,"depend"}=
		$par{"para",$itpar,$itlevel,$itfile,"depend"}; 
				# FOR third level:
	    if ($itlevel >= 3){
				# take away sequence part:
#       in:                     $depend:     e.g. seq=1:1,sec=2:1-8,acc=1:1-4,caph=1:13,cape=1:14
#       in:                     $dependFile: e.g. 1:3:1,1:3:2,1:3:3,1:3:4
		$depend=$par{"para",$itpar,$itlevel,$itfile,"depend"}; 
		$depend=~s/seq=[^,]+,//g;
		if (! defined $depend3rd{$depend}){
		    $depend3rd{$depend}=$itpar.":".$itlevel.":".$itfile;
		    push(@depend3rd,$depend);}
		else {
		    $depend3rd{$depend}.=",".$itpar.":".$itlevel.":".$itfile;}}
	}
    }
				# ------------------------------
				# change input mode for third level
    if ($itlevel >= 3){
	$depend=$par{"para",$itpar,$itlevel,$itfile,"depend"};
	return(&errSbr("no depend for itpar=$itpar, itlevel=$itlevel, itfile=$itfile!")) 
	    if (! $depend);
	return(&errSbr("depend no seq=$1! for itpar=$itpar, itlevel=$itlevel, itfile=$itfile!")) 
	    if ($depend !~ /seq=([^,]+)/);
	$depend=$1;
	($itlevelwant,$itfilewant)=split(/:/,$depend);
				# sequence stuff taken from following
	$modein=$run{$itpar,$itlevelwant,$itfilewant,"modein"};
	$modein=~s/win=\d+,*//;
	$modein=~s/,/_/g;
	$run{$itpar,$itlevel,$itfile,"modein"}=~s/(seq=)?all-fst/seq=$modein/;
    }

    return(1,"ok $SBR2");
}				# end of buildArgOne

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#===============================================================================
sub decode_inputUnits1st {
    local($winHalfLoc,$modeinLoc,$numaaLoc) = @_ ;
    my($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   decode_inputUnits1st        figures out meaning of input unit (i), i=1,..,NUMIN
#                               
#       in:                     $winHalfLoc=   window half length (numwin-1)/2
#       in:                     $modeinLoc=input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $numaaLoc= 21
#                               
#       in GLOBAL:              $par{"verbForVec"}
#       in GLOBAL:              @aa21=     residue names (' ' for spacer)
#       in GLOBAL:              @aa=       residue names
#       in GLOBAL:              $aa{aa}=   1 for all 20 known residues
#                               
#       in GLOBAL:              @codeLen   intervals for seq length (<n), + last= >n
#       in GLOBAL:              @codeNali  intervals for number of alis (<n), + last= >n
#       in GLOBAL:              @codeNfar  intervals for number of remote alis (<n), + last= >n
#       in GLOBAL:              @codeDisN  intervals for distance from N-term (<n), + last= >n
#       in GLOBAL:              @codeDisC  intervals for distance from C-term (<n), + last= >n
#                               
#       out GLOBAL              @codeUnitIn1st
#                               
#       out:                    1|0,msg,\@tmp, with $tmp[i]=meaning of input unit i
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."decode_inputUnits1st";

    $#tmp=0;
				# --------------------------------------------------
				# local: sliding window of $winLoc residues
				# --------------------------------------------------
    $ctUnit=0;
    foreach $itwin (1 .. (2*$winHalfLoc + 1)){
	if ($modeinLoc=~/aa/)  {   # residues
	    foreach $itaa(1..($numaaLoc-1)){ 
		++$ctUnit; $tmp[$ctUnit]="aa".$aa21[$itaa].$itwin.":   prof for aa=".$aa21[$itaa];}
	    ++$ctUnit; $tmp[$ctUnit]="aa"."X".$itwin.":   prof for spacer";}
	if ($modeinLoc=~/cw/)  {   # conservation weight
	    ++$ctUnit; $tmp[$ctUnit]="cw".$itwin.":   cons weight";}
	if ($modeinLoc=~/nins/){   # number of insertions
	    ++$ctUnit; $tmp[$ctUnit]="nins".$itwin.": number of insertions";}
	if ($modeinLoc=~/ndel/){   # number of deletions
	    ++$ctUnit; $tmp[$ctUnit]="ndel".$itwin.": number of deletions";}
    }
				# --------------------------------------------------
				# global: no sliding window
				# --------------------------------------------------
    if ($modeinLoc=~/comp/) {      # global AA composition    
	foreach $tmp (@aa){
	    ++$ctUnit; $tmp[$ctUnit]="comp".$tmp.": composition for aa=".$tmp;} }
    if ($modeinLoc=~/len/)  {      # length of protein
	foreach $it (@codeLen){
	    ++$ctUnit; $tmp[$ctUnit]="len".$it. ":  protein length unit <".$it;} }
    if ($modeinLoc=~/nali/) {      # no of homologues	
	foreach $it (@codeNali){
	    ++$ctUnit; $tmp[$ctUnit]="nali".$it. ": number of alignments unit <".$it;} }
    if ($modeinLoc=~/nfar/) {      # no of distant homologues	
	foreach $it (@codeNfar){
	    ++$ctUnit; $tmp[$ctUnit]="nfar".$it. ": number of distant ali unit <".$it;} }
    if ($modeinLoc =~/dis/) {      # distance of window from ends
	foreach $it (@codeDisN){
	    ++$ctUnit; $tmp[$ctUnit]="disN".$it. ": distance of window from N-term unit <".$it;}
	foreach $it (@codeDisC){
	    ++$ctUnit; $tmp[$ctUnit]="disC".$it. ": distance of window from C-term unit <".$it;} }

				# ------------------------------
				# global/semi global
				# ------------------------------
				# hack yy change at some point (hydro IS local!!)
#    $winLoc=int(($par{"numwin"}-1)/2);
    if ($#hydrophobicityScalesWanted){
	foreach $scale (@hydrophobicityScalesWanted){
	    foreach $it (-$winHalfLoc .. $winHalfLoc){
		++$ctUnit;$tmp[$ctUnit]=$scale.": hydrobhobicity for pos=".sprintf("%3d",$it);}}}
				# summed hydrophobicity
    if ($#hydrophobicityScalesWantedSum){
	foreach $scale (@hydrophobicityScalesWantedSum){
	    foreach $it (2,3,4){
		++$ctUnit;$tmp[$ctUnit]="S".$scale.": SUM hydrobhobicity for i,i+".$it;}}}
    if ($modeinLoc=~/salt/) {      # salt bridges
	foreach $it (1..$winHalfLoc){
	    ++$ctUnit;$tmp[$ctUnit]="salt: [DE] for pos i,i+".$it;}
	foreach $it (1..$winHalfLoc){
	    ++$ctUnit;$tmp[$ctUnit]="salt: [KL] for pos i,i+".$it;}}

				# ------------------------------
				# dbg write
				# ------------------------------
    if ($par{"verbForVec"}) {
	print $FHTRACE "dbg $SBR5 meaning of units:\n";
	undef %tmp;
	foreach $it (1..$#tmp) {
	    next if (defined $tmp{$tmp[$it]}); # do not repeat for all window positions!
	    $tmp{$tmp[$it]}=1;
	    printf $FHTRACE "unit %4d : %-s\n",$it,$tmp[$it];}
	undef %tmp;             # slim-is-in!
    }

    @codeUnitIn1st=@tmp;
    $#tmp=0;			# slim-is-in again
    
    return(1,"ok $SBR5");
}				# end of decode_inputUnits1st

#===============================================================================
sub decode_inputUnits2nd {
    local($winHalfLoc,$modeinLoc,@outnum2symLoc) = @_ ;
    my($SBR5,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   decode_inputUnits2nd        figures meaning of in unit (i) for 2nd level, i=1,..,NUMIN
#                               
#       in GLOBAL:              $par{"modein | verbForVec"}
#       in GLOBAL:              @aa=       residue names
#                               
#       in GLOBAL:              @codeLen   intervals for seq length (<n), + last= >n
#       in GLOBAL:              @codeNali  intervals for number of alis (<n), + last= >n
#       in GLOBAL:              @codeNfar  intervals for number of remote alis (<n), + last= >n
#       in GLOBAL:              @codeDisN  intervals for distance from N-term (<n), + last= >n
#       in GLOBAL:              @codeDisC  intervals for distance from C-term (<n), + last= >n
#                               
#       in:                     $winHalfLoc=    half window length (($par{"numwin"}-1)/2)
#       in:                     @outnum2sym symbol for output units (structure units)
#       out:                    1|0,msg,\@tmp, with $tmp[i]=meaning of input unit i
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."decode_inputUnits2nd";

    $#tmp=0;
				# --------------------------------------------------
				# local: sliding window of $winLoc residues
				# --------------------------------------------------
    $ctUnit=0;
    foreach $itwin (1 .. (2*$winHalfLoc + 1)){
	if ($modeinLoc=~/str/)  {  # structure
	    foreach $it (1 .. $#outnum2symLoc){
		++$ctUnit; $tmp[$ctUnit]=
		    "out".$outnum2symLoc[$it].$itwin.":   output for str=".$outnum2symLoc[$it];}
	    ++$ctUnit; $tmp[$ctUnit]="out"."X".$itwin.":   output for spacer";}
	if ($modeinLoc=~/win/)  {  # winner
	    foreach $it (1 .. $#outnum2symLoc){
		++$ctUnit; $tmp[$ctUnit]=
		    "win".$outnum2symLoc[$it].$itwin.":   winner for str=".$outnum2symLoc[$it];}}
	if ($modeinLoc=~/rel/)  {  # reliability index
	    ++$ctUnit; $tmp[$ctUnit]="rel".$itwin.":   relIndex for win=$itwin";}
    }

				# --------------------------------------------------
				# local: repeat sliding window of $winLoc residues
				# --------------------------------------------------
    foreach $itwin (1 .. (2*$winHalfLoc + 1)){
	if ($modeinLoc=~/cw/)  {   # conservation weight
	    ++$ctUnit; $tmp[$ctUnit]="cw".$itwin.":   cons weight for win=$itwin";}
    }

				# --------------------------------------------------
				# global: no sliding window
				# --------------------------------------------------
    if ($modeinLoc=~/comp/) {      # global AA composition    
	foreach $tmp (@aa){
	    ++$ctUnit; $tmp[$ctUnit]="comp".$tmp.": composition for aa=".$tmp;} }
    if ($modeinLoc=~/len/)  {      # length of protein
	foreach $it (@codeLen){
	    ++$ctUnit; $tmp[$ctUnit]="len".$it. ":  protein length unit <".$it;} }
    if ($modeinLoc=~/nali/) {      # no of homologues	
	foreach $it (@codeNali){
	    ++$ctUnit; $tmp[$ctUnit]="nali".$it. ": number of alignments unit <".$it;} }
    if ($modeinLoc=~/nfar/) {      # no of distant homologues	
	foreach $it (@codeNfar){
	    ++$ctUnit; $tmp[$ctUnit]="nfar".$it. ": number of distant ali unit <".$it;} }
    if ($modeinLoc =~/dis/) {      # distance of window from ends
	foreach $it (@codeDisN){
	    ++$ctUnit; $tmp[$ctUnit]="disN".$it. ": distance of window from N-term unit <".$it;}
	foreach $it (@codeDisC){
	    ++$ctUnit; $tmp[$ctUnit]="disC".$it. ": distance of window from C-term unit <".$it;} }

				# ------------------------------
				# dbg write
				# ------------------------------
    if ($par{"verbForVec"}) {
	print $FHTRACE "dbg $SBR5 meaning of units:\n";
	undef %tmp;
	foreach $it (1..$#tmp) {
	    next if (defined $tmp{$tmp[$it]}); # do not repeat for all window positions!
	    $tmp{$tmp[$it]}=1;
	    printf $FHTRACE "unit %4d : %-s\n",$it,$tmp[$it];}
	undef %tmp;             # slim-is-in!
    }
    
    return(1,"ok $SBR5",\@tmp);
}				# end of decode_inputUnits2nd

#===============================================================================
sub decode_inputUnits3rd {
    local($modeinLoc,$numin1stLoc) = @_ ;
    my($SBR5,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   decode_inputUnits3rd        figures meaning of in unit (i) for 3rd level, i=1,..,NUMIN
#                               
#       in:                     $winHalfLoc=    half window length (($par{"numwin"}-1)/2)
#       in:                     @outnum2sym symbol for output units (structure units)
#                               
#       in GLOBAL:              $par{"modein | verbForVec"}
#       in GLOBAL:              @aa=       residue names
#                               
#       in GLOBAL:              @codeLen   intervals for seq length (<n), + last= >n
#       in GLOBAL:              @codeNali  intervals for number of alis (<n), + last= >n
#       in GLOBAL:              @codeNfar  intervals for number of remote alis (<n), + last= >n
#       in GLOBAL:              @codeDisN  intervals for distance from N-term (<n), + last= >n
#       in GLOBAL:              @codeDisC  intervals for distance from C-term (<n), + last= >n
#                               
#       out GLOBAL:             @codeUnitIn3rd, with $codeUnitIn3rd[i]=meaning of input unit i
#                               
#       out:                    1|0,msg,%tmp{<sec|acc|cape|caph>,<nunitPerResidue|window>}=
#                                           number of units per residue for mode (e.g. 7 for sec)
#                                           window for mode
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."decode_inputUnits3rd";

    $#tmp=0;
    $ctunit=0;
    $ctin=  $numin1stLoc;
				# --------------------------------------------------
				# local: sliding window of $winLoc residues
				# --------------------------------------------------
    undef %tmp;
    $out{"modes"}=~s/,$//g;
    @modes=split(/,/,$out{"modes"});
#    foreach $kwd ("sec","acc","htm","caph","cape"){
    foreach $kwd (@modes){
				# kwd=<sec|acc|caph|cape>=N1xN2

				# secondary structure part
	if    ($kwd eq "sec" || $kwd eq "htm"){
	    $tmp=$modeinLoc;
	    $tmp=~s/^.*$kwd=//g;
	    $tmp=~s/[a-z]+=.*$//g;
	    $tmp=~s/,*//g;
	    ($nunitPerResidue,$winTmp)=split(/[x]/,$tmp);
	    return(&errSbr("sec MUST have 7 units, seems to want unit_per_residue=$nunitPerResidue!\n",
			   $SBR5)) if ($nunitPerResidue != 7);
	    $winHalfTmp=($winTmp-1)/2;
	    foreach $itwin (-1*$winHalfTmp .. $winHalfTmp ){
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"outH");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"outE");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"outL");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"binH");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"binE");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"binL");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d SEC%-5d %-s",$ctin,$itwin,"RI_SEC");
	    }}
				# solvent accessibility
	elsif ($kwd eq "acc"){
	    $tmp=$modeinLoc;
	    $tmp=~s/^.*$kwd=//g;
	    $tmp=~s/[a-z]+=.*$//g;
	    $tmp=~s/,*//g;
	    ($nunitPerResidue,$winTmp)=split(/[x]/,$tmp);
	    return(&errSbr("acc MUST have 4 units, seems to want unit_per_residue=$nunitPerResidue!\n",
			   $SBR5)) if ($nunitPerResidue != 4);
	    $winHalfTmp=($winTmp-1)/2;
	    foreach $itwin (-1*$winHalfTmp .. $winHalfTmp ){
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d ACC%-5d %-s",$ctin,$itwin,"RELACC");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d ACC%-5d %-s",$ctin,$itwin,"oute");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d ACC%-5d %-s",$ctin,$itwin,"outb");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d ACC%-5d %-s",$ctin,$itwin,"RI_ACC");
	    }}
				# Hcap
	elsif ($kwd eq "caph"){
	    $tmp=$modeinLoc;
	    $tmp=~s/^.*$kwd=//g;
	    $tmp=~s/[a-z]+=.*$//g;
	    $tmp=~s/,*//g;
	    ($nunitPerResidue,$winTmp)=split(/[x]/,$tmp);
	    return(&errSbr("caph MUST have 3 units, seems to want unit_per_residue=$nunitPerResidue!\n",
			   $SBR5)) if ($nunitPerResidue != 3);
	    $winHalfTmp=($winTmp-1)/2;
	    foreach $itwin (-1*$winHalfTmp .. $winHalfTmp ){
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d CAPH%-5d %-s",$ctin,$itwin,"outHC");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d CAPH%-5d %-s",$ctin,$itwin,"outHN");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d CAPH%-5d %-s",$ctin,$itwin,"RI_CAPH");
	    }}
				# Ecap
	elsif ($kwd eq "cape"){
	    $tmp=$modeinLoc;
	    $tmp=~s/^.*$kwd=//g;
	    $tmp=~s/[a-z]+=.*$//g;
	    ($nunitPerResidue,$winTmp)=split(/[x]/,$tmp);
	    $tmp=~s/,*//g;
	    return(&errSbr("cape MUST have 3 units, seems to want unit_per_residue=$nunitPerResidue!\n",
			   $SBR5)) if ($nunitPerResidue != 3);
	    $winHalfTmp=($winTmp-1)/2;
	    foreach $itwin (-1*$winHalfTmp .. $winHalfTmp ){
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d CAPE%-5d %-s",$ctin,$itwin,"outEC");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d CAPE%-5d %-s",$ctin,$itwin,"outEN");
		++$ctunit; ++$ctin; $tmp[$ctunit]=sprintf("%3d CAPE%-5d %-s",$ctin,$itwin,"RI_CAPE");
	    }}
				# unk
	else {
	    return(&errSbr("came with kwd=$kwd, expect <sec|acc|htm|caph|cape>"));}
	$tmp{$kwd,"nunitPerRes"}=$nunitPerResidue;
	$tmp{$kwd,"window"}=     $winTmp;
    }

    @codeUnitIn3rd=@tmp;
    $#tmp=0;			# slim-is-in again

    return(1,"ok $SBR5",%tmp);
}				# end of decode_inputUnits3rd

#===============================================================================
sub doOne {
    local($ct_fileIn,$fileIn,$chainIn,$formatIn,$modeWrt,$whichPROFloc) = @_ ;
    local($SBR1);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doOne                       runs all networks for one protein
#       in:                     $ct_fileIn=   counting through input files
#       in:                     $fileInLoc=   database file (to read)
#       in:                     $chainIn=     chain id ($par{"symbolChainAny"} if none)
#       in:                     $formatIn=    format of input file
#       in:                     $modeWrtLoc=      mode for job, any of the following (or all)
#                                  dssp           write DSSP format
#                                  msf            write MSF format
#                                  saf            write SAF format
#                                  casp           write CASP2 format
#                               
#                                  header         write header with notation
#                                  notation       
#                                  averages       compile averages (AA,SS)
#                                         
#                                  brief          only secondary structure and reliability
#                                  normal         predictions + rel + subsets
#                                  subset         include SUBset of more reliable predictions
#                                  detail         include ASCII graph
#                                  ali            include alignment 
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#                                         
#       in GLOBAL:              %par, %run
#                                         
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR1=""."doOne";           $fhoutLoc="FHOUT_".$SBR1;
				# ------------------------------
				# check arguments
    return(&errSbr("not def ct_fileIn!",$SBR1))  if (! defined $ct_fileIn);
    return(&errSbr("not def fileIn!",   $SBR1))  if (! defined $fileIn);
    return(&errSbr("not def chainIn!",  $SBR1))  if (! defined $chainIn);
    return(&errSbr("not def formatIn!", $SBR1))  if (! defined $formatIn);
    return(&errSbr("not def modeWrt!",  $SBR1))  if (! defined $modeWrt);
    return(&errSbr("not def whichPROF", $SBR1))  if (! defined $whichPROFloc);
				# existing file?
    return(&errSbr("no fileIn=$fileIn!",$SBR1))  if (! -e $fileIn && $formatIn !~/seq/);
    
    $Ltimexyx=0;
    $Ltimexyx=1                  if ($par{"debug"});
    $Ltimexyx=0;
    $timexyx_doone1=time if ($Ltimexyx);

				# ------------------------------
				# local settings
    if ($par{"debugfor"}){
	$fileOutScreen=0;}
    else {
	$fileOutScreen=$par{"fileOutScreen"};}
    
				# ------------------------------
				# output file
    if (defined $par{"fileOutRdb"} && length($par{"fileOutRdb"}) > 3){
	$fileOutRdb=$par{"fileOutRdb"}; 
    }
    else {
	$fileOutRdb=$fileOut[$ct_fileIn];
				# bugfix br 2003-08-09: id_prof.prof -> id_prof.rdbProf not -> id.rdbProf!
#bug	$fileOutRdb=~s/$par{"extProfOut"}.*$/$par{"extProfRdb"}/;
	$fileOutRdb=~s/^([^\.]+.*)$par{"extProfOut"}.*$/$1$par{"extProfRdb"}/;
    }
	
    $fileOutNot=$fileOutRdb;
    $fileOutNot=~s/$par{"extProfRdb"}/$par{"extNotHtm"}/;
    $fileOut{$ct_fileIn,"rdb"}=$fileOutRdb;
    $fileOut{$ct_fileIn,"not"}=$fileOutNot;

				# **************************************************
				# <--- <--- <--- <--- <--- <--- 
				# to skip since existing already?
    return(1,"skipped since existing fileout=$fileOutRdb")
	if (-e $fileOutRdb && $par{"doSkipExisting"});
				# <--- <--- <--- <--- <--- <--- 
				# **************************************************

				# ------------------------------
				# local parameters (used for &wrtRdbHead)
    $numwhite= $par{"rdbWhite"};
    $numhyphen=$par{"rdbHyphen"};
    $sep=      $par{"rdbSep"};
				# --------------------------------------------------
				# (0)  clean up old files
    if ($#FILE_REMOVE_TMP>0 && ! $par{"debug"}){
	foreach $file (@FILE_REMOVE_TMP){
	    unlink($file);}}
    print $FHTRACE "5.."        if ($par{"verbose"} && ! $par{"debug"});

				# --------------------------------------------------
				# (1a) run conversion, filter, asf
				#      GLOBAL in:  $par{}
				#      GLOBAL out: $par{}
				#      GLOBAL out: $prot{}
				#      GLOBAL out: $protacc{} (for acc)
				#      fileTaken:  alignment file used
				#      paraTaken:  parameters for filter used
    ($Lok,$msg,$fileTaken,$paraTaken)=
	&protRd($fileIn,$chainIn,$formatIn,$whichPROFloc
		);              return(&errSbrMsg("reading db=$fileIn, chain=$chainIn! (&protRd)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
    if ($Lok==2){
	push(@FILE_IN_PROBLEM,$fileIn."_".$msg);
	return(2,$msg);
    }

				# --------------------------------------------------
				# (1b) postprocess protein data (speed up &nnWrt!)
				#      GLOBAL out: %prot and %protacc
    ($Lok,$msg)=
	&prot2nn
	    ($whichPROFloc,$par{"numaa"},$fileIn
	     );                 return(&errSbrMsg("after call prot2nn($whichPROFloc)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);

				# --------------------------------------------------
				# (2)  build up FORTRAN input for 1st level
				#      GLOBAL in:  $par{},$prot{},$protacc{},$run{}
    $#breaks=0;			#      set chain breaks

    if ($run{"nlevel"} > 0){	# yy hack

	$itlevel=$itpar=$itfile[1]=1;
	print $FHTRACE "4.."        if ($par{"verbose"} && ! $par{"debug"});
	$timexyx_nnwrt1=time  if ($Ltimexyx);
	($Lok,$msg)=
	    &nnWrt(1);          return(&errSbrMsg("dbfile=$fileIn, chain=$chainIn! (&nnWrt)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
	$timexyx_nnwrt1=time-$timexyx_nnwrt1  if ($Ltimexyx);
				# --------------------------------------------------
				# (3)  run first level
				#      GLOBAL in:  $par{},$prot{},$protacc{},$run{}
	$timexyx_nnforrun1=time  if ($Ltimexyx);
	($Lok,$msg)=
	    &nnForRun(1);           return(&errSbrMsg("1st db=$fileIn, chain=$chainIn! (&nnForRun(1))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
				# (3b) filter for HELBGT asf
				#      WATCH it: changes FORTRAN output file!!!
	if ($run{"nlevel"}<2){	#  zz dirty hack
	    ($Lok,$msg)=
		&interpretCompress
		    (1);        return(&errSbrMsg("1st db=$fileIn, chain=$chainIn! (&interpretCompress(1))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
	}
	$timexyx_nnforrun1=time-$timexyx_nnforrun1  if ($Ltimexyx);
    }				# yy end of hack

				# --------------------------------------------------
				# (4)  do all 2nd levels
    if ($run{"nlevel"}>1){
	print $FHTRACE "3.."    if ($par{"verbose"} && ! $par{"debug"});
	$level=2;
				# (4a) build up FORTRAN input
	$timexyx_nnwrt2=time  if ($Ltimexyx);
	($Lok,$msg)=
	    &nnWrt($level);     return(&errSbrMsg("dbfile=$fileIn, chain=$chainIn! (&nnWrt)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
	$timexyx_nnwrt2=time-$timexyx_nnwrt2  if ($Ltimexyx);
				# (4b) run for higher levels
	$timexyx_nnforrun2=time  if ($Ltimexyx);
	($Lok,$msg)=
	    &nnForRun($level);  return(&errSbrMsg("2nd db=$fileIn, chain=$chainIn! (&nnForRun(2))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
				# (4c) filter for HELBGT asf
				#      WATCH it: changes FORTRAN output file!!!
	($Lok,$msg)=
	    &interpretCompress
		($level);       return(&errSbrMsg("2nd db=$fileIn, chain=$chainIn! (&interpretCompress(2))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
	$timexyx_nnforrun2=time-$timexyx_nnforrun2 if ($Ltimexyx);
    }				# end of second level


				# --------------------------------------------------
				# (5)  do all 3rd levels
    if ($run{"nlevel"}>2){
	print $FHTRACE "2.."    if ($par{"verbose"} && ! $par{"debug"});
	$level=3;
				# (5a) loop over all dependencies:
				#      currently this means 'acc+sec' and 'htm'
	$timexyx_nn3rd=time if ($Ltimexyx);
	foreach $depend (@depend3rd){
	    $timexyx_nn3rdx=time if ($Ltimexyx);
	    ($Lok,$msg)=
		&nn3rd($depend,$depend3rd{$depend}
		       );       return(&errSbrMsg("file=$fileIn, chain=$chainIn! (&nn3rd($depend))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
	    $timexyx_nn3rdx=time-$timexyx_nn3rdx  if ($Ltimexyx);
	}
	$timexyx_nn3rd=time-$timexyx_nn3rd if ($Ltimexyx);
				# (5b) run for higher level
	$timexyx_nnrun3=time if ($Ltimexyx);
	($Lok,$msg)=
	    &nnForRun($level);  return(&errSbrMsg("3rd db=$fileIn, chain=$chainIn! (&nnForRun(3))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
				# (5c) filter for HELBGT asf
				#      WATCH it: changes FORTRAN output file!!!
	($Lok,$msg)=
	    &interpretCompress
		($level);       return(&errSbrMsg("3rd db=$fileIn, chain=$chainIn! (&interpretCompress(3))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
	$timexyx_nnrun3=time-$timexyx_nnrun3 if ($Ltimexyx);
    }				# end of third level

				# --------------------------------------------------
				# (6) interpret modes, initialise for RDB
				#     out GLOBAL: %rdb, $modepredFin

				#      
    undef %rdb;			#      <<<--- this contains THE data from first call
				#             to &interpret1() onwards!


				# yy hack
    $was3=0;			# yy hack
    $was3=1                     if ($whichPROFloc eq "3"); # yy hack
    $#kwdPrd=$#kwdObs=$#kwdRdb=0;
    ($Lok,$msg,$whichPROFloc2)=
	&wrtRdbHeadIni($fileIn,$fileTaken,$paraTaken,$whichPROFloc
		       );       return(&errSbrMsg("failed wrtRdbHeadIni (ct=$ct_fileIn,file=$fileIn)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
    $whichPROFloc2=3            if ($was3); # yy hack
    $Lphd_finished=0;

				# --------------------------------------------------
				# (7)  collect output, and jury
				# --------------------------------------------------

    foreach $fin (@finfin){
				# ------------------------------
				# (7a) digest: fin: <acc|sec|sec_[HE]cap>=itpar:itlevel:itfile1-itfile2
	($mode,$tmp)=           split(/=/,$fin);
				# now account for jury 2 and 3:
				#      'sec=1:2:1-4_3:1-8'
	@mix=                   split(/_/,$tmp);
	$#filetmp=  0;
	$#winouttmp=0;
	foreach $one_level (@mix){
	    if    ($one_level =~ /^(\d+):(\d+):(.*)$/){
		$itpar=  $1;
		$itlevel=$2;
		$tmp2=   $3; }
	    elsif ($one_level =~ /^(\d+):(.*)$/){
		$itlevel=$1;
		$tmp2=   $2; }
	    else {
		return(&errSbr("failed fin=$fin, one_level=$one_level, finfin=".
			       join(',',@finfin,"\n").
			       "\n"."line=".__LINE__."\n",$SBR1)); }
	    $tmp2=~s/,*$//g;
	    @tmp=               split(/,/,$tmp2);
	    $#itfile=0;
	    foreach $tmp (@tmp){
		next if (length($tmp)<1 || $tmp !~ /\d/);
		if ($tmp !~ /\-/){
		    push(@itfile,$tmp);}
		else {
		    ($beg,$end)=    split(/\-/,$tmp);
		    foreach $it ($beg .. $end){
			push(@itfile,$it);
		    }}}
	    @itfile = sort bynumber (@itfile);
	    $#tmp=0;
				# ------------------------------
				# (7b) get all files for jury
	    foreach $itfile (@itfile){
		$run{"ri_ave",$itfile}=$par{"para",$itpar,$itlevel,$itfile,"ri_ave"};
		$run{"ri_sig",$itfile}=$par{"para",$itpar,$itlevel,$itfile,"ri_sig"};
		push(@filetmp,  $run{$itpar,$itlevel,$itfile,"fileout"}); 
		push(@winouttmp,$run{$itpar,$itlevel,$itfile,"winout"}); 
	    }
	}

				# ------------------------------
				# (7c) add PHD to jury?
				#      run only once in all necessary modes (3|both|.)
	if ($par{"optJury"}=~/phd/i && ! $Lphd_finished){
	    $Lphd_finished=1;
	    ($Lok,$msg,$LisHtm,$fileOldRdb)=
		&assHack1994
		    ($fileTaken,$chainIn,whichPROFloc
		     );         return(&errSbrMsg("assHack1994 failed",$msg,$SBR1)) if (! $Lok);
	    push(@FILE_REMOVE_TMP,$fileOldRdb)
		if (! $par{"doRetPhd1994"});
				# changing mode if no HTM found
	    $whichPROFloc2="both" 
		if ($whichPROF =~/^3/ && ! $LisHtm);
#	    push(@filetmp,$fileOldRdb);
	}
	    

				# ------------------------------
				# (7d) call jury
	undef %prd; undef %obs;
	$winouttmpJoin=join(',',@winouttmp);
	if ($par{"optJury"} !~/weight/){
				# global in: $par{"optJury"} and $rdb{"phd"}
	    ($Lok,$msg)=
		&nnJury
		    ($mode,$winouttmpJoin,@filetmp
		     );         return(&errSbrMsg("jury FINAL db=$fileIn, chain=$chainIn! fin=$fin ".
						  "(&nnJury($mode, winout=$winouttmpJoin, file=".
						  join(',',@filetmp)."))"."\n"."line=".__LINE__."\n",
						  $msg,$SBR1)) if (! $Lok);}
	else {
				# global in: $par{"optJury"} and $rdb{"phd"}
	    ($Lok,$msg)=
		&nnJuryWeight
		    ($mode,$winouttmpJoin,@filetmp
		     );         return(&errSbrMsg("jury FINAL db=$fileIn, chain=$chainIn! fin=$fin ".
						  "(&nnJuryWeight($mode".join(',',@filetmp)."))".
						  "\n"."line=".__LINE__."\n",
						  $msg,$SBR1)) if (! $Lok);}

				# ------------------------------
				# (7f) process special modes
				#      note: for 'modeout' 
	if (defined $run{"special"} && length($run{"special"})>1){
	    @modeoutSpecial=split(/,/,$run{"special"});
	    foreach $modeoutSpecial (@modeoutSpecial){
		$run{$modeoutSpecial,"files"}=~s/^,*|,*$//g;
		@filetmp=split(/,/,$run{$modeoutSpecial,"files"});
		($Lok,$msg)=
		    &nnJurySpecial
			("sec".$modeoutSpecial,$modeoutSpecial,@filetmp
			 );     return(&errSbrMsg("jury special=$modeoutSpecial db=$fileIn, chain=$chainIn! ".
						  "(&nnJury(sec$modeoutSpecial,file=".
						  join(',',@filetmp)."))"."\n"."line=".__LINE__."\n",
						  $msg,$SBR1)) if (! $Lok);
				# final interpretation
		($Lok,$msg)=
		    &interpretCompressFin
			($modeoutSpecial,$L3D_KNOWN
			 );     return(&errSbrMsg("3rd db=$fileIn, chain=$chainIn! (&interpretCompress(3))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
		
	    }
	}

				# ------------------------------
				# (7e) process PROF
				# yyyy to be done!!
	if ($par{"para",$itpar,$itlevel,$itfile[1],"modepred"} eq "htm" &&
	    ! $Lphd_finished){
				#      do change whichPROF here ...
				#      out GLOBAL: $fileOutNotHtm
	    ($Lok,$msg,@tmp)=
		&htmProcess
		    ($fileIn,$chainIn,
		     $ct_fileIn,$numwhite,$L3D_KNOWN
		     );         return(&errSbrMsg("HTM problem db=$fileIn, chn=$chainIn, ".
						  "(&htmProcess($ct_fileIn,$numwhite,$L3D_KNOWN))".
						  "\n"."line=".__LINE__."\n",$msg,
						  $SBR1)) if (! $Lok);
	    $Lhtm_finished=1;
	}
	elsif (! $Lphd_finished){
	    $Lhtm_finished=0;}
	    

				# ------------------------------
				# (7g) write one mode
				#      <<<<<<<<<<<<<<<<<<<<<<<<< 
				#      
				#      THIS module contains most
				#      prediction specific parts!
				#      
				#      ALSO: filter prediction
				#      
				#      >>>>>>>>>>>>>>>>>>>>>>>>>
	($Lok,$msg,@tmp)=
	    &interpret1($par{"para",$itpar,$itlevel,$itfile[1],"modepred"},
			$par{"para",$itpar,$itlevel,$itfile[1],"modeout"},
			$par{"para",$itpar,$itlevel,$itfile[1],"winout"},
			$L3D_KNOWN,$whichPROFloc2
			);      return(&errSbrMsg("after interpret1 db=$fileIn,chn=$chainIn, fin=$fin,".
						  "itpar=$itpar, itlevel=$itlevel!\n".
						  "line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);

    }				# loop over all FINAL to be collected for one mode
				# --------------------------------------------------

				# yyyy currently HACK
    $tmpkwd=join(",",@kwdRdb);
    if ($whichPROFloc2 =~ /^(htm|3)$/ &&
	! $Lhtm_finished && ! $Lphd_finished){
	($Lok,$msg,$LisHtm,$fileOldRdb)=
	    &assHack1994
		($fileTaken,$chainIn
		 );             return(&errSbrMsg("assHack1994 failed",$msg,$SBR1)) if (! $Lok);
	$whichPROFloc2="both"   if (! $LisHtm && $whichPROFloc !~ /htm/);
	push(@FILE_REMOVE_TMP,$fileOldRdb)
	    if (! $par{"doRetPhd1994"});
	if   ($whichPROFloc2 eq "htm"){
	    $#tmp=0;
	    foreach $kwd (@{$kwdGlob{"gen"}}){
		push(@tmp,$kwd) if ($tmpkwd!~/$kwd/);
	    }
	    @kwdRdb=(@tmp,@kwdRdb);
	    if (! defined $rdb{"NROWS"} ||  ! $rdb{"NROWS"}){
		if    (defined $rdb{"NROWS_HTM"}){
		    $rdb{"NROWS"}=$rdb{"NROWS_HTM"};}
		elsif (defined $rdb{"prot_nres"}){
		    $rdb{"NROWS"}=$rdb{"NROWS_HTM"}=$rdb{"prot_nres"};}
		else {
		    print "-*- strong warning Nres not defined $SBR1\n";
		}}
		    
	    foreach $itres (1..$rdb{"NROWS"}){
		$rdb{$itres,"AA"}=$rdb{$itres,"AAhtm"};
		$rdb{$itres,"No"}=$itres;
	    }
	}
    }
    elsif ($whichPROFloc2 eq "3"){
	foreach $kwd (@{$kwdGlob{"want"}->{"htm"}}){
	    push(@kwdRdb,$kwd)  if ($tmpkwd!~/$kwd/);
	}
    }

				# ----------------------------------------
				# (7h) prediction for too short regions
				#      IN/OUT GLOBAL %rdb
				# ----------------------------------------
    ($Lok,$msg)=
	&pred4short();          return(&errSbrMsg("after call pred4short",$msg)) if (! $Lok);

    print $FHTRACE "1 "         if ($par{"verbose"} && ! $par{"debug"});

				# ------------------------------
				# (8)  write RDB results file
				#      write new RDB HEADER
    open($fhoutLoc,">".$fileOutRdb) || 
	return(&errSbr("fileOut($ct_fileIn)=$fileOutRdb, not created".
		       "\n"."line=".__LINE__."\n",$SBR1));

				# correct kwdRdb array
    ($Lok,$msg)=
	&wrtRdbBefore();        return(&errSbrMsg("failed wrtRdbBefore (ct=$ct_fileIn,file=$fileIn)".
						  "\n"."line=".__LINE__."\n",
						  $msg,$SBR1)) if (! $Lok);
    ($Lok,$msg)=
	&wrtRdbHead($fhoutLoc,$fileIn,$fileTaken,$paraTaken,$whichPROFloc2,
		    $numwhite,$numhyphen,$L3D_KNOWN
		    );          return(&errSbrMsg("failed  RDB header (ct=$ct_fileIn,file=$fileIn)".
						  "\n"."line=".__LINE__."\n",
						  $msg,$SBR1)) if (! $Lok);
				#      write RDB body
    ($Lok,$msg)=
	&wrtRdbBody($fhoutLoc,$numhyphen,$sep
		       );       return(&errSbrMsg("failed  RDB body (ct=$ct_fileIn,file=$fileIn)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok);
    close($fhoutLoc);		# end of RDB writing for one protein

				# ------------------------------
				# (9)  rudimentary error for one
				#      protein: NOTE works only for ONE mode!!
				# out GLOBAL: %error
    if ($L3D_KNOWN && $par{"doEval"}){
	$mode{"acc2Thresh"}= $acc2ThreshLoc[1] if (defined $acc2ThreshLoc[1]);
	$mode{"acc3Thresh1"}=$acc3ThreshLoc[1] if (defined $acc3ThreshLoc[1]);
	$mode{"acc3Thresh2"}=$acc3ThreshLoc[2] if (defined $acc3ThreshLoc[2]);
	print "\n";
	($Lok,$msg)=
	    &errPrdOneProt($ct_fileIn,$whichPROFloc2,\%mode,@outnum2sym
			   );   return(&errSbrMsg("failed on protein specific error: whichPROF=".
						  $whichPROFloc2,$msg,$SBR1)) if (! $Lok); }

				# ------------------------------
				# (10) write special formats
    if ($par{"doRetAscii"} ||	#      human readable  (.prof)
	$par{"doRetMsf"}   ||	#      alignment + PROF (.msfProf)
	$par{"doRetSaf"}   || 	#      alignment + PROF (.safProf)
	$par{"doRetCasp"}       #      CASP format     (.caspProf)
	){ 

				# build up GLOBAL argument %rdb
	$rdb{"numres"}=$rdb{"prot_nres"};
	$rdb{"numali"}=$rdb{"prot_nali"};
	foreach $kwd (keys %prot){
	    next if (defined $rdb{$kwd});
	    next if (! defined $prot{$kwd} || length($prot{$kwd})<1);
	    $rdb{$kwd}=$prot{$kwd};}
				# pair
	foreach $itali (1..$rdb{"numali"}){
	    $rdb{"pide",$itali}=100*$rdb{"IDE",$itali} if (defined $rdb{"IDE",$itali});
	    $rdb{"lali",$itali}=$rdb{"LALI",$itali}    if (defined $rdb{"LALI",$itali});}
				# alignment
	if ($rdb{"numali"}<2){
	    $rdb{"id",1}=$prot{"ID"}||$prot{"ID",1};
	    foreach $itres (1..$rdb{"numres"}){
		$rdb{$rdb{"id",1},$itres}=$prot{"seq",$itres};
	    }}
	else {
	    foreach $itali (1..$rdb{"numali"}){
		$rdb{"id",$itali}=$prot{"ID",$itali};
		foreach $itres (1..$rdb{"numres"}){
		    $rdb{$rdb{"id",$itali},$itres}=$prot{"ali",$itali,$itres};
		}}}
				# output file
	$fileOutMis=$fileOutRdb;
	$fileOutMis=~s/$par{"extProfRdb"}(.*)$/.misProf/;
	$fileOutMis.=$1         if (defined $1 && length($1)>=1);

				# call routine from lib-profwrt.pm
				#     GLOBAL in: %rdb
	($Lok,$msg)=
	    &convProf
		(0,0,$fileOutMis,$modeWrt,$par{"nresPerRow"},
		 $par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSec"},$par{"riSubSym"},
		 $par{"optOutTxtPreRow"},$par{"debug"}
		 );             return(&errSbrMsg("failed writing RDB body (ct=$ct_fileIn,file=$fileIn)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok); 
				# get file names right
	foreach $kwd ("Casp","Dssp","Prof"){

	    if ($par{"doRet".$kwd}           && 
		defined $par{"fileOut".$kwd} && 
		length($par{"fileOut".$kwd})>3){
		if (defined $par{"extProf".$kwd}){
		    $ext=$par{"extProf".$kwd};}
		else{
		    $tmp=$kwd;$tmp=~tr/[A-Z]/[a-z]/;
		    $ext=".".$tmp."Prof";}
		$fileOutNow=$fileOutMis;
		$fileOutNow=~s/\..*$/$ext/;
#		next if (! defined $fileOutNow);
		$fileOutWant=$par{"fileOut".$kwd};
		$cmd="\\mv ".$fileOutNow." ".$fileOutWant;
		($Lok,$msg)=	
		    &sysRunProg
			($cmd,$fileOutScreen,$FHPROG
			 );	print "-*- WARN $SBR1: failed system '$cmd'\n" if (! $Lok);
	    }}
    }

				# ------------------------------
				# (11) write HTML output
    if ($par{"doRetHtml"}){
	if (! defined $par{"fileOutHtml"} || !  $par{"fileOutHtml"}){
	    $fileOutHtml= $fileOut[$ct_fileIn];
	    $fileOutHtml=~s/$par{"extProfOut"}.*$/$par{"extProfHtml"}/;}
	else {
	    $fileOutHtml=$par{"fileOutHtml"};}
	$fileOut{$ct_fileIn,"html"}=$fileOutHtml;
	($Lok,$msg)=
	    &convProf2html(0,0,$fileOutHtml,$par{"optModeRetHtml"},$par{"nresPerRowHtml"},
			  $par{"riSubSec"},$par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSym"}
			  );    return(&errSbrMsg("failed writing HTML (ct=$ct_fileIn,file=$fileIn)".
						  "\n"."line=".__LINE__."\n",$msg,$SBR1)) if (! $Lok); 
    }
    print $FHTRACE "done!\n"    if ($par{"verbose"} && ! $par{"debug"});


				# --------------------------------------------------
				# (12)  clean up old files
    if ($#FILE_REMOVE_TMP>0 && ! $par{"debug"}){
	foreach $file (@FILE_REMOVE_TMP){
	    unlink($file);}}
    
				# temporary: time 
    if ($Ltimexyx){
	$timexyx_doone1=time-$timexyx_doone1;
	print 
	    "xyx times:\n",
	    "doone=       $timexyx_doone1\n",
	    "nnwrt1=      $timexyx_nnwrt1\n",
	    "nnforrun1=   $timexyx_nnforrun1\n",
	    "  nnwrt2=    $timexyx_nnwrt2\n",
	    "  nnforrun2= $timexyx_nnforrun2\n";
	if ($maxLevel > 2){
	    print 
		"    nn3rd=   $timexyx_nn3rd\n",
		"    nnrun3=  $timexyx_nnrun3\n",
		"\n";}}
    
    return(1,"ok $SBR1",$whichPROFloc2,$L3D_KNOWN,\%mode);
}				# end of doOne

#===============================================================================
sub assHack1994 {
    local($fileTakenLoc,$chainInLoc,$whichPROFloc)=@_;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assHack1994                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."assHack1994";
    $fhinyy="FHIN_yy".$SBR2;

				# ------------------------------
				# local settings
    if ($par{"debugfor"}){
	$fileOutScreen=0;}
    else {
	$fileOutScreen=$par{"fileOutScreen"};}
    
				# ------------------------------
				# build up argument for old
    $titleTmp=$par{"titleTmp"};
    $titleTmp=~s/[^a-zA-Z0-9]*$//g;

    $optNiceLoc="";
    if ($par{"optNice"} =~ /(\d+)/){
	$tmp=$1;
	if (defined $par{"exeSysNice"} && 
	    $par{"exeSysNice"}         &&
	    (-e $par{"exeSysNice"} || -l $par{"exeSysNice"})){
	    $optNiceLoc=$par{"exeSysNice"};}
	else {
	    $optNiceLoc="nice";}
	$optNiceLoc.=" -".$tmp;}
    $cmd=$optNiceLoc." ".$par{"exePhd1994"}." ".$fileTakenLoc;

    $cmd.="_".$chainInLoc       if ($chainInLoc =~ /[0-9A-Z]/);
				# no jury, no nothing but HTM
    if    ($par{"optJury"} !~/phd/i && ! $par{"doRetPhd1994"}){
	$cmd.=" htm"; }
				# else use current mode for PHD, too
    elsif ($par{"optProf"} !~ /3/) {
	$cmd.=" ".$par{"optProf"};}

    $fileOldRdb=$titleTmp.".rdbPhdEMBL";
    $fileOldPhd=$titleTmp.".phdEMBL";
    $fileOldNot=$titleTmp.".notHtm";
    $fileOldNot=$par{"fileOutNotHtm"} if (defined $par{"fileOutNotHtm"} &&
					  length($par{"fileOutNotHtm"}) > 3);
    $cmd.=" exePhd=".           $par{"exePhd1994For"};
				# br 2003-08-28: add all kinds of stuff
    $cmd.=" exeHsspFilter=".    $par{"exeFilterHsspFor"};
    $cmd.=" exeHsspFilterPl=".  $par{"exeFilterHssp"};
    $cmd.=" exeHsspFilterPack=".$par{"exeFilterHsspPack"};

    $cmd.=" exeConvertSeq=".    $par{"exeConvertSeqFor"};
    $cmd.=" exeCopf=".          $par{"exeCopf"};
    $cmd.=" exeCopfPack=".      $par{"exeCopfPack"};
    $cmd.=" exeConvHssp2saf=".  $par{"exeConvHssp2saf"};

#    $cmd.=" =".$par{""};
#    $cmd.=" =".$par{""};

#    $cmd.=" dirMaxMat=".$par{""};
#    $cmd.=" =".$par{""};
				# add directory directives
    $cmd.=" ARCH=".$ARCH;

    if (defined $par{"dirWork"}     && 
	$par{"dirWork"}             &&
	length($par{"dirWork"})>=1  &&
	$par{"dirWork"} !~/^unk$/i  &&
	-d $par{"dirWork"}){
	$tmpDirWork=$par{"dirWork"};
	$tmpDirWork.="/"        if ($tmpDirWork !~/\/$/);
	$fileOldPhd=$tmpDirWork.$fileOldPhd;
	$fileOldRdb=$tmpDirWork.$fileOldRdb;
	$fileOldNot=$tmpDirWork.$fileOldNot;
	$cmd.=" dirWork=".   $par{"dirWork"};
    }
				# output file names
    $cmd.=" filePhd=".   $fileOldPhd;
    $cmd.=" fileRdb=".   $fileOldRdb;
    $cmd.=" fileNotHtm=".$fileOldNot;


    ($Lok,$msg)=	
	&sysRunProg
	    ($cmd,$fileOutScreen,$FHPROG
	     );		        return(&errSbrMsg("failed to run PHD1994:".$par{"exePhd1994"}." cmd=\n".
						  $cmd,$msg,$SBR2)) if (! $Lok); # 

				# output file existing??
    return(&errSbr   ("SYSTEM call:\n".$cmd."\n"."failed producing output file=".$fileOldRdb,
		      $SBR2)) if (! -e $fileOldRdb);
    unlink($fileOldPhd);	# delete the ASCII file right away!


    # ################################################################################

				# yy: watch it in the future you better right it out
				#     even if it is NOT htm!!!

    # ################################################################################

    $LisHtm=1
	if ($par{"optProf"} eq "3" ||
	    $par{"optProf"} eq "htm");

				# ------------------------------
				# (1) NOT htm: change whichPROF
    if (-e $fileOldNot && $par{"optProf"} eq "3"){
	$whichPROFloc="both";
	unlink($fileOldNot); 
	$LisHtm=0;
    }

    if (-e $fileOldNot || $par{"optProf"} =~ /^(both|sec|acc)/ || ! $LisHtm){
				# delete if not required for jury
	if ($par{"optJury"} !~ /phd/i){
	    print "--- NOTE: no HTM detected -> files deleted ($fileOldRdb)\n";
	    unlink($fileOldRdb);}
				# read file, since used for jury
	else {
	    ($Lok,$msg)=
		&assHack1994rdrdb
		    ($fileOldRdb
		     );         return(&errSbrMsg("after call to assHack1994rdrdb",
						  $msg,$SBR2)) if (! $Lok);}
	unlink($fileOldNot)     if (defined $fileOldNot && -e $fileOldNot);
	$LisHtm=0;
    }
				# ------------------------------
				# (2) IS HTM or optPHD=htm
    else {
	$LisHtm=1;
	unlink($fileOldNot) if (-e $fileOldNot);
				# read the stuff from old RDB
	($Lok,$msg,$ctres)=
	    &assHack1994rdrdb
		($fileOldRdb);  return(&errSbrMsg("after call to assHack1994rdrdb",
						  $msg,$SBR2)) if (! $Lok);
	
				# assign key words
	$rdb{"NROWS_HTM"}=$ctres;
	$rdb{"NROWS"}=    $ctres if (! defined $rdb{"NROWS"});
	push(@kwdObs,"OMN")     if (defined $rdb{1,"OMN"} || defined $rdb{1,"OHL"});

	$kwdPrd="PMN";
	$kwdObs="OMN";
	$#kwdAdd=0;
#	push(@kwdAdd,$kwdPrd);
	@outnum2symloc=("M","N");
	foreach $itout (1..2){
	    push(@kwdAdd, "p".$outnum2symloc[$itout]);}
	foreach $itout (1..2){
	    push(@kwdAdd,"Ot".$outnum2symloc[$itout]);}

	$mode{"htmKwdRi"}= $kwdGlob{"ri"}->{"htm"};
	$mode{"htmKwdPrd"}=$kwdPrd;
	$mode{"htmKwdObs"}=0;
	$mode{"htmKwdObs"}=
	    $kwdObs if (defined $rdb{1,"OMN"} || defined $rdb{1,"OHL"});
	foreach $kwd (@{$kwdGlob{"want"}->{"htm"}}){
	    next if (! defined $rdb{1,$kwd});
	    push(@kwdRdb,$kwd);
	}
	push(@kwdRdb,@kwdAdd);
    }				# end of reading RDB file

    return(1,"ok $SBR2",$LisHtm,$fileOldRdb);
}				# end of assHack1994

#===============================================================================
sub assHack1994rdrdb {
    local($fileOldRdbLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assHack1994rdrdb            reads the RDB from old PHD
#       in:                     $fileInLoc (rdb)
#       out:                    1|0,msg,  implicit: %res
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."assHack1994rdrdb";
    $fhinyy="FHIN_yy".$SBR3;

				# --------------------------------------------------
				# read the stuff
				# --------------------------------------------------
    $Lok=1;
    open($fhinyy,$fileOldRdbLoc) || 
	return(0,"*** ERROR $SBR3: failed to open phd1999rdb=$fileOldRdbLoc!\n");
	
				# ------------------------------
				# header
    $#hdr1994rdrdb=0;
    $LmodeHtmloc=  0;
    while(<$fhinyy>){
	chop;
	$lastline=$_;
	next if ($_ =~ /^\#\s*$/);
	if ($_ =~ /^\#\s*PHDhtm/){
	    $LmodeHtmloc=1;
	    next;}
	if ($_ =~ /^\#\s*PHDsec.PHDacc.PHDhtm/){
	    $LmodeHtmloc=1;
	    next;}
	next if ($_ =~ /^\#\s*PHD/);
	next if ($_ =~ /^\#\s*NOTATION/);
				# membrane stuff
	if ($_ =~ /^\#\s*(NHTM|REL|MODEL|HTM)/i){
	    $tmp=$_;
	    $tmp=~s/^\# \s*//g;
	    $tmp=~s/(\S+)\s*: //;
	    $kwd=$1;
#	    $kwd=~tr/[A-Z]/[a-z]/;
#	    $kwd="htm_".$kwd;
	    $kwd="HTM_".$kwd;
	    $kwd2=$kwd;
	    $kwd2=~tr/[A-Z]/[a-z]/;
	    if (! defined $rdb{$kwd}){
		$rdb{$kwd}=$tmp;}
	    else {
		$rdb{$kwd}.="\t".$tmp;}
	    $rdb{$kwd2}=$rdb{$kwd};
	    next;}
	next if ($_ =~ /^\#/);
	
	if ($_ =~ /^No/){
	    $names=$_;
	    next;}
	last;			# formats
    }
				# ------------------------------
				# get names to read
				#     translate from all kinds of things!
    @names=split(/\s*\t\s*/,$names);
    $#skiptmp=0;
    foreach $it (1..$#names){
				# membrane stuff
	if    ($names[$it] eq "OHL")     { $names[$it]="OMN"; }
	elsif ($names[$it] eq "OTN")     { $names[$it]="OMN"; }
	elsif ($names[$it] eq "PHL")     { $names[$it]="PMN"; }
	elsif ($names[$it] eq "PTN")     { $names[$it]="PMN"; }
	elsif ($names[$it] eq "PRHL")    { $names[$it]="PRMN"; }
	elsif ($names[$it] eq "PRTN")    { $names[$it]="PRMN"; }
	elsif ($names[$it] eq "PR2HL")   { $names[$it]="PR2MN"; }
	elsif ($names[$it] eq "PiTo")    { $names[$it]="PiMo"; }
	elsif ($names[$it] eq "PiMo")    { $names[$it]="PiMo"; }
	elsif ($names[$it] eq "pT")      { $names[$it]="pM"; }
	elsif ($names[$it] eq "pN")      { $names[$it]="pN"; }
	elsif ($names[$it] eq "OtT")     { $names[$it]="OtM"; }
	elsif ($names[$it] eq "OtN")     { $names[$it]="OtN"; }
	elsif ($names[$it] eq "AA"  &&
	       $LmodeHtmloc)             { $names[$it]="AAhtm"; }
	elsif ($names[$it] eq "RI_H" &&
	       $LmodeHtmloc            ) { $names[$it]="RI_M"; }
	elsif ($names[$it] eq "RI_M")    { $names[$it]="RI_M"; }
	elsif ($names[$it] eq "RI_S" &&
	       $names !~/RI_[TMH]/   &&
	       $LmodeHtmloc)             { $names[$it]="RI_M"; }
	elsif ($names[$it] eq "pH"  &&
	       $names !~/,p[TMH],/  &&
	       $LmodeHtmloc)             { $names[$it]="pM"; }
	elsif ($names[$it] eq "pL"  &&
	       $names !~/,p[TMH],/  &&
	       $LmodeHtmloc)             { $names[$it]="pN"; }
	elsif ($names[$it] eq "OtH" &&
	       $names !~/OtT/       &&
	       $LmodeHtmloc)             { $names[$it]="OtM"; }
	elsif ($names[$it] eq "OtL" &&
	       $names !~/OtN/       &&
	       $LmodeHtmloc)             { $names[$it]="OtN"; }
				# all others only if optJury matches phd
	elsif ($par{"optJury"} !~ /phd/i){ $skiptmp[$it]=1;}

				# secondary structure
#	elsif ($names[$it] eq "PHEL")    { $names[$it]="PHELphd"; }
	elsif ($names[$it]=~/^Ot([HEL])/){ $tmp=$1;
					   if ($par{"optProf"} =~/^(htm|acc)/){$skiptmp[$it]=1;}
					   else { $names[$it]="Ot".$tmp."phd"; }}
#	elsif ($names[$it] =~ /RI_S/)    { $names[$it]="RI_Sphd"; }
				# solvent accessibility
#	elsif ($names[$it] eq "PACC")    { $names[$it]="PACCphd"; }
#	elsif ($names[$it] eq "PREL")    { $names[$it]="PRELphd"; }
#	elsif ($names[$it] eq "Pbie")    { $names[$it]="Pbiephd"; }
	elsif ($names[$it] =~ /^Ot(\d)/) { $tmp=$1;
					   if ($par{"optProf"} =~/^(htm|sec)/){$skiptmp[$it]=1;}
					   else { $names[$it]="Ot".$tmp."phd"; }}
#	elsif ($names[$it] =~ /RI_A/)    { $names[$it]="RI_Aphd"; }
				# not important 
	else                             { $skiptmp[$it]=1;}
    }

    $ctres=0;
				# ------------------------------
				# last one format or data?
    if ($lastline!~/\d+[SNF]\t|\t\d+[SNF]/){
	++$ctres;
	@tmp=split(/\s*\t\s*/,$lastline);
	foreach $it (1..$#tmp){
	    next if (defined $skiptmp[$it]);
	    $rdb{$ctres,$names[$it]}=$tmp[$it];
	}
				# hack br 2002-04: acc pM and pN
	&assHack1994detail($ctres,$rdb{$ctres,"OtM"},$rdb{$ctres,"OtN"})
	    if (! defined $rdb{$ctres,"pM"} && defined $rdb{$ctres,"OtM"});
    }

				# ------------------------------
				# now comes the data
    while(<$fhinyy>){
	chop;
	++$ctres;
	@tmp=split(/\s*\t\s*/,$_);
	foreach $it (1..$#tmp){
	    next if (defined $skiptmp[$it]);
	    $rdb{$ctres,$names[$it]}=$tmp[$it];
	}
				# hack br 2002-04: acc pM and pN
	&assHack1994detail($ctres,$rdb{$ctres,"OtM"},$rdb{$ctres,"OtN"})
	    if (! defined $rdb{$ctres,"pM"} && defined $rdb{$ctres,"OtM"});
    }
    close($fhinyy);
    return(1,"ok $SBR3",$ctres);
}				# end of assHack1994rdrdb


#===============================================================================
sub assHack1994detail {
    local($ctresloc,$tmp_OtM,$tmp_OtN)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assHack1994detail           compiles detaile 'pM' 'pN'
#       in:                     number of residue
#       out:                    1|0,msg,  implicit: %res
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."assHack1994detail";
    $sum=$tmp_OtM+$tmp_OtN;
    $rdb{$ctres,"pM"}=int(10*$tmp_OtM/$sum);
    $rdb{$ctres,"pN"}=int(10*$tmp_OtN/$sum);

    foreach $kwdloc ("pM","pN"){
	if    ($rdb{$ctresloc,$kwdloc}<0){
	    $rdb{$ctresloc,$kwdloc}=0;
	}
	elsif ($rdb{$ctresloc,$kwdloc}>9){
	    $rdb{$ctresloc,$kwdloc}=9;
	}
    }
    return(1,"ok $SBR4");
}				# end of assHack1994detail

#===============================================================================
sub fileParRd {
    local($whichPROFloc,@fileInParTmp)=@_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileParRd                   read neural network parameter files!
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#       in:                     @fileInPar:   all parameter files to use
#                               OR: file(s) with junction
#       out GLOBAL:             %par{"para",$it,$kwd}:
#                                   where:
#                                   it=1..$#fileInParTmp
#                                   $kwd=[dir_home|dir_net]
#           ------------------------------
#           boundaries:                    
#           ------------------------------
#                               
#           $par{"para"}=                number of parameter files
#           $par{"para",$ctpar}=         number of levels for file ctpar
#           $par{"para",$ctpar,$ctlevel} number of files in $ctlevel
#                               
#           ------------------------------
#           general:                    
#           ------------------------------
#                               
#           $par{"para",$kwd}=           kwd=[dir_home|dir_net]
#                               
#           ------------------------------
#           individual:                    
#           ------------------------------
#                               
#           $par{"para",$ctpar,$ctlevel,$ctfile}=
#                     $ctpar:   counts number of paramter files (given as input)
#                               1..$#fileInParTmp
#                     $ctlevel: counts network level (1:seq-to-str, 2: str-to-str)
#                               1..$par{"para",$ctpar}
#                     $ctfile:  counts the number of architectures to get for that level
#                               1..$par{"para",$ctpar,$ctlevel}
#                               
#           ------------------------------
#           individual keywords (GLOBAL from fileParRdOne):
#           ------------------------------
#                               
#           $par{"para",$ctpar,$ctlevel,$ctfile,$kwd}=$val
#                               kwd=[modepred|modenet|modein|modejob|version]
#                                   [numin|numhid|numout]
#                               NOTE: lower caps
#                               -> $ctfile at level $ctlevel depends on $NUM at level ($ctlevel-1)
#                               
#           ------------------------------
#           individual pointers:
#           ------------------------------
#                               
#           $par{"para",$ctpar,$ctlevel,$ctfile,"depend"}=$NUM
#                               NOTE: format 'dep_level:itfile,dep_level:itfile2'
#                               -> $ctfile at level $ctlevel depends on $NUM at level dep_level
#                               
#                               
#           ------------------------------
#           input directives:
#           ------------------------------
#                               
#           $par{"par",$ctpar,$ctlevel,"modein"}='modein1,modein2,modein3,...'
#                               -> all input modes to use
#           $par{"par",$ctpar,$ctlevel,"finfin"}= e.g. 'acc=3:1-4,sec=3:5-13,caph=1:n' 
#                               -> predict accessibility with jury over 3rd level files 1-4
#                                  secondary with jury over 3rd level files 5-13
#                                  helix caps for 1st level ..
#                                   
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."fileParRd";
    $fhinLoc="FHIN".$SBR2;
				# ------------------------------
				# check arguments
    return(&errSbr("not def whichPROFloc!",$SBR2)) if (! defined $whichPROFloc);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# xyyx hack
    if (! $fileInParTmp[1]){
	$netlevelMax=  0;
	$netlevelFound=0;
	$par{"para"}=  0;
	return(1,"old",$whichPROFloc);}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


    return(&errSbr("not def fileParIn!",  $SBR2)) if (! @fileInParTmp);
    $netlevelMax=4;		# maximal number of network levels expected
    $netlevelMax=$par{"netlevelMax"}  if (defined $par{"netlevelMax"});
    $netlevelFound=1;

				# --------------------------------------------------
				# (1) loop over all files: first go
				# --------------------------------------------------
    $par{"para"}=$#fileInParTmp;
    undef %tmpadd;
    foreach $itpar (1..$#fileInParTmp){
	$filePar=$fileInParTmp[$itpar];
	return(&errSbr("missing filePar=$filePar",$SBR2))
	    if (! -e $filePar);
				# read one parameter file
				#     out GLOBAL: %par{"para",$itpar *}
				#     out GLOBAL: %tmp{"readalso"}='jury10,juryhel'
				#                 $tmp{"modepred",$file},$tmp{"modeout",$file},
				#     NOTE:       currently not used!
	($Lok,$msg)=
	    &fileParRdOne
		($filePar,
		 $itpar);	return(&errSbrMsg("fileParRdOne failed for filePar=$filePar!",
						  $msg,$SBR2)) if (! $Lok);
    }				# end of loop over all parameter files
				# --------------------------------------------------

				# --------------------------------------------------
				# (2) add parameter files to read for third level
				#     NOTE:       currently not used!
				# --------------------------------------------------
    if (%tmpadd){
	$dir=$fileInParTmp[1];
	$dir=~s/(^.*\/)[^\/]*$/$1/; 
	$dir.="/"               if (length($dir) > 1 && $dir !~ /\/$/);
	$tmpadd{"readalso"}=~s/,*$//g;
	@add=split(/,/,$tmpadd{"readalso"});
	foreach $itadd (1..$#add){
	    $filePar= $add[$itadd];
	    $modepred=$tmpadd{"modepred",$filePar};
	    $modeout= $tmpadd{"modeout", $filePar};
	    
				# ignore those already read
	    if (defined $par{$modepred,$modeout}){
		print "-*- WARN $SBR2: already defined $modepred,$modeout!\n";
		next; }
	    $itpar=$par{"para"}+$itadd;
	    $par{$modepred,$modeout}=$itpar;

				# add directory
	    $filePar=$dir.$filePar if (! -e $filePar);
	    return(&errSbr("missing filePar=$filePar",$SBR2))
		if (! -e $filePar);
				# read one parameter file
				#     out GLOBAL: %par{"para",$itpar *}
	    ($Lok,$msg)=
		&fileParRdOne
		    ($filePar,
		     $itpar);	return(&errSbrMsg("fileParRdOne failed 3rd level add filePar=".
						  $filePar."!",$msg,$SBR2)) if (! $Lok);
	}
				# update count
	$par{"para"}=$itpar; }

				# --------------------------------------------------
				# (3) read modes for all junctions
				# --------------------------------------------------
    foreach $itpar (1..$par{"para"}){
				# ------------------------------
				# loop over levels
	$ctlevel=0;
	foreach $itlevel (1..$netlevelFound){
	    next if (! defined $par{"para",$itpar,$itlevel});
				# store number of levels found for this
	    if ($itlevel>$ctlevel){
		$ctlevel=           $itlevel;
		$par{"para",$itpar}=$ctlevel;}
				# loop over all files
	    foreach $itfile (1..$par{"para",$itpar,$itlevel}){
				# out GLOBAL: $par{"para",$itpar,$itlevel,$itfile,$kwdtmp}
				#             kwdtmp=[modepred|modeout|modenet]
		($Lok,$msg)=
		    &fileParRdJct($par{"para",$itpar,$itlevel,$itfile},
				  $itpar,$itlevel,$itfile);
		return(&errSbrMsg("failed reading file for itpar=$itpar, ".
				  "itlevel=$itlevel, itfile=$itfile!\n",$msg,$SBR2))
		    if (! $Lok);
				# check ri
		if ($par{"optJury"}=~/sigma/){
		    $tmp=$par{"para",$itpar,$itlevel,$itfile};
		    $tmp=~s/^.*\///g;
		    if (defined $par{"known",$tmp,"ri_ave"}){
			foreach $kwd ("ri_ave","ri_sig"){
			    $par{"para",$itpar,$itlevel,$itfile,$kwd}=
				$par{"known",$tmp,$kwd};
			}}}
	    }			# end of loop over all in level $itlevel
	}
    }				# end of loop over all parameter files 
				# --------------------------------------------------

				# --------------------------------------------------
				# (4) error check
				# --------------------------------------------------
    $err="";
    $txt="";
    $txt.=sprintf("%3s %3s %3s %-15s ","ipar","ilev","ijct","file");
    foreach $kwdmode ("modepred","modenet","modeout","modein"){
	$tmp=$kwdmode;$tmp=~s/mode//g;
	$txt.=$tmp.":";}
    $txt=~s/\:$/\n/g;

    undef %tmpmode; $tmpmode="";
    foreach $itpar (1..$par{"para"}){
	foreach $itlevel (1..$netlevelFound){
	    next if (! defined $par{"para",$itpar,$itlevel});
	    foreach $itfile (1..$par{"para",$itpar,$itlevel}){
		$tmp=$par{"para",$itpar,$itlevel,$itfile}; $tmp=~s/^.*\/|\.dat|\.jct//g;
		$txt.=sprintf("%3d %3d %3d %-15s ",$itpar,$itlevel,$itfile,$tmp);
		foreach $kwd ("modepred","modenet","modeout","modein"){
		    if (! defined $par{"para",$itpar,$itlevel,$itfile,$kwd}){
			$err.="file=".$par{"para",$itpar,$itlevel,$itfile}.
			    " miss kwd=$kwd\n";}
		    else {
			if ($kwd eq "modepred"){
			    $mode=$par{"para",$itpar,$itlevel,$itfile,$kwd};
			    if (! defined $tmpmode{$mode}) {
				$tmpmode{$mode}=1;
				$tmpmode.=$mode.",";}}
			$txt.=$par{"para",$itpar,$itlevel,$itfile,$kwd}.":";}
		}
		$txt=~s/\:$/\n/g;
	    }
	}
    }
				# --------------------------------------------------
				# (5) assign mode for entire thing
				# --------------------------------------------------
    if    ($tmpmode=~/sec/ && $tmpmode=~/acc/ && $tmpmode=~/htm/) {
	$whichPROFloc="3"; }
    elsif ($tmpmode=~/sec/ && $tmpmode=~/acc/) {
	$whichPROFloc="both"; }
    elsif ($tmpmode=~/sec/) {
	$whichPROFloc="sec"; }
    elsif ($tmpmode=~/acc/) {
	$whichPROFloc="acc"; }
    elsif ($tmpmode=~/htm/) {
	$whichPROFloc="htm"; }
    else {
	$whichPROFloc="htm";	# xyyx hack
	print "*** ERROR $SBR2: problem with mode for optProf cannot be set\n";
	print "***              you may pray and hope ...\n";}
    
    return(0,
	   "*** ERROR $SBR2: some problems with paras:\n".
	   $err)                if (length($err)>1);
    print $FHTRACE2 $txt        if ($par{"verb2"});

				# ------------------------------
				# clean up
    $#fileInParTmp=0;		# slim-is-in
    $#tmp=$#tmp2=0;		# slim-is-in
    undef %tmpmode;
    return(1,"ok $SBR2",$whichPROFloc);
}				# end of fileParRd

#===============================================================================
sub fileParRdOne {
    local($filePar,$itpar) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileParRdOne                reads one parameter/junction file
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."fileParRdOne";
				# check arguments
    return(&errSbr("not def filePar!",$SBR2))    if (! defined $filePar);
#    return(&errSbr("not def !",$SBR2))          if (! defined $);

				# ------------------------------
				# (1a) is junction
    if ($filePar=~/$par{"extProfJct"}$/){	# HARD_CODED: extension '.jct' for junctions
	$par{"para",$itpar}=    1;
	$par{"para",$itpar,1}=  1;
	$par{"para",$itpar,1,1}=$filePar;
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# early return
	return(1,"ok"); 
				# early return
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    }

				# ------------------------------
				# (1b) is parameter file
    open($fhinLoc,$filePar) ||
	    return(&errSbr("failed opening filePar=$filePar! (fhin=$fhinLoc)",$SBR3));
    print $FHTRACE2
	"--- $SBR3: read filePar=$filePar\n" if ($par{"verb2"});
    $ctline=0; 
				# ini number of levels
    foreach $netlevel (1..$netlevelMax){
	$ctfile[$netlevel]=0; }

				# ini dirs
    foreach $kwd ("dir_home","dir_net"){
	$par{"para",$itpar,$kwd}="";
    }
    $dirHome="";
    $dirNet= "";
    while(<$fhinLoc>){
	++$ctline;
				# grep version
	if ($_=~/^[\s\t]*\#/){
	    if ($_=~/[Vv]ersion:[\s\t]+(\S)/){
		$par{"para",$itpar,"version"}=$1;}
				# skip comments
	    next; }

	$_=~s/\n//g; $line=$_;
				# skip empty
	next if (length($_)==0);
				# directories
	if ($_=~/^(dir_.*)[\s\t]+(\S+)/){
	    return(&errSbr("filePar=$filePar, ctline=$ctline, kwd=$1, missing value!\n",
			   $SBR3)) if (! defined $2);
	    $kwd=$1; 
	    $val=$2; 
	    $kwd=~s/\s//g;$val=~s/\s//g;	# remove blanks
				# add slash
	    $val.="/"       if ($val!~/\/$/);
	    $par{"para",$itpar,$kwd}=$val;
	    $dirHome=$val   if ($kwd=/home/ && &isName($val));
	    $dirNet= $val   if ($kwd=/net/ &&  &isName($val));
	    next; }
				# file_1,file_2,file_3 asf
	if ($_=~/^file_(\d+)[\s\t]+(\S+)/){
	    $itlevel=$1; 
	    return(&errSbr("filePar=$filePar, ctline=$ctline, level=$1, missing value2!\n",
			   $SBR3)) if (! defined $2);
	    $val=  $2; 
	    undef $ptr;
				# second level
	    if   ($itlevel==2){
		$val=~s/[\s\t]+\S+.*$//g;
		$ptr=$line;
		$ptr=~s/^file_\d+[\s\t]+\S+[\s\t]+(\d.*)$/$1/g;
		$ptr=~s/\s//g; 
		return(&errSbr("filePar=$filePar, ctline=$ctline, level=$1, missing value3!\n",
			       $SBR3)) if (! defined $ptr || $ptr=~/^\s*$/);
				# count up levels found
		$netlevelFound=$itlevel if ($itlevel > $netlevelFound);
				# dissect info
				#     '1,2' -> 'PREVIOUS_LEVEL:1,PREVIOUS_LEVEL:2'
		if ($ptr !~/:/){
		    @tmp2=split(/,/,$ptr);
		    $tmp="";
		    foreach $tmp2 (@tmp2){
			$tmp.=($itlevel-1).":".$tmp2.",";
		    }
		    $tmp=~s/\,$//g;}
		$ptr=$tmp;
	    }
				# third level
	    elsif ($itlevel==3){
		$val=~s/[\s\t]+\S+.*$//g;
		$ptr=$line;
		$ptr=~s/^file_\d+[\s\t]+\S+[\s\t]+(\S.*)$/$1/g;
		$ptr=~s/\s//g; 
		return(&errSbr("filePar=$filePar, ctline=$ctline, level=$1, missing value3!\n",
			       $SBR3)) if (! defined $ptr || $ptr=~/^\s*$/);
				# count up levels found
		$netlevelFound=$itlevel if ($itlevel > $netlevelFound);
	    }
	    
	    $val=~s/\s//g;
	    $val2=$val;
				# file with junction existing in local dir?
				#   not -> (1) add directory: if NOT existing file junction
	    $val2=$dirHome.$dirNet.$val
		if (! -e $val2 && ! -l $val2 && 
		    $val2 !~/$dirHome/ && $val2 !~/$dirNet/);
				# still not there: try GLOBAL para
	    $val2=$par{"dirNet"}.$val
		if (! -e $val2 && ! -l $val2 && 
		    $val2 !~/$par{"dirNet"}/);
				# still not there: stop
	    return(&errSbr("cannot locate file with junctions=$val2 (dirNetLocal=$dirNet, ".
			   "par{dirNet}=".$par{"dirNet"}),$SBR3)
		if (! -e $val2 && ! -l $val2); # 

				# count number of files in current level
	    ++$ctfile[$itlevel];
				# store results
	    $itfile=$ctfile[$itlevel];
	    $par{"para",$itpar,$itlevel}=                 $itfile;
	    $par{"para",$itpar,$itlevel,$itfile}=         $val2;
	    $par{"para",$itpar,$itlevel,$itfile,"depend"}=$ptr 
		if ($itlevel > 1 && defined $ptr);
	    next; 
	}
				# for 3rd level: final predictions to do
	if ($_=~/^finfin[\s\t]+(\S+)[\s\t]+(\S+)/){
	    return(&errSbr("filePar=$filePar, ctline=$ctline, kwd=$1, value=$2!\n",
			   $SBR3)) if (! defined $1 || ! defined $2);
	    $kwd=$1;		# of form 'sec'
	    $val=$2;		# of form '3:1-5'
				# split for jury over different levels

	    if (! defined $par{"para",$itpar,$itlevel,"finfin"}){
		$par{"para",$itpar,$itlevel,"finfin"}=    $kwd."=".$itpar.":".$val;}
	    else {
		$par{"para",$itpar,$itlevel,"finfin"}.=   ",".$kwd."=".$itpar.":".$val;}
	    next; }
				# for 3rd level: dependency
				#     NOTE:       currently not used!
	if ($_=~/^mode_(.*)[\s\t]+(\S+)/){
	    return(&errSbr("filePar=$filePar, ctline=$ctline, kwd=$1, missing value!\n",
			   $SBR3)) if (! defined $2);
	    $kwd=$1; 
	    $val=$2; 
	    $kwd=~s/\s//g;$val=~s/\s//g;	# remove blanks
	    ($modepred,$modeout)=split(/:/,$kwd);
	    $tmpadd{"readalso"}=""    if (! defined $tmpadd{"readalso"});
	    $tmpadd{"readalso"}.=$val.",";
	    $tmpadd{"modepred",$val}=$modepred;
	    $tmpadd{"modeout", $val}=$modeout;
	    $tmpadd{$val}=$itpar;
	    next; }
    } 
    close($fhinLoc);

    return(1,"ok $SBR3");
}				# end of fileParRdOne

#===============================================================================
sub fileParRdJct {
    local($fileInLoc,$itpar,$itlevel,$itfile) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileParRdJct                reads one junction file (header only)
#       in:                     $fileInLoc: one neural network architecture
#       in:                     $itpar:     count through parameter files (for e.g. ACC+SEC)
#       in:                     $itlevel:   network levels (1:seq-2-str,2:str-2-str,3:new)
#       in:                     $itfile:    count number of files found at given level
#       out GLOBAL:             $par{"para",$itpar,$itlevel,$itfile,$kwd}=
#                                   where kwd=[modepred|modenet|modein|modejob]
#                                            =[numin|numhid|numout]
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."fileParRdJct";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR3))          if (! defined $fileInLoc);

    open($fhinLoc,$fileInLoc) ||
	return(&errSbr("failed opening fileInLoc=$fileInLoc! (fhin=$fhinLoc)\n".
		       "it=$itpar, level=$itlevel, itfile=$itfile,\n",$SBR3));
    print $FHTRACE2
	"--- $SBR3: read fileInLoc=$fileInLoc\n" if ($par{"verb3"});

    while(<$fhinLoc>){
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g; $line=$_;
				# skip empty
	next if (length($_)==0);
				# stop reading when junctions come
	last if ($_=~/^\* jct/ ||
		 $_=~/^[\s\t]+[\-0-9]/);
				# numbers
	if ($_=~/^NUM(IN|HID|OUT)/){
	    $kwd=$1; $kwd=~tr/[A-Z]/[a-z]/;
	    $kwd="num".$kwd;
	    $tmp=$line;
	    $tmp=~s/^.*\:[\s\t]+(\d+)\s*$/$1/;
	    $par{"para",$itpar,$itlevel,$itfile,$kwd}=$tmp;}

				# modes
	elsif ($_=~/^(MODE[^\:]+)/){
	    $kwd=$1; $kwd=~tr/[A-Z]/[a-z]/;
	    $tmp=$line;
	    $tmp=~s/^.*\:[\s\t]+(\S+)\s*$/$1/;
	    $par{"para",$itpar,$itlevel,$itfile,$kwd}=$tmp;}
    } 
    close($fhinLoc);
    return(1,"ok $SBR3");
}				# end of fileParRdJct

#===============================================================================
sub func_sigmoid {
    local($x) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   func_sigmoid                compiles the neural network sigmoid function
#-------------------------------------------------------------------------------
    $y=1/( 1 + exp ((-1)*$x));
    return($y);
}				# end of func_sigmoid

#===============================================================================
sub func_sigmoidGen {
    local($x,$temperatureLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   func_sigmoidGen             compiles the neural network sigmoid function:
#                               WITH temperature
#-------------------------------------------------------------------------------
    $y=1/( 1 + exp ((-1)*$temperatureLoc*$x));
    return($y);
}				# end of func_sigmoid

#===============================================================================
sub get_outAcc {
    local($modeoutLoc,$accBuriedSat,$acc2Thresh,$acc3Thresh1,$acc3Thresh2,
	  $bitaccLoc,@vecLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outAcc                  relative accessibility value for acc=be|bie !
#                               formula e.g. 'be', thresh=16
#                               1:  winner=unit 1 (for b), value=0.75
#                               ->  acc= 16 - (16-0)*   2*(0.75-0.5) 
#                                      =  8
#                               2:  winner=unit 2 (for e), value=0.75
#                               ->  acc= 16 + (100-16)* 2*(0.75-0.5)
#                                      = 58
#       in:                     $modeout:       some unique description of output coding (HEL)
#       in:                     $modeoutLoc:    <BE|BIE|10>
#       in:                     $acc2Thresh:    threshold for 2-state acc, b: acc<=thresh, e: else
#       in:                     $acc3Thresh:    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#       in:                     $accBuriedSat:  2|3-state model if accPrd < -> 0
#       in:                     $bitacc:        accuracy of @vec, i.e. output= integers, out/bitacc = real
#       in:                     @vec:           output vector 
#                               
#       in GLOBAL:                                      
#                               
#                               
#       out:                    1|0,msg,$accRel
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outAcc";
				# check arguments
    return(&errSbr("not def modeoutLoc!",$SBR6),0)          if (! defined $modeoutLoc);
    return(&errSbr("not def accBuriedSat!",$SBR6),0)        if (! defined $accBuriedSat);
    return(&errSbr("not def acc2Thresh!",$SBR6),0)          if (! defined $acc2Thresh);
    return(&errSbr("not def acc3Thresh1!",$SBR6),0)         if (! defined $acc3Thresh1);
    return(&errSbr("not def acc3Thresh2!",$SBR6),0)         if (! defined $acc3Thresh2);
    return(&errSbr("bitaccLoc < 1!",$SBR6),0)               if ($bitaccLoc<1);
    return(&errSbr("no vector (vecLoc,$SBR6)!"),0)          if (! defined @vecLoc || $#vecLoc<1);

    $undecidedLoc=$bitaccLoc*0.5 if (! defined $undecidedLoc);

    $acc="";
				# ------------------------------
				# ACC 2 states -> rel acc
				# ------------------------------
    if ($modeoutLoc eq "be") {
				# ->  acc= 16 - (16-0)*   2 * (val - 0.5) 
	if ($vecLoc[1] > $vecLoc[2]) {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[1] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $diff=1             if ($diff >= $accBuriedSat); # correct for high reliability buried!
	    $acc=$acc2Thresh - (    $acc2Thresh    * $diff ); }
				# ->  acc= 16 + (100-16)* 2*  (val - 0.5)
	else {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[2] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $acc=$acc2Thresh + ( (100-$acc2Thresh) * $diff ); }}

				# ------------------------------
				# ACC 3 states -> rel acc
				# ------------------------------
    if ($modeoutLoc eq "bie") {
				# ->  acc= 4 - (4-0)*     2 * (val - 0.5) 
	if    ($vecLoc[1] > $vecLoc[2] &&
	       $vecLoc[1] > $vecLoc[3]) {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[1] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $diff=1             if ($diff >= $accBuriedSat); # correct for high reliability buried!
	    $acc=$acc3Thresh1 - ( $acc3Thresh1          * $diff ); }
				# ->  acc= 4 + (25-4)*    2*  (val - 0.5)
	elsif ($vecLoc[2] > $vecLoc[3]){
	    $diff=(2 / $bitaccLoc) * ($vecLoc[2] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $acc=$acc3Thresh1 + ( ($acc3Thresh2-$acc3Thresh1) * $diff ); }
				# ->  acc= 25 + (100-25)* 2*  (val - 0.5)
	else {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[3] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $acc=$acc3Thresh2 + ( (100-$acc3Thresh2)    * $diff ); }}
    $acc=int($acc);

    return(1,"ok $SBR6",$acc);
}				# end of get_outAcc

#===============================================================================
sub get_outAccBE {
    local($accRelLoc,$acc2Thresh,@prdLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outAccBE                converts  relative accessibility + actual output
#                               values to two-state model Buried Exposed
#       in:                     $accRelLoc:     relative accessibility
#       in:                     $acc2Thresh:    threshold for 2-state acc, b: acc<=thresh, e: else
#       in:                     @prdLoc:        output vector 
#                               
#       in GLOBAL:                                      
#                               
#                               
#       out:                    1|0,msg,$accRel
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outAccBE";
				# check arguments
    return(&errSbr("not def accRelLoc!",  $SBR6),0)        if (! defined $accRelLoc);
    return(&errSbr("not def acc2Thresh!", $SBR6),0)        if (! defined $acc2Thresh);
    return(&errSbr("no vector (prdLoc)!", $SBR6),0)        if (! defined @prdLoc || $#prdLoc<1);

				# ------------------------------
				# fast end for others
    if ($#prdLoc<10 || ! $par{"optAcc10Filter2"}){
	return(1,"ok",$acc2SymbolLoc[1]) if ($accRelLoc <= $acc2Thresh);
	return(1,"ok",$acc2SymbolLoc[2]);}

				# ------------------------------
				# compile averages over each state 
				#    for 10 state prediction
    if ($#prdLoc==10){
	$#tmp=$#cttmp=0;
	foreach $itout (1..$#prdLoc){
				# is buried
	    if ((($itout-1)*$itout)<=$acc2Thresh){
		++$cttmp[1];++$tmp[1];}
	    else {		# is exposed
		++$cttmp[2];++$tmp[2];}}
				# normalise
	$max=$pos=0;
	foreach $it (1,2){
	    $tmp[$it]=0; 
	    $tmp[$it]=$tmp[$it]/$cttmp[$it] if ($cttmp[$it]>0);
	    if ($max < $tmp[$it]){
		$max=$tmp[$it];
		$pos=$it;}}
				# now winner gets it
	return(1,"ok",$acc2SymbolLoc[$pos]) if ($pos>0);
				# undecided: give it to traditional winner
	return(1,"ok",$acc2SymbolLoc[1])    if ($accRelLoc <= $acc2Thresh);
	return(1,"ok",$acc2SymbolLoc[2]); }

    return(0,"should have never come here:$SBR6!",0);
}				# end of get_outAccBE

#===============================================================================
sub get_outAccBIE {
    local($accRelLoc,$acc3Thresh1,$acc3Thresh2,@prdLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outAccBIE               converts  relative accessibility + actual output
#                               values to two-state model Buried Exposed
#       in:                     $accRelLoc:     relative accessibility
#       in:                     $acc3Thresh:    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#       in:                     @prdLoc:        output vector 
#                               
#       in GLOBAL:                                      
#                               
#                               
#       out:                    1|0,msg,$accRel
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outAccBIE";
				# check arguments
    return(&errSbr("not def accRelLoc!",  $SBR6),0)        if (! defined $accRelLoc);
    return(&errSbr("not def acc3Thresh1!",$SBR6),0)        if (! defined $acc3Thresh1);
    return(&errSbr("not def acc3Thresh2!",$SBR6),0)        if (! defined $acc3Thresh2);
    return(&errSbr("no vector (prdLoc)!", $SBR6),0)        if (! defined @prdLoc || $#prdLoc<1);

				# ------------------------------
				# compile averages over each state 
				#    for 10 state prediction
    if ($#prdLoc==10){
	$#tmp=$#cttmp=0;
	foreach $itout (1..$#prdLoc){
				# is buried
	    if    ((($itout-1)*$itout) <= $acc3Thresh1){
		++$cttmp[1];++$tmp[1];}
				# is exposed
	    elsif ((($itout-1)*$itout) >  $acc3Thresh2){
		++$cttmp[3];++$tmp[3];}
	    else {		# is intermediate
		++$cttmp[2];++$tmp[2];}}
				# normalise
	$max=$pos=0;
	foreach $it (1,2,3){
	    $tmp[$it]=0; 
	    $tmp[$it]=$tmp[$it]/$cttmp[$it] if ($cttmp[$it]>0);
	    if ($max < $tmp[$it]){
		$max=$tmp[$it];
		$pos=$it;}}
				# now winner gets it
	return(1,"ok",$acc3SymbolLoc[$pos]) if ($pos>0);
				# undecided: give it to traditional winner
	return(1,"ok",$acc3SymbolLoc[1]) if ($accRelLoc <= $acc3Thresh1);
	return(1,"ok",$acc3SymbolLoc[3]) if ($accRelLoc >  $acc3Thresh2);
	return(1,"ok",$acc3SymbolLoc[2]); }

				# ------------------------------
				# fast end for others
    if ($#prdLoc<10){
	return(1,"ok",$acc3SymbolLoc[1]) if ($accRelLoc <= $acc3Thresh1);
	return(1,"ok",$acc3SymbolLoc[3]) if ($accRelLoc >  $acc3Thresh2);
	return(1,"ok",$acc3SymbolLoc[2]); } 

    return(0,"should have never come here:$SBR6!",0);
}				# end of get_outAccBIE

#===============================================================================
sub get_outSym {
    local($modepredLoc,$posWinLoc,@outnum2symLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outSym                  returns symbol for output winner
#       in:                     $modepred:      short description of what the job is about
#       in:                     $posWin:        number of output unit with highest value
#       in:                     @outnum2sym:    's1,s2,s3' symbols for output units (e.g. 'H,E,L')
#       out:                    1|0,msg,$sym
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outSym";
				# check arguments
    return(&errSbr("not def modepredLoc!",$SBR6),0)      if (! defined $modepredLoc);
    return(&errSbr("not def posWinLoc!",$SBR6),0)        if (! defined $posWinLoc);
    return(&errSbr("not def outnum2symLoc!",$SBR6),0)    if (! defined @outnum2symLoc || 
							     $#outnum2symLoc<1);
    return(&errSbr("numout must be > 1, here",$SBR6),0)  if ($#outnum2symLoc<2);
    return(&errSbr("undefined symbol for posWinLoc=$posWinLoc, outnum2symLoc=".
                   join(',',@outnum2symLoc,$SBR6)),0)    if ($#outnum2symLoc<$posWinLoc);
                                # ------------------------------
                                # sec|htm|acc (2,3 states)
    if    ($modepredLoc eq "sec" || $modepredLoc eq "htm" ||
        ($modepredLoc eq "acc" && $#outnum2symLoc<=3) ){
        return(&errSbr("for mode=$modepredLoc, should be more than ".$#outnum2symLoc.
                       " output units",$SBR6),0) if ($#outnum2symLoc<2);
        $sym=$outnum2symLoc[$posWinLoc];
        return(1,"ok $SBR6",$sym); }
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 

                                # ------------------------------
                                # acc (10 states)
    elsif ($modepredLoc eq "acc" && $#outnum2symLoc>3) {
        return(&errSbr("for mode=acc, should be more less than ".$#outnum2symLoc.
                       " output units",$SBR6),0) if ($#outnum2symLoc>10);
        $sym=$posWinLoc-1;
        return(1,"ok $SBR6",$sym); }
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 
                                # ------------------------------
                                # unk
    else { 
        return(&errSbr("combination of modepredLoc=$modepredLoc, numout=".$#outnum2symLoc.
                       ", unknown",$SBR6),0); }

    return(0,"*** ERROR $SBR6: should have never come her...",0);
}				# end of get_outSym

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
				# ******************************
				# yxy hack br 2003-11-04: changed the way this is done:
				# now (1) compile averages over 2 state, (2) do RI on these
	if (0){
	    $max=$pos=$max2=$pos2=0;
	    foreach $itout (1..$#vecLoc){ # max
	       if ($vecLoc[$itout]>$max) { 
		   $max=$vecLoc[$itout]; $pos=$itout;}}
	    foreach $itout (1..$#vecLoc){ # 2nd best, at least three units away!
	       if ($vecLoc[$itout]>$max2 && ( $itout < ($pos-2) || $itout > ($pos+2) ) ){
		   $max2=$vecLoc[$itout]; $pos2=$itout;}}
				# correct if 2nd too close
	    $max2=0                 if (&func_absolute($pos2-$pos)<3);
            
#	    return(&errSbr("for mode=acc and numout=".$#vecLoc.", the maximal unit was found to be:$pos, ".
#			   "the 2nd:$pos2, this is less than 2 units apart (out=".
#			   join(',',@vecLoc).")",$SBR6),0)
                                # define reliability index
	    $ri=int( 30 * ($max-$max2)/$bitaccLoc );  $ri=0 if ($ri<0); $ri=9 if ($ri>9);
	}

				# now (1) compile averages over 2 state, (2) do RI on these
				# NOTE: do not use the global  2 thresh thing here, instead FIXED hard_coded
				# try 2 state shit
	$valb=$vale=0;
				# first 4 = buried (0,1,4,9)
	foreach $it (1..4)       {$valb+=$vecLoc[$it];}
				# others = exposed (16,25,36,49,64,81)
	foreach $it (5..$#vecLoc){$vale+=$vecLoc[$it];}
	$valb=$valb/4; $vale=$vale/6; $sumval=$valb+$vale;

	$diff=0;
        if    ($valb==$vale){$ri=0;}
	elsif ($valb>$vale) {$diff=$valb-$vale;}
	else                {$diff=$vale-$valb;}
	if ($diff){
	    $diff_frac=$diff/$sumval;
	    $factor=10+int($diff_frac*4);
	    $ri=int( $factor * $diff_frac );
	}

	$ri=0 if ($ri<0); $ri=9 if ($ri>9);

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
sub hsspRdProf {
    local ($fileInLoc,$kwdInLoc,$modeDebug) = @_ ;
    local ($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf                       
#       in:                     $fileHssp (must exist), 
#       in:                     $kwdInLoc:  default keywords separated by comma, also
#       in:                     $modeDebug=[all|head|pair|seq|ali|prof|ins|nfar]
#                                           if any set: will write info, and stop!
#       in:           kwd=~/nohead/     surpresses reading header information
#       in:           kwd=~/nopair/     surpresses reading pair information
#       in:           kwd=~/nonfar/     surpresses compiling number of distant alis!
#       in:           kwd=~/noseq/      surpresses reading sequence
#       in:           kwd=~/nosec/      surpresses reading secondary structure
#       in:           kwd=~/noacc/      surpresses reading accessibility
#       in:           kwd=~/noali/      surpresses reading alignments
#       in:           kwd=~/noprof/     surpresses reading profiles
#       in:           kwd=~/noins/      surpresses reading insertion list
#       in:           kwd=~/nofill/     surpresses writing full aligned sequences (no ins!)
#       in:           kwd=~/chn=A,B/    read chains A,B
#       in:           kwd=~/ali=1-5,7/  read alis of seq1-5 and 7
#       in:           kwd=~/ali=id1,id2/ read alis of id1 and id2 (note: no '-' here!)
#       in:           kwd=~/dist=INT/   count number of distant family members,
#                                       where 'distant' = distance < this integer INT=[0..100]
#       in:           kwd=~/distMode=[gt|ge|lt|le]
#       in:                             if gt: will count all CLOSE relatives (see /dist=INT/)
#       in:           
#       in GLOBAL:              from hsspRdProf_ini:
#       in GLOBAL:              %hsspRdProf_ini
#       in GLOBAL:              @hsspRdProf_iniKwdHdr,@hsspRdProf_iniKwdPair,
#       in GLOBAL:              @hsspRdProf_iniKwdAli,
#                               
#       out GLOBAL:   %hssp:
#                               specials for overall
#                     $hssp{"numres"}
#                     $hssp{"numali"}
#                     $hssp{"pair","numali"}
#                     $hssp{"ali","numres"}
#                     $hssp{"ali","numres",$ctBlock}
#                               
#                     $hssp{$kwd}          for all keywords in HEADER (@hsspRdProf_iniKwdHdr)
#                     $hssp{$kwd,$ctali}   for all pair keywords, data for ali no $ctali
#                               
#                     $hssp{'ndist'}=      number of proteins below (or above) distance 
#                                            (see kwd=/dist=/ /distMode=/ and sbr hsspRdProf_getNfar)
#                     $hssp{'ndist',$chain}=those for chain $chain
#                               
#                     $hssp{'[chain|seq|sec|acc]',$ctres} 
#                               
#                     $hssp{'chain'}        e.g. A,B,
#                     $hssp{'chain',$chain,'beg'} first residue of chain $chain
#                     $hssp{'chain',$chain,'end'} last residue of chain $chain
#                                           NOTE: $chain=' ' for no chain!
#                               
#                     $hssp{'chain',$chain,'begSeqNo'} first residue of chain $chain according to SeqNo
#                     $hssp{'chain',$chain,'endSeqNo'} last residue of chain $chain  according to SeqNo
#                               
#                     $hssp{'ali',  $numali,$ctres} residue aliged at $ctres residue for ali=$numali
#                               NOTE: can be more than one residue for insertions!
#                     $hssp{'ali','numbers_wanted'}=1,5,7
#                               pointer to the numbers of alis read
#                     $hssp{'prof',$kwd,$ctres} kwd like in PROF (@hsspRdProf_iniKwdProf)
#                     $hssp{'fin',$numali}= full sequence (NOTE: guide=$numali=0)          
#                               
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR2=$tmp."hsspRdProf";
    $fhinLoc="FHIN_"."hsspRdProf";$fhoutLoc="FHOUT_"."hsspRdProf";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR2))     if (! defined $fileInLoc);
    $kwdInLoc=0                                     if (! defined $kwdInLoc);
    return(&errSbr("no fileIn=$fileInLoc!",$SBR2))  if (! -e $fileInLoc);

				# ------------------------------
				# hack debug otions:
				#     if set will die after that!
				# avoid warning
    $LdebugWrtHead=$LdebugWrtPair=$LdebugWrtAli= 
	$LdebugWrtProf=$LdebugWrtIns= $LdebugWrtNfar=$LdebugWrtFill=0; 

    $LdebugWrtHead=0; 
    $LdebugWrtPair=0; 
    $LdebugWrtAli= 0; 
    $LdebugWrtProf=0; 
    $LdebugWrtIns= 0; 
    $LdebugWrtNfar=0; 
    $LdebugWrtFill=0; 

#    $kwdHsspIn="noali noins nofill dist=".$par{"convPfar"}.",distMode=le,";

				# ------------------------------
				# check input arguments
    $LnoHead=$LnoPair=$LnoAli=$LnoProf=$LnoIns=$LnoFill=$LnoAliFill=0;
    $LnoAli= 1                  if ($kwdInLoc=~/noali/);
    $LnoIns= 1                  if ($kwdInLoc=~/noins/);
    $LnoFill=1                  if ($kwdInLoc=~/nofil/);
#    $LnoAliFill=1               if ($kwdInLoc=~/noalifil/);
    $distCount=                 $par{"convPfar"};
    $distCount=                 20   if (! defined $distCount);
    $distCountMode=             "le";
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR2));
    undef %hssp;
    undef %tmp;
				# --------------------------------------------------
				# read header
				# note: all variable global!
				# --------------------------------------------------
    ($Lok,$msg)=
	&hsspRdProf_head();     return(&errSbr("file=$fileInLoc: problem with hsspRdProf_head:".
						  $msg."\n",$SBR2)) if (! $Lok);
				# no ali: reject
    if ($hssp{"NALIGN"}<1){
	return(1,"empty HSSP");
    }

#     &hsspRdProf_debug("head")    if (! $LnoHead && 
# 				    ($LdebugWrtHead || (defined $modeDebug && $modeDebug=~/all|head/)));

				# store info
    $hssp{"numres"}=$hssp{"SEQLENGTH"};
    $hssp{"numali"}=$hssp{"NALIGN"};
				# --------------------------------------------------
				# read pairs
				# note: all variable global!
				# --------------------------------------------------
    ($Lok,$msg)=&hsspRdProf_pair(); return(&errSbr("file=$fileInLoc: problem with hsspRdProf_pair:".
					       $msg."\n",$SBR2)) if (! $Lok);
    &hsspRdProf_debug("pair")       if (! $LnoPair && 
				    ($LdebugWrtPair || (defined $modeDebug && $modeDebug=~/all|pair/)));
				# --------------------------------------------------
				# read alignments
				# --------------------------------------------------

				# digest what to read
    undef %tmp;
				# in  GLOBAL: $hssp{"ali",$num}
				# out GLOBAL: $tmp{"chain",$chain}=1 -> read chain, undefined else
				# out GLOBAL: $tmp{"ali",$num}=1     -> read protein, undefined else
				# out GLOBAL: @wantNum=   numbers for alignments to read
				# out GLOBAL: @wantBlock= num of blocks with alignments to read
    ($Lok,$msg)=
	&hsspRdProf_aliPre(
			  );    return(&errSbr("file=$fileInLoc: problem with hsspRdProf_aliPre:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# finally go off reading
				# in GLOBAL: $tmp{"chain",$chain}=1 -> read chain, undefined else
				# in GLOBAL: $tmp{"ali",$num}=1     -> read protein, undefined else
				# in GLOBAL: @wantNum=   numbers for alignments to read
				# in GLOBAL: @wantBlock= num of blocks with alignments to read
    ($Lok,$msg)=&hsspRdProf_ali(
			       );return(&errSbr("file=$fileInLoc: problem with hsspRdProf_ali:".
						$msg."\n",$SBR2)) if (! $Lok);
    &hsspRdProf_debug("ali")     if ($LdebugWrtAli || (defined $modeDebug && $modeDebug=~/all|ali/));
	

    $#exclLoc=0;		# correct number of alis for chains 
				#    see end of routine

    if (! $LnoAli){		# correct missing parts
	foreach $itali (1..$hssp{"NALIGN"}){
	    $tmp="";
	    foreach $it (1..$hssp{"ali","numres"}){
		if    (! defined $hssp{"ali",$itali,$it}){
		    $hssp{"ali",$itali,$it}=$hsspRdProf_ini{"symbolInsertion"};}
		elsif ($hssp{"ali",$itali,$it} eq " "){
		    $hssp{"ali",$itali,$it}=$hsspRdProf_ini{"symbolInsertion"};}
		$tmp.=$hssp{"ali",$itali,$it};
	    }
				# not aligned to chain
	    if (($hsspRdProf_ini{"symbolInsertion"} eq "." && $tmp=~/^\.+$/) ||
		    ($hsspRdProf_ini{"symbolInsertion"} ne "." && 
		     $tmp=~/^$hsspRdProf_ini{"symbolInsertion"}+$/)){
		$exclLoc[$itali]=1;}
	}}
    
				# --------------------------------------------------
				# read profiles
				# --------------------------------------------------
    ($Lok,$msg,$LisEOF)=
	&hsspRdProf_prof(
			);      return(&errSbr("file=$fileInLoc: problem with hsspRdProf_prof:".
					       $msg."\n",$SBR2)) if (! $Lok);
    &hsspRdProf_debug("prof")    if (! $LnoProf      &&
				    ($LdebugWrtProf || 
				     (defined $modeDebug && $modeDebug=~/all|prof/)));

				# ------------------------------------------------------------
				# read insertions
				# ------------------------------------------------------------
    if (! $LnoIns){
	($Lok,$msg,@insMax)=
	    &hsspRdProf_ins();   return(&errSbr("file=$fileInLoc: problem with hsspRdProf_ins:".
					       $msg."\n",$SBR2)) if (! $Lok);
    }

    close($fhinLoc);		# finally close the file

				# --------------------------------------------------
				# get number of 'special' family members
				#     kwd=/dist=INT,distMode=le/ for distant members
				# --------------------------------------------------
#    ($Lok,$msg)=
#	&hsspRdProf_getNfar($distCount,$distCountMode
#			   );   return(&errSbr("file=$fileInLoc: problem with hsspRdProf_getNfar:".
#					       $msg."\n",$SBR2)) if (! $Lok);
				# HACK
    ($Lok,$msg)=
	&hsspRdProf_getNfar($distCount,$distCountMode,@otherDistance
			   );   return(&errSbr("file=$fileInLoc: problem with hsspRdProf_getNfar:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# ------------------------------------------------------------
				# fill in insertions asf
				# ------------------------------------------------------------
    if (! $LnoIns && ! $LnoAli && $#wantNum){
	($Lok,$msg)=
	    &hsspRdProf_fill(@insMax
			   );   return(&errSbr("file=$fileInLoc: problem with hsspRdProf_fill:".
					       $msg."\n",$SBR2)) if (! $Lok);
    }

				# --------------------------------------------------
				# correct number of alis if chain to be read
				# --------------------------------------------------
				# correct alignment (for chains)
    if ($#exclLoc>=1){
	$ctali=0;
				# pair info
	foreach $itali (1..$hssp{"NALIGN"}){
	    next if (defined $exclLoc[$itali]);
	    ++$ctali;
				# pair info
	    if (! $LnoPair){
		foreach $kwd (@hsspRdProf_iniKwdPair){
		    $hssp{$kwd,$ctali}=$hssp{$kwd,$itali};}}
				# ali info
	    if (! $LnoAli){
		foreach $kwd ("ali"){
		    foreach $itres (1..$hssp{"ali","numres"}){
			$hssp{$kwd,$ctali,$itres}=$hssp{$kwd,$itali,$itres};}}}
				# fill 
	    if (! $LnoAliFill){
		foreach $kwd ("fin"){
		    $hssp{$kwd,$ctali}=$hssp{$kwd,$itali};}}
	}
				# CHANGE number of alis!!!
	$hssp{"numali"}=$hssp{"NALIGN"}=$ctali;
    }
				# clean up
    $#wantNum=$#wantBlock=$#wantNumLoc=
	$#insMax=$#tmp=0;	# slim-is-in

    return(1,"ok $SBR2");
}				# end of hsspRdProf

#===============================================================================
sub hsspRdProf_ini {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_ini               PROF2 specific: initialises stuff necessary to read HSSP
#       out GLOBAL:             %hsspRdProf_ini
#       out GLOBAL:             @hsspRdProf_iniKwdHdr,@hsspRdProf_iniKwdPair,
#       out GLOBAL:             @hsspRdProf_iniKwdAli,@hsspRdProf_iniKwdPair,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."hsspRdProf_iniHere";

    undef %hsspRdProf_ini;
				# settings describing format HEADER
    @hsspRdProf_iniKwdHdr= 
	(
	 "PDBID","DATE","SEQBASE","THRESHOLD",
	 "REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
	 "SEQLENGTH","NCHAIN","KCHAIN","NALIGN"
	 );

    foreach $kwd (@hsspRdProf_iniKwdHdr){
	$hsspRdProf_ini{"head",$kwd}=1;
    }
    
				# HEADER pair information
    @hsspRdProf_iniKwdPair= 
	(
#	 "NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
#	 "JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN"

	 "ID","STRID","IDE","WSIM","IFIR","ILAS","LALI","NGAP","LGAP","LSEQ2","PROTEIN"
	 );
    foreach $kwd (@hsspRdProf_iniKwdPair){
	$hsspRdProf_ini{"pair",$kwd}=1;
    }
				# ALI information
    @hsspRdProf_iniKwdAli= 
	(
	 "PDBNo","SeqNo","chain","seq","sec","acc","ali"
	 );
    foreach $kwd (@hsspRdProf_iniKwdAli){
	$hsspRdProf_ini{"ali",$kwd}=1;
    }
				# PROF information
    @hsspRdProf_iniKwdProf= 
	(
#	 "SeqNo","PDBNo",
	 "V","L","I","M","F","W","Y","G","A","P",
	 "S","T","C","H","R","K","Q","E","N","D",
	 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT"
	 );
    foreach $kwd (@hsspRdProf_iniKwdProf){
	$hsspRdProf_ini{"prof",$kwd}=1;
    }


    $hsspRdProf_ini{"regexpBegPair"}=   "^\#\# PROTEINS";           # begin of reading 
    $hsspRdProf_ini{"regexpEndPair"}=   "^\#\# ALIGNMENTS";         # end of reading

    $hsspRdProf_ini{"regexpLongId"}=    "^PARAMETER  LONG-ID :YES"; # identification of long id

    $hsspRdProf_ini{"regexpBegAli"}=    "^\#\# ALIGNMENTS";         # begin of reading
    $hsspRdProf_ini{"regexpEndAli"}=    "^\#\# SEQUENCE PROFILE";   # end of reading
    $hsspRdProf_ini{"regexpSkip"}=      "^ SeqNo";                  # skip lines with pattern
    $hsspRdProf_ini{"nmaxBlocks"}=      100;	                # maximal number of blocks considered (=7000 alis!)
    $hsspRdProf_ini{"regexpProfNames"}= "^ SeqNo";                  # lines with description of profile columns 
    $hsspRdProf_ini{"nmaxRes"}=       10000;	                # maximal number of residues (only if ONLY prof to read)

    $hsspRdProf_ini{"regexpBegIns"}=    "^\#\# INSERTION LIST";     # begin of reading insertion list
    $hsspRdProf_ini{"regexpInsNames"}=  "^ AliNo  IPOS";            # lines with description of profile columns 

    $hsspRdProf_ini{"regexpEndIns"}=    "^\/\/";                    # end of reading insertion list
    

    $hsspRdProf_ini{"lenStrid"}=          4;	# minimal length to identify PDB identifiers
    $hsspRdProf_ini{"LisLongId"}=         0;	# long identifier names

    $hsspRdProf_ini{"symbolInsertion"}= ".";        # symbol used for insertions

				# pointers

				# column numbers
    $hsspRdProf_ini{"ptr","IDE"}=       1;
    $hsspRdProf_ini{"ptr","WSIM"}=      2;
    $hsspRdProf_ini{"ptr","IFIR"}=      3;
    $hsspRdProf_ini{"ptr","ILAS"}=      4;
    $hsspRdProf_ini{"ptr","JFIR"}=      5;
    $hsspRdProf_ini{"ptr","JLAS"}=      6;
    $hsspRdProf_ini{"ptr","LALI"}=      7;
    $hsspRdProf_ini{"ptr","NGAP"}=      8;
    $hsspRdProf_ini{"ptr","LGAP"}=      9;
    $hsspRdProf_ini{"ptr","LSEQ2"}=    10;
    $hsspRdProf_ini{"ptr","ACCNUM"}=   11;
    $hsspRdProf_ini{"ptr","PROTEIN"}=  12;

				# position of character in line
    $hsspRdProf_ini{"pos","STRIDlong"}= 49;	# number of characters where to find STRID in LONG-ID

    $hsspRdProf_ini{"ptr","SeqNo"}=     1;
    $hsspRdProf_ini{"ptr","PDBNo"}=     7;
    $hsspRdProf_ini{"ptr","chain"}=    13;
    $hsspRdProf_ini{"ptr","seq"}=      15;
    $hsspRdProf_ini{"ptr","sec"}=      18;
    $hsspRdProf_ini{"ptr","acc"}=      37;
    $hsspRdProf_ini{"ptr","ali"}=      52;

    $hsspRdProf_ini{"ptr","prof"}=     14;
    $hsspRdProf_ini{"ptr","profchain"}=12;

				# column numbers
    $hsspRdProf_ini{"ptr","ins","alino"}=1;
    $hsspRdProf_ini{"ptr","ins","ipos"}= 2;
    $hsspRdProf_ini{"ptr","ins","jpos"}= 3;
    $hsspRdProf_ini{"ptr","ins","len"}=  4;
    $hsspRdProf_ini{"ptr","ins","seq"}=  5;

    $modeSec=     $par{"modeSec"};

    return(1,"ok $SBR3");
}				# end of hsspRdProf_ini

#===============================================================================
sub hsspRdProf_debug {
    local($modeDebugLoc)=@_;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_debug             writes debug and dies
#       in:                     $modeDebugLoc=[all|head|pair|seq|ali|prof|ins|nfar]
#                                           if any set: will write info, and stop!
#       in GLOBAL:              ALL (%hssp= results)
#       out GLOBAL:             ALL
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5="hsspRdProf_debug";
    if ($modeDebugLoc && $modeDebugLoc=~/head/){
	foreach $kwd (@hsspRdProf_iniKwdHdr){
	    print $FHTRACE2 "dbg $SBR5: $kwd=",$hssp{$kwd},"\n";
	}}
    if ($modeDebugLoc && $modeDebugLoc=~/pair/){
	foreach $it (1..$hssp{"NALIGN"}){
	    printf "dbg $SBR5: %3d ",$it;
	    foreach $kwd (@hsspRdProf_iniKwdPair){
		if (! defined $hssp{$kwd,$it}){
		    print $FHTRACE2 "-*- WARN not defined it=$it, kwd=$kwd\n";
		    next;}
		print $FHTRACE2 $hssp{$kwd,$it}," ";
	    }
	    print $FHTRACE2 "\n";
	}}
    if ($modeDebugLoc && $modeDebugLoc=~/ali/){
	print $FHTRACE2 "dbg $SBR5:seq,sec,acc\n";
	foreach $it(1..$hssp{"SEQLENGTH"}){
	    foreach $kwd (@hsspRdProf_iniKwdAli){
		next if ($kwd eq "ali");
		next if ($kwd eq "seq" && $LnoSeq);
		next if ($kwd eq "sec" && $LnoSec);
		next if ($kwd eq "acc" && $LnoAcc);
		print $FHTRACE2 $hssp{$kwd,$it},"\t";
	    }
	    print"\n";
	}
	if (! $LnoAli){
	    print $FHTRACE2 "dbg $SBR5:ali\n";
	    foreach $itali (1..$hssp{"NALIGN"}){
		$seq="";
		foreach $it (1..$hssp{"ali","numres"}){
		    if    (! defined $hssp{"ali",$itali,$it}){
			$hssp{"ali",$itali,$it}=$hsspRdProf_ini{"symbolInsertion"};}
		    elsif ($hssp{"ali",$itali,$it} eq " "){
			$hssp{"ali",$itali,$it}=$hsspRdProf_ini{"symbolInsertion"};}
		    $seq.=$hssp{"ali",$itali,$it};
		}
		printf "dbg %3d %-s\n",$itali,substr($seq,1,80);}
	    print $FHTRACE2 "dbg $SBR5: seq restricted to 80 residues!\n";
	}}
    
    if ($modeDebugLoc && $modeDebugLoc=~/prof/){
	print $FHTRACE2 "dbg $SBR5:prof\n";
	foreach $itRes (1..$hssp{"ali","numres"}){
	    printf "dbg: %4d prof:",$itRes;
	    foreach $kwd (@hsspRdProf_iniKwdProf){
		$tmp=3; $tmp=1+length($hssp{"prof",$kwd,$itRes}) if (length($hssp{"prof",$kwd,$itRes})>3);
		printf "%".$tmp."s",$hssp{"prof",$kwd,$itRes};}
	    print $FHTRACE2 "\n";
	}}

    if ($modeDebugLoc && $modeDebugLoc=~/ins/){
	print $FHTRACE2 "dbg $SBR5:ins\n";
	foreach $itali (1..$hssp{"NALIGN"}){
	    $seq="";
	    foreach $it (1..$hssp{"ali","numres"}){
		if    (! defined $hssp{"ali",$itali,$it}){
		    $hssp{"ali",$itali,$it}=$hsspRdProf_ini{"symbolInsertion"};}
		elsif ($hssp{"ali",$itali,$it} eq " "){
		    $hssp{"ali",$itali,$it}=$hsspRdProf_ini{"symbolInsertion"};}
		$seq.=$hssp{"ali",$itali,$it};
	    }
	    printf "dbg %3d %-s\n",$itali,substr($seq,1,80);}
	print $FHTRACE2 "dbg $SBR5: seq restricted to 80 residues!\n"; }

    if ($modeDebugLoc && $modeDebugLoc=~/nfar/){
	print $FHTRACE2 "dbg $SBR5: nfar ($distCount,$distCountMode) ndist=",$hssp{"ndist"},",\n";
	foreach $tmp (@tmpChain){
	    print $FHTRACE2 "dbg $SBR5: chain=$tmp, number of members=",$hssp{"ndist",$tmp},"\n";
	}}

    if ($modeDebugLoc && $modeDebugLoc=~/fill/){
	print $FHTRACE2 "dbg $SBR5:fill\n";
	foreach $itali (0..$hssp{"NALIGN"}){
	    printf "dbg %3d %-s\n",$itali,substr($hssp{"fill",$itali},1,80);
	}}

    return(1,"ok $SBR5");
}				# end of hsspRdProf_debug

#===============================================================================
sub hsspRdProf_getNfar {
    local($distLoc,$distModeLoc,@otherDist)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_getNfar              
#       in:                     $chainInLoc  : chain to read
#                                   '*' for omitting the test
#       in:                     $distLoc     : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $chainInLoc:  current chain
#       in:                     $distModeLoc: [gt|ge|lt|le]: if mode=gt: all with
#                                             dist > distLoc counted
#                                   '0' for omitting the test
#       in GLOBAL:              ALL (%hssp= results)
#       out GLOBAL:             ALL
#       in:                     $fileInLoc
#       out:                    1|0,msg,$num,$take:
#                               $num= number of alis in chain and below $distLoc
#                               $take='n,m,..': list of pairs ok
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRdProf_getNfar";

				# ------------------------------
				# get chains
    $take="";
    if ($Lchain){
	$tmp=$hssp{'chain'};
	$tmp=~s/,*$//g;
	$tmp=~s/\s//g;
	@tmpChain=split(/,/,$tmp);}
    else {
	@tmpChain=("*");
    }
    $hssp{"ndist"}=             0;
    if ($#otherDist){
	foreach $otherDistance (@otherDist){
	    $hssp{"ndist",$otherDistance}=0;}
	undef %otherDist;}

				# --------------------------------------------------
				# get number of distant alignments
				# --------------------------------------------------
    foreach $chainInLoc (@tmpChain){
	next if (length($chainInLoc)<1);
	foreach $itali (1..$hssp{"pair","numali"}){
				# ------------------------------
				# (1) is it aligned to chain?
	    next if ($Lchain &&
		     (($hssp{"IFIR",$itali} > $hssp{"chain",$chainInLoc,"endSeqNo"}) ||
		      ($hssp{"ILAS",$itali} < $hssp{"chain",$chainInLoc,"begSeqNo"}) ));
				# ------------------------------
				# (2) is it correct distance?
	    if ($distModeLoc){
		$lali= $hssp{"LALI",$itali}; 
		$pide= 100*$hssp{"IDE",$itali};
		return(&errSbr("distModeLoc=$distModeLoc, pair=$itali, no lali|ide ($lali,$pide)",$SBR3))
		    if (! defined $lali || ! defined $pide);
                                # compile distance to HSSP threshold (new)
		($pideCurve,$msg)= 
		    &getDistanceNewCurveIde($lali);
		return(&errSbrMsg("failed on getDistanceNewCurveIde($lali)\n".$msg."\n",$SBR3))
		    if (! $pideCurve && ($msg !~ /^ok/));
	    
		$dist=$pide-$pideCurve;
				# other
		if ($#otherDist){
		    foreach $otherDist (@otherDist){
			$otherDist{$otherDist}=0 if (! defined $otherDist{$otherDist});
			next if (($distModeLoc eq "gt" && $dist <= $otherDist) ||
				 ($distModeLoc eq "ge" && $dist <  $otherDist) ||
				 ($distModeLoc eq "lt" && $dist >= $otherDist) ||
				 ($distModeLoc eq "le" && $dist >  $otherDist)); 
			++$otherDist{$otherDist};}}
				# mode
		next if (($distModeLoc eq "gt" && $dist <= $distLoc) ||
			 ($distModeLoc eq "ge" && $dist <  $distLoc) ||
			 ($distModeLoc eq "lt" && $dist >= $distLoc) ||
			 ($distModeLoc eq "le" && $dist >  $distLoc)); 
	    }
				# ------------------------------
				# (3) ok, take it
	    $take.=$itali.","; 
	}

	$num=0;
	if ($take=~/,/){
	    $take=~s/^,*|,*$//g;
	    @tmp=split(/,/,$take);
	    $num=$#tmp;}
	$hssp{"ndist",$chainInLoc}= $num;
	$hssp{"ndist"}=             0 if (! defined $hssp{"ndist"});
	$hssp{"ndist"}+=            $num;
	if ($#otherDist){
	    foreach $otherDist (@otherDist){
		$hssp{"ndist",$otherDist}=$otherDist{$otherDist};
	    }}
    }

    undef @tmp;		# slim-is-in!

    return(1,"ok $SBR3");
}				# end of hsspRdProf_getNfar

#===============================================================================
sub hsspRdProf_head {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_head                 read section with HEADER info
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRdProf_head";
				# ------------------------------------------------------------
				# read header
				# ------------------------------------------------------------
    $ctRd=0;			# force reading "NALIGN" "SEQLENGTH"
    $ctMinRead=2;
    $hsspRdProf_ini{"head","SEQLENGTH"}=1;
    $hsspRdProf_ini{"head","NALIGN"}=   1;

    while ( <$fhinLoc> ) {
				# finish this part if pairs start
	last if ($_=~ /$hsspRdProf_ini{"regexpBegPair"}/); 
				# skip reading
	next if ($LnoHead && $ctRd < $ctMinRead);
	chop; $line=$_;
	$kwd=$_; $kwd=~s/^(\S+)\s+(.*)$/$1/;
	undef $remain;
	$remain=$2              if (defined $2);
				# line to read
	if (defined $hsspRdProf_ini{"head",$kwd}){
	    next if (! defined $remain);
	    $tmp=$remain;
	    $tmp=~s/^\s*|\s*$//g;
				# purge non digits
	    if ($kwd=~/SEQLENGTH/ ||
		$kwd=~/NCHAIN/ ||
		$kwd=~/NALIGN/){
		$tmp=~s/(\d+)\D*.*$/$1/;}
	    $hssp{$kwd}=$tmp;
	    ++$ctRd;
	    next;}
				# is long id
	if ($line =~ /$hsspRdProf_ini{"regexpLongId"}/) {
	    $LisLongId=1;
	    next; }
    }				# end of HEADER
    
				# ------------------------------
				# correct errors (holm)
    if (defined $hsspRdProf_ini{"head","KCHAIN"} &&
	! defined $hssp{"KCHAIN"}){
	$hssp{"KCHAIN"}=1;
    }

    return(1,"ok $SBR3");
}				# end of hsspRdProf_head

#===============================================================================
sub hsspRdProf_pair {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_pair                 read HEADER pair info
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRdProf_pair";

				# switch on reading ids if to read ali
    $LwantAliById=0;
    if ($LnoPair && ! $LnoAli &&
	$kwdInLoc && $kwdInLoc=~/ali=[A-Za-z0-9][A-Za-z0-9]+/){
	$LnoPair=0;
	$hsspRdProf_ini{"pair","ID"}=1;
	$LwantAliById=1;}
				# now read
    $ctAli=0;
    while ( <$fhinLoc> ) { 
				# finish this part if end of pair (begin of ali)
	last if ($_ =~ /$hsspRdProf_ini{"regexpEndPair"}/); 
				# supress reading pair info
	next if ($LnoPair);
				# skip descriptors
	next if ($_ =~ /^  NR\./);
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine      if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {
	    $id=$beg;$id=~s/([^\s]+).*$/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g;
	    $strid=0            if ($strid=~/^\s*$/);}
	else              {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($line,$hsspRdProf_ini{"pos","STRIDlong"},6);$strid=~s/\s//g; 
	    $strid=0            if ($strid=~/^\s*$/);}
	if ($strid){
	    $tmp=$hsspRdProf_ini{"lenStrid"}-1;
	    if ( (length($strid)<$hsspRdProf_ini{"lenStrid"}) && 
		($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
		$strid=substr($id,1,$hsspRdProf_ini{"lenStrid"}); }}
	++$ctAli;
	$hssp{"numali"}=$hssp{"pair","numali"}=$ctAli;

	if (defined $hsspRdProf_ini{"pair","ID"}){
	    $hssp{"ID",$ctAli}=     $id;}
	if (defined $hsspRdProf_ini{"pair","STRID"}){
	    $strid=""           if (! $strid);
	    $hssp{"STRID",$ctAli}=  $strid;
				# correct for ID = PDBid
	    $hssp{"STRID",$ctAli}=  $id if ($strid=~/^\s*$/ && 
					 $id=~/\d\w\w\w.?\w?$/);}
	if (defined $hsspRdProf_ini{"pair","PROTEIN"}){
	    $hssp{"PROTEIN",$ctAli}=$end; }
	if (defined $hssp{"PDBID"}){
	    $hssp{"ID1",$ctAli}=    $hssp{"PDBID"};}
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {
	    $_=~s/\s//g;}

	foreach $kwd (@hsspRdProf_iniKwdPair){
	    next if (! defined $hsspRdProf_ini{"ptr",$kwd});
	    next if (! defined $hsspRdProf_ini{"pair",$kwd});
	    $ptr=$hsspRdProf_ini{"ptr",$kwd};
	    $val=$tmp[$ptr]; 
	    $val=~s/\s//g if ($kwd !~/PROTEIN/);
	    $hssp{$kwd,$ctAli}=$val;
				# store for 'want ali by id'
	    $hssp{"ali",$val}=$ctAli if ($LwantAliById);
	}
    }				# end of PAIRS

    return(1,"ok $SBR3");
}				# end of hsspRdProf_pair

#===============================================================================
sub hsspRdProf_aliPre {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_aliPre               finds out what to read
#       in GLOBAL:              $hssp{"ali",$num}
#       out GLOBAL:             $tmp{"chain",$chain}=1 if that chain to read 
#                                   else: undefined
#       out GLOBAL:             $tmp{"ali",$num}=1 if that protein to read (by number)
#                                   else: undefined
#       out GLOBAL:             @wantNum=   numbers for alignments to read
#       out GLOBAL:             @wantBlock= numbers of blocks which contain alignments to read
#       out GLOBAL:             
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRdProf_aliPre";

				# ------------------------------
				# read particular chain?
    $Lchain=0;

    if ($kwdInLoc && $kwdInLoc=~/(chain|chn)=(.+)/){
	if (! defined $2){
	    print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, missing chain?\n";}
	else { $tmp=$2;
	       $tmp=~s/([A-Z0-9,\*]+)(no|ali|seq|sec|acc)*.*$/$1/g;
	       if ($tmp !~/[A-Z0-9\*]/){
		   print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, chain=$tmp?\n";}
	       else {
		   $tmp=~s/^,|,$//g;
		   foreach $tmp (split(/,/,$tmp)){
		       $tmp{"chain",$tmp}=1;
		   }
		   $Lchain=1;
	       }}}
				# ------------------------------
				# read particular ali?
    $LaliNo= 0;
    if (! $LnoAli && $kwdInLoc && $kwdInLoc=~/ali=(.+)/){
	if (! defined $1){
	    print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, missing ali=?\n";}
	else { $tmp=$1;
				# mode 1: given by number
	       if ($tmp=~/^\d+$/    || 
		   $tmp=~/^\d+[\-,]/){
		   @tmp2=split(/[,]/,$tmp);
		   $#tmp=0;
		   foreach $tmp (@tmp2){
				# finish if not number
		       last if ($tmp !~/^\d+$/ && 
				$tmp !~/^\d+\-\d+/);
				# is range
		       if ($tmp=~/^(\d+)\-(\d+)$/){
			   foreach $it ($1..$2){
			       push(@tmp,$it);
			   }}
				# is single number
		       else {
			   push(@tmp,$tmp);}}
		   if ($#tmp > 0){
		       $LaliNo=1;
		       foreach $tmp (@tmp){
			   $tmp{"ali",$tmp}=1;
		       }}}
				# mode 2: given id
	       else {
		   $#tmp=0;
		   @tmp2=split(/[,]/,$tmp);
		   foreach $tmp (@tmp2){
				# finish if not id
		       last if ($tmp !~ /^[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]/);
		       next if (! defined $hssp{"ali",$tmp} ||
				$hssp{"ali",$tmp}!~/^\d+$/);
		       $it=$hssp{"ali",$tmp};
		       push(@tmp,$it);}
		   if ($#tmp > 0){
		       $LaliNo=1;
		       foreach $tmp (@tmp){
			   $tmp{"ali",$tmp}=1;
		       }}
	       }
	       if ($LaliNo && $#tmp > 0){
				# get numbers to take
		   @wantNum=sort bynumber (@tmp);
		   $#tmp=0;
				# get blocks to take
		   $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
		   foreach $ctBlock (1..$hsspRdProf_ini{"nmaxBlocks"}){
		       $beg=1+($ctBlock-1)*70;
		       $end=$ctBlock*70;
		       last if ($wantLast < $beg);
		       $Ltake=0;
		       foreach $num (@wantNum){
			   if ( ($beg<=$num) && ($num<=$end) ){
			       $Ltake=1;
			       last;}}
		       if ($Ltake){
			   $wantBlock[$ctBlock]=1;}
		       else{
			   $wantBlock[$ctBlock]=0;}}
	       }
	   }}
				# read all blocks
    elsif (! $LnoAli){
	foreach $ctBlock (1..$hsspRdProf_ini{"nmaxBlocks"}){
	    $wantBlock[$ctBlock]=1;}
	$#wantNum=0;
	foreach $ctAli (1..$hssp{"NALIGN"}){
	    push(@wantNum,$ctAli);}
    }

    $#tmp=$#tmp2=0;		# slim-is-in
    return(1,"ok $SBR3");
}				# end of hsspRdProf_aliPre

#===============================================================================
sub hsspRdProf_ali {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_ali                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       in GLOBAL:              $tmp{"chain",$chain}=1 if that chain to read 
#                                   else: undefined
#       in GLOBAL:              $tmp{"ali",$num}=1 if that protein to read (by number)
#                                   else: undefined
#       in GLOBAL:              @wantNum=   numbers for alignments to read
#       in GLOBAL:              @wantBlock= numbers of blocks which contain alignments to read
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRdProf_ali";

    $ctRes=  0;
    $ctBlock=1;
				# ------------------------------
				# check what to read of first block
    if (! $LnoAli && $wantBlock[$ctBlock]){
				# out GLOBAL: @wantNumLoc: relative position of ali to read
	($Lok,$msg,$LreadBlock,$numFirstAli,$numLastAli)=
	    &hsspRdProf_aliBlockIni
		(0,$ctBlock);   return(&errSbr("file=$fileInLoc: problem with hsspRdProf_aliBlockIni:".
					       $msg."\n",$SBR3)) if (! $Lok); 
    }

				# ------------------------------------------------------------
				# read ALIGNMENT section
				# ------------------------------------------------------------
    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;
				# ------------------------------
				# end of alignments
	last if ($line=~/$hsspRdProf_ini{"regexpEndAli"}/); 

				# skip line
	next if ($line=~/$hsspRdProf_ini{"regexpSkip"}/);
				# ------------------------------
				# new alignment block 
	if (! $LnoAli && $line=~/$hsspRdProf_ini{"regexpBegAli"}/){
	    ++$ctBlock;
	    $numLastAli=0;
	    $LreadBlock=0;
	    $ctRes=     0;	# reset counting of residues!

	    if ($wantBlock[$ctBlock]) {
				# out GLOBAL: @wantNumLoc: relative position of ali to read
		($Lok,$msg,$LreadBlock,$numFirstAli,$numLastAli)=
		    &hsspRdProf_aliBlockIni($line,$ctBlock); 
				# hack error in HSSP
		return(&errSbr("file=$fileInLoc: problem with hsspRdProf_aliBlockIni:".
			       $msg."\n",$SBR3)) if (! $Lok);}
	    next;		# skip rest of line
	}
	elsif ($line=~/$hsspRdProf_ini{"regexpBegAli"}/){
	    $ctRes=     0;	# reset counting of residues!
	    next; }
				# ------------------------------
				# chain
        $chainRd=substr($line,$hsspRdProf_ini{"ptr","chain"},1);  # grep out chain identifier
	next if ( $Lchain && ! defined $tmp{"chain",$chainRd});
	++$ctRes;
	$hssp{"ali","numres",$ctBlock}=$ctRes;
				# ------------------------------
				# mark begin and end of chain
	if ($Lchain) { $hssp{"chain"}=""            if (! defined $hssp{"chain"});
		       if (! defined $hssp{"chain",$chainRd,"beg"}){
			   $hssp{"chain"}.=              $chainRd.",";
			   $hssp{"chain",$chainRd,"beg"}=$ctRes;}
		       $hssp{"chain",$chainRd,"end"}=    $ctRes; }
	$hssp{"chain",$ctRes}=$chainRd if (defined $hsspRdProf_ini{"ali","chain"});
				# ------------------------------
				# read sequence, sec str, acc
				# only for first block!
	if ($ctBlock==1){
	    $hssp{"ali","numres"}=$hssp{"numres"}=$hssp{"NROWS"}=$ctRes;
	    ($Lok,$msg)=
		&hsspRdProf_aliSeqSecAcc($line); 
	    return(&errSbr("file=$fileInLoc: problem with hsspRdProf_aliSeqSecAcc:".
			   $msg."\n",$SBR3)) if (! $Lok); }

				# ------------------------------
				# now to the alignments
				# ------------------------------
	next if ($LnoAli);
				# skip block
	next if (! $LreadBlock);
				# skip since no alis
	next if (length($line)<$hsspRdProf_ini{"ptr","ali"});

				# DEFAULT insertions for all positions
	foreach $numAliLoc (@wantNumLoc){
	    $hssp{"ali",($numAliLoc+$numFirstAli-1),$ctRes}=$hsspRdProf_ini{"symbolInsertion"};
	}
				# now the alignments
	$tmp=substr($line,$hsspRdProf_ini{"ptr","ali"}); 
	@tmp=split(//,$tmp);
				# NOTE: @wantNumLoc has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $numAliLoc (@wantNumLoc){
				# missing ?
	    next if ($numAliLoc > $#tmp);
				# note: numFirstAli=71 in the example above
	    $numAli= $numAliLoc+$numFirstAli-1; 
	    $hssp{"ali",$numAli,$ctRes}=$tmp[$numAliLoc];
	    $hssp{"ali",$numAli}=1 if (! defined $hssp{"ali",$numAli});
	}
    }				# end of reading the alignments and seq,sec,acc,chain

				# clean up
    $#wantNumLoc=0;		# slim-is-in

    return(1,"ok $SBR3");
}				# end of hsspRdProf_ali

#===============================================================================
sub hsspRdProf_aliBlockIni {
    local($line,$ctBlockLoc)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_aliBlockIni          new block to read?
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             @wantNumLoc: relative position of ali to read
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="hsspRdProf_aliBlockIni";
    $LreadBlock=0;
				# which numbers are in this block?
				# first block
    if (! $line){ 
	$beg=1;
	$end=70; 
	$end=$hssp{"NALIGN"} if ($hssp{"NALIGN"} < $end);}
    else {
	$tmp=$line; $tmp=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
	$beg=$1;
	$end=$2;
				# hack ERROR in HSSP
	if (defined $ctBlockLoc){
	    $beg=($ctBlockLoc-1)*70+1;
	    $end =$beg+69;
	    $end =$hssp{"NALIGN"} if ($hssp{"NALIGN"}<$end);
	}
    }
    $LreadBlock=1;
    
    $#wantNumLoc=0;		# local numbers
    foreach $num (@wantNum){
	if ( ($beg<=$num) && ($num<=$end) ){
	    $tmp=($num-$beg)+1; 
	    if ($tmp<1){
		print $FHTRACE2 
		    "-*- WARN $SBR2: negative local alignment number !\n",
		    "-*-             tmp=$tmp,$beg,$end,\n";}
	    else {
		push(@wantNumLoc,$tmp);
	    }
	}
    }
    return(1,"ok $SBR4",$LreadBlock,$beg,$end);
}				# end of hsspRdProf_aliBlockIni

#===============================================================================
sub hsspRdProf_aliSeqSecAcc {
    local($line)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_aliSeqSecAcc                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="hsspRdProf_aliSeqSecAcc";
				# get numbers
    if (defined $hsspRdProf_ini{"ali","SeqNo"}) {
	$SeqNo=  substr($line,$hsspRdProf_ini{"ptr","SeqNo"},6);
	exit if (! defined $SeqNo || length($SeqNo)<1);
	$SeqNo=~s/\s//g;
	$hssp{"SeqNo",$ctRes}=$SeqNo;
	$hssp{"chain",$chainRd,"begSeqNo"}=$SeqNo if (! defined $hssp{"chain",$chainRd,"begSeqNo"});
	$hssp{"chain",$chainRd,"endSeqNo"}=$SeqNo;}
    
    if (defined $hsspRdProf_ini{"ali","PDBNo"}) {
	$PDBNo=  substr($line,$hsspRdProf_ini{"ptr","PDBNo"},6);
	$PDBNo=~s/\s//g;
	$hssp{"PDBNo",$ctRes}=$PDBNo;}
				# for later: restrict to fragment yy
#	    next if ( $ifirLoc  && ($SeqNo < $ifirLoc));
#	    next if ( $ilasLoc  && ($SeqNo > $ilasLoc));
				# sequence
    if (! $LnoSeq && defined $hsspRdProf_ini{"ali","seq"}) {
	$hssp{"seq",$ctRes}=  substr($line,$hsspRdProf_ini{"ptr","seq"},1);}
				# secondary structure
    if (! $LnoSec && defined $hsspRdProf_ini{"ali","sec"}) {	    
	$hssp{"sec",$ctRes}=  substr($line,$hsspRdProf_ini{"ptr","sec"},1);}
				# solvent accessibility
    if (! $LnoAcc && defined $hsspRdProf_ini{"ali","acc"}) {	    
	$hssp{"acc",$ctRes}=  substr($line,$hsspRdProf_ini{"ptr","acc"},3);
	$hssp{"acc",$ctRes}=~s/\D//g; }

    return(1,"ok $SBR4");
}				# end of hsspRdProf_aliSeqSecAcc

#===============================================================================
sub hsspRdProf_prof {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_prof                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRdProf_prof";
				# ------------------------------
				# read the profile
				# ------------------------------
    $LisEOF=0;
    $ctRes=0;
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# no insertions will follow: is END of file
        if ($_=~/^$hsspRdProf_ini{"regexpEndIns"}/){
	    $LisEOF=1;
	    last;}
				# finish reading
	last if ($line=~/^$hsspRdProf_ini{"regexpBegIns"}/);
				# skip reading until end
	next if ($LnoProf);
				# ------------------------------
				# is line with column names
	if ($line=~/^$hsspRdProf_ini{"regexpProfNames"}/){
				# skip part with 'SeqNo PDBNo ' (including chain)
	    $tmp=substr($line,$hsspRdProf_ini{"ptr","prof"});
	    $tmp=~s/^\s*|\s*$//g;
	    @tmp=split(/\s+/,$tmp);
	    $#tmp_wantCol=$#tmp_kwdCol=0;
	    foreach $it (1..$#tmp){
				# not to be read
		next if (! defined $hsspRdProf_ini{"prof",$tmp[$it]});
		push(@tmp_kwdCol,$tmp[$it]);
		push(@tmp_wantCol,$it);
	    }
	    $#tmp=0;
	    next;}
				# seems to be an error
	next if (length($line)<$hsspRdProf_ini{"ptr","prof"});

				# check out chain
	if ($Lchain){
	    $chainRd=substr($line,$hsspRdProf_ini{"ptr","profchain"},1);
				# chain, in fact not to be read
	    next if (! defined $hssp{"chain",$chainRd,"beg"}); }

				# yy allow for fragment selection later yy
#	next if ( $ifirLoc  && ($SeqNo < $ifirLoc));
#	next if ( $ilasLoc  && ($SeqNo > $ilasLoc));

				# skip part with 'SeqNo PDBNo ' (including chain)
	$tmp=substr($line,$hsspRdProf_ini{"ptr","prof"});
	$tmp=~s/^\s*|\s*$//g;
	@tmp=split(/\s+/,$tmp);

	++$ctRes;
	$hssp{"prof","numres"}=$ctRes;
	foreach $it (1..$#tmp_wantCol){
	    $it_wantCol=$tmp_wantCol[$it];
	    $hssp{"prof",$tmp_kwdCol[$it_wantCol],$ctRes}=
		$tmp[$it_wantCol];
	}
    }				# end of reading profiles

				# clean up
    $#tmp=$#tmp_wantCol=$#tmp_kwdCol=0;	# slim-is-in
    return(1,"ok $SBR3",$LisEOF);
}				# end of hsspRdProf_prof

#===============================================================================
sub hsspRdProf_ins {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_ins                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    $insMax[$itres]= maximal number of insertions
#                               for residue $itres
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="lib-prof:hsspRdProf_ins";

    undef @insMax;		# note: $insMax[$SeqNo]=5 means at residue 'SeqNo'
    $numres=0;
    $numres=$hssp{"ali","numres",1}  if (! $numres && defined $hssp{"ali","numres",1});
    $numres=$hssp{"SEQLENGTH"}       if (! $numres && defined $hssp{"SEQLENGTH"});
    $numres=$hsspRdProf_ini{"nmaxRes"}   if (! $numres);

				# set number of maximal insertions to 0
    foreach $itRes (1..$numres){
	$insMax[$itRes]=0;
    }

				# ------------------------------
				# read the insertions
    while (<$fhinLoc>){
				# end reading insertion list
        last if ($_=~/^$hsspRdProf_ini{"regexpEndIns"}/); 

				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
	$line=$_; $line=~s/\n//;

				# skip line with names
	next if ($line=~/^$hsspRdProf_ini{"regexpInsNames"}/);

				# --------------------------------------------------
				# continuation of previous line
	if ($line=~/^\s+\+\s*(\S+)$/){ 
	    $seqIns.=$1;
				# number of residues inserted
	    $nresIns=(length($seqIns) - 2);
				# increase count of maximally inserted residues
	    $insMax[$ipos]=$nresIns if ($nresIns > $insMax[$ipos]);

				# NOTE: here $tmp{$it,$SeqNo} gets more than
				#       one residue assigned (ref=11)
				# change 'ACinK' -> 'ACINEWNK'
	    $hssp{"ali",$alino,$ipos}=substr($seqIns,1,(length($seqIns)-1));
	    next; }
	    
				# --------------------------------------------------
				# ERRROR should not happen (see syntax)
        if ($line !~ /^\s*\d+/) {
	    print "-*- WARN $SBR3: problem with line=$line, insertion list!\n";
	    next;}
	$tmp=$line;
				# purge leading blanks
	$tmp=~s/^\s*|\s*$//g;
				# note written into columns ' AliNo  IPOS  JPOS   Len Sequence'
	@tmp=split(/\s+/,$tmp);

	$alino=$tmp[$hsspRdProf_ini{"ptr","ins","alino"}];
				# skip since it did NOT want that one, anyway
	next if (! defined $hssp{"ali",$alino});

				# ok -> take
				# residue position in insertion
	$ipos=   $tmp[$hsspRdProf_ini{"ptr","ins","ipos"}];
				# sequence at insertion 'kQLGAEi'
	$seqIns= $tmp[$hsspRdProf_ini{"ptr","ins","seq"}];
				# number of residues inserted
	$nresIns=(length($seqIns) - 2);
				# increase count of maximally inserted residues
	$insMax[$ipos]=$nresIns if ($nresIns > $insMax[$ipos]);

				# --------------------------------------------------
				# NOTE: here $tmp{$it,$SeqNo} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$hssp{"ali",$alino,$ipos}=substr($seqIns,1,(length($seqIns)-1));
    }				# end of reading insertions

    @tmp=@insMax;
    $#insMax=0;			# slim-is-in
    return(1,"ok $SBR3",@tmp);
}				# end of hsspRdProf_ins

#===============================================================================
sub hsspRdProf_fill {
    local(@insMax)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProf_fill              fills the insertion list asf out: final alignment
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."hsspRdProf_fill";

    $numres=0;
    $numres=$hssp{"ali","numres",1}  if (! $numres && defined $hssp{"ali","numres",1});
    $numres=$hssp{"SEQLENGTH"}       if (! $numres && defined $hssp{"SEQLENGTH"});
    $numres=$hsspRdProf_ini{"nmaxRes"}   if (! $numres);

				# set to ''
    foreach $itAli (0,@wantNum){
	$hssp{"fin",$itAli}="";
    }
				# --------------------------------------------------
				# loop over residues
				# --------------------------------------------------
    foreach $itRes (1..$numres){
	$insMax=$insMax[$itRes];
				# ------------------------------
				# guide sequence
	$hssp{"fin",0}.=$hssp{"seq",$itRes};
				# dirty: fill in the end
	$hssp{"fin",0}.="." x $insMax if ($insMax);

				# ------------------------------
				# loop over all alis
	foreach $itAli (@wantNum){
	    $hssp{"fin",$itAli}.=$hssp{"ali",$itAli,$itRes};
	    $hssp{"fin",$itAli}.="." x (1 + $insMax - length($hssp{"ali",$itAli,$itRes}));
	}
    }
				# ------------------------------
				# now assign to final
    foreach $itAli (0,@wantNum){
				# replace ' ' -> '.'
	$hssp{"fin",$itAli}=~s/\s/\./g;
	next if ($itAli==0);
				# all capital for aligned (NOT for sequence)
	$hssp{"fin",$itAli}=~tr/[a-z]/[A-Z]/;
    }
				# clean up
    $#tmp=0;

    return(1,"ok $SBR3");
}				# end of hsspRdProf_fill

#===============================================================================
sub htmProcess {
    local($fileInLoc,$chainInLoc,
	  $ct_fileInLoc,$numwhiteLoc,$L3D_KNOWNloc,
	  $fhErrSbr) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmProcess                  processes the HTM prediction (filter, check
#                                  whether HTM or not, refine, get topology)
#       in:                     
#       in:                     
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."htmProcess";$fhoutLoc="FHOUT_".$SBR2;

				# check arguments
#    return(&errSbr("not def fileInLoc!",$SBR2))          if (! defined $fileInLoc);
#    return(&errSbr("not def !",$SBR2))          if (! defined $);

                                # --------------------------------------------------
                                # delete FLAG file if existing
#    $fileOutNotHtm=$par{"dirWork"}.$par{"titleTmp"}."_htmnot".$par{"extOutTmp"};

    if (defined $fileOut{$ct_fileInLoc,"not"}){
	$fileOutNotHtm=$fileOut{$ct_fileInLoc,"not"};}
    else {
	$fileOutNotHtm=$par{"dirWork"}.$par{"titleTmp"}."_htmnot".$par{"extOutTmp"};}

    if (-e $fileOutNotHtm){
	unlink ($fileOutNotHtm);
	print $fhSbrErr
	    "*** WATCH! flag file '$fileOutNotHtm' (flag for NOT htm) existed!\n"
		if ($fhSbrErr); }

                                # --------------------------------------------------
				# temporary file names
    $fileTmp{"htmsim"}=$par{"dirWork"}.$par{"titleTmp"}."_htmrdb".$par{"extOutTmp"};
    $fileTmp{"htmfin"}=$par{"dirWork"}.$par{"titleTmp"}."_htmfin".$par{"extOutTmp"};
    $fileTmp{"htmfil"}=$par{"dirWork"}.$par{"titleTmp"}."_htmfil".$par{"extOutTmp"};
    $fileTmp{"htmref"}=$par{"dirWork"}.$par{"titleTmp"}."_htmref".$par{"extOutTmp"};
    $fileTmp{"htmtop"}=$par{"dirWork"}.$par{"titleTmp"}."_htmtop".$par{"extOutTmp"};
    if (! $par{"debug"}){
	foreach $kwd ("htmsim","htmfin","htmfil","htmref","htmtop"){
	    push(@file_REMOVE,$fileTmp{$kwd});
	}}
                                # --------------------------------------------------
                                # write the file with PROF.rdb_htm
    $fileOutLoc=$fileTmp{"htmsim"};
    ($Lok,$msg)=
	&htmProcessWrttmp
	    ($fileOutLoc,
	     $L3D_KNOWNloc);	return(&errSbrMsg("failed on writing temp RDB_htm",
						  $msg,$SBR2)) if (! $Lok || ! -e $fileOutLoc);

                                # --------------------------------------------------
				# postprocess
    ($Lok,$msg,$LisHtm)=
	&htmProcessPost
	    ($fileInLoc,$chainInLoc,$fileTmp{"htmsim"},$par{"dirScrLib"},$par{"optNice"},
#	     $par{"exeHtmfil"},
	     $par{"exeHtmref"},$par{"exeHtmtop"},
#	     $par{"optDoHtmfil"},
	     $par{"optDoHtmisit"},$par{"optHtmisitMin"},
	     $par{"optDoHtmref"},$par{"optDoHtmtop"},
	     $fileOutNotHtm,
	     $fileTmp{"htmfin"},$fileTmp{"htmfil"},$fileTmp{"htmref"},$fileTmp{"htmtop"},
	     $par{"fileOutScreen"},
	     $FHPROG);		return(&errSbrMsg("failed on htmProcessPost($fileOutLoc)",
						  $msg,$SBR2)) if (! $Lok);
    return(1,"ok $SBR2");
}				# end of htmProcess

#==============================================================================
sub htmProcessPost {
    local($fileHssp,$chainHssp,$fileInRdbLoc,$dirLib,$optNiceInLoc,
	  $exeHtmrefLoc,$exeHtmtopLoc,
          $LdoHtmisitLoc,$optHtmisitMinLoc,$LdoHtmrefLoc,$LdoHtmtopLoc,
          $fileOutNotLoc,$fileOutRdbLoc,$fileTmpFil,$fileTmpRef,$fileTmpTop,
	  $fileOutScreenLoc,$fhSbrErr) = @_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmProcessPost                       
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $fileInRdbLoc  : RDB file from PHD fortran
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress
#       in:                     $optNiceLoc    : priority 'nonice|nice|nice-n'
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#       in:                     $LdoHtmfil     : 1|0 do or do NOT run
#       in:                     $LdoHtmisit    : 1|0 do or do NOT run
#       in:                     $optHtmMinVal  : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $LdoHtmref     : 1|0 do or do NOT run
#       in:                     $LdoHtmtop     : 1|0 do or do NOT run
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#       in:                     $fileOutRdbLoc : final RDB file
#       in:                     $fileTmpFil    : temporary file from htmfil
#       in:                     $fileTmpIsit   : temporary file from htmfil
#       in:                     $fileTmpRef    : temporary file from htmfil
#       in:                     $fileTmpTop    : temporary file from htmfil
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="lib-prof:"."htmProcessPost"; 
    $fhinLoc="FHIN_".$SBR3; $fhoutLoc="FHOUT_".$SBR3;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!",        $SBR3))     if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!",       $SBR3))     if (! defined $chainHssp);
    return(&errSbr("not def fileInRdbLoc!",    $SBR3))     if (! defined $fileInRdbLoc);
    return(&errSbr("not def dirLib!",          $SBR3))     if (! defined $dirLib);
    return(&errSbr("not def optNiceInLoc!",    $SBR3))     if (! defined $optNiceInLoc);

#    return(&errSbr("not def exeHtmfilLoc!",    $SBR3))     if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmrefLoc!",    $SBR3))     if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!",    $SBR3))     if (! defined $exeHtmtopLoc);

#    return(&errSbr("not def LdoHtmfilLoc!",    $SBR3))     if (! defined $LdoHtmfilLoc);
    return(&errSbr("not def LdoHtmisitLoc!",   $SBR3))     if (! defined $LdoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!",$SBR3))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def LdoHtmrefLoc!",    $SBR3))     if (! defined $LdoHtmrefLoc);
    return(&errSbr("not def LdoHtmtopLoc!",    $SBR3))     if (! defined $LdoHtmtopLoc);

    return(&errSbr("not def fileOutNotLoc!",   $SBR3))     if (! defined $fileOutNotLoc);
    return(&errSbr("not def fileOutRdbLoc!",   $SBR3))     if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileTmpFil!",      $SBR3))     if (! defined $fileTmpFil);
    return(&errSbr("not def fileTmpRef!",      $SBR3))     if (! defined $fileTmpRef);
    return(&errSbr("not def fileTmpTop!",      $SBR3))     if (! defined $fileTmpTop);
				# ------------------------------
				# input files existing ?
#    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
#    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
#    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (! &is_hssp_empty($fileHssp));
    return(&errSbr("no rdb '$fileInRdbLoc'!",$SBR3))   if (! -e $fileInRdbLoc);

                                # ------------------------------
                                # executables ok?
    foreach $exe ($exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in exe '$exe'!",$SBR3))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!",$SBR3))   if (! -l $exe && ! -x $exe ); }

				# ------------------------------
				# defaults

    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=1;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $minLenLoc=$minLenDefLoc    if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc    if (! defined $doStatLoc);


				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNiceTmp="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNiceTmp=$optNiceInLoc; 
	$optNiceTmp=~s/\s//g;
	$optNiceTmp=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNiceTmp="";}
    $fileFinalHtm=$fileInRdbLoc;

				# --------------------------------------------------
                                # is HTM ?
    if ($LdoHtmisitLoc) {       # --------------------------------------------------


	($Lok,$msg,$LisHtm,%tmp)=
	    &phdHtmIsit
		($fileInRdbLoc,$optHtmisitMinLoc,$minLenLoc,
		 $doStatLoc);	return(&errSbrMsg("failed on phdHtmIsit (file=$fileInRdbLoc,".
						  "minVal=$optHtmisitMinLoc,, minLen=$minLenLoc, ".
						  "stat=$doStatLoc",$msg,$SBR3)) if (! $Lok);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile
		($fileInRdbLoc,$fileOutRdbLoc
		 );		return(&errSbrMsg("htmisit copy",$msg,$SBR3))  if (! $Lok);

	$fileFinalHtm=$fileOutRdbLoc;

	if (! $LisHtm){
	    open($fhoutLoc,">".$fileOutNotLoc) ||
		return(&errSbr("failed creating flag file '$fileOutNotLoc'",$SBR3));
	    print $fhoutLoc
		"value of best=",$tmp{"valBest"},
		", min=$optHtmisitMinLoc, posBest=",$tmp{"posBest"},",\n";
	    close($fhoutLoc); 
				# HACK yxyxy ...
	    ($Lok,$msg)=
		&htmProcessRdtmp
		    ($fileInRdbLoc);    
	    foreach $itres (1..$prd{"NROWS"}){
		foreach $kwdxyz ("PRMN","PR2MN","PiTo"){
		    $prd{$itres,$kwdxyz}=$prd{$itres,"PMN"};
		}}
	    return(&errSbrMsg("after call htmProcessRdtmp($fileFinalHtm)",
			      $msg,$SBR3)) if (! $Lok);
				# HACK xyyxyy hackbr
	    
                                # **********************
				# NOT MEMBRANE -> return
	    return(1,"none after htmisit ($SBR3)",0); 

	}}

				# --------------------------------------------------
    if ($LdoHtmrefLoc) {        # do refinement ?
				# --------------------------------------------------
                                # build up argument
#        @tmp=($fileInRdbLoc,"nof file_out=$fileTmpRef");
        @tmp=($fileInRdbLoc,"file_out=$fileTmpRef");
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
	push(@tmp,"prof");

        $arg=join(' ',@tmp);
	
                                # run system call
        if ($exeHtmrefLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmrefLoc $fileInRdbLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg
		    ($command,$fileOutScreenLoc,$fhSbrErr
		     );		return(&errSbrMsg("htmref=$exeHtmrefLoc, msg=",$msg,$SBR3)) if (! $Lok);}
        else {                  # include package
            &phd_htmref::phd_htmref(@tmp);
            $tmp=$exeHtmrefLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }

        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
				# missing file
        return(&errSbr("after htmref=$exeHtmrefLoc, no out=$fileTmpRef",$SBR3)) 
            if (! -e $fileTmpRef);
	$fileFinalHtm=$fileTmpRef;
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile
		($fileTmpRef,$fileOutRdbLoc
		 );	        return(&errSbrMsg("htmref copy",$msg,$SBR3)) if (! $Lok); }

				# --------------------------------------------------
    if ($LdoHtmtopLoc) {        # do the topology prediction ?
				# --------------------------------------------------
                                # build up argument
	if    (-e $fileTmpRef){ $file_tmp=$fileTmpRef;   $arg=" ref"; }
	elsif (-e $fileTmpFil){ $file_tmp=$fileTmpFil;   $arg=" fil"; }
        else                  { $file_tmp=$fileInRdbLoc; $arg=" nof"; }
	$tmp= "file_out=$fileTmpTop file_hssp=$fileHssp";
	$tmp.="_".$chainHssp                               if (defined $chainHssp && 
                                                               $chainHssp=~/^[0-9A-Z]$/);
	@tmp=($file_tmp,$tmp);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
	push(@tmp,"prof");

        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmtopLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmtopLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg
		    ($command,$fileOutScreenLoc,$fhSbrErr
		     );		return(&errSbrMsg("htmtop=$exeHtmtopLoc, msg=",$msg,$SBR3)) if (! $Lok);}
        else {                  # include package
            &phd_htmtop::phd_htmtop(@tmp);
            $tmp=$exeHtmtopLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
	return(&errSbr("after htmtop=$exeHtmtopLoc, no out=$fileTmpTop",$SBR3)) 
            if (! -e $fileTmpTop);
	$fileFinalHtm=$fileTmpTop;
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile
		($fileTmpTop,$fileOutRdbLoc
		 );		return(&errSbrMsg("htmtop copy",$msg,$SBR3)) if (! $Lok); 
    }

				# --------------------------------------------------
				# now read it in again!
    ($Lok,$msg)=
	&htmProcessRdtmp
	    ($fileFinalHtm);    return(&errSbrMsg("after call htmProcessRdtmp($fileFinalHtm)",
						  $msg,$SBR3)) if (! $Lok);
    return(1,"ok $SBR3",1);
}				# end of htmProcessPost

#===============================================================================
sub htmProcessRdtmp {
    local($fileInLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmProcessRdtmp             reads the final RDB_htm file
#                               
#       in GLOBAL:              
#       out GLOBAL:             %prd
#                               
#       in:                     RDB_fileToRead
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."htmProcessRdtmp";$fhinLoc="FHIN_".$SBR3;

				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR3))          if (! defined $fileInLoc);
				# existing file?
    return(&errSbr("no fileIn=$fileInLoc!",$SBR3))       if (! -e $fileInLoc);


    open($fhinLoc,$fileInLoc) || 
	return(&errSbr("failed reading filein(rdbhtm)=$fileInLoc",$SBR3));


				# ------------------------------
				# read file
    $#ptrloc=0;
    while (<$fhinLoc>) {	# header
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
				# skip empty
	next if (length($_)==0);
				# names
	@tmp=split(/[\s\t]+/,$_);
	foreach $it (1..$#tmp){
	    $ptrloc[$it]=$tmp[$it];
	}
	@kwdloc=@tmp;
	last;}
    $ctres=0;
    while (<$fhinLoc>) {	# body
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	++$ctres;
	$_=~s/^\s*//g;
	@tmp=split(/[\s\t]+/,$_);
	foreach $it (1..$#tmp){
	    $prd{$ctres,$ptrloc[$it]}=$tmp[$it];
	}
    }
    $prd{"NROWS"}=$ctres;
    close($fhinLoc);
				# ------------------------------
				# to screen
    if (defined $par{"verb2"} && $par{"verb2"}){
	print "--- $SBR3: read the following keywords: \n";
	print "--- kwd($fileInLoc)=",join(',',@kwdloc,"\n");
    }
				# clean up
    $#kwdloc=0;			# slim-is-in
    $#ptrloc=0;			# slim-is-in

    return(1,"ok $SBR3");
}				# end of htmProcessRdtmp

#===============================================================================
sub htmProcessWrttmp {
    local($fileOutLoc,$L3D_KNOWNloc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmProcessWrttmp            writes a temporary RDB_htm file for communication
#                               with refinement stuff
#       in:                     fileTowrit
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."htmProcessWrttmp";$fhoutLoc="FHOUT_".$SBR3;

                                # --------------------------------------------------
                                # write the file with PROF.rdb_htm
    if (-e $fileOutLoc){
	print "-*- WARN $SBR2: remove old file=$fileOutLoc\n";
	unlink($fileOutLoc);
    }
    open($fhoutLoc,">".$fileOutLoc) || 
	return(&errSbr("failed writing fileout(rdbhtm)=$fileOutLoc",$SBR3));
    print $fhoutLoc
	"\# Perl-RDB\n",
	"\# \n",
	"\# PHDhtm: prediction of helical transmembrane regions\n";
				# keep old names!
    print $fhoutLoc
	"No","\t","AA","\t",
	$kwdGlob{"want"}->{"htm"}->[1],"\t",
	$kwdGlob{"want"}->{"htm"}->[2],"\t",
	$kwdGlob{"ri"}->{"htmfin"},"\t",
	"pM","\t","pN","\t","OtM","\t","OtN","\n";

    $kwdRi=$kwdGlob{"ri"}->{"htm"};

    @outsymTmp=("H","L");

    foreach $itres (1..$prd{"NROWS"}){
	if    (! $L3D_KNOWNloc ||
	       (! defined $prot{"sec",$itres} && ! defined $prot{"htm",$itres})){
	    $obs="?";}
	else {
	    if (defined $prot{"sec",$itres}){
		$obs=$prot{"sec",$itres};}
	    else {
		$obs=$prot{"htm",$itres};}}

	$obs=~s/[MT]/H/;
	$obs=~s/[N]/L/;
	($Lok,$msg,$ri)=
	    &get_ri("htm",$par{"bitacc"},$prd{$itres,1},$prd{$itres,2}
		    );		return(&errSbrMsg("failed on HTMtmp rel index for itres=$itres, ".
						  "output=".$prd{$itres,1}.",".$prd{$itres,2},
						  $msg,$SBR2))  if (! $Lok); 
	$sum=$prd{$itres,1}+$prd{$itres,2};
	$p1=int(10*($prd{$itres,1}/$sum));$p1=9 if ($p1 > 9);
	$p2=int(10*($prd{$itres,2}/$sum));$p2=9 if ($p2 > 9);
				# write
	printf $fhoutLoc
	    "%4d\t%1s\t%1s\t%1s\t%1d\t%1d\t%1d\t%3d\t%3d\n",
	    $itres,$prot{"seq",$itres},$obs,$outsymTmp[$prd{$itres,"win"}],$ri,
	    $p1,$p2,$prd{$itres,1},$prd{$itres,2};
    }
    close($fhoutLoc);
    return(1,"ok $SBR3");
}				# end of htmProcessWrttmp

#===============================================================================
sub interpret1 {
    local($modepredLoc,$modeoutLoc,$winoutLoc,$L3d_knownLoc,$whichPROFloc2) = @_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpret1                  interprets one particular mode (<sec|acc|htm|cap>)
#                               sets keywords to write, in particular @kwdRdb
#                               
#                  NOTE:        also filter on prediction (in &interpretPrd)
#                               
#       in:                     $modepredLoc    prediction mode [3|all|both|sec|acc|htm]
#       in:                     $modeoutLoc     output mode     [HEL|be|bie|10|HL|HT|TM|Hcap]
#       in:                     $winoutLoc      output window   1= normal
#       in:                     $L3d_knownLoc   =1 if structure known
#                               
#       in/out GLOBAL:          %rdb
#       in/out GLOBAL:          %ptrGlob        set in &interpretMode (called here)
#       in/out GLOBAL:          @kwdRdb         set in &interpretMode (called here)
#                               
#       in GLOBAL:              %par
#       in GLOBAL:              %prot
#       in GLOBAL:              $L3D_KNOWN
#       in GLOBAL:              @kwdSec,@kwdAcc,@kwdHtm (from main:iniDef)
#                               
#       out:                    
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."interpret1";$fhinLoc="FHIN_"."interpret1"; 

    return(&errSbr("not def modepredLoc!",  $SBR3)) if (! defined $modepredLoc);
    return(&errSbr("not def modeoutLoc!",   $SBR3)) if (! defined $modeoutLoc);
    return(&errSbr("not def winoutLoc!",    $SBR3)) if (! defined $winoutLoc);
    $L3d_knownLoc=0                                 if (! defined $L3d_knownLoc);

    $numsamLoc=$prd{"NROWS"};
    $numoutLoc=$prd{"NUMOUT"};
				# change for particular modes
    $numoutLoc2=$numoutLoc;
    $numoutLoc2=length($par{"map",$modeoutLoc})
	if ($modeoutLoc =~ /^(HELBGT)$/);
#    $numoutLoc2=$numoutLoc/$winoutLoc if ($winoutLoc > 1);

				# ------------------------------
				# interpret mode
				# ------------------------------
    $#outnum2sym=0;
				# interpret output mode
				# out GLOBAL: %ptrGlob
				# out GLOBAL: @kwdRdb
				# out GLOBAL: @outnum2sym
    ($Lok,$msg,$numoutExpected)=
	&interpretMode($modepredLoc,$modeoutLoc,$L3d_knownLoc,$numoutLoc2
		       );       return(&errSbrMsg("failed to interpret: modepred=$modepredLoc, ".
						  "modeout=$modeoutLoc",$msg,$SBR3)) if (! $Lok);
    return(&errSbr("interpret said numout=$numoutExpected, local said numout=$numoutLoc, ???",
		   $SBR3))      if ($numoutExpected != $numoutLoc2);

                                # determine desired output
				# out GLOBAL: %rdb $rdb{$itres,<OHEL|OACC|...>}
    if ($L3d_knownLoc){
	($Lok,$msg)=
	    &interpretObs($modepredLoc,$modeoutLoc,$numsamLoc,$numoutLoc2
			  );    return(&errSbrMsg("failed to interpret OBS: modepred=$modepredLoc, ".
						  "modeout=$modeoutLoc",$msg,$SBR3)) if (! $Lok);
    }

				# determine network output for RDB
				# in  GLOBAL: %prot %prd
				# out GLOBAL: %rdb $rdb{$itres,<PHEL|PACC|RI_*|p*|...>}

    ($Lok,$msg)=
	&interpretPrd($modepredLoc,$modeoutLoc,$numsamLoc,$winoutLoc,$numoutLoc
		      );        return(&errSbrMsg("failed to interpret PROF (modepred=$modepredLoc, ".
						  "modeout=$modeoutLoc)",$msg,$SBR3)) if (! $Lok);
				# ------------------------------
				# clean up
    $#tmp=0;			# slim-is-in
    undef %prd;
    undef %obs;

    return(1,"ok $SBR3",@tmp);
}				# end of interpret1

#===============================================================================
sub interpretCompress {
    local($levelHere) = @_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretCompress           changes FORTRAN output for particular output
#                               modes by compressing it to fewer units:
#                               modes: HELBGT -> HEL
#       in:                     $levelHere:     level to run =INTEGER (1st,2nd,3rd)
#                               
#       in GLOBAL:              from MAIN:
#                               $par{$kwd}, in particular for $kwd=
#                               'fileOutScreen' file for FORTRAN screen dump (STDOUT if '0|STDOUT')
#                               
#       in GLOBAL:              from &build1st:
#                               %run with
#                               'npar'            number of parameter files
#                               {$itpar}          number of levels for para file $itpar
#                               {$itpar,$itlevel} number of files for $itlevel
#                               {$itpar,$itlevel,$kwd}:
#                               
#                               with $kwd:
#                               
#                               'numout'        number of output units
#                               'filein'        fortran input file
#                               'modepred'      short description of what the job is about
#                                               [sec|acc|htm]
#                               'modeout'       some unique description of output coding (HEL)
#                               
#       in/out GLOBAL:          @FILE_REMOVE=   files to remove after completion
#                               
#       in:                     $Lverb=         1 -> lots of blabla
#       in:                     $Lverb2=        1 -> bit of blabla
#       in:                     $fhtrace=       trace file-handle (STDOUT if =0)
#       out:                    
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."interpretCompress";
    $fhinLoc="FHIN_"."interpretCompress"; $fhoutLoc2="FHOUT_"."interpretCompress";
				# ------------------------------
				# check arguments
    return(&errSbr("not def levelHere!",$SBR3))               if (! defined $levelHere);
    return(&errSbr("levelHere=$levelHere, no number?",$SBR3)) if (! $levelHere=~/\D/);
				# ------------------------------
				# local settings
    if ($par{"debugfor"}){
	$fileOutScreen=0;}
    else {
	$fileOutScreen=$par{"fileOutScreen"};}
    
                                # --------------------------------------------------
				# loop over all parameter files
				# --------------------------------------------------
    foreach $itpar (1..$run{"npar"}){
	next if (! defined $run{$itpar});          # some strange error!
				# ------------------------------
				# NOTE: only $levelHere taken!!
	$itlevel=$levelHere;
	next if (! defined $run{$itpar,$itlevel}); # current level may not have to be run!

				# ------------------------------
				# loop over all architectures
	foreach $itfile (1..$run{$itpar,$itlevel}){
				# only for particular modes
	    $modeoutLoc= $run{$itpar,$itlevel,$itfile,"modeout"};
	    $modepredLoc=$run{$itpar,$itlevel,$itfile,"modepred"};
	    next if (! defined $par{"map",$modeoutLoc});

	    $fileInLoc= $run{$itpar,$itlevel,$itfile,"fileout"}; # FORTRAN output file
	    $fileOutTmp=$par{"fileOutTmp"}; # temporary output
	    open($fhinLoc,$fileInLoc) || 
		return(&errSbr("fileInLoc(forOut)=$fileInLoc, not opened",$SBR3));
	    open($fhoutLoc2,">".$fileOutTmp) || 
		return(&errSbr("fileOutTmp=$fileOutTmp, not created",$SBR3));
				# header: simply mirror
	    while (<$fhinLoc>){ print $fhoutLoc2 $_;
				last if ($_=~/^\* residue/);  }
				# body: massage
	    while (<$fhinLoc>){
		last if ($_=~/^\//);
		$_=~s/\n//g;
		$_=~s/^\s*|\s*$//g;
		($nosam,@tmp)=split(/[\s\t]+/,$_);
		$sum=0;		# get sum over all output values
		foreach $it (1..$#tmp){
		    $sum+=$tmp[$it];}
				# group to 3 states
		$numoutnew=length($par{"map","HELBGT"});
		$#tmpout=0;
		foreach $it (1..$numoutnew){
		    $tmpout[$it]=0;}
		foreach $it (1..$#tmp){
		    $tmpout[$par{"map","HELBGT",$it}]+=$tmp[$it]; }
				# normalise
		foreach $it (1..$numoutnew){
		    $tmpout[$it]=int(100*$tmpout[$it]/$sum);}
				# now write new
		printf $fhoutLoc2 
		    "%8d "."%4d" x $numoutnew . "\n",
		    $nosam,@tmpout;
	    }
	    close($fhinLoc);
	    close($fhoutLoc2);

	    print $FHTRACE2 
		"--- $SBR3: produced $fileOutTmp\n" if ($Lverb);
				# NOW move file old to new
	    $run{$itpar,$itlevel,$itfile,"fileout",$modeoutLoc}=
		$run{$itpar,$itlevel,$itfile,"fileout"};
	    $run{$itpar,$itlevel,$itfile,"fileout",$modeoutLoc}=~s/(\.[^\.]+)$/_$modeoutLoc$1/;
	    $tmp_new=$run{$itpar,$itlevel,$itfile,"fileout",$modeoutLoc};
	    $tmp_old=$run{$itpar,$itlevel,$itfile,"fileout"};
	    $cmd="\\mv ".$tmp_old. " " . $tmp_new;
	    ($Lok,$msg)=	
		&sysRunProg
		    ($cmd,$fileOutScreen,
		     $FHTRACE2);return(&errSbrMsg("failed to run system '$cmd'",
						  $msg,$SBR3)) if (! $Lok  || ! -e $tmp_new);
				# NOW move new to old
	    $cmd="\\mv ".$fileOutTmp." ".$run{$itpar,$itlevel,$itfile,"fileout"};
	    ($Lok,$msg)=	
		&sysRunProg
		    ($cmd,$fileOutScreen,
		     $FHTRACE2);return(&errSbrMsg("failed to run system '$cmd'",
						  $msg,$SBR3)) if (! $Lok  || ! -e $tmp_new);
				# delete in the end!
	    push(@FILE_REMOVE,$run{$itpar,$itlevel,$itfile,"fileout",$modeoutLoc});
				# store info about files on highest level
	    if (! defined $run{$modeoutLoc,"highest"} ||
		$run{$modeoutLoc,"highest"} < $itlevel){
				# announce 'there is some special treat, here!'
		if    (! defined $run{"special"}){
		    $run{"special"}=$modeoutLoc;}
		elsif ($run{"special"} !~/$modeoutLoc/){
		    $run{"special"}.=",".$modeoutLoc;}
				# keep in mind which is the highest level for that treat!
		$run{$modeoutLoc,"highest"}=$itlevel;
				# keep respective FORTRAN output files in mind!
		$run{$modeoutLoc,"files"}.= $run{$itpar,$itlevel,$itfile,"fileout",$modeoutLoc};}
	    else {		# keep respective FORTRAN output files in mind!
		$run{$modeoutLoc,"files"}.=
		    ",".$run{$itpar,$itlevel,$itfile,"fileout",$modeoutLoc};}
	}			# end of loop over architectures
    }				# end of loop over parameter files
				# --------------------------------------------------

    return(1,"ok $SBR3");
}				# end of interpretCompress

#===============================================================================
sub interpretCompressFin {
    local($modeoutLoc,$L3D_KNOWNloc) = @_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretCompressFin        fills in the missing %rdb for the special modes
#                               modes: HELBGT -> HEL
#       in:                     $modeoutSpecial: e.g. HELBGT 
#                               
#       in GLOBAL:              from MAIN:
#                               $par{$kwd}, in particular for $kwd=
#                               'fileOutScreen' file for FORTRAN screen dump (STDOUT if '0|STDOUT')
#                               'fileOutError'  file into which error history is written by nn.pl
#                               
#       in GLOBAL:              from &protRdAliHssp()
#                               $prot{"sec6",$itres}
#                               
#       in GLOBAL:              from &nnJurySpecial()
#                               $prd{$modeoutLoc,"NUMOUT"}
#                               $prd{$modeoutLoc,"NROWS"}
#                               $prd{$modeoutLoc,$ctres,$itout}
#                               
#                               
#       in GLOBAL:              from &build1st:
#                               %run with
#                               'npar'            number of parameter files
#                               {$itpar}          number of levels for para file $itpar
#                               {$itpar,$itlevel} number of files for $itlevel
#                               {$itpar,$itlevel,$kwd}:
#                               
#                               with $kwd:
#                               
#                               'numout'        number of output units
#                               'filein'        fortran input file
#                               'modepred'      short description of what the job is about
#                                               [sec|acc|htm]
#                               'modeout'       some unique description of output coding (HEL)
#                               
#       in/out GLOBAL:          @FILE_REMOVE=   files to remove after completion
#                               
#       in:                     $Lverb=         1 -> lots of blabla
#       in:                     $Lverb2=        1 -> bit of blabla
#       in:                     $fhtrace=       trace file-handle (STDOUT if =0)
#       out:                    
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."interpretCompressFin";
    $fhinLoc="FHIN_"."interpretCompressFin"; $fhoutLoc2="FHOUT_"."interpretCompressFin";
				# ------------------------------
				# check arguments
    return(&errSbr("not def modeoutLoc!",$SBR3))               if (! defined $modeoutLoc);
    $L3D_KNOWNloc=0             if (! defined $L3D_KNOWN);

				# note (e.g.):
				#      par{'map',HELBGT}='HEL'
				#      par{'maptrans',HELBGT}='HGTEBL'
				#      par{'map',HELBGT,[12]}=1
				#      par{'map',HELBGT,[45]}=2
				#      par{'map',HELBGT,[36]}=3
    @outsymloc=split(//,$par{"maptrans",$modeoutLoc});

    
				# ------------------------------
				# 
    foreach $itres (1..$prd{$modeoutLoc,"NROWS"}){
	if ($L3D_KNOWNloc && $modeoutLoc =~/^(HELBGT)$/){
	    $rdb{$itres,"O".$modeoutLoc}=$prot{"sec6",$itres};		
	}
	$sum=$max=$iwin=0;
				# get sum and winnner
	foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
	    $sum+=$prd{$modeoutLoc,$itres,$itout};
	    if ($prd{$modeoutLoc,$itres,$itout} >= $max){
		$max= $prd{$modeoutLoc,$itres,$itout};
		$iwin=$itout;}
	}
				# normalise and write out
	foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
	    $rdb{$itres,$kwdGlob{"HELBGT","Ot"}.$outsymloc[$itout]}=
		int(100*$prd{$modeoutLoc,$itres,$itout}/$sum);
	    $rdb{$itres,$kwdGlob{"HELBGT","p"}.$outsymloc[$itout]}=
		int(10*$prd{$modeoutLoc,$itres,$itout}/$sum);
	    $rdb{$itres,$kwdGlob{"HELBGT","p"}.$outsymloc[$itout]}=
		9               if ($rdb{$itres,$kwdGlob{"HELBGT","p"}.$outsymloc[$itout]}>9);
	}
				# assign winner
	$rdb{$itres,"P".$modeoutLoc}=$outsymloc[$iwin];
    }

    return(1,"ok $SBR3");
}				# end of interpretCompressFin

#===============================================================================
sub interpretMode {
    local($modepredLoc,$modeoutLoc,$L3d_knownLoc,$numoutLoc)=@_;
    my($SBR9,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretMode               interprets mode: output unit -> meaning
#                               note: this should become the 'single' to touch
#                               part for new training modes!
#       in:                     $modepredLoc    prediction mode [3|all|both|sec|acc|htm]
#       in:                     $modeoutLoc     output mode     [HEL|be|bie|10|HL|HT|TM|Hcap]
#       in:                     $L3d_knownLoc   =1 if 3D given 
#       in:                     $numoutLoc      number of output units read so far
#                               
#       in GLOBAL:              @kwdSec,@kwdAcc,@kwdHtm (from main:iniDef)
#                               
#       in/out GLOBAL:          %rdb{"txt","modepred"}
#                               
#       out GLOBAL:             %ptrGlob{"outnum2sym",$itout}
#       out GLOBAL:             %ptrGlob{"outsym2num",$symbol} 'H' = unit 1
#       out GLOBAL:             %ptrGlob
#                               
#       out GLOBAL:             @outnum2sym
#                               
#       out GLOBAL:             @kwdRdb   from &interpretMode;
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR9="interpretMode";
    return(&errSbr("not def modepredLoc!",  $SBR9))  if (! defined $modepredLoc);
    return(&errSbr("not def modeoutLoc!",   $SBR9))  if (! defined $modeoutLoc);
    return(&errSbr("not def winoutLoc!",    $SBR3))  if (! defined $winoutLoc);
    return(&errSbr("not def L3d_knownLoc!", $SBR9))  if (! defined $L3d_knownLoc);
    return(&errSbr("not def numoutLoc!",    $SBR9))  if (! defined $numoutLoc);
    
				# ------------------------------
				# mode of job
				# ------------------------------
    $rdb{"txt","modepred"}=
	$par{"txt","modepred",$modepredLoc} if ($modepredLoc=~/^(3|all|acc|sec|htm|cap|loc)$/);

				# --------------------------------------------------
				# secondary structure | HTM
				# --------------------------------------------------
    if ($modepredLoc=~/^(3|all|both|sec|htm)$/){
				# ------------------------------
				# normal PROFsec
	if    ($modeoutLoc =~/^(HEL|HELT|HL|EL|TL|MN)$/) {
	    $numoutExpected=length($modeoutLoc); 
				# note: to update here, watch also: nnWrtVecOut
	    foreach $it (1..$numoutExpected){
		$sym=      substr($modeoutLoc,$it,1);
		$ptrGlob{"outnum2sym",$it}= $sym;
		$ptrGlob{"outsym2num",$sym}=$it;} }
				# ------------------------------
				# HELBGT
	elsif ($modeoutLoc =~/^(HELBGT)$/) {
				# HELBGT
	    $numoutExpected=length($par{"map",$modeoutLoc}); 
				# note: to update here, watch also: nnWrtVecOut
	    foreach $it (1..$numoutExpected){
		$sym=      substr($par{"map",$modeoutLoc},$it,1);
		$ptrGlob{"outnum2sym",$it}= $sym;
		$ptrGlob{"outsym2num",$sym}=$it;} }
				# ------------------------------
				# SEC caps
	elsif ($modeoutLoc =~/^(H|E|HE)cap$/) {
	    $numoutExpected=2; 
				# note: to update here, watch also: nnWrtVecOut
	    $ptrGlob{"outnum2sym","1"}=   $par{"secCapSym".$modeoutLoc};
	    $ptrGlob{"outnum2sym","2"}=   $par{"secCapSymNon"};
	    $ptrGlob{"outsym2num",$par{"secCapSym".$modeoutLoc}}=1;
	    $ptrGlob{"outsym2num",$par{"secCapSymNon"}}=         2;
				# now additional ones to qualify for secCapNon1, secCapSeg1|2
	    $ptrGlob{"outsym2num","1"}=                 2;
	    $ptrGlob{"outsym2num","2"}=                 2;
	    $ptrGlob{"outsym2num","0"}=                 2; 
	    $outnum2sym[1]=               $par{"secCapSym".$modeoutLoc};
	    $outnum2sym[2]=               $par{"secCapSymNon"};}
	else { 
	    return(&errSbr("modeout=".$modeoutLoc.", and modepred=".
			   $modepredLoc.", not understood",$SBR9)); }
	if ($modepredLoc eq "htm" && $numoutExpected != 2) {            
	    return(&errSbr("modeout=".$modeoutLoc.
			   ", not ok for HTM (numout ought to be 2, modeout=HL)",$SBR9));} }

				# --------------------------------------------------
				# solvent accessibility
				# --------------------------------------------------
    elsif ($modepredLoc=~/^(3|all|both|acc)$/){
				# ------------------------------
				# all PROFacc
	if ($modeoutLoc !~ /^(be|bie|10)$/) {
	    return(&errSbr("modeout=".$modeoutLoc.", and modepred=".
			   $modepredLoc.", not understood (ok would be: <be|bie|10>)",$SBR9));}
	$numoutExpected=2   if ($modeoutLoc eq "be");
	$numoutExpected=3   if ($modeoutLoc eq "bie");
        $numoutExpected=10  if ($modeoutLoc eq "10");
				# ------------------------------
				# 2- or 3-state PROFacc 
	if ($modeoutLoc =~ /^(be|bie)$/) {
	    foreach $it (1..$numoutExpected){
		$sym=                         substr($modeoutLoc,$it,1);
		$ptrGlob{"outnum2sym",$it}=   $sym;
		$ptrGlob{"outsym2num",$sym}=  $it;}}
				# ------------------------------
				# normal PROFacc (10 states)
	else {
	    foreach $it (1..$numoutExpected){
		$sym=                         ($it-1);
		$ptrGlob{"outnum2sym",$it}=   $sym;
		$ptrGlob{"outsym2num",$sym}=  $it;}}
    }

    else { 
	return(&errSbr("modepred (".$modepredLoc.") not understood (numout)\n",$SBR9));}


				# ------------------------------
				# symbols for output units
    if (! defined @outnum2sym || ! $#outnum2sym){
        foreach $itout (1..$numoutLoc){
            push(@outnum2sym,$ptrGlob{"outnum2sym",$itout});
        }}

				# keyword for prediction
    $#kwdAdd=0;

    if    ($modeoutLoc =~ /(E|H|HE)cap/){
	$tmp=substr($modepredLoc,1,1); $tmp=~tr/[a-z]/[A-Z]/;
	$kwdPrd=$kwdGlob{"want"}->{$modepredLoc.$modeoutLoc}->[2];
	$kwdObs=$kwdGlob{"want"}->{$modepredLoc.$modeoutLoc}->[1];
	$tmp=substr($modepredLoc,1,1); $tmp=~tr/[a-z]/[A-Z]/;
	push(@kwdAdd,"OHEL") if ($modepredLoc =~ /sec/);
	push(@kwdAdd,"OMN")  if ($modepredLoc =~ /htm/);
	push(@kwdAdd,
	     "p". $par{"secCapSym".$modeoutLoc}. "_".$modeoutLoc.$tmp, 
	     "p". $par{"secCapSymNon"}.          "_".$modeoutLoc.$tmp, 
	     "Ot".$par{"secCapSym".$modeoutLoc}. "_".$modeoutLoc.$tmp, 
	     "Ot".$par{"secCapSymNon"}.          "_".$modeoutLoc.$tmp
	     );
	$mode{$modepredLoc."numout"}=2;}
    elsif    ($modeoutLoc =~ /HELBGT/){
	$kwdPrd="PHEL";
	$kwdObs="OHEL";
	push(@kwdAdd,
	     "OHELBGT",
	     "PHELBGT");
#	@tmp= split(//,$modeoutLoc);
	@tmp= ("H","G","E","B","T","L");
	@tmp2=split(//,$par{"map",$modeoutLoc});
	foreach $tmp (@tmp){
	    push(@kwdAdd,
		 $kwdGlob{"HELBGT","p"}.$tmp);}
	foreach $tmp (@tmp){
	    push(@kwdAdd,
		 $kwdGlob{"HELBGT","Ot"}.$tmp);}
	foreach $tmp (@tmp2){
	    push(@kwdAdd,
		 "p".$tmp);}
    }
    elsif ($modeoutLoc =~ /winout=(\d+)/){
	$winoutLoc=$1;
	$numoutLoctmp=$numoutLoc/$winoutLoc;
	$kwdPrd="P";
	$kwdObs="O";
	foreach $itout (1..$numoutLoctmp){
	    $kwdObs.=$outnum2sym[$itout];
	    $kwdPrd.=$outnum2sym[$itout]; }
	push(@kwdAdd,$kwdPrd);
	foreach $itout (1..$numoutLoctmp){
	    push(@kwdAdd,"p".$outnum2sym[$itout]);}}
    elsif ($modeoutLoc ne "10"){
	$kwdPrd="P";
	$kwdObs="O";
	foreach $itout (1..$numoutLoc){
	    $kwdObs.=$outnum2sym[$itout];
	    $kwdPrd.=$outnum2sym[$itout]; }
	push(@kwdAdd,$kwdPrd);
	foreach $itout (1..$numoutLoc){
	    push(@kwdAdd,"p".$outnum2sym[$itout]);}}
    else {
	$kwdObs="OREL";
	$kwdPrd="PREL";}
    if ($modeoutLoc !~/cap/){
	foreach $itout (1..$numoutLoc){
	    push(@kwdAdd,"Ot".$outnum2sym[$itout]);}}
    $mode{$modepredLoc."numout"}=$numoutLoc;
				# ------------------------------
				# keywords for RDB output
    $tmp=join(",",@kwdRdb);
				# add keywords for general stuff 'No,AA'
    if ($#kwdRdb<1 || $tmp !~/AA/){
	foreach $kwd (@{$kwdGlob{"gen"}}){
	    push(@kwdRdb,$kwd);
	}}

				# specific keywords for PROF/PHD
    if    ($modepredLoc eq "sec" && $modeoutLoc !~ /cap/){
	$mode{"secKwdRi"}= $kwdGlob{"ri"}->{$modepredLoc};
	$mode{"secKwdPrd"}=$kwdPrd;
	$mode{"secKwdObs"}=$kwdObs;
	push(@kwdRdb,@{$kwdGlob{"want"}->{$modepredLoc}});}
    elsif ($modepredLoc eq "acc"){
	$mode{"accKwdRi"}= $kwdGlob{"ri"}->{$modepredLoc};
	$mode{"accKwdPrd"}=$kwdPrd;
	$mode{"accKwdObs"}=$kwdObs;
	push(@kwdRdb,@{$kwdGlob{"want"}->{$modepredLoc}});}
    elsif ($modepredLoc eq "htm" && $modeoutLoc !~ /cap/){
	$mode{"htmKwdRi"}= $kwdGlob{"ri"}->{$modepredLoc};
	$mode{"htmKwdPrd"}=$kwdPrd;
	$mode{"htmKwdObs"}=$kwdObs;
	push(@kwdRdb,@{$kwdGlob{"want"}->{$modepredLoc}});}
    elsif ($modepredLoc =~ /sec|htm/ && $modeoutLoc =~ /cap/){
	$mode{$modepredLoc."KwdRi"}= $kwdGlob{"ri"}->{$modepredLoc.$modeoutLoc};
	$mode{$modepredLoc."KwdPrd"}=$kwdPrd;
	$mode{$modepredLoc."KwdObs"}=$kwdObs;
	push(@kwdRdb,@{$kwdGlob{"want"}->{$modepredLoc.$modeoutLoc}});}
    else {
	return(&errSbr("modepred (".$modepredLoc.") not understood (kwdRdb)\n",$SBR9));}

    push(@kwdRdb,@kwdAdd);

				# avoid duplications
    undef %tmp; $#tmp=0;
    foreach $tmp (@kwdRdb){
	next if (defined $tmp{$tmp});
	next if (! $L3d_knownLoc && 
		 $tmp=~/^O/ && $tmp !~/^Ot/);
	$tmp{$tmp}=1;
	push(@tmp,$tmp);}
    @kwdRdb=@tmp;
				# ------------------------------
				# threshold
				# ------------------------------
    if (defined $tmp{"Pbie"}){
	@acc3ThreshLoc=split(/,/,$par{"acc3Thresh"});
	@acc3SymbolLoc=split(/,/,$par{"acc3Symbol"}); }
    if (defined $tmp{"Pbe"}){ 
	@acc2ThreshLoc=split(/,/,$par{"acc2Thresh"});
	@acc2SymbolLoc=split(/,/,$par{"acc2Symbol"}); }

    undef %tmp; $#tmp=0;	# slim-is-in
	
    return(1,"ok $SBR9",$numoutExpected);
}				# end of interpretMode

#===============================================================================
sub interpretObs {
    local($modepredLoc,$modeoutLoc,$numsamLoc,$numoutLoc)=@_;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretObs                interprets the observed data
#       in:                     $modepredLoc    prediction mode [3|all|both|sec|acc|htm]
#       in:                     $modeoutLoc     output mode     [HEL|be|bie|10|HL|HT|TM|Hcap]
#       in:                     $numsamLoc      number of samples (residues)
#       in:                     $numoutLoc      number of output units
#                               
#       in GLOBAL:              @kwdRdb         e.g. @kwdAcc from prof.pl
#       in GLOBAL:              
#                               
#                               
#       out GLOBAL:             @kwdObs         e.g. ('OHEL','OACC') subset of @kwdRdb with /^O/ ! /^Ot/
#       out GLOBAL:             
#       out GLOBAL:             
#       out GLOBAL:             
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."interpretObs";
				# check arguments
    return(&errSbr("not def modepredLoc!",$SBR5)) if (! defined $modepredLoc);
    return(&errSbr("not def modeoutLoc!", $SBR5)) if (! defined $modeoutLoc);
    return(&errSbr("not def numsamLoc!",  $SBR5)) if (! defined $numsamLoc);
    return(&errSbr("not def numoutLoc!",  $SBR5)) if (! defined $numoutLoc);

				# ------------------------------
				# (1) get the ones we want
				# acc: "OHEL","OACC","OREL","Obie"
				# sec: "OHEL",
				# htm: "OMN","Otop",
				# ------------------------------
    undef %tmp;
    foreach $kwd (@kwdRdb){
	next if ($kwd !~ /^O/ || $kwd =~ /^Ot/);
	push(@kwdObs,$kwd);
	$tmp{$kwd}=1;
	$kwdCapHere=$kwd            if ($kwd =~ /cap/);
				# OEcapS -> OEcap
	$tmp{substr($kwd,1,(length($kwd)-1))}=1 if ($modeoutLoc=~/cap/);
    }
				# ------------------------------
				# hack 2001-04: add 'prot(htm)'
    if ($modepredLoc=~/^(3|htm)/ && ! defined $prot{"htm",1}){
	foreach $itres (1..$numsamLoc){
	    if    ($prot{"sec",$itres}=~/H/){
		$prot{"htm",$itres}="M";}
	    elsif ($prot{"sec",$itres}=~/L/){
		$prot{"htm",$itres}="N";}
	    else {
		$prot{"htm",$itres}=$prot{"sec",$itres};}
	}}
	
				# ------------------------------
				# (2) check existence of data
				# ------------------------------
    if ($modepredLoc=~/^(3|both|acc)/){
	return(&errSbr("missing prot{accRel}",$SBR5)) if (! defined $prot{"accRel",1});
	return(&errSbr("missing prot{acc}",$SBR5))    if (! defined $prot{"acc",1});
	return(&errSbr("missing prot{sec}",$SBR5))    if (! defined $prot{"sec",1} && 
							  defined $tmp{"OHEL"}); 
    }

    if ($modepredLoc=~/^(3|both|sec)/){
	return(&errSbr("missing prot{sec}",$SBR5))    if (! defined $prot{"sec",1}); 
    }
    if ($modepredLoc=~/^(3|htm)/){
	return(&errSbr("missing prot{htm}",$SBR5))    if (! defined $prot{"htm",1}); 
    }
	
				# ------------------------------
                                # (3) RDB for all residues
				# ------------------------------
    foreach $itres (1..$numsamLoc){
				# wants acc 3 states
	if (defined $tmp{"Obie"}){
	    if    ($prot{"accRel",$itres}<$acc3ThreshLoc[1]){
		$rdb{$itres,"Obie"}=$acc3SymbolLoc[1]; }
	    elsif ($prot{"accRel",$itres}>=$acc3ThreshLoc[2]){
		$rdb{$itres,"Obie"}=$acc3SymbolLoc[3]; }
	    else {
		$rdb{$itres,"Obie"}=$acc3SymbolLoc[2]; } }
				# wants acc 2 states
	if (defined $tmp{"Obe"}){
	    if    ($prot{"accRel",$itres}<$acc2ThreshLoc[1]){
		$rdb{$itres,"Obe"}=$acc2SymbolLoc[1]; }
	    else {
		$rdb{$itres,"Obe"}=$acc2SymbolLoc[2]; } }
				# wants acc
	$rdb{$itres,"OACC"}=$prot{"acc",$itres}    if (defined $tmp{"OACC"});
	$rdb{$itres,"OREL"}=$prot{"accRel",$itres} if (defined $tmp{"OREL"});
				# wants sec
	if (defined $tmp{"OHEL"} ||
	    defined $tmp{"OHL"}){
	    $rdb{$itres,"OHEL"}=$prot{"sec",$itres};}
				# adds 6 state to sec
	$rdb{$itres,"OHELBGT"}=$prot{"sec6",$itres} if ($modeoutLoc =~ /HELBGT/);
	
				# wants htm/top
	if    (defined $tmp{"OMN"} && defined $prot{"htm",$itres} && 
	       ! defined $rdb{$itres,"OMN"}){
	    $rdb{$itres,"OMN"}= $prot{"htm",$itres};}
	elsif (defined $tmp{"OMN"} && defined $prot{"sec",$itres} &&
	       ! defined $rdb{$itres,"OMN"}){
	    $rdb{$itres,"OMN"}= $prot{"htm",$itres};}
	elsif (defined $tmp{"OMN"} && 
	       ! defined $rdb{$itres,"OMN"}){
	    $txt= "*** ERROR $SBR5: missing prot{'htm|sec',1}! \n";
	    $txt.="***        modepred=$modepredLoc, modeout=$modeoutLoc, numout=$numoutLoc,\n";
	    return(&errSbrMsg("missing htm",$txt,$SBR5));}

	$rdb{$itres,"Otop"}=$prot{"top",$itres}     if (defined $tmp{"Otop"});
				# wants cap
	if (defined $tmp{"OEcap"}){
	    $rdb{$itres,$kwdCapHere}=$par{"secCapSymNon"};
	    if (defined $prot{"sec",$itres} && $prot{"sec",$itres} eq "E" &&
		((defined $prot{"sec",($itres-1)} && $prot{"sec",($itres-1)} ne "E") ||
		 (defined $prot{"sec",($itres+1)} && $prot{"sec",($itres+1)} ne "E"))){
		$rdb{$itres,$kwdCapHere}=$par{"secCapSym".$modeoutLoc};
	    }}
	if (defined $tmp{"OHcap"}){
	    $rdb{$itres,$kwdCapHere}=$par{"secCapSymNon"};
	    if (defined $prot{"sec",$itres} && $prot{"sec",$itres} eq "H" &&
		((defined $prot{"sec",($itres-1)} && $prot{"sec",($itres-1)} ne "H") ||
		 (defined $prot{"sec",($itres+1)} && $prot{"sec",($itres+1)} ne "H"))){
		$rdb{$itres,$kwdCapHere}=$par{"secCapSym".$modeoutLoc};
	    }}
	if (defined $tmp{"OHEcap"}){
	    $rdb{$itres,$kwdCapHere}=$par{"secCapSymNon"};
	    if (defined $prot{"sec",$itres} && $prot{"sec",$itres} =~ /^[HE]$/ &&
		((defined $prot{"sec",($itres-1)} && $prot{"sec",($itres-1)} !~ /^[HE]$/) ||
		 (defined $prot{"sec",($itres+1)} && $prot{"sec",($itres+1)} !~ /^[HE]$/))){
		$rdb{$itres,$kwdCapHere}=$par{"secCapSym".$modeoutLoc};
	    }}
    }
				# ------------------------------
                                # (4) check that all there
				# ------------------------------
    $#errTmp=0;
    foreach $kwd (@kwdObs){
	next if ($kwd=~/OMN/);  # hack br 2002-04
	push(@errTmp,$kwd)      if (! defined $rdb{1,$kwd});
    }
    return(&errSbr("missing observed  rdb{1,kwd} for kwd=".
		   join(',',@errTmp),$SBR5)) if ($#errTmp);

    return(1,"ok $SBR5");
				# ------------------------------
				# (5) %obs for getting ERROR
				# ------------------------------
    foreach $itres (1..$numsamLoc){
	print $FHTRACE "*** yyyy write %obs for error computation!!\n";
	die;
    }
    return(1,"ok $SBR5");
}				# end of interpretObs

#===============================================================================
sub interpretPrd {
    local($modepredLoc,$modeoutLoc,$numsamLoc,$winoutLoc,$numoutLoc)=@_;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretPrd                interprets the predicted data
#                               
#                  NOTE:        also filter on prediction (in &interpretPrd)
#                               
#       in:                     $modepredLoc    prediction mode [3|all|both|sec|acc|htm]
#       in:                     $modeoutLoc     output mode     [HEL|be|bie|10|HL|HT|TM|Hcap]
#       in:                     $numsamLoc      number of samples (residues)
#       in:                     $winoutLoc      output window   1= normal
#       in:                     $numoutLoc      number of output units
#                               
#       in GLOBAL:              %par            from main
#       in GLOBAL:              $par{<bitacc|accBuriedSat>
#       in GLOBAL:              $par{<acc2Thresh|acc2Symbol|acc3Thresh|acc3Symbol
#       in GLOBAL:              @kwdRdb         e.g. @kwdAcc from prof.pl
#       in GLOBAL:              %prot{'seq',$it from reading protein
#       in GLOBAL:              %prd            from calling sbr AND &nnJuryDo()
#       in GLOBAL:              $prd{"NUMOUT|NROWS"}, $prd{$itres,<win|$itout>}
#       in GLOBAL:              %ptrGlob        from calling sbr AND &interpretMode()
#       in GLOBAL:              $ptrGlob{"outnum2sym"}
#                               
#       out GLOBAL:             @kwdPrd         e.g. ('PHEL','PACC') subset of @kwdRdb NOT with /^O/
#       out/in GLOBAL:          %rdb            from calling sbr AND &interpretObs()
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."interpretPrd";
    return(&errSbr("not def modepredLoc!",  $SBR5)) if (! defined $modepredLoc);
    return(&errSbr("not def modeoutLoc!",   $SBR5)) if (! defined $modeoutLoc);
    return(&errSbr("not def numsamLoc!",    $SBR5)) if (! defined $numsamLoc);
    return(&errSbr("not def winoutLoc!",    $SBR3)) if (! defined $winoutLoc);
    return(&errSbr("not def numoutLoc!",    $SBR5)) if (! defined $numoutLoc);

    $modeoutLoc2=$modeoutLoc;
    $modeoutLoc2="HEL"          if ($modeoutLoc =~ /HELBGT/);
    @outnum2sym2=@outnum2sym;
    @outnum2sym2=("H","E","L")  if ($modeoutLoc =~ /HELBGT/);

				# ------------------------------
				# (1) get the ones we want
				# acc NOT: "OHEL","OACC","OREL","Obie"
				# sec NOT: "OHEL",
				# htm NOT: "OMN","Otop",
				# ------------------------------
    $#kwdPrd=$Lget_ri=0;
    undef %tmp;
    foreach $kwd (@kwdRdb){
	next if ($kwd=~/^O/ && $kwd!~/^Ot/);
	push(@kwdPrd,$kwd);
	$tmp{$kwd}=1;
	$Lget_ri=  1             if ($kwd=~/RI_/);
    }
    if ($Lget_ri){
	if ($modeoutLoc =~/cap/){
	    $kwd_ri=$kwdGlob{"ri"}->{$modepredLoc.$modeoutLoc};}
	else {
	    $kwd_ri=$kwdGlob{"ri"}->{$modepredLoc};}
    }
    $modepred1st=substr($modepredLoc,1,1);$modepred1st=~tr/[a-z]/[A-Z]/;

				# --------------------------------------------------
				# (2) filter output 
				#     replaces $prd{$itres,$itout} 
				#     by neighbour averages
				#     out(i)-> (out(i-1) + out(i) + out(i+1)) / 3
				#        DO also changes $prd{$itres,"win"}
				# --------------------------------------------------
    if ($prd{"NUMOUT"}==10 && $par{"optAcc10Filter"}){
	($Lok,$msg)=
	    &nnOutFilterAcc10($numsamLoc
			      );return(&errSbrMsg("failed on filtering acc10:",
						  $msg,$SBR5)) if (! $Lok);}

				# --------------------------------------------------
                                # (3) RDB for all residues
				# --------------------------------------------------
    $rdb{"NROWS"}= $numsamLoc;
    $rdb{"NUMOUT"}=$prd{"NUMOUT"};
    $numoutEffective=$numoutLoc;
    
#     if ($winoutLoc > 1){
# 	$winHalf=($winoutLoc-1)/2;
# 	$numoutEffective=$numoutLoc/$winoutLoc;
# 	$beg=$winHalf*$numoutEffective+1;
# 	$end=($winHalf+1)*$numoutEffective;
# 	foreach $itres (1..$numsamLoc){
# 	    undef %prd2;
# 	    $ctout=0;
# 	    foreach $itout ($beg .. $end){
# 		++$ctout;
# 		$prd2{$ctout}=$prd{$itres,$itout};
# 	    }
# 				# undefine old
# 	    foreach $itout (1..$numoutLoc){
# 		undef $prd{$itres,$itout};}
# 				# reassign
# 	    foreach $itout (1..$numoutEffective){
# 		$prd{$itres,$itout}=$prd2{$itout};
# 	    }
# 	}
# 	$prd{"NUMOUT"}=$numoutEffective;
#     }
# 				# normal output: one unit 
#     else {
# 	$beg=1;
# 	$end=$numoutEffective=
# 	    $numoutLoc;}

    foreach $itres (1..$numsamLoc){
				# ------------------------------
				# general protein stuff
	$rdb{$itres,"No"}= $itres;
	$rdb{$itres,"AA"}= $prot{"seq",$itres};
	if ($prot{"seq",$itres} =~/^[\.!]/ || $prof_skip{$itres}){
	    foreach $kwd (@kwdPrd){
				# take output as given
		if ($kwd=~/^Ot(.+)/){
		    $sym=$1;
		    foreach $itout (1..$prd{"NUMOUT"}){
			next if ($sym !~ /$outnum2sym2[$itout]/);
			$rdb{$itres,$kwd}=$prd{$itres,$itout};
		    }}
				# set RI=0
		elsif ($kwd=~/^RI/){
		    $rdb{$itres,$kwd}=0;}
		elsif ($kwd!~/^(O|No|AA)/){
		    $rdb{$itres,$kwd}=$prot{$kwd,$itres};}
	    }
	    next; }
				# winner
        $iwin=$prd{$itres,"win"};
				# ------------------------------
        if ($numoutLoc>1){	# get symbol for this output unit
            ($Lok,$msg,$sym)=
                &get_outSym($modepredLoc,$iwin,@outnum2sym2
			    );  return(&errSbrMsg("failed to interpret output for itres=$itres, ".
						  "modepred=$modepredLoc, modeout=$modeoutLoc",
						  $msg,$SBR5))  if (! $Lok);
	}
        else { 
	    return(&errSbr("for numout<=1, assignment problem not solved, yet ",$SBR5));}
	       
				# ------------------------------
				# get output
	$#out=$sumOut=0;
	foreach $itout (1..$prd{"NUMOUT"}){
	    push(@out,$prd{$itres,$itout});
				# normalise to probabilities
	    $sumOut+=$prd{$itres,$itout};
	}
				# ------------------------------
				# get reliability index
	if ($Lget_ri){
	    ($Lok,$msg,$rdb{$itres,$kwd_ri})=
		&get_ri($modepredLoc,$par{"bitacc"},@out
			);      return(&errSbrMsg("failed on reliability index for itres=$itres, ".
						  "modepred=$modepredLoc, modeout=$modeoutLoc\n".
						  "output=".join(',',@out),
						  $msg,$SBR5))  if (! $Lok); 
				# get RI without PHD jury
	    if ($par{"riAddNophd"}){
		if (defined $prd{"nophd",$itres,1}){
		    $#out2=$sumOut2=0;
		    foreach $itout (1..$prd{"NUMOUT"}){
			push(@out2,$prd{"nophd",$itres,$itout});
				# normalise to probabilities
			$sumOut2+=$prd{"nophd",$itres,$itout};}
		    ($Lok,$msg,$rdb{$itres,$kwd_ri."nophd"})=
			&get_ri
			    ($modepredLoc,$par{"bitacc"},@out2
			     ); return(&errSbrMsg("failed on reliability index PHD for itres=$itres, ".
						  "modepred=$modepredLoc, modeout=$modeoutLoc\n".
						  "output=".join(',',@out2),
						  $msg,$SBR5))  if (! $Lok); 
		}}
	}
    
                                # ------------------------------
                                # acc specific stuff
        if ($modepredLoc=~/^(3|all|both|acc)$/){
				# relative acc
            if ($modeoutLoc=~/10/){
                $accRel=0;
                                # rel acc = (pos-1)*pos
                $accRel=
                    ($prd{$itres,"win"}-1) * $prd{$itres,"win"} if ($prd{$itres,"win"}>1); }
	    else {
                ($Lok,$msg,$accRel)=
                    &get_outAcc($modeoutLoc,$par{"accBuriedSat"},
				$acc2ThreshLoc[1],$acc3ThreshLoc[1],$acc3ThreshLoc[2],
                                $par{"bitacc"},@out
                                ); return(&errSbrMsg("accRel ($accRel) itres=$itres,",
						     $msg,$SBR5)) if (! $Lok); }
				# wants full accessibility
            if (defined $tmp{"PACC"}){
                ($Lok,$acc)=
                    &convert_accRel2acc($accRel,$prot{"seq",$itres}
					); return(&errSbrMsg("accRel=$accRel->acc failed itres=$itres,",
							     $acc,$SBR5)) if (! $Lok); 
		$rdb{$itres,"PACC"}=$acc;}

				# wants acc 3 states
	    if (defined $tmp{"Pbie"}){
                ($Lok,$msg,$rdb{$itres,"Pbie"})=
                    &get_outAccBIE($accRel,$acc3ThreshLoc[1],$acc3ThreshLoc[2],@out
				   ); return(&errSbrMsg("accRel->BIE ($accRel) itres=$itres,",
							$msg,$SBR5)) if (! $Lok); }
				# wants acc 2 states
	    if (defined $tmp{"Pbe"}){
		($Lok,$msg,$rdb{$itres,"Pbe"})=
		    &get_outAccBE($accRel,$acc2ThreshLoc[1],@out
				  ); return(&errSbrMsg("accRel->BE ($accRel) itres=$itres,",
						       $msg,$SBR5)) if (! $Lok); }
				# wants relative acc
            $rdb{$itres,"PREL"}=$accRel            if (defined $tmp{"PREL"}); 

				# all states output
	    foreach $itout (1..$numoutLoc){
		$sym=$outnum2sym2[$itout];
		$rdb{$itres,"p". $sym}=int(10*($out[$itout]/$sumOut));
		$rdb{$itres,"p". $sym}=9 if ($rdb{$itres,"p". $sym}>9);
		$rdb{$itres,"Ot".$sym}=$out[$itout];
	    }
	}			# end of ACC


				# ------------------------------
				# general stuff
				# ------------------------------
	else {
				# one symbol prediction
	    $rdb{$itres,$mode{$modepredLoc."KwdPrd"}}=$outnum2sym2[$prd{$itres,"win"}];
	    foreach $itout (1..$numoutLoc){
		$sym=$outnum2sym2[$itout];
		$sym.="_".$modeoutLoc.$modepred1st if ($modeoutLoc =~ /cap/);
		$rdb{$itres,"p". $sym}=int(10*($out[$itout]/$sumOut));
		$rdb{$itres,"p". $sym}=9 if ($rdb{$itres,"p".$sym} > 9);
		$rdb{$itres,"Ot".$sym}=$out[$itout];
	    }
	}
    }				# end of loop over all residues

				# ------------------------------
				# (4) HTM specific stuff
				# ------------------------------
    if ($modepredLoc =~/^(3|htm)/){
	$Lerr=0; undef %tmperr;
	foreach $itres (1..$numsamLoc){
	    foreach $kwd (@kwdRdb){
		next if ($kwd !~/^PR|^Pi/);
		if (! defined $prd{$itres,$kwd}){
		    if (! defined $tmperr{$kwd}){
			$tmperr{$kwd}=1;
			print "*** ERROR $SBR5:  missing prd{kwd=$kwd}!\n";
			$Lerr=1;}
				# yy br hack 2002 beg
		    if ($kwd=~/^(PR|PiT)/){
			$rdb{$itres,$kwd}=$prd{$itres,"PMN"};
		    }
				# yy br hack 2002 end
		}
		$rdb{$itres,$kwd}=$prd{$itres,$kwd};
	    }
				# convert to pM (hack br 2002-04)
	    if (! defined $rdb{$itres,"pM"}){
		$sum=$rdb{$itres,"OtM"}+$rdb{$itres,"OtN"};
		$rdb{$itres,"pM"}=int(10*$rdb{$itres,"OtM"}/$sum);
		$rdb{$itres,"pN"}=int(10*$rdb{$itres,"OtN"}/$sum);
		foreach $kwd2 ("pM","pN"){
		    if    ($rdb{$itres,$kwd2}<0){
			$rdb{$itres,$kwd2}=0;}
		    elsif ($rdb{$itres,$kwd2}>9){
			$rdb{$itres,$kwd2}=9;}
		}
	    }
	}
	return(&errSbr("failed on modepredloc=$modepredLoc for membrane stuff",$SBR5))
	    if ($Lerr);}
	    
                                # ------------------------------
                                # (5) filter
                                # ------------------------------

				# filter HELIX
    if    ($par{"optSecFilterH"} && defined $rdb{1,"PHEL"}){
	($Lok,$msg)=
	    &nnOutFilterSecHelix($par{"optSecFilterH"},"L"
				 ); return(&errSbrMsg("problem filter helix",$SBR5)) if (! $Lok); }
				# filter cap: flip caps of low reliability
    elsif ($modeoutLoc =~ /cap/){
	foreach $itres (1..$numsamLoc){
	    next if ($rdb{$itres,$mode{"secKwdPrd"}} eq $par{"secCapSymNon"});
	    $rdb{$itres,$mode{"secKwdPrd"}}=
		$par{"secCapSymNon"} if ($rdb{$itres,$kwd_ri} < $par{"riCapFlip"});
	}}

				# filter STRAND
    if    ($par{"optSecFilterE"} && defined $rdb{1,"PHEL"}){
	($Lok,$msg)=
	    &nnOutFilterSecStrand($par{"optSecFilterE"},"L"
				  ); return(&errSbrMsg("problem filter strand",$SBR5)) if (! $Lok); }

    
				# ------------------------------
                                # (5) check that all there
				# ------------------------------
    $#errTmp=0;
    foreach $kwd (@kwdPrd){
	next if ($kwd=~/^(pM|pN)$/); # hack 2002-04
	push(@errTmp,$kwd)      if (! defined $rdb{1,$kwd}); }

    return(&errSbr("missing predicted rdb{1,kwd} for kwd=".
		   join(',',@errTmp),$SBR5)) if ($#errTmp);

    return(1,"ok $SBR5");
				# ------------------------------
                                # (6) %obs for getting ERROR
				# ------------------------------
    foreach $itres (1..$numsamLoc){
	print $FHTRACE "*** yyyy write %obs for error computation!!\n";
	die;
    }

    return(1,"ok $SBR5");
}				# end of interpretPrd

#===============================================================================
sub nn3rd {
    local($depend,$dependFile) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nn3rd                       
#       in:                     $depend:     e.g. seq=1:1,sec=2:1-8,acc=1:1-4,caph=1:13,cape=1:14
#                                            i.e. use the second level files 1-8 (jury over
#                                             all) for secondary structure asf
#       in:                     $dependFile: e.g. 1:3:1,1:3:2,1:3:3,1:3:4
#                                            i.e. the files from run{1,3,1-4} depend on $depend
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."nn3rd";
				# ------------------------------
				# check arguments
    return(&errSbr("not def depend!",$SBR2))     if (! defined $depend);
    return(&errSbr("not def dependFile!",$SBR2)) if (! defined $dependFile);

				# --------------------------------------------------
				# (1)  get parameter files associated
				#      NOTE: not really needed ..
				# --------------------------------------------------
    $#itparWant=0;undef %tmp;
    @tmp=split(/,/,$dependFile);
    foreach $tmp (@tmp){
	@tmp2=split(/:/,$tmp);
	if (! defined $tmp{$tmp2[1]}){
	    push(@itparWant,$tmp2[1]);
	    $tmp{$tmp2[1]}=1;}}
    return(&errSbr("sorry, currently 3rd level dependencies ($depend on file=$dependFile)\n".
		   "   MUST depend all on the SAME level (i.e. NOT 1:n:m AND 2:o:p)\n",$SBR2))
	if ($#itparWant > 1);

    $#tmp=$#tmp2=0;
				# --------------------------------------------------
				# (2)  get modes to get
				# --------------------------------------------------
    $depend=~s/,*$//g;
    @toget=split(/,/,$depend);
    $itparHere=$itparWant[1];
    undef %out;
    foreach $toget (@toget){
				# ------------------------------
				# which files to get jury for? 
				#    is: sec=2:1-8
	($modepredin,$itlevelHere,$files)=split(/[:=]/,$toget);
	if (! defined $out{"modes"}){
	    $out{"modes"}=$modepredin;}
	else {
	    $out{"modes"}.=",".$modepredin;}
				# which files to jury?
	$#itfiles=0;
	@tmp=split(/\+/,$files);
	foreach $tmp (@tmp){
	    next if (length($tmp)<1 || $tmp !~ /\d/);
	    if ($tmp=~/\-/){
		($beg,$end)=split(/\-/,$tmp);
		foreach $it ($beg .. $end){
		    push(@itfiles,$it);}}
	    else {
		push(@itfiles,$tmp);}}
	$#files4jury=0;		# get the output files
	$#winouttmp= 0;
	foreach $itfile (@itfiles){
	    push(@files4jury,$run{$itparHere,$itlevelHere,$itfile,"fileout"}); 
	    push(@winouttmp, $run{$itparHere,$itlevelHere,$itfile,"winout"}); 
	}
	$winouttmpJoin=join(',',@winouttmp);
				# ------------------------------
				# compile jury decision
	undef %prd;
	($Lok,$msg)=
	    &nnJury
		("to3rd".$modepredin,$winouttmpJoin,
		 @files4jury);  return(&errSbrMsg("jury 3rd level=$fileIn, chain=$chainIn! \n".
						  "  it=$itparHere (&nnJury(mode=".
						  "to3rd".$modepredin.", winout=$winouttmpJoin, file=".
						  join(',',@files4jury)."))".
						  "\n"."line=".__LINE__."\n",$msg,$SBR2)) if (! $Lok);
				# verify that all have same number of samples!!
	if (defined $out{"NROWS"}){
	    return(&errSbr("trouble: toget=$toget, ($depend,$dependFile): ".
			   "currently nres=",$out{"NROWS"},", now=",$prd{"NROWS"},"?\n",$SBR2)) 
		if ($out{"NROWS"} != $prd{"NROWS"});}
	else {
	    $out{"NROWS"}=$prd{"NROWS"};}
				# store results
	$out{$modepredin,"NROWS"}= $prd{"NROWS"};
	$out{$modepredin,"NUMOUT"}=$prd{"NUMOUT"};
	foreach $itres (1..$prd{"NROWS"}){
	    $#tmp=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		push(@tmp,$prd{$itres,$itout});
	    }
				# get ri
	    ($Lok,$msg,$ra_add)=
		&nn3rdProcessOnesam
		    ($modepredin,
		     @tmp);	return(&errSbrMsg("failed on modepredin=$modepredin,".
						  " itres=$itres,",$msg,$SBR2)) if (! $Lok);
	    $out{$modepredin,$itres}=$ra_add;
	}
    }				# end of loop over all jurys to get

				# --------------------------------------------------
				# (3)  build up FORTRAN input
				#      writes all input files for current 'depend'
				# --------------------------------------------------
    ($Lok,$msg)=
	&nn3rd_nnWrt
	    ($itparHere);       return(&errSbrMsg("dbfile=$fileIn, chain=$chainIn! (&nn3rd_nnWrt(".
						  "itpar=".$itparHere."))\n"."line=".
						  __LINE__."\n",$msg,$SBR2)) if (! $Lok);
    undef %out;			# slim-is-in

    return(1,"ok $SBR2");
}				# end of nn3rd

#===============================================================================
sub nn3rdProcessOnesam {
    local($modepredLoc,@tmp) = @_ ;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nn3rdProcessOnesam          compiles ri asf for one sample
#       in:                     @tmp=outputs for all units for one sample
#                               
#       in GLOBAL:              $par{"bitacc"},$par{"acc2Thresh"}
#       in GLOBAL:              
#       in GLOBAL:              
#                               
#       out GLOBAL:             @out[1..$itout] for current mode!
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nn3rdProcessOnesam";
				# check arguments
    return(&errSbr("not def modepredLoc!",$SBR4)) if (! defined $modepredLoc);
    return(&errSbr("not def outputs!",$SBR4))     if (! defined @tmp);

    $#out=$sum=0;
    foreach $itout (1..$#tmp){
	$sum+=$tmp[$itout];}
				# normalise
    $max=0;
    foreach $itout (1..$#tmp){
	$out[$itout]=$par{"bitacc"}*$tmp[$itout]/$sum;
	if ($out[$itout]>$max){ 
	    $max=$out[$itout];
	    $win=$itout;} }
				# second best: acc (2nd must be 2 units away!)
    if ($modepredLoc =~/acc/){
	$max2nd=0;
				# skip best in close (2 residues) neighbourhood
	foreach $itout (1..$#tmp){
	    next if (($itout >= ($win-2)) &&
		     ($itout <= ($win+2)));
	    if ($out[$itout] > $max2nd){ 
		$max2nd=$out[$itout];
		$pos2nd=$itout;
	    }}}
				# second best: other
    else {
	$max2nd=0;
	foreach $itout (1..$#tmp){
	    next if ($itout == $win);
	    if ($out[$itout]>$max2nd){ 
		$max2nd=$out[$itout];
		$pos2nd=$itout;
	    }}}
				# RI
    $ri=int( $max-$max2nd );  
    $ri=0                   if ($ri<0); 
    $ri=100                 if ($ri>100);

				# --------------------------------------------------
				# now build up new units
    my(@add);
    $#add=0;
				# ------------------------------
				# accessibility
    if    ($modepredLoc =~/acc/){
	$acc=$win*($win-1); 
	push(@add,$acc);
				# exposed
	if ($acc >= $par{"acc2Thresh"}){
	    push(@add,0,100);
	}
				# buried
	else {
	    push(@add,100,0);
	}
	push(@add,$ri);
    }
				# ------------------------------
				# caps
    elsif ($modepredLoc =~ /cap/){
	if ($win==1){
	    push(@add,100,0);
	}
	else {
	    push(@add,0,100);
	}
	push(@add,$ri);
    }
				# ------------------------------
				# secondary structure
    elsif ($modepredLoc =~ /sec/){
				# full info
	foreach $itout (1..$#tmp){
	    push(@add,int($out[$itout]));
	}
				# binary info
	foreach $itout (1..$#tmp){
	    if ($itout == $win){
		push(@add,100);
	    }
	    else {
		push(@add,0);
	    }
	}
				# ri
	push(@add,$ri);
    }
    else {
	return(&errSbr("mode=$modepredLoc not recognised!",$SBR4));}

    return(1,"ok $SBR4",\@add);
}				# end of nn3rdProcessOnesam

#===============================================================================
sub nn3rd_nnWrt {
    local($itparHere) = @_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nn3rd_nnWrt                 writing NN input for third level
#                               
#       in GLOBAL:              %prot
#       in GLOBAL:              $par{"para"}=          number of parameter files
#       in GLOBAL:              $par{"para",$ctpar}=   number of levels for file ctpar
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel}= number of files 
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel,$ctfile}= current file
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel,$ctfile,$kwd}= 
#       in GLOBAL:                  with kwd=[modein|modepred|modenet|numin|numhid|numout]
#                               
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"filein"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"filejct"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"argFor"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"modein"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"numwin"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"origin"}
#                                   $ctpar TAB $ctlevel TAB $ctfile: points
#                                   to another architecture using the same input
#                               
#       in GLOBAL:              %out from &nn3rd 
#       in GLOBAL:              $out{"NROWS"}= number of residues
#       in GLOBAL:              $out{"modes"}= e.g. "sec,acc,caph,cape"
#       in GLOBAL:              $out{$mode,"NUMOUT"}= number of output units
#       in GLOBAL:              $out{$mode,$itres}=   string with join('\t',@out)
#       in GLOBAL:              
#       in GLOBAL:              
#                               
#       out GLOBAL:             
#                               
#       out GLOBAL:             @PRD_EMPTY[1..$numres]= 
#                                              all blank except for those for which 
#                                              no prediction done (since too short)
#                                              those= $par{"symbolPrdShort"}
#                               
#                               
#       out:                    implicit: parameter file, input/output vectors
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."nn3rd_nnWrt";
    $fhoutLoc="FHOUT_"."nn3rd_nnWrt";
				# check arguments
    return(&errSbr("not def itparHere!",$SBR3))               if (! defined $itparHere);
    return(&errSbr("itparHere=$itparHere, no number?",$SBR3)) if (! $itparHere=~/\D/);
				# local settings
    $itlevelHere=3;

				# --------------------------------------------------
				# loop over all architectures
				# --------------------------------------------------
    foreach $itfile (1..$run{$itparHere,$itlevelHere}){
				# get keywords
	foreach $kwd ("modein","modepred","modenet",
		      "numin","numhid","numout",
		      "filein","fileout"){
	    return(&errSbr("no kwd=$kwd, itpar=$itparHere, itlevel=$itlevelHere, itfile=$itfile!",
			   $SBR3))
		if (! defined $run{$itparHere,$itlevelHere,$itfile,$kwd});
	    $partmp{$kwd}=  $run{$itparHere,$itlevelHere,$itfile,$kwd};
	}
	$numwin=   $run{$itparHere,$itlevelHere,$itfile,"numwin"};
	$winHalf=  ($numwin-1)/2;	# number of spacer residues at begin
	$dependLoc=0;
	$dependLoc=$run{$itparHere,$itlevelHere,$itfile,
			"depend"} if (defined $run{$itparHere,$itlevelHere,$itfile,"depend"});

				# --------------------------------------------------
				# open file and write header for input files
	($Lok,$msg)=
	    &nnWrtHdr($partmp{"filein"},$fhoutLoc,
		      $partmp{"modepred"},$partmp{"modenet"},$partmp{"numin"},$prot{"nres"}
		      );    return(&errSbrMsg("failed on nnWrtHdr:\n",$msg,$SBR3)) if (! $Lok);
	push(@FILE_REMOVE_TMP,$partmp{"filein"});

				# loop over all residues
	($Lok,$msg,$nosam)=
	    &nn3rd_nnWrtData
		($itparHere,$itlevelHere,$itfile,$dependLoc,$winHalf,$partmp{"numin"},
		 $partmp{"modein"},$partmp{"modepred"},$par{"numaa"},$fhoutLoc,$partmp{"filein"}
		 );             return(&errSbrMsg("after nn3rd_nnWrtData(itfile=$itfile, depend=$dependLoc)",
						  $msg,$SBR3)) if (! $Lok); 
				# write final line and close file
	print $fhoutLoc "\/\/\n";
	close($fhoutLoc)    if ($fhoutLoc !~/^STD/);

				# warning if numres wrong
# 	if ($nosam != $prot{"nres"}){
# 	    $tmp= "-** STRONG WARN $SBR3: NN wrote nosam=$nosam, samples, prot has ";
# 	    $tmp.=$prot{"nres"}." residues (par=$itparHere,level=$itlevelHere,file=$itfile)!!\n";
# 	    print $FHTRACE $tmp;
# 	    print $tmp;}
    }				# end of loop over all files at level $itlevel

                                # ------------------------------
                                # save memory
    undef %tmp;			# slim-is-in !
    undef %out;			# slim-is-in !
    
    $#tmp=0;			# slim-is-in !
    return(1,"ok $SBR3");
}				# end of nn3rd_nnWrt

#===============================================================================
sub nn3rd_nnWrtData {
    local($itpar,$itlevel,$itfile,$dependLoc,
	  $winHalf,$numinLoc,$modeinLoc,$modepredLoc,$numaaLoc,$fhoutLoc,$fileOutLoc)=@_;
    my($SBR4,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nn3rd_nnWrtData             processes the %prot input and writes FORTRANin
#                               NOTE: reads all samples from $fileseq (taken from $dependLoc seq=)
#                               
#       in:                     $itpar:        level of parameter file =INTEGER
#       in:                     $itlevel:      level to run            =INTEGER (1st,2nd,3rd)
#       in:                     $itfile:       number of file
#       in:                     $depend:       e.g. seq=1:1,sec=2:1-8,acc=1:1-4,caph=1:13,cape=1:14
#                                              i.e. use the second level files 1-8 (jury over
#                                              all) for secondary structure asf
#                               
#       in:                     $fileOutNet:   network output
#       in:                     $winHalfLoc:   half window length = (numwin-1)/2
#       in:                     $numinLoc=     number of input units, used for error check
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#       in:                     $numaaLoc=     21
#       in:                     $fhoutLoc=     file_handle to write %vecIn
#       in:                     $fileOutLoc=   name of output file (for debug purposes!)
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#                               
#       in GLOBAL:              %out from &nn3rd 
#       in GLOBAL:              $out{"NROWS"}= number of residues
#       in GLOBAL:              $out{"modes"}= e.g. "sec,acc,caph,cape"
#       in GLOBAL:              $out{$mode,"NUMOUT"}= number of output units
#       in GLOBAL:              $out{$mode,$itres}=   string with join('\t',@out)
#                               
#                               
#       out:                    1|0,$msg
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nn3rd_nnWrtData"; $fhinLoc="FHINLOC_".$SBR4; 

    return(&errSbr("not def itpar!",      $SBR4)) if (! defined $itpar);
    return(&errSbr("not def itlevel!",    $SBR4)) if (! defined $itlevel);
    return(&errSbr("not def itfile!",     $SBR4)) if (! defined $itfile);
    return(&errSbr("not def dependLoc!",  $SBR4)) if (! defined $dependLoc);
    return(&errSbr("not def winHalf!",    $SBR4)) if (! defined $winHalf);
    return(&errSbr("not def numinLoc!",   $SBR4)) if (! defined $numinLoc);
    return(&errSbr("not def modeinLoc!",  $SBR4)) if (! defined $modeinLoc);
    return(&errSbr("not def modepredLoc!",$SBR4)) if (! defined $modepredLoc);
    return(&errSbr("not def numaaLoc!",   $SBR4)) if (! defined $numaaLoc);
    return(&errSbr("not def fhoutLoc!",   $SBR4)) if (! defined $fhoutLoc);

				# --------------------------------------------------
				# (1) assign modein specifics (e.g. hydro)
				#     returns %HYDRO
				# --------------------------------------------------
    ($Lok,$msg)=
	&assData_inputUnits($winHalf,$modeinLoc,$numaaLoc
			    );  return(&errSbrMsg("after assData_inputUnits: $itpar,$itlevel,$itfile, ".
						  " ($winHalf,$modeinLoc,$numaaLoc)",
						  $msg,$SBR4)) if (! $Lok); 
				# --------------------------------------------------
				# (2) get meaning of input units
				#     in  GLOBAL:  %prot
				#     out GLOBAL:  @codeUnitIn1st
				#     out GLOBAL:  @num_codeUnitIn (if $Ldobuild2nd)
				# --------------------------------------------------
    $#codeUnitIn1st=0;
    $modein1st=$modeinLoc; 
    $modein1st=~s/^.*seq=//g;
    $modein1st=~s/(sec|acc|cap.*)=[^,]*//g;
    ($Lok,$msg)=
	&decode_inputUnits1st($winHalf,$modein1st,$numaaLoc
			      ); return(&errSbrMsg("spoiled decode_inputUnits1st ($winHalf,$modein1st,".
						   "$numaaLoc)",$msg,$SBR4)) if (! $Lok); 
				#                  
				#     out GLOBAL:  @codeUnitIn3rd
				#     out :        %mode2units{<sec|acc|cape|caph>,<nunitPerResidue|window>}=
				#                  number of units per residue for mode (e.g. 7 for sec)
				#                  window for mode
				#                  
    $numinSeq=$#codeUnitIn1st;
    $#codeUnitIn3rd=0;
    ($Lok,$msg,%mode2units)=
	&decode_inputUnits3rd($modeinLoc,$numinSeq
			      ); return(&errSbrMsg("spoiled decode_inputUnits3rd ($modeinLoc,$numinSeq)",
						   $msg,$SBR4)) if (! $Lok); 
    $numintrd=$#codeUnitIn1st+$#codeUnitIn3rd;
    return(&errSbr("came in with numinLoc=$numinLoc, now claims numintrd=$numintrd!",$SBR4))
	if ($numintrd != $numinLoc);

				# --------------------------------------------------
				# (3) set spacer
				# --------------------------------------------------
    @modes=split(/,/,$out{"modes"});
    foreach $mode (@modes){
	my (@tmp);
	$#tmp=0;
	foreach $it (1..$mode2units{$mode,"nunitPerRes"}){
	    push(@tmp,0);}
	$out{$mode,"spacer"}=\@tmp;
    }
				# --------------------------------------------------
				# (4) read input and write output
				# --------------------------------------------------
				# get input file to read sequence stuff from 
    $tmp=$dependLoc;
    $tmp=~s/^.*seq=//g;
    $tmp=~s/^([^,]+),.*$/$1/g;
    return(&errSbr("dependLoc=$dependLoc, (tmp=$tmp) MUST contain seq=ITLEVEL:ITFILE!"))
	if ($tmp !~ /:/);	# 
    ($itleveltmp,$itfiletmp)=split(/:/,$tmp);
    $fileseq=$run{$itpar,$itleveltmp,$itfiletmp,"filein"};

    print "--- $SBR4: working on fileInIn4rd($modepredLoc)=$fileseq->$fileOutLoc ($fhoutLoc)!\n"
	if ($par{"verb2"});
    open($fhinLoc,$fileseq)     || return(&errSbr("failed to open fileseq=$fileseq!",$SBR4));

				# ------------------------------
				# header
    while (<$fhinLoc>) {
				# grep number of original input units
	if    ($_=~/^NUMIN\s+\:\s+(\d+)/){
	    $numinseq=  $1;}
	elsif ($_=~/^NUMSAMFILE\s+\:\s+(\d+)/){
	    $numsamfile=$1;}
				# last line
	last if ($_=~/^\* samples\:/);
    }
    return(&errSbr("not defined NUMIN=$numinseq, in file=$fileseq!",
		   $SBR4)) if (! defined $numinseq || $numinseq !~ /^\d+$/);
    return(&errSbr("not defined NUMINSAMFILE=$numsamfile, in file=$fileseq!",
		   $SBR4)) if (! defined $numsamfile || $numsamfile !~ /^\d+$/);
			       
				# ------------------------------
				# now body
    $#tmpin=0;
    while (<$fhinLoc>) {
				# EOF: now for final pattern
	if ($_=~/^\//){
	    return(&errSbr("premature EOF! fileseq=$fileseq, nosam=$nosam, numsamfile=$numsamfile,\n",
			   $SBR4)) if ($#tmpin<1);
	    print "*** STRONG WARNING $SBR4 final nosam=$nosam, numsamfile=$numsamfile!\n" x 3
		if ($nosam != $numsamfile);
	    return(&errSbr("final nosam=$nosam, numsamfile=$numsamfile!\n",$SBR4))
		if ($nosam != $numsamfile);
	    ($Lok,$msg)=
		&assData3rd_wrtForIn
		    ($fhoutLoc,$nosam,$txtsam,$numintrd,@modes
		     );		 return(&errSbrMsg("assData3rd_wrtForIn (1) failed on ($nosam,".
						   "txt=$txtsam, numin3rd=$numintrd) modes=".
						   join(',',@modes)."\n",$msg,$SBR4)) if (! $Lok);
	    $#tmpin=0;
	    last;}

	$_=~s/\n//g;
	$line=$_;
				# number of sample
	if ($line=~/ITSAM\s*\:\s*(\d+)/){
	    $nosam=$1;
				# previously added
	    return(&errSbr("tmpin > too large=".$#tmpin.
			   " for sam=$nosam!\n",$SBR4)) if ($#tmpin > $numintrd);
	    if ($#tmpin>1){
		return(&errSbr("tmpin > 1 but nosam=1",$SBR4)) if ($nosam==1);
		($Lok,$msg)=
		    &assData3rd_wrtForIn
			($fhoutLoc,($nosam-1),$txtsam,$numintrd,@modes
			 );	return(&errSbrMsg("assData3rd_wrtForIn (2) failed on (".($nosam-1).",".
						  "txt=$txtsam, numin3rd=$numintrd) modes=".
						  join(',',@modes)."\n",$msg,$SBR4)) if (! $Lok);
	    }
				# reset
	    $#tmpin=0;
	    $txtsam=$line;
	    next; }
				# all samples into temporary array
	$line=~s/^\s*|\s*$//g;
	@tmp=split(/\s+/,$line);
	push(@tmpin,@tmp);
    }
    close($fhinLoc);
				# ------------------------------
				# anything left to write (if no proper control!)
    if ($#tmpin>0){
	($Lok,$msg)=
	    &assData3rd_wrtForIn
		($fhoutLoc,$nosam,$txtsam,$numintrd,@modes
		 );		return(&errSbrMsg("assData3rd_wrtForIn (3) failed on ($nosam,".
						  "$txtsam,$numintrd)\n",$msg,$SBR4)) if (! $Lok);
    }

				# clean up
    undef %mode2units;		# slim-is-in !

    $#tmp=0;			# slim-is-in
    $#tmpin=0;			# slim-is-in
    $#modes=0;			# slim-is-in !

    return(1,"ok $SBR4",$nosam);
}				# end of nn3rd_nnWrtData

#===============================================================================
sub assData3rd_wrtForIn {
    local($fhoutLoc,$nosamLoc,$txtsamLoc,$numintrdLoc,@modesLoc) = @_ ;
    local($SBR6,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData3rd_wrtForIn         write input units for one sample
#                               
#       in:                     $fhoutLoc:    file handle to write to
#       in:                     $nosamLoc:    current number of samples
#       in:                     $txtsamLoc:   line with 'ITSAM '
#       in:                     $numintrdLoc: number of third level input units
#       in:                     @modesLoc:    e.g. ("sec","acc","caph","cape")
#                               
#       in GLOBAL:              @tmpin=       all input units (of 1st level)
#                               
#       in GLOBAL:              %out from &nn3rd:nn3rdProcessOneSample() 
#       in GLOBAL:              $out{"NROWS"}= number of residues
#       in GLOBAL:              $out{"modes"}= e.g. "sec,acc,caph,cape"
#       in GLOBAL:              $out{$mode,"NUMOUT"}= number of output units
#       in GLOBAL:              $out{$mode,$itres}=   string with join('\t',@out)
#                               
#       in GLOBAL:              $par{"bitacc"}
#                               
#       in GLOBAL:              from nn3rd_nnWrtData::decode_inputUnits3rd
#       in GLOBAL:              %mode2units{<sec|acc|cape|caph>,<nunitPerResidue|window>}=
#       in GLOBAL:                          number of units per residue for mode (e.g. 7 for sec)
#       in GLOBAL:                          window for mode
#                               
#       in GLOBAL:              
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6="assData3rd_wrtForIn";

    $#tmpadd=0;
				# --------------------------------------------------
				# loop over all predictions to use as input
				# --------------------------------------------------
    foreach $modepredtmp (@modesLoc){

				# get respective window
	return(&errSbr("missing %mode2units{$modepredtmp,'window'} nosam=$nosamLoc!",$SBR6))
	    if (! defined $mode2units{$modepredtmp,"window"});
	return(&errSbr("mode2units{$modepredtmp,'window'}=".
		       $mode2units{$modepredtmp,"window"}.", STRANGE nosam=$nosamLoc!",$SBR6))
	    if ($mode2units{$modepredtmp,"window"} !~ /^\d+$/);
	$winloc=$mode2units{$modepredtmp,"window"};

				# ------------------------------
				# now find respective predictions
	$winBeg=(-1*($winloc-1)/2);
	$winEnd=(   ($winloc-1)/2);
	foreach $itwin ($winBeg .. $winEnd){
	    $nosamTmp=$nosamLoc+$itwin;
				# normal residue
				#     -> append info from &nn3rdProcessOneSam()
	    if (defined $prot_seq{$nosamTmp}){
		push(@tmpadd,@{$out{$modepredtmp,$nosamTmp}}); 
	    }
				# SPACER: before|after protein
				#     -> simply add spacer
	    else {
		push(@tmpadd,@{$out{$modepredtmp,"spacer"}}); 
	    }
	}			# end of loop over window
    }				# end of loop over all modes
    
    return(&errSbr("number of input units to add=".$#tmpadd.", old=".$#tmpin.
		   "-> new total=".($#tmpadd+$#tmpin).", but wanted=$numintrdLoc",$SBR6))
	if (($#tmpadd+$#tmpin) != $numintrdLoc);

				# ------------------------------
				# write new input
				# itsam
    print $fhoutLoc $txtsamLoc,"\n";
				# old input+new
    @new=(@tmpin,@tmpadd);
    return(&errSbr("file=$fileIn, numinNew=".$#new.
		   ", but wanted=$numintrdLoc\n",$SBR6)) if ($#new != $numintrdLoc);

    $formRepeat=$par{"formRepeat"} || 25;

    for ($itin=1;$itin<=$#new;$itin+=$formRepeat){
				# write: 25 per row
	$itinEnd=($itin+($formRepeat-1));
	$itinEnd=$#new          if ($itinEnd > $#new);
	foreach $itin2 ($itin .. $itinEnd){
                                # integer already
	    printf $fhoutLoc "%6d",$new[$itin2];
				# ERROR: too high
#	    return(&errSbr("itsam=$nosamLoc, itin2=$itin2, input unit=",
#			   $new[$itin2],", too large!",$SBR6))
#		   if ($new[$itin2] > $par{"bitacc"});
	}
	print $fhoutLoc "\n";
    }

    $#new=0;			# slim-is-in!
    return(1,"ok $SBR6");
}				# end of assData3rd_wrtForIn

#===============================================================================
sub nnForRun {
    local($levelHere) = @_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnForRun                       runs the FORTRAN program NN
#       in:                     $levelHere:     level to run =INTEGER (1st,2nd,3rd)
#                               
#       in GLOBAL:              from MAIN:
#                               $par{$kwd}, in particular for $kwd=
#                               'dirWork'       working dir (into which FORTRAN writes)
#                               'dirOut'        output dir (into which FORTRAN output will be moved)
#                               'jobid'         job-identifier for intermediate files asf.
#                               'fileOutScreen' file for FORTRAN screen dump (STDOUT if '0|STDOUT')
#                               'fileOutError'  file into which error history is written by nn.pl
#                               'optNice'       ' ' for nonice, otherwise 'nice -num'
#                               'exeNetFor'     FORTRAN executable
#                               
#                               'bitacc'        accuracy of computation, out=int, out/bitacc = real
#                               
#                               
#                               'acc2Thresh'    threshold for 2-state acc, b: acc<=thresh, e: else
#                               'acc3Thresh'    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#                               'title_net'     
#                               
#                               
#                               
#       in GLOBAL:              from &build1st:
#                               %run with
#                               'npar'            number of parameter files
#                               {$itpar}          number of levels for para file $itpar
#                               {$itpar,$itlevel} number of files for $itlevel
#                               {$itpar,$itlevel,$kwd}:
#                               
#                               with $kwd:
#                               
#                               'numin'         number of NN input units
#                               'numhid'        number of NN hidden units
#                               'numout'        number of output units
#                               'filein'        fortran input file
#                               'argFor'        argument to run fortran
#                               'modepred'      short description of what the job is about
#                                               [sec|acc|htm]
#                               'modein'        some unique description of input coding
#                               'modeout'       some unique description of output coding (HEL)
#                               'modenet'       1st|2nd|3rd + unb|bal
#                               'modejob'       some unique description of job
#                               ''      
#                               ''      
#                               ''      
#                               
#                               
#       in/out GLOBAL:          @FILE_REMOVE=   files to remove after completion
#                               
#       in:                     $Lverb=         1 -> lots of blabla
#       in:                     $Lverb2=        1 -> bit of blabla
#       in:                     $fhtrace=       trace file-handle (STDOUT if =0)
#       out:                    
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."nnForRun";$fhinLoc="FHIN_"."nnForRun"; $fhoutLoc2="FHOUT_"."nnForRun";

				# ------------------------------
				# check arguments
    return(&errSbr("not def levelHere!",$SBR3))               if (! defined $levelHere);
    return(&errSbr("levelHere=$levelHere, no number?",$SBR3)) if (! $levelHere=~/\D/);
				# ------------------------------
				# local settings
    if ($par{"debugfor"}){
	$fileOutScreen=0;}
    else {
	$fileOutScreen=$par{"fileOutScreen"};}
    
				# nice level
    $optNiceLoc="";
    if ($par{"optNice"} =~ /(\d+)/){
	$tmp=$1;
	if (defined $par{"exeSysNice"} && 
	    $par{"exeSysNice"}         &&
	    (-e $par{"exeSysNice"} || -l $par{"exeSysNice"})){
	    $optNiceLoc=$par{"exeSysNice"};}
	else {
	    $optNiceLoc="nice";}
	$optNiceLoc.=" -".$tmp;}
    $exeProfForNice=$optNiceLoc." ".$par{"exeProfFor"};

                                # --------------------------------------------------
				# loop over all parameter files
				# --------------------------------------------------
    foreach $itpar (1..$run{"npar"}){
	next if (! defined $run{$itpar});          # some strange error!
				# ------------------------------
				# NOTE: only $levelHere taken!!
	$itlevel=$levelHere;
	next if (! defined $run{$itpar,$itlevel}); # current level may not have to be run!
				# ------------------------------
				# loop over all architectures
	foreach $itfile (1..$run{$itpar,$itlevel}){
	    foreach $kwd ("fileout","argFor"){ # 
		return(&errSbr("missing $kwd ($itpar,$itlevel,$itfile)!",$SBR3))
		    if (! defined $run{$itpar,$itlevel,$itfile,$kwd});}
	    $argFor= $run{$itpar,$itlevel,$itfile,"argFor"};
	    $argFor=~s/numsam/$prot{"nres"}/;
	    $fileOut=$run{$itpar,$itlevel,$itfile,"fileout"};

	    push(@FILE_REMOVE_TMP,$fileOut);
				# security: erase output file if existing
	    unlink($fileOut)    if (-e $fileOut);
				# argument to run
	    $cmd=$exeProfForNice." ".$argFor." >> ".$fileOut;
#	    eval "\$cmdFor=\"$cmd\"";

	    # **************************************************
	    ($Lok,$msg)=	
		&sysRunProg($cmd,$fileOutScreen,$FHPROG);
	    
	    return(&errSbrMsg("failed to run netFor:".$par{"exeProfFor"}." cmd=\n".
			      $cmd,$msg,$SBR3)) if (! $Lok);
				# output file existing??
	    return(&errSbr   ("FORTRAN call:\n".$cmd."\n"."failed producing output file=".$fileOut,
			      $SBR3)) if (! -e $fileOut);
	    # **************************************************

	    print $FHTRACE2 
		"--- $SBR3: produced $fileOut\n" if ($Lverb);
	}			# end of loop over architectures
    }				# end of loop over parameter files
				# --------------------------------------------------

    return(1,"ok $SBR3");
}				# end of nnForRun

#===============================================================================
sub nnJury {
    local($dbgtxt,$winoutJoinLoc,@fileOutNetLoc) = @_;
    local($SBR4,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnJury                      reads output files and compiles average
#       in:                     $dbgtxt:        used to write temporary file
#       in:                           NOTE:     also has mode <acc|sec|cape|caph>
#                                            OR <to3rd> !!
#       in:                     $winoutJoin:    mode for many output units
#       in:                     @fileOutNetLoc: fortran output files
#       out:                    1|0,msg,$numnet
#       out GLOBAL:             %prd, with $prd{'NUMOUT'},$prd{'NROWS'}, $prd{$ctres,$itout}
#       out GLOBAL:                        $prd{$ctres,'win'}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnJury";          $fhinLoc="FHIN_"."nnJury";$fhoutLoc="FHOUT_"."nnJury";

    $LverbLoc=0;                # temporary writes
#    $LverbLoc=1;
				# check arguments
    return(&errSbr("not def fileOutNetLoc!",$SBR4)) if (! defined @fileOutNetLoc ||
							! @fileOutNetLoc);

    @winoutJoinLoc=split(/,/,$winoutJoinLoc);

				# --------------------------------------------------
				# loop over all output files
				# --------------------------------------------------
    $ctnet=0;
    foreach $file (@fileOutNetLoc){
	++$ctnet;

	open($fhinLoc,$file) || return(&errSbr("file=$file, not opened",$SBR4));
	print "--- $SBR4 read fileOutNet($ctnet)=$file\n" 
	    if ($LverbLoc);
				# ------------------------------
				# read file out
	$numoutEffective=0;
#	undef %tmpxyx;
	while (<$fhinLoc>) {
				# skip comments
	    next if ($_=~/^\#/ ||
		     $_=~/^\*/ ||
		     $_=~/^\-/   );
	    $_=~s/\n//g;
	    $line=$_;
	    $line=~s/^\s*|\s*$//g; # leading blanks
	    next if (length($line)==0); # skip empty
	    ($ctres,@tmp)=split(/[\t\s]+/,$line);
				# process many output units
	    if ($winoutJoinLoc[$ctnet] > 1){
#		foreach $itout (1..$#tmp){
#		    $tmpxyx{$ctres,$itout}=$tmp[$itout];
#		}
				# ini
		if (! $numoutEffective){
		    $winout=$winoutJoinLoc[$ctnet];
		    $winHalfout=($winoutJoinLoc[$ctnet]-1)/2;
		    $numoutEffective=$#tmp/$winoutJoinLoc[$ctnet];
		    $beg=$winHalfout*$numoutEffective+1;
		    $end=($winHalfout+1)*$numoutEffective;
		}
				# do
		$#tmp2=0;
		foreach $itout ($beg..$end){
		    push(@tmp2,$tmp[$itout]);
		}
		@tmp=@tmp2;
	    }
	    print "--- $SBR4 nout=".$#tmp." for fileOutNet($ctnet)=$file\n" 
		if ($LverbLoc);
				# ini
	    if (! defined $prd{$ctres,1}){
		$prd{"NUMOUT"}=$#tmp 
		    if (! defined $prd{"NUMOUT"});
		foreach $itout (1..$#tmp){
		    $prd{$ctres,$itout}=0;
		}}
				# add up
	    foreach $itout (1..$#tmp){
		$prd{$ctres,$itout}+=$tmp[$itout];
	    }
	}
	close($fhinLoc);
# 				# redo
# 	if (0 && defined %tmpxyx){
# 	    foreach $itres (2..($ctres-1)){
# 		$#tmp=0;
# 		foreach $itout (1..$numoutEffective){
# 		    $tmp[$itout]=0;
# 		    foreach $itwin (1..$winout){
# 			$tmp[$itout]+=$tmpxyx{$itres,(($itwin-1)*$numoutEffective+$itout)};
# 		    }
# 		    $tmp[$itout]=       $tmp[$itout]/3;
# 		    $prd{$itres,$itout}=int($tmp[$itout]);
# 		}
# 	    }
# 	    undef %tmpxyx;
#	}
    }				# end of loop over output files
				# --------------------------------------------------

				# --------------------------------------------------
				# add PHD output: 
				#         buuuh, bad hack: hard-coded keywords!!
				# --------------------------------------------------
    $prd{"NROWS"}=$ctres;
    if    ($dbgtxt !~ /to3/ &&
	   $dbgtxt=~/sec/   && $par{"optJury"}=~/phd/i){
	@kwdtmp=("OtH","OtE","OtL");
	foreach $kwd (@kwdtmp){
	    $kwd.="phd";}
	foreach $itres (1..$prd{"NROWS"}){
	    if (! defined $prd{"NUMOUT"}){
		print "*** BIG problem $SBR4, prd{NUMOUT} not defined!\n";
		exit;
	    }
	    foreach $itout (1..$prd{"NUMOUT"}){ 
		return(&errSbr("dbg=$dbgtxt, itres=$itres, itout=$itout, problem with kwdtmp for PHD!",
			       $SBR4)) if (! defined $kwdtmp[$itout]);
		return(&errSbr("dbg=$dbgtxt, itres=$itres, itout=$itout, no PHD(kwd=".$kwdtmp[$itout].")",
			       $SBR4)) if (! defined $rdb{$itres,$kwdtmp[$itout]});
				# memorise phd
		if ($par{"riAddNophd"}){
		    $prd{"nophd",$itres,$itout}=$rdb{$itres,$kwdtmp[$itout]};}
		    
		$prd{$itres,$itout}+=$rdb{$itres,$kwdtmp[$itout]}; }}}
    elsif ($dbgtxt !~ /to3/ &&
	   $dbgtxt=~/acc/   && $par{"optJury"}=~/phd/i){
	$#kwdtmp=0;
	foreach $it (1..10)   {push(@kwdtmp,"Ot".($it-1)."phd");}
	foreach $itres (1..$prd{"NROWS"}){
	    foreach $itout (1..$prd{"NUMOUT"}){ 
		return(&errSbr("dbg=$dbtxt, itres=$itres, itout=$itout, problem with kwdtmp for PHD!",
			       $SBR4)) if (! defined $kwdtmp[$itout]);
		if (! defined $rdb{$itres,$kwdtmp[$itout]}){
		    foreach $kwd (sort keys %rdb){
			next if ($kwd!~/phd/);
			next if ($kwd!~/^3\d/);
		    }
		    exit;}
		return(&errSbr("dbg=$dbtxt, itres=$itres, itout=$itout, no PHD(kwd=".$kwdtmp[$itout].")",
			       $SBR4)) if (! defined $rdb{$itres,$kwdtmp[$itout]});
				# memorise phd
		if ($par{"riAddNophd"}){
		    $prd{"nophd",$itres,$itout}=$rdb{$itres,$kwdtmp[$itout]};}

		$prd{$itres,$itout}+=$rdb{$itres,$kwdtmp[$itout]}; }}}
    $numnet=$ctnet;
    ++$numnet                   if ($par{"optJury"}=~/phd/i && 
				    $dbgtxt !~ /to3/        && 
				    $dbgtxt !~ /htm/        );


				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# beg of hack on capE AND capH
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# br 2000-08
    if ($dbgtxt =~ /to3rd.*cape/){
				# skew output values to require higher weight on
				#    unit 'is E cap'!
	foreach $itres (1..$prd{"NROWS"}){
				# only change if capE predicted
	    $prd{$itres,1}=   $prd{$itres,1}-20;
	    $prd{$itres,2}=   $prd{$itres,2}+20;
	    $prd{$itres,1}=   0 if ($prd{$itres,1} <   0);
	    $prd{$itres,2}= 100 if ($prd{$itres,2} > 100);
	}
    }
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
    if (0 && $dbgtxt =~ /to3rd.*caph/){
				# skew output values to require higher weight on
				#    unit 'is E cap'!
	foreach $itres (1..$prd{"NROWS"}){
				# only change if capE predicted
	    $prd{$itres,1}=   $prd{$itres,1}-10;
	    $prd{$itres,2}=   $prd{$itres,2}+10;
	    $prd{$itres,1}=   0 if ($prd{$itres,1} <   0);
	    $prd{$itres,2}= 100 if ($prd{$itres,2} > 100);
	}
    }
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# end of hack on capE AND capH
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 

    return(&errSbr("numnet=$numnet??",$SBR4)) if ($numnet<1);

				# ------------------------------
				# normalise
				# ------------------------------
    if ($numnet > 1){
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		$prd{$itres,$itout}=int($prd{$itres,$itout}/$numnet);
		if ($max<$prd{$itres,$itout}){
		    $max=$prd{$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{"NUMOUT"}){
		    push(@tmp,$prd{$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$itres,"win"}=$pos;
	}}
    else {
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		if ($max<$prd{$itres,$itout}){
		    $max=$prd{$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{"NUMOUT"}){
		    push(@tmp,$prd{$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$itres,"win"}=$pos;
	}}

				# ------------------------------
				# temporary output file
				# ------------------------------
    if ($par{"debug"}){
	$fileout=
	    $par{"dirWork"}.$par{"titleTmp"}.
		$dbgtxt."j".$par{"extOutTmp"};
#	    $par{"dirWork"}.$par{"titleNetOut"}.
#		$dbgtxt."-"."jury".$par{"extNetOut"};
#	$run{$itpar,"fileout"}=$fileout;
				# security erase existing file
	unlink($fileout)        if (-e $fileout);
	push(@FILE_REMOVE,$fileout);
	open($fhoutLoc,">".$fileout)||
	    do { print "-*- WARN $SBR4: failed opening fileout=$fileout!\n";
		 $fileout=0;}; 
	foreach $itres (1..$ctres){
	    $#tmp=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		push(@tmp,$prd{$itres,$itout});}
	    printf $fhoutLoc
		"%8d ". "%4d" x $prd{"NUMOUT"} . "\n",
		$itres,@tmp;
	}
	close($fhoutLoc); }

    return(1,"ok $SBR4");
}				# end of nnJury

#===============================================================================
sub nnJurySpecial {
    local($dbgtxt,$modeoutLoc,@fileOutNetLoc) = @_;
    local($SBR4,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnJurySpecial               reads output files and compiles average
#                               for special formats (HELBGT)
#       in:                     $dbgtxt:        used to write temporary file
#       in:                           NOTE:     also has mode <acc|sec|cape|caph>
#                                            OR <to3rd> !!
#       in:                     $modeoutLoc:    e.g. HELBGT
#       in:                     @fileOutNetLoc: fortran output files
#       out:                    1|0,msg,$numnet
#       out GLOBAL:             %prd{$modeoutLoc}, with 
#       out GLOBAL:                 $prd{$modeoutLoc,'NUMOUT'},$prd{$modeoutLoc,'NROWS'}, 
#       out GLOBAL:                 $prd{$modeoutLoc,$ctres,$itout}
#       out GLOBAL:                 $prd{$modeoutLoc,$ctres,'win'}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnJurySpecial";          $fhinLoc="FHIN_"."nnJurySpecial";$fhoutLoc="FHOUT_"."nnJurySpecial";
				# check arguments
    return(&errSbr("not def fileOutNetLoc!",$SBR4)) if (! defined @fileOutNetLoc ||
							! @fileOutNetLoc);
				# --------------------------------------------------
				# loop over all output files
				# --------------------------------------------------
    $ctnet=0;
    foreach $file (@fileOutNetLoc){
	++$ctnet;

	open($fhinLoc,$file) || return(&errSbr("file=$file, not opened",$SBR4));
				# ------------------------------
				# read file out
	while (<$fhinLoc>) {
				# skip comments
	    next if ($_=~/^\#/ ||
		     $_=~/^\*/ ||
		     $_=~/^\-/   );
	    $_=~s/\n//g;
	    $line=$_;
	    $line=~s/^\s*|\s*$//g; # leading blanks
	    next if (length($line)==0); # skip empty
	    ($ctres,@tmp)=split(/[\t\s]+/,$line);
				# ini
	    if (! defined $prd{$modeoutLoc,$ctres,1}){
		$prd{$modeoutLoc,"NUMOUT"}=$#tmp 
		    if (! defined $prd{$modeoutLoc,"NUMOUT"});
		foreach $itout (1..$#tmp){
		    $prd{$modeoutLoc,$ctres,$itout}=0;
		}}
				# add up
	    foreach $itout (1..$#tmp){
		$prd{$modeoutLoc,$ctres,$itout}+=$tmp[$itout];
	    }
	}
	close($fhinLoc);
    }				# end of loop over output files
				# --------------------------------------------------
    $prd{$modeoutLoc,"NROWS"}=$ctres;
    $numnet=$ctnet;

    return(&errSbr("numnet=$numnet??",$SBR4)) if ($numnet<1);

				# ------------------------------
				# normalise
				# ------------------------------
    if ($numnet > 1){
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
		$prd{$modeoutLoc,$itres,$itout}=int($prd{$modeoutLoc,$itres,$itout}/$numnet);
		if ($max<$prd{$modeoutLoc,$itres,$itout}){
		    $max=$prd{$modeoutLoc,$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{$modeoutLoc,"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
		    push(@tmp,$prd{$modeoutLoc,$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$modeoutLoc,$itres,"win"}=$pos;
	}}
    else {
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
		if ($max<$prd{$modeoutLoc,$itres,$itout}){
		    $max=$prd{$modeoutLoc,$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{$modeoutLoc,"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
		    push(@tmp,$prd{$modeoutLoc,$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$modeoutLoc,$itres,"win"}=$pos;
	}}

				# ------------------------------
				# temporary output file
				# ------------------------------
    if ($par{"debug"}){
	$fileout=
	    $par{"dirWork"}.$par{"titleTmp"}.
		$dbgtxt."j".$par{"extOutTmp"};
#	    $par{"dirWork"}.$par{"titleNetOut"}.
#		$dbgtxt."-"."jury".$par{"extNetOut"};
#	$run{$itpar,"fileout"}=$fileout;
				# security erase existing file
	unlink($fileout)        if (-e $fileout);
	push(@FILE_REMOVE,$fileout);
	open($fhoutLoc,">".$fileout)||
	    do { print "-*- WARN $SBR4: failed opening fileout=$fileout!\n";
		 $fileout=0;}; 
	foreach $itres (1..$ctres){
	    $#tmp=0;
	    foreach $itout (1..$prd{$modeoutLoc,"NUMOUT"}){
		push(@tmp,$prd{$modeoutLoc,$itres,$itout});}
	    printf $fhoutLoc
		"%8d ". "%4d" x $prd{$modeoutLoc,"NUMOUT"} . "\n",
		$itres,@tmp;
	}
	close($fhoutLoc); }

    return(1,"ok $SBR4");
}				# end of nnJurySpecial

#===============================================================================
sub nnJuryWeight {
    local($dbgtxt,$winoutJoinLoc,@fileOutNetLoc) = @_;
    local($SBR4,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnJuryWeight                reads output files and compiles weighted average
#       in:                     $dbgtxt:        used to write temporary file
#       in:                           NOTE:     also has mode <acc|sec|cape|caph>
#       in:                     $winoutJoin:    mode for many output units
#       in:                     @fileOutNetLoc: fortran output files
#       out:                    1|0,msg,$numnet
#       out GLOBAL:             %prd, with $prd{'NUMOUT'},$prd{'NROWS'}, $prd{$ctres,$itout}
#       out GLOBAL:                        $prd{$ctres,'win'}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnJuryWeight";    $fhinLoc="FHIN_"."nnJuryWeight";$fhoutLoc="FHOUT_"."nnJuryWeight";
				# check arguments
    return(&errSbr("not def fileOutNetLoc!",$SBR4)) if (! defined @fileOutNetLoc ||
							! @fileOutNetLoc);
    @winoutJoinLoc=split(/,/,$winoutJoinLoc);

				# --------------------------------------------------
				# loop over all output files
				# --------------------------------------------------
    $ctnet=0;
    undef %prdnet;
    foreach $file (@fileOutNetLoc){
	++$ctnet;

	open($fhinLoc,$file) || return(&errSbr("file=$file, not opened",$SBR4));

				# ------------------------------
				# read file out
	$numoutEffective=0;
#	undef %tmpxyx;
	while (<$fhinLoc>) {
				# skip comments
	    next if ($_=~/^\s*\#/ ||
		     $_=~/^\s*\*/ ||
		     $_=~/^\s*\-/   );
	    $_=~s/\n//g;
	    $line=$_;
	    $line=~s/^\s*|\s*$//g; # leading blanks
	    next if (length($line)==0); # skip empty
	    ($ctres,@tmp)=split(/[\t\s]+/,$line);
	    $end=$#tmp          if (! $end);
				# process many output units
	    if ($winoutJoinLoc[$ctnet] > 1){
#		foreach $itout (1..$#tmp){
#		    $tmpxyx{$ctres,$itout}=$tmp[$itout];
#		}
				# ini
		if (! $numoutEffective){
		    $winHalfout=($winoutJoinLoc[$ctnet]-1)/2;
		    $numoutEffective=$#tmp/$winoutJoinLoc[$ctnet];
		    $beg=$winHalfout*$numoutEffective+1;
		    $end=($winHalfout+1)*$numoutEffective;
		}
				# do
		$#tmp2=0;
		foreach $itout ($beg..$end){
		    push(@tmp2,$tmp[$itout]);
		}
		@tmp=@tmp2; $#tmp2=0;
	    }
				# add up
	    foreach $itout (1..$#tmp){
		$prdnet{$ctres,$itout,$ctnet}=$tmp[$itout];
	    }
	    $sum=$max=0;
	    foreach $itout (1..$#tmp){
		$sum+=$tmp[$itout];
		if ($tmp[$itout] > $max){
		    $max=$tmp[$itout];
		    $pos=$itout;}}
	    if ($sum<=0){
		print "*** ERROR $SBR4: file=$file, ctnet=$ctnet, ctres=$ctres, \n";
		print "***              sum=$sum, tmp=",join('-',@tmp,"\n");
		print "*** line read=",$line,"\n";
		die;}
	    $prdnet{$ctres,"prob",$ctnet}=int(100*$max/$sum);
	    $prdnet{"prob",$ctnet}=0 if (! defined $prdnet{"prob",$ctnet});
	    $prdnet{"prob",$ctnet}+=$prdnet{$ctres,"prob",$ctnet};
	}
	close($fhinLoc);
# 				# redo
# 	if (defined %tmpxyx){
# 	    foreach $itres (2..($ctres-1)){
# 		$#tmp=0;
# 		foreach $itout (1..$numoutEffective){
# 		    $tmp[$itout]=0;
# 		    foreach $itwin (1..$winout){
# 			$tmp[$itout]+=$tmpxyx{$itres,(($itwin-1)*$numoutEffective+$itout)};
# 		    }
# 		    $tmp[$itout]=       $tmp[$itout]/3;
# 		    $prdnet{$itres,$itout,$ctnet}=int($tmp[$itout]);
# 		}
# 	    }
# 	    undef %tmpxyx;
# 	}
				# store number of output units once
	$numoutloc=$#tmp;
	$prd{"NUMOUT"}=$#tmp 
	    if (! defined $prd{"NUMOUT"});
    }				# end of loop over output files
				# --------------------------------------------------
    $prd{"NROWS"}=$ctres;
    $numnet=$ctnet;

				# weight according to ri
    $sumprob=0;
    foreach $itnet (1..$numnet){
	$sumprob+=$prdnet{"prob",$itnet};
    }
    foreach $itnet (1..$numnet){
	$prdnet{"prob",$itnet}=$prdnet{"prob",$itnet}/$sumprob;
    }
    foreach $itres (1..$ctres){
				# ini
	foreach $itout (1..$numoutloc){
	    $prd{$itres,$itout}=0;
	}

	foreach $itnet (1..$numnet){
	    foreach $itout (1..$numoutloc){
		$prd{$itres,$itout}+=$prdnet{"prob",$ctnet}*$prdnet{$itres,$itout,$itnet};
	    }
	}
    }
				# hack for later
    foreach $itres (1..$ctres){
	foreach $itout (1..$numoutloc){
	    $prd{$itres,$itout}=$prd{$itres,$itout}*$numnet;
	}}
	
    undef %prdnet;		# slim-is-in


				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# beg of hack on capE AND capH
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# br 2000-08
    if ($dbgtxt =~ /to3rd.*cape/){
				# skew output values to require higher weight on
				#    unit 'is E cap'!
	foreach $itres (1..$prd{"NROWS"}){
				# only change if capE predicted
	    $prd{$itres,1}=   $prd{$itres,1}-20;
	    $prd{$itres,2}=   $prd{$itres,2}+20;
	    $prd{$itres,1}=   0 if ($prd{$itres,1} <   0);
	    $prd{$itres,2}= 100 if ($prd{$itres,2} > 100);
	}
    }
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
    if (0 && $dbgtxt =~ /to3rd.*caph/){
				# skew output values to require higher weight on
				#    unit 'is E cap'!
	foreach $itres (1..$prd{"NROWS"}){
				# only change if capE predicted
	    $prd{$itres,1}=   $prd{$itres,1}-10;
	    $prd{$itres,2}=   $prd{$itres,2}+10;
	    $prd{$itres,1}=   0 if ($prd{$itres,1} <   0);
	    $prd{$itres,2}= 100 if ($prd{$itres,2} > 100);
	}
    }
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 
				# end of hack on capE AND capH
				# -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- -*- 

    return(&errSbr("numnet=$numnet??",$SBR4)) if ($numnet<1);

				# ------------------------------
				# normalise
				# ------------------------------
    if ($numnet > 1){
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		$prd{$itres,$itout}=int($prd{$itres,$itout}/$numnet);
		if ($max<$prd{$itres,$itout}){
		    $max=$prd{$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{"NUMOUT"}){
		    push(@tmp,$prd{$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$itres,"win"}=$pos;
	}}
    else {
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		if ($max<$prd{$itres,$itout}){
		    $max=$prd{$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{"NUMOUT"}){
		    push(@tmp,$prd{$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$itres,"win"}=$pos;
	}}

				# ------------------------------
				# temporary output file
				# ------------------------------
    if ($par{"debug"}){
	$fileout=
	    $par{"dirWork"}.$par{"titleTmp"}.
		$dbgtxt."j".$par{"extOutTmp"};
#	    $par{"dirWork"}.$par{"titleNetOut"}.
#		$dbgtxt."-"."jury".$par{"extNetOut"};
#	$run{$itpar,"fileout"}=$fileout;
				# security erase existing file
	unlink($fileout)        if (-e $fileout);
	push(@FILE_REMOVE,$fileout);
	open($fhoutLoc,">".$fileout)||
	    do { print "-*- WARN $SBR4: failed opening fileout=$fileout!\n";
		 $fileout=0;}; 
	foreach $itres (1..$ctres){
	    $#tmp=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		push(@tmp,$prd{$itres,$itout});}
	    printf $fhoutLoc
		"%8d ". "%4d" x $prd{"NUMOUT"} . "\n",
		$itres,@tmp;
	}
	close($fhoutLoc); }

    return(1,"ok $SBR4");
}				# end of nnJuryWeight

#===============================================================================
sub nnOutRd {
    local($fileInLoc)= @_ ;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnOutRd                     reads the results from the network
#       in:                     $fileInLoc:  
#       in:                     $desLoc:    where to store results
#                                   =0      -> do NOT use, i.e. 
#                                           $nnout{$des,*}=$nnout{*}
#       out GLOBAL:             %nnout
#       out GLOBAL:             $nnout{$des,"NROWS"}=      number of residues
#       out GLOBAL:             $nnout{$des,"outNum"}=     number of output units
#       out GLOBAL:     RAW       
#       out GLOBAL:             $nnout{$des,$itout,$itres}=raw network output 
#       out GLOBAL:     DERIVED       
#       out GLOBAL:             $nnout{$des,"iwin",$itres}=number of winner unit
#       out GLOBAL:             $nnout{$des,"ri",$itres}=  reliability
#       out GLOBAL:             $nnout{$des,"prob",$itout,$itres}= 
#       out GLOBAL:                                        normalised output for $itout $itres
#       out GLOBAL:             
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnOutRd";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR4))    if (! defined $fileInLoc);

    open($fhinLoc,$fileOutNet) ||
	return(&errSbr("failed to open network output=$fileOutNet!",$SBR4));
    undef $ncol;
    $ctline=0;
				# ------------------------------
				# read file
    while (<$fhinLoc>) {	# 
	++$ctline;
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	next if ($_=~/^[\s\t]*\*/);
	next if ($_=~/^[\s\t]*\-\-/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty
	$line=$_;
	$tmp=$line;
	$tmp=~s/^\s*|\s*$//g;	# purge leading blanks
	($itres,@tmp)=split(/[\s\t]+/,$tmp);
				# first column= residue number -> skip
	if (! defined $ncol){
	    $ncol=$#tmp+1;
	    if (! defined $nnout{"outNum"}){
		$nnout{"outNum"}=        $#tmp;}}
				# error check
	$tmpErr="";
	foreach $tmp (@tmp){
	    $tmpErr.="tmp=$tmp, seems wrong!\n" if ($tmp=~/\D/); }
	return(&errSbr("*** ERROR $SBR4: output from fileOutNet=$fileOutNet,\n".
		       $tmpErr."\n")) if (length($tmpErr)>0);

				# now for all output units
	$pos=$sum=$max=0;
	foreach $it (1..$#tmp){
	    $nnout{$it,$itres}=$tmp[$it];
	    $sum+=$tmp[$it];
	    $max= $tmp[$it] if ($tmp[$it]>$max);}
				# iwin
	$iwin=$pos;
				# prob
	foreach $it (1..$#tmp){
	    $nnout{"prob",$itout,$itres}=     int($par{"bitacc"}*$tmp[$it]/$sum);
	}

	return(&errSbr("itres=$itres, line=$ctline, fileOutNet=$fileOutNet: sum<1!"))
	    if ($sum<1);
				# store winner
	return(&errSbr("itres=$itres, line=$ctline, fileOutNet=$fileOutNet: iwin<1!"))
	    if ($iwin < 1);

	$nnout{$itout,"iwin",$itres}= $iwin;

	$last=$itres;
    }
    close($fhinLoc);

    if (! defined $nnout{"NROWS"}){
	$nnout{"NROWS"}=$last;}

    return(1,"ok $SBR4");
}				# end of nnOutRd

#===============================================================================
sub nnOutRdDepend {
    local($fileInLoc,$desLoc)= @_ ;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnOutRdDepend               reads the results from the network
#       in:                     $fileInLoc:  
#       in:                     $desLoc:    where to store results
#                                   =0      -> do NOT use, i.e. 
#                                           $nnout{$des,*}=$nnout{*}
#       out GLOBAL:             %nnout
#       out GLOBAL:             $nnout{$des,"NROWS"}=      number of residues
#       out GLOBAL:             $nnout{$des,"outNum"}=     number of output units
#       out GLOBAL:     RAW       
#       out GLOBAL:             $nnout{$des,$itout,$itres}=raw network output 
#       out GLOBAL:     DERIVED       
#       out GLOBAL:             $nnout{$des,"iwin",$itres}=number of winner unit
#       out GLOBAL:             $nnout{$des,"ri",$itres}=  reliability
#       out GLOBAL:             $nnout{$des,"prob",$itout,$itres}= 
#       out GLOBAL:                                        normalised output for $itout $itres
#       out GLOBAL:             
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnOutRdDepend";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR4))    if (! defined $fileInLoc);

    open($fhinLoc,$fileOutNet) ||
	return(&errSbr("failed to open network output=$fileOutNet!",$SBR4));
    undef $ncol;
    $ctline=0;
				# ------------------------------
				# read file
    $#nnout_prob=$#nnout_out=$#nnout_iwin=$#nnout_win=0;
    while (<$fhinLoc>) {	# 
	++$ctline;
				# skip comments
	next if ($_ !~ /^\s*\d/);
	$_=~s/\n//g;
	$line=$_;
	$tmp=$line;
	$tmp=~s/^\s*|\s*$//g;	# purge leading blanks
	my(@tmp);
	($itres,@tmp)=split(/[\s\t]+/,$tmp);
				# first column= residue number -> skip
				# error check
# 	$tmpErr="";
# 	foreach $tmp (@tmp){
# 	    $tmpErr.="tmp=$tmp, seems wrong!\n" if ($tmp=~/\D/); }
# 	return(&errSbr("*** ERROR $SBR4: output from fileOutNet=$fileOutNet,\n".
# 		       $tmpErr."\n")) if (length($tmpErr)>0);

				# now for all output units
	$pos=$sum=$max=0;
	foreach $it (1..$#tmp){
	    $sum+=$tmp[$it];
				# note: '>=' will let exposed/loop win for equal numbers
	    if ($tmp[$it]>=$max){
		$pos= $it;
		$max= $tmp[$it]; }
	}
	return(&errSbr("itres=$itres, line=$ctline, fileOutNet=$fileOutNet: sum<1!"))
	    if ($sum<1);
				# iwin
				# prob and win
	my(@tmp2);
	my(@tmp3);
	$iwin=$pos;
	foreach $it (1..$#tmp){
	    if ($it == $pos){
		push(@tmp2,$par{"bitacc"});}
	    else {
		push(@tmp2,0);}
	    push(@tmp3,int($par{"bitacc"}*$tmp[$it]/$sum));
	}
	    
				# store winner
	return(&errSbr("itres=$itres, line=$ctline, fileOutNet=$fileOutNet: iwin<1!"))
	    if ($iwin < 1);

	$nnout_iwin[$itres]=$iwin;
	$nnout_win[$itres]= \@tmp2;
	$nnout_out[$itres]= \@tmp;
	$nnout_prob[$itres]=\@tmp3;
	$last=$itres;
    }
    $numout=$#{$nnout_prob[$last]};
    close($fhinLoc);

    return(1,"ok $SBR4",$last,$numout);
}				# end of nnOutRdDepend

#===============================================================================
sub nnOutRdDependwin {
    local($fileInLoc,$desLoc,$winoutLoc)= @_ ;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnOutRdDependwin            reads the results from the network (only central!)
#       in:                     $fileInLoc:  
#       in:                     $desLoc:    where to store results
#                                   =0      -> do NOT use, i.e. 
#                                           $nnout{$des,*}=$nnout{*}
#       in:                     $winoutLoc: window of output units
#                                           read ( (winout-1)/2 + 1) .. numout/winout
#                               
#       out GLOBAL:             %nnout
#       out GLOBAL:             $nnout{$des,"NROWS"}=      number of residues
#       out GLOBAL:             $nnout{$des,"outNum"}=     number of output units
#       out GLOBAL:     RAW       
#       out GLOBAL:             $nnout{$des,$itout,$itres}=raw network output 
#       out GLOBAL:     DERIVED       
#       out GLOBAL:             $nnout{$des,"iwin",$itres}=number of winner unit
#       out GLOBAL:             $nnout{$des,"ri",$itres}=  reliability
#       out GLOBAL:             $nnout{$des,"prob",$itout,$itres}= 
#       out GLOBAL:                                        normalised output for $itout $itres
#       out GLOBAL:             
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnOutRdDependwin";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR4))    if (! defined $fileInLoc);

    open($fhinLoc,$fileOutNet) ||
	return(&errSbr("failed to open network output=$fileOutNet!",$SBR4));
    undef $ncol;
    $ctline=0;
				# ------------------------------
				# read file
    $#nnout_prob=$#nnout_out=$#nnout_iwin=$#nnout_win=0;
    $winHalfout=($winoutLoc-1)/2;
    $numoutEffective=0;

    while (<$fhinLoc>) {	# 
	++$ctline;
				# skip comments
	next if ($_ !~ /^\s*\d/);
	$_=~s/\n//g;
	$line=$_;
	$tmp=$line;
	$tmp=~s/^\s*|\s*$//g;	# purge leading blanks
	my(@tmp);
	($itres,@tmp)=split(/[\s\t]+/,$tmp);
				# first column= residue number -> skip
				# error check
# 	$tmpErr="";
# 	foreach $tmp (@tmp){
# 	    $tmpErr.="tmp=$tmp, seems wrong!\n" if ($tmp=~/\D/); }
# 	return(&errSbr("*** ERROR $SBR4: output from fileOutNet=$fileOutNet,\n".
# 		       $tmpErr."\n")) if (length($tmpErr)>0);

	if (! $numoutEffective){
	    $numoutEffective=$#tmp/$winoutLoc;
	    $beg=$winHalfout*$numoutEffective+1;
	    $end=($winHalfout+1)*$numoutEffective;
	}
				# do compress output
	$#tmp2=0;
	foreach $itout ($beg..$end){
	    push(@tmp2,$tmp[$itout]);
	}
	@tmp=@tmp2; $#tmp2=0;

				# now for all output units
	$pos=$sum=$max=0;
	foreach $it (1..$#tmp){
	    $sum+=$tmp[$it];
				# note: '>=' will let exposed/loop win for equal numbers
	    if ($tmp[$it]>=$max){
		$pos= $it;
		$max= $tmp[$it]; }
	}
	return(&errSbr("itres=$itres, line=$ctline, fileOutNet=$fileOutNet: sum<1!"))
	    if ($sum<1);
				# iwin
				# prob and win
	my(@tmp2);
	my(@tmp3);
	$iwin=$pos;
	foreach $it (1..$#tmp){
	    if ($it == $pos){
		push(@tmp2,$par{"bitacc"});}
	    else {
		push(@tmp2,0);}
	    push(@tmp3,int($par{"bitacc"}*$tmp[$it]/$sum));
	}
	    
				# store winner
	return(&errSbr("itres=$itres, line=$ctline, fileOutNet=$fileOutNet: iwin<1!"))
	    if ($iwin < 1);

	$nnout_iwin[$itres]=$iwin;
	$nnout_win[$itres]= \@tmp2;
	$nnout_out[$itres]= \@tmp;
	$nnout_prob[$itres]=\@tmp3;
	$last=$itres;
    }
    $numout=$#{$nnout_prob[$last]};
    close($fhinLoc);

    return(1,"ok $SBR4",$last,$numoutEffective);
}				# end of nnOutRdDependwin

#===============================================================================
sub nnOutFilterAcc10 {
    local($ctresLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnOutFilterAcc10            filters 10 state accessibility prediction
#                               by compiling neighbour averages:
#                               out(i)-> (out(i-1) + out(i) + out(i+1)) / 3
#       in:                     $ctresLoc   number of residues
#       in/out GLOBAL:          $prd{$itres,$itout}= actual network output
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."nnOutFilterAcc10";
				# check arguments
    return(&errSbr("not def ctresLoc!",$SBR6))          if (! defined $ctresLoc);
				# ------------------------------
				# loop over all residues
    foreach $itres (1..$ctresLoc){
	$max=0;
	$#filter=0;
				# all output units
	foreach $itout (1..$prd{"NUMOUT"}){
	    $cttmp=$sum=0;
				# now < i-1, i, i+1 >
	    foreach $itout2 (($itout-1)..($itout+1)){
		next if ($itout2 < 1 || $itout2 > $prd{"NUMOUT"});
		++$cttmp;
		$sum+=$prd{$itres,$itout2};
	    }
	    $filter[$itout]=int($sum/$cttmp);}
				# redecide on winner
	foreach $itout (1..$prd{"NUMOUT"}){
				# - * - - * - - * - - * - 
				# replace prediction HERE
	    $prd{$itres,$itout}=$filter[$itout];
				# - * - - * - - * - - * - 
 	    if ($max<$prd{$itres,$itout}){
 		$max=$prd{$itres,$itout};
 		$pos=$itout;}}
 	if ($pos<1 || $pos>$prd{"NUMOUT"}){
 	    $#tmp=0;
 	    foreach $itout (1..$prd{"NUMOUT"}){
 		push(@tmp,$prd{$itres,$itout});}
 	    return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR6));}
 	$prd{$itres,"win"}=$pos;
    }

    $#filter=0;			# slim-is-in
    return(1,"ok $SBR6");
}				# end of nnOutFilterAcc10

#===============================================================================
sub nnOutFilterSecHelix {
    local($riSwitchLoc,$symLoopLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnOutFilterSecHelix           filters secondary structure prediction in the
#                               following way:
#                               
#                               IF ('helix') AND length(HELIX) <= 2
#                                  IF RELINDEX >= 4 
#                                     extend helix to 3 in direction of lowest RI
#                                  ELSE
#                                     cut
#                               
#       in:                     $riSwitchLoc     rel index to decide whether to 
#                                                delete helix or to elongate
#       in:                     $symLoopLoc      symbol used for loop
#       in/out GLOBAL:          $rdb{"NROWS"},$rdb{"<PHEL|RI_S>",$itres}
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."nnOutFilterSecHelix";
				# check arguments
    return(&errSbr("not def riSwitchLoc!",$SBR6)) if (! defined $riSwitchLoc);
    $symLoopLoc="L"                               if (! defined $symLoopLoc);

				# --------------------------------------------------
				# get helix lengths
    $#tmpbeg=$#tmpbeg=$#tmpend=$prev=$cth=0;
    foreach $itres (1..$rdb{"NROWS"}){
	next if ($prof_skip{$itres} || ! defined $rdb{$itres,"PHEL"});
	if    ($rdb{$itres,"PHEL"} ne "H") {
	    push(@tmpend,($itres-1))
		if ($prev);
	    $prev=0;}
	elsif (! $prev){ 
	    push(@tmpbeg,$itres);
	    ++$cth;
	    $tmplen[$cth]=1;
	    $prev=1;}
	else {
	    ++$tmplen[$cth];}
    }
				# set last
    $tmpend[$cth]=$tmplen[$cth] if (! defined $tmpend[$cth]);
				# --------------------------------------------------
				# find short ones
    foreach $it (1..$#tmpbeg){
				# no change for helix longer than two
	next if ($tmplen[$it]>2);
				# no change for 'HH' terminal helices
	next if ($tmpbeg[$it]==1 || $tmpend[$it]==$rdb{"NROWS"});
				# ------------------------------
				# helix of one 
	if ($tmplen[$it]==1){
				# terminal -> purge
	    if ($tmpbeg[$it]==2                              || # one residue off N-term
		$tmpend[$it]==($rdb{"NROWS"}-1)              ||	# one residue off C-term
		$rdb{$tmpbeg[$it],"RI_S"} < $riSwitchLoc     ||	# low reliability
		$rdb{($tmpbeg[$it]+1),"RI_S"} > $riSwitchLoc ||	# high reliability of next loop
		$rdb{($tmpbeg[$it]+1),"RI_S"} > $riSwitchLoc){	# high reliability of prev loop
		$rdb{$tmpbeg[$it],"RI_S"}=0;
		$rdb{$tmpbeg[$it],"PHEL"}=$symLoopLoc; }
				# really extend into both directions!!
	    else {
		$rdb{$tmpbeg[$it],"RI_S"}=
		    $rdb{($tmpbeg[$it]-1),"RI_S"}=$rdb{($tmpbeg[$it]-1),"RI_S"}=0;
		$rdb{$tmpbeg[$it],"PHEL"}=
		    $rdb{($tmpbeg[$it]-1),"PHEL"}=$rdb{($tmpbeg[$it]-1),"PHEL"}="H";}
	}
				# ------------------------------
				# helix of two
	else {
				#   both below threshold -> delete
	    if    (($rdb{$tmpbeg[$it],"RI_S"}+$rdb{$tmpend[$it],"RI_S"})<2*$riSwitchLoc){
		$rdb{$tmpbeg[$it],"RI_S"}=$rdb{$tmpend[$it],"RI_S"}=0;
		$rdb{$tmpbeg[$it],"PHEL"}=$rdb{$tmpend[$it],"PHEL"}=$symLoopLoc; }
				#   both above, but STRONG flanking loop -> delete
	    elsif ($rdb{($tmpbeg[$it]-1),"RI_S"} > ($riSwitchLoc+1) ||
		   $rdb{($tmpbeg[$it]-1),"RI_S"} > ($riSwitchLoc+1) ){
		$rdb{$tmpbeg[$it],"RI_S"}=$rdb{$tmpend[$it],"RI_S"}=0;
		$rdb{$tmpbeg[$it],"PHEL"}=$rdb{$tmpend[$it],"PHEL"}=$symLoopLoc; }
				#   one above: extend
	    else {
				#   N-term -> add after
		if    ($tmpbeg[$it]==1){ # 
		    $rdb{($tmpend[$it]+1),"RI_S"}=0;
		    $rdb{($tmpend[$it]+1),"PHEL"}="H";}
				#   C-term -> add before
		elsif ($tmpend[$it]==$rdb{"NROWS"}){
		    $rdb{($tmpend[$it]-1),"RI_S"}=0;
		    $rdb{($tmpend[$it]-1),"PHEL"}="H";}
				#   middle -> lowest rel
		else {
				# dance to the right
		    if ($rdb{($tmpend[$it]+1),"RI_S"} < $rdb{($tmpbeg[$it]-1),"RI_S"} ||
			$tmpbeg[$it]==1){
			$rdb{($tmpend[$it]+1),"RI_S"}=0;   # reset reliability index
			$rdb{($tmpend[$it]+1),"PHEL"}="H"; # reset prediction
				# dance to the left
		    }else{
			$rdb{($tmpbeg[$it]-1),"RI_S"}=0;   # reset reliability index
			$rdb{($tmpbeg[$it]-1),"PHEL"}="H"; # reset prediction
		    }}
	    }
	}			# end of case: helix of two
    }				# end of loop over all helices
    return(1,"ok $SBR6");
}				# end of nnOutFilterSecHelix

#===============================================================================
sub nnOutFilterSecStrand {
    local($riSwitchLoc,$symLoopLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnOutFilterSecStrand        filters secondary structure prediction in the
#                               following way:
#                               
#                               IF ('strand') AND length(STRAND) == 1
#                                  IF RELINDEX < 2
#                                     cut
#                                  ELSE
#                                     no change
#                               
#                               
#       in:                     $riSwitchLoc     rel index to decide whether to 
#                                                delete helix or to elongate
#       in:                     $symLoopLoc      symbol used for loop
#       in/out GLOBAL:          $rdb{"NROWS"},$rdb{"<PHEL|RI_S>",$itres}
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."nnOutFilterSecStrand";
				# check arguments
    return(&errSbr("not def riSwitchLoc!",$SBR6)) if (! defined $riSwitchLoc);
    $symLoopLoc="L"                               if (! defined $symLoopLoc);

				# --------------------------------------------------
				# get helix lengths
    $#tmpbeg=$#tmpbeg=$#tmpend=$prev=$cte=0;
    foreach $itres (1..$rdb{"NROWS"}){
	next if ($prof_skip{$itres} || ! defined $rdb{$itres,"PHEL"});
	if    ($rdb{$itres,"PHEL"} ne "E") {
	    push(@tmpend,($itres-1))
		if ($prev);
	    $prev=0;}
	elsif (! $prev){ 
	    push(@tmpbeg,$itres);
	    ++$cte;
	    $tmplen[$cte]=1;
	    $prev=1;}
	else {
	    ++$tmplen[$cte];}
    }
				# set last
    $tmpend[$cte]=$tmplen[$cte] if (! defined $tmpend[$cte]);
				# --------------------------------------------------
				# find short ones
    foreach $it (1..$#tmpbeg){
				# no change for strand longer than one
	next if ($tmplen[$it]>1);
				# no change for 'E' terminal helices
	next if ($tmpbeg[$it]==1 || $tmpend[$it]==$rdb{"NROWS"});
				# ------------------------------
				# strand of one 
				# terminal -> purge
	if ($tmpbeg[$it]==2                              ||     # one residue off N-term
	    $tmpend[$it]==($rdb{"NROWS"}-1)              ||	# one residue off C-term
	    $rdb{$tmpbeg[$it],"RI_S"} < $riSwitchLoc     ||	# low reliability
	    $rdb{($tmpbeg[$it]+1),"RI_S"} > $riSwitchLoc ||	# high reliability of next loop
	    $rdb{($tmpbeg[$it]+1),"RI_S"} > $riSwitchLoc){	# high reliability of prev loop
	    $rdb{$tmpbeg[$it],"RI_S"}=0;
	    $rdb{$tmpbeg[$it],"PHEL"}=$symLoopLoc; 
	}
    }				# end of loop over all helices
    return(1,"ok $SBR6");
}				# end of nnOutFilterSecStrand

#===============================================================================
sub nnWrt {
    local($levelHere) = @_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnWrt                       writing NN input 
#                               
#       in:                     $levelHere:     level to run =INTEGER (1st,2nd,3rd)
#                               
#       in GLOBAL:              %prot
#       in GLOBAL:              $par{"para"}=          number of parameter files
#       in GLOBAL:              $par{"para",$ctpar}=   number of levels for file ctpar
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel}= number of files 
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel,$ctfile}= current file
#       in GLOBAL:              $par{"para",$ctpar,$ctlevel,$ctfile,$kwd}= 
#       in GLOBAL:                  with kwd=[modein|modepred|modenet|numin|numhid|numout]
#                               
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"filein"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"filejct"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"argFor"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"modein"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"numwin"}
#       in GLOBAL:              $run{$ctpar,$ctlevel,$ctfile,"origin"}
#                                   $ctpar TAB $ctlevel TAB $ctfile: points
#                                   to another architecture using the same input
#                               
#       out GLOBAL:             
#                               
#       out GLOBAL:             @PRD_EMPTY[1..$numres]= 
#                                              all blank except for those for which 
#                                              no prediction done (since too short)
#                                              those= $par{"symbolPrdShort"}
#                               
#                               
#       out:                    implicit: parameter file, input/output vectors
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."nnWrt";
    $fhoutLoc="FHOUT_"."nnWrt";

				# check arguments
    return(&errSbr("not def levelHere!",$SBR3))               if (! defined $levelHere);
    return(&errSbr("levelHere=$levelHere, no number?",$SBR3)) if (! $levelHere=~/\D/);

				# --------------------------------------------------
				# input file for each mode
				# --------------------------------------------------
    foreach $itpar (1..$run{"npar"}){
	next if (! defined $run{$itpar});          # some strange error!
				# ------------------------------
				# NOTE: only $levelHere taken!!
	$itlevel=$levelHere;
	next if (! defined $run{$itpar,$itlevel}); # current level may not have to be run!

				# ------------------------------
				# loop over all architectures
	foreach $itfile (1..$run{$itpar,$itlevel}){
				# skip if already written
	    next if ($itlevel==1 && $run{$itpar,$itlevel,$itfile,"origin"});

	    foreach $kwd ("modein","modepred","modenet",
			  "numin","numhid","numout",
			  "filein","fileout"){
		return(&errSbr("no kwd=$kwd, itpar=$itpar, itlevel=$itlevel, itfile=$itfile!",
			       $SBR3))
		    if (! defined $run{$itpar,$itlevel,$itfile,$kwd});
		$partmp{$kwd}=  $run{$itpar,$itlevel,$itfile,$kwd};
	    }
	    $numwin=  $run{$itpar,$itlevel,$itfile,"numwin"};
	    $winHalf= ($numwin-1)/2;	# number of spacer residues at begin
	    $depend=  0;
	    $depend=  
		$run{$itpar,$itlevel,$itfile,"depend"} if (defined 
							   $run{$itpar,$itlevel,$itfile,"depend"});
	    
				# --------------------------------------------------
				# open file and write header for input files
	    ($Lok,$msg)=
		&nnWrtHdr($partmp{"filein"},$fhoutLoc,
			  $partmp{"modepred"},$partmp{"modenet"},
			  $partmp{"numin"},$prot{"nres"}
			  );    return(&errSbrMsg("failed on nnWrtHdr:\n",$msg,$SBR3)) if (! $Lok);
	    push(@FILE_REMOVE_TMP,$partmp{"filein"});
				# 1st level
	    if ($itlevel == 1){
		($Lok,$msg,$ctSamTot)=
		    &nnWrtData1st
			($itpar,$itfile,$winHalf,
			 $partmp{"numin"},$partmp{"modein"},$partmp{"modepred"},$par{"numaa"},
			 $fhoutLoc
			 );     return(&errSbrMsg("after nnWrtData1st",$msg,$SBR3)) if (! $Lok); }
	    else {
		($Lok,$msg,$ctSamTot)=
		    &nnWrtData2nd
			($itpar,$itfile,$winHalf,
			 $partmp{"numin"},$partmp{"modein"},$partmp{"modepred"},$fhoutLoc
			 );     return(&errSbrMsg("after nnWrtData2nd",$msg,$SBR3)) if (! $Lok); }

				# write final line and close file
	    print $fhoutLoc "\/\/\n";
	    close($fhoutLoc)    if ($fhoutLoc !~/^STD/);
	    
				# warning if numres wrong
	    print $FHTRACE
		"-** STRONG WARN $SBR3: NN wrote $ctSamTot samples, prot has ",
		$prot{"nres"},
		" residues (par=$itpar,level=$itlevel,file=$itfile)!!\n"
		    if ($ctSamTot != $prot{"nres"});
	}			# end of loop over all files at level $itlevel
    }				# end of loop over all parameter files

                                # ------------------------------
                                # save memory
    undef %tmp;			# slim-is-in !
    $#tmp=$#vecGlob=0;		# slim-is-in !
    return(1,"ok $SBR3");
}				# end of nnWrt

#===============================================================================
sub nnWrtHdr {
    local($fileinLoc,$fhoutLoc,$taskPredLoc,$taskNetLoc,$numinLoc,$numsamLoc)=@_;
    my($SBR4,$fhinLoc,$tmp,$Lok,@nnInHdr);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnWrtHdr                    opens file and writes header of FORTRAN input files
#       in:                     $fileinLoc,$fhinLoc,$taskPredLoc,$taskNetLoc
#-------------------------------------------------------------------------------
    $SBR4=""."nnWrtHdr";

    open($fhoutLoc,">".$fileinLoc) ||
	return(&errSbr("failed to open new fileinLoc=$fileinLoc!",$SBR4))
	    if ($fhoutLoc !~/^STD/);

    print $fhoutLoc 
	"* ","NNin_in              file for FORTRAN NN.f (input vectors)","\n",
	"* ","-" x 65 ," ","\n",
	"* ","Parameter input for neural network (nn)","\n",
	"* ","~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"," ","\n",
	"* ",$par{"txt","copyright"},"\n",
	"* ","fax:   ".$par{"txt","contactFax"},"\n",
	"* ","email: ".$par{"txt","contactEmail"},"\n",
	"* ","www:   ".$par{"txt","contactWeb"},"\n";
    print $fhoutLoc
	"* ","date:  $Date","\n"         if (defined $Date);

    print $fhoutLoc
	"* ","$taskPredLoc","\n",
	"* ","$taskNetLoc","\n",
	"* ","mode:  tvt","\n",
	"* ","-" x 65 ," ","\n";
                                # ------------------------------
				# write top information
				# ------------------------------
    $tmpFormat="8d";
    print  $fhoutLoc "* ","-" x 20,"\n","* overall: (A,T25,I8)\n";
    
    printf $fhoutLoc "%-22s: %$tmpFormat\n","NUMIN"     , $numinLoc;
    printf $fhoutLoc "%-22s: %$tmpFormat\n","NUMSAMFILE", $numsamLoc;
    print  $fhoutLoc "* ","-" x 20,"\n","* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)\n";
    return(1,"ok $SBR4");
}				# end of nnWrtHdr

#===============================================================================
sub nnWrtData1st {
    local($itpar,$itfile,$winHalf,$numinLoc,$modeinLoc,$modepredLoc,$numaaLoc,$fhoutLoc)=@_;
    my($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnWrtData1st                processes the %prot input and writes FORTRANin
#                               
#       in:                     $itpar:    level of parameter file =INTEGER
#       in:                     $itfile:   number of file
#                               
#       in:                     $fileOutNet:   network output
#       in:                     $winHalfLoc:   half window length = (numwin-1)/2
#       in:                     $numinLoc=     number of input units, used for error check
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#       in:                     $numaaLoc=     21
#       in:                     $fhoutLoc=     file_handle to write %vecIn
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#                               
#       in GLOBAL:              @protChainBreaks from &prot2nn_countChainBreaks: number of chains
#                                      [$it]   beg-end
#                               
#       out GLOBAL:             @PRD_EMPTY[1..$numres]= 
#                                              all blank except for those for which 
#                                              no prediction done (since too short)
#                                              those= $par{"symbolPrdShort"}
#                               
#       out:                    1|0,$msg,$ctSamTot
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnWrtData1st"; $fhinLoc="FHINLOC_".$SBR4; 

    return(&errSbr("not def itpar!",      $SBR4)) if (! defined $itpar);
    return(&errSbr("not def itfile!",     $SBR4)) if (! defined $itfile);
    return(&errSbr("not def winHalf!",    $SBR4)) if (! defined $winHalf);
    return(&errSbr("not def numinLoc!",   $SBR4)) if (! defined $numinLoc);
    return(&errSbr("not def modeinLoc!",  $SBR4)) if (! defined $modeinLoc);
    return(&errSbr("not def modepredLoc!",$SBR4)) if (! defined $modepredLoc);
    return(&errSbr("not def numaaLoc!",   $SBR4)) if (! defined $numaaLoc);
    return(&errSbr("not def fhoutLoc!",   $SBR4)) if (! defined $fhoutLoc);

				# --------------------------------------------------
				# (1) assign modein specifics (e.g. hydro)
				#     returns %nnout
				# --------------------------------------------------
    ($Lok,$msg)=
	&assData_inputUnits($winHalf,$modeinLoc,$numaaLoc
			    );  return(&errSbrMsg("after assData_inputUnits(1): $itpar,$itfile, ".
						  " ($winHalf,$modeinLoc,$numaaLoc)",
						  $msg,$SBR4)) if (! $Lok); 
				# --------------------------------------------------
				# (2) get meaning of input units
				#     in  GLOBAL:  %prot
				#     out GLOBAL:  @codeUnitIn1st
				#     out GLOBAL:  @num_codeUnitIn (if $Ldobuild2nd)
				# --------------------------------------------------
    if (! defined @codeUnitIn1st) {
	($Lok,$msg)=
	    &decode_inputUnits1st($winHalf,$modeinLoc,$numaaLoc
				  ); return(&errSbrMsg("spoiled decode_inputUnits1st(1)",
						       $msg,$SBR4)) if (! $Lok); }
				# --------------------------------------------------
				# (4) get global input vectors
				# 
				#     out GLOBAL: @vecGlob
				# --------------------------------------------------
    $#vecGlob=0;
    push(@vecGlob,split(/,/,$prot_seqGlobComp)) if ($modeinLoc=~/comp/); # global AA composition
    push(@vecGlob,split(/,/,$prot_seqGlobLen))  if ($modeinLoc=~/len/);  # length of protein
    push(@vecGlob,split(/,/,$prot_seqGlobNali)) if ($modeinLoc=~/nali/); # no of homologues
    push(@vecGlob,split(/,/,$prot_seqGlobNfar)) if ($modeinLoc=~/nfar/); # no of distant homologues

				# --------------------------------------------------
				# (5) loop over chains (in, only)
				# --------------------------------------------------
    $ctSamBreak=$ctSamTot=0;
    undef %prd;
    $ctres=0;
    foreach $itbreak (1..$#protChainBreaks){
	($BEG,$END)=split(/\-/,$protChainBreaks[$itbreak]);
	$LEN=1 + $END - $BEG; 
				# ------------------------------
				# too short -> store NO PREDICTION
				#     WRITE immediately
	if ($LEN < $par{"numresMin"}){
	    $PROF_SKIP=1;
	    foreach $itres ($BEG..$END){
		$prof_skip{$itres}=1;
		foreach $itin (1..$numinLoc){
		    push(@vecIn,0);
		}
		($Lok,$msg)=
		    &vecInWrt
			($itres,$fhoutLoc,$numinLoc
			 );     return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR4)) if (! $Lok); 
	    }
	    $Lskip=1;}
	else {
	    $Lskip=0;
	    foreach $itres ($BEG..$END){
		$prof_skip{$itres}=0;}}
				# ------------------------------
				# short: skip further stuff!
	next if ($Lskip);

	print $FHTRACE2 "--- dbg ($SBR4): itbreak=$itbreak, $BEG-$END=$LEN ($itpar:1:$itfile)\n" 
	    if ($par{"verb2"});
				# ------------------------------
				# loop over all residues
				# ------------------------------
	&errSbr("modepred (",$modepredLoc,") not understood\n",$SBR4) 
	    if ($modepredLoc !~ /^sec/ && $modepredLoc !~ /^acc/ && $modepredLoc !~ /^htm/);
	
				# ------------------------------
				# loop over all residues
				# ------------------------------
	if    ($modeinLoc =~ /aa\-cw\-nins\-ndel.*,.*len\-dis\-comp\-/ &&
	       $modeinLoc =~ /eisen|ooi|salt/){
	    ($Lok,$msg)=
		&assData_vecIn1stHydro
		    ($winHalf,$BEG,$END,$LEN,$numaaLoc,$numinLoc,$modepredLoc
		     );         return(&errSbrMsg("after call assData_vecIn1stHydro",
						  $msg,$SBR4)) if (! $Lok);}

	elsif ($modeinLoc =~ /aa\-cw\-nins\-ndel,.*len\-dis\-comp/){
	    ($Lok,$msg)=
		&assData_vecIn1stNOThydro
		    ($winHalf,$BEG,$END,$LEN,$numaaLoc,$numinLoc,$modepredLoc
		     );         return(&errSbrMsg("after call assData_vecIn1stNOThydro",
						  $msg,$SBR4)) if (! $Lok);}
	else {
	    ($Lok,$msg)=
		&assData_vecIn1st
		    ($winHalf,$BEG,$END,$LEN,$numaaLoc,$modeinLoc,$numinLoc,$modepredLoc
		     );          return(&errSbrMsg("after call assData_vecIn1st",
						   $msg,$SBR4)) if (! $Lok);}

    }				# end of loop over all chains
				# --------------------------------------------------

				# ------------------------------
				# clean up
    undef %vecIn;		# slim-is-in
				# ------------------------------
				# clean up
    $#vecDis=$#vecGlob=0;	# slim-is-in


    return(1,"ok $SBR4",$ctSamTot);
}				# end of nnWrtData1st

#===============================================================================
sub nnWrtData2nd {
    local($itpar,$itfile,$winHalf,$numinLoc,$modeinLoc,$modepredLoc,$fhoutLoc)=@_;
    my($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnWrtData2nd                processes the %prot input and writes FORTRANin
#                               
#       in:                     $itpar:        level of parameter file =INTEGER
#       in:                     $itfile:       number of file
#       in:                     $winHalf:      half window length = (numwin-1)/2
#       in:                     $numinLoc=     number of input units, used for error check
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#       in:                     $numaaLoc=     21
#       in:                     $fhoutLoc=     file_handle to write %vecIn
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#                               
#       out GLOBAL:             @PRD_EMPTY[1..$numres]= 
#                                              all blank except for those for which 
#                                              no prediction done (since too short)
#                                              those= $par{"symbolPrdShort"}
#                               
#       out:                    1|0,$msg,$ctSamTot
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnWrtData2nd"; $fhinLoc="FHINLOC_".$SBR4; 

    return(&errSbr("not def itpar!",      $SBR4)) if (! defined $itpar);
    return(&errSbr("not def itfile!",     $SBR4)) if (! defined $itfile);
    return(&errSbr("not def winHalf!",    $SBR4)) if (! defined $winHalf);
    return(&errSbr("not def numinLoc!",   $SBR4)) if (! defined $numinLoc);
    return(&errSbr("not def modeinLoc!",  $SBR4)) if (! defined $modeinLoc);
    return(&errSbr("not def modepredLoc!",$SBR4)) if (! defined $modepredLoc);
    return(&errSbr("not def fhoutLoc!",   $SBR4)) if (! defined $fhoutLoc);

    &errSbr("modepred (",$modepredLoc,") not understood\n",$SBR4) 
	if ($modepredLoc !~ /^sec/ && $modepredLoc !~ /^acc/ && $modepredLoc !~ /^htm/);
	
				# --------------------------------------------------
				# (1) read network output
				#     returns %nnout
				# yyy for more than one dependency: change
				# --------------------------------------------------
    if ($modeinLoc=~/winout=(\d+)/){
	$winoutLoc=$1;
	($Lok,$msg)=
	    &assData_nnoutwin($itpar,2,$itfile,$winoutLoc
			      );return(&errSbrMsg("after assData_nnoutwin ($itpar,2,$itfile,$winoutLoc)",
						  $msg,$SBR4)) if (! $Lok); }
    else {
	($Lok,$msg)=
	    &assData_nnout($itpar,2,$itfile
			   );   return(&errSbrMsg("after assData_nnout ($itpar,2,$itfile)",
						  $msg,$SBR4)) if (! $Lok); }

				# --------------------------------------------------
				# (2) get global input vectors
				# 
				#     out GLOBAL: @vecGlob
				# --------------------------------------------------
    $#vecGlob=0;
    push(@vecGlob,split(/,/,$prot_seqGlobComp)) if ($modeinLoc=~/comp/); # global AA composition
    push(@vecGlob,split(/,/,$prot_seqGlobLen))  if ($modeinLoc=~/len/);  # length of protein
    push(@vecGlob,split(/,/,$prot_seqGlobNali)) if ($modeinLoc=~/nali/); # no of homologues
    push(@vecGlob,split(/,/,$prot_seqGlobNfar)) if ($modeinLoc=~/nfar/); # no of distant homologues
    
				# --------------------------------------------------
				# (6) loop over chains (in, only)
				# --------------------------------------------------
    $ctSamBreak=$ctSamTot=0;
    undef %prd;
    $ctres=0;

    foreach $itbreak (1..$#protChainBreaks){
	($BEG,$END)=split(/\-/,$protChainBreaks[$itbreak]);
	$LEN=1 + $END - $BEG; 
				# ------------------------------
				# too short -> store NO PREDICTION
				#     WRITE immediately
	if ($LEN < $par{"numresMin"}){
	    $PROF_SKIP=1;
	    foreach $itres ($BEG..$END){
		$prof_skip{$itres}=1;
		foreach $itin (1..$numinLoc){
		    push(@vecIn,0);
		}
		($Lok,$msg)=
		    &vecInWrt
			($itres,$fhoutLoc,$numinLoc
			 );     return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR4)) if (! $Lok); 
	    }
	    $Lskip=1;}
	else {
	    $Lskip=0;
	    foreach $itres ($BEG..$END){
		$prof_skip{$itres}=0;}}
				# ------------------------------
				# short: skip further stuff!
	next if ($Lskip);

	print $FHTRACE2 "--- dbg ($SBR4): itbreak=$itbreak, $BEG-$END=$LEN ($itpar:1:$itfile)\n" 
	    if ($par{"verb2"});

				# ------------------------------
				# loop over all residues
				# ------------------------------
	if    ($modeinLoc =~ /str\-win\-rel\-cw.*,.*len\-dis\-comp/){
	    ($Lok,$msg)=
		&assData_vecIn2ndAll
		    ($winHalf,$BEG,$END,$LEN,$numinLoc
		     );         return(&errSbrMsg("after call assData_vecIn2ndAll",
						  $msg,$SBR4)) if (! $Lok);}
	else {
	    ($Lok,$msg)=
		&assData_vecIn2nd
		    ($winHalf,$BEG,$END,$LEN,$modeinLoc,$numinLoc
		     );         return(&errSbrMsg("after call assData_vecIn2nd",
						  $msg,$SBR4)) if (! $Lok);}

    }				# end of loop over all chains
				# --------------------------------------------------

				# ------------------------------
				# clean up
    $#vecDis=$#vecGlob=0;	# slim-is-in


    return(1,"ok $SBR4",$ctSamTot);
}				# end of nnWrtData2nd

#===============================================================================
sub assData_inputUnits {
    local($winHalfLoc,$modeinLoc,$numaaLoc)=@_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_inputUnits          adds numbers and keywords for additional
#                               input modes specific to current input mode
#                               also correct accessibility and sec for breaks
#   in GLOBAL:                  %prot,@hydrophobicityScalesWanted
#   out GLOBAL:                 $HYDRO{}
#-------------------------------------------------------------------------------
    $SBR3=""."assData_countChainBreaks";$fhinLoc="FHIN_"."assData_countChainBreaks";
    $#tmp=0;
				# ------------------------------
				# set hydrophobicity: 
				# 1*$numwin  units per scale
				# 3 units per scale of sum (i,i+2),(i,i+3),(i,i+4)
				# global OUT: %HYDRO{"scale",$aa,"norm"}
				# ------------------------------
    $#hydrophobicityScalesWanted=$#hydrophobicityScalesWantedSum=$nunits_hydro=0;
    undef %tmp; $scale="";
    foreach $tmp (@hydrophobicityScales){
	if ($modeinLoc=~/loc=[a-z0-9\-]*$tmp/){
	    push(@hydrophobicityScalesWanted,$tmp);
	    if (! defined $tmp{$tmp}){
		$tmp{$tmp}=1;
		$scale.=$tmp.",";}}
	if ($modeinLoc=~/(sum|SUM|Sum)$tmp/){
	    push(@hydrophobicityScalesWantedSum,$tmp);
	    if (! defined $tmp{$tmp}){
		$tmp{$tmp}=1;
		$scale.=$tmp.",";}}
    }
    $nunits_hydro= (2*$winHalfLoc+1)*$#hydrophobicityScalesWanted;
    $nunits_hydro+=3*$#hydrophobicityScalesWantedSum;

    return(1,"ok $SBR3");
}				# end of assData_inputUnits

#===============================================================================
sub assData_nnout {
    local($itpar,$itlevel,$itfile)=@_;
    my($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_nnout               reads all necessary NNoutput files
#                               
#       in:                     $itpar:    level of parameter file =INTEGER
#       in:                     $itlevel:  level to run            =INTEGER (1st,2nd,3rd)
#       in:                     $itfile:   number of file
#                               
#       in GLOBAL:              $run{}
#       in:                     $depend:       current architecture depends on $depend
#                                   'i1:j1,i2:j2'
#                                   -> depends on j1-th architecture on level i1 
#                                      AND on j2-th architecture on level i2
#                               
#       out GLOBAL:             %nnout
#       out:                    1|0,$msg,$ctSamTot
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."assData_nnout"; $fhinLoc="FHINLOC_".$SBR3; 

				# ------------------------------
				# MUST exist here!
    return(&errSbr("not defined job{'depend'} for ($itpar,$itlevel,$itfile)",$SBR3))
	if (! defined $run{$itpar,$itlevel,$itfile,"depend"});
				# ------------------------------
				# get all dependent files
    @depend=split(/,/,$run{$itpar,$itlevel,$itfile,"depend"});

     if ($#depend > 1) {
 	print "*** ERROR dependency not fully implemented, yet!!\n";
 	print "*** to change: all sbrs vecGetIn* using nnout{}!\n";
 	die; }

				# --------------------------------------------------
				# loop over all network output(s)
				#     returns %nnout
				# --------------------------------------------------
    undef %nnout;
    foreach $depend (@depend){
	($itlevelHere,$itfileHere)=split(/:/,$depend);
	return(&errSbr("not def fileout depend=$depend, ($itlevelHere,$itfileHere)",
		       $SBR3)) if (! defined $run{$itpar,$itlevelHere,$itfileHere,"fileout"});
	$fileOutNet=$run{$itpar,$itlevelHere,$itfileHere,"fileout"};
	$modeoutTmp=$run{$itpar,$itlevelHere,$itfileHere,"modeout"};

	return(&errSbr("missing fileout=$fileOutNet depend=$depend, ($itlevelHere,".
		       "$itfileHere)",$SBR3)) if (! -e $fileOutNet);
	($Lok,$msg,$numres,$numout)=
	    &nnOutRdDepend
		($fileOutNet,$depend
		 );             return(&errSbrMsg("nnOutRdDepend (depend=$depend,$fileOutNet)",
						   $msg,$SBR3)) if (! $Lok);
				# get reliability index
	if ($run{$itpar,$itlevel,$itfile,"modein"}=~/rel/){
	    foreach $itres (1..$numres){
		$#tmp=0;
		foreach $itout (1..$numout){
		    push(@tmp,$nnout_out[$itres]->[$itout]);
		}
		($Lok,$msg,$ri)=
		    &get_ri($run{$itpar,$itlevel,$itfile,"modepred"},$par{"bitacc"},@tmp
			    ); return(&errSbrMsg("after nnOutGetRi (".
						 $run{$itpar,$itlevel,$itfile,"modepred"}.
						 ",$itres,out=".
						 join('|',@tmp).") level=$itlevel, file=".
						 $fileOutNet,$msg,$SBR3)) if (! $Lok);
		$nnout_ri[$itres]=int($par{"bitacc"} * $ri/10);
	    }
	}			# end of reading nnout for one fileout
    }				# end of loop over all dependent outputs
				# --------------------------------------------------

				# ------------------------------
				# clean up
    $#tmp=$#depend=0;		# slim-is-in

    return(1,"ok $SBR3",$ctSamTot);
}				# end of assData_nnout

#===============================================================================
sub assData_nnoutwin {
    local($itpar,$itlevel,$itfile,$winoutLoc)=@_;
    my($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_nnoutwin            reads only output for central output units
#                               
#       in:                     $itpar:     level of parameter file =INTEGER
#       in:                     $itlevel:   level to run            =INTEGER (1st,2nd,3rd)
#       in:                     $itfile:    number of file
#       in:                     $winoutLoc: window of output units
#                               
#       in GLOBAL:              $run{}
#       in:                     $depend:       current architecture depends on $depend
#                                   'i1:j1,i2:j2'
#                                   -> depends on j1-th architecture on level i1 
#                                      AND on j2-th architecture on level i2
#                               
#       out GLOBAL:             %nnout
#       out:                    1|0,$msg,$ctSamTot
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."assData_nnoutwin"; $fhinLoc="FHINLOC_".$SBR3; 

				# ------------------------------
				# MUST exist here!
    return(&errSbr("not defined job{'depend'} for ($itpar,$itlevel,$itfile)",$SBR3))
	if (! defined $run{$itpar,$itlevel,$itfile,"depend"});
				# ------------------------------
				# get all dependent files
    @depend=split(/,/,$run{$itpar,$itlevel,$itfile,"depend"});

     if ($#depend > 1) {
 	print "*** ERROR dependency not fully implemented, yet!!\n";
 	print "*** to change: all sbrs vecGetIn* using nnout{}!\n";
 	die; }

				# --------------------------------------------------
				# loop over all network output(s)
				#     returns %nnout
				# --------------------------------------------------
    undef %nnout;

    foreach $depend (@depend){
	($itlevelHere,$itfileHere)=split(/:/,$depend);
	return(&errSbr("not def fileout depend=$depend, ($itlevelHere,$itfileHere)",
		       $SBR3)) if (! defined $run{$itpar,$itlevelHere,$itfileHere,"fileout"});
	$fileOutNet=$run{$itpar,$itlevelHere,$itfileHere,"fileout"};
	$modeoutTmp=$run{$itpar,$itlevelHere,$itfileHere,"modeout"};

	return(&errSbr("missing fileout=$fileOutNet depend=$depend, ($itlevelHere,".
		       "$itfileHere)",$SBR3)) if (! -e $fileOutNet);
	($Lok,$msg,$numres,$numout)=
	    &nnOutRdDependwin
		($fileOutNet,$depend,$winoutLoc
		 );             return(&errSbrMsg("nnOutRdDependwin (depend=$depend,$fileOutNet)",
						   $msg,$SBR3)) if (! $Lok);
				# get reliability index
	if ($run{$itpar,$itlevel,$itfile,"modein"}=~/rel/){
	    foreach $itres (1..$numres){
		$#tmp=0;
		foreach $itout (1..$numout){
		    push(@tmp,$nnout_out[$itres]->[$itout]);
		}
		($Lok,$msg,$ri)=
		    &get_ri($run{$itpar,$itlevel,$itfile,"modepred"},$par{"bitacc"},@tmp
			    ); return(&errSbrMsg("after nnOutGetRi (".
						 $run{$itpar,$itlevel,$itfile,"modepred"}.
						 ",$itres,out=".
						 join('|',@tmp).") level=$itlevel, file=".
						 $fileOutNet,$msg,$SBR3)) if (! $Lok);
		$nnout_ri[$itres]=int($par{"bitacc"} * $ri/10);
	    }
	}			# end of reading nnout for one fileout
    }				# end of loop over all dependent outputs
				# --------------------------------------------------

				# ------------------------------
				# clean up
    $#tmp=$#depend=0;		# slim-is-in

    return(1,"ok $SBR3",$ctSamTot);
}				# end of assData_nnoutwin

#===============================================================================
sub assData_vecIn1st {
    local($winHalf,$BEG,$END,$LEN,$numaaLoc,$modeinLoc,$numinLoc,$modepredLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn1st            loops over all residues in one chain and writes vecIn
#                               GENERAL version for specialists, see below
#                               
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $numaaLoc:     number of amino acids
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $numinLoc= number of input units
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#                               
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#                               
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn1st";
    $errMsg=
	"\n*** ERROR $SBR5: called with: ".
	    "winHalf=$winHalf, GLOBAL BEG=$BEG, END=$END, modein=$modeinLoc\n";

				# --------------------------------------------------
				# all residues in current chain!
				# (1)  separate parts with diff in %prot and %protacc
				# --------------------------------------------------

    if ($modepredLoc ne "acc"){
	foreach $itres ($BEG..$END){
	    $#vecIn=0;
	    $winBeg=($itres-$winHalf);
	    $winEnd=($itres+$winHalf);
				# local info from window
	    foreach $itwin ($winBeg .. $winEnd){
				# normal residue
		if (defined $prot_seq{$itwin}){
				# ---> sequence profile
		    if ($modeinLoc=~/aa/){
			foreach $itaa (1..$#aa) {
			    push(@vecIn,$prot_prof[$itwin]->[$itaa]); 
			}
				# spacer
			push(@vecIn,0);
		    }
				# ---> conservation weight
		    if ($modeinLoc=~/cw/){
			push(@vecIn,$prot_cons{$itwin});
		    }
				# ---> number of deletions
		    if ($modeinLoc=~/ndel/){
			push(@vecIn,$prot_ndel[$itwin]);
		    }
				# ---> number of insertions
		    if ($modeinLoc=~/nins/){
			push(@vecIn,$prot_nins[$itwin]);
		    }
		}
		else {		# for BEFORE|AFTER
		    if ($modeinLoc=~/aa/){
			foreach $itaa (1..$#aa) {
			    push(@vecIn,0);}         # profile
			push(@vecIn,$par{"bitacc"}); # profile spacer
		    }
		    if ($modeinLoc=~/cw/){
			push(@vecIn,$prot_cons_spacer); # conservation weight
		    }
		    if ($modeinLoc=~/ndel/){
			push(@vecIn,0);                 # deletion
		    }
		    if ($modeinLoc=~/nins/){
			push(@vecIn,0);                 # insertion
		    }
		}
	    }			# end of loop over window
	    
				# ------------------------------
				# global info from outside window
	    push(@vecIn,@vecGlob);
				# global from residue
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# add additional local information: go through window
	    if (defined @hydrophobicityScalesWanted && $#hydrophobicityScalesWanted){
		foreach $itwin (($itres-$winHalf) .. ($itres+$winHalf)){
		    foreach $scale (@hydrophobicityScalesWanted) {
			push(@vecIn,$prot{$itwin,$scale});
		    }
		}}
				# ------------------------------
				# local info: once per window

				# sum over hydrophobicity (i+2,+3,+4)
	    if (defined @hydrophobicityScalesWantedSum && $#hydrophobicityScalesWantedSum){
		foreach $scale (@hydrophobicityScalesWantedSum) {
		    push(@vecIn,split(/,/,$prot{$itres,$scale."sum",($winHalf*2+1)}));
		}}
				# salt bridges
	    push(@vecIn,split(/,/,$prot{$itres,"salt",($winHalf*2+1)}))
		if ($modeinLoc=~/salt/);

				# ------------------------------
				# add additional global info
				# yy may be one day ..


				# ------------------------------
				# security check
	    return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
			   "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
			   $errMsg,$SBR5)) if ($#vecIn != $numinLoc);

				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	    ($Lok,$msg)=
		&vecInWrt($itres,$fhoutLoc,$numinLoc
			  );    return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
	}			# end of loop over all residues (one break)
    }				# end of split %prot


				# ------------------------------
				# DO for ACC
    else {
	foreach $itres ($BEG..$END){
	    $#vecIn=0;
	    $winBeg=($itres-$winHalf);
	    $winEnd=($itres+$winHalf);
				# local info from window
	    foreach $itwin ($winBeg .. $winEnd){
				# normal residue
		if (defined $prot_seq{$itwin}){
				# ---> sequence profile
		    if ($modeinLoc=~/aa/){
			foreach $itaa (1..$#aa) {
			    push(@vecIn,$protacc_prof[$itwin]->[$itaa]); 
			}
				# spacer
			push(@vecIn,0);
		    }
				# ---> conservation weight
		    if ($modeinLoc=~/cw/){
			push(@vecIn,$protacc_cons[$itwin]);
		    }
				# ---> number of deletions
		    if ($modeinLoc=~/ndel/){
			push(@vecIn,$protacc_ndel[$itwin]);
		    }
				# ---> number of insertions
		    if ($modeinLoc=~/nins/){
			push(@vecIn,$protacc_nins[$itwin]);
		    }
		}
		else {		# for BEFORE|AFTER
		    if ($modeinLoc=~/aa/){
			foreach $itaa (1..$#aa) {
			    push(@vecIn,0);}         # profile
			push(@vecIn,$par{"bitacc"}); # profile spacer
		    }
		    if ($modeinLoc=~/cw/){
			push(@vecIn,$prot_cons_spacer); # conservation weight
		    }
		    if ($modeinLoc=~/ndel/){
			push(@vecIn,0);                 # deletion
		    }
		    if ($modeinLoc=~/nins/){
			push(@vecIn,0);                 # insertion
		    }
		}
	    }			# end of loop over window
	    
				# ------------------------------
				# global info from outside window
	    push(@vecIn,@vecGlob);
				# global from residue
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# add additional local information: go through window
	    if (defined @hydrophobicityScalesWanted && $#hydrophobicityScalesWanted){
		foreach $itwin (($itres-$winHalf) .. ($itres+$winHalf)){
		    foreach $scale (@hydrophobicityScalesWanted) {
			push(@vecIn,$prot{$itwin,$scale});
		    }
		}}
				# ------------------------------
				# local info: once per window

				# sum over hydrophobicity (i+2,+3,+4)
	    if (defined @hydrophobicityScalesWantedSum && $#hydrophobicityScalesWantedSum){
		foreach $scale (@hydrophobicityScalesWantedSum) {
		    push(@vecIn,split(/,/,$prot{$itres,$scale."sum",($winHalf*2+1)}));
		}}
				# salt bridges
	    push(@vecIn,split(/,/,$prot{$itres,"salt",($winHalf*2+1)}))
		if ($modeinLoc=~/salt/);

				# ------------------------------
				# add additional global info
				# yy may be one day ..


				# ------------------------------
				# security check
	    return(&errSbr("ACC: itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
			   "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
			   $errMsg,$SBR5)) if ($#vecIn != $numinLoc);

				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	    ($Lok,$msg)=
		&vecInWrt($itres,$fhoutLoc,$numinLoc
			  );    return(&errSbrMsg("after vecInWrt(acc,$itres)",$msg,$SBR5)) if (! $Lok); 
	}			# end of loop over all residues (one break)
    }				# end of split %protacc
				# --------------------------------------------------

				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn1st

#===============================================================================
sub assData_vecIn1stHydro {
    local($winHalf,$BEG,$END,$LEN,$numaaLoc,$numinLoc,$modepredLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn1stHydro       loops over all residues in one chain and writes vecIn
#                               
#                               ==================================================
#                               expected input modein:
#                               loc=aa-cw-nins-ndel-<hydro>,glob=nali-nfar-len-dis-comp-sum<>-salt
#                               ==================================================
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $numaaLoc:     number of amino acids
#       in:                     $numinLoc= number of input units
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn1stHydro";

    $errMsg=
	"\n*** ERROR $SBR5: called with: ".
	    "winHalf=$winHalf, GLOBAL BEG=$BEG, END=$END, modein=$modeinLoc\n";

				# --------------------------------------------------
				# all residues in current chain!
				# --------------------------------------------------
				# (1)  separate parts with diff in %prot and %protacc
				# --------------------------------------------------
    if ($modepredLoc ne "acc"){

	foreach $itres ($BEG .. $END){
	    $#vecIn=0;
	    $winBeg=($itres-$winHalf);
	    $winEnd=($itres+$winHalf);
				# local info from window
	    foreach $itwin ($winBeg .. $winEnd){
				# normal residue
		if (defined $prot_seq{$itwin}){
				# ---> sequence profile
		    foreach $itaa (1..$#aa) {
			push(@vecIn,$prot_prof[$itwin]->[$itaa]); 
		    }
				# spacer
		    push(@vecIn,0);
				# ---> conservation weight
		    push(@vecIn,$prot_cons{$itwin});
				# ---> number of deletions
		    push(@vecIn,$prot_ndel[$itwin]);
				# ---> number of insertions
		    push(@vecIn,$prot_nins[$itwin]);
		}
		else {		# for BEFORE|AFTER
		    foreach $itaa (1..$#aa) {
			push(@vecIn,0);}            # profile
		    push(@vecIn,$par{"bitacc"});    # profile spacer
		    push(@vecIn,$prot_cons_spacer); # conservation weight
		    push(@vecIn,0);                 # deletion
		    push(@vecIn,0);                 # insertion
		}
	    }
				# ------------------------------
				# global info from outside window
	    push(@vecIn,@vecGlob);
				# global from residue
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# add additional local information: go through window
	    if (defined @hydrophobicityScalesWanted && $#hydrophobicityScalesWanted){
		foreach $itwin (($itres-$winHalf) .. ($itres+$winHalf)){
		    foreach $scale (@hydrophobicityScalesWanted) {
			if (defined $prot_hydro{$itwin,$scale}){
			    push(@vecIn,$prot_hydro{$itwin,$scale});}
			else{
			    push(@vecIn,0);}
		    }
		}}
				# ------------------------------
				# local info: once per window

				# sum over hydrophobicity (i+2,+3,+4)
	    if (defined @hydrophobicityScalesWantedSum && $#hydrophobicityScalesWantedSum){
		foreach $scale (@hydrophobicityScalesWantedSum) {
		    if (defined $prot_hydro{$itres,$scale."sum",($winHalf*2+1)}){
			push(@vecIn,split(/,/,$prot_hydro{$itres,$scale."sum",($winHalf*2+1)}));}
		    else {
			    push(@vecIn,0);}
		}}
				# salt bridges
	    if ($modeinLoc=~/salt/){
		if (defined $prot_hydro{$itres,"salt",($winHalf*2+1)}){
		    push(@vecIn,split(/,/,$prot_hydro{$itres,"salt",($winHalf*2+1)}));}
		else {
		    push(@vecIn,0);}
	    }

				# ------------------------------
				# security check
	    return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
			   "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
			   $errMsg,$SBR5)) if ($#vecIn != $numinLoc);
				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	    ($Lok,$msg)=
		&vecInWrt($itres,$fhoutLoc,$numinLoc
			  );    return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
	}			# end loop over all residues
    }				# enf of NON-acc

				# ------------------------------
				# DO for ACC
    else {
	foreach $itres ($BEG .. $END){
	    $#vecIn=0;
	    $winBeg=($itres-$winHalf);
	    $winEnd=($itres+$winHalf);
				# local info from window
	    foreach $itwin ($winBeg .. $winEnd){
				# normal residue
		if (defined $prot_seq{$itwin}){
				# ---> sequence profile
		    foreach $itaa (1..$#aa) {
			push(@vecIn,$protacc_prof[$itwin]->[$itaa]); 
		    }
				# spacer
		    push(@vecIn,0);
				# ---> conservation weight
		    push(@vecIn,$protacc_cons[$itwin]);
				# ---> number of deletions
		    push(@vecIn,$protacc_ndel[$itwin]);
				# ---> number of insertions
		    push(@vecIn,$protacc_nins[$itwin]);
		}
		else {		# for BEFORE|AFTER
		    foreach $itaa (1..$#aa) {
			push(@vecIn,0);}            # profile
		    push(@vecIn,$par{"bitacc"});    # profile spacer
		    push(@vecIn,$prot_cons_spacer); # conservation weight
		    push(@vecIn,0);                 # deletion
		    push(@vecIn,0);                 # insertion
		}
	    }
				# ------------------------------
				# global info from outside window
	    push(@vecIn,@vecGlob);
				# global from residue
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# add additional local information: go through window
	    if (defined @hydrophobicityScalesWanted && $#hydrophobicityScalesWanted){
		$#tmp=0;
		foreach $itwin (($itres-$winHalf) .. ($itres+$winHalf)){
		    foreach $scale (@hydrophobicityScalesWanted) {
			if (defined $prot_hydro{$itwin,$scale}){
			    push(@vecIn,$prot_hydro{$itwin,$scale});}
			else{
			    push(@vecIn,0);}
		    }
		}}

				# ------------------------------
				# local info: once per window
				# sum over hydrophobicity (i+2,+3,+4)
	    if (defined @hydrophobicityScalesWantedSum && $#hydrophobicityScalesWantedSum){
		$#tmp=0;
		foreach $scale (@hydrophobicityScalesWantedSum) {
		    if (defined $prot_hydro{$itres,$scale."sum",($winHalf*2+1)}){
			push(@vecIn,split(/,/,$prot_hydro{$itres,$scale."sum",($winHalf*2+1)}));
			push(@tmp,split(/,/,$prot_hydro{$itres,$scale."sum",($winHalf*2+1)}));
		    }
		    else {
			push(@vecIn,0);}
		}}
				# salt bridges
	    if ($modeinLoc=~/salt/){
		if (defined $prot_hydro{$itres,"salt",($winHalf*2+1)}){
		    push(@vecIn,split(/,/,$prot_hydro{$itres,"salt",($winHalf*2+1)}));}
		else {
		    push(@vecIn,0);}
	    }

				# ------------------------------
				# security check
	    return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
			   "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
			   $errMsg,$SBR5)) if ($#vecIn != $numinLoc);
				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	    ($Lok,$msg)=
		&vecInWrt($itres,$fhoutLoc,$numinLoc
			  );    return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
	}			# end of loop over residues
    }				# end of difference between %prot and %protacc
				# --------------------------------------------------

				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn1stHydro

#===============================================================================
sub assData_vecIn1stNOThydro {
    local($winHalf,$BEG,$END,$LEN,$numaaLoc,$numinLoc,$modepredLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn1stNOThydro    loops over all residues in one chain and writes vecIn
#                               all input sequence stuff EXCEPT hydro
#                               
#                               ==================================================
#                               expected input modein:
#                               loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp
#                               ==================================================
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $numaaLoc:     number of amino acids
#       in:                     $numinLoc= number of input units
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn1stNOThydro";

    $errMsg=
	"\n*** ERROR $SBR5: called with: ".
	    "winHalf=$winHalf, GLOBAL BEG=$BEG, END=$END, modein=$modeinLoc\n";

				# --------------------------------------------------
				# all residues in current chain!
				# (1)  separate parts with diff in %prot and %protacc
				# --------------------------------------------------
    if ($modepredLoc ne "acc"){
	foreach $itres ($BEG .. $END){
	    $#vecIn=0;
	    $winBeg=($itres-$winHalf);
	    $winEnd=($itres+$winHalf);
				# local info from window
	    foreach $itwin ($winBeg .. $winEnd){
				# normal residue
		if (defined $prot_seq{$itwin}){
				# ---> sequence profile
		    foreach $itaa (1..$#aa) {
			push(@vecIn,$prot_prof[$itwin]->[$itaa]); 
		    }
				# spacer
		    push(@vecIn,0);
				# ---> conservation weight
		    push(@vecIn,$prot_cons{$itwin});
				# ---> number of deletions
		    push(@vecIn,$prot_ndel[$itwin]);
				# ---> number of insertions
		    push(@vecIn,$prot_nins[$itwin]);
		}
		else {		# for BEFORE|AFTER
		    foreach $itaa (1..$#aa) {
			push(@vecIn,0);}            # profile
		    push(@vecIn,$par{"bitacc"});    # profile spacer
		    push(@vecIn,$prot_cons_spacer); # conservation weight
		    push(@vecIn,0);                 # deletion
		    push(@vecIn,0);                 # insertion
		}
	    }
				# ------------------------------
				# global info from outside window
	    push(@vecIn,@vecGlob);
				# global from residue
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# security check
	    return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
			   "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
			   $errMsg,$SBR5)) if ($#vecIn != $numinLoc);
				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	    ($Lok,$msg)=
		&vecInWrt($itres,$fhoutLoc,$numinLoc
			  );    return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
	}			# end loop over all residues
    }				# enf of NON-acc

				# ------------------------------
				# DO for ACC
    else {
	foreach $itres ($BEG .. $END){
	    $#vecIn=0;
	    $winBeg=($itres-$winHalf);
	    $winEnd=($itres+$winHalf);
				# local info from window
	    foreach $itwin ($winBeg .. $winEnd){
				# normal residue
		if (defined $prot_seq{$itwin}){
				# ---> sequence profile
		    foreach $itaa (1..$#aa) {
			push(@vecIn,$protacc_prof[$itwin]->[$itaa]); 
		    }
				# spacer
		    push(@vecIn,0);
				# ---> conservation weight
		    push(@vecIn,$protacc_cons[$itwin]);
				# ---> number of deletions
		    push(@vecIn,$protacc_ndel[$itwin]);
				# ---> number of insertions
		    push(@vecIn,$protacc_nins[$itwin]);
		}
		else {		# for BEFORE|AFTER
		    foreach $itaa (1..$#aa) {
			push(@vecIn,0);}            # profile
		    push(@vecIn,$par{"bitacc"});    # profile spacer
		    push(@vecIn,$prot_cons_spacer); # conservation weight
		    push(@vecIn,0);                 # deletion
		    push(@vecIn,0);                 # insertion
		}
	    }
				# ------------------------------
				# global info from outside window
	    push(@vecIn,@vecGlob);
				# global from residue
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# security check
	    return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
			   "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
			   $errMsg,$SBR5)) if ($#vecIn != $numinLoc);
				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	    ($Lok,$msg)=
		&vecInWrt($itres,$fhoutLoc,$numinLoc
			  );    return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
	}			# end of loop over residues
    }				# end of difference between %prot and %protacc
				# --------------------------------------------------

				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn1stNOThydro

#===============================================================================
sub assData_vecIn2nd {
    local($winHalf,$BEG,$END,$LEN,$modeinLoc,$numinLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn2nd            loops over all residues in one chain and writes vecIn
#                               GENERAL version for specialists, see below
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $numinLoc= number of input units
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#                               
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#                               
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn2nd";

				# --------------------------------------------------
				# all residues in current chain!
				# --------------------------------------------------

    foreach $itres ($BEG..$END){
	$#vecIn=0;
	$winBeg=($itres-$winHalf);
	$winEnd=($itres+$winHalf);
				# local info from window
	foreach $itwin ($winBeg .. $winEnd){
				# normal residue
	    if (defined $prot_seq{$itwin}){
				# ---> in: predictions
		if ($modeinLoc =~/str/){
		    foreach $itout (1..$numout){
			push(@vecIn,$nnout_prob[$itwin]->[$itout]); }
		    push(@vecIn,0);
		}
				# ---> in: winner pred (repeat)
				#      winner to 100, all others to 0
		if ($modeinLoc =~/win[-,]/){
		    foreach $itout (1..$numout){
			push(@vecIn,$nnout_iwin[$itwin]->[$itout]); }
		}
				# ---> in: reliability index
				#      unit: bitacc * ri / 10
		if ($modeinLoc =~/rel/){
		    push(@vecIn,$nnout_ri[$itwin]);
		}}
				# spacer:
	    else {
				# ---> in: predictions
		if ($modeinLoc =~/str/){
		    foreach $itout (1..$numout){
			push(@vecIn,0); }	    
		    push(@vecIn,$par{"bitacc"});
		}
				# ---> in: winner pred (repeat)
		if ($modeinLoc =~/win[-,]/){
		    foreach $itout (1..$numout){
			push(@vecIn,0); }
		}
				# ---> in: reliability index
		if ($modeinLoc =~/rel/){
		    push(@vecIn,0);
		}}
	}			# end of loop over window
				# ------------------------------

				# ------------------------------
				# (2)  write sequence part
				#      out GLOBAL %vecIn(for one sample)
				#      out GLOBAL @vecIn
				# ------------------------------

				# ------------------------------
				# local info from window

				# in/out GLOBAL: $itVec AND %vecIn
				#       go through window
	if ($modeinLoc =~ /\-cw/){    
	    foreach $itwin (($itres-$winHalf) .. ($itres+$winHalf)){
				# ---> conservation weight
		if (defined $prot_cons{$itwin}){
		    push(@vecIn,$prot_cons{$itwin});}
		else {
		    push(@vecIn,$prot_cons_spacer);}
	    }}
				# ------------------------------
				# global info from outside window
	push(@vecIn,@vecGlob);
				# global from residue
	if ($modeinLoc =~/dis/) {                              
	    push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	    push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));
	}
				# ------------------------------
				# security check
	return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
		       "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
		       $errMsg,$SBR5)) if ($#vecIn != $numinLoc);

				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	($Lok,$msg)=
	    &vecInWrt($itres,$fhoutLoc,$numinLoc
		      );        return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
    }				# end of loop over residues for one break!
				# ------------------------------------------------------------
    $#vecIn=0;
				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn2nd

#===============================================================================
sub assData_vecIn2ndAll {
    local($winHalf,$BEG,$END,$LEN,$numinLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn2ndAll         loops over all residues in one chain and writes vecIn
#                               GENERAL version for specialists, see below
#                               
#                               ==================================================
#                               expected input modein:
#                               loc=str-win-rel-cw,glob=nali-nfar-len-dis-comp
#                               
#                               i.e. sequence part for 2nd level!
#                               
#                               ==================================================
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $numinLoc= number of input units
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#                               
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#                               
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn2ndAll";

				# --------------------------------------------------
				# all residues in current chain!
				# --------------------------------------------------
    $numout=$#{$nnout_prob[1]};
    
    foreach $itres ($BEG..$END){
	$#vecIn=0;
				# ------------------------------
				# (1)  write higher level data: 
				#      out GLOBAL %vecIn(for one sample)
				#      out GLOBAL @vecIn
				# ------------------------------
	$winBeg=($itres-$winHalf);
	$winEnd=($itres+$winHalf);
				# local info from window
	foreach $itwin ($winBeg .. $winEnd){
				# normal residue
	    if (defined $prot_seq{$itwin}){
				# ---> in: predictions
		foreach $itout (1..$numout){
		    push(@vecIn,$nnout_prob[$itwin]->[$itout]); 
		}
		push(@vecIn,0);
				# ---> in: winner pred (repeat)
				#      winner to 100, all others to 0
		foreach $itout (1..$numout){
		    push(@vecIn,$nnout_win[$itwin]->[$itout]); }
				# ---> in: reliability index
				#      unit: bitacc * ri / 10
		push(@vecIn,$nnout_ri[$itwin]);
	    }
				# spacer:
	    else {
				# ---> in: predictions
		foreach $itout (1..$numout){
		    push(@vecIn,0); }
		push(@vecIn,$par{"bitacc"});
				# ---> in: winner pred (repeat)
		foreach $itout (1..$numout){
		    push(@vecIn,0); }
				# ---> in: reliability index
		push(@vecIn,0);}
	}			# end of loop over window
				# ------------------------------

				# ------------------------------
				# (2)  write sequence part
				#      out GLOBAL %vecIn(for one sample)
				#      out GLOBAL @vecIn
				# ------------------------------

				# ------------------------------
				# local info from window

				# in/out GLOBAL: $itVec AND %vecIn
				#       go through window
	foreach $itwin (($itres-$winHalf) .. ($itres+$winHalf)){
				# ---> conservation weight
	    if (defined $prot_cons{$itwin}){
		push(@vecIn,$prot_cons{$itwin});}
	    else {
		push(@vecIn,$prot_cons_spacer);}
	}
				# ------------------------------
				# global info from outside window
	push(@vecIn,@vecGlob);
				# global from residue
	push(@vecIn,split(/,/,$prot_seqGlobDisN[$itres]));
	push(@vecIn,split(/,/,$prot_seqGlobDisC[$itres]));

				# ------------------------------
				# security check
	return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
		       "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
		       $errMsg,$SBR5)) if ($#vecIn != $numinLoc);

				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	($Lok,$msg)=
	    &vecInWrt($itres,$fhoutLoc,$numinLoc
		      );        return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
    }				# end of loop over residues for one break!
				# ------------------------------------------------------------

    $#vecIn=0;
				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn2ndAll

#===============================================================================
sub phdHtmIsit {
    local($fileInLoc,$minValLoc,$minLenLoc,$doStatLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmIsit                  returns best HTM
#       in:                     $fileInLoc        : PHD rdb file
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  undefined|0    -> defaults
#       in:                     $minLenLoc        : length of best helix (18)
#                                  undefined|0    -> defaults
#       in:                     $doStatLoc        : compute further statistics
#                                  undefined|0    -> defaults
#       out:                    1|0,msg,$LisMembrane (1=yes, 0=no),%tmp:
#                               $tmp{"valBest"}   : value of best HTM
#                               $tmp{"posBest"}   : first residue of best HTM
#                   if doStat:
#                               $tmp{"len"}       : length of protein
#                               $tmp{"nhtm"}      : number of membrane helices
#                               $tmp{"seqHtm"}    : sequence of all HTM (string)
#                               $tmp{"seqHtmBest"}: sequence of best HTM (string) 
#                                            (note: may be shorter than minLenLco)
#                               $tmp{"aveLenHtm"} : average length of HTM
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmIsit";$fhinLoc="FHIN_"."phdHtmIsit";
				# ------------------------------
				# defaults
    $minValDefLoc= 0.8;		# average value of best helix (required)
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=0;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $minValLoc=$minValDefLoc                       if (! defined $minValLoc || $minValLoc == 0);
    $minLenLoc=$minLenDefLoc                       if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc                       if (! defined $doStatLoc);

    $kwdNetHtm="OtH";		# name of column with network output for helix (0..100)
    $kwdPhdHtm="PHL";		# name of column with final prediction

    $kwdNetHtm="OtM";		# name of column with network output for helix (0..100)
    $kwdPhdHtm="PMN";		# name of column with final prediction
    $kwdSeq=   "AA";		# name of column with sequence

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
#    return(&errSbr("not RDB (htm) '$fileInLoc'!")) if (! &is_rdbf($fileInLoc));

    undef %tmp;
				# ------------------------------
				# read RDB file
    @kwdLoc=($kwdNetHtm);
    push(@kwdLoc,$kwdPhdHtm,$kwdSeq)    if ($doStatLoc);

    %tmp=
	&rdRdbAssociative($fileInLoc,"not_screen","header","PDBID","body",@kwdLoc); 
    return(&errSbr("failed reading $fileInLoc (rd_rdb_associative), kwd=".
		   join(',',@kwdLoc))) if (! defined $tmp{"NROWS"} || ! $tmp{"NROWS"});

				# ------------------------------
				# get network output values
    $#htm=0; 
    foreach $it (1..$tmp{"NROWS"}) {
	push(@htm,$tmp{$kwdNetHtm,$it}); }
				# ------------------------------
				# get best
    ($Lok,$msg,$valBest,$posBest)=
	&phdHtmGetBest($minLenLoc,@htm);
    return(&errSbrMsg("failed getting best HTM ($fileInLoc, minLenLoc=$minLenLoc,\n".
		      "htm=".join(',',@htm,"\n"),$msg)) if (! $Lok);
				# ------------------------------
				# IS or IS_NOT, thats the question
    $LisMembrane=0;
    $LisMembrane=1              if ($valBest >= $minValLoc);

    undef @htm;			# slim-is-in!

    undef %tmp2;
    $tmp2{"valBest"}=    $valBest;
    $tmp2{"posBest"}=    $posBest;

				# ------------------------------
				# no statics -> this is ALL!!
    if (! $doStatLoc) {		# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	undef %tmp;
	return(1,"ok $sbrName",$LisMembrane,%tmp2);
    }				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


				# --------------------------------------------------
				# now: do statistics
				# --------------------------------------------------
    $lenProt=$tmp{"NROWS"}; 
				# prediction -> string
    $seqHtm=$seqHtmBest=$phd="";
    foreach $it (1..$tmp{"NROWS"}) {
	$phd.=       $tmp{$kwdPhdHtm,$it}; 
				# subset of residues in HTM
	next if ($tmp{$kwdPhdHtm,$it} ne "H");
	$seqHtm.=    $tmp{$kwdSeq,$it};
				# subset of residues for best HTM
	next if ($posBest > $it || $it >  ($posBest + $minLenLoc));
	$seqHtmBest.=$tmp{$kwdSeq,$it};
    }
	
				# ------------------------------
				# average length
    $tmp=$phd;
    $tmp=~s/^[^H]*|[^H]$//g;	# purge non-HTM begin and end
    @tmp=split(/[^H]+/,$tmp);
    $nhtm=$#tmp;		# number of helices
    $htm=join('',@tmp);		# only helices
    $nresHtm=length($htm);	# total number of residues in helices

    $aveLenHtm=0;
    $aveLenHtm=($nresHtm/$nhtm) if ($nhtm > 0);


    $tmp2{"len"}=        $lenProt;
    $tmp2{"nhtm"}=       $nhtm;
    $tmp2{"seqHtm"}=     $seqHtm;
    $tmp2{"seqHtmBest"}= $seqHtmBest;
    $tmp2{"aveLenHtm"}=  $aveLenHtm;

				# ------------------------------
				# temporary write to file yy
    if (0){			# yy
	$id=$tmp{"PDBID"};$id=~tr/[A-Z]/[a-z]/;
	$tmpWrt= sprintf("%-s\t%6.2f\t%5d\t%5d\t%5d\t%6.1f",
			 $id,$tmp2{"valBest"},$tmp2{"posBest"},
		     $tmp2{"len"},$tmp2{"nhtm"},$tmp2{"aveLenHtm"});
#	system("echo '$tmpWrt' >> stat-htm-glob.tmp");
	system("echo '$tmpWrt' >> stat-htm-htm.tmp");
    }

    undef %tmp;			# slim-is-in

    return(1,"ok $sbrName",$LisMembrane,%tmp2);
}				# end of phdHtmIsit

#===============================================================================
sub phdHtmGetBest {
    local($minLenLoc,@tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  = 0    -> defaults (18)
#       in:                     @tmp=             network output HTM unit (0 <= OtH <= 100)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmGetBest";$fhinLoc="FHIN_"."phdHtmGetBest";
				# check arguments
    return(&errSbr("no input!")) if (! defined @tmp || $#tmp==0);
    $minLenLoc=18                if ($minLenLoc == 0);

    $max=0;
				# loop over all residues
    foreach $it (1 .. ($#tmp + 1 - $minLenLoc)) {
				# loop over minLenLoc adjacent residues
	$htm=0;
	foreach $it2 ($it .. ($it + $minLenLoc - 1 )) {
	    $htm+=$tmp[$it2];}
				# store 
	if ($max < $htm) { $pos=$it;
			   $max=$htm; } }
				# normalise
    $val=$max/$minLenLoc;
    $val=$val/100;		# network written to 0..100

    return(1,"ok $sbrName",$val,$pos);
}				# end of phdHtmGetBest

#===============================================================================
sub pred4short {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pred4short                  fill in predictions for chain breaks and
#                               too short regions
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."pred4short";
				# ------------------------------
				# defaults for non prediction
				# ------------------------------
    undef %tmp;
    foreach $kwd (@kwdRdb){
	next if ($kwd =~ /^(No|AA)/);
	if    ($kwd =~ /^[OP](HEL|HL|MN|R2MN|RMN|capH|capS|cap)/){
	    $tmp{$kwd}="L";}
	elsif ($kwd =~ /^[OP][HE](capS|capH)/){
	    $tmp{$kwd}="n";}
	elsif ($kwd =~ /^Pi[MT]o/){
	    $tmp{$kwd}="?";}
	elsif ($kwd =~ /^[OP](REL|ACC)/){
	    $tmp{$kwd}=100;}
	elsif ($kwd =~ /^[OP](be|bie)/){
	    $tmp{$kwd}="e";}
	elsif ($kwd =~ /^RI/){
	    $tmp{$kwd}=0;}
	elsif ($kwd =~ /^Ot/){
	    $tmp{$kwd}=0;}
	elsif ($kwd =~ /^p/){
	    $tmp{$kwd}=0;}
	else {
	    print "-*- WARN: $SBR2: kwd=$kwd, not understood!\n";
	    $tmp{$kwd}=" ";}
    }

				# --------------------------------------------------
				# loop over all residues
				# --------------------------------------------------
    foreach $itres (1..$rdb{"NROWS"}){
				# ------------------------------
				# case 1: chain break
	if ($rdb{$itres,"AA"} eq "!" || $prof_skip{$itres}){
	    foreach $kwd (@kwdRdb){
		next if (defined $rdb{$itres,$kwd} && $rdb{$itres,$kwd}!~/^\s+$/);
		$rdb{$itres,$kwd}=$tmp{$kwd};
	    }}
    }

    return(1,"ok $SBR2");
}				# end of pred4short

#===============================================================================
sub prot2nn {
    local($whichPROFloc,$numaaLoc,$fileInLoc) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn                     compiles the data from %prot and %protacc
#                               as needed for the input vectors (&nnWrt)
#                               
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#       in:                     $numaaLoc:    number of amino acids
#       in:                     $fileInLoc:   sequence file for ERROR message in &prot2nn_countChainBreaks 
#                               
#       in/out GLOBAL:          %prot with:
#                               
#                               $prot{"nali"}
#                               $prot{"nres"}
#                               $prot{"nfar"}:     number of distant relatives
#                               
#                               $prot{$aa,$itres}  profile for amino acid $aa residue=$itres
#                               $prot{$kwd,$itres} 
#                                   kwd=("nocc","ndel","nins","entr","rele","cons")
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."prot2nn";
				# check arguments
    return(&errSbr("not def whichPROFloc!",$SBR2))          if (! defined $whichPROFloc);

				# --------------------------------------------------
				# (1)  MASSAGE protein
				#    - profiles for unknown residues to DB ave
				#    - profiles            -> nnin
				#    - conservation weight -> nnin
				#    - N insertions        -> nnin
				#    - N deletions         -> nnin
				#    
				# --------------------------------------------------
    $#prot_seq= 0;
    undef %prot_seq;		# terrible hack, turns out that $prot_seq[-5] HAS
				#      a defined value after the loop!!!
    $numres=$prot{"numres"};
    $numali=$prot{"nali"};
    $numfar=$prot{"nfar"};
    foreach $itres (1..$numres){
	$prot_seq[$itres]=$prot{"seq",$itres};
	$prot_seq{$itres}=1;
    }

				# note: stupid calling this in any case pumps up
				#       memory unnecessarily, however, faster ...
    ($Lok,$msg)=
	&prot2nn_seqasf();	return(&errSbrMsg("failed prot2nn_seqasf",$msg,$SBR2)) if (! $Lok);

    if ($whichPROFloc =~ /^(3|both|acc)$/){
	($Lok,$msg)=
	    &prot2nn_seqasfacc
		();	        return(&errSbrMsg("failed prot2nn_seqasfacc",$msg,$SBR2)) if (! $Lok);
    }

				# --------------------------------------------------
				# (2)  ASSIGN chain breaks
				#      NOTE: all identical for %prot and %protacc
				#      -> done only for %prot
				# --------------------------------------------------
    @protChainBreaks=
	&prot2nn_countChainBreaks($fileInLoc);

				# --------------------------------------------------
				# (3)  GLOBAL input units: 
				#      NOTE: all identical for %prot and %protacc
				#      -> done only for %prot
				# --------------------------------------------------

				# ------------------------------
				# (3a) residue independent
    $#vecGlob=0;
				# global AA composition
    ($Lok,$msg,$prot_seqGlobComp)=
	&prot2nn_seqGlobComp(1,$numres,$numres
			     );	return(&errSbrMsg("failed on prot2nn_seqGlobComp",$msg,$SBR2)) if (! $Lok);
				# length of protein
    ($Lok,$msg,$prot_seqGlobLen)=
	&prot2nn_seqGlobLen ($numres
			     ); return(&errSbrMsg("failed on prot2nn_seqGlobLen",$msg,$SBR2)) if (! $Lok);
				# no of homologues
    ($Lok,$msg,$prot_seqGlobNali)=
	&prot2nn_seqGlobNali($numali
			     ); return(&errSbrMsg("failed on prot2nn_seqGlobNali",$msg,$SBR2)) if (! $Lok);
				# no of distant homologues
    ($Lok,$msg,$prot_seqGlobNfar)=
	&prot2nn_seqGlobNfar($numfar
			     ); return(&errSbrMsg("failed on prot2nn_seqGlobNfar",$msg,$SBR2)) if (! $Lok);

				# --------------------------------------------------
				# (3b) window dependent: N-C distance
    $#prot_seqGlobDisN=$#prot_seqGlobDisC=0;
    foreach $itres ( 1 .. $numres ){
				# distance from N-term
	($Lok,$msg,$prot_seqGlobDisN[$itres])=
	    &prot2nn_seqGlobDisN
		($itres);	return(&errSbrMsg("prot2nn_seqGlobDisN($itres)",$msg,$SBR2)) if (! $Lok);
				# distance from C-term
	($Lok,$msg,$prot_seqGlobDisC[$itres])=
	    &prot2nn_seqGlobDisC
		($itres,
		 $numres);      return(&errSbrMsg("prot2nn_seqGlobDisC($itres)",$msg,$SBR2)) if (! $Lok);
    }
				# --------------------------------------------------
				# (3c) window dependendent: hydrophobicity

				# NOTE: only once for the job (NOT for every protein!)

    if (! defined %HYDRO){
				# set scales
	$scales=join(',',@hydrophobicityScales);
	($Lok,$msg)=
	    &hydrophobicity_scales
		($scales);      return(&errSbrMsg("failed getting hydropobicity scales, ".
						  "wanted=$scales",$msg,$SBR2)) if (! $Lok);
				# scale from [0-100] to [0-1]
				#    out GLOBAL: %HYDRO
	foreach $kwdScale (@hydrophobicityScales){
	    next if (! defined $hydrophobicityScalesWant{$kwdScale} &&
		     ! defined $hydrophobicityScalesWantSum{$kwdScale});
	    foreach $aa (@aa){ 
		next if (! defined $HYDRO{$kwdScale,$aa,"norm"});
		$HYDRO{$kwdScale,$aa,"norm"}=int($par{"bitacc"}*$HYDRO{$kwdScale,$aa,"norm"}/100);
		$HYDRO{$kwdScale,$aa,"norm"}=
		    $par{"bitacc"} if ($HYDRO{$kwdScale,$aa,"norm"} > $par{"bitacc"});
	    }
	}}
				# protein specific: hydrophobicity
				# chains
    undef %prot_hydro;
    foreach $itbreak (1..$#protChainBreaks){
	($BEG,$END)=split(/\-/,$protChainBreaks[$itbreak]);
	$LEN=1 + $END - $BEG; 
				# too short
	if ($LEN < $par{"numresMin"}){
	    foreach $itres ($BEG .. $END){
		foreach $scale (@hydrophobicityScales){
		    next if (! defined $hydrophobicityScalesWant{$scale} &&
			     ! defined $hydrophobicityScalesWantSum{$scale});
		    $prot_hydro{$itres,$scale}=0;
		}
	    }}
				# residues for current chain
	else {
	    foreach $itres ($BEG .. $END){
		foreach $scale (@hydrophobicityScales){
		    next if (! defined $hydrophobicityScalesWant{$scale} &&
			     ! defined $hydrophobicityScalesWantSum{$scale});
		    $prot_hydro{$itres,$scale}=$HYDRO{$scale,$prot_seq[$itres],"norm"};
		}
	    }}
    }

				# protein specific: hydro SUM
				#    NOTE DEPENDS on window length
    foreach $win (split(/,/,$run{"numwinWanted"})){
	next if ($win !~ /^\d+$/);
	$winHalf=int(($win-1)/2);
				# chains
	foreach $itbreak (1..$#protChainBreaks){
	    ($BEG,$END)=split(/\-/,$protChainBreaks[$itbreak]);
	    $LEN=1 + $END - $BEG; 
				# too short
	    if ($LEN < $par{"numresMin"}){
		foreach $itres ($BEG .. $END){
				# ---> hydro sum
		    foreach $scale (@hydrophobicityScales){
			next if (! defined $hydrophobicityScalesWantSum{$scale});
			$prot_hydro{$itres,$scale."sum",$win}=0;
		    }
				# ---> salt
		    ($Lok,$msg,$prot_hydro{$itres,"salt",$win})=
			&prot2nn_seqLocSalt($itres,$winHalf,$BEG,$END);
		}}
				# residues for current chain
	    else {
		foreach $itres ($BEG .. $END){
				# ---> hydro sum
		    foreach $scale (@hydrophobicityScales){
			next if (! defined $hydrophobicityScalesWantSum{$scale});
			($Lok,$msg,$prot_hydro{$itres,$scale."sum",$win})=
			    &prot2nn_seqLocHydroSum($itres,$winHalf,$BEG,$END,$scale);
		    }
				# ---> salt
		    ($Lok,$msg,$prot_hydro{$itres,"salt",$win})=
			&prot2nn_seqLocSalt($itres,$winHalf,$BEG,$END);
		}
	    }
	}}
				# --------------------------------------------------
    return(1,"ok $SBR2");
}				# end of prot2nn

#===============================================================================
sub prot2nn_seqasf {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqasf              
#-------------------------------------------------------------------------------
    $SBR3=""."prot2nn_seqasf";

				# ------------------------------
				# (1a) profile
				# ------------------------------
    $#prot_prof=0;
    foreach $itres (1..$numres){
	my(@tmp);
	$#tmp=0;
				# normal profile: normalise
	if ($prot_seq[$itres] ne $par{"symbolResidueUnk"}){
	    foreach $itaa (1..($numaaLoc-1)){
		$tmp=int($par{"bitacc"}*($prot{$aa[$itaa],$itres}/100));
		$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
		push(@tmp,$tmp);
		undef $prot{$aa[$itaa],$itres};
	    }}
				# unknown residue
	elsif ($prot_seq[$itres] ne "!") {
	    foreach $itaa (1..($numaaLoc-1)){
		$tmp=int($par{"bitacc"}*$aaXprof[$itaa]); 
		$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
		push(@tmp,$tmp);
		undef $prot{$aa[$itaa],$itres};
	    }}
				# chain: skip
#	else {
#	    print "note: yy break $itres\n";
#	}
	$prot_prof[$itres]=\@tmp;
    }
				# ------------------------------
				# (1b) conservation weight
				# ------------------------------
    undef %prot_cons;
    $prot_cons_spacer=          int($par{"bitacc"}*0.25);
    foreach $itres (1..$numres){
				# unknown residue
	if ($prot_seq[$itres] eq $par{"symbolResidueUnk"}){
	    $prot_cons{$itres}=  0;
	    next; }
				# normal residue: normalise
	$tmp=               int($par{"bitacc"}* 0.5*$prot{"cons",$itres});
	$tmp=               $par{"bitacc"} if ($tmp > $par{"bitacc"});
	undef $prot{"cons",$itres};
	$prot_cons{$itres}= $tmp;
    }

				# ------------------------------
				# (1c) insertions and deletions
				# ------------------------------
    $#prot_nins=$#prot_ndel=0;
    foreach $itres (1..$numres){
				# ok
	if (defined $prot{"nocc",$itres} && $prot{"nocc",$itres}){
	    $tmp=               int($par{"bitacc"}*($prot{"nins",$itres}/$prot{"nocc",$itres}));
	    $tmp=               $par{"bitacc"} if ($tmp > $par{"bitacc"});
	    $prot_nins[$itres]= $tmp;

	    $tmp=               int($par{"bitacc"}*($prot{"ndel",$itres}/$prot{"nocc",$itres}));
	    $tmp=               $par{"bitacc"} if ($tmp > $par{"bitacc"});
	    $prot_ndel[$itres]= $tmp;
	}
				# set 0
	else {
	    $prot_nins[$itres]=  0;
	    $prot_ndel[$itres]=  0;}
				# save memory
	undef $prot{"nins",$itres};
	undef $prot{"ndel",$itres};
	undef $prot{"nocc",$itres};
    }

    return(1,"ok $SBR3");
}				# end of prot2nn_seqasf

#===============================================================================
sub prot2nn_seqasfacc {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqasfacc              
#-------------------------------------------------------------------------------
    $SBR3=""."prot2nn_seqasfacc";

				# ------------------------------
				# (1a) profile
				# ------------------------------
    $#protacc_prof=0;
    foreach $itres (1..$numres){
	my(@tmp);
	$#tmp=0;
				# normal profile: normalise
	if ($prot_seq[$itres] ne $par{"symbolResidueUnk"}){
	    foreach $itaa (1..($numaaLoc-1)){
		$tmp=0;
		$tmp=int($par{"bitacc"}*($protacc{$aa[$itaa],$itres}/100))
		    if (defined $aa[$itaa] && defined $protacc{$aa[$itaa],$itres});
		$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
		push(@tmp,$tmp);
		undef $protacc{$aa[$itaa],$itres};
	    }}
				# unknown residue
	elsif ($prot_seq[$itres] ne "!") {
	    foreach $itaa (1..($numaaLoc-1)){
		$tmp=int($par{"bitacc"}*$aaXprof[$itaa]); 
		$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
		push(@tmp,$tmp);
		undef $protacc{$aa[$itaa],$itres};
	    }}
				# chain: skip
	else {
	    print "note yy break $itres\n";
	}
	$protacc_prof[$itres]=\@tmp;
    }
				# ------------------------------
				# (1b) conservation weight
				# ------------------------------
    $#protacc_cons=0;
    $prot_cons_spacer=          int($par{"bitacc"}*0.25);
    foreach $itres (1..$numres){
				# unknown residue
	if ($prot_seq[$itres] eq $par{"symbolResidueUnk"}){
	    $protacc_cons[$itres]=  0;
	    next; }
				# normal residue: normalise
	$tmp=               int($par{"bitacc"}* 0.5*$protacc{"cons",$itres})
	    if (defined $protacc{"cons",$itres});
	$tmp=               $par{"bitacc"} if ($tmp > $par{"bitacc"});
	undef $protacc{"cons",$itres};
	$protacc_cons[$itres]= $tmp;
    }

				# ------------------------------
				# (1c) insertions and deletions
				# ------------------------------
    $#protacc_nins=$#protacc_ndel=0;
    foreach $itres (1..$numres){
				# ok
	if (defined $protacc{"nocc",$itres} && $protacc{"nocc",$itres}){
	    $tmp=               int($par{"bitacc"}*($protacc{"nins",$itres}/$protacc{"nocc",$itres}));
	    $tmp=               $par{"bitacc"} if ($tmp > $par{"bitacc"});
	    $protacc_nins[$itres]= $tmp;

	    $tmp=               int($par{"bitacc"}*($protacc{"ndel",$itres}/$protacc{"nocc",$itres}));
	    $tmp=               $par{"bitacc"} if ($tmp > $par{"bitacc"});
	    $protacc_ndel[$itres]= $tmp;
	}
				# set 0
	else {
	    $protacc_nins[$itres]=  0;
	    $protacc_ndel[$itres]=  0;}
				# save memory
	undef $protacc{"nins",$itres};
	undef $protacc{"ndel",$itres};
	undef $protacc{"nocc",$itres};
    }

    return(1,"ok $SBR3");
}				# end of prot2nn_seqasfacc

#===============================================================================
sub prot2nn_countChainBreaks {
    local($fileInLoc)=@_;
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_countChainBreaks    simple function to prot2nn_ in previous: count chain breaks
#                               also correct accessibility and sec for breaks
#   in GLOBAL:                  %prot
#-------------------------------------------------------------------------------
    $SBR3=""."prot2nn_countChainBreaks";$fhinLoc="FHIN_"."prot2nn_countChainBreaks";
    $#tmp=0;
    $ibeg=1;
    foreach $itTmp (1..$numres){
                                # if break detected, store: ibeg-iend
        if ($prot_seq[$itTmp] eq "!") {
                                # through too short ones
            $iend=$itTmp;	# include chain break in end !!
            push(@tmp,$ibeg."-".$iend)
		if ((1+$iend-$ibeg) >=1);
            $ibeg=0; }
        elsif (! $ibeg){
            $ibeg=$itTmp;}
    }
                                # final end: note if no break detected, just 1-length
    push(@tmp,$ibeg."-".$numres);

				# notify of problems with short breaks!
				# yy correct one day
    if ($#tmp > 1) {
	foreach $itBreak (1..$#tmp) {
	    ($beg,$end)=split(/\-/,$tmp[$itBreak]);
	    $len=1+$end-$beg;
	    $tmp="filein=$fileInLoc, itbreak=$itBreak $tmp[$itBreak] too short";
	    if ($len < 25) {
		open("FHOUT",">>".$par{"fileOutErrorChain"}) || 
		    warn "-*- $SBR3: failed appending to file=".$par{"fileOutErrorChain"}."\n";
		print FHOUT $tmp,"\n";
		close("FHOUT");}
	}}

    return(@tmp);
}				# end of prot2nn_countChainBreaks

#===============================================================================
sub prot2nn_seqGlobComp {
    local($BEG,$END,$LEN)=@_;
    local($SBR10);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqGlobComp         compiles overall amino acid composition
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#       in:                     $LEN=      length of current chain
#                               
#       in GLOBAL:              $aa{aa}=   1 for all 20 known residues
#       in GLOBAL:              @aa=       residue names
#       in GLOBAL:              $par{<verbForVec>}
#       in GLOBAL:              $prot{<seq>,$it}
#                               
#       in && OUT GLOBAL:       @vecGlob
#-------------------------------------------------------------------------------
    $SBR10="prot2nn_seqGlobComp";
    $prev=0; undef %ct;
				# security check
    return(&errSbr("beg=$BEG, end=$END",$SBR10))
	if (! defined $BEG || ! defined $END || $LEN < 1);

				# compile composition
    foreach $itTmp ($BEG .. $END){
	++$ct{$prot{"seq",$itTmp}}  if (defined $aa{$prot{"seq",$itTmp}} && 
					$aa{$prot{"seq",$itTmp}}); }
				# compile percentages
    $#tmp=0;
    foreach $tmp (@aa){
	$tmpComp=0;
	$tmpComp=int($par{"bitacc"}*$ct{$tmp}/$LEN) if (defined $ct{$tmp});
	push(@tmp,$tmpComp);
    }
    undef %ct;			# slim-is-in
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqGlobComp

#===============================================================================
sub prot2nn_seqGlobLen {
    local($LEN)=@_;
    local($SBR10);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqGlobLen           writes the global protein length
#       in:                     $LEN=      length of current chain
#                               
#       in GLOBAL:              $aa{aa}=   1 for all 20 known residues
#       in GLOBAL:              @aa=       residue names
#       in GLOBAL:              @codeLen   intervals for seq length (<n), + last= >n
#       in GLOBAL:              $par{<verbForVec>}
#                               
#       in && OUT GLOBAL:       @vecGlob
#-------------------------------------------------------------------------------
    $SBR10="prot2nn_seqGlobLen";
    $prev=0;
    $#tmp=0;

    foreach $itItrvl (1..$#codeLen){
	$itrvl=$codeLen[$itItrvl]-$prev;
	if    ($LEN >= $codeLen[$itItrvl]){       # larger
	    $tmp=1;}
	elsif (($itItrvl > 1) && 
	       ($LEN <= $codeLen[$itItrvl-1])){   # smaller
	    $tmp=0;}
	else {		     	                  # fraction
	    $tmp=($LEN - $prev) /$itrvl;
	    $tmp=1              if ($tmp>1);
	    $tmp=0              if ($tmp<0);}
	$prev= $codeLen[$itItrvl];
	push(@tmp,int($par{"bitacc"}*$tmp));
    }
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqGlobLen

#===============================================================================
sub prot2nn_seqGlobNali {
    local($naliLoc)=@_;
    local($SBR10);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqGlobNali         writes the global number of aligned sequences
#       in:                     $LEN=      length of current chain
#                               
#       in GLOBAL:              @codeNali  intervals for number of alis (<n), + last= >n
#       in GLOBAL:              $par{<verbForVec>}
#       in GLOBAL:              $prot{<nali>,$it}
#                               
#       in && OUT GLOBAL:       @vecGlob
#-------------------------------------------------------------------------------
    $SBR10="prot2nn_seqGlobNali";
    $prev=0;
    $#tmp=0;

    foreach $itItrvl (1..$#codeNali){
	$itrvl=$codeNali[$itItrvl]-$prev;
	if    ($naliLoc >= $codeNali[$itItrvl]){ # larger than this
	    $tmp=1;}
	elsif ($itItrvl>1 &&
	       $naliLoc <= $codeNali[$itItrvl-1]){ # smaller than previous
	    $tmp=0;}
	else {			# fraction
	    $tmp=($naliLoc-$prev)/$itrvl;
	    $tmp=1  if ($tmp>1);$tmp=0  if ($tmp<0);}
	$prev= $codeNali[$itItrvl];
	push(@tmp,int($par{"bitacc"}*$tmp));
    }
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqGlobNali

#===============================================================================
sub prot2nn_seqGlobNfar {
    local($nfarLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqGlobNfar         writes the global number of remote aligned sequences
#       in:                     $LEN=      length of current chain
#                               
#       in GLOBAL:              @codeNfar  intervals for number of remote alis (<n), + last= >n
#       in GLOBAL:              $par{<verbForVec>}
#       in GLOBAL:              $prot{<nfar>,$it}
#                               
#       in && OUT GLOBAL:       @vecGlob
#                               
#       in:                     $nndbrd{} -> protein data read from nndb.rdb
#-------------------------------------------------------------------------------
    $prev=0;
    $#tmp=0;

    foreach $itItrvl (1..$#codeNfar){
	$itrvl=$codeNfar[$itItrvl]-$prev;
	if    ($nfarLoc >= $codeNfar[$itItrvl]){ # larger than this
	    $tmp=1;}
	elsif ($itItrvl>1 &&
	       $nfarLoc <= $codeNfar[$itItrvl-1]){ # smaller than previous
	    $tmp=0;}
	else {			# fraction
	    $tmp=($nfarLoc-$prev)/$itrvl;
	    $tmp=1  if ($tmp>1);$tmp=0  if ($tmp<0);}
	$prev= $codeNfar[$itItrvl];
	push(@tmp,int($par{"bitacc"}*$tmp));
    }
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqGlobNfar

#===============================================================================
sub prot2nn_seqGlobDisN {
    local($pos)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqGlobDisN          writes the global distance of the current window
#                               from the protein ends
#                               NOTE: small distance -> large values!!
#                               
#       in:                     pos= position of current window (itRes)
#                               
#       in GLOBAL:              @codeDisN  intervals for distance from N-term (<n), + last= >n
#       in GLOBAL:              $par{<verbForVec>}
#                               
#       in && OUT GLOBAL:       @vecDis
#-------------------------------------------------------------------------------
    $prev=0;
    $dist=$pos - 1;
    
    $#tmp=0;
    foreach $itItrvl (1..$#codeDisN){
	$itrvl=$codeDisN[$itItrvl]-$prev;
				# ------------------------------
				# larger
	if    ($dist >= $codeDisN[$itItrvl]){
	    $tmp=1;}		# note: inverted
				# ------------------------------
				# smaller
	elsif ($itItrvl > 1 && $dist <= $codeDisN[$itItrvl-1]){
	    $tmp=0;}		# note: inverted
				# ------------------------------
	else {			# fraction
	    $tmp=($dist-$prev)/$itrvl;
	    $tmp=1              if ($tmp>1);  # saturation
	    $tmp=0              if ($tmp<0);} # saturation
	$prev= $codeDisN[$itItrvl];
	push(@tmp,int($par{"bitacc"}*$tmp));
    }
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqGlobDisN

#===============================================================================
sub prot2nn_seqGlobDisC {
    local($pos,$END)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqGlobDisC          writes the global distance of the current window
#                               from the protein ends
#                               NOTE: small distance -> large values!!
#                               
#       in:                     pos= position of current window (itRes)
#       in:                     $END=      end of current chain
#                               
#       in GLOBAL:              @codeDisC  intervals for distance from C-term (<n), + last= >n
#       in GLOBAL:              $par{<verbForVec>}
#                               
#       in && OUT GLOBAL:       @vecDis
#-------------------------------------------------------------------------------
    $prev=0;
    $dist=$END - $pos;

    $#tmp=0;
    foreach $itItrvl (1..$#codeDisC){
	$itrvl=$codeDisC[$itItrvl]-$prev;
				# ------------------------------
				# larger
	if    ($dist >= $codeDisC[$itItrvl]){
	    $tmp=1;}		# note: inverted
				# ------------------------------
				# smaller
	elsif ($itItrvl > 1 && $dist <= $codeDisC[$itItrvl-1]){ 
	    $tmp=0;}		# note: inverted
				# ------------------------------
	else {			# fraction
	    $tmp=($dist-$prev)/$itrvl;
	    $tmp=1              if ($tmp>1);  # saturation
	    $tmp=0              if ($tmp<0);} # saturation
	$prev= $codeDisC[$itItrvl];
	push(@tmp,int($par{"bitacc"}*$tmp));
    }
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqGlobDisC

#===============================================================================
sub prot2nn_seqLocHydroSum {
    local($itRes,$winLoc,$BEG,$END,$kwdScale)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqLocHydroSum       writes hydrophobicity summed over all:
#                               3-10:   i,i+3,i+6; i+1,i+4,i+8; ...
#                               helix:  i,i+4,i+8; i+1,i+5,i+9; ...
#                               strand: i,i+2,i+4; i+1,i+3,i+5; ...
#                               
#                               NOTE: is semi-global in that sum is over window, only!
#                               
#       in GLOBAL:              $par{$kwd}, $kwd=<bitacc|verbForVec>
#                  WATCH IT:    may exceed 100% ! (set back to 100!)
#                               
#       in GLOBAL:              $prot{<nins|nocc>,$it}
#                               
#       in && OUT GLOBAL:       $itVec=    counting vector components
#       in && OUT GLOBAL:       %vecIn{}
#                               
#       in:                     $itRes=    current residue number
#       in:                     $winLoc=   half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#       in:                     $kwdScale= <ges|eisen|hydro|heijne|htm|ooi>
#                                          identifier of hydrophobicity scale
#-------------------------------------------------------------------------------

				# window begin and end
    $beg=$itRes-$winLoc;
    $end=$itRes+$winLoc;
				# go through window for 
				#    sheets  (i,i+2; i+1,i+3)
				#    3-10    (i,i+3; i+1,i+4; i+2,i+5)
				#    helices (i,i+4; i+1,i+5; i+2,i+6; i+3,i+7)
    undef %tmp;
    $#tmp=0;

    foreach $itx (2,3,4){
	$tmp{"occ"}=0;
	$tmp{"sum"}=0;
				# residue itself
	++$tmp{"occ"};
	if (defined $HYDRO{$kwdScale,$prot_seq[$itRes],"norm"}){
	    $tmp{"sum"}+=$HYDRO{$kwdScale,$prot_seq[$itRes],"norm"}; 
	}

				# loop over window towards N-term
	for ($itwin=$itRes+$itx; $itwin<=$end; $itwin+=$itx){
	    last if ($itwin>$end);
				# ignore spacers and weirdos
	    next if (! defined $prot_seq[$itwin] || $prot_seq[$itwin] eq "!");
	    last if ( ($itwin < $BEG) || ($itwin > $END) );
	    ++$tmp{"occ"};
	    if (defined $HYDRO{$kwdScale,$prot_seq[$itwin],"norm"}){
		$tmp{"sum"}+=$HYDRO{$kwdScale,$prot_seq[$itwin],"norm"}; 
	    }}
				# loop over window towards N-term
	for ($itwin=$itRes-$itx; $itwin>=$beg; $itwin-=$itx){
	    last if ($itwin<$beg);
				# ignore spacers and weirdos
	    next if (! defined $prot_seq[$itwin] || $prot_seq[$itwin] eq "!");
	    last if ( ($itwin < $BEG) || ($itwin > $END) );
	    ++$tmp{"occ"};
	    if (defined $HYDRO{$kwdScale,$prot_seq[$itwin],"norm"}){
		$tmp{"sum"}+=$HYDRO{$kwdScale,$prot_seq[$itwin],"norm"};
	    }}
				# lo

				# normalise
	$val=0;
	$val=int($tmp{"sum"}/$tmp{"occ"}) if ($tmp{"occ"}>=1);

	$val=$par{"bitacc"}     if ($val > $par{"bitacc"});
	push(@tmp,$val);
    }				# end of loop over sheet (2), 3-10 (3), helix (4)

    undef %tmp;			# slim-is-in
    return(1,"ok",join(',',@tmp));
}				# end of prot2nn_seqLocHydroSum

#===============================================================================
sub prot2nn_seqLocSalt {
    local($itRes,$winLoc,$BEG,$END)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_seqLocSalt          sums over salt bridges to [ED]-[KL]=1, [KL]-[ED]=1 
#                               i,(i+n)  where n=1..$winLoc 
#                               NOTE: =1 if either i-n OR i+n opposite charge
#                               1 for ED all: i,(i+n)
#                               2 for KD all: i,(i+n)
#                               total number of units = (win-1)*2
#                               
#       in GLOBAL:              $par{$kwd}, $kwd=<bitacc|verbForVec>
#                  WATCH IT:    may exceed 100% ! (set back to 100!)
#                               
#       in && OUT GLOBAL:       $itVec=    counting vector components
#       in && OUT GLOBAL:       %vecIn{}
#                               
#       in:                     $itRes=    current residue number
#       in:                     $winLoc=   half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#-------------------------------------------------------------------------------

				# window begin and end
    $beg=$itRes-$winLoc;
    $end=$itRes+$winLoc;
				# go through window for 
				#    sheets  (i,i+2)
				#    3-10    (i,i+3)
				#    helices (i,i+4)
    $val=0;
    $#tmpout=0;
				# --------------------------------------------------
				# not at all defined -> all 0
				# --------------------------------------------------
    if (! defined $prot{"seq",$itRes} || ! $BEG){
	foreach $it ($beg..$end){ 
	    next if ($it==$itRes); # skip itself
	    push(@tmpout,0);
	}
	foreach $it ($beg..$end){ 
	    next if ($it==$itRes); # skip itself
	    push(@tmpout,0);
	}
				# <-- <-- <-- early end
	return(1,"ok",join(',',@tmpout));
				# <-- <-- <-- early end
				# **************************************************
    }

				# --------------------------------------------------
				# first (win-1) units for [DE]
				# --------------------------------------------------

				# set all to zero
    $#tmp=0;
    foreach $it (1..$winLoc){
	$tmp[$it]=0;
    }

				# ------------------------------
				# find pairs
    if ($prot{"seq",$itRes}=~/[DE]/){
	foreach $it (1..$winLoc){
				# residue BEFORE $itRes IS opposite
	    if ((defined $prot{"seq",($itRes-$it)} &&
		 $prot{"seq",($itRes-$it)}=~/[KL]/)   ||
				# residue AFTER $itRes IS opposite
		(defined $prot{"seq",($itRes+$it)} &&
		 $prot{"seq",($itRes+$it)}=~/[KL]/)){
		$val=$par{"bitacc"}; 
		$tmp[$it]=$val; 
	    }}
    }				# end of central = [ED]
    push(@tmpout,@tmp);

				# --------------------------------------------------
				# second (win-1) units for [KL]
				# --------------------------------------------------
				# set all to zero
    $#tmp=0;
    foreach $it (1..$winLoc){
	$tmp[$it]=0;}
				# find pairs
    if ($prot{"seq",$itRes}=~/[KL]/){
	foreach $it (1..$winLoc){
	    $val=0;
				# residue BEFORE $itRes IS opposite
	    if ((defined $prot{"seq",($itRes-$it)} &&
		 $prot{"seq",($itRes-$it)}=~/[ED]/)   ||
				# residue AFTER $itRes IS opposite
		(defined $prot{"seq",($itRes+$it)} &&
		 $prot{"seq",($itRes+$it)}=~/[ED]/)){
		$val=$par{"bitacc"}; 
		$tmp[$it]=$val; 
	    }}
    }				# end of central = KL
    push(@tmpout,@tmp);
    
    return(1,"ok",join(',',@tmpout));
}				# end of prot2nn_seqLocSalt

#===============================================================================
sub prot2nn_spacer {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prot2nn_spacer                       
#-------------------------------------------------------------------------------
    $SBR3=""."prot2nn_spacer";

				# profiles
#     foreach $aatmp (@aa){
# 	$loc{$aatmp,$itwin}= 0;
#     }
				# explicit spacer unit
#    $loc{"spacer",$itwin}=   $par{"bitacc"};
				# average conservation weight
#    $loc{"cons",$itwin}=     int($par{"bitacc"}*0.25);
				# deletions
#    $loc{"ndel",$itwin}=     0;
				# insertions
#    $loc{"nins",$itwin}=     0;

				# hydrophobicity
#     foreach $scale (@hydrophobicityScales){
# 	$prot{$itwin,$scale}=0;
#     }

    return(1,"ok $SBR3");
}				# end of prot2nn_spacer

#===============================================================================
sub protRd {
    local($fileInLoc,$chainInLoc,$formatInLoc,$whichPROFloc) = @_ ;
    my($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   protRd                      converts database files to protRd.rdb format
#                               
#       in:                     fileInLoc:    database file 
#                                   (hssp,dssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,swiss)
#       in:                     $FHTRACELoc:  trace file-handle
#       in:                     $formatIn:    format of input file
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#                               
#       out GLOBAL:             %prot with:
#                               
#                               $prot{"nali"}
#                               $prot{"nres"}
#                               $prot{"nfar"}:     number of distant relatives
#                               
#                               $prot{$aa,$itres}  profile for amino acid $aa residue=$itres
#                               $prot{$kwd,$itres} 
#                                   kwd=("nocc","ndel","nins","entr","rele","cons")
#                               
#                               $L3D_KNOWN=1       if 3D given
#                               
#                               
#       out:                    @fileConverted_to_protRd_rdb
#       err:                    (1,'ok',@file), (0,'message',0)
#-------------------------------------------------------------------------------
    $SBR3=""."protRd";
    $fhinLoc="FHIN_"."protRd"; $fhoutLoc="FHOUT_"."protRd";
				# check arguments
    return(&errSbr("not def fileInLoc!",   $SBR3))  if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!",  $SBR3))  if (! defined $chainInLoc);
    return(&errSbr("not def formatIn!",    $SBR3))  if (! defined $formatInLoc);
    return(&errSbr("not def whichPROF",    $SBR3))  if (! defined $whichPROFloc);
				# existing file?
    return(&errSbr("no fileIn=$fileInLoc!",$SBR3))  if (! -e $fileInLoc && $formatInLoc !~/seq/);

				# ------------------------------
				# local parameter
    $nres2test=10;		# will only test for the $nres2test first residues
				#    whether or not everything is read ok

    print $FHTRACE "\n"         if ($par{"verbAli"});

				# --------------------------------------------------
				# digest database files (GLOBAL)
				# (1) convert all to HSSP
				# (2) filter the HSSP
				# (3) convert to NET-RDB-DB format
				# --------------------------------------------------
    if ($formatInLoc eq "seq"){
	$formatInLoc="fasta";
	$id="sequence";}
    else{
	$id=$fileInLoc;$id=~s/^.*\///g;$id=~s/\..*$//g;
	$id.=$par{"extChain"}.$chainInLoc if ($chainInLoc !~ /^(unk|\*)$/ &&
					      $chainInLoc ne $par{"symbolChainAny"});}

				# ------------------------------
				# (1) input is alignment
				# ------------------------------
    if    ($formatInLoc=~ /^(hssp|msf|saf|pirmul|fastamul)$/){
	$tmp= $fileInLoc."  "; 
	$tmp.="_".$chainInLoc   if ($chainInLoc ne "unk" && $chainInLoc ne $par{"symbolChainAny"});
	print $FHTRACE2 
	    "--- $SBR3 read ali: id=$id, f=$tmp, form=$formatInLoc\n"
		if ($par{"verbAli"});
				# NOTE: will also convert and filter!
				#     GLOBAL out: %prot
	($Lok,$msg,$fileTaken,$paraTaken)=
	    &protRdAli($fileInLoc,$chainInLoc,$id,$formatInLoc,$whichPROFloc);
	if    (! $Lok) {
	    $tmp="*** ERROR $scrName:$SBR3: after protRdAli, fileIn=$fileInLoc, \n".
		"***       message from sbr:\n".$msg."\n";
	    print $FHERROR $tmp;
	    return(&errSbr("$tmp",$SBR3)); }
	elsif ($Lok==2){
	    return(2,"empty");}
    }
				# ------------------------------
				# (2) single sequence formats
				# ------------------------------
    elsif ($formatIn =~ /^(pir|fasta|gcg|dssp|seq|swiss)$/){
	$fileOut=$par{"dirWork"}.$id."ext_why.tmp";
	print $FHTRACE2 
	    "--- $scrName (seq): $fileInLoc ($chainInLoc) form=$formatInLoc id=$id -> out=$fileOut\n"
		if ($par{"verbAli"});
				# out GLOBAL: %prot
	($Lok,$msg)=
	    &protRdSeq($fileInLoc,$chainInLoc,$formatInLoc,$id,$fileOut,$par{"extChain"},
		       $par{"debug"},$par{"fileOutScreen"},$par{"dirWork"},$whichPROFloc);
	if (! $Lok) {
	    $tmp="*** ERROR $scrName:$SBR3: after protRdSeq, fileIn=$fileInLoc, \n".
		"***       message from sbr:\n".$msg."\n";
	    print $FHERROR $tmp;
	    return(&errSbr("$tmp",$SBR3)); }
	$fileTaken=$fileInLoc;
	$paraTaken=0;
	push(@fileConv,$fileOut);}
				# ------------------------------
				# (4) wrong format
    else { 
	return(0,"*** ERROR $scrName: wrong input format ($formatInLoc)\n",0);}

				# ------------------------------
				# (5) check whether all is there
				# ------------------------------
    $errTxt="";
				# for entire protein
    foreach $kwd ("nres","nali","nfar"){
	$errTxt.="*** missing:".$kwd."\n" if (! defined $prot{$kwd}); }
				# for each residue
    foreach $itTmp (1..$prot{"nres"}){
	foreach $kwd ("seq","cons","nocc","nins","ndel"){
	    $errTxt.="*** missing:"."res=".$itTmp." kwd=".$kwd."\n" 
		if (! defined $prot{$kwd,$itTmp});
	}
				# profiles there?
	foreach $tmp (@aa){
	    $errTxt.="*** missing:"."res=".$itTmp." profAA=".$tmp."\n" 
		if (! defined $prot{$tmp,$itTmp});
	}
	last if ($itTmp >= $nres2test); }

				# DOES have an error, somewhere
    return(0,
	   "*** ERROR $SBR3: missing important information about protein in=$fileInLoc, chn=$chainInLoc:\n".
	   $errTxt) 
	if (length($errTxt)>0);
	
    return(1,"ok $SBR3",$fileTaken,$paraTaken);
}				# end of protRd

#===============================================================================
sub protRdAli {
    local($fileInLoc,$chainInLoc,$id,$formatInLoc,$whichPROFloc)=@_;
    my($SBR4,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   protRdAli                   processes the input database file(s) for alis
#                               (1) convert all to HSSP
#                               (2) filter the HSSP
#                               (3) convert to NN-RDB-DB format
#                               
#       in:                     fileInLoc=database file 
#                                   (hssp,dssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,swiss)
#       in:                     $formatIn=  format of input file
#       in:                     $whichPROF:  is par{"optProf"} <3|both|sec|acc|htm|cap>
#                               
#       in GLOBAL:              @aa
#                               
#       in / out GLOBAL:        @FILE_REMOVE, @file_ERROR -> temporary files
#       in / out GLOBAL:        $prot{},$protRdPtr{}
#                               
#       out GLOBAL:             %prot with:
#                               
#                               $prot{"nali"}
#                               $prot{"nres"}
#                               $prot{"nfar"}:     number of distant relatives
#                               $prot{$aa,$itres}  profile for amino acid $aa residue=$itres
#                               $prot{$kwd,$itres} 
#                                   kwd=("nocc","ndel","nins","entr","rele","cons")
#                               
#                               $L3D_KNOWN=1       if 3D given
#                               
#       out:                    $Lok,$msg,$fileTaken,$paraTaken (final ali file and parameters)
#-------------------------------------------------------------------------------
    $SBR4=""."protRdAli";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!",  $SBR4))  if (! defined $fileInLoc);
    $chainInLoc="unk"                              if (! defined $chainInLoc);
    return(&errSbr("not def id!",         $SBR4))  if (! defined $id);
    return(&errSbr("not def formatInLoc!",$SBR4))  if (! defined $formatInLoc);
    return(&errSbr("not def whichPROF",   $SBR4))  if (! defined $whichPROFloc);

    return(0,"*** $SBR: no in fileIn=$fileInLoc!",$SBR4)  if (! -e $fileInLoc);

				# ------------------------------
				# local settings
    if ($chainInLoc eq "unk" ||
	$chainInLoc eq "*"){
	$LisChain=0; 
	$chainInLoc="";}
    else {
	$LisChain=1;}

    $aaLoc=$aa                     if (defined $aa && $aa);
    $aaLoc="VLIMFWYGAPSTCHRKQEND"  if (! defined $aa || ! $aa);
    @aaLoc=split(//,$aaLoc);
    %ptrLoc=('nocc',"NOCC", 'ndel',"NDEL", 'nins',"NINS", 
	     'entr',"ENTROPY", 'rele',"RELENT", 'cons',"WEIGHT")
	if (! defined %protRdPtr || ! %protRdPtr);
    %ptrLoc=%protRdPtr               if (defined %protRdPtr && %protRdPtr);
    $LisHssp=0;
    if ($par{"debugali"}){
	$fileOutScreen=0;}
    else {
	$fileOutScreen=$par{"fileOutScreen"};}

				# --------------------------------------------------
				# (1) convert all to HSSP
				# -------------------------------------------------
    if ($formatInLoc ne "hssp"){
	$arg= "";
	$arg.="exeConvertSeq=".$par{"exeConvertSeqFor"};
				# account for chains
	if ($formatInLoc eq "dssp" && $LisChain){
	    $file=$fileInLoc."_".$chainInLoc;}
	else {
	    $file=$fileInLoc;}
				# output file
	$fileOutTmp= $par{"dirWork"}. $par{"titleTmp"}.$id; 
	$fileOutTmp.=$par{"extChain"}.$chainInLoc if ($LisChain); 
	$fileOutTmp.=$par{"extHssp"};
				# ------------------------------
				# run copf
	$cmd= $par{"exeCopf"}." ".$fileInLoc." hssp fileOut=$fileOutTmp $arg";
	($Lok,$msg)=
	    &sysRunProg($cmd,$fileOutScreen,$FHPROG_ALI);
	return(&errSbrMsg("failed conversion to HSSP",$msg,$SBR4)) 
	    if (! $Lok || ! -e $fileOutTmp);
	$fileHsspTmp=$fileOutTmp;
				# mark for later removal
	push(@FILE_REMOVE,$fileOutTmp)
	    if (! $par{"debug"} && ! $par{"doKeepHssp"});}
    else {
	$fileHsspTmp=$fileInLoc;
	$LisHssp=1;}

				# --------------------------------------------------
				# (2a) 'normal' filter for HSSP file
				# --------------------------------------------------
    if ($par{"doFilter"}){
	$fileOutTmp= $par{"dirWork"}. $par{"titleTmp"}.$id; 
	$fileOutTmp.=$par{"extChain"}.$chainInLoc if ($LisChain); 
	$fileOutTmp.=$par{"extHsspFil"};
				# security: delete existing
	unlink($fileOutTmp)     if (-e $fileOutTmp);
				# ------------------------------
				# run filter HSSP
	$paraTaken=$par{"optFilter"};
	$cmd= $par{"exeFilterHssp"}." $fileHsspTmp ".$par{"optFilter"};
	$cmd.=" fileOut=$fileOutTmp exeFilterHssp=".$par{"exeFilterHsspFor"};
	($Lok,$msg)=
	    &sysRunProg
		($cmd,$fileOutScreen,
		 $FHPROG_ALI);  return(&errSbrMsg("failed to filter HSSP ($fileHsspTmp)",
						  $msg,$SBR4)) if (! $Lok || ! -e $fileOutTmp);
	$fileHsspFilterTmp=$fileOutTmp;
				# mark for later removal
	push(@FILE_REMOVE,$fileOutTmp)
	    if (! $par{"debug"} && ! $par{"doKeepHssp"});}
    else {
	$paraTaken=0;
	$fileHsspFilterTmp=$fileHsspTmp;}
    $fileTaken=$fileHsspFilterTmp;
				# --------------------------------------------------
				# (2b) force FILTER for acc and htm?
				# --------------------------------------------------
    if ($whichPROFloc =~ /^(3|acc|both)/ &&
	$par{"doFilterAcc"}){
#	$fileOutTmp= $par{"dirWork"}. $par{"titleTmp"}.$id; 
#	$fileOutTmp.=$par{"extChain"}.$chainInLoc if ($LisChain); 
	$fileOutTmp= $par{"dirWork"}. $par{"titleTmp"};
	$fileOutTmp.=$par{"extHssp4acc"};
				# security: delete existing
	unlink($fileOutTmp)     if (-e $fileOutTmp);
				# ------------------------------
				# run filter HSSP
	$paraTaken=$par{"optFilterAcc"};
	$cmd= $par{"exeFilterHssp"}." $fileHsspTmp ".$par{"optFilter"};
	$cmd.=" fileOut=$fileOutTmp exeFilterHssp=".$par{"exeFilterHsspFor"};
	($Lok,$msg)=
	    &sysRunProg
		($cmd,$fileOutScreen,
		 $FHPROG_ALI);	return(&errSbrMsg("failed to filter HSSP ($fileHsspTmp)",
						  $msg,$SBR4)) if (! $Lok || ! -e $fileOutTmp);
	$fileHssp4acc=$fileOutTmp;
				# mark for later removal
	push(@FILE_REMOVE,$fileOutTmp)
	    if (! $par{"debug"} && ! $par{"doKeepHssp"});}


				# --------------------------------------------------
				# (3a) read HSSP for ALL modes
				#      out GLOBAL: %prot
				# --------------------------------------------------
    $L3D_KNOWN=0;
    ($Lok,$msg,$L3D_KNOWN)=
	&protRdAliHssp("all",$fileTaken,$chainInLoc,$id,$L3D_KNOWN
		       );       return(&errSbrMsg("after call protRdAliHssp(all,hssp=$fileTaken)",
						  $msg,$SBR4)) if (! $Lok);
    if ($Lok && $msg=~/empty/i){
	return(2,"empty HSSP");
    }

				# --------------------------------------------------
				# (3b) read HSSP for PROFacc
				#      out GLOBAL: %protacc
				# --------------------------------------------------
    if    ($whichPROFloc eq "acc"){
				# yy: bad idea blows up memory ...
	%protacc=%prot;}
    elsif ($whichPROFloc =~ /3|both/ &&
	   $par{"doFilterAcc"}){
	($Lok,$msg,$L3D_KNOWN)=
	    &protRdAliHssp("acc",$fileHssp4acc,$chainInLoc,$id,$L3D_KNOWN
			   );   return(&errSbrMsg("after call protRdAliHssp(acc,hssp4acc=$fileHssp4acc)",
						  $msg,$SBR4)) if (! $Lok);}
    elsif ($whichPROFloc =~ /3|both/){
	($Lok,$msg,$L3D_KNOWN)=
	    &protRdAliHssp("acc",$fileTaken,$chainInLoc,$id,$L3D_KNOWN
			   );   return(&errSbrMsg("after call protRdAliHssp(acc,hssp4acc=$fileHssp4acc)",
						  $msg,$SBR4)) if (! $Lok);}
                                # ------------------------------
                                # save memory
    undef %ali; undef %tmp; undef %chn; undef %ptrLoc; 
    $#tmpKwd=$#chainAli=$#seqAli=$#secAli=$#accAli=$#tmp=0;
    
    return(1,"ok $SBR4",$fileTaken,$paraTaken);
}				# end of protRdAli

#===============================================================================
sub protRdAliHssp {
    local($modeLoc,$fileInLoc,$chainInLoc,$id) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   protRdAliHssp                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."protRdAliHssp";
				# ------------------------------
				# check arguments
    return(&errSbr("not def modeLoc!",   $SBR5)) if (! defined $modeLoc);
    return(&errSbr("not def fileInLoc!", $SBR5)) if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!",$SBR5)) if (! defined $chainInLoc);
    return(&errSbr("not def id!",        $SBR5)) if (! defined $id);

				# ------------------------------
				# local settings
    if (! defined $par{"aliMinLen"}){
	$minlen=20;}		# minimal length for reporting alignment hits
    else {
	$minlen= $par{"aliMinLen"};}

				# ------------------------------
				# initialise pointers and keywords
    if (! defined %hsspRdProf_ini){
	($Lok,$msg)=
	    &hsspRdProf_ini();
	return(&errSbr("failed on hsspRdProf_iniHere\n".$msg,$SBR4)) if (! $Lok);
				# set keywords for reading HSSP:
				#     no alignment, no insertion list, no fill-up
	$kwdHsspIn="dist=".$par{"convPfar"}.",distMode=le,";
	if    (($par{"optOutAli"} || $par{"doRetMsf"} || $par{"doRetSaf"}) &&
	       ! $par{"doRetAliExpand"}){
	    $kwdHsspIn.=" noins nofill ";}
	elsif (! $par{"optOutAli"} && ! $par{"doRetMsf"} && ! $par{"doRetSaf"}){
	    $kwdHsspIn.=" noali noins nofill ";}
    }
				# ------------------------------
				# read HSSP
    $kwdHsspInTmp= $kwdHsspIn;
    $kwdHsspInTmp.="chain=$chainInLoc,"   if ($LisChain);
				# out GLOBAL %hssp
    ($Lok,$msg)=
	&hsspRdProf($fileInLoc,$kwdHsspInTmp);

				# empty HSSP
    if ($Lok && $msg =~/empty/i){
	return(2,"empty HSSP");}

				# --------------------------------------------------
				# PSI-BLAST: get BLAST profiles
				#            NEED file.blastmat here!
				# --------------------------------------------------
    if ($hssp{"numali"} > 1 &&
	$par{"modeAli"} =~ /psi|blast/){
	($Lok,$msg)=
	    &blastpsiRdProf
		($fileInLoc
		 );             return(&errSbrMsg("after call blastpsiRdProf",
						  $msg,$SBR5)) if (! $Lok); }

				# ------------------------------
				# PSI-BLAST single: read BLOSUM62
				# ------------------------------
    elsif (1 && $par{"modeAli"} =~ /psi|blast/){
	($Lok,$msg)=
	    &blastpsiMatReadBlosum
		($par{"fileMatBlosum62psi"}
		 );             return(&errSbrMsg("after call blastPsiMatReadBlosum(".
						  $par{"fileMatBlosum62psi"}.")",
						  $msg,$SBR5)) if (! $Lok);
	foreach $itres (1..$hssp{"numres"}){
	    foreach $tmpAA (@aa){
		$hssp{"prof",$tmpAA,$itres}=
		    int(100 * &func_sigmoidGen
			($BLASTMAT{$hssp{"seq",$itres},$tmpAA},
			 $par{"blastConvTemperature"}));
	    }
	}}

				# --------------------------------------------------
				# translate some keywords
				# --------------------------------------------------
				# set some flags
    if ($modeLoc ne "acc"){
	$numres2=$hssp{"numres"};
				# note: believes that all is fine provided fine for the first, second, or last residue!
				# 
	$L3D_KNOWN=1            if ((defined $hssp{"acc",1} && $hssp{"acc",1}=~/^\d+$/) ||
				    (defined $hssp{"acc",2} && $hssp{"acc",2}=~/^\d+$/) ||
				    (defined $hssp{"acc",$numres2} && $hssp{"acc",$numres2}=~/^\d+$/) ||
				    (defined $hssp{"sec",1} && $hssp{"sec",1}=~/^[\sGHIEBSTN]$/) ||
				    (defined $hssp{"sec",2} && $hssp{"sec",2}=~/^[\sGHIEBSTN]$/) ||
				    (defined $hssp{"sec",$numres2} && $hssp{"sec",$numres2}=~/^[\sGHIEBSTN]$/));
	$L3D_KNOWN=0            if (defined $hssp{"sec",1} && $hssp{"sec",1} eq "U" &&
				    defined $hssp{"sec",2} && $hssp{"sec",2} eq "U" &&
				    defined $hssp{"sec",($numres2-1)} && $hssp{"sec",($numres2-1)} eq "U" &&
				    defined $hssp{"sec",$numres2} && $hssp{"sec",$numres2} eq "U");
				     
				# ------------------------------
				# convert HSSP data:
				#    loop over all residues
	foreach $itres (1..$hssp{"numres"}){
				# small caps to 'C'
#	    $hssp{"seq",$itres}="C" 
#		if ($hssp{"seq",$itres}=~/[a-z]/);
	    if ($L3D_KNOWN){
				# accessibility: absolute to relative
		$hssp{"accRel",$itres}="";
		$hssp{"accRel",$itres}=int(&convert_acc($hssp{"seq",$itres},$hssp{"acc",$itres}))
		    if (defined $hssp{"acc",$itres} && $hssp{"acc",$itres}=~/^\d+$/);
		$hssp{"accRel",$itres}=100 if ($hssp{"accRel",$itres} > 100);
	    } 
	}
				# secondary structure
				#    loop over all residues
	if ($L3D_KNOWN){
	    $sec="";
	    foreach $itres (1..$hssp{"NROWS"}){
		$sec.=$hssp{"sec",$itres}; }
				# fine-grained conversion of DSSP
	    ($Lok,$msg,$secConv)=
		&convert_secFine($sec,$modeSec);
	    print "-*- WARN $SBR: sec=$sec, failed (msg=$msg)\n" if (! $Lok);
	    $secConv=$sec           if (! $Lok);
				# now change throughout
	    @tmp=split(//,$secConv);
	    foreach $itres (1..$hssp{"NROWS"}){
		$hssp{"sec",$itres}= $tmp[$itres]; 
		$hssp{"sec6",$itres}=$tmp[$itres]; }
				# add 6 states (HELBGT)
	    ($Lok,$msg,$secConv6)=
		&convert_secFine($sec,$par{"modeSec6"});
	    if ($Lok){
		@tmp=split(//,$secConv6);
		foreach $itres (1..$hssp{"NROWS"}){
		    $hssp{"sec6",$itres}=$tmp[$itres]; }}
	}
    }

				# --------------------------------------------------
				# RENAME: and some translations
				# --------------------------------------------------

				# ------------------------------
				# all except 'acc' -> %prot
    if ($modeLoc ne "acc"){
	if (defined defined $hssp{"sec",1}){
	    foreach $it (1..50){
		last if (! defined $hssp{"sec",$it});
		if ($hssp{"sec",$it} =~/^[GHIEBSTN]$/){
		    $L3D_KNOWN=1;
		    last; }}}
	if (! $L3D_KNOWN && defined $hssp{"acc",1}){
	    foreach $it (1..50){
		last if (! defined $hssp{"acc",$it});
		if ($hssp{"sec",$it} =~/^\d+$/){
		    $L3D_KNOWN=1;
		    last; }}}
	
	%prot=%hssp; undef %hssp;
	$prot{"nali"}=$prot{"numali"};
	$prot{"nres"}=$prot{"numres"};
				# translate some names
	$prot{"nfar"}=0;
	$prot{"nfar"}=$prot{"ndist"}  if (defined $prot{"ndist"});
	foreach $other (@otherDistance){
	    $prot{"nfar",$other}=$prot{"ndist",$other} if (defined $prot{"ndist",$other});
	}
	$prot{"nchn"}=$prot{"NCHAIN"} if (defined $prot{"NCHAIN"});
	$prot{"PDBID"}.=$par{"extChain"}.$chainInLoc if ($LisChain);
	$prot{"id"}=  $prot{"PDBID"};
	
	foreach $itres (1..$prot{"numres"}){
	    foreach $kwd ("nocc","ndel","nins","entr","rele","cons"){
		$kwdHssp=$nndbPtr{$kwd};
		return(&errSbr("HSSP=$fileInLoc chain=$chainInLoc:".
			       "missing hssp{'prof',$kwdHssp,$itres}!",
			       $SBR4)) if (! defined $prot{"prof",$kwdHssp,$itres});
		$prot{$kwd,$itres}=$prot{"prof",$kwdHssp,$itres};
		undef $prot{"prof",$kwdHssp,$itres};
	    }
				# profiles
	    foreach $aa (@aa){
		$prot{$aa,$itres}=$prot{"prof",$aa,$itres};
		undef $prot{"prof",$aa,$itres};
	    }
	}}
				# ------------------------------
				# 'acc' -> %protacc
    else {
	$protacc{"numres"}=
	    $protacc{"nres"}=$hssp{"numres"};
	$protacc{"nali"}=$hssp{"numali"};
				# translate some names
	$protacc{"nfar"}=0;
	$protacc{"nfar"}=$hssp{"ndist"}  if (defined $hssp{"ndist"});
	foreach $other (@otherDistance){
	    $prot{"nfar",$other}=$prot{"ndist",$other} if (defined $prot{"ndist",$other});
	}
	
	foreach $itres (1..$protacc{"numres"}){
	    foreach $kwd ("nocc","ndel","nins","cons"){
		$kwdHssp=$nndbPtr{$kwd};
		return(&errSbr("HSSP=$fileInLoc chain=$chainInLoc:".
			       "missing hssp{'prof',$kwdHssp,$itres}!",
			       $SBR4)) if (! defined $hssp{"prof",$kwdHssp,$itres});
		$protacc{$kwd,$itres}=$hssp{"prof",$kwdHssp,$itres};
	    }
				# profiles
	    foreach $aa (@aa){
		$protacc{$aa,$itres}=$hssp{"prof",$aa,$itres};
	    }
	}
    }
				# --------------------------------------------------
				# cut insertions, deletions, strange
				# --------------------------------------------------
				# ------------------------------
				# all except 'acc' -> %prot
    $#WARN_SEQUENCE_CUT=0;
    if ($modeLoc ne "acc"){
				# find them
	$#tmp=0;
	foreach $itres (1..$prot{"numres"}){
				# lower to upper
	    if   ($prot{"seq",$itres}=~ /[acdefghiklmnpqrstvwxy]/){
		$prot{"seq",$itres}=~tr/[a-z]/[A-Z]/;
		next; }
				# insertions
	    if ($prot{"seq",$itres} =~ /[\.\-~]/){
		$tmp[$itres]=1;
		push(@WARN_SEQUENCE_CUT,$itres);
		next; }
				# unknown residue
	    if ($prot{"seq",$itres} !~ /[ACDEFGHIKLMNPQRSTVWYZ!]/){
		$prot{"seq",$itres}=$par{"symbolResidueUnk"}; 
		next; }}

				# now cut
	$ct=0;
	foreach $itres (1 .. $prot{"numres"}){
	    next if (defined $tmp[$itres]);	# insertion!
	    ++$ct;
	    foreach $kwd ("seq","acc","sec","nocc","ndel","nins","entr","rele","cons",@aa){
		$prot{$kwd,$ct}=$prot{$kwd,$itres} if (defined $prot{$kwd,$itres});
	    }}
	$numres=$ct;
				# free memory for remaining (now unused ones)
	foreach $itres (($ct+1) .. $prot{"numres"}){
	    foreach $kwd ("seq","acc","sec","nocc","ndel","nins","entr","rele","cons",@aa){
		undef $prot{$kwd,$itres} if (defined $prot{$kwd,$itres});}}
	
				# update count
	$prot{"numres"}=$prot{"nres"}=$numres;

				# --------------------------------------------------
				# cut out proteins with too few aligned residues
	if    (($par{"optOutAli"} || $par{"doRetMsf"} || $par{"doRetSaf"}) &&
	       ! $par{"doRetAliExpand"}){
	    $ct=0;
	    undef %tmp;
	    foreach $itali (1..$prot{"numali"}){
		$seq="";
		foreach $itres (1 .. $prot{"numres"}) {
		    if (! defined $prot{"ali",$itali,$itres}){
			$seq.="?";}
		    else{
			$seq.=$prot{"ali",$itali,$itres}; }
		}
		$seq=~s/[\-\.~]//g;
		if (length($seq) < $minlen){
		    $tmp{$itali}=1;
		    next; 
		}
		++$ct;
		foreach $kwd ("fin","ID","IDE","LALI"){
		    next if (! defined $prot{$kwd,$itali});
		    $prot{$kwd,$ct}=   $prot{$kwd,$itali};
		}
		foreach $kwd ("ali"){
		    foreach $itres (1 .. $prot{"numres"}) {
			$prot{$kwd,$ct,$itres}=$prot{$kwd,$itali,$itres};
		    }}
	    }
	    $prot{"numali"}=$ct if ($ct < $prot{"numali"}); 
	}
    }

				# ------------------------------
				# now for %protacc
    else {
				# find them
	$#tmp=0;
	foreach $itres (1..$protacc{"numres"}){
				# insertions
	    if ($hssp{"seq",$itres} =~ /[\.\-~]/){
		$tmp[$itres]=1;}}
				# now cut
	$ct=0;
	foreach $itres (1 .. $protacc{"numres"}){
	    next if (defined $tmp[$itres]);	# insertion!
	    ++$ct;
	    foreach $kwd ("seq","acc","sec","nocc","ndel","nins","entr","rele","cons",@aa){
		$protacc{$kwd,$ct}=$protacc{$kwd,$itres} if (defined $protacc{$kwd,$itres});
	    }}
	$numres=$ct;
				# free memory for remaining (now unused ones)
	foreach $itres (($ct+1) .. $protacc{"numres"}){
	    foreach $kwd ("seq","acc","sec","nocc","ndel","nins","entr","rele","cons",@aa){
		undef $protacc{$kwd,$itres} if (defined $protacc{$kwd,$itres});}}
				# update count
	$protacc{"numres"}=$protacc{"nres"}=$numres;}

    undef %hssp;

    return(1,"ok $SBR5",$L3D_KNOWN);
}				# end of protRdAliHssp

#===============================================================================
sub protRdSeq {
    local($fileInLoc,$chainInLoc,$formatInLoc,$id,$fileOutLoc,$extChain,
	  $Ldebug,$fileOutScreen,$dirWork,$whichPROFloc) = @_ ;
    my($SBR4,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   protRdSeq                   processes the input database file(s) for single sequences
#                               (3) convert to NN-RDB-DB format
#                               
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#                               
#       in / out GLOBAL:        @FILE_REMOVE, $file{} -> temporary files
#       in / out GLOBAL:        $protRd{},$protRdPtr{}
#                               
#       out GLOBAL:             %prot
#                               
#       out:                    $Lok,$msg
#-------------------------------------------------------------------------------
    $SBR4=""."protRdSeq";
				# check arguments
    return(&errSbr("not def fileInLoc!",    $SBR4)) if (! defined $fileInLoc);
    $chainInLoc=0                                   if (! defined $chainInLoc);
    return(&errSbr("not def formatInLoc!",  $SBR4)) if (! defined $formatInLoc);
    return(&errSbr("not def id!",           $SBR4)) if (! defined $id);
    return(&errSbr("not def fileOutLoc!",   $SBR4)) if (! defined $fileOutLoc);
    return(&errSbr("not def extChain!",     $SBR4)) if (! defined $extChain);
    return(&errSbr("not def Ldebug!",       $SBR4)) if (! defined $Ldebug);
    return(&errSbr("not def fileOutScreen!",$SBR4)) if (! defined $fileOutScreen);
    return(&errSbr("not def dirWork!",      $SBR4)) if (! defined $dirWork);
    return(&errSbr("not def whichPROF",     $SBR4)) if (! defined $whichPROFloc);
#    $fhSbr="STDOUT"                                              if (! defined $fhSbr);

    return(0,"*** $SBR4: no in file=$fileInLoc!")   if (! -e $fileInLoc &&
							$formatInLoc ne "seq");

    $aaLoc=$aa                     if (defined $aa && $aa);
    $aaLoc="VLIMFWYGAPSTCHRKQEND"  if (! defined $aa || ! $aa);
    @aaLoc=split(//,$aaLoc);
    %ptrLoc=('nocc',"NOCC", 'ndel',"NDEL", 'nins',"NINS", 
	     'entr',"ENTROPY", 'rele',"RELENT", 'cons',"WEIGHT")
	if (! defined %protRdPtr || ! %protRdPtr);
    foreach $tmp(@aaLoc){$aaLoc{$tmp}=1;}

    $LisChain=0; 
    $LisChain=1                if (&is_chain($chainInLoc));

				# --------------------------------------------------
				#  read sequence
				# -------------------------------------------------
    if    ($formatInLoc=~/^pir/  ){ # pir
	($Lok,$idTmp,$seqTmp)=  &pirRdMul($fileInLoc,1);}
    elsif ($formatInLoc=~/^fasta/){ # fasta
	($Lok,$idTmp,$seqTmp)=  &fastaRdMul($fileInLoc,1);}
    elsif ($formatInLoc=~/^gcg/){   # gcg
	($Lok,$idTmp,$seqTmp)=  &gcgRd($fileInLoc);}
    elsif ($formatInLoc=~/^swiss/){ # swiss-prot
	($Lok,$idTmp,$seqTmp)=  &swissRdSeq($fileInLoc);}
    elsif ($formatInLoc=~/^dssp/ ){ # dssp
	($Lok,$idTmp,$seqTmp)=  &dsspRdSeq($fileInLoc,$chainInLoc);}
    elsif ($formatInLoc=~/^seq$/ ){ # single sequence in
	$Lok=1; $idTmp=$id; $seqTmp=$fileInLoc;}
    else {
	return(0,"*** ERROR $SBR4: input format $formatInLoc not supported\n");}
    return(0,"*** ERROR $SBR4: failed reading format $formatInLoc\n"."$idTmp\n") if (! $Lok);

				# ------------------------------
				# process sequence
    $seqTmp=~s/[\.~\-]//g;	# purge insertions
    $seqTmp=~tr/[a-z]/[A-Z]/;	# lower to upper case
    $seqTmp=~s/[^ABCDEFGHIKLMNPQRSTUVWXYZ]//g; # purge all non-amino acids
				# ------------------------------
				# translate
    undef %prot;
    $prot{"keywords"}="name,origin,nres,nali,nfar,pfar,nchn,csec"      if (! defined $ali{"keywords"});
    $prot{"names"}=   "no,seq,sec,acc,".
	             join(',',@aaLoc)."cons,nocc,ndel,nins"            if (! defined $prot{"names"});
    $prot{"formats"}= "5N,1S,1S,3N,"."4N," x $#aaLoc ."5.3F,4N,4N,4N"  if (! defined $prot{"formats"});
    $prot{"NROWS"}=length($seqTmp);
	
    foreach $it (1..$prot{"NROWS"}){
	$prot{"no",$it}=    $it;
	$prot{"cons",$it}=  1;
	$prot{"nocc",$it}=  1; $prot{"ndel",$it}=0;$prot{"nins",$it}=0;
#	$prot{"entr",$it}=  1; 
#	$prot{"rele",$it}=100;
	foreach $tmpAA(@aaLoc){	# all profile counts to zero ...
	    $prot{$tmpAA,$it}=0;}
				# ... except for the one there
	$tmpAA=substr($seqTmp,$it,1);
	$prot{"seq",$it}= $tmpAA;
				# AA known?
	if    (defined $aaLoc{$tmpAA}){ $prot{$tmpAA,$it}=100;}
	elsif ($tmpAA eq "B")         { $prot{"D",$it}= 50;
				        $prot{"N",$it}= 50;}
	elsif ($tmpAA eq "Z")         { $prot{"E",$it}= 50;
				        $prot{"Q",$it}= 50;}
	else                          { foreach $tmpAA(@aaLoc){ $prot{$tmpAA,$it}=5;}}}
    $prot{"nres"}=    $prot{"NROWS"};
    $prot{"nali"}=    1;
    $prot{"csec"}=    $modeSec;
    $prot{"nfar"}=    0;
    $prot{"name"}=    $id;
    $prot{"ID"}=      $id;
    $tmp=             $fileInLoc; $tmp=~s/^.*\///g;
    $prot{"origin"}=  $tmp;

				# ------------------------------
				# FOR BLAST: read BLOSUM62
				# ------------------------------
    if ($par{"modeAli"} =~ /psi|blast/){
	($Lok,$msg)=
	    &blastpsiMatReadBlosum
		($par{"fileMatBlosum62psi"}
		 );             return(&errSbrMsg("after call blastPsiMatReadBlosum(".
						  $par{"fileMatBlosum62psi"}.")",
						  $msg,$SBR6)) if (! $Lok);
	foreach $itres (1..$prot{"NROWS"}){
	    foreach $tmpAA (@aa){
		$prot{$tmpAA,$itres}=
		    int(100 * &func_sigmoidGen
			($BLASTMAT{$prot{"seq",$itres},$tmpAA},
			 $par{"blastConvTemperature"}));
	    }
	}
    }
				# --------------------------------------------------
				# cut insertions, deletions, strange
				# --------------------------------------------------
    
				# ------------------------------
				# all except 'acc' -> %prot
				# find them
    $#tmp=0;
    $#WARN_SEQUENCE_CUT=0;
    foreach $itres (1..$prot{"NROWS"}){
				# lower to upper
	if   ($prot{"seq",$itres}=~ /[acdefghiklmnpqrstvwxy]/){
	    $prot{"seq",$itres}=~tr/[a-z]/[A-Z]/;
	    next; }
				# insertions
	if ($prot{"seq",$itres} =~ /[\.\-~]/){
	    $tmp[$itres]=1;
	    push(@WARN_SEQUENCE_CUT,$itres);
	    next; }
				# unknown residue
	if ($prot{"seq",$itres} !~ /[ACDEFGHIKLMNPQRSTVWYZ!]/){
	    $prot{"seq",$itres}=$par{"symbolResidueUnk"}; 
	    next; }}

				# now cut
    $ct=0;
    foreach $itres (1 .. $prot{"nres"}){
	next if (defined $tmp[$itres]);	# insertion!
	++$ct;
	foreach $kwd ("nocc","ndel","nins",
#		      "entr","rele",
		      "cons",@aa){
	    $prot{$kwd,$ct}=$prot{$kwd,$itres} if (defined $prot{$kwd,$itres});
	}}
    $numres=$ct;

				# free memory for remaining (now unused ones)
    foreach $itres (($ct+1) .. $prot{"nres"}){
	foreach $kwd ("nocc","ndel","nins",
#		      "entr","rele",
		      "cons",@aa){
	    undef $prot{$kwd,$itres} if (defined $prot{$kwd,$itres});}}
	
				# update count
    $prot{"numres"}=$prot{"nres"}=
	$protacc{"numres"}=$protacc{"nres"}=
	    $numres;

				# ------------------------------
				# now for %protacc
    if ($whichPROFloc =~ /^(3|acc|both)/){
				# find them
	$#tmp=0;
	foreach $itres (1..$protacc{"nres"}){
				# insertions
	    if ($prot{"seq",$itres} =~ /[\.\-~]/){
		$tmp[$itres]=1;
	    }
	}
				# now cut
	$ct=0;
	foreach $itres (1 .. $protacc{"nres"}){
	    next if (defined $tmp[$itres]);	# insertion!
	    ++$ct;
	    foreach $kwd ("nocc","ndel","nins",
#			  "entr","rele",
			  "cons",@aa){
		$protacc{$kwd,$ct}=$protacc{$kwd,$itres} if (defined $protacc{$kwd,$itres});
	    }}
	$numres=$ct;
				# free memory for remaining (now unused ones)
	foreach $itres (($ct+1) .. $protacc{"nres"}){
	    foreach $kwd ("nocc","ndel","nins",
#			  "entr","rele",
			  "cons",@aa){
		undef $protacc{$kwd,$itres} if (defined $protacc{$kwd,$itres});}
	}
				# update count
	$protacc{"numres"}=$protacc{"nres"}=$numres;
    }
				# ------------------------------
				# set some flags
    $L3D_KNOWN=0;
                                # ------------------------------
                                # save memory
    undef %tmp; undef %ptrLoc; 
    return(1,"ok $SBR4");
}				# end of protRdSeq

#===============================================================================
sub vecInWrt {
    local($itSamLoc,$fhoutInLoc,$numinLoc) = @_ ; 
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   vecInWrt                    write the input patterns for NN.f
#                               
#       in:                     $itSamLoc=   current sample
#       in:                     $fhoutInLoc= file handle for current output
#       in:                     $numinLoc= number of input units
#       in:                     $BEG=      beg of current chain
#       in:                     $END=      end of current chain
#       in:                     $ra_codeUnitIn with $codeUnitIn[i]=meaning of input unit i
#                               
#       in GLOBAL:              $par{"verb3|bitacc"}
#       in GLOBAL:              @codeUnitIn1st
#                               
#       in GLOBAL:              @vecIn: input vector for one sample
#       in GLOBAL:              $vecIn{}=      input vector, with
#       in GLOBAL:                 $vecIn{"it","seq"}=   aa corresponding to input vector it
#       in GLOBAL:                 $vecIn{"it","itvec"}= value of the 'itvec' component of 
#                                              the input vector 'it'
#       in GLOBAL:                 $vecIn{"NROWS"}=      total number of rows (e.g. residues)
#       in GLOBAL:                 $vecIn{"NUMIN"}=      total number of units per example
#                                  NOTE:       NOW integer (i.e. * bitacc)
#       out:                    implicit: file
#       err:                    1|0, message
#-------------------------------------------------------------------------------
    $SBR3=""."vecInWrt";

    $formRepeat=$par{"formRepeat"} || 25
	if (! defined $formRepeat);

                                # --------------------------------------------------
                                # ONLY CURRENT SAMPLE
                                # --------------------------------------------------
    printf $fhoutInLoc "%-8s%8d\n","ITSAM:",$itSamLoc; 
                                # format: I8 = ctSam, + 25I6 = vecIn
    for ($itin=1;$itin<=$numinLoc;$itin+=$formRepeat){
	$itinEnd=($itin+($formRepeat-1));
	$itinEnd=$numinLoc      if ($itinEnd > $numinLoc);
	foreach $itin2 ($itin .. $itinEnd){
	    printf $fhoutInLoc "%6d",$vecIn[$itin2]; 
	}
	print $fhoutInLoc "\n";
    }
    return(1,"ok $SBR3");
}				# end of vecInWrt

#===============================================================================
sub wrtRdbBefore {
#    local() = @_ ;
    local($SBR2,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbBefore                cleans up array @kwdRdb
#       in GLOBAL:              @kwdRdb:        build up by &interpretMode(),
#       out GLOBAL:             @kwdRdb:        build up by &interpretMode(),
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."wrtRdbBefore";
				# security hack: avoid duplication
    $#tmp=0; undef %tmp;
    foreach $kwd (@kwdRdb){
	$kwd=~s/\s//g;
	$kwd=~s/[^a-z0-9A-Z\-\_\.]//g;
	if (! defined $tmp{kwd}){
	    push(@tmp,$kwd);
	    $tmp{$kwd}=1;
	}}
    @kwdRdb=@tmp;

				# resort arrays
    undef %tmp2;
    foreach $kwd (@kwdRdb){
	$tmp2{$kwd}=1;
    }
    $#tmp2=0;
    undef %tmp3;
    foreach $kwd (split(/,/,$kwdGlob{"succession"})){
	next if (! defined $tmp2{$kwd});
	push(@tmp2,$kwd);
	$tmp3{$kwd}=1;
    }
				# now the missing ones
    $#tmp3=0;
    foreach $kwd (@kwdRdb){
	next if (defined $tmp3{$kwd});
	push(@tmp3,$kwd);}
    @kwdRdb=(@tmp2,@tmp3);
    undef %tmp2; undef %tmp3;
    $#tmp2=0;
    $#tmp3=0;

    return(1,"ok $SBR2");
}				# end of wrtRdbBefore

#===============================================================================
sub wrtRdbBody {
    local($fhoutLoc,$numhyphen,$sep) = @_ ;
    local($SBR2,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbBody                  writes body of final RDB file
#       in:                     $fhoutLoc:      file handle to write
#       in:                     $numhyphen:     num hyphens used as optical guide
#       in:                     $sep:           separator for columns
#       in GLOBAL:              @kwdRdb:        build up by &interpretMode(),
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."wrtRdbBody";
				# check arguments
    return(&errSbr("not def fhoutLoc!",$SBR2)) if (! defined $fhoutLoc);
    $numhypen=80                               if (! defined $numhyphen);
    $sep=     "\t"                             if (! defined $sep);

				# ------------------------------
				# finish writing the header
    print $fhoutLoc 
	"# ". "-" x $numhyphen ."\n",
	"# \n";
				# ------------------------------
				# write names
    $tmp="";
    foreach $kwd (@kwdRdb){
	next if (! defined $rdb{1,$kwd});
	$tmp.=$kwd.$sep;
	$tmp.=$kwd."NOphd".$sep
	    if ($kwd=~/ri/i && defined $rdb{1,$kwd."nophd"});
    }
    $tmp=~s/$sep$/\n/;
    print $fhoutLoc $tmp;
				# ------------------------------
				# write new RDB BODY
    foreach $itres (1..$rdb{"NROWS"}){
	$tmp="";
	foreach $kwd (@kwdRdb){
	    next if (! defined $rdb{$itres,$kwd});
	    $tmp.=$rdb{$itres,$kwd}.$sep;
	    $tmp.=$rdb{$itres,$kwd."nophd"}.$sep
		if ($kwd=~/ri/i && defined $rdb{$itres,$kwd."nophd"});
	}
	$tmp=~s/$sep$/\n/;
	print $fhoutLoc $tmp;
    }

    return(1,"ok $SBR2");
}				# end of wrtRdbBody

#===============================================================================
sub wrtRdbHead {
    local($fhoutLoc2,$fileInLoc,$fileTakenLoc,$paraTakenLoc,$whichPROFloc,
	  $numwhite,$numhyphen,$L3d_knownLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHead                  writes header for RDB file from PROF
#                               
#       in:                     $fhoutLoc2      file handle to write
#       in:                     $fileInLoc      prediction mode [3|all|both|sec|acc|htm]
#       in:                     $fileTakenLoc   alignment file taken
#       in:                     $paraTakenLoc   filter parameters (=0 if none)
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#       in:                     $numwhite       num white spaces used as guide
#       in:                     $numhyphen      num hyphens used as optical guide
#       in:                     $L3d_knownLoc   =1 if structure known
#                               
#       in GLOBAL:              %rdb;
#       in GLOBAL:              %par;
#       in GLOBAL:              @kwdRdb         from &interpretMode;
#                               
#       out GLOBAL:             $modepredFin    prediction mode [3|all|both|sec|acc|htm]
#       out GLOBAL:             %rdb
#       in:                     $modeoutLoc     output mode     [HEL|be|bie|10|HL|HT|TM|Hcap]
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."wrtRdbHead";   
				# ------------------------------
				# check arguments
    return(&errSbr("not def fhoutLoc2!",    $SBR5)) if (! defined $fhoutLoc2);
    return(&errSbr("not def fileInLoc!",    $SBR5)) if (! defined $fileInLoc);
    return(&errSbr("not def fileTakenLoc!", $SBR5)) if (! defined $fileTakenLoc);
    return(&errSbr("not def paraTakenLoc!", $SBR5)) if (! defined $paraTakenLoc);
    return(&errSbr("not def whichPROFloc",   $SBR5)) if (! defined $whichPROFloc);
    $numwhite=    10            if (! defined $numwhite);
    $numhyphen=   80            if (! defined $numhyphen);
    $L3d_knownLoc= 0            if (! defined $L3d_knownLoc || $L3d_knownLoc ne "1");

				# ------------------------------
				# summary information
    @tmpwrt=
	("# Perl-RDB ",
	 "# PROF".$whichPROFloc,
	 "# ",
	 "# Copyright          : ".$par{"txt","copyright"},
	 "# Email              : ".$par{"txt","contactEmail"},
	 "# WWW                : ".$par{"txt","contactWeb"},
	 "# Version            : ".$rdb{"version"},
	 "# ",
	 );
				# ------------------------------
				# protein information
    @tmp2=
	("# ". "-" x $numhyphen ,
	 "# About your protein :",
	 "# ");
    undef %tmp;
    foreach $kwd ("prot_id","prot_name",
		  "prot_nchn","prot_kchn",
		  "prot_nres",
		  "prot_nali","prot_nfar",
		  "prot_cut"
		  ){
	next if (! defined $rdb{$kwd});
	next if ($rdb{$kwd}=~/^\s*$/);
	$tmp{$kwd}=1;
	$tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	push(@tmp2,"# VALUE    ".$tmp. " " x ($numwhite-length($tmp)) .": ".$rdb{$kwd});

				# other info
	if ($kwd =~ /prot_nfar/ && $#otherDistance){
	    foreach $other (@otherDistance){
		next if (! defined $rdb{$kwd,$other} || 
			 ! defined $otherDistance[$#otherDistance] ||
			 ! defined $rdb{$kwd,$otherDistance[$#otherDistance]});
		if ($other > 0){
		    $val= $rdb{$kwd,$other}-$rdb{$kwd,$otherDistance[$#otherDistance]};
		    $kwd2=$kwd.$other."-".$otherDistance[$#otherDistance];}
		else {
		    $val= $rdb{$kwd,$other};
		    $kwd2=$kwd.$other;}
		$tmp=$kwd2; $tmp=~tr/[a-z]/[A-Z]/;
		push(@tmp2,"# VALUE    ".$tmp. " " x ($numwhite-length($tmp)) .": ".$val);
	    }}
    }

    if ($#tmp2>3) { push(@tmpwrt,@tmp2,"# ");
		    $Lprot=1;} else {$Lprot=0;}

				# ------------------------------
				# alignment information
    @tmp2=
	("# ". "-" x $numhyphen ,
	 "# About the alignment:",
	 "# ");
    foreach $kwd (
		  "ali_orig","ali_used","ali_para"
		  ){
	next if (! defined $rdb{$kwd});
	next if ($kwd eq "ali_used" &&
		 $rdb{"ali_orig"} eq $rdb{$kwd});
	next if (! $rdb{$kwd});
	next if ($rdb{$kwd}=~/^\s*$/);
	$tmp{$kwd}=1;
	$tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	push(@tmp2,"# VALUE    ".$tmp. " " x ($numwhite-length($tmp)) .": ".$rdb{$kwd});}
    push(@tmpwrt,@tmp2,"# ")    if ($#tmp2 > 3);

				# ------------------------------
				# PROFhtm summary
    if ($whichPROFloc =~ /^(3|htm)$/){
	$numwhiteHtm=$numwhite+10;
	@tmp2=
	    ("# ". "-" x $numhyphen ,
	     "# PROFhtm summary:","# ");
	foreach $kwd (@{$kwdGlob{"head"}}){
	    next if ($kwd !~ /^htm/);
	    next if (! defined $rdb{$kwd});
	    @tmpval=split(/\t/,$rdb{$kwd});
	    $tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	    foreach $tmpval (@tmpval){
		push(@tmp2,"# VALUE    ".$tmp. " " x ($numwhiteHtm-length($tmp)) .": ".$tmpval);
	    }
	}
	push(@tmpwrt,@tmp2,"# ") if ($#tmp2>3);
    }
				# ------------------------------
				# network information
    @tmp2=
	("# ". "-" x $numhyphen ,
	 "# About PROF specifics:","# ");
    foreach $kwd ("prof_fpar","prof_nnet","prof_fnet"){
	next if (! defined $rdb{$kwd});
	next if ($rdb{$kwd}=~/^\s*$/);
	$tmp{$kwd}=1;
	$tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	push(@tmp2,"# VALUE    ".$tmp. " " x ($numwhite-length($tmp)) .": ".$rdb{$kwd});}
    if ($#tmp2>3) { push(@tmpwrt,@tmp2,"# ");
		    $Lnet=1;} else {$Lnet=0;}

				# --------------------------------------------------
				# write (only if flag to surpress header NOT set)
    if (! $par{"rdbHdrSimple"}){
	($Lok,$msg,@tmp2)=
	    &wrtRdbHeadNotation($whichPROFloc);	
	if (! $Lok){ $tmp="*** ERROR $SBR5: failed to write notation!\n".$msg."\n";
		     print $FHERROR $tmp;
		     print $FHTRACE $tmp; }
	push(@tmpwrt,@tmp2)     if ($Lok && $#tmp2>0);
	$#tmp2=0; }

				# --------------------------------------------------
				# write entire header
    foreach $hdr (@tmpwrt){ 
	next if (! defined $hdr);
	next if ($hdr=~/^\s*$/);
	next if ($hdr=~/observed/ && ! $L3d_knownLoc); 
	print $fhoutLoc2 $hdr,"\n"; 
    }
				# ------------------------------
				# clean up
    $#tmp=0;			# slim-is-in
    return(1,"ok $SBR5");
}				# end of wrtRdbHead

#===============================================================================
sub wrtRdbHeadIni {
    local($fileInLoc,$fileTakenLoc,$paraTakenLoc,$whichPROFloc2) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHeadIni               builds the initial header for RDB file from PROF
#                               gets data from %prot, writes to 
#                               
#       in:                     $fileInLoc      prediction mode [3|all|both|sec|acc|htm]
#       in:                     $fileTakenLoc   alignment file taken
#       in:                     $paraTakenLoc   filter parameters (=0 if none)
#       in:                     $whichPROFloc: is par{"optProf"} <3|both|sec|acc|htm|cap>
#                               
#       in GLOBAL:              %prot;
#       in GLOBAL:              %rdb;
#       in GLOBAL:              %par;
#       in GLOBAL:              @kwdRdb         from &interpretMode;
#                               
#       out GLOBAL:             $modepredFin    prediction mode [3|all|both|sec|acc|htm]
#       out GLOBAL:             %rdb
#       in:                     $modeoutLoc     output mode     [HEL|be|bie|10|HL|HT|TM|Hcap]
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."wrtRdbHeadIni";   
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!",    $SBR5)) if (! defined $fileInLoc);
    return(&errSbr("not def fileTakenLoc!", $SBR5)) if (! defined $fileTakenLoc);
    return(&errSbr("not def paraTakenLoc!", $SBR5)) if (! defined $paraTakenLoc);
    return(&errSbr("not def whichPROFloc2", $SBR5)) if (! defined $whichPROFloc2);

				# ------------------------------
				# initialise names asf
				# ------------------------------
    if    (defined $prot{"id"})   {$rdb{"prot_id"}=  $prot{"id"};}
    elsif (defined $prot{"PDBID"}){$rdb{"prot_id"}=  $prot{"PDBID"};}
    else                          {$rdb{"prot_id"}=  "unk";}
	    
    $rdb{"prot_name"}=$prot{"HEADER"} if (defined $prot{"HEADER"});
    $rdb{"prot_cmpd"}=$prot{"COMPND"} if (defined $prot{"COMPND"});
    $rdb{"prot_nchn"}=$prot{"nchn"}   if (defined $prot{"nchn"});
    $rdb{"prot_kchn"}=$prot{"kchn"}   if (defined $prot{"kchn"});
    $rdb{"prot_nres"}=$prot{"nres"}   if (defined $prot{"nres"});
    $rdb{"prot_nali"}=$prot{"nali"}   if (defined $prot{"nali"});
    $rdb{"prot_nfar"}=$prot{"nfar"}   if (defined $prot{"nfar"});

    foreach $other (@otherDistance){
	$rdb{"prot_nfar",$other}=$prot{"nfar",$other};}

    $rdb{"ali_orig"}= $fileInLoc;
    $rdb{"ali_used"}= $fileTakenLoc;
    $rdb{"ali_para"}= $paraTakenLoc;

				# ------------------------------
				# get all modes
    $tmp="";
    foreach $itpar (1..$par{"para"}){
				# highest current level
	$level=   $par{"para",$itpar};
	foreach $itfile (1..$par{"para",$itpar,$level}){
				# modes
	    foreach $kwd ("modepred","modeout"){
		$run{$itpar,$kwd}=$par{"para",$itpar,$level,$itfile,$kwd};
		$tmp.=$run{$itpar,$kwd}.",";
		next if ($kwd=~/modeout/);
		$rdb{"modepred",$run{$itpar,$kwd}}=1;
	    }
	}
    }
				# xyyx hack
    $tmp=$whichPROFloc2         if (length($tmp) < 1);
				# yy end of hack
    if    ($tmp=~/sec/ && $tmp=~/acc/ && $tmp=~/htm/){
	$modepredFin="3";}
    elsif ($tmp=~/sec/ && $tmp=~/acc/){
	$modepredFin="both";}
    elsif ($tmp=~/sec/){
	$modepredFin="sec";}
    elsif ($tmp=~/acc/){
	$modepredFin="acc";}
    elsif ($tmp=~/htm/){
	$modepredFin="htm";}
    else {
	return("mode=$tmp, not digested!",$SBR5);}
    $rdb{"modepred"}=$modepredFin;
    $whichPROFloc2=$modepredFin;

				# ------------------------------
				# convert to %rdb
				# ------------------------------
    $rdb{"version"}=  $par{"txt","version"} if (! defined $rdb{"version"});
    $rdb{"date"}=     $date              if (! defined $rdb{"date"});
    $rdb{"prof_fpar"}= "";
    $rdb{"prof_nnet"}= "";
    $rdb{"prof_mode"}= "";
    foreach $itpar (1..$par{"para"}){
	$rdb{"prof_fpar"}.=$run{$itpar,"modepred"}."=".$filePar[$itpar].",";
	$rdb{"prof_nnet"}.=$run{$itpar,"modepred"}."=".$par{"para",$itpar,$par{"para",$itpar}}.",";
	$rdb{"prof_mode"}.=$run{$itpar,"modepred"}.":".
	    $par{"para",$itpar,$par{"para",$itpar},1,"modeout"}.",";
	$rdb{"modepred",$run{$itpar,"modepred"}}=1;
    }
    $rdb{"prof_fpar"}=~s/,$//g;
    $rdb{"prof_nnet"}=~s/,$//g;

#    $rdb{"modepred"}= $modepredLoc        if (! defined $rdb{"modepred"});
#    $rdb{"modeout"}=  $modeoutLoc         if (! defined $rdb{"modeout"});
    $rdb{"version"}=    $par{"txtVersion"}  if (! defined $rdb{"version"});
    $rdb{"prof_version"}=$rdb{"version"};

				# trace about truncation
    if ($#WARN_SEQUENCE_CUT){
	$kwd="PROT_CUT";
	if ($#WARN_SEQUENCE_CUT == 1){
	    $val= "The non-amino acid residue (no=".
		$WARN_SEQUENCE_CUT[1].") was truncated!";}
	else {
	    $val= "The non-amino acid residues (nos=".
		&assNumbers2range(@WARN_SEQUENCE_CUT).") were truncated!";}
	$rdb{"prot_cut"}=$val;
#	push(@tmp2,"# VALUE    ".$kwd. " " x ($numwhite-length($kwd)) .": ".$val);
    }
				# ------------------------------
				# clean up
    $#tmp=0;			# slim-is-in
    $#tmp2=0;			# slim-is-in
    return(1,"ok $SBR5",$whichPROFloc2);
}				# end of wrtRdbHeadIni

#===============================================================================
sub wrtRdbHeadNotation {
    local($whichPROFloc)=@_;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHeadNotation          writes meaning of notation into RDB header
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."wrtRdbHeadNotation";

    $#tmp2=0;
    push(@tmp2,
	 "# ". "-" x $numhyphen ,
	 "# Notation used      :");

				# ------------------------------
				# notation: header: protein
    $tmp="HEADER". " " x ($numwhite-6) . ": PROTEIN";
    push(@tmp2,
	 "# ",
#	 "# NOTATION "."-" x length($tmp),
	 "# "."-" x 72,
	 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp))
	 );
    foreach $kwd ("prot_id","prot_name","prot_nres","prot_nchn","prot_kchn",
		  "prot_nali","prot_nfar"){
	next if (! defined $par{"notation",$kwd});
	next if (! defined $tmp{$kwd});
	$tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	$tmpcontd=$kwd." contd";
	$tmpdes=     "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)) .": ";
	$tmpdescontd="# NOTATION ".$tmpcontd. " " x ($numwhite-length($tmpcontd)) .": ";
	$notation=$par{"notation",$kwd};
	$notation=~s/\n/\n$tmpdescontd/g;
	push(@tmp2,$tmpdes.$notation);}

				# ------------------------------
				# notation: header: alignment
    $tmp="HEADER". " " x ($numwhite-6) . ": ALIGNMENT";
    push(@tmp2,
	 "# ",
	 "# "."-" x 72,
	 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));
    foreach $kwd ("ali_orig","ali_used","ali_para"
		  ){
	next if (! defined $par{"notation",$kwd});
	next if (! defined $tmp{$kwd});
	$tmpcontd=$kwd." contd";
	$tmpdes=     "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)) .": ";
	$tmpdescontd="# NOTATION ".$tmpcontd. " " x ($numwhite-length($tmpcontd)) .": ";
	$notation=$par{"notation",$kwd};
	$notation=~s/\n/\n$tmpdescontd/g;
	push(@tmp2,$tmpdes.$notation);}

				# ------------------------------
				# notation: header: network
    $tmp="HEADER". " " x ($numwhite-6) . ": INTERNAL";
    push(@tmp2,
	 "# ",
	 "# "."-" x 72,
	 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));
    foreach $kwd ("prof_fpar","prof_nnet","prof_fnet","prof_mode"){
	next if (! defined $par{"notation",$kwd});
	next if (! defined $tmp{$kwd});
	$tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	$tmpcontd=$kwd." contd";
	$tmpdes=     "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)) .": ";
	$tmpdescontd="# NOTATION ".$tmpcontd. " " x ($numwhite-length($tmpcontd)) .": ";
	$notation=$par{"notation",$kwd};
	push(@tmp2,$tmpdes.$notation);}

				# ------------------------------
				# notation: body: protein
    push(@tmp2,"# ");
    $tmp="BODY ". " " x ($numwhite-5) . ": PROTEIN";
    push(@tmp2,
	 "# ",
	 "# "."-" x 72,
	 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));
    foreach $kwd ("No","AA","CHN"){
	next if (! defined $par{"notation",$kwd});
	$tmp=$kwd; $tmp=~tr/[a-z]/[A-Z]/;
	$tmpdes=     "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)) .": ";
	$tmpdescontd="# NOTATION ".$tmpcontd. " " x ($numwhite-length($tmpcontd)) .": ";
	$notation=$par{"notation",$kwd};
	$notation=~s/\n/\n$tmpdescontd/g;
	push(@tmp2,$tmpdes.$notation);}

				# ------------------------------
				# notation: body: prof

    $#tmp=0;
    if ($whichPROFloc =~ /^(3|both)$/){
	$tmp="BODY ". " " x ($numwhite-5) . ": PROF";
	push(@tmp,
	     "# ",
	     "# "."-" x 72,
	     "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));}
    else {
	push(@tmp,
	     "# ");}
	

				# get ok succession for notation of keywords
    $#tmpkwd=0;
    undef %tmpkwd;
    push(@tmpkwd,split(/,/,$kwdGlob{"succession","notation","sec"})) 
	if ($whichPROFloc =~/^(sec|3|both)/);
    push(@tmpkwd,split(/,/,$kwdGlob{"succession","notation","acc"}))
	if ($whichPROFloc =~/^(acc|3|both)/);
    push(@tmpkwd,split(/,/,$kwdGlob{"succession","notation","htm"}))
	if ($whichPROFloc =~/^(htm|3)/);
    foreach $kwd (@tmpkwd){
	$tmpkwd{$kwd}=1;
    }
				# missing ones
    foreach $kwd (@kwdRdb){
	next if (defined $tmpkwd{$kwd});
	push(@tmpkwd,$kwd);
	$tmpkwd{$kwd}=1;
    }

    undef %tmp;
#    foreach $kwd (@kwdRdb){
    foreach $kwd (@tmpkwd){
				# avoid duplication
	next if (defined $tmp{$kwd});
	next if ($kwd =~ /^(No|AA)/);
	$tmp{$kwd}=1;
	next if (! defined $par{"notation",$kwd});
				# skip known, since not wanted here
	next if (! $L3d_knownLoc && $kwd =~/^O/ && $kwd !~/^Ot/);
				# check whether is there
	$rdb{$kwd}=1;
	$tmp=$kwd; 
#	$tmp=~tr/[a-z]/[A-Z]/;
				# split annotations too long
	$tmpdes=     "# NOTATION ".$tmp.      " " x ($numwhite-length($tmp))      .": ";
	$notation=$par{"notation",$kwd};
				# no new line in RDB
	$notation=~s/\n/ /g;
				# ------------------------------
				# insert header
	if    ($kwd =~ /ACC/ && ! defined $tmp{"acc"}){
	    $tmp{"acc"}=1;
	    $tmp="BODY ". " " x ($numwhite-5) . ": PROFacc";
	    push(@tmp,"# ",
		 "# "."-" x 72,
		 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));}
	elsif ($kwd =~ /HEL/ && ! defined $tmp{"sec"}){
	    $tmp{"sec"}=1;
	    $tmp="BODY ". " " x ($numwhite-5) . ": PROFsec";
	    push(@tmp,"# ",
		 "# "."-" x 72,
		 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));}
	elsif ($kwd =~ /MN/ && ! defined $tmp{"htm"}){
	    $tmp{"htm"}=1;
	    $tmp="BODY ". " " x ($numwhite-5) . ": PROFhtm";
	    push(@tmp,"# ",
		 "# "."-" x 72,
		 "# NOTATION ".$tmp. " " x ($numwhite-length($tmp)));}

				# ------------------------------
				# add to final
	push(@tmp,$tmpdes.$notation);
    }
    $#tmpkwd=0;

    if (defined $PROF_SKIP){
	$tmp="NOTE";
	push(@tmp,
	     "# NOTATION ".$tmp." " x ($numwhite-length($tmp)) .": ".$par{"notation","prof_skip"});}
    push(@tmp2,
	 @tmp,
	 "# " ,
#	 "# ". "-" x $numhyphen ,
#	 "# "
	 )                      if ($#tmp > 3);

    return(1,"ok $SBR6",@tmp2);
}				# end of wrtRdbHeadNotation

#===============================================================================
sub wrtScreenHead {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtScreenHead               write header onto screen
#-------------------------------------------------------------------------------
    print $FHTRACE 
	"---     ------------------------------------------------- \n",
	"---     Dear User, \n","---      \n",
	"---     Welcome to PROF the three level neural network  \n",
	"---     prediction of: \n",
	"---                   secondary structure in 3 states, \n",
	"---                   solvent accessibility in 10 states, \n",
	"---                   or helical trans-membrane regions in 2 states. \n",
	"---      \n",
	"---     either call with:  \n",
	"---     	'".$0." file.HSSP'  \n",
	"---     or use defaults :  \n",
	"---     	'".$0."' \n",
	"---     in which case you will be requested to name a \n",
	"---     file containing an alignment in the format of \n",
	"---     HSSP|SAF|MSF|FASTA \n","---      \n",
	"---      \n",
	"---     in case of difficulties, feel free to contact: \n",
	"---        	Burkhard Rost \n",
	"---        	internet: rost\@columbia.edu \n",
	"---      \n",
	"---     One common trouble is: that your environment \n",
	"---     does not define a ARCH, i.e. the machine type. \n",
	"---     If so, please use:  \n",
	"---     	'$tmp2", ".ARCH \n",
	"---     where MACHINE is  \n",
	"---     	= LINUX, for LINUX boxes\n",
	"---     	= ALPHA, for DEC ALPHA\n",
	"---     	= SGI5,  for SGI R5000, O2\n",
	"---     	= SGI64, for SGI R10-12000 \n",
	"---      \n",
	"---     ------------------------------------------------- \n",
	"---      \n";
}				# end of wrtScreenHead

#===============================================================================
sub wrtScreenFoot {
    local($timeBegLoc,$dateLoc,$nfileInLoc,$whichPROFloc)=@_;
#-------------------------------------------------------------------------------
#   wrtScreenFoot              write final words onto screen
#-------------------------------------------------------------------------------

				# run time
    $white="10";
    print 
#	"--- ------------------------------------------------------------------\n",
	"--- PROF:    ",$dateLoc, " " x ($white-length($dateLoc)),
	"        run time=",&fctRunTime($timeBegLoc),"\n";
    print 
	"--- N proteins: ",$nfileInLoc," " x ($white-length($nfileInLoc)),
	" time per protein=",&fctSeconds2time((time-$timeBegLoc)/$nfileInLoc),"\n"
	    if ($nfileInLoc > 2);
	

				# ------------------------------
				# just brief message
    if ((defined $USERID && $USERID =~ /^(rost|prof|eva|meta)$/) || 
	$par{"rdbHdrSimple"}) {
				# close trace files
				# note: deleted in assCleanUp()
#	close($FHTRACE)         if ($FHTRACE  !~/STDOUT/);
#	close($FHTRACE2)        if ($FHTRACE2 !~/STDOUT/);
#	close($FHPROG)          if ($FHPROG   !~/STDOUT/);

				# <--- <--- <--- <--- <--- <--- 
	return(1,"ok");		# early end ...
    }

				# close trace files
    $tmp=substr($whichPROFloc,1,1); $tmp=~tr/[a-z]/[A-Z]/; $tmp.=substr($whichPROFloc,2);
    $des="headProf".$tmp;
				# some more to say
    print  
	"--- \n",
	"--- ", "-" x 74 , " ---\n",
	"--- \n";

    print  
	"---     The program PROF has ended successfully !\n",
	"---     Thanks for Your interest !\n","--- \n",
	"---     .......................................\n",
	"---     Copyright:      Burkhard Rost          \n",
	"---                     ".$par{"txt","contactEmail"}."\n",
	"---     .......................................\n","--- \n";

    print "---     Output files";
    print " (in dir=",$par{"dirOut"},")" if (length($par{"dirOut"})>1);
    print ": \n";

    $#missing=$#format=$#kwdtmp=0;
				# ini
    foreach $it (1..$nfileInLoc){
	$wrt[$it]="";}
				# ------------------------------
				# delete RDB files if unwanted !!
    if (0 && ! $par{"doRetRdb"}){
	foreach $it (1..$nfileInLoc){
#	    unlink($fileOut{$it,"rdb"});
	    print "--- WARN deleting RDB file=",$fileOut{$it,"rdb"},"\n" if ($par{"verb2"});
	    undef $fileOut{$it,"rdb"};
	}}

				# ------------------------------
				# all possible output kwds
    foreach $kwd ("rdb","html","prof","msf","saf","notHtm","dssp","casp"){
	$tmp= substr($kwd,1,1); $tmp=~tr/[a-z]/[A-Z]/;
	$tmp2=$tmp.substr($kwd,2);
				# not to write
	next if (! $par{"doRet".$tmp2});
				# not written
	next if (! defined $fileOut{1,$kwd});
				# not existing
	if (! -e $fileOut{1,$kwd}){
	    push(@missing,$fileOut{1,$kwd});
	    next;}
				# loop over all input files
	$maxlen=0;
	foreach $it (1..$nfileInLoc){
	    $tmp=$fileOut{$it,$kwd};
	    $tmp=~s/^.*\///g;
	    $maxlen=length($tmp) if (length($tmp)>$maxlen);
	    $wrt[$it].=$tmp.",";}
	push(@format,$maxlen);
	push(@kwdtmp,$kwd);
    }
				# now write description
    printf "---     %-5s  ","num";
    foreach $itcol (1..$#format){
	printf "%-".$format[$itcol]."s ",$kwdtmp[$itcol];
    }
    print "\n";
				# now data
    foreach $it (1..$nfileInLoc){
	printf "---     %5d  ",$it;
	$wrt[$it]=~s/,*$//g;
	@tmp=split(/,/,$wrt[$it]);
	foreach $itcol (1..$#format){
	    printf "%-".$format[$itcol]."s ",$tmp[$itcol];
	}
	print "\n";
    }
				# missing output files
    if ($#missing > 0){
	print 
	    "---     NOTE: the following output files appear missing:\n";
	print join("\n",@missing,"\n");
    }

    print  
	"---     Have more or less fun with evaluating the results. \n",
	"---     -------------------------------------------------- \n";
    return(1,"ok");
}				# end of wrtScreenFin 

1;

