#!/usr/bin/perl
use lib '/nfs/data5/users/ppuser/server/scr/lib';
require _PP_DB;
$tmpDB = _PP_DB->new('bonsai.bioc.columbia.edu','PREDICTPROTEIN','yachdav','Y4chd4v');
$fileStrore = "/nfs/data5/users/ppuser/server/scr/tst/t5/";
$fhfileStore = "FHFILESTORE";
$Lok=       open($fhfileStore,$fileStore);
#return(0,"*** ERROR $sbr: '$fileStore not opened\n") if (! $Lok);
undef $/;			# 'slurp' mode
$tmpContents = <$fhfileStore>;
close $fhfileStore;
$/="\n";			# back to regular mode
$tmpDB->setResults($randomString, $tmpContents, $file{"in"});

$tmpDB->close;
## GY - end of new block 
