#!/usr/pub/bin/perl4 -w
#
# extracts address from files that ended up unsent in
#   /home/phd/server/result
#   and tries to send
#
$[ =1 ;

push (@INC, "/home/phd/ut/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print "goal:  extracts address from files that ended up unsent in\n";
	      print "       /home/phd/server/result\n"; 
	      print "       and tries to send\n"; 
	      print "note:  recognises address by 'from '\n"; 
	      print "use:   clean-done.pl pred*done \n"; 
	      exit;}

$fhin=     "FHIN";
$dirMail=  "/home/phd/server/mail/";
$mailCmd=  "/usr/sbin/Mail";


foreach $arg (@ARGV){
    if (! -e $arg){
	next;}
    $file=$arg;
				# ------------------------------
				# read file
    &open_file("$fhin", "$file");
    $address="unk";$Lok=0;
    while (<$fhin>) {$_=~s/\n//g;
		     if (/^______/ && ! $Lok){$Lok=1; # start reading
					      next;}
		     if (/^______/ && $Lok)  {$Lok=1; # end reading
					      last;}
		     if (/^\s*from /){$_=~s/^\s*from\s*//g;$_=~s/\s//g;
				      $address=$_;
				      last;}}close($fhin);
				# ------------------------------
    if ($address ne "unk"){	# sent
	print "xx $file $address\n";
	&sendMail($file,$address,$mailCmd);
	system("\\rm $file");
	next; }
				# ------------------------------
				# search for address in directory /mail
    $tmp=$file; $tmp=~s/done/query/;
    $fileMail=$dirMail . $tmp;
    if (! -e $fileMail){	# none found
	print "*** address unknown for '$file'\n";
	$tmp="tmp/"."$file";
	system ("\\mv $file $tmp"); # move file
	next;}
				# read address
    &open_file("$fhin", "$fileMail");
    $address="unk";$Lok=0;
    while (<$fhin>) {$_=~s/\n//g;
		     if (/^\s*from /){$_=~s/^\s*from\s*//g;$_=~s/\s//g;
				      $address=$_;
				      last;}}close($fhin);
    if ($address eq "unk"){	# none found
	print "*** address unknown for '$file'\n";
	$tmp="tmp/"."$file";
	system ("\\mv $file $tmp"); # move file
	next;}

    &sendMail($file,$address,$mailCmd);
    system("\\rm $fileMail");
}
exit;

sub sendMail{
    local ($fileIn,$userIn,$mailCmdLoc)=@_;
    print "--- system \t '$mailCmdLoc -s Predict-Protein $userIn < $fileIn'\n";
    system "$mailCmdLoc -s Predict-Protein $userIn < $fileIn";
}
    
