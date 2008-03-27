#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "user name|file_with_names";
$scrGoal="sets up links from /User/\$name to /Volumes/user/\$name\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t note:   names [a-zA-Z]\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2002	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2002	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
#$sep=   "\t";

$rootmac="rootmac";
@dirWant=
    ("Desktop",
     "Documents",
     "Library",
     "Movies",
     "Music",
     "Pictures",
     "Public",
     "Sites"
     );
$dirNoLink{"Documents"}=1;
$dirNoLink{"Library"}=1;
$dirUsers="/Users/";
$dirLink= "/Volumes/user/";
$dirRoot=$dirUsers.$rootmac;

				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";
#$fhout="FHOUT";
$#fileIn=0;
#$dirOut=0;
$#user=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^([A-Za-z]+)$/)         { push(@user,$arg); }
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

if ($#fileIn){
    $fileIn=$fileIn[1];
    print "--- $scrName: working on fileIn=$fileIn!\n";
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      exit;}
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    while (<$fhin>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	$_=~s/\#.*$//g;		# purge after comment
	$_=~s/\s//g;		# purge blanks
	push(@user,$_);
    }
    close($fhin);
}

if (! $#user){
    print "*** no users found in ";
    if (! $#fileIn){
	print "command line";}
    else {
	print "file $fileIn";}
    print " \n";
    print "--- may be there were not of type [a-zA-Z]?\n";
    exit;}


$#filePurge=0;


# 1: get stuff from rootmac
$cmd="chdir $dirRoot";
print "--- sys $cmd\n";
chdir($dirRoot);
$fileRootTar=$dirRoot;
$fileRootTar.="/" if ($fileRootTar !~/\/$/);
$fileRootTar.="tmp-root-stuff.tar";
push(@filePurge,$fileRootTar);
$cmd="tar -cf $fileRootTar ".join(" ",@dirWant);
system("$cmd");
print "--- system $cmd\n" if ($Lverb);

				# ------------------------------
				# (1) all users
				# ------------------------------
$ctuser=$ctok=0;
foreach $user (@user){
    ++$ctuser;
    print "--- $scrName: working on user=$user!\n";

    # go to user
    chdir($dirUsers);

    $dirThis=$user;

    # remove if existing
    if (-l $dirThis){
	&sysloc("\\rm -r ".$dirThis);
    }
    
    $dirThisFull=$dirUsers.$user."/";


    # 2 make new dir if missing
    if (! -d $dirThis){
	&sysloc("mkdir ".$dirThis);
    }
    # 3 go there
    chdir($dirThis);

    # make copy on user
    $dirThisLink=$dirLink.$user;
    if (! -d $dirThisLink){
	&sysloc("mkdir $dirThisLink");
    }
    
    $dirThis.="/";
    # clean up
    &sysloc("\\rm -r *");
    
    # copy root stuff
    $fileTarLoc=$fileRootTar;
    $fileTarLoc=~s/^.*\///g;
#    $fileTarLoc=$dirThis.$fileTarLoc;
    $fileTarLoc=$fileTarLoc;
    &sysloc("cp $fileRootTar $fileTarLoc");
    &sysloc("tar -xf $fileTarLoc");
    
    # now delete stuff for user
    foreach $dirWant (@dirWant){
	next if (defined $dirNoLink{$dirWant});
	# tar it
	$fileTarTmp="tmp".$dirWant.".tar";
	&sysloc("tar -cf $fileTarTmp $dirWant");
	&sysloc("\\mv $fileTarTmp $dirThisLink");
	chdir($dirThisLink);
	&sysloc("tar -xf $fileTarTmp");
	&sysloc("\\rm $fileTarTmp");
	chdir($dirThisFull);
	&sysloc("\\rm -r $dirWant");
	$dirThisLink.="/" if ($dirThisLink !~/\/$/);
	&sysloc("ln -s ".$dirThisLink.$dirWant."/ ".$dirWant);
#	print "xx dirthis=$dirThis (after wnat $dirWant) ls=\n";system("ls -l");print "pwd\n";system("pwd");die;
    }
    chdir("$dirThis");
    unlink($fileTarLoc);
    &sysloc("ln -s $dirThisLink user");
    chdir("$dirUsers");
    &sysloc("chown -R ".$user.":staff ".$user);
}
unlink($fileRootTar);
exit;

sub sysloc {
    $[ =1 ;				# count from one
    ($cmd)=@_;
    system("$cmd");
    print "--- system $cmd\n" if ($Lverb);
}
