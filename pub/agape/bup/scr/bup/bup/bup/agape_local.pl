#! /usr/bin/perl -w

#($jobId,$FastaIn,$agapeOut,$dbg)=@ARGV;
$|=1;

$m_address='dudek@cubic.bioc.columbia.edu';
$title    ="AGAPE_failed";

$configFile    ="/home/dudek/server/pub/agape/scr/agape_config_local.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile";

$oldumask=umask(000);

($Lok,$msg)=&prepareAndRun(@ARGV);
if(! $Lok){
    die "ERROR: $msg, stopped";
    open(FHOUTTMP,">agape_err_msg_$$");
    print FHOUTTMP $msg,"\n";
    close FHOUTTMP;
    system("Mail -s $title $m_address < agape_err_msg_$$");
    unlink "agape_err_msg_$$";
}
umask ($oldumask);    




#=============================================================================================
sub prepareAndRun{
    my $sbr="prepareAndRun";
    my ($jobID,$FastaIn,$agapeOutDir,$dbg)=@_;
    return(0,"ERROR $0: arguments not defined: jobID=$jobID FastaIn=$FastaIn agapeOutDir=agapeOutDir, stopped") 
	if(! defined $jobID || ! defined $FastaIn || ! defined $agapeOutDir);
    

    return(0,"ERROR: please specify full (or local) paths (no relative paths accepted), stopped")
	if($FastaIn =~/\.\// || $agapeOutDir =~/\.\/|^\.+$/);

    if(! defined $dbg){ $dbg=0; }

    require $par{'agape_pack'} == 1 || 
	return(0,"ERROR $0 main: failed to require agape packege file: $par{agape_pack}");
    if($dbg){ $LogFile  =$jobID."_agape.log"; }
    else{     $LogFile  =$main::par{'log_dir'}.$jobID."_agape.log"; 
	      $ErrFile  =$main::par{'log_dir'}.$jobID."_agape.err";
    }

    if(! $dbg){ open(STDERR,">".$ErrFile); 
		open(STDOUT,">".$LogFile); }

    $pathLoc=`pwd`;   #to do: replace it with perl;
    $pathLoc=~s/\s//g; 
    $pathLoc.="/" if($pathLoc !~ /\/$/);

    if($FastaIn !~ /^\//)             { $FastaIn=$pathLoc.$FastaIn; }
    if($agapeOutDir!~/\/$/)          { $agapeOutDir.="/"; }
    if($agapeOutDir !~ /^\//)         { $agapeOutDir=$pathLoc.$agapeOutDir; }

    $QueryName         =$jobID;
        
    $finalMpearson     =$agapeOutDir.$QueryName.".agape-long";
    $finalShort        =$agapeOutDir.$QueryName.".agape-short";
    $finalAL           =$agapeOutDir.$QueryName.".agape-AL";
    $finalMpdb         =$agapeOutDir.$QueryName.".agape-TS";

    if($dbg){
	print "finalMpearson: $finalMpearson\n";
	print "finalShort:    $finalShort\n";
	print "finalAL:       $finalAL\n";
	print "finalMpdb:     $finalMpdb\n";
    }

    if($dbg){ print "work_dir: $par{work_dir}\n"; }
    $par{'work_dir'}.="/" if($par{'work_dir'} !~ /\/$/);
    $work_dir_loc=$par{'work_dir'}.$QueryName."-".$$."/";
    if($dbg){ print "work_dir_loc: $work_dir_loc\n"; }
    mkdir ($work_dir_loc, 0777) ==1 || return(0,"ERROR: mkdir $work_dir_loc failed, stopped"); 
    #system("\\mkdir $work_dir_loc")==0 ||
#	return(0,"ERROR $sbr: failed to mkdir=$work_dir_loc, stopped");

    chdir ($work_dir_loc) || 
	return(0,"ERROR $sbr: failed to chdir to work_dir_loc=$work_dir_loc, stopped");


    ($Lok,$msg)=&agape::run_agape($configFile,$FastaIn,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$jobID,$dbg);
    if(! $Lok){
	print "$jobID  $FastaIn\n";
	print "$msg\n"; 
	die "stopped";
	print "will try again\n";
	chdir $par{'work_dir'} ||
	    return(0,"ERROR: failed to chdir into $par{work_dir}, stopped");

	#system("\\rm -rf $work_dir_loc")==0 ||
	#    return(0,"ERROR: failed to remove directory $work_dir_loc, stopped");
	($Lok,$msg)=&clean_dir($work_dir_loc);
	return(0,"ERROR: failed to remove directory $work_dir_loc")
	    if(! $Lok);
	sleep 300;
	
	mkdir ($work_dir_loc, 0777) ==1 || return(0,"ERROR: mkdir $work_dir_loc failed, stopped");
	
	chdir ($work_dir_loc) || 
	    return(0,"ERROR $sbr: failed to chdir to work_dir_loc=$work_dir_loc, stopped");

	($Lok,$msg)=&agape::run_agape($configFile,$FastaIn,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$dbg);
	if(! $Lok){
	    return(0,"ERROR: agape failed for the 2-nd time on $jobID $FastaIn:\n $msg");
	}else{ 
	    chdir $par{'work_dir'} ||
		return(0,"ERROR: failed to chdir into $par{work_dir}, stopped");
	    #system("\\rm -rf $work_dir_loc")==0 ||
		#return(0,"ERROR: failed to remove directory $work_dir_loc, stopped");
	    if(! $dbg){
		($Lok,$msg)=&clean_dir($work_dir_loc);
		return(0,"ERROR: failed to remove directory $work_dir_loc")
		    if(! $Lok);
	    }
	}
    }else{
	if(! $dbg){
	    ($Lok,$msg)=&clean_dir($work_dir_loc);
	    return(0,"ERROR: failed to remove directory $work_dir_loc")
		if(! $Lok);
	}
    }


    if(! $dbg && defined $ErrFile && -e $ErrFile){
	unlink $ErrFile;
    }
    system("gzip -f $LogFile");

    return(1,"ok");
}
#==========================================================================================
#==========================================================================================
sub clean_dir{
    my $sbr="clean_dir";
    my ($dir)=@_;
    return(0,"$sbr: dir to clean not defined")
	if(! defined $dir);
    my @l_files;
    my $file;

    $dir.="/" if($dir !~ /\/$/);
    opendir(FHDIRCLEAN,$dir) || 
	return(0,"$sbr: failed to open dir=$dir");
    @l_files=readdir FHDIRCLEAN;
    closedir FHDIRCLEAN;
    foreach $file (@l_files){
	next if($file eq "." || $file eq "..");
	$file=$dir.$file;
	unlink $file;
    }
    system("rmdir $dir")==0 || system("rm -rf $dir")==0 ||
	return(0,"$sbr: failed to remove dir=$dir");
    return (1,"ok");
}
#===================================================================================
