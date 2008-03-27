#!/usr/bin/perl
package PPTempProc;
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
#my $response = runQuery("",$ARGV[0]);
#print $response;
sub runQuery{
    my ( $self, $userJobId ) =@_; 
    # init
    my $User;
    my $cmd="";
    my $cmmnd="";
    my $currTime = localtime;
    my $res="";
    $res="Hello";
    return "hello";
    my $fHandleIn = 'FHIN';
    my $filePred = "/home/ppuser/server/work/".$userJobId.".pred_temp";
    open ($fHandleIn,$filePred)||warn "Could not open file $filePred. $!";
    my @tmpBuff = <$fHandleIn>;
    foreach my $tmp(@tmpBuff){
	$res .= $tmp;
    }
    $res = $userJobId;
    return $res; 	
}


1;

