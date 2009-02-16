#!/usr/bin/perl -w

use lib '/nfs/data5/users/ppuser/server/scr/lib';
require _PP_DB;


use constant FAILED      =>   4;
use constant RUNNING     =>   3;
use constant COMPLETED   =>   2;
use constant PENDING     =>   1;
use constant NEW         =>   0;

#my $db;
my $db = &init_db();
while (){


    my $local_hashref_set = $db->getNextJob(NEW);
	
    if (!$local_hashref_set || !defined $local_hashref_set){
	;
#	print ("No batch jobs to process.\n") if ($dbg);
    }else{
	&submit($local_hashref_set);
    }

    sleep (5);
}
close_db($db);


sub submit{
    my $hashref_batch_set = shift;
    for my $hashref_batch(@$hashref_batch_set){
	if ( ($hashref_batch->{'NAME'}) &&  ($hashref_batch->{'INPUT'})   ){
	    $prd_file = "$ENV{HOME}/server/xch/prd/".$hashref_batch->{'NAME'};
	    system ("touch $prd_file.lock");
	    open (PRDFILE,">$prd_file")||warn "can't open $prd_file\n$!";
	    print PRDFILE "$hashref_batch->{'INPUT'}";
	    close PRDFILE;
	    unlink ("$prd_file.lock");
	    $db->setJobStartTime($hashref_batch->{'ID'}); 
	    $db->setJobState($hashref_batch->{'ID'}, PENDING); 
	}else{
	   $db->setJobState($hashref_batch->{'ID'}, FAILED); 
	}
    }
}



sub init_db{
#    return _PP_DB->new('bonsai.bioc.columbia.edu','PREDICTPROTEIN','phd','Pr3d8ct');
    return _PP_DB->new('cherry.bioc.columbia.edu','PREDICTPROTEIN','phd','Pr3d8ct');
}

sub close_db{
    my $loc_db = shift;
    $loc_db->close;
}


__END__






