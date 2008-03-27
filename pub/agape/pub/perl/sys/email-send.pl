#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
# mail command (i)  cat file | Mail -s subject user
# mail command (ii)  Mail -s subj user text
#
$[ =1 ;
				# ------------------------------
				# help
if ($#ARGV<2){print "goal:   sends a mail to many users\n";
	      print "usage:  script file-with-mail file-with-users (one line per address)\n";
	      print "option: 'text=this is another way of writing the text'\n";
	      print "        user=rost\@embl-heidelberg.de  and another to give the user\n";
	      print "        subj=subject (specify subject)\n";
	      print "        \n";
	      print "        from-me      (send to all my accounts)\n";
	      print "        to-me        (sends from all my accounts)\n";
	      print "        \n";
	      die;}
				# ------------------------------
				# initialise variables
$exeMail="Mail";
$fhin="FHIN";
				# get arg
$fileMail=$ARGV[1];
$fileUser=$ARGV[2];
				# ini
$text=$user=$subj="";
$LfromMe=$LtoMe=0;
				# ------------------------------
foreach $arg (@ARGV){		# process command line arguments
#    print "arg ='$arg'\n";
    if   ($arg =~/^text=(.+)/) {
	$text=$1;
	print "--- will write    '$text'\n";}
    elsif($arg =~/^user=(.+)/) {
	$user=$1;
	print "--- will write to '$user'\n";}
    elsif($arg =~/^subj=(.+)/){
	$subj=$1;
	print "--- subject is    '$subj'\n";}
    elsif($arg =~/^from-me/)   {$LfromMe=$1;}
    elsif($arg =~/^to-me/)     {$LtoMe=$1;}
    elsif(-e $arg){
	next;}
    else { print "*** command line argument '$arg' not understood\n";
	   die;}}

if (!-e $fileMail && (length($text)<1)){
    print "*** first argument: file with the mail text\n";
    die;}
if (!-e $fileUser && (length($user)<1)){
    print "*** second argument: should be user\n";
    die;}

				# get user names
#$subj="letter against biological weapons (no chain, just sending it out to many ...)";
$#user=0;
if (-e $fileUser){
    open("$fhin", "$fileUser") || die "*** failed opening input file=$fileUser";
    while (<$fhin>) {$_=~s/\n//g;
		     push(@user,$_);}close($fhin);}
if (length($user)>1){
    push(@user,$user);}

push(@user,"rost\@columbia.edu"); # security : send also to me!

				# --------------------------------------------------
				# now do it
if   ($LfromMe){
    &fromAllBr;}
elsif($LtoMe){
    &toAllBr;}
else {
    if (length($subj)<2){ $subj="no subject"; }
    foreach $user (@user){
	next if ( (length($user)<3) && ($user !~/\@/));
	if (length($text)>=1){
	    $mail="echo '$text'  |$exeMail -s '$subj' $user";}
	else {
	    $mail="cat $fileMail |$exeMail -s '$subj' $user";}
	print "--- system \t '$mail'\n";
	system("$mail");}
}

exit;

#===============================================================================
sub fromAllBr {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fromAllBr                  sends file from all my accounts
#-------------------------------------------------------------------------------

    @mach=("phenix.embl-heidelberg.de",
	   "193.62.198.114",	# circinus EBI
	   "150.244.12.79",	# gredos CNB
	   "128.59.96.15",	# becks Columbia
	   "128.135.164.46",	# twyla UoC
	   "132.64.62.10"	# leonardo Jerusalem
       );

    foreach $mach (@mach){
	if (length($text)>=1){
	    $mail="echo '$text'  |$exeMail -s $subj $user";}
	else {
	    $mail="cat $fileMail |$exeMail -s $subj $user";}
	print "--- rsh $mach '$mail'\n";
	system("rsh $mach '$mail'");
    }
}				# end of fromAllBr

#===============================================================================
sub toAllBr {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   toAllBr                     sends file to all my accounts
#-------------------------------------------------------------------------------
    @user=("rost\@embl-heidelberg.de",
	   "rost\@ebi.ac.uk",
       );
    if (length($subj)<2){ $subj="no subject"; }

    foreach $user (@user){
	if (length($text)>=1){
	    $mail="echo '$text'  |$exeMail -s '$subj' $user";}
	else {
	    $mail="cat $fileMail |$exeMail -s '$subj' $user";}
	print "--- \t '$mail'\n";
	system("$mail");}
    
}				# end of subx

