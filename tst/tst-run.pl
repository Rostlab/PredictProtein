#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl -w
#
#
$[ =1 ;

if ($#ARGV<1){print "goal:   compare new with stored results (run phd_local)\n";
	      print "usage:  'script list-of-test-files' (or *)\n";
	      print "note:   \n";
	      print "        sequences in         /home/phd/server/tst/seq\n";
	      print "        'good' results in    /home/phd/server/tst/sav\n";
	      print "        scripts copied from  /home/phd/dev/\n";
	      exit;}

$fileIn=$ARGV[1];

#$fileOut=   "OutTst-".$$;
$fileError= "ErrTst-".$$;

				# get ARCH
$ARCH= $ARCH || $ENV{'ARCH'} || 'unk';
if ($ARCH eq "unk") {
    $scr="/home/phd/server/scr/ut/pvmgetarch.sh"; # HARD_CODED
    if (-e $scr && -x $scr){ $ARCH=`$scr`; 
			     $ARCH=~s/\s|\n//g; } }
$ARCH= $ARCH || 'SGI64';


$dirSave=   "/home/phd/server/tst/".$ARCH."/"; # HARD_CODED

$dirScr=    "/home/phd/dev/";	# HARD_CODED
$dirScr=    "/home/phd/server/scr/";	# HARD_CODED

$exePPloc=  $dirScr."manualPP.pl"; # HARD_CODED
$exePPenv=  $dirScr."envPP.pm";	# HARD_CODED
$ENV{"PPENV"}=$exePPenv;	# set environment

$exeTstDiff="tst-diff.pl";

$fhin="FHIN";$fhoutError="FHOUT_ERROR";


die("not existing dirSave=$dirSave") if (! -d $dirSave);
die("not existing dirScr =$dirScr")  if (! -d $dirScr);
				# ------------------------------
				# get list of files
$#file=$#fileLoc=$#filePred=0;
if ($#ARGV>1){
    foreach $arg (@ARGV){
	if (-e $arg){push(@file,$arg);}}}
else {
    if ($fileIn=~/^(.*\/t\-|t\-)/) {	# HARD_CODED (name begins with t-*)
	push(@file,$ARGV[1]); }
    else {			# expect list of files
	&open_file("$fhin", "$fileIn");
	while (<$fhin>) {$_=~s/\n//g;
			 if (-e $_){push(@file,$_);}
			 else {print "*** missing file  to test=$_\n";}}close($fhin);}}
				# ------------------------------
				# copy files
foreach $file (@file){
    $fileLoc=$file;$fileLoc=~s/^.*\///g;
    print "--- system \t 'cp $file $fileLoc'\n";
    system("\\cp $file $fileLoc");
    push(@fileLoc,$fileLoc);}
				# ------------------------------
				# run phd_local
&open_file("$fhoutError", ">$fileError");
foreach $file (@fileLoc){
    $filePred=$file.".pred";
    if (-e $filePred){		# remove results files before going on
	print "--- system \t 'rm $filePred'\n";
	system("\\rm $filePred");}
    print "--- system \t '$exePPloc $file pp'\n";
    system("$exePPloc $file rost\@embl-heidelberg.de");
    if (-e $filePred){
	push(@filePred,$filePred);}
    else {
	print $fhoutError "not: $filePred\n";}}
				# ------------------------------
				# diff on files
print "--- system \t '$exeTstDiff *.pred'\n";
system("$exeTstDiff *.pred");
				# ------------------------------
				# rm scripts
exit;				# no clean up as is /home/phd/tmp!!!

#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file



#==============================================================================
# library collected (end)
#==============================================================================
