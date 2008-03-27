#!/usr/pub/bin/perl -w
#
#  hacks on errors: when files come off the VAX without having
#  been correctly processed by the scanner
#
$[ =1 ;
				# help
if ($#ARGV<1){print "goal:    files from VAX (only numbers) to those for server/pred\n";
	      print "usage:   script * (for files)\n";
	      exit;}
$ct=0;
foreach $_(@ARGV){		# 
    $file=$_;
    next if (! -e $file);
    ++$ct;
    $file_new=$_;
    $num=$$; $num=$num-($#ARGV+$ct);
    $file_out="pred_hack".$num;
    $file_mail_query="/home/phd/mail/". $file_out . "_query";
    $file_mail_query=$file_out . "_query";

				# extract data from input file
    $user=       &extractUser($file_new);
    $origin=     "MAIL";
    $resp_mode=  "MAIL";

    open (QUERY,">$file_mail_query");
    print QUERY "from $user\n";
    print QUERY "orig $origin\n";
    print QUERY "resp $resp_mode\n";
    close(QUERY);


    open (FILE,    $file_new);
    open (OUTFILE, ">$file_out");
    print OUTFILE "from $user\n";
    print OUTFILE "orig $origin\n";
    print OUTFILE "resp $resp_mode\n";

    while (<FILE>) {
	print OUTFILE $_;}
    close(FILE);close(OUTFILE);
    print "out=$file_out\n";
}
exit;
#=======================================================================
# extract user_address from input file
#=======================================================================
sub extractUser{
    local ($file_name) = @_;
    local ($user);

    open (FILE, $file_name);
    while (<FILE>) {chop;
		    if (/\S+\@\S+\.[a-zA-Z][a-zA-Z]/) {
#			print "in $_\n";
			$user=$_;
			$user=~s/[. ]*(\S+\@\S+\.[a-zA-Z][a-zA-Z])[\s.]*$/$1/g;
			last;}}
    close(FILE);
    return $user;
}

#=======================================================================
# extract request's origin from input file
#=======================================================================
