#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="lists all perl files in home directory (may also do grep and changes)";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'extSearch',              ".pl,.pm", # extensions of files to be searched
      'fileType',               "T",       # file type to search (-B for binaries)
#      'fileType',               "B",       # file type to search (-B for binaries)
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "     \t ignoring old/ bup/ pub/bup ..\n";
    print  "use: \t '$scrName ls|grep=xyz|dir=DIR'\n";
    print  "note:\t currently /home/rost/data ignored when using the default mode 'ls'\n";
    print  "opt: \t \n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","noScreen", "no value","";
    printf "     \t %-15s  %-20s %-s\n","grep",     "xyz",     "will list all with this expression";
    printf "     \t %-15s  %-20s %-s\n"," ",        "",        "separate by '\\n': 'regexp1\\nregexp2'";
    printf "     \t %-15s  %-20s %-s\n","dir",      "x",       "restrict search to directory x";
    printf "     \t %-15s  %-20s %-s\n","type",     "T|B|x|l", "file type, now: 'T|B|x|l'";
    printf "     \t %-15s  %-20s %-s\n","count",    "no value","does a line count on all found";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}=~/^[\d\-]+$/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}=~/^[0-9\.\-]+$/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
$fhout="FHOUT";
				# ------------------------------
$#fileIn=$#chainIn=0;		# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^ls$/)                  { print "--- note 'ls' is default, do NOT need to type it!\n";}
    elsif ($arg=~/^grep=(.*)$/)           { $grep=$1;}
    elsif ($arg=~/^dir=(.*)$/)            { $dirSearch=$1;}
    elsif ($arg=~/^type=(.*)$/)           { $par{"fileType"}=$1;}
    elsif ($arg=~/^count$/)               { $Lcount=1;}
#    elsif ($arg=~/^=(.*)$/) { $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

				# ------------------------------
				# get search directory
$dirSearch= $dirSearch || "/home/rost" || $ENV{'HOME'};
die ("missing search dir ".$dirSearch)   if (! -d $dirSearch);
$dirSearch=~s/\/$//g;
				# ------------------------------
				# file types
$fileType=$par{"fileType"};
if ($fileType !~/^(T|B|x|l)$/) {
    print "*** for 'type=T' only the following values allowed at the moment:\n";
    print "T|B|x|l\n";
    exit; }
				# ------------------------------
				# extensions
@extSearch=split(/,/,$par{"extSearch"});
				# ------------------------------
				# grep regular expressions?
$#grepSearch=0;
@grepSearch=split(/\n/,$grep)   if (defined $grep);

				# output file
if (! defined $fileOut){
    $fileOut="Out-".$scrName.".tmp";}

				# ------------------------------
				# (1) read dir
				# ------------------------------
if ($dirSearch eq "/home/rost"){
    @dirList=  &dirLsAll($dirSearch);
    foreach $dir (@dirList){
	next if (! -d $dir);
	next if ($dir =~ /home\/rost\/data/ );
	@file= &fileLsAll($dir);
	push(@fileList,@file);}}
else {
    @fileList= &fileLsAll($dirSearch); }
	
if ($#fileList==0){
    print "*** no files found in dirSearch=$dirSearch,\n";
    exit;}
				# ------------------------------
				# (2) find all with extension
				# ------------------------------
$#fileOk=0;
foreach $file (@fileList) {
				# ignore all with bup
    next if ($file =~/bup\//i);
    next if ($file =~/old\//i);
    next if ($file =~/pub\/bup//i);

    if (! -e $file){print "-*- WARN $scrName: file=$file, not existing (dir=$dirSearch)\n";
		    next;}
    next if ($fileType ne "l" && ! -e $file); # ignore missing files

    next if (! -T $file && $fileType eq "T"); # wrong mode
    next if (! -B $file && $fileType eq "B"); # wrong mode
    next if (! -x $file && $fileType eq "x"); # wrong mode
    next if (! -l $file && $fileType eq "l"); # wrong mode
    next if ($fileType ne "l" && -l $file);   # ignore links

    $Lok=0;
    foreach $ext (@extSearch) { last if $Lok;
				$Lok=1  if ($file =~/$ext$/); }
    next if (! $Lok);		# wrong extension

    push(@fileOk,$file);	# ok
}
$#fileList=0;			# slick-is-in!

				# ------------------------------
				# (3) grep for expression
				# ------------------------------
if ($#grepSearch > 0) {
    @fileTmp=@fileOk;
    $#fileOk=0; }
foreach $file (@fileTmp) {
    $Lok=0;
    foreach $tmp (@grepSearch){ $out=`grep '$tmp' $file`; # system call
				$out=~s/\s|\n//g;
				if (length($out) >= length($tmp)) {
				    $grep{"$file"}=""  if (! defined $grep{"$file"});
				    $grep{"$file"}.="$out"."\n"; 
				    $Lok=1; }}
    next if (! $Lok);		# expression not found
    
    push(@fileOk,$file);	# ok
}
$#fileTmp=0;			# slick-is-in!

				# ------------------------------
				# (4) write screen
				# ------------------------------
foreach $file (@fileOk){
    print "$file";
    if (defined $grep{"$file"}){
	print "\t $grep found:";
	@tmp=split(/\n/,$grep{"$file"});
	foreach $tmp (@tmp){
	    print "\t(",$tmp,")";} }
    print "\n"; }

				# ------------------------------
				# (5) write output
				# ------------------------------
if ($#fileOk > 0){		# 

    open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";
    foreach $file (@fileOk) {
	print $fhout "$file\n"; }
    close($fhout);
    print "--- list of files in file=$fileOut\n"; }
else {
    print "--- no file found \n"; }
				# ------------------------------
				# final
print "--- did search in dir=$dirSearch, for extensions '",join('|',@extSearch),", \n";
if (defined $grep){ 
    print "--- for grep '",join('|',@grepSearch),", \n";}
				# ------------------------------
				# count lines
if ($#fileOk > 0 && defined $Lcount && $Lcount){
    $ct=$max=0; $min=1000;
    print "--- \n";
    print "--- now working on statistics\n";
    print "--- \n";
    foreach $file (@fileOk){

	$tmp=`wc -l $file`;

	$tmp=~s/\n//g; $tmp=~s/^\s*(\d+)\s*.*$/$1/g;
	$ct+=$tmp; 
	if ($tmp>$max) { $max=$tmp;
			 $filemax=$file;}
	if ($tmp<$min) { $min=$tmp;
			 $filemin=$file;}}

    printf "--- %-20s %8d %-s\n","no of files",$#fileOk,"";
    printf "--- %-20s %8s %-s\n"," ",".M..T...",     "";
    printf "--- %-20s %8d %-s\n","no of lines",$ct,     "";
    printf "--- %-20s %8d %-s\n","shortest",   $min,    "$filemin";
    printf "--- %-20s %8d %-s\n","longest",    $max,    "$filemax";
    printf "--- %-20s %8d %-s\n","average",    ($ct/$#fileOk), "";
}

	
exit;

#===============================================================================
sub dirLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   dirLsAll                    will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    return(0)                   if (! -d $dirLoc); # directory empty
    $sbrName="dirLsAll";$fhinLoc="FHIN"."$sbrName";$#tmp=0;
    print "xx entered with dir=$dirLoc,\n";
    $#tmp=0;
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>)    { $_=~s/\s//g;
			    next if (! -d $_);
			    print "xx found $_\n";
			    push(@tmp,$_); } close($fhinLoc);
    return(@tmp)                if ($#tmp>1);
				# ------------------------------
				# may have failed for big dirs 
    $#tmp=$#tmp2=0;
    @tmp2=`ls -a1 $dirLoc`; 
    $dirLocTmp=$dirLoc; $dirLocTmp.="/" if ($dirLocTmp !~/\/$/);
    foreach $tmp (@tmp2)  { $tmp=~s/\s|\n//g;
			    next if ($tmp eq ".");
			    next if ($tmp eq "..");
			    next if (length($tmp)<1);
			    $tmp=$dirLocTmp.$tmp;
			    next if (! -d $tmp);
			    push(@tmp,$tmp); } 
    $#tmp2=0;
    return(@tmp);
}				# end of dirLsAll

#==========================================================================================
sub fileLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAll                   will return a list of all files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! defined $dirLoc || $dirLoc eq "." || 
	length($dirLoc)==0 || $dirLoc eq " " || ! $dirLoc){
	if (defined $ENV{'PWD'}){
	    $dirLoc=$ENV{'PWD'}; }
	else {
	    $dirLoc=`pwd`; } }
				# directory missing/empty
    return(0)                   if (! -d $dirLoc || ! defined $dirLoc || $dirLoc eq "." || 
				    length($dirLoc)==0 || $dirLoc eq " " || ! $dirLoc);
				# ok, now do
    $sbrName="fileLsAll";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# read dir
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g; 
		       next if ($_=~/\$/);
				# avoid reading subdirectories
		       $tmp=$_;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
#		       next if ($tmp=~/^\//);
		       next if (-d $_);
		       push(@tmp,$_);}close($fhinLoc);
    return(@tmp);
}				# end of fileLsAll

