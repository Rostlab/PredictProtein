#!/usr/bin/perl
if (@ARGV<2){die "Usage: $0 file_name.hssp file_name.rdbProf\n"}
@e=@ARGV;
$g=30;
$sfilehssp=$e[0];
$sfilerdbProf=$e[1];
($sfile,$b)=split (/\./,$sfilehssp);
@a=split (/\//,$sfile);
$sfile=pop @a;
$sch=2;#half stretch
$crd=3;
#$nitr=;
#$PATH=`pwd`;
#chop $PATH;
if ($ENV{"PP_ROT"}){
    $PATH=$ENV{"PP_ROT"}."/server/pub/disis";
}else{
    $PATH="/nfs/data5/users/ppuser/server/pub/disis";
}
######################
print "perl $PATH/get_raw_svm_pred.pl $PATH $sfile $PATH $PATH/30163.model $sfilehssp $sfilerdbProf > $PATH/SVM-$sfile.tmp\n";
system "perl $PATH/get_raw_svm_pred.pl $PATH $sfile $PATH $PATH/30163.model $sfilehssp $sfilerdbProf > $PATH/SVM-$sfile.tmp";
foreach $l (`cat $PATH/SVM-$sfile.tmp`){
    if ($l=~/^seq/){($b,$seq)=split (/=/,$l)}
}
#system "rm SVM-$sfile.tmp";
#print "perl get_prediction.pl $PATH/$sfile.svm-raw.tmp $PATH/sfile.processed-server $g $sch $crd $seq\n";
system "perl $PATH/get_prediction.pl $PATH/$sfile.svm-raw.tmp $PATH/$sfile.processed-server $g $sch $crd $seq";
system "rm $PATH/*.tmp";
system "rm $PATH/*.processed-server";
