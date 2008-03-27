#! /usr/bin/perl -w

#($jobId,$FastaIn,$agapeOut,$dbg)=@ARGV;
$|=1; 

$configFile    ="/home/dudek/server/pub/agape/scr/agape_config_local.pm";
require $configFile == 1 || 
    return(0,"ERROR $0 main: failed to require config file: $configFile");

$oldumask=umask(000);

($Lok,$msg)=&prepareAndRun(@ARGV);
if(! $Lok){
    print "ERROR: $msg\n";
}
umask ($oldumask);    


print "!!!!!! make sure that db_profiles have sssa in their name no matter what user names it !!!!!!!!!!!!!!!!!\n\n";

#=============================================================================================
sub prepareAndRun{
    my $sbr="prepareAndRun";
    my ($FastaIn,@l_args)=@_;
    my ($jobID,$agapeOutDir,$dbg,$db_dssp_list,$db_profile_list);

    return(0,"ERROR $0: arguments not defined: FastaIn=$FastaIn, stopped") 
	if(! defined $FastaIn);

    return(0,"ERROR: please specify full (or local) path (no relative paths accepted) for files $FastaIn, stopped")
	if($FastaIn =~/^\./);

    foreach $it (@l_args){
	if($it=~/db_dssp=(\S+)/i)       { $db_dssp_list=$1; }
	elsif($it=~/db_sssa=(\S+)/i)    { $db_sssa_list=$1; }
	elsif($it=~/dbg|debug/i)        { $dbg=1; }
	else{ return(0,"ERROR: argument \"$it\" not recognized, stopped"); }
    }

    if(! defined $db_dssp_list || ! defined $db_sssa_list){
	return(0,"ERROR: please specify all arguments, stopped");
    }
    
    return(0,"ERROR: please specify full (or local) path (no relative paths accepted) for files $db_dssp_list and $db_sssa_list, stopped")
	if($db_dssp_list =~/^\./ || $db_sssa_list=~/^\./);


    $pathLoc=`pwd`;   #to do: replace it with perl;
    $pathLoc=~s/\s//g; 
    $pathLoc.="/" if($pathLoc !~ /\/$/);
    
    $agapeOutDir=$pathLoc;
    $jobID=$FastaIn; $jobID=~s/^.*\///; $jobID=~s/\..*//;


    if(! defined $dbg){ $dbg=0; }

    require $par{'agape_pack'} == 1 || 
	return(0,"ERROR $0 main: failed to require agape packege file: $par{agape_pack}");
    if($dbg){ $LogFile  =$jobID."_agape.log"; $ErrFile=$jobID."_agape.err";}
    else{     $LogFile  =$main::par{'log_dir'}.$jobID."_agape.log"; 
	      $ErrFile  =$main::par{'log_dir'}.$jobID."_agape.err";
    }

    if(! $dbg){ open(STDERR,">".$ErrFile); 
		open(STDOUT,">".$LogFile); }

    

    if($FastaIn !~ /^\//)             { $FastaIn=$pathLoc.$FastaIn; }
    if($db_dssp_list !~ /^\//)        { $db_dssp_list=$pathLoc.$db_dssp_list; }
    if($db_sssa_list !~ /^\//)        { $db_sssa_list=$pathLoc.$db_sssa_list; }
    

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


    $par{'work_dir'}=$pathLoc;
    $par{'work_dir'}.="/" if($par{'work_dir'} !~ /\/$/);
    $work_dir_loc=$par{'work_dir'}.$QueryName."-".$$."/";
    mkdir ($work_dir_loc, 0777) ==1 || return(0,"ERROR: mkdir $work_dir_loc failed, stopped"); 
    #system("\\mkdir $work_dir_loc")==0 ||
#	return(0,"ERROR $sbr: failed to mkdir=$work_dir_loc, stopped");

    chdir ($work_dir_loc) || 
	return(0,"ERROR $sbr: failed to chdir to work_dir_loc=$work_dir_loc, stopped");

    #make sure db files have a proper name
    $db_dssp_list_tmp="db_dssp.list_".$$;
    $db_sssa_list_tmp="db_sssa.list_".$$;
    system("cp $db_dssp_list $db_dssp_list_tmp")==0 ||
	return(0,"$0 $sbr ERROR failed to copy $db_dssp_list $db_dssp_list_tmp");
    system("cp $db_sssa_list $db_sssa_list_tmp")==0 ||
	return(0,"$0 $sbr ERROR failed to copy $db_sssa_list $db_sssa_list_tmp");
    

    $ErrFileLoc=$ErrFile; $LogFileLoc=$LogFile;
    $ErrFileLoc=~s/^.*\///; $LogFileLoc=~s/^.*\///;

    ($Lok,$msg)=&agape::run_agape($configFile,$FastaIn,$db_dssp_list_tmp,$db_sssa_list_tmp,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$jobID,$dbg);
    if(! $Lok){
	print "$jobID  $FastaIn\n";
	#print "$msg\n"; print "will try again\n";
	if($dbg){
	    system("cp $ErrFile $ErrFileLoc");
	    system("cp $LogFile $LogFileLoc");
	}
	#die "agape failed, will not try again !!!!!";
	chdir $par{'work_dir'} ||
	    return(0,"ERROR: failed to chdir into $par{work_dir}, stopped");

	#system("\\rm -rf $work_dir_loc")==0 ||
	#    return(0,"ERROR: failed to remove directory $work_dir_loc, stopped");
	#($Lok,$msg)=&clean_dir($work_dir_loc);
	#return(0,"ERROR: failed to remove directory $work_dir_loc")
	#    if(! $Lok);
	die "";
	#sleep 300;
	
	mkdir ($work_dir_loc, 0777) ==1 || return(0,"ERROR: mkdir $work_dir_loc failed, stopped");
	
	chdir ($work_dir_loc) || 
	    return(0,"ERROR $sbr: failed to chdir to work_dir_loc=$work_dir_loc, stopped");

	($Lok,$msg)=&agape::run_agape($configFile,$FastaIn,$db_dssp_list,$db_sssa_list,$finalMpearson,$finalShort,$finalAL,$finalMpdb,$dbg);
	if(! $Lok){
	    if($dbg){
		system("cp $ErrFile $ErrFileLoc");
		system("cp $LogFile $LogFileLoc");
	    }
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
