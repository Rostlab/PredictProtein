#===============================================================================
sub phdRunPost1 {
    local($fileHssp,$chainHssp,$fileInRdbLoc,$dirLib,$optNiceInLoc,
	  $exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc,
          $LdoHtmfilLoc,$LdoHtmisitLoc,$optHtmMinValLoc,$LdoHtmrefLoc,$LdoHtmtopLoc,
          $fileOutNotLoc,$fileOutRdbLoc,$fileTmpFil,$fileTmpRef,$fileTmpTop,
	  $fileOutScreenLoc,$fhSbrErr) = @_;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunPost1                       
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $fileInRdbLoc  : RDB file from PHD fortran
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress
#       in:                     $optNiceLoc    : priority 'nonice|nice|nice-n'
#                               
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmisitLoc : Perl executable for HTMisit
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#                               
#       in:                     $LdoHtmfil     : 1|0 do or do NOT run
#       in:                     $LdoHtmisit    : 1|0 do or do NOT run
#       in:                     $optHtmMinVal  : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $LdoHtmref     : 1|0 do or do NOT run
#       in:                     $LdoHtmtop     : 1|0 do or do NOT run
#                               
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#       in:                     $fileOutRdbLoc : final RDB file
#       in:                     $fileTmpFil    : temporary file from htmfil
#       in:                     $fileTmpIsit   : temporary file from htmfil
#       in:                     $fileTmpRef    : temporary file from htmfil
#       in:                     $fileTmpTop    : temporary file from htmfil
#                               
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunPost1"; $fhinLoc="FHIN_"."$SBR";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!",$SBR))             if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!",$SBR))            if (! defined $chainHssp);
    return(&errSbr("not def fileInRdbLoc!",$SBR))         if (! defined $fileInRdbLoc);
    return(&errSbr("not def dirLib!",$SBR))               if (! defined $dirLib);
    return(&errSbr("not def optNiceInLoc!",$SBR))         if (! defined $optNiceInLoc);

    return(&errSbr("not def exeHtmfilLoc!",$SBR))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmisitLoc !",$SBR))       if (! defined $exeHtmisitLoc);
    return(&errSbr("not def exeHtmrefLoc!",$SBR))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!",$SBR))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def LdoHtmfilLoc!",$SBR))         if (! defined $LdoHtmfilLoc);
    return(&errSbr("not def LdoHtmisitLoc!",$SBR))        if (! defined $LdoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!",$SBR))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def LdoHtmrefLoc!",$SBR))         if (! defined $LdoHtmrefLoc);
    return(&errSbr("not def LdoHtmtopLoc!",$SBR))         if (! defined $LdoHtmtopLoc);

    return(&errSbr("not def fileOutNotLoc!",$SBR))        if (! defined $fileOutNotLoc);
    return(&errSbr("not def fileOutRdbLoc!",$SBR))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileTmpFil!",$SBR))           if (! defined $fileTmpFil);
    return(&errSbr("not def fileTmpRef!",$SBR))           if (! defined $fileTmpRef);
    return(&errSbr("not def fileTmpTop!",$SBR))           if (! defined $fileTmpTop);
				# ------------------------------
				# input files existing ?
#    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
#    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
#    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (! &is_hssp_empty($fileHssp));
    return(&errSbr("no rdb '$fileInRdbLoc'!",$SBR))   if (! -e $fileInRdbLoc);
                                # ------------------------------
                                # executables ok?
    foreach $exe ($exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in exe '$exe'!",$SBR))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!",$SBR))   if (! -x $exePhdLoc ); }
				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

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

				# --------------------------------------------------
                                # is HTM ?
    if ($LdoHtmisitLoc) {       # --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc);
        push(@tmp,"min_val=".substr($optHtmMinValLoc,1,4)) if (defined $optHtmMinValLoc);
        push(@tmp,"file_out_flag="."$fileOutNotLoc")       if (defined $fileOutNotLoc);
        push(@tmp,"not_file_out_wrt") ;                    # dont write numbers in extra output file!
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmisitLoc =~ /\.pl/) { 
            $cmd="$optNiceTmp $exeHtmisitLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmisit=$exeHtmisitLoc, msg=",$msg,$SBR)) if (! $Lok); }
        else {                  # include package
            &phd_htmisit'phd_htmisit(@tmp);                      # e.e'
            $tmp=$exeHtmisitLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
                                # **********************
				# NOT MEMBRANE -> return
        return(1,"none after htmisit ($SBR)",0)            if (-e $fileOutNotLoc);}

				# --------------------------------------------------
    if ($LdoHtmfilLoc) {        # old hand waving filter ?
				# --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc,$fileTmpFil,$fileOutNotLoc);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp); 
                                # run system call
        if ($exeHtmfilLoc =~ /\.pl/) {
            $cmd="$optNiceTmp $exeHtmfilLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmfil=$exeHtmfilLoc, msg=",$msg,$SBR)) if (! $Lok); }
        else {                  # include package
            &phd_htmfil'phd_htmfil(@tmp);                        # e.e'
            $tmp=$exeHtmfilLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileTmpFil,$fileOutRdbLoc)         if (-e $fileTmpFil);}
                
				# --------------------------------------------------
    if ($LdoHtmrefLoc) {        # do refinement ?
				# --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc,"nof file_out=$fileTmpRef");
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmrefLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmrefLoc $fileInRdbLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmref=$exeHtmrefLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmref'phd_htmref(@tmp);                        # e.e'
            $tmp=$exeHtmrefLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
        return(&errSbr("after htmref=$exeHtmrefLoc, no out=$fileTmpRef",$SBR),0) 
            if (! -e $fileTmpRef);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpRef,$fileOutRdbLoc);
	return(&errSbrMsg("htmref copy",$msg,$SBR),0)      if (! $Lok); }

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
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmtopLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmtopLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmtop=$exeHtmtopLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmtop'phd_htmtop(@tmp);                        # e.e'
            $tmp=$exeHtmtopLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
	return(&errSbr("after htmtop=$exeHtmtopLoc, no out=$fileTmpTop",$SBR),0) 
            if (! -e $fileTmpTop);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpTop,$fileOutRdbLoc);
	return(&errSbrMsg("htmtop copy",$msg,$SBR),0)      if (! $Lok); }
    
    return(1,"ok $SBR",1);
}				# end of phdRunPost1

