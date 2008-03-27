#!/usr/sbin/perl -w
#
# merges z-score (from strip) into  hssp header
#
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

@des=  ("fileHssp","fileStrip","fileOut","naliWrt");
				# ------------------------------
				# help
if ($#ARGV<1){print"goal:   merges z-score (from strip) into hssp header\n";
	      print"usage:  'script file.hssp_topits (or list)'\n";
	      print"note1:  you can give the list in a file or by *.hssp\n";
	      print"note2:  strip by default: file with .hssp -> .strip\n";
	      print"option: \n";
	      &myprt_array(",",@des);
	      exit;}
				# ------------------------------
				# defaults
$par{"naliWrt"}=        10;
$par{"fileStrip"}=      "unk";
$par{"fileOut"}=        "Out-merge.rdb";

@desWrt=  ("z","ide","wsim","lali","ngap","lgap","len2","len1","id2","id1");
foreach $des("z"){
    $form{"$des"}="4.1f";}
foreach $des("ide","wsim","lali","ngap","lgap","len2","len1"){
    $form{"$des"}="4d";}
foreach $des("id1","id2","id"){
    $form{"$des"}="-8s";}

$fhout="FHOUT";$fhin="FHIN";
$Lscreen=1;
				# ------------------------------
				# read input
$fileHssp=$par{"fileHssp"}=$ARGV[1];
@fileHssp=			# get file names
    &get_in_database_files("HSSP",@ARGV);
				# get key-word options
foreach $_(@ARGV){$arg=$_;if (-e $arg){next;}
		  foreach $des (@des){
		      if ($arg=~/^$des=/){$arg=~s/^$des=|\s//g;$par{"$des"}=$arg;
					  last;}}}
				# ------------------------------------------------------------
				# loop over files
$ctFile=0;
foreach $fileHssp(@fileHssp){
    $id1=$fileHssp;$id1=~s/^.*\///g;
    $id1=~s/\.hssp//g;$id1=~s/_?topits//g;
    if (length($id1)>4){$tmp=$id1;$id1=substr($id1,1,4)."_".substr($id1,5,1);}
    if ($par{"fileStrip"} eq "unk"){
	$fileStrip=$fileHssp;$fileStrip=~s/\.hssp/\.strip/;}
    else{$fileStrip=$par{"fileStrip"};}
    ++$ctFile;
    if ($Lscreen){print"--- \t hssp=$fileHssp, strip=$fileStrip, id1=$id1,\n";}
				# --------------------------------------------------
				# note: $ali{"ct","x"} ct = number of hit
				# x = "z","id"
    %strip=			# read strip file (for security first 20)
	&rdStripHack($fileStrip,$par{"naliWrt"});
				# transpose
    foreach $it (1..$par{"naliWrt"}){
	$ali{"$ctFile","$it","z"}=$strip{"$it","z"};
	$ali{"$ctFile","$it","zId"}=$strip{"$it","id"};}
				# --------------------------------------------------
				# note: $rd{"ct","x"} ct = number of hit
				# x = "IDE","WSIM","IFIR","ILAS","JFIR","JLAS",
				#     "LALI","NGAP","LGAP","LEN2","ACCNUM",
                                #     "ID","STRID","NAME"
				# and   $rd{"y"}
				# y = LEN1
    @tmp=(1..$par{"naliWrt"});
    %rd=
	&hssp_rd_header($fileHssp,$par{"naliWrt"});
				# transpose
    foreach $it (1..$par{"naliWrt"}){
	foreach $des(@desWrt){
	    if    ($des eq "id1"){
		$id1=~s/\s//g;
		$ali{"$ctFile","$it","$des"}=$id1;}
	    elsif ($des eq "len1"){
		$ali{"$ctFile","$it","$des"}=$rd{"LEN1"};}
	    elsif ($des eq "z"){ # already done
		next; }
	    else {
		if ($des eq "id2"){$desTmp="ID";}
		else {$desTmp=$des; $desTmp=~tr/[a-z]/[A-Z]/;}
		if (defined $rd{"$it","$desTmp"}){
		    if ($des eq "id"){ $rd{"$it","$desTmp"}=~s/\s//g;} # purge blanks
		    if (($des eq "ide")||($des eq "wsim")){
			$ali{"$ctFile","$it","$des"}=int(100*$rd{"$it","$desTmp"});}
		    else {
			$ali{"$ctFile","$it","$des"}=$rd{"$it","$desTmp"};}
		    if ($des eq "id"){
			if ($rd{"$it","$desTmp"} ne $strip{"$it","id"}){
			    print 
				"*** ERROR id's differ for '$fileHssp', it=$it, hssp=",
				$rd{"$it","$desTmp"},", strip=",$strip{"$it","id"},",\n";}}
		}
		else {
		    print "x.x missing rd for it=$it, des=$des, desTmp=$desTmp,\n";}
	    }
	}}
}				# end of loop over files
				# ------------------------------------------------------------

$nFiles=$ctFile;

&wrtMergedHeader("STDOUT",",",$nFiles,$par{"naliWrt"},@desWrt);
$fileOut=$par{"fileOut"};
print "x.x file=$fileOut,\n";
&open_file("$fhout", ">$fileOut");
&wrtMergedHeader($fhout,"\t",$nFiles,$par{"naliWrt"},@desWrt);
close($fhout);

print "x.x output in '$fileOut'\n";
exit;

#==========================================================================================
sub rdStripHack {
    local ($fileLoc,$numExtr) = @_ ;
    local ($fhinLoc,$ct,$z,$id,%ali);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdStripHack                reads zscore and id from strip file
#       in:                     file.strip_topits number_of_ids_to_extract
#       out:                    $ali{"ct","x"} x = 'id' and 'z'
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_RDSTRIP";
    &open_file("$fhinLoc","$fileLoc");
    while(<$fhinLoc>){
	last if (/^ IAL/);}
    $ct=0;
    while(<$fhinLoc>){
	++$ct;
	last if ($ct>$numExtr);
	$z= substr($_,30,8);$z=~s/\s//g;
	$id=substr($_,71,8);$id=~s/\s//g;
	$ali{"$ct","id"}=$id;
	$ali{"$ct","z"}=$z;
    }close($fhinLoc);
    return(%ali);
}				# end of rdStripHack

#==========================================================================================
sub wrtMergedHeader {
    local ($fhloc,$sep,$nFilesLoc,$naliWrt,@desIn) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtCasp2                       
#--------------------------------------------------------------------------------

				# ------------------------------
				# header
    print $fhloc "# Perl-RDB\n# \n";
    printf $fhloc "%5s$sep%5s","nProt","nHit";
    foreach $des(@desIn){$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
			 printf $fhloc "$sep$tmp",$des;}print $fhloc "\n";
				# format
    printf $fhloc "%5s$sep%5s","5N","5N";
    foreach $des(@desIn){$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
			 $tmpX=&form_perl2rdb($form{"$des"});
			 printf $fhloc "$sep$tmp",$tmpX;}print $fhloc "\n";
				# ------------------------------
				# body
    
    foreach $itFiles (1..$nFilesLoc){
	foreach $it (1..$naliWrt){
	    printf $fhloc "%5d$sep%5d",$itFiles,$it;
	    foreach $des(@desIn) {
		if (! defined $ali{"$itFiles","$it","$des"}){
		    $tmpX="xx";
		    print "*** not defined: itFiles=$itFiles, it=$it, des=$des,\n";}
		else {$tmpX=$ali{"$itFiles","$it","$des"};}
		$tmp="%".$form{"$des"};
		printf $fhloc "$sep$tmp",$tmpX;}print $fhloc "\n";
	}}
}				# end of wrtCasp2

#==========================================================================================
sub subx {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    subx                       
#         c
#       in:
#         A                     A
#       out:
#         A                     A
#--------------------------------------------------------------------------------

}				# end of subx


