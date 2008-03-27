#! /usr/bin/perl -w

($fileIn,$fileDb,$fileHsspOut,$fileStripOut,$dirWork,$ZeroShift,$GO,$GE,$dbg)=@ARGV;

foreach $it ($fileIn,$fileDb,$fileHsspOut,$fileStripOut,$dirWork,$ZeroShift,$GO,$GE){
    die "argument not defined, stopped" if(! defined $it);
}
$dbg=0 if(! defined $dbg);
chdir $dirWork || die "failed to chdir to $dirWork, stopped";

$configFile        ="/home/$ENV{USER}/server/pub/agape/config/config.pm";
require $configFile == 1 || 
    die "ERROR $0 main: failed to require config file: $configFile\n";


die "fileDb=$fileDb not found, stopped"
    if(! -e $fileDb);

$dbSize=0;
open(FHINLOC,$fileDb) ||
    die "failed to open fileDb=$fileDb, stopped";
while(<FHINLOC>){
    next if(/^\s*$|^\#/);
    $dbSize++;
}
close FHINLOC;
die "ERROR: maxhom database $fileDb contains no sequences, stopped"
    if($dbSize < 1);

($Lok,$msg)=&run_maxhom($fileIn,$fileDb,$fileHsspOut,$fileStripOut,$ZeroShift,$GO,$GE,$par{'maxhom_binary'},$par{'maxhom_def'},$dbSize,$dbg);
die "ERROR $0: $msg, stopped" if(! $Lok);


#===========================================================================================
sub run_maxhom{
    my $sbr="run_maxhom";
    my ($QueryFile,$DBFile,$HsspFile,$StripFile,$ZeroShift,$GO,$GE,$maxhom_exe,$maxhom_default,$dbSize,$dbg)=@_;
    die "ERROR $0: arguments not defined, stopped"
	if(! defined $QueryFile || ! defined $DBFile ||
	   ! defined $HsspFile || ! defined $StripFile ||
	   ! defined $ZeroShift || ! defined $GO ||
	   ! defined $GE || ! defined $maxhom_exe || 
	   ! defined $maxhom_default);
    my ($maxhom_metric);
    my ($FileMaxhomErr,$FileMaxhomInfo,$FileMaxhomLog,$FileMaxhomParam);
    my ($correct,$error,$maxhom_cmd,$MaxhomParam);
    my (@file);
    
    die "ERROR $sbr: maxhom_default=$maxhom_default not found, stopped"
	if(! -e $maxhom_default);
    die "ERROR $sbr: maxhom_exe=$maxhom_exe not executable, stopped"
	if(! -x $maxhom_exe);

    $maxhom_metric   ="PROFILE";
	    
    $MaxhomParam.="";
    $MaxhomParam.="COMMAND NO\n";                  
    $MaxhomParam.="BATCH\n";          
    $MaxhomParam.="PID: ".$$."\n";              
    $MaxhomParam.="SEQ_1 ".$QueryFile."\n";        
    $MaxhomParam.="SEQ_2 ".$DBFile."\n";     
    #$MaxhomParam.="2_PROFILES MEMBER\n";
    #$MaxhomParam.="2_PROFILES NO\n";
    $MaxhomParam.="METRIC ".$maxhom_metric."\n";
    $MaxhomParam.="NORM_PROFILE   NO\n"; 
    $MaxhomParam.="MEAN_PROFILE   IGNORED\n"; 
    $MaxhomParam.="FACTOR_GAPS    IGNORED\n";  
    $MaxhomParam.="SMIN           IGNORE\n";          
    $MaxhomParam.="SMAX           IGNORE\n";          
    $MaxhomParam.="GAP_OPEN ".$GO."\n";      
    $MaxhomParam.="GAP_ELONG ".$GE."\n";      
    $MaxhomParam.="WEIGHT1 NO\n";         
    $MaxhomParam.="WEIGHT2 NO\n";         
    $MaxhomParam.="WAY3_ALIGN NO\n";      
    $MaxhomParam.="INDEL_1 YES\n";        
    $MaxhomParam.="INDEL_2 YES\n";        
    $MaxhomParam.="RELIABILITY NO\n";    
    $MaxhomParam.="FILTER_RANGE 10.0\n"; 
    $MaxhomParam.="NBEST 1\n";           
    $MaxhomParam.="MAXALIGN ".$dbSize."\n";       
    $MaxhomParam.="THRESHOLD ALL\n";      
    $MaxhomParam.="SORT ZSCORE\n";        
    $MaxhomParam.="HSSP ".$HsspFile."\n";           
    $MaxhomParam.="SAME_SEQ_SHOW YES\n";  
    $MaxhomParam.="SUPERPOS NO\n";        
    $MaxhomParam.="PDB_PATH /data/pdb/\n";
    $MaxhomParam.="PROFILE_OUT NO\n";     
    $MaxhomParam.="STRIP_OUT ".$StripFile."\n";    
    $MaxhomParam.="LONG_OUT  NO\n";     
    $MaxhomParam.="DOT_PLOT NO\n";      
    #$MaxhomParam.="ZEROSHIFT ".$ZeroShift."\n";
    $MaxhomParam.="HIGHZ 7.0\n";
    $MaxhomParam.="LOWZ -3.0\n";
    $MaxhomParam.="RUN\n";              
    
    $FileMaxhomInfo="MAXHOM_$$.out";
    $FileMaxhomErr="MAXHOM_$$.err"; 
    $FileMaxhomLog="MAXHOM.LOG_$$";
    $FileMaxhomParam="MAXHOM_$$.tmp";
    open(FHPAR,">".$FileMaxhomParam) ||
	die "ERROR: could not open FileMaxhomParam=$FileMaxhomParam for writing, stopped";
    print FHPAR $MaxhomParam;
    close FHPAR;

    open(SAVEOUT,">&STDOUT");
    open(SAVEERR,">&STDERR");
    
    open(STDOUT,">".$FileMaxhomInfo) ||
	die "ERROR failed to open $FileMaxhomInfo for writing, stopped";
    open(STDERR,">".$FileMaxhomErr) ||
	die "ERROR failed to open $FileMaxhomErr for writing, stopped";
    
    select STDERR; $|=1;
    select STDOUT; $|=1;
    $maxhom_cmd="$maxhom_exe -nopar -d=$maxhom_default < $FileMaxhomParam";
    $error=system($maxhom_cmd);
    
    close STDOUT;
    close STDERR;
    
    open(STDOUT,">&SAVEOUT");
    open(STDERR,">&SAVEERR");
    undef *SAVEOUT; undef *SAVEERR;
    
    #die "ERROR: failed executing maxhom_cmd=$maxhom_cmd, stopped"
#	if($error);
    
    open(FHINFO,$FileMaxhomInfo) ||
	die "ERROR failed to open FileMaxhomInfo=$FileMaxhomInfo for reading, stopped";
    @file=(<FHINFO>);
    close FHINFO;
    $correct=grep m/normal\s*termination/i, @file;
    die "ERROR maxhom failed, stopped" if($correct == 0);
    
    unlink ($FileMaxhomParam,$FileMaxhomInfo,$FileMaxhomErr,$FileMaxhomLog) 
	if(! $dbg);
#    system("gzip $HsspFile $StripFile");
    return(1,"ok");
}
#============================================================================
 
