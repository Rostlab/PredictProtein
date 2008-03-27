#!/usr/bin/perl -w
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

$file_in=$ARGV[1];
$fhin="FHIN";
&open_file("$fhin", "$file_in");
while (<$fhin>) {
    $_=~s/<html>/<HTML>/g;$_=~s/<\/html>/<\/HTML>/;
    $_=~s/<body>/<BODY>/g;$_=~s/<\/body>/<\/BODY>/;
    $_=~s/<title>/<TITLE>/g;$_=~s/<\/title>/<\/TITLE>/;
    $_=~s/<a href=/<A HREF=/;
    $_=~s/<a name=/<A NAME=/;
    $_=~s/<h(\d)>/<H$1>/g;$_=~s/<\/h(\d)>/<\/H$1>/g;
    $_=~s/<p>/<P>/g;$_=~s/<\/a>/<\/A>/g;
    $_=~s/<ul>/<UL>/g;$_=~s/<\/ul>/<\/UL>/g;
    $_=~s/<li>/<LI>/g;$_=~s/<\/li>/<\/LI>/g;
    $_=~s/<ol>/<OL>/g;$_=~s/<\/ol>/<\/OL>/g;
    $_=~s/<dl>/<DL>/g;$_=~s/<\/dl>/<\/DL>/g;
    $_=~s/<dd>/<dd>/g;$_=~s/<\/dd>/<\/dd>/g;
    print $_;
}
print "\n";
close($fhin);
exit;
