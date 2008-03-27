#!/usr/sbin/perl -w
##!/usr/bin/perl
#
#  splitting trembl
#
$[ =1 ;

push (@INC, "/home/rost/perl","/u/rost/perl/") ;
#require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

@des=("dirOut","dirTrembl","docTrembl","fileList","idList");

if ($#ARGV<1){print"goal:   split trembl\n";
	      print"usage:  'script file.dat'\n";
	      print"options: ";&myprt_array(",",@des);
	      print"        or: 'name=x' then assumed: \n";
	      print"            in=  'trembl/x.dat'\n";
	      print"            out= 'trembl/x_num'\n";
	      exit;}
				# defaults
$par{"dirOut"}=     "trembl/";
$par{"dirTrembl"}=  "trembl/";
$par{"docTrembl"}=  "trembl.dat";
$par{"fileList"}=   "SplitTrembl.list";
$par{"idList"}=     "SplitTremblId.list";
$par{"filesPerDir"}=50;
$name=              "";		# will be appended to split directories
				# ------------------------------
foreach $_(@ARGV){		# read command line
    if (/^name=/){$_=~s/^name=//g;$name=$_;
		  $par{"fileList"}=~s/Trembl/-$name/;
		  $par{"idList"}=~s/Trembl/-$name/;}
    foreach $des(@des){ if (/^$des=/){$_=~s/^$des=|\s//g;$par{"$des"}=$_;
				      last;}}}
				# if first file given: assume document
if (-e $ARGV[1]){
    $par{"docTrembl"}=$ARGV[1]; 
    $par{"dirTrembl"}="";}
				# process parameters asf.
foreach $des ("dirOut","dirTrembl"){
    $par{"$des"}=&complete_dir($par{"$des"});}
$fhin="FHIN";$fhout="FHOUT";$fhoutList="FHOUT_LIST";$fhoutIdList="FHOUT_ID_LIST";
$fileOutError="ERROR-$name.list";                   $fhoutError="FHOUT_ERROR";

				# output subdirectories
if (! -d $par{"dirOut"}){
    $dir=$par{"dirOut"};system("mkdir $dir"); print "--- system: 'mkdir $dir'\n";}
				# list of files generated!
$fileOut=$par{"fileList"};&open_file("$fhoutList", ">$fileOut");
				# id's of files generated!
$fileOutId=$par{"idList"};&open_file("$fhoutIdList", ">$fileOutId");
				# errors
&open_file("$fhoutError", ">$fileOutError");
				# read entire trembl
$fileIn=$par{"dirTrembl"}.$par{"docTrembl"};
&open_file("$fhin", "$fileIn");
$Lnew=0;$ct=$ctDir=$ctFile=0;$ctLine=0;
while (<$fhin>) {
    $line=$_;
    $_=~s/\n//g;
    if   (/^ID/){   if (($ctLine>0)&&($ctLine<2)){ close($fhout); # error: empty line!
						   system("\\rm $fileOut");}
		    $Lnew=1;	# get id
		    $id=$_;$id=~s/^ID   (\S+) .*/$1/g;
		    $fileOut="$id"; # open output file
		    $Lerror=0;
		    if ($id =~/\s+/){
			print $fhoutError "$fileOut\n";$Lerror=1;}
		    if (! $Lerror){
			++$ctFile;$ctLine=1;
			&open_file("$fhout", ">$fileOut");}}
    elsif(/^\/\//){ $Lnew=0;
		    if (! $Lerror){
			print $fhout "//\n";
			close($fhout);
			if ($ct>$par{"filesPerDir"}){$ct=0;}
			if ($ct==0){ ++$ctDir; 
				     if (length($name)>1){
					 $dirOut=$par{"dirOut"}."$name"."_"."$ctDir";}
				     else {$dirOut=$par{"dirOut"}."$ctDir";}
				     if (-d $dirOut){
					 print "-*- WARNING: directory exists '$dirOut'\n";}
				     else {
					 system("mkdir $dirOut"); }}
			++$ct;++$ctLine;
			if (length($name)>1){
			    $file=$par{"dirOut"}."$name"."_"."$ctDir"."/"."$fileOut";}
			else {$file=$par{"dirOut"}."$ctDir"."/"."$fileOut";}
			print $fhoutList "$file\n";
			$id=$file;$id=~s/^.*\///g;
			print $fhoutIdList "$id\n";
			system("mv $fileOut $file");
			print "--- system: 'mv $fileOut $file' (nr. $ctFile, ct=$ct)\n";}}
    if ($Lnew){
	if (! $Lerror){
	    print $fhout $line;}}
    last if ($ctFile>4000);
}close($fhin);close($fhoutList);close($fhoutIdList);
exit;
