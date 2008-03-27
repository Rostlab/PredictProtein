#!/usr/pub/bin/perl4 -w
$[ =1 ;

push (@INC, "/home/rost/perl","/home/phd/etc/") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"move from /server/work/ to /server/prd/ (if something went wrong)\n";
	      print"    del resp. files in /mail\n";
	      print"in: list-of-files predict_x from, e.g., /work\n";
	      exit;}

$file_in=$ARGV[1];
$dirPred="/home/phd/server/prd/";
$dirMail="/home/phd/server/mail/";

$dirTmp="/trash/phd/tmp/";
				# create dir if missing
system("mkdir $dirTmp") if (! -d $dirTmp);

$fhin="FHIN";
&open_file("$fhin", "$file_in");
while (<$fhin>) {$_=~s/\n//g;
		 if (-e $_){
		     $work=$_;
				# security safe
		     print "--- system 'cp $work $dirTmp' (for security)\n";
		     system("cp $work $dirTmp");
				# extract
		     $tmp=$work; $tmp=~s/^.*\///g; $tmp=~s/predict_/pred_/;
		     $pred=$dirPred.$tmp;
		     $mail=$dirMail.$tmp."_query";
		     print "--- system 'mv $work $pred'\n";
		     system("mv $work $pred");
		     if (-e $mail){
			 print "--- system '\\rm $mail'\n";
			 system("\\rm $mail");}}
		 else {
		     print "--- missing '$work'\n";}}close($fhin);
exit;
