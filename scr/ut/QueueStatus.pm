#!/usr/bin/perl
package wwwPPStatusLog;
#use strict;
use CGI qw(:standard);
use Time::Local;

(my $SEC,my $MIN, my $HOUR, my $DAY, my $MONTH, my $YEAR) = (localtime)[0,1,2,3,4,5];
my $res = "";
my $resJobStatus ="";
my $errFlag="";
my $jobFoundFlag=0;
my %hashUserJobs;
my $sgeQueueID;
my @names = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

my $rCount = 0;			
my $qCount = 0;
my $eCount = 0;
my $status = "";
my $qstatExe = "/usr/local/sge/bin/glinux/qstat";
$ENV{'SGE_ROOT'} = "/usr/local/sge";
my $User;			
if ($ENV{USER} eq ""){
    $User = "ppuser";
}else {$User=$ENV{USER}};	

sub runQuery{
    my ( $self, $userEmail ) =@_; 
    # init
    my $cmd="";
    my $cmmnd="";
    my $currTime = localtime;
    my %hits={ 
	'month' => '',
	'day' =>'',
	'year' => ''
	};
    
    # Get Server Statistics 
    $cmmnd = "/bin/grep ".$names[$MONTH].":".$DAY.":".($YEAR+1900)." /home/ppuser/server/log/phd.log| /usr/bin/wc -l ";
    $hits{"day"} = `$cmmnd`;
    $cmmnd = "/bin/grep ".$names[$MONTH].":[0-9][0-9]*:".($YEAR+1900)." /home/ppuser/server/log/phd.log| /usr/bin/wc -l ";
    $hits{"month"} = `$cmmnd`;
    $cmmnd = "/bin/grep :".(1900+$YEAR).": /home/ppuser/server/log/phd.log | /usr/bin/wc -l";
    $hits{"year"} = `$cmmnd`;

    # take out trailing carriage returns
    chomp($hits{"year"});
    chomp($hits{"month"});
    chomp($hits{"day"});

    # Find users jobs, look into scan.log to see what was submitted 
    if (defined $userEmail && $userEmail){
	$cmmnd = "/bin/grep 'submitted ".$userEmail."' /home/$User/server/log/scan.log";
	my @arrRespJobs = `$cmmnd`;

	foreach my $tmp(@arrRespJobs){
	    my $tmpJobIndex =  index($tmp, " ",9);
	    my $jobId = substr($tmp,9,($tmpJobIndex-8));
	    $jobId=~ tr/ //d;
	    my $emailIndex  = rindex($tmp," ", (length $tmp));
	    my $emailId  = substr ($tmp, $emailIndex+1,((length $tmp)-$emailIndex));
	    chomp $emailId;
	    $hashUserJobs{$jobId} = $emailId; 	    
	}
    }

    
    # build an array with current queue status
    $cmd="$qstatExe -u $User";	
    my @arrRespQueue = `$cmd`;
    my $msgProcess = "";
    my $posProcess = -1;
 
    foreach my $tmp(@arrRespQueue){ 
	if ($tmp =~ /predict_/){
	    # Get SGE job Ids to compare with user jobs
	    $sgeQueueID = substr ($tmp,1,index($tmp, " ",3));
	    $sgeQueueID =~ tr/ //d;	 
	    if ($tmp =~ ' Eqw ' ){	# 
		$eCount++;
		$status = "e";	
	    }elsif ($tmp =~ ' r ' ){
		$rCount++;	    $status = "r";
	    }elsif ($tmp =~ ' qw ' || $tmp =~ ' t '){
		$qCount++;				    $status = "q";
	    }

	    # if there's a job matching the user's email -> display its status
	    if (exists $hashUserJobs{$sgeQueueID}){
		my($statName, $pos)= &getStatusName;
		$resJobStatus .= "\t---\tFound job number: $sgeQueueID\tStatus: <b>$statName</b>\tPostition:<b> $pos</b>\n";
	    }
	}
    } # foreach my $tmp(@arrRespQueue){
    
    # Calculate avrg wait time
   $[=1;		
    my $month = substr($currTime, 5, 3);
    my $tot = 0;
    use Time::localtime;
    my $tm = localtime;
    my ($year,$mday, $hour) = ($tm->year, $tm->mday, $tm->hour);
    if ($hour<10){
	$hour = "0$hour";			
    }

    # get load over last ~3 hours
    for (my  $x=($tm->hour);$x>(($tm->hour)-3);$x--){
        my $tempHour;
        if ($x<10){$tempHour = "0$x";}else{$tempHour = $x;}

	$cmd = "cat /home/ppuser/server/log/phd.log | grep \'".$month.":".$tm->mday.":".(($tm->year)+1900).":".$tempHour."\'|wc -l";
	$tot +=  `$cmd`;
    }
    my $avgWaitHour = $tot/3;
    my $avgWait;		
    if ($avgWaitHour > 0 ){
	$avgWait = $qCount/$avgWaitHour;
    }else{
	$avgWait = 0;
    }

    $avgWait = $avgWait*60;

    $avgWait = sprintf("%.2f",$avgWait) if ($avgWait>0);


    # Format and display results
$res .= <<EOL;
\t------------------------------------------------------------------------------------
    \t---\tPredict Protein Work Load as of $currTime EST (GMT -05:00)
\t---
\t---
\t---\tProcesses running               =>      $rCount
\t---
\t---\tProcesses waiting in the queue  =>      $qCount
\t---
\t---\tProcesses waiting in error mode =>      $eCount  
\t---				
\t---\tCurrent wait time is approximately $avgWait minutes
\t---\t  - > (wait time is defined as the time a job is 
\t---\t       waiting in the queue before being processed)				
\t---\t      
\t---\t      
\t---\tServer Stats to Date
\t---\t--------------------
\t---\tRequests this year:\t\t\t$hits{"year"}
\t---\tRequests in $names[$MONTH]:   \t\t\t$hits{"month"}
\t---\tRequests today:    \t\t\t$hits{"day"}
\t---\t
EOL
if (!$resJobStatus && defined $userEmail){
    $resJobStatus="\t---\tNo Job found\n";
} 
$res.=$resJobStatus;
$res.=$errFlag if ($errFlag);  
$res.="\t--------------------------------------------------------------------------------------\n";

return $res; 	
}

sub getStatusName{
	if ( $status eq "q" ){
	    return ("Queued", $qCount);
	} elsif ( $status eq "r" ){
	    return ("Running", $rCount);
	}elsif ( $status eq "e" ){
	    $errFlag="Your job is in error mode. Cobtact the PP admin at \n\t---\tpp_admin\@predictprotein.org\n";
	    return ("Error", $eCount);
	}
}


sub getTempPred{
    my ( $self, $userJobId ) =@_;
    # init
    my $cmd="";
    my $cmmnd="";
    my $currTime = localtime;
    my $res="";
    my $workDir  = "/home/ppuser/server/work/";
    my $fHandleIn = 'FHIN';
    my $filePred;
    my $qID;

    $filePred = $workDir.$userJobId;

    if ( -e $filePred ){
	$cmd = "ls $workDir$userJobId.map.*"; 
	@arrRes = `$cmd`;
	if (scalar @arrRes > 1 ){
	    return $res;
	}else{
	    $qID =$arrRes[0];
	    $qID =~ s/$workDir$userJobId.map.//g;
	    $qID =~ s/\n//g;
	    $cmd = "$qstatExe -u $User |grep $qID";

	    my $respQueue = `$cmd`;
	    if ($respQueue =~ ' Eqw ' ){	
		$status = "in error mode";	
	    }elsif ($respQueue =~ ' r ' || $respQueue =~ ' dr '){
		$status = "running";
	    }elsif ($respQueue =~ ' qw ' || $respQueue =~ ' t '){
		$status = "queued";
	    }
	}
	$res .= "Ticket ID for this job is $qID\nThis job is currently <b>$status</b>\n";
	return $res;
    }			
}

sub sendPredFile{
    ($self, $fileName,$fileSize,$fileCntnt)=@_;	
#    return ("stopped");
    $dirTarget = "/home/ppuser/server/xch/tmp/";
    $dirPred = "/home/ppuser/server/xch/prd/";
    $fhOut = "FHOUT";
    $fhIn = "FHIN";
    $fileTarget = $dirTarget.$fileName;
    open ($fhOut, ">$fileTarget") || 
	return ("Could not open file $fileTarget.\nsysMsg:$!");
    print $fhOut $fileCntnt;
    close $fhOut;
    $fileSizeLoc = -s $fileTarget;
    return ("File size mismatch. Remotefilesize=$fileSize Localfilesize=$fileSizeLoc")
	if ($fileSizeLoc != $fileSize);
    $filePred = $dirPred.$fileName;
    $command = "mv $fileTarget $filePred";
    system ($command);
    return ("File Recieved");
    
}			       

1;

