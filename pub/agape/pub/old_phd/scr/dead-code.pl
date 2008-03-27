#===============================================================================
sub runPhdHtmPost {
    local ($fileHssp,$chainHssp,
	   $filePhd,$fileRdb,$fileNotHtm,$ftmp_fil,$ftmp_ref,$ftmp_top,
	   $exeHtmfil,$Ldo_htmfil,$exeHtmisit,$Ldo_htmisit,$htmisit_min_val,
	   $exeHtmref,$Ldo_htmref,$exeHtmtop,$Ldo_htmtop,$LscreenLoc,$LscreenLoc2)=@_;
    local (@del_loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runPhdHtmPost               post-process HTM pred (htmfil, htmref, htmtop, htmisit)
#       out:                    $Lok,$msg,$LisMembrane
#       err:                    ok -> (1,"ok sbr"), err -> (0,"msg")
#-------------------------------------------------------------------------------
    $sbrName="runPhdHtmPost";
    $#del_loc=0;
				# consistency check
    if (( (! -e $fileRdb) && ($Ldo_htmisit || $Ldo_htmref || $Ldo_htmtop) ) ||
	( (! -e $filePhd) && $Ldo_htmfil ) ) {
	$msg="*** ERROR $sbrName: no existing file (RDB needed for 'top', 'ref', 'isit')\n".
	     "***       neither filePhd '$filePhd', nor fileRdb '$fileRdb' ok\n";
	&abortProg($msg);}
				# ------------------------------
    if ($Ldo_htmisit) {		# is HTM ?
        @tmp=($fileRdb);
        push(@tmp,"min_val=".substr($htmisit_min_val,1,4))       if (defined $htmisit_min_val);
        push(@tmp,"file_out_flag="."$fileNotHtm")                if (defined $fileNotHtm);
        push(@tmp,"not_file_out_wrt") ;                          # dont write numbers in extra output file!
        push(@tmp,"dirLib=".$par{"dirLib"})                      if (-d $par{"dirLib"});
        push(@tmp,"not_screen")                                  if (! $LscreenLoc2);

        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmisit =~ /\.pl/) { 
            $cmd="$optNice $exeHtmisit $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=&sysRunProg($command,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("htmisit=$exeHtmisit, msg=",$msg)) if (! $Lok);
#            &run_program("$command","$fhTrace","warn"); 
	}
        else {                  # include package
            &phd_htmisit'phd_htmisit(@tmp);                      # e.e'
            $tmp=$exeHtmisit;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print "$cmd\n"                                       if ($LscreenLoc); }
        print "--- ","-" x 50,"\n"                               if ($LscreenLoc);
                                # **********************
				# NOT MEMBRANE -> return
        return(1,"none after htmisit",0)                         if (-e $fileNotHtm);}

				# ------------------------------
    if ($Ldo_htmfil) {		# old hand waving filter ?
        $fileTmp=0;
	if    ( -e $fileRdb ) { $fileTmp=$fileRdb; $Ltmprdb=1;}
        elsif ( -e $filePhd ) { $fileTmp=$filePhd; $Ltmprdb=0}
        if ($fileTmp) { @tmp=($fileTmp,$ftmp_fil,$fileNotHtm);
                        push(@tmp,"dirLib=".$par{"dirLib"})      if (-d $par{"dirLib"});
                        push(@tmp,"not_screen")                  if (! $LscreenLoc2); 
                        $arg=join(' ',@tmp); }
                                # run system call
        if ($fileTmp && $exeHtmfil =~ /\.pl/) {
            $cmd="$optNice $exeHtmfil $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=&sysRunProg($command,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("htmfil=$exeHtmfil, msg=",$msg))   if (! $Lok);
#            &run_program("$command","$fhTrace","warn"); 
	}
        elsif ($fileTmp) {      # include package
            &phd_htmfil'phd_htmfil(@tmp);                        # e.e'
            $tmp=$exeHtmfil;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print "$cmd\n"                                       if ($LscreenLoc); }
        print "--- ","-" x 50,"\n"                               if ($LscreenLoc);

        if    ($fileTmp && $Ltmprdb && -e $ftmp_fil){	# now copy
            ($Lok,$msg)=
                &sysCpfile($ftmp_fil,$fileRdb);
#		return(0,"*** ERROR $sbrName after copy\n".$msg,0);
            $file{"tmp$sbrName"."$ftmp_fil"}=$ftmp_fil; push(@kwdRm,"tmp$sbrName"."$ftmp_fil"); }
        elsif ($fileTmp && ! $Ltmprdb && -e $ftmp_fil){	# now copy
            $file{"tmp$sbrName"."$ftmp_fil"}=$ftmp_fil; push(@kwdRm,"tmp$sbrName"."$ftmp_fil"); }}
				# ------------------------------
    if ($Ldo_htmref) {		# do refinement?
        @tmp=($fileRdb,"nof file_out=$ftmp_ref");
        push(@tmp,"dirLib=".$par{"dirLib"})                      if (-d $par{"dirLib"});
        push(@tmp,"not_screen")                                  if (! $LscreenLoc2);
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmref=~/\.pl/){
            $cmd="$optNice $exeHtmref $fileRdb $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=&sysRunProg($command,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("htmref=$exeHtmref, msg=",$msg))   if (! $Lok);
#            &run_program("$command","$fhTrace","warn"); 
	}
        else {                  # include package
            &phd_htmref'phd_htmref(@tmp);                        # e.e'
            $tmp=$exeHtmref;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print "$cmd\n"                                       if ($LscreenLoc); }
        print "--- ","-" x 50,"\n"                               if ($LscreenLoc);

	return(0,"*** ERROR $sbrName after $exeHtmref no output file\n",0) if (! -e $ftmp_ref);
	print "--- ref -> rdb \t \t '\\cp $ftmp_ref $fileRdb'\n" if ($LscreenLoc);
	($Lok,$msg)=
	    &sysCpfile($ftmp_ref,$fileRdb);
	return(&errSbrMsg("(htmref) after copy",$msg),0)         if (! $Lok);
	$file{"tmp$sbrName"."$ftmp_ref"}=$ftmp_ref; push(@kwdRm,"tmp$sbrName"."$ftmp_ref");}
				# ------------------------------
    if ($Ldo_htmtop) {		# do the topology prediction ?
	if    (-e $ftmp_ref)  { $file_tmp=$ftmp_ref;$arg=" ref"; }
	elsif (-e $ftmp_fil)  { $file_tmp=$ftmp_fil;$arg=" fil"; }
        else                  { $file_tmp=$fileRdb; $arg=" nof"; }
	$tmp= "file_out=$ftmp_top file_hssp=$fileHssp";
	$tmp.="_".$chainHssp                                     if (defined $chainHssp && 
								     $chainHssp=~/^[0-9A-Z]$/);
	@tmp=($file_tmp,$tmp);
        push(@tmp,"dirLib=".$par{"dirLib"})                      if (-d $par{"dirLib"});
        push(@tmp,"not_screen")                                  if (! $LscreenLoc2);
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmtop=~/\.pl/){
            $cmd="$optNice $exeHtmtop $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=&sysRunProg($command,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("htmtop=$exeHtmtop, msg=",$msg))   if (! $Lok);
#            &run_program("$command","$fhTrace","warn"); 
	}
        else {                  # include package
            &phd_htmtop'phd_htmtop(@tmp);                        # e.e'
            $tmp=$exeHtmtop;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print "$cmd\n"                                       if ($LscreenLoc); }
        print "--- ","-" x 50,"\n"                               if ($LscreenLoc);

	return(&errSbr("$exeHtmtop no output file"),0)           if (! -e $ftmp_top);
	print "--- top -> rdb \t \t '\\cp $ftmp_top $fileRdb'\n" if ($LscreenLoc);
	($Lok,$msg)=
	    &sysCpfile($ftmp_top,$fileRdb);
	return(&errSbrMsg("(htmtop) after copy",$msg),0)         if (! $Lok);
	$file{"tmp$sbrName"."$ftmp_top"}=$ftmp_top; 
        push(@kwdRm,"tmp$sbrName"."$ftmp_top"); }
    return(1,"ok $sbrName",1);
}				# end of runPhdHtmPost

