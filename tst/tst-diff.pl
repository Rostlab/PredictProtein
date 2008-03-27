#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl4 -w
#
# makes a 'diff' between new and old .pred files (ignoring names asf)
#
$[ =1 ;

				# ------------------------------
				# defaults
				# get ARCH
$ARCH= $ARCH || $ENV{'ARCH'} || 'unk';
if ($ARCH eq "unk") {
    $scr="/home/phd/server/scr/ut/pvmgetarch.sh"; # HARD_CODED
    if (-e $scr && -x $scr){ $ARCH=`$scr`; 
			     $ARCH=~s/\s|\n//g; } }
$ARCH= $ARCH || 'SGI64';

$dirSave= "/home/phd/server/tst/$ARCH/";	# HARD_CODED
$fileOut= "Diff.fin";
$Ldebug=  0;
				# ------------------------------
				# help
if ($#ARGV<1){print "goal:   makes a 'diff' between new and old .pred files (ignoring names asf)\n";
	      print "usage:  'script *.pred'\n";
	      print "option: dir=$dirSave (default for directory of reference results)\n";
	      print "        fileOut=$fileOut (default)\n";
	      print "        debug\n";
#	      print "        \n";
	      exit;}
				# ------------------------------
				# settings
$fileTmp= "DiffTmp-".$$.".tmp";
$fileTmp2="DiffTmp2-".$$.".tmp";

$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=0;			# get command line
foreach $arg (@ARGV){
    if    ($arg=~/^dir=(.*)/)    {$dirSave=$arg;}
    elsif ($arg=~/^fileOut=(.*)/){$fileOut=$arg;}
    elsif ($arg=~/^debug/)       {$Ldebug=1;}
    else                         {$file=$arg;
				  if ( -e $file){
				      push(@fileIn,$arg);}
				  else {
				      print "*** argument '$arg' not understood ($scrName)\n";
				      exit;}}}

die ("missing dirSave=$dirSave") if (!-e $dirSave);

				# ------------------------------
foreach $file(@fileIn){		# get differences
    $tmp=$file; $tmp=~s/^.*\///g;
    $fileSave=$dirSave."$tmp";
    system("echo $file >> $fileTmp");
    print "--- diff $file $fileSave >> $fileTmp\n";
    system("diff $file $fileSave >> $fileTmp");}
				# ------------------------------
				# filter name and date
&open_file("$fhin", "$fileTmp"); 
&open_file("$fhout", ">$fileTmp2");
while (<$fhin>) {
    if    (/\.pred$/){
	print $fhout $_;}
    elsif (/\d+| 199[6789]|DATE|date/){ # ignore name/date
	print "x.x ignore name '$_'\n";}
    else {
	print $fhout $_;}}
				# ------------------------------
				# filter empty ones
&open_file("$fhin", "$fileTmp2"); 
&open_file("$fhout", ">$fileOut");
$ct=$#store=0;
while (<$fhin>) {
    $_=~s/\n//g;
    if (/^e_.*\.pred$/){	# file name, start to buffer
	print $fhout "$_\n";
	if ($ct>0){
	    foreach $it(1..$#store){
		&filter3();}}
	$#store=$ct=0;
	push(@store,$_);}
    else {
	if ((! /^---/)&&(!/\dc\d/)){
#	    print "x.x ok ct? '$_'\n";
	    ++$ct;}
	push(@store,$_);}}

if ($ct>0){
    foreach $it(1..$#store){
	&filter3();}}

close($fhin);close($fhout);
if (! $Ldebug){print "--- remove $fileTmp $fileTmp2\n";
	       unlink($fileTmp);unlink($fileTmp2);}
print "--- $fileOut=$fileOut\n";
exit;

#==========================================================================================
sub filter3 {
    $[ =1 ;
#--------------------------------------------------------------------------------
    if ($it<($#store-2)){
	if (($store[$it] =~/^---/)&&($store[$it+2] =~/^---/)){
	    return;}
	elsif (($store[$it] !~/^[<>] /)&&($store[$it+2] !~/^[<>] /)){
	    return;}}
    print $fhout "$store[$it]\n";
}				# end of subx


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
