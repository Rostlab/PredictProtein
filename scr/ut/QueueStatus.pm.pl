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
		   
print  getTempPred("","tx9");
sub runQuery{
    my ( $self, $userEmail ) =@_; 
    # init
    my $User;
    my $cmd="";
    my $cmmnd="";
    my $currTime = localtime;

    if ($ENV{USER} eq ""){
	$User = "ppuser";
    }else {$User=$ENV{USER}};
    $ENV{'SGE_ROOT'} = "/usr/local/sge";
    my $qstatExe = "/usr/local/sge/bin/glinux/qstat";

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
	# Get SGE job Ids to compare with user jobs
	$sgeQueueID = substr ($tmp,2,index($tmp, " ",3));
	$sgeQueueID =~ tr/ //d;
	if ($tmp =~ ' Eqw ' ){	# 
	    $eCount++;
	    $status = "e";	
	}elsif ($tmp =~ ' r ' || $tmp =~ ' dr '){
	    $rCount++;	    $status = "r";
	}elsif ($tmp =~ ' qw ' || $tmp =~ ' t '){
	    $qCount++;				    $status = "q";
	}

	# if there's a job matching the user's email -> display its status
	if (exists $hashUserJobs{$sgeQueueID}){
	    my($statName, $pos)= &getStatusName;
	    $resJobStatus .= "\t---\tFound job number: $sgeQueueID\tStatus: <b>$statName</b>\tPostition:<b> $pos</b>\n";
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
\t---\tRequests this year:\t$hits{"year"}
\t---\tRequests in $names[$MONTH]:\t$hits{"month"}
\t---\tRequests today:    \t$hits{"day"}
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
    print $userJobId,"\n";
    # init
    my $User;
    my $cmd="";
    my $cmmnd="";
    my $currTime = localtime;
    my $res="";

    my $fHandleIn = "FHIN";
    my $filePred = "/home/ppuser/server/work/".$userJobId.".pred_temp";
    
    open ($fHandleIn,$filePred)||warn "Could not open file $filePred. $!";
    my @tmpBuff = <$fHandleIn>;
    foreach my $tmp(@tmpBuff){
        $res .= $tmp;
    }

    return $res;





}





1;


#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
