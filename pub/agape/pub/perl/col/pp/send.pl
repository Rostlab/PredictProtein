#!/usr/pub/bin/perl -w
#
#
$[ =1 ;

$file="message.txt";
foreach $it (1..$ARGV[1]){
    $cmd="cat < ".$file." | /usr/sbin/Mail -s ".$it." phd2\@embl-heidelberg.de";
    print "$cmd\n";
    system("$cmd");
}
exit;
