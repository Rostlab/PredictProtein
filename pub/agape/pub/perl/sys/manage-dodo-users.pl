#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="writes out a list of dodo users, links home pages to /home, asf\n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Aug,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'send',     0,		# if 1: send mail to users
      'subj',     0,		# subject for mail
      'link',     0,		# if 1: link home directories
      'msg',      0,		# if 1: send message (could also be a file)
      'quota',    0,		# if 1: du is checked
      'dumax',    '2000',	# if more than 2GB: send mail to user
      'group',    "all",	# specify a group <all|honig|rost|special>
      'list',     0,		# if 1: list all users, and disk use asf
      'list_only',0,		# if 1: only lists all users
      'junk',     0,            # if 1: makes a directory in /junk for all users

      'passwd',   "/etc/passwd", # password file
      'exe_ln',   "/usr/local/bin/ln",
      'exe_du',   "/usr/local/bin/du",
      'exe_mail', "/usr/local/bin/Mail",

      'dir_home', "/home",	# default home directory
      'dir_junk', "/junk",      # junk dir

      'machine',  "dodo.cpmc.columbia.edu",

      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
@user=
    (
     "alex",
     "atsanov",
     "bissan",
     "courcell",
     "cubic",
     "database",
     "djabali",
     "fabio",
     "felix",
     "ftp",
     "gaasterl",
     "glenn",
     "guest",
     "hitz",
     "honig",
     "jjung",
     "karlin",
     "katie",
     "liu",
     "manel",
     "marina",
     "meta",
     "michelle",
     "murad",
     "murray",
     "nair",
     "norel",
     "pazos",
     "petrey",
     "phd",
     "rost",
     "test",
     "volker",
     "www",
     "xiang",
     "yanga",
     );
@user_exclude=
    (
     'sysadm',
     'diag',
     'daemon',
     'bin',
     'sys',
     'adm',
     'lp',
     'auditor',
     'dbadmin',
     'rfindd',
     'cron',
     'nobody',
     'noaccess',
     '4Dgifts',
     'OutOfBox',
     'demos',
     'EZsetup',
     'sgiweb',
     'root',
     'cmwlogin',
     'uucp',
     'nuucp',
#     '',
     );

%user_exclude_junk=
    (
     'alex',      "1",
     'cubic',     "1",
     'database',  "1",
     'ftp',       "1",
     'guest',     "1",
     'meta',      "1",
     'phd',       "1",
     'test',      "1",
     );

     
%user_group=
    (
     'alex',      "honig",
     'atsanov',   "honig",
     'bissan',    "honig",
     'courcell',  "rost",
     'cubic',     "rost",
     'database',  "special",
     'djabali',   "rost",
     'fabio',     "honig",
     'felix',     "honig",
     'ftp',       "special",
     'gaasterl',  "rost",
     'glenn',     "honig",
     'guest',     "special",
     'hitz',      "honig",
     'honig',     "honig",
     'jjung',     "honig",
     'karlin',    "honig",
     'katie',     "honig",
     'liu',       "rost",
     'manel',     "honig",
     'marina',    "honig",
     'meta',      "rost",
     'michelle',  "honig",
     'murad',     "honig",
     'murray',    "honig",
     'nair',      "rost",
     'norel',     "honig",
     'pazos',     "rost",
     'petrey',    "honig",
     'phd',       "rost",
     'rost',      "rost",
     'test',      "honig",
     'volker',    "rost",
     'www',       "special",
     'xiang',     "honig",
     'yanga',     "honig",
     );
%user_home=
    (
     'alex',      "/danube",
     'atsanov',   "/danube/homehg",
     'bissan',    "/home",
     'courcell',  "/dodo2",
     'cubic',     "/dodo2",
     'database',  "/home",
     'djabali',   "/dodo2",
     'fabio',     "/danube/homehg",
     'felix',     "/home",
     'ftp',       "/home",
     'gaasterl',  "/dodo2",
     'glenn',     "/home",
     'guest',     "/home",
     'hitz',      "/danube/homehg",
     'honig',     "/danube/homehg",
     'jjung',     "/danube/homehg",
     'karlin',    "/home",
     'katie',     "/danube/homehg",
     'liu',       "/dodo2",
     'manel',     "/danube/homehg",
     'marina',    "/danube/homehg",
     'meta',      "/home",
     'michelle',  "/danube",
     'murad',     "/home",
     'murray',    "/home",
     'nair',      "/dodo3",
     'norel',     "/home",
     'pazos',     "/dodo2",
     'petrey',    "/danube/homehg",
     'phd',       "/home",
     'rost',      "/home",
     'test',      "/home",
     'volker',    "/dodo2",
     'www',       "/home",
     'xiang',     "/home",
     'yanga',     "/home",
     );
foreach $user (@user){
    $user{$user}=1;
    $user_home{$user}.="/" if ($user_home{$user}!~/\/$/);
    $user_home{$user}.=$user;}

foreach $user (@user_exclude){
    $user{$user}=0;}
     
     
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName auto' (or respective keywords)\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

    printf "%5s %-15s %-20s %-s\n","","list",    "no value","makes list of all users asf";
    printf "%5s %-15s %-20s %-s\n","","list_only","no value","only lists all users";
    printf "%5s %-15s %-20s %-s\n","","junk",    "no value","makes dir for each user in /junk";
    printf "%5s %-15s %-20s %-s\n","","send",    "no value","send email";
    printf "%5s %-15s %-20s %-s\n","","quota",   "no value","check disk usage";
    printf "%5s %-15s %-20s %-s\n","","link",    "no value","link home directories";
    printf "%5s %-15s %-20s %-s\n","","<all|honig|rost|special>",   "no value","restrict user (default=all)";
    printf "%5s %-15s=%-20s %-s\n","","msg",     "x", "'this is a message to send'";
    printf "%5s %-15s %-20s %-s\n","","",        "", "OR: msg=file_name to send file file_name";
    printf "%5s %-15s=%-20s %-s\n","","subj",    "x",       "subject for sending mail";
    
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
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
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^de?bu?g$/)             { $Ldebug=          1;
					    $Lverb=           1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=           1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=           0;}

    elsif ($arg=~/^auto$/)                { $par{"send"}=     0;
					    $par{"list"}=     1;
					    $par{"link"}=     1;
					    $par{"quota"}=    1;}

    elsif ($arg=~/^all$/)                 { $par{"group"}=    "all";}
    elsif ($arg=~/^honig$/)               { $par{"group"}=    "honig";}
    elsif ($arg=~/^rost$/)                { $par{"group"}=    "rost";}
    elsif ($arg=~/^special$/)             { $par{"group"}=    "special";}
    elsif ($arg=~/^send$/)                { $par{"send"}=     1;}
    elsif ($arg=~/^link$/)                { $par{"link"}=     1;}
    elsif ($arg=~/^junk$/)                { $par{"junk"}=     1;}
    elsif ($arg=~/^list$/)                { $par{"list"}=     1;}
    elsif ($arg=~/^list.?only$/)          { $par{"list_only"}=1;}
    elsif ($arg=~/^quota$/)               { $par{"quota"}=    1;}
    elsif ($arg=~/^msg=(.*)$/)            { $tmp=             $1; }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
#    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}


$par{"dir_home"}.="/"           if ($par{"dir_home"} !~/\/$/);
$par{"subj"}="root_on_dodo"     if (! $par{"subj"} && $par{"send"});

				# --------------------------------------------------
				# (1) check user: read password file
				# --------------------------------------------------
if ($par{"quota"} || $par{"link"} || $par{"junk"} || 
    $par{"list"} || $par{"list_only"}){
    $fileIn=$par{"passwd"};
    if (-e $fileIn){
	open($fhin,$fileIn) || die "*** $scrName ERROR opening file $fileIn";
	while (<$fhin>) {
	    $_=~s/\n//g;
	    @tmp=split(/:+/,$_);
	    $user=$tmp[1]; $home=$tmp[6];
				# exclude users
	    next if (defined $user{$user} && ! $user{$user});
	    next if (defined $user_group{$user} &&
		     $user_group{$user} eq "special");

	    next if ($par{"group"} ne "all" &&
		     defined $user_group{$user} &&
		     $user_group{$user} ne $par{"group"});
				# user not listed in this script
	    if    (! defined $user{$user}){
		print "-*- missing in script: user $user, please update field '\@user'!\n";
		push(@user,$user); $user{$user}=1;
		$user_home{$user}=$home;}
				# user listed with different home directory
	    elsif ($home !~ /\/home/ &&
		   $user_home{$user} ne $home){
		print 
		    "-*- WARN $user home=$home (in $fileIn), expected home=",
		    $user_home{$user}," (update in script '\%user_home')\n";
		$user_home{$user}=$home;}
	    elsif ($Ldebug || $Lverb){
		next if ($par{"group"} ne "all" &&
			 defined $user_group{$user} &&
			 $user_group{$user} ne $par{"group"});
		print "--- $user $home is ok\n";}
	}
	close($fhin);}
    else {
	print "*** STRONG WARN: password file=$fileIn missing!!\n";}}
				# --------------------------------------------------
				# (2) link home directories
				# --------------------------------------------------
if ($par{"link"}){
    foreach $user (@user){
				# exclude users
	next if (defined $user{$user} && ! $user{$user});

	next if ($par{"group"} ne "all" &&
		 defined $user_group{$user} &&
		 $user_group{$user} ne $par{"group"});
	$home=$par{"dir_home"}.$user;
	if (! -e $user_home{$user} && ! -l $user_home{$user}) {
	    print "*** ERROR home=",$user_home{$user},", for user=$user, missing!!\n";
	    next;}
	if (! -e $home && ! -l $home){
	    $cmd=$par{"exe_ln"}." -s ".$user_home{$user}." $home";
	    print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
#xx	    system("$cmd");
	}
	if (! -e $home && ! -l $home) {
	    print "*** system command failed no link to home=$home!\n";}
	else {
	    print "--- $user link to $home ok\n" if ($Lverb || $Ldebug);}
    }}

				# --------------------------------------------------
				# (3) check quota
				# --------------------------------------------------
if ($par{"quota"}){
    $#over=0;
    foreach $user (@user){
				# exclude users
	next if (defined $user{$user} && ! $user{$user});

	next if ($par{"group"} ne "all" &&
		 defined $user_group{$user} &&
		 $user_group{$user} ne $par{"group"});
	$home=$par{"dir_home"}.$user;
	$homeOrig=$user_home{$user};
	if (! -e $user_home{$user} && ! -l $user_home{$user}) {
	    print "*** WARN home=",$user_home{$user},", for user=$user, missing!!\n";
	    next;}
	if (! -e $home && ! -l $home){
	    print "*** WARN home=$home, for user=$user missing!\n";
	    next; }
				# check du
	$cmd=$par{"exe_du"}." -sk $homeOrig";
	print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
	$tmp=`$cmd`;
	@tmp=split(/\n/,$tmp);
	$tmp=$tmp[$#tmp]; 
	$tmp=~s/^(\d+)\s*.*$/$1/g;
	$kb=int($tmp/1000);
	$user_quota{$user}=$kb;
	if ($kb > $par{"dumax"}){
	    push(@over,$user."\t".$kb);
	    print "--- $user over quota! usage=$kb KB, max=",$par{"dumax"}," Kb\n";
	}}
				# send mail
    if ($#over > 1){
	$fileOut_quota="dodo_admin_over_quota.tmp";
	open("$fhout",">$fileOut_quota") || die "*** $scrName ERROR creating file $fileOut_quota";
	print $fhout "WARNING the following user are requested to reduce their data on dodo!\n";
	foreach $over (@over){
	    print $fhout $over,"\n";
	}
	close($fhout);
	foreach $over (@over) {
	    $user=$over; $user=~s/\t.*$//g;
	    $user.="\@".$par{"machine"};
	    $cmd="cat $fileOut_quota | ".$par{"exe_mail"}." -s dodo_home_over_quota $user";
	    print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
#xx	    system("$cmd");
	}}
}

				# --------------------------------------------------
				# (4) send email
				# --------------------------------------------------
if ($par{"send"}){
    foreach $user (@user){
				# exclude users
	next if (defined $user{$user} && ! $user{$user});

	next if ($par{"group"} ne "all" &&
		 defined $user_group{$user} &&
		 $user_group{$user} ne $par{"group"});
	$user.="\@".$par{"machine"};
				# email file
	if (-e $par{"msg"}) {
	    $cmd="cat ".$par{"msg"}. " | ".$par{"exe_mail"}." -s '".$par{"subj"}."' $user";}
	else {
	    $cmd="echo ".$par{"msg"}." | ".$par{"exe_mail"}." -s '".$par{"subj"}."' $user";}
	print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
	system("$cmd");
    }
}
				# --------------------------------------------------
				# (5) list of statistics asf
				# --------------------------------------------------
if ($par{"list"}){
    $sep="\t";
    $fileOut_list="dodo_users_stat.rdb";
    open("$fhout",">$fileOut_list") || die "*** $scrName ERROR creating file $fileOut_list";
    $tmp=`date`;$tmp=~s/[\s\n]*$//g;
    print $fhout 
	"# Perl-RDB\n",
	"# users on dodo $tmp\n";
    print $fhout
	"user",$sep,"du Kb",$sep,"group",$sep,"home",$sep,"email","\n",
	"10S", $sep,"8N",   $sep,"10s",  $sep,"20S", $sep,"S","\n";

    foreach $user (@user){
				# exclude users
	next if (defined $user{$user} && ! $user{$user});

	next if ($par{"group"} ne "all" &&
		 defined $user_group{$user} &&
		 $user_group{$user} ne $par{"group"});
	if (defined $user_home{$user}){
	    $home=$user_home{$user};}
	else {
	    $home=$par{"dir_home"}.$user;}
	if (! -e $home && ! -l $home) {
	    print "*** ERROR $user $home missing!\n";
	    next;}

	if (! defined $user_quota{$user}){
				# check du
	    $cmd=$par{"exe_du"}." -sk $home";
	    print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
	    $tmp=`$cmd`;
	    @tmp=split(/\n/,$tmp);
	    $tmp=$tmp[$#tmp]; 
	    $tmp=~s/^(\d+)\s*.*$/$1/g;
	    $kb=int($tmp/1000);
	    $user_quota{$user}=$kb;}
	$group="?";
	$group=$user_group{$user} if (defined $user_group{$user});
				# statistics for user
	printf $fhout
	    "%-10s$sep%8d$sep%-10s$sep%-20s$sep%-s\n",
	    $user,$user_quota{$user},$group,$home,$user."\@".$par{"machine"};
    }
    close($fhout);
}
				# --------------------------------------------------
				# (6) list users
				# --------------------------------------------------
if ($par{"list_only"}){
    $sep="\t";
    $fileOut_listonly="dodo_users_list.dat";
    open("$fhout",">$fileOut_listonly") || 
	die "*** $scrName ERROR creating file $fileOut_listonly";
    foreach $user (@user){
				# exclude users
	next if (defined $user{$user} && ! $user{$user});

	next if ($par{"group"} ne "all" &&
		 defined $user_group{$user} &&
		 $user_group{$user} ne $par{"group"});
	print $fhout $user,"\n";
    }
    close($fhout);
}
				# --------------------------------------------------
				# (7) make user directory on /junk
				# --------------------------------------------------
if ($par{"junk"}){
    $dir_junk=$par{"dir_junk"};
    $dir_junk.="/"              if ($dir_junk !~/\/$/);
    foreach $user (@user){
				# exclude users
	next if (defined $user{$user} && ! $user{$user});
	next if (defined $user_exclude_junk{$user} && $user_exclude_junk{$user});

	next if ($par{"group"} ne "all" &&
		 defined $user_group{$user} &&
		 $user_group{$user} ne $par{"group"});
	
	$dir=$dir_junk.$user;
				# already existing
	next if (-l $dir || -d $dir);
				# make directory
	$cmd="mkdir $dir";
	print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
	system("$cmd");
				# change permission
	$cmd="chown $user:user $dir";
	print "--- system '$cmd'\n" if ($Lverb || $Ldebug);
	system("$cmd");
    }
}
print "--- quota in $fileOut_quota\n"            if (defined $fileOut_quota && 
						     -e $fileOut_quota);
print "--- statistics in $fileOut_list\n"        if (defined $fileOut_list && 
						     -e $fileOut_list);
print "--- list of users in $fileOut_listonly\n" if (defined $fileOut_listonly && 
						     -e $fileOut_listonly);
#print "--- output in $fileOut\n" if (-e $fileOut);
exit;


#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd


