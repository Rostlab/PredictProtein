#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="testing PROF installation";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      'exeProf',                "/home/rost/pub/prof/prof",   # PROF (perl script)
      'fhTrace',                "FHTRACE",                    # file handle for trace file
      'fileScreen',             "XTST-PROF-SCREEN".".tmp",    # trace file
      'dirExa',                 "/home/rost/pub/prof/exa/",   # directory pointing to PROF examples
      );

@tst=(
				# test general run options
      "dirExa"."1ppt.hssp   fileRdb=tst-1ppt.rdbProfSec  sec  ascii",
      "dirExa"."1ppt.hssp   fileRdb=tst-1ppt.rdbProfAcc  acc  ascii",
      "dirExa"."1ppt.hssp   fileRdb=tst-1ppt.rdbProfBoth both ascii",
      "dirExa"."1ppt.hssp   fileRdb=tst-1ppt.rdbProf          ascii",

      "dirExa"."1prc.hssp_L fileRdb=tst-1prcL.rdbProfSec sec  ascii",
      "dirExa"."1prc.hssp_L fileRdb=tst-1prcL.rdbProfAcc acc  ascii",
      "dirExa"."1prc.hssp_L fileRdb=tst-1prcL.rdbProfHtm htm  ascii",
      "dirExa"."1prc.hssp_L fileRdb=tst-1prcL.rdbProf         ascii",

      "dirExa"."1shg.hssp   fileRdb=tst-1shg.rdbProf     both ascii ".
                                           "saf  fileAli=tst-1shg.profSaf ".
                                           "dssp fileDssp=tst-1shg.profDssp",
      "dirExa"."1shg.hssp   fileRdb=tst-1shg.rdbProfFilter both ascii ".
                                           "filter optFilter=red=70 ".
                                           "msf fileAli=tst-1shg.profFilterMsf",

				# test sequence conversion
      "dirExa"."256b.dssp      fileRdb=tst-256b.rdbProfSec sec ascii",
      "dirExa"."2ppt.fastamul  fileRdb=tst-2ppt.rdbProfSec sec ascii",
#      "dirExa"."3ppt.gcg       fileRdb=tst-3ppt.rdbProfSec sec ascii",
      "dirExa"."8rnt.msf       fileRdb=tst-8rnt.rdbProfSec sec ascii",
      "dirExa"."9rnt.saf       fileRdb=tst-9rnt.rdbProfSec sec ascii",
#      "dirExa"."paho_chick     fileRdb=tst-paho.rdbProfSec sec ascii",

      );

if (0){
    @tst=(
				# test general run options
	  "dirExa"."1ppt.hssp   fileRdb=tst-1ppt.rdbProfSec sec ascii",
	  );}

@kwd=sort (keys %par);
$Lskip=0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "       ", "=" x length($scrName), "===\n";
    print  "use:  '$scrName do (or any other argument to run automatical test)'\n";
    print  "       ", "=" x length($scrName), "===\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s  %-20s %-s\n","pwd",      "x",       "your local directory in which to run the test";
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "will list all differences between now and want";
    printf "      %-15s  %-20s %-s\n","noScreen", "no value","no output to screen";
    printf "      %-15s  %-20s %-s\n","debug",    "no value","all onto screen, keep temp files";

    printf "      %-15s  %-20s %-s\n","skip",     "no value","skips running PROF for existing files";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	$tmp= sprintf("      %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("      %-15s  %-20s %-s\n","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("      %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("      %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    print ">>> do:\n";
    print $0,".'.pl do'\n\n";
    die '      forced exit'; }
				# initialise variables
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
$Ldebug=0;
$Lverb=1;

$pwd=$ENV{'PWD'} || `pwd`;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq "do");
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^noScr.[a-z]*$/i)       { $Lverb=  0;}
    elsif ($arg=~/^debug$/i)              { $Ldebug= 1;}
    elsif ($arg=~/^skip$/i)               { $Lskip=  1;}

    elsif ($arg=~/^pwd=(.*)$/)            { $pwd=    $1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){
		$Lok=1;$par{"$kwd"}=$1;
		last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die '      forced exit';}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die '      forced exit';}}

				# ------------------------------
				# check input 
$par{"dirExa"}.="/"             if ($par{"dirExa"} !~ /\/$/);

if (! -e $par{"exeProf"} && ! -l $par{"exeProf"}) {
    print "*** ERROR $scrName: exeProf=",$par{"exeProf"},", not existing\n";
    exit;}
if (! -x $par{"exeProf"} ) {
    print "*** ERROR $scrName: exeProf=",$par{"exeProf"},", not executable\n";
    exit;}
if (! -d $par{"dirExa"}){
    print "*** ERROR $scrName: directory with PROF examples (prof/exa) set to be=",$par{"dirExa"},"\n";
    print "***                 but: not existing\n";
    exit; }
$fileOut="TEST-PROF-INSTALLATION.out"    if (! defined $fileOut);

if (! defined $pwd) {
    print "*** sorry for this, could not determined current directory!\n";
    print "*** please do use the argument 'pwd=your_current_directory'\n";
    exit; }
if ($pwd eq $par{"dirExa"}) {
    print "*** sorry the directory where you run the test must be different than the\n";
    print "*** original prof/exa directory to avoid problems\n";
    exit; }


				# screen/trace file
$par{"fileScreen"}=0            if ($Ldebug);
$par{"fhTrace"}=   "STDOUT"     if ($Ldebug || $Lverb);

    
if (! $Lverb && ! $Ldebug) {
    open($par{"fhTrace"},$par{"fileScreen"}) ||
	do {
	    warn "*** ERROR $scrName failed opening new file ".$par{"fileScreen"}."\n";
	    $par{"fhTrace"}="STDOUT"; } }
$fhTrace=$par{"fhTrace"};
				# ------------------------------
				# fill in directory
foreach $tst (@tst){
    $tst=~s/dirExa/$par{"dirExa"}/;
    $tst=~s/\s\s+/ /g; }

				# ------------------------------
				# (1) run commands
				# ------------------------------
$cmdSys="";			# avoid warnings
$#fileProf=$#fileRdb=0;
$Lerr=$ct=0;
foreach $tst (@tst){
    $cmd=$tst;

    $tmp=$cmd;
    $tmp=~s/.*fileRdb=(\S+)//;
    $fileRdb= $1; 
    $fileProf=$fileRdb;$fileProf=~s/.rdbProf/.prof/;

    $cmd.=" debug"              if ($Ldebug);
    $cmd=$par{"exeProf"}." ".$cmd;

    if ($Lskip && -e $fileRdb){
	print $fhTrace "--- skipped ($fileRdb exists, flag set) \t $cmd\n";
	next;}

    print $fhTrace "--- system \t $cmd\n";

    eval            "\$cmdSys=\"$cmd\"";
    ++$ct;
				# run FORTRAN script
    ($Lok,$msg)=    &sysRunProg($cmdSys,$par{"fileScreen"},$par{"fhTrace"});
	
    if (! $Lok){
	print "*** ERROR $scrName: failed to run $cmd\n",$msg,"\n";
	$Lerr=1;
	next; }
    $fileProf[$ct]=$fileProf      if (-e $fileProf);
    $fileRdb[$ct]=$fileRdb      if (-e $fileRdb);
}
				# ------------------------------
				# (2) get differences
				# ------------------------------
$tmpWrt="";
foreach $it (1..$#tst){
    $tmpWrt.=         sprintf ("---> %-10s %-s\n","command=",$tst[$it]);
				# diff on file.prof
    if (defined $fileProf[$it]){
	$exa=$fileProf[$it]; $exa=~s/^.*\///g; $exa=~s/^tst\-//g;
	$exa=$par{"dirExa"}.$exa;
	$tmpWrt.=     sprintf ("---> %-10s %-30s %-s\n","diff",$fileProf[$it]." (<)",$exa." (>)");
	$cmd="diff ".$fileProf[$it]." $exa";
	@tmp=`$cmd`;
	foreach $tmp (@tmp){
	    $tmp=~s/\n//g;$tmp=~s/\s*$//g;
	    $tmpWrt.= sprintf ("%-s\n",$tmp); } }
    
				# diff on file.rdb
    if (defined $fileRdb[$it]){
	$exa=$fileRdb[$it]; $exa=~s/^.*\///g; $exa=~s/^tst\-//g;
	$exa=$par{"dirExa"}.$exa;
	$tmpWrt.=     sprintf ("---> %-10s %-30s %-s\n","diff",$fileRdb[$it]." (<)",$exa." (>)");
	$cmd="diff ".$fileRdb[$it]." $exa";
	@tmp=`$cmd`;
	foreach $tmp (@tmp){
	    $tmp=~s/\n//g;$tmp=~s/\s*$//g;
	    $tmpWrt.= sprintf ("%-s\n",$tmp); } }
}

				# ------------------------------
				# (3) filter differences
				# ------------------------------
@tmpWrt=split(/\n/,$tmpWrt);
$tmpWrt=""; $buffer=0; $ct=0;
foreach $tmp (@tmpWrt){
				# keywords
    if ($tmp=~/^\-+[\>]* (command|diff)/){
	$tmpWrt.=$tmp."\n";
	next;}
				# line of difference
    if ($tmp=~/^\d+c\d+/){
				# exceptions: date
	$buffer=&filterBuffer($buffer)
	    if ($buffer);
	$tmpWrt.=$buffer        if ($buffer);
	++$ct                   if ($buffer);
	$buffer=$tmp."\n"; 
	next; }
				# differences
    $buffer.=$tmp."\n";
}
				# last buffer
$buffer=&filterBuffer($buffer)
    if ($buffer);
$tmpWrt.=$buffer               if ($buffer);

				# ------------------------------
                                # (4) write differences
open("$fhout",">$fileOut"); 
printf $fhout "---  %-10s\t%-30s\t%-30s\n"," ","fileNew","fileOld";
print $fhout $tmpWrt;
close($fhout);	

print "--- ------------------------------------------------------------\n";
print "--- $scrName ended\n";
print "--- \n";
print "--- you did run ",$#tst," PROF jobs\n";
print "--- \n";
print "--- the default PROF results and those you obtained with your cur-\n";
print "---     rent installation, differed by $ct line"; print "s" if ($ct>1); print "\n";
print "--- \n";
print "--- output in $fileOut\n" if (-e $fileOut);
exit;

#===============================================================================
sub filterBuffer {
    local($bufferLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   filterBuffer                       
#       in:                     $buffer
#       out:                    0|$buffer
#-------------------------------------------------------------------------------
    return(0) if ($bufferLoc =~ /(199[89]|200\d)[\s\n]/ ||
		  $bufferLoc =~ /(199[89]|200\d)[\s\n]/ );
		  
    return($bufferLoc);
}				# end of filterBuffer

#======================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-ut:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if    ($fhErrLoc && ! @arg) {
#	print $fhErrLoc "-*- WARN $sbrName: no arguments to pipe into:\n$prog\n";
    }
    elsif ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system cmd=\n$prog\n--- $sbrName: fileOut=$fileScrLoc cmd IN:\n$cmd\n";}
				# ------------------------------
				# pipe output into file?
    $prog.=" | cat >> $fileScrLoc " if ($fileScrLoc);
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg


